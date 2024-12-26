library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity top is
    generic(
        FREQ_MHZ_CLK_RTL : integer := 400;
        TIME_STEP_US     : integer := 500;
        PACKET_SIZE      : integer := 32;
        DWIDTH           : integer := 32
    );
    port(
        -- RTL clock
        clk_rtl    : in std_logic;
        proc_reset : in std_logic;
        en_core    : in std_logic;

        -- MAXIS to DMA S2MM
        M_AXIS_ACLK     : in std_logic;
        M_AXIS_TVALID   : out std_logic;
        M_AXIS_TREADY   : in std_logic;
        M_AXIS_TDATA    : out std_logic_vector(DWIDTH-1 downto 0);
        M_AXIS_TLAST    : out std_logic;

        -- Interrupt
        fifo_rcnt       : out std_logic_vector( DWIDTH-1 downto 0);
        intr_wr_done    : out std_logic;

        -- GPIO
        uled_uf1 : out std_logic;
        uled_uf2 : out std_logic;
        pmod1    : out std_logic_vector(7 downto 0);
        pmod2    : out std_logic_vector(7 downto 0);
        pmod3    : out std_logic_vector(7 downto 0);
        pmod4    : out std_logic_vector(7 downto 0)
    );
end entity top;

architecture RTL of top is
    -- Time step generator
    constant PERIOD_CCY : integer := TIME_STEP_US*FREQ_MHZ_CLK_RTL;

    -- Reset
    signal srst_rtl     : std_logic := '1';
    
    -- Native stream
    signal nats_dvalid  : std_logic := '0';
    signal nats_tstamp  : std_logic_vector( DWIDTH-1 downto 0) := (others => '0');
    signal nats_data    : std_logic_vector( DWIDTH-1 downto 0) := (others => '0');
begin
    -- Drive GPIOs
    uled_uf1    <= '1';
    uled_uf2    <= not(srst_rtl);
    pmod1       <= (others => '0');
    pmod2       <= (others => '0');
    pmod3       <= (others => '0');
    pmod4       <= (others => '0');

    -- Drive reset
    srst_rtl <= proc_reset;

    -- Generate dummy rtl stream
    dummy_rtl_stream_inst: entity work.dummy_rtl_stream
    generic map (
        PERIOD_CCY  => PERIOD_CCY,
        PACKET_SIZE => PACKET_SIZE,
        DWIDTH      => DWIDTH
    )
    port map(
        clk_rtl     => clk_rtl,
        srst_rtl    => srst_rtl,
        en_core     => en_core,

        nats_dvalid => nats_dvalid,
        nats_tstamp => nats_tstamp,
        nats_data   => nats_data
    );

    -- Convert native stream to MAXIS to DMA S2MM
    nat2maxis_nbt_inst: entity work.nat2maxis_nbt
    generic map  (
        PACKET_SIZE => PACKET_SIZE,
        DWIDTH      => DWIDTH
    )
    port map(
        clk_rtl       => clk_rtl,
        srst_rtl      => srst_rtl,
        nat_dvalid    => nats_dvalid,
        nat_tstamp    => nats_tstamp,
        nat_data      => nats_data,
        m_axis_aclk   => m_axis_aclk,
        m_axis_tvalid => m_axis_tvalid,
        m_axis_tready => m_axis_tready,
        m_axis_tdata  => m_axis_tdata,
        m_axis_tlast  => m_axis_tlast,
        fifo_rcnt     => fifo_rcnt,
        intr_wr_done  => intr_wr_done
    );

end architecture RTL;
