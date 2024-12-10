-- Create IP from TCL:
-- create_ip -name axigpio -vendor xilinx.com -library ip -version 2.0 -module_name axigpio_dualch
-- set_property -dict [list \
--   CONFIG.C_ALL_INPUTS {1} \
--   CONFIG.C_ALL_OUTPUTS_2 {1} \
--   CONFIG.C_IS_DUAL {1} \
-- ] [get_ips axigpio_dualch]

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axigpio_dualch_intr is
    generic(
        DWIDTH_GPIO : integer := 32
    );
    port(
        -- AXI BUS
        S_AXI_ACLK    : in  std_logic;
        S_AXI_ARESETN : in  std_logic;
        S_AXI_AWADDR  : in  std_logic_vector(8 downto 0);
        S_AXI_AWVALID : in  std_logic;
        S_AXI_AWREADY : out std_logic;
        S_AXI_WDATA   : in  std_logic_vector(DWIDTH_GPIO-1 downto 0);
        S_AXI_WSTRB   : in  std_logic_vector(3 downto 0);
        S_AXI_WVALID  : in  std_logic;
        S_AXI_WREADY  : out std_logic;
        S_AXI_BRESP   : out std_logic_vector(1 downto 0);
        S_AXI_BVALID  : out std_logic;
        S_AXI_BREADY  : in  std_logic;
        S_AXI_ARADDR  : in  std_logic_vector(8 downto 0);
        S_AXI_ARVALID : in  std_logic;
        S_AXI_ARREADY : out std_logic;
        S_AXI_RDATA   : out std_logic_vector(DWIDTH_GPIO-1 downto 0);
        S_AXI_RRESP   : out std_logic_vector(1 downto 0);
        S_AXI_RVALID  : out std_logic;
        S_AXI_RREADY  : in  std_logic;

        data_to_ps      : in std_logic_vector(DWIDTH_GPIO-1 downto 0);
        data_from_ps    : out std_logic_vector(DWIDTH_GPIO-1 downto 0);
        pl_irpt_trigger : in std_logic;
        pl_intr         : out std_logic;
        ps_intr         : out std_logic
    );
end entity axigpio_dualch_intr;

architecture RTL of axigpio_dualch_intr is
    attribute SIGIS : string;
    attribute SIGIS of pl_intr : signal is "INTR_LEVEL_HIGH";

    component axigpio_dualch_intr_ip
        port (
            s_axi_aclk    : in  std_logic;
            s_axi_aresetn : in  std_logic;
            s_axi_awaddr  : in  std_logic_vector(8 downto 0);
            s_axi_awvalid : in  std_logic;
            s_axi_awready : out std_logic;
            s_axi_wdata   : in  std_logic_vector(DWIDTH_GPIO-1 downto 0);
            s_axi_wstrb   : in  std_logic_vector(3 downto 0);
            s_axi_wvalid  : in  std_logic;
            s_axi_wready  : out std_logic;
            s_axi_bresp   : out std_logic_vector(1 downto 0);
            s_axi_bvalid  : out std_logic;
            s_axi_bready  : in  std_logic;
            s_axi_araddr  : in  std_logic_vector(8 downto 0);
            s_axi_arvalid : in  std_logic;
            s_axi_arready : out std_logic;
            s_axi_rdata   : out std_logic_vector(DWIDTH_GPIO-1 downto 0);
            s_axi_rresp   : out std_logic_vector(1 downto 0);
            s_axi_rvalid  : out std_logic;
            s_axi_rready  : in  std_logic;
            gpio_io_i     : in  std_logic_vector(DWIDTH_GPIO-1 downto 0);
            gpio2_io_o    : out std_logic_vector(DWIDTH_GPIO-1 downto 0);
            ip2intc_irpt  : out std_logic
        );
    end component;
begin
    pl_intr <= pl_irpt_trigger;

    axigpio_dualch_isnt : axigpio_dualch_intr_ip
    PORT MAP (
      s_axi_aclk    => S_AXI_ACLK,
      s_axi_aresetn => S_AXI_ARESETN,
      s_axi_awaddr  => S_AXI_AWADDR,
      s_axi_awvalid => S_AXI_AWVALID,
      s_axi_awready => S_AXI_AWREADY,
      s_axi_wdata   => S_AXI_WDATA,
      s_axi_wstrb   => S_AXI_WSTRB,
      s_axi_wvalid  => S_AXI_WVALID,
      s_axi_wready  => S_AXI_WREADY,
      s_axi_bresp   => S_AXI_BRESP,
      s_axi_bvalid  => S_AXI_BVALID,
      s_axi_bready  => S_AXI_BREADY,
      s_axi_araddr  => S_AXI_ARADDR,
      s_axi_arvalid => S_AXI_ARVALID,
      s_axi_arready => S_AXI_ARREADY,
      s_axi_rdata   => S_AXI_RDATA,
      s_axi_rresp   => S_AXI_RRESP,
      s_axi_rvalid  => S_AXI_RVALID,
      s_axi_rready  => S_AXI_RREADY,
      gpio_io_i     => data_to_ps,
      gpio2_io_o    => data_from_ps,
      ip2intc_irpt  => ps_intr
    );
end architecture RTL;

