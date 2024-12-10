library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity conv_nat_to_maxis_aer is
    generic (
        MAX_SPK_PER_TS : integer := 1000;
        DATAWIDTH : integer := 32
    );
    port (
        -- Clocks & resets
        clk_pl  : in std_logic;
        clk_axi : in std_logic;
        srst_pl : in std_logic;

        -- Control from PS
        rdy_in_events : in std_logic;
        ts_event      : in std_logic_vector(DATAWIDTH-1 downto 0);
        nb_event      : in std_logic_vector(DATAWIDTH-1 downto 0);
        id_event      : in std_logic_vector(DATAWIDTH-1 downto 0);

        -- AXI Stream to DMA
        m_axis_aclk     : in std_logic;
        m_axis_tvalid   : out std_logic;
        m_axis_tready   : in std_logic;
        m_axis_tdata    : out std_logic_vector(DATAWIDTH-1 downto 0);
        m_axis_tlast    : out std_logic;

        -- Interrupt
        dma_spk_intr    : out std_logic
    );
end entity conv_nat_to_maxis_aer;

architecture rtl of conv_nat_to_maxis_aer is
    -- Intermediate FIFO
    type fsm_mux_din_tdata_fifo_t is (
        SEL_TS_EVENT,  -- Assert tvalid
        SEL_NB_EVENT,  -- Send stream
        SEL_ID_EVENT   -- Send stream
    );
    signal fsm_mux_din_tdata_fifo : fsm_mux_din_tdata_fifo_t := SEL_TS_EVENT;
    signal tdata_fifo_din         : std_logic_vector(DATAWIDTH-1 downto 0);
    signal tdata_fifo_wr_en       : std_logic := '0';
    signal tdata_fifo_rd_en       : std_logic;
    signal tdata_fifo_dout        : std_logic_vector(DATAWIDTH-1 downto 0);
    signal tdata_fifo_full        : std_logic;
    signal tdata_fifo_almost_full : std_logic;
    signal tdata_fifo_overflow    : std_logic;
    signal tdata_fifo_empty       : std_logic;
    signal tdata_fifo_wr_rst_busy : std_logic;
    signal tdata_fifo_rd_rst_busy : std_logic;
    signal last_nb_events         : std_logic_vector(DATAWIDTH-1 downto 0);

    -- RTL to AXI Stream master
    -- AXI protocol imposes:
    --  * master TDATA can't change while TVALID is HIGH and TREADY is LOW
    --  * master can't wait for TREADY HIGH to set TVALID HIGH
    type fsm_m_axis_mon_t is (
        IDLE,           -- Wait for data valid
        ASSERT_TVALID,  -- Assert tvalid
        SEND_STREAM,    -- Send stream
        ASSERT_TLAST    -- Assert tlast at the end of stream
    );
    signal fsm_m_axis_mon     : fsm_m_axis_mon_t := IDLE;
    signal m_axis_mon_aclk    : std_logic := '0';
    signal m_axis_mon_aresetn : std_logic := '0';
    signal m_axis_mon_tvalid  : std_logic := '0';
    signal m_axis_mon_tdata   : std_logic_vector(DATAWIDTH-1 downto 0) := (others => '0');
    signal m_axis_mon_tlast   : std_logic;
    signal ext_spk_tlast     : std_logic;
    
    -- AXI Stream slave FIFO
    signal s_axis_aresetn   : std_logic := '0';
    signal s_axis_aclk      : std_logic := '0';
    signal s_axis_tvalid    : std_logic := '0';
    signal s_axis_tready    : std_logic := '0';
    signal s_axis_tdata     : std_logic_vector(DATAWIDTH-1 downto 0) := (others=>'0');
    signal s_axis_tlast     : std_logic := '0';

    -- ========================================
    -- From IP Catalog:
    -- Small fifo First Word Fall Through to backthrottle tdata
    -- ========================================
    component small_fwft_fifo_sc is
    port (
        clk         : in std_logic;
        srst        : in std_logic;
        din         : in std_logic_vector(31 downto 0);
        wr_en       : in std_logic;
        rd_en       : in std_logic;
        dout        : out std_logic_vector(31 downto 0);
        full        : out std_logic;
        almost_full : out std_logic;
        overflow    : out std_logic;
        empty       : out std_logic;
        wr_rst_busy : out std_logic;
        rd_rst_busy : out std_logic
    );
    end component;
    
    -- ========================================
    -- From IP Catalog:
    -- Crossing clock domain axi stream FIFO from PL to AXI DMA
    -- ========================================
    component axis_data_fifo_spk_mon is
    port ( 
        s_axis_aresetn      : in std_logic;
        s_axis_aclk         : in std_logic;
        s_axis_tvalid       : in std_logic;
        s_axis_tready       : out std_logic;
        s_axis_tdata        : in std_logic_vector ( 31 downto 0 );
        s_axis_tlast        : in std_logic;
        m_axis_aclk         : in std_logic;
        m_axis_tvalid       : out std_logic;
        m_axis_tready       : in std_logic;
        m_axis_tdata        : out std_logic_vector ( 31 downto 0 );
        m_axis_tlast        : out std_logic
    );
    end component;
begin

    ---------------------------------------------------------------------------------------
    --
    --  ███    ██  █████  ████████     ██████      ███    ███  █████  ██   ██ ██ ███████ 
    --  ████   ██ ██   ██    ██             ██     ████  ████ ██   ██  ██ ██  ██ ██      
    --  ██ ██  ██ ███████    ██         █████      ██ ████ ██ ███████   ███   ██ ███████ 
    --  ██  ██ ██ ██   ██    ██        ██          ██  ██  ██ ██   ██  ██ ██  ██      ██ 
    --  ██   ████ ██   ██    ██        ███████     ██      ██ ██   ██ ██   ██ ██ ███████ 
    --                                                                                   
    --                          
    -- Native stream to master axis
    ---------------------------------------------------------------------------------------

    -- ========================================
    -- Write tdata to temporary FIFO
    -- ========================================
    -- Map FIFO control
    tdata_fifo_map : process(all)
    begin    
        tdata_fifo_wr_en  <= rdy_in_events;
        tdata_fifo_rd_en  <= m_axis_mon_tvalid and s_axis_tready;
        tdata_fifo_din    <= nb_event when fsm_mux_din_tdata_fifo = SEL_NB_EVENT else
                            id_event when fsm_mux_din_tdata_fifo = SEL_ID_EVENT else
                            ts_event;
        last_nb_events    <= nb_event when fsm_mux_din_tdata_fifo = SEL_NB_EVENT;
    end process tdata_fifo_map;

    -- Mux din tdata FIFO
    fsm_mux_din_tdata_fifo_proc: process (clk_pl)
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                fsm_mux_din_tdata_fifo <= SEL_TS_EVENT;
            else
                case fsm_mux_din_tdata_fifo is
                    when SEL_TS_EVENT => fsm_mux_din_tdata_fifo  <= SEL_NB_EVENT when rdy_in_events = '1';
                    when SEL_NB_EVENT => fsm_mux_din_tdata_fifo  <= SEL_ID_EVENT;
                    when SEL_ID_EVENT => fsm_mux_din_tdata_fifo  <= SEL_TS_EVENT when rdy_in_events = '0';
                end case;
            end if;
        end if;
    end process;

    -- FIFO for tdata while waiting for tready to be asserted
    tdata_fifo_sc_inst: small_fwft_fifo_sc
    port map(
        clk         => clk_pl,
        srst        => srst_pl,
        din         => tdata_fifo_din,
        wr_en       => tdata_fifo_wr_en,
        rd_en       => tdata_fifo_rd_en,
        dout        => tdata_fifo_dout,
        full        => tdata_fifo_full,
        almost_full => tdata_fifo_almost_full,
        overflow    => tdata_fifo_overflow,
        empty       => tdata_fifo_empty,
        wr_rst_busy => tdata_fifo_wr_rst_busy,
        rd_rst_busy => tdata_fifo_rd_rst_busy
    );


    -- ========================================
    -- Native stream to maxis
    -- ========================================
    -- Map maxis
    map_maxis_mon : process(all)
    begin    
        m_axis_mon_aclk    <= clk_pl;
        m_axis_mon_aresetn <= not(srst_pl);
        m_axis_mon_tdata   <= tdata_fifo_dout;
        m_axis_mon_tvalid  <= '1' when fsm_m_axis_mon = ASSERT_TVALID or
                                    fsm_m_axis_mon = SEND_STREAM   or
                                    fsm_m_axis_mon = ASSERT_TLAST
                                else '0';
        m_axis_mon_tlast   <= '1' when fsm_m_axis_mon = ASSERT_TLAST
                                else '0';
    end process map_maxis_mon;

    -- Generate controls
    fsm_m_axis_mon_proc: process (m_axis_mon_aclk)
        variable word_cnt : integer range 0 to MAX_SPK_PER_TS-1 := 0;
    begin
        if rising_edge(m_axis_mon_aclk) then
            if m_axis_mon_aresetn = '0' then
                word_cnt  := 0;
                fsm_m_axis_mon <= IDLE;
            else
                case fsm_m_axis_mon is
                    when IDLE =>                        
                        fsm_m_axis_mon <= ASSERT_TVALID when tdata_fifo_wr_en = '1';

                    when ASSERT_TVALID =>
                        word_cnt  := to_integer(unsigned(last_nb_events));

                        fsm_m_axis_mon <= SEND_STREAM when s_axis_tready = '1';

                    when SEND_STREAM =>
                        if word_cnt > 1 then
                            word_cnt := word_cnt -1;
                        else                            
                            fsm_m_axis_mon <= ASSERT_TLAST;
                        end if;

                    when ASSERT_TLAST =>
                        fsm_m_axis_mon <= IDLE;

                end case;
            end if;
        end if;
    end process;

    -- ========================================
    -- Move tlast maxis mon domain to saxis domain
    -- ========================================
    -- Mapping
    dma_spk_intr <= ext_spk_tlast;

    -- Extent spike tlast to conenct to dma intr spike in clk ps domain (AXI GPIO)
    extent_spk_tlast : entity work.trig_pulse_once_const
    generic map (
      WIDTH_CCY => 4 -- clk_axi up to ~4 times slower than clk_pl
    )
    port map (
      clk       => clk_pl,
      rst       => srst_pl,
      trig_in   => m_axis_mon_tlast,
      trig_out  => ext_spk_tlast
    );

    ---------------------------------------------------------------------------------------
    --
    --  ███    ███  █████  ██   ██ ██ ███████           ██       ███████  █████  ██   ██ ██ ███████ 
    --  ████  ████ ██   ██  ██ ██  ██ ██                 ██      ██      ██   ██  ██ ██  ██ ██      
    --  ██ ████ ██ ███████   ███   ██ ███████     █████   ██     ███████ ███████   ███   ██ ███████ 
    --  ██  ██  ██ ██   ██  ██ ██  ██      ██            ██           ██ ██   ██  ██ ██  ██      ██ 
    --  ██      ██ ██   ██ ██   ██ ██ ███████           ██       ███████ ██   ██ ██   ██ ██ ███████ 
    --                                                                                              
    --                          
    -- Master axis to slave axis of CDC FIFO
    ---------------------------------------------------------------------------------------

    -- Map AXI Stream Data FIFO
    s_axis_aclk     <= m_axis_mon_aclk;
    s_axis_aresetn  <= m_axis_mon_aresetn;
    s_axis_tvalid   <= m_axis_mon_tvalid;
    s_axis_tdata    <= m_axis_mon_tdata;
    s_axis_tlast    <= m_axis_mon_tlast;

    ---------------------------------------------------------------------------------------
    --
    --  ███████           ██       ███████ ██ ███████  ██████            ██       ███    ███ 
    --  ██                 ██      ██      ██ ██      ██    ██            ██      ████  ████ 
    --  ███████     █████   ██     █████   ██ █████   ██    ██     █████   ██     ██ ████ ██ 
    --       ██            ██      ██      ██ ██      ██    ██            ██      ██  ██  ██ 
    --  ███████           ██       ██      ██ ██       ██████            ██       ██      ██ 
    --                                                                                       
    --                                                                                       
    -- Master axis to slave axis of CDC FIFO
    ---------------------------------------------------------------------------------------

    axis_data_fifo_inst: axis_data_fifo_spk_mon
    port map(
        -- To DMA
        s_axis_aresetn    => s_axis_aresetn,
        s_axis_aclk       => s_axis_aclk,
        s_axis_tvalid     => s_axis_tvalid,
        s_axis_tready     => s_axis_tready,
        s_axis_tdata      => s_axis_tdata,
        s_axis_tlast      => s_axis_tlast,
        -- From spike monitoring
        m_axis_aclk       => m_axis_aclk,
        m_axis_tvalid     => m_axis_tvalid,
        m_axis_tready     => m_axis_tready,
        m_axis_tdata      => m_axis_tdata,
        m_axis_tlast      => m_axis_tlast
    );
end architecture;