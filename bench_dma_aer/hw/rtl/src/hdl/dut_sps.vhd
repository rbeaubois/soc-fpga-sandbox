library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity dut_sps is
    generic(
        FREQ_MHZ_CLK_RTL   : integer := 400;
        TIME_STEP_US       : integer := 500;
        PACKET_SIZE        : integer := 32;
        DWIDTH_SPS         : integer := 32;
        DWIDTH_TS          : integer := 32;
        DWIDTH_ID          : integer := 16;
        AWIDTH_FIFO_SPS2PL : integer := 10;
        NB_CHANNELS        : integer := 10
    );
    port(
        -- RTL clock
        clk_rtl    : in std_logic;
        proc_reset : in std_logic;
        en_core    : in std_logic;
        ts_tick    : in std_logic;

        -- Samples PL -> PS via DMA
        M_AXIS_ACLK     : in std_logic;
        M_AXIS_ARESETN  : in std_logic;
        M_AXIS_TVALID   : out std_logic;
        M_AXIS_TREADY   : in std_logic;
        M_AXIS_TDATA    : out std_logic_vector(DWIDTH_SPS-1 downto 0);
        M_AXIS_TLAST    : out std_logic;

        -- Samples PS -> PL via DMA
        S_AXIS_ACLK     : in std_logic;
        S_AXIS_ARESETN  : in std_logic;
        S_AXIS_TREADY   : out std_logic;
        S_AXIS_TDATA    : in std_logic_vector(DWIDTH_SPS-1 downto 0);
        S_AXIS_TLAST    : in std_logic;
        S_AXIS_TVALID   : in std_logic;

        wr_en_sps2pl      : in std_logic;
        wr_cnt_fifo_sps2l : out std_logic_vector( AWIDTH_FIFO_SPS2PL-1 downto 0);

        -- Interrupt
        fifo_rcnt       : out std_logic_vector( DWIDTH_SPS-1 downto 0);
        intr_wr_done    : out std_logic
    );
end entity dut_sps;

architecture RTL of dut_sps is
    -- Time step generator
    constant PERIOD_CCY : integer := TIME_STEP_US*FREQ_MHZ_CLK_RTL;

    -- Reset
    signal srst_rtl     : std_logic := '1';
    
    -- Native stream
    signal nats_dvalid  : std_logic := '0';
    signal nats_tstamp  : std_logic_vector( DWIDTH_SPS-1 downto 0) := (others => '0'); -- TODO: patch dummy for tstamp on different size
    signal nats_data    : std_logic_vector( DWIDTH_SPS-1 downto 0) := (others => '0');

    -- Samples from PS
    signal sps_rdy      : std_logic := '0';
    signal sps_ts       : std_logic_vector(DWIDTH_TS-1 downto 0)  := (others => '0');
    signal sps_chan_id  : std_logic_vector(DWIDTH_ID-1 downto 0)  := (others => '0');
    signal sps_data     : std_logic_vector(DWIDTH_SPS-1 downto 0) := (others => '0');
begin
    -- Drive reset
    srst_rtl <= proc_reset;

    -- Generate dummy rtl stream
    dummy_rtl_stream_inst: entity work.dummy_rtl_stream
    generic map (
        PERIOD_CCY  => PERIOD_CCY,
        PACKET_SIZE => PACKET_SIZE,
        DWIDTH      => DWIDTH_SPS
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
    nat2maxis_nbt_inst: entity work.nat2maxis_dma_sps_nbt
    generic map  (
        PACKET_SIZE => PACKET_SIZE,
        DWIDTH      => DWIDTH_SPS
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

    -- Receive samples from PS
    saxis2nat_dma_sps_inst: entity work.saxis2nat_dma_sps
    generic map(
        DWIDTH_SPS  => DWIDTH_SPS,
        DWIDTH_TS   => DWIDTH_TS,
        DWIDTH_ID   => DWIDTH_ID,
        AWIDTH_FIFO => AWIDTH_FIFO_SPS2PL,
        NB_CHANNELS => NB_CHANNELS
    )
    port map(
        clk_pl         => clk_rtl,
        srst_pl        => srst_rtl,
        srst_axi       => proc_reset,
        en_core        => en_core,
        ts_tick        => ts_tick,
        ps_tx_dma_rdy  => wr_en_sps2pl,
        count_fifo     => wr_cnt_fifo_sps2l,
        s_axis_aclk    => s_axis_aclk,
        s_axis_aresetn => s_axis_aresetn,
        s_axis_tready  => s_axis_tready,
        s_axis_tdata   => s_axis_tdata,
        s_axis_tlast   => s_axis_tlast,
        s_axis_tvalid  => s_axis_tvalid,
        rdy            => sps_rdy,
        ts             => sps_ts,
        chan_id        => sps_chan_id,
        sample         => sps_data
    );

end architecture RTL;