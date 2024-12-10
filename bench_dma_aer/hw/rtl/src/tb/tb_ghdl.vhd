library ieee;
use ieee.std_logic_1164.all;

entity tb_ghdl is
end tb_ghdl;

use work.axlmap_control.axlmap;
use work.fpga_arch_pkg.fpga_arch_t;
use work.fpga_arch_pkg.all;

architecture Behavioral of tb_ghdl is
begin

    process
    begin
        -- Print "Hello, World!" to the simulation output
        report "";
        report "AXI-Lite mapping:";
        report "REGW_CONTROL             :" & integer'image(axlmap.REGW_CONTROL);
        report "BIT_RESET_REGW_CONTROL   :" & integer'image(axlmap.BIT_RESET_REGW_CONTROL);
        report "BIT_EN_CORE_REGW_CONTROL :" & integer'image(axlmap.BIT_EN_CORE_REGW_CONTROL);

        report "";
        report "Number of registers:";
        report "NB_REGS :" & integer'image(axlmap.NB_REGS);
        report "NB_REGW :" & integer'image(axlmap.NB_PS_REGW);
        report "NB_REGR :" & integer'image(axlmap.NB_PS_REGR);

        report "";
        report "Architecture selection:";
        report "Test: " & integer'image(sel_from_farch(VERSAL, (ZYNQMP=>10, VERSAL=>15)));

        -- End simulation
        wait;
    end process;

end Behavioral;