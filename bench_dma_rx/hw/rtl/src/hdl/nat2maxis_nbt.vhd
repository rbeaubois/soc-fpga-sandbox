library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity nat2maxis_nbt is
    generic (
        PACKET_SIZE : integer;
        DWIDTH      : integer
    );
    port (
        -- Clocks & resets
        clk_rtl  : in std_logic;
        srst_rtl : in std_logic;

        -- Control from PS
        nat_dvalid : in std_logic;
        nat_tstamp : in std_logic_vector(DWIDTH-1 downto 0);
        nat_data   : in std_logic_vector(DWIDTH-1 downto 0);

        -- AXI Stream to DMA
        m_axis_aclk     : in std_logic;
        m_axis_tvalid   : out std_logic;
        m_axis_tready   : in std_logic;
        m_axis_tdata    : out std_logic_vector(DWIDTH-1 downto 0);
        m_axis_tlast    : out std_logic;

        -- Interrupt
        fifo_rcnt       : out std_logic_vector( DWIDTH-1 downto 0);
        intr_wr_done    : out std_logic
    );
end entity nat2maxis_nbt;

architecture rtl of nat2maxis_nbt is
    -- Intermediate FIFO
    type fsm_mux_tdata_t is (
        SEL_TSTAMP, -- Assert tvalid
        SEL_DATA    -- Send stream
    );
    signal fsm_mux_tdata      : fsm_mux_tdata_t := SEL_TSTAMP;
    signal event_stream_valid : std_logic := '0';

    -- RTL to AXI Stream master
    -- AXI protocol imposes:
    --  * master TDATA can't change while TVALID is HIGH and TREADY is LOW
    --  * master can't wait for TREADY HIGH to set TVALID HIGH
    type fsm_m_axis_mon_t is (
        IDLE,           -- Wait for data valid
        SEND_STREAM,    -- Send stream
        ASSERT_TLAST    -- Assert tlast at the end of stream
    );
    signal fsm_m_axis_mon     : fsm_m_axis_mon_t := IDLE;
    signal m_axis_mon_aclk    : std_logic := '0';
    signal m_axis_mon_aresetn : std_logic := '0';
    signal m_axis_mon_tvalid  : std_logic := '0';
    signal m_axis_mon_tdata   : std_logic_vector(DWIDTH-1 downto 0) := (others => '0');
    signal m_axis_mon_tlast   : std_logic;
    signal ext_spk_tlast     : std_logic;
    
    -- AXI Stream slave FIFO
    signal s_axis_aresetn   : std_logic := '0';
    signal s_axis_aclk      : std_logic := '0';
    signal s_axis_tvalid    : std_logic := '0';
    signal s_axis_tready    : std_logic := '0';
    signal s_axis_tdata     : std_logic_vector(DWIDTH-1 downto 0) := (others=>'0');
    signal s_axis_tlast     : std_logic := '0';
    
    -- ========================================
    -- From IP Catalog:
    -- Crossing clock domain axi stream FIFO from PL to AXI DMA
    -- ========================================
    component axis_data_fifo_dma_s2mm_ip is
    port ( 
        s_axis_aresetn      : in std_logic;
        s_axis_aclk         : in std_logic;
        s_axis_tvalid       : in std_logic;
        s_axis_tready       : out std_logic;
        s_axis_tdata        : in std_logic_vector( DWIDTH-1 downto 0 );
        s_axis_tlast        : in std_logic;
        m_axis_aclk         : in std_logic;
        m_axis_tvalid       : out std_logic;
        m_axis_tready       : in std_logic;
        m_axis_tdata        : out std_logic_vector( DWIDTH-1 downto 0 );
        m_axis_tlast        : out std_logic;
        axis_rd_data_count  : out std_logic_vector( DWIDTH-1 downto 0)
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
    fsm_mux_din_tdata_fifo_proc: process (clk_rtl)
    begin
        if rising_edge(clk_rtl) then
            if srst_rtl = '1' then
                fsm_mux_tdata <= SEL_TSTAMP;
            else
                case fsm_mux_tdata is
                    when SEL_TSTAMP => 
                        fsm_mux_tdata <= SEL_DATA when nat_dvalid = '1';
                    when SEL_DATA => 
                        fsm_mux_tdata <= SEL_TSTAMP when nat_dvalid = '0';
                end case;
            end if;
        end if;
    end process;

    -- Map maxis
    map_maxis_mon : process(all)
    begin    
        m_axis_mon_aclk    <= clk_rtl;
        m_axis_mon_aresetn <= not(srst_rtl);
        m_axis_mon_tdata   <= nat_data when fsm_mux_tdata = SEL_DATA else
                              nat_tstamp;
        m_axis_mon_tvalid  <= '1' when nat_dvalid = '1' else
                              '0';
        m_axis_mon_tlast   <= '1' when fsm_m_axis_mon = ASSERT_TLAST else
                              '0';
    end process map_maxis_mon;

    -- Generate controls
    fsm_m_axis_mon_proc: process (m_axis_mon_aclk)
        variable word_cnt : integer range 0 to PACKET_SIZE-1 := 0;
    begin
        if rising_edge(m_axis_mon_aclk) then
            if m_axis_mon_aresetn = '0' then
                word_cnt  := 0;
                fsm_m_axis_mon <= IDLE;
            else
                case fsm_m_axis_mon is
                    when IDLE =>
                        word_cnt := PACKET_SIZE-1;                  
                        fsm_m_axis_mon <= SEND_STREAM when nat_dvalid = '1';

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
    intr_wr_done <= m_axis_mon_tlast;
    
    -- intr_wr_done <= ext_spk_tlast;
    -- -- Extent spike tlast to conenct to dma intr spike in clk ps domain (AXI GPIO)
    -- extent_spk_tlast : entity work.trig_pulse_once_const
    -- generic map (
    --   WIDTH_CCY => 4 -- m_axis_aclk up to ~4 times slower than clk_rtl
    -- )
    -- port map (
    --   clk       => clk_rtl,
    --   rst       => srst_rtl,
    --   trig_in   => m_axis_mon_tlast,
    --   trig_out  => ext_spk_tlast
    -- );

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

    axis_data_fifo_dma_s2mm_ip_inst: axis_data_fifo_dma_s2mm_ip
    port map(
        -- slave from rtl in clock rtl domain
        s_axis_aresetn    => s_axis_aresetn,
        s_axis_aclk       => s_axis_aclk,
        s_axis_tvalid     => s_axis_tvalid,
        s_axis_tready     => s_axis_tready,
        s_axis_tdata      => s_axis_tdata,
        s_axis_tlast      => s_axis_tlast,
        -- master to dma s2mm in clk axi domain
        m_axis_aclk       => m_axis_aclk,
        m_axis_tvalid     => m_axis_tvalid,
        m_axis_tready     => m_axis_tready,
        m_axis_tdata      => m_axis_tdata,
        m_axis_tlast      => m_axis_tlast,
        -- Read word in fifo in read domain
        axis_rd_data_count => fifo_rcnt
    );
end architecture;