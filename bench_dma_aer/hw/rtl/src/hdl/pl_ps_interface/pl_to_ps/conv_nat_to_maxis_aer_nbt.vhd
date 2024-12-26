library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity conv_nat_to_maxis_aer_nbt is
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
end entity conv_nat_to_maxis_aer_nbt;

architecture rtl of conv_nat_to_maxis_aer_nbt is
    -- Intermediate FIFO
    type fsm_mux_tdata_t is (
        SEL_TS_EVENT,  -- Assert tvalid
        SEL_NB_EVENT,  -- Send stream
        SEL_ID_EVENT   -- Send stream
    );
    signal fsm_mux_tdata  : fsm_mux_tdata_t := SEL_TS_EVENT;
    signal last_nb_events : std_logic_vector(DATAWIDTH-1 downto 0);
    signal event_stream_valid : std_logic := '0';

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
    -- Native stream to maxis
    -- ========================================
    -- Mux din tdata FIFO
    fsm_mux_din_tdata_fifo_proc: process (clk_pl)
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                fsm_mux_tdata <= SEL_TS_EVENT;
            else
                case fsm_mux_tdata is
                    when SEL_TS_EVENT => fsm_mux_tdata  <= SEL_NB_EVENT when rdy_in_events = '1';
                    when SEL_NB_EVENT => fsm_mux_tdata  <= SEL_ID_EVENT;
                    when SEL_ID_EVENT => fsm_mux_tdata  <= SEL_TS_EVENT when rdy_in_events = '0';
                end case;
            end if;
        end if;
    end process;

    -- Map maxis
    map_maxis_mon : process(all)
    begin    
        m_axis_mon_aclk    <= clk_pl;
        m_axis_mon_aresetn <= not(srst_pl);
        m_axis_mon_tdata   <= nb_event when fsm_mux_tdata = SEL_NB_EVENT else
                              id_event when fsm_mux_tdata = SEL_ID_EVENT else
                              ts_event;
        m_axis_mon_tvalid  <= '1' when rdy_in_events = '1' else
                              '0';
        m_axis_mon_tlast   <= '1' when fsm_m_axis_mon = ASSERT_TLAST else
                              '0';
        event_stream_valid <= rdy_in_events;
    end process map_maxis_mon;

    map_last_ev : process (m_axis_mon_aclk) is
    begin
        if rising_edge(m_axis_mon_aclk) then
            if m_axis_mon_aresetn = '0' then
                last_nb_events <= (others => '0');
            else
                last_nb_events <= nb_event when fsm_mux_tdata = SEL_NB_EVENT else
                                  last_nb_events;
            end if;
        end if;
    end process map_last_ev;

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
                        fsm_m_axis_mon <= ASSERT_TVALID when event_stream_valid = '1';

                    when ASSERT_TVALID =>
                        word_cnt  := to_integer(unsigned(last_nb_events));

                        if word_cnt = 1 then
                            fsm_m_axis_mon <= ASSERT_TLAST;
                        else
                            fsm_m_axis_mon <= SEND_STREAM;
                        end if;

                    when SEND_STREAM =>
                        if word_cnt > 2 then
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