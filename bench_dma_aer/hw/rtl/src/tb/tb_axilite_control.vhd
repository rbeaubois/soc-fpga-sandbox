
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axlmap_control.axlmap;

entity axilite_control_tb is
end;

architecture bench of axilite_control_tb is
    -- Clock period
    constant clk_period : time := 5 ns;
    -- Generics
    constant C_S_AXI_DATA_WIDTH : integer := 32;
    constant C_S_AXI_ADDR_WIDTH : integer := 16;
    constant OPT_MEM_ADDR_BITS  : integer := 8;
    -- Ports
    signal rst               : std_logic;
    signal en_core           : std_logic;
    signal ps_rd_events_size : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal pl_wr_events_size : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal S_AXI_ACLK        : std_logic;
    signal S_AXI_ARESETN     : std_logic;
    signal S_AXI_AWADDR      : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal S_AXI_AWPROT      : std_logic_vector(2 downto 0);
    signal S_AXI_AWVALID     : std_logic;
    signal S_AXI_AWREADY     : std_logic;
    signal S_AXI_WDATA       : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal S_AXI_WSTRB       : std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
    signal S_AXI_WVALID      : std_logic;
    signal S_AXI_WREADY      : std_logic;
    signal S_AXI_BRESP       : std_logic_vector(1 downto 0);
    signal S_AXI_BVALID      : std_logic;
    signal S_AXI_BREADY      : std_logic;
    signal S_AXI_ARADDR      : std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
    signal S_AXI_ARPROT      : std_logic_vector(2 downto 0);
    signal S_AXI_ARVALID     : std_logic;
    signal S_AXI_ARREADY     : std_logic;
    signal S_AXI_RDATA       : std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal S_AXI_RRESP       : std_logic_vector(1 downto 0);
    signal S_AXI_RVALID      : std_logic;
    signal S_AXI_RREADY      : std_logic;
begin
    S_AXI_ACLK <= not S_AXI_ACLK after clk_period/2;
    axilite_control_inst : entity work.axilite_control
    port map (
        rst               => rst,
        en_core           => en_core,
        S_AXI_ACLK        => S_AXI_ACLK,
        S_AXI_ARESETN     => S_AXI_ARESETN,
        S_AXI_AWADDR      => S_AXI_AWADDR,
        S_AXI_AWPROT      => S_AXI_AWPROT,
        S_AXI_AWVALID     => S_AXI_AWVALID,
        S_AXI_AWREADY     => S_AXI_AWREADY,
        S_AXI_WDATA       => S_AXI_WDATA,
        S_AXI_WSTRB       => S_AXI_WSTRB,
        S_AXI_WVALID      => S_AXI_WVALID,
        S_AXI_WREADY      => S_AXI_WREADY,
        S_AXI_BRESP       => S_AXI_BRESP,
        S_AXI_BVALID      => S_AXI_BVALID,
        S_AXI_BREADY      => S_AXI_BREADY,
        S_AXI_ARADDR      => S_AXI_ARADDR,
        S_AXI_ARPROT      => S_AXI_ARPROT,
        S_AXI_ARVALID     => S_AXI_ARVALID,
        S_AXI_ARREADY     => S_AXI_ARREADY,
        S_AXI_RDATA       => S_AXI_RDATA,
        S_AXI_RRESP       => S_AXI_RRESP,
        S_AXI_RVALID      => S_AXI_RVALID,
        S_AXI_RREADY      => S_AXI_RREADY
    );

    print_registers_index : process is
        constant spacing : string := "    ";
    begin
        report "";
        report "AXI-Lite mapping:";
        report "REGW_CONTROL :" & integer'image(axlmap.REGW_CONTROL) & spacing
             & "BIT_RESET_REGW_CONTROL :" & integer'image(axlmap.BIT_RESET_REGW_CONTROL) & spacing
             & "BIT_EN_CORE_REGW_CONTROL :" & integer'image(axlmap.BIT_EN_CORE_REGW_CONTROL) & spacing;

        report "";
        report "Number of registers:";
        report "NB_REGS :" & integer'image(axlmap.NB_REGS) & spacing
            & "NB_REGW :" & integer'image(axlmap.NB_PS_REGW) & spacing
            & "NB_REGR :" & integer'image(axlmap.NB_PS_REGR) & spacing;
        wait;
    end process print_registers_index;
    
end;