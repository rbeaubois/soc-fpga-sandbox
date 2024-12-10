library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;

-- User dependencies
use work.fpga_arch_pkg.fpga_arch_t;
use work.fpga_arch_pkg.farch_to_str;
use work.fpga_arch_pkg.gen_selector_hwconfig_hfile;

use work.system_pkg.H_HWCONFIG_DIRPATH;
use work.system_pkg.H_HWCONFIG_GEN;
use work.system_pkg.FPGA_ARCH;

use work.futils_global_pkg.to_lowercase;
use work.futils_cpp_pkg;

package axidma_pkg is
    -- General parameters ---------------------------------------------------------------------------
        -- Stream from PS to PL
        constant DWIDTH_DMA_SPK_IN  : integer := 32;
        constant DEPTH_FIFO_SPK_IN  : integer := 1024; -- should match IP declaration <nat_fifo_spk_stream_from_ps_ip>
        constant DWIDTH_FIFO_SPK_IN : integer := 32;
        constant AWIDTH_FIFO_SPK_IN : integer := integer(ceil(log2(real(DEPTH_FIFO_SPK_IN))));

        -- Stream from PS to PL
        constant DWIDTH_DMA_SPK_MON  : integer := 32;
        constant DEPTH_FIFO_SPK_MON  : integer := 1024; -- should match IP declaration <nat_fifo_spk_stream_to_ps_ip>
        constant DWIDTH_FIFO_SPK_MON : integer := 32;
        constant AWIDTH_FIFO_SPK_MON : integer := integer(ceil(log2(real(DEPTH_FIFO_SPK_IN))));

        -- Stream from PL to PS
        type dma_opmode_t is record
            THRESHOLD: std_logic_vector(0 downto 0);
            PERIODIC : std_logic_vector(0 downto 0);
        end record dma_opmode_t;
        constant dma_opmode : dma_opmode_t := (THRESHOLD=>"0", PERIODIC=> "1");

        -- Export hardware config for C++ app --
        impure function gen_hwconfig_hfile(gen:boolean; dirpath:string; fname:string; farch:fpga_arch_t) return boolean;
        constant gen_status_hfile : boolean := gen_hwconfig_hfile( H_HWCONFIG_GEN, H_HWCONFIG_DIRPATH, "hwconfig_axidma", FPGA_ARCH);
end package axidma_pkg;

package body axidma_pkg is
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
                futils_cpp_pkg.add_comment(fout, "*** Generated from: axidma_pkg.vhd ***");
                futils_cpp_pkg.add_blank_line(fout);
                -- <<<<<<<<<<<<<<<<<<<<<
    
                futils_cpp_pkg.add_include_guard_top(fout, fname & "_" & farch_str);
                futils_cpp_pkg.add_blank_line(fout);
    
                -- Export config >>>>>>>>
                futils_cpp_pkg.add_comment(fout, "Coding DMA operations modes");
                futils_cpp_pkg.add_define(fout, "DMA_OPMODE_THREHSOLD", to_integer(unsigned(dma_opmode.THRESHOLD)));
                futils_cpp_pkg.add_define(fout, "DMA_OPMODE_PERIODIC",  to_integer(unsigned(dma_opmode.PERIODIC)));
                futils_cpp_pkg.add_blank_line(fout);

                futils_cpp_pkg.add_comment(fout, "Generics DMA PS send FIFO");
                futils_cpp_pkg.add_define(fout, "DEPTH_FIFO_SPK_IN",    DEPTH_FIFO_SPK_IN);
                futils_cpp_pkg.add_define(fout, "DWIDTH_FIFO_SPK_IN",   DWIDTH_FIFO_SPK_IN);
                futils_cpp_pkg.add_define(fout, "AWIDTH_FIFO_SPK_IN",   AWIDTH_FIFO_SPK_IN);
                futils_cpp_pkg.add_blank_line(fout);
        
                futils_cpp_pkg.add_comment(fout, "Generics DMA PS recv FIFO");
                futils_cpp_pkg.add_define(fout, "DEPTH_FIFO_SPK_MON",   DEPTH_FIFO_SPK_MON);
                futils_cpp_pkg.add_define(fout, "DWIDTH_FIFO_SPK_MON",  DWIDTH_FIFO_SPK_MON);
                futils_cpp_pkg.add_define(fout, "AWIDTH_FIFO_SPK_MON",  AWIDTH_FIFO_SPK_MON);
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
end package body axidma_pkg;