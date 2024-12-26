
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top_tb is
end;

architecture bench of top_tb is
    -- Clock period
    constant clk_period_rtl : time := 2.5 ns;
    constant clk_period_axi : time := 5.0 ns;
    -- Generics
    constant FREQ_MHZ_CLK_RTL : integer := 400;
    constant TIME_STEP_US     : integer := 10;
    constant PACKET_SIZE      : integer := 32;
    constant DWIDTH           : integer := 32;
    -- Ports
    signal clk_rtl            : std_logic := '0';
    signal proc_reset         : std_logic := '0';
    signal en_core            : std_logic := '0';
    signal m_axis_aclk        : std_logic := '0';
    signal m_axis_tvalid      : std_logic := '0';
    signal m_axis_tready      : std_logic := '0';
    signal m_axis_tdata       : std_logic_vector(DWIDTH-1 downto 0) := (others => '0');
    signal m_axis_tlast       : std_logic := '0';
    signal fifo_rcnt          : std_logic_vector( DWIDTH-1 downto 0) := (others => '0');
    signal intr_wr_done       : std_logic := '0';
    signal uled_uf1           : std_logic := '0';
    signal uled_uf2           : std_logic := '0';
    signal pmod1              : std_logic_vector(7 downto 0) := (others => '0');
    signal pmod2              : std_logic_vector(7 downto 0) := (others => '0');
    signal pmod3              : std_logic_vector(7 downto 0) := (others => '0');
    signal pmod4              : std_logic_vector(7 downto 0) := (others => '0');
    -- Intermediate
    constant NB_TIME_STEP_GENERATED       : integer := 20;
    constant NB_TIME_STEP_TO_WAIT_FOR_DMA : integer := NB_TIME_STEP_GENERATED/2;
    signal rst_over : std_logic := '0';
begin
    drive_reset : process is
    begin
        proc_reset <= '1';
        wait for 20*clk_period_axi;
        proc_reset  <= '0';
        rst_over    <= '1';
        wait;
    end process drive_reset;

    enable: process is
    begin
        en_core <= '0';
        wait until rising_edge(rst_over);
        en_core <= '1';
        wait for NB_TIME_STEP_GENERATED*(FREQ_MHZ_CLK_RTL*TIME_STEP_US)*clk_period_axi;
        std.env.finish;
    end process enable;

    emulate_dma_proxy_driver: process is
    begin
        m_axis_tready <= '0';
        wait until rising_edge(rst_over);
        wait for NB_TIME_STEP_TO_WAIT_FOR_DMA*(FREQ_MHZ_CLK_RTL*TIME_STEP_US)*clk_period_axi;
        m_axis_tready <= '1';
        wait;
    end process emulate_dma_proxy_driver;

    top_inst : entity work.top
    generic map (
        FREQ_MHZ_CLK_RTL => FREQ_MHZ_CLK_RTL,
        TIME_STEP_US     => TIME_STEP_US,
        PACKET_SIZE      => PACKET_SIZE,
        DWIDTH           => DWIDTH
    )
    port map (
        clk_rtl       => clk_rtl,
        proc_reset    => proc_reset,
        en_core       => en_core,
        m_axis_aclk   => m_axis_aclk,
        m_axis_tvalid => m_axis_tvalid,
        m_axis_tready => m_axis_tready,
        m_axis_tdata  => m_axis_tdata,
        m_axis_tlast  => m_axis_tlast,
        fifo_rcnt     => fifo_rcnt,
        intr_wr_done  => intr_wr_done,
        uled_uf1      => uled_uf1,
        uled_uf2      => uled_uf2,
        pmod1         => pmod1,
        pmod2         => pmod2,
        pmod3         => pmod3,
        pmod4         => pmod4
    );
    clk_rtl     <= not clk_rtl     after clk_period_rtl/2;
    m_axis_aclk <= not m_axis_aclk after clk_period_axi/2;

end;