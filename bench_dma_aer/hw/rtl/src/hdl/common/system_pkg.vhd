library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

use work.fpga_arch_pkg.all;
use work.fpga_arch_pkg.sel_from_farch;
use work.fpga_arch_pkg.farch_to_str;
use work.fpga_arch_pkg.fpga_arch_t;
use work.fpga_arch_pkg.gen_selector_hwconfig_hfile;

use work.futils_global_pkg.to_lowercase;
use work.futils_cpp_pkg;

package system_pkg is
    -- General parameters ---------------------------------------------------------------------------
        -- <EDIT> >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        -- Hardware version --
        constant HW_VERSION : string  := "0.1.0";
        constant HW_UID     : integer := 999_999_003;

        -- FPGA Architecture --
        constant FPGA_ARCH : fpga_arch_t := ZYNQMP; -- ZYNQMP | VERSAL

        -- Project path --
        constant PRJ_ROOT_PATH      : string  := "/home/rbeaubois/work/projects/sandbox/bench_dma_aer/";

        -- C++ header hardware config files for C++ app --
        constant H_HWCONFIG_DIRPATH : string  := PRJ_ROOT_PATH & "sw/target/app/src/hwconfig/include/";
        constant H_HWCONFIG_GEN     : boolean := false; -- true to generate files by refreshing hierarchy in vivado, false when synth

        -- System clocking --
        constant FREQUENCY_MHZ_CLOCK_PL  : real := sel_from_farch(FPGA_ARCH, (ZYNQMP=>400.0, VERSAL=>400.0));
        constant FREQUENCY_MHZ_CLOCK_AXI : real := sel_from_farch(FPGA_ARCH, (ZYNQMP=>200.0, VERSAL=>200.0));

        -- Export hardware config for C++ app --
        impure function gen_hwconfig_hfile(gen:boolean; dirpath:string; fname:string; farch:fpga_arch_t) return boolean;
        constant gen_status_hfile : boolean := gen_hwconfig_hfile( H_HWCONFIG_GEN, H_HWCONFIG_DIRPATH, "hwconfig_sys", FPGA_ARCH);
    -- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
end package system_pkg;

package body system_pkg is
    impure function gen_hwconfig_hfile(gen:boolean; dirpath:string; fname:string; farch:fpga_arch_t) return boolean is
        constant gen_sel   : boolean := gen_selector_hwconfig_hfile(gen, dirpath, fname);
        constant farch_str : string  := farch_to_str(farch);
        constant fpath     : string  := dirpath & farch_str & "/" & to_lowercase(fname & "_" & farch_str) & ".h";
        file fout          : text;
        variable fout_op   : file_open_status;
    begin
        if gen then
            -- Try to open file
            file_open(fout_op, fout, fpath, write_mode);
            
            if fout_op = OPEN_OK then
                -- Export notes >>>>>>>>
                futils_cpp_pkg.add_comment(fout, "*** Generated from: system_pkg.vhd ***");
                futils_cpp_pkg.add_blank_line(fout);
                -- <<<<<<<<<<<<<<<<<<<<<
    
                futils_cpp_pkg.add_include_guard_top(fout, fname & "_" & farch_str);
                futils_cpp_pkg.add_blank_line(fout);
    
                -- Export config >>>>>>>>
                futils_cpp_pkg.add_define(fout, "HW_VERSION",              HW_VERSION);
                futils_cpp_pkg.add_define(fout, "FREQUENCY_MHZ_CLOCK_PL",  FREQUENCY_MHZ_CLOCK_PL);
                futils_cpp_pkg.add_define(fout, "FREQUENCY_MHZ_CLOCK_AXI", FREQUENCY_MHZ_CLOCK_AXI);
                futils_cpp_pkg.add_blank_line(fout);
                -- <<<<<<<<<<<<<<<<<<<<<

                futils_cpp_pkg.add_include_guard_bot(fout);
                file_close(fout);
            else
                return false;
            end if;
        end if;

        return gen;
    end function;
end package body system_pkg;