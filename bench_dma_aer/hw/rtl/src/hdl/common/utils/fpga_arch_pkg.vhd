--!	@title		FPGA architecture support
--!	@file		fpga_arch_prk.vhd
--!	@author		Romain Beaubois
--!	@date		26 Nov 2024
--!	@copyright
--! SPDX-FileCopyrightText: © 2024 Romain Beaubois <refbeaubois@yahoo.com>
--! SPDX-License-Identifier: MIT
--! 
--! @brief Package to handle generics and configurations files for different
--! FPGA architecture.
--! 
--! * Benefits:
--!     - Set generics for each architecture indepedently
--!     - Fool proof syntax (ARCH1=> val, ARCH2=> val)
--!     - Generate "top" config file for Makefile to select arch from define
--!
--! * Add new architecture:
--!     - Add a new architecture in fpga_arch_t
--!     - List it in SUPPORTED_FPGA_ARCH
--!     - Update your calls of sel_from_farch to add the new arch
--! 
--! @details 
--! > **26 Nov 2024** : file creation (RB)

library ieee;
use ieee.numeric_std.all;

use std.textio.all;
use work.futils_global_pkg.to_lowercase;
use work.futils_global_pkg.to_uppercase;
use work.futils_cpp_pkg;

package fpga_arch_pkg is
    -- FPGA architecture
    type fpga_arch_t is (
        ZYNQMP,
        VERSAL
        -- ARTIX,
        -- KINTEX,
        -- VIRTEX,
        -- ALVEO,
        -- AGILEX,
    );
    type supported_fpga_arch_t is array(integer range <>) of fpga_arch_t;
    constant SUPPORTED_FPGA_ARCH : supported_fpga_arch_t(0 to 1) := (ZYNQMP, VERSAL);
    type farch_to_int_map_t is array(fpga_arch_t)  of integer;
    type farch_to_bool_map_t is array(fpga_arch_t) of boolean;
    type farch_to_real_map_t is array(fpga_arch_t) of real;

    -- Makefile link
    constant MAKEFILE_FLAG_HW_ARCH : string := "HW_FPGA_ARCH";

    -- Functions to select parameters depending on the target architecture
    function sel_from_farch(farch:fpga_arch_t; farch_map:farch_to_int_map_t)  return integer;
    function sel_from_farch(farch:fpga_arch_t; farch_map:farch_to_bool_map_t) return boolean;
    function sel_from_farch(farch:fpga_arch_t; farch_map:farch_to_real_map_t) return real;
    function farch_to_str(farch:fpga_arch_t) return string;
    procedure report_unsupported_farch(farch:fpga_arch_t);
    impure function gen_selector_hwconfig_hfile(gen:boolean; dirpath:string; fname:string) return boolean;
end package fpga_arch_pkg;

package body fpga_arch_pkg is
    -- ==================
    -- Private functions
    -- ==================
    function is_farch_supported(farch:fpga_arch_t) return boolean is
    begin
        for i in 0 to SUPPORTED_FPGA_ARCH'length-1 loop
            if farch = SUPPORTED_FPGA_ARCH(i) then
               return true; 
            end if;            
        end loop;
        return false;
    end function;

    -- ==================
    -- Public functions
    -- ==================
    function sel_from_farch(farch:fpga_arch_t; farch_map:farch_to_int_map_t) return integer is
    begin
        if is_farch_supported(farch) then
            return farch_map(farch);
        else
            report_unsupported_farch(farch);
            return -1;
        end if;
    end;

    function sel_from_farch(farch:fpga_arch_t; farch_map:farch_to_bool_map_t) return boolean is
    begin
        if is_farch_supported(farch) then
            return farch_map(farch);
        else
            report_unsupported_farch(farch);
            return false;
        end if;
    end;

    function sel_from_farch(farch:fpga_arch_t; farch_map:farch_to_real_map_t) return real is
    begin        
        if is_farch_supported(farch) then
            return farch_map(farch);
        else
            report_unsupported_farch(farch);
            return -1.0;
        end if;
    end;

    function farch_to_str(farch:fpga_arch_t) return string is
    begin
        return to_lowercase(fpga_arch_t'image(farch));
    end function;

    procedure report_unsupported_farch(farch:fpga_arch_t) is
    begin
        report "Undefined FPGA architecture: " & fpga_arch_t'image(farch)
                & "Existing are listed in: fpga_arch_pkg.vhd > type fpga_arch_t"
        severity failure;
    end procedure report_unsupported_farch;

    impure function gen_selector_hwconfig_hfile(gen:boolean; dirpath:string; fname:string) return boolean is
        constant fpath         : string := dirpath & to_lowercase(fname) & ".h";
        file fout              : text;
        variable fout_op       : file_open_status;
        constant RELATIVE_PATH : boolean := true; -- relative path to folder (if makefile doesn't allow to see all include "in same directory")
    begin
        if gen then
            -- Try to open file
            file_open(fout_op, fout, fpath, write_mode);
            
            if fout_op = OPEN_OK then    
                futils_cpp_pkg.add_include_guard_top(fout, fname);
                futils_cpp_pkg.add_blank_line(fout);

                -- Generate case include for arch selected by Makefile
                for i in 0 to SUPPORTED_FPGA_ARCH'length-1 loop
                    if i = 0 then
                        futils_cpp_pkg.add_pragma_ifdef(fout, MAKEFILE_FLAG_HW_ARCH & "_" & to_uppercase(farch_to_str(SUPPORTED_FPGA_ARCH(0))));
                    else
                        futils_cpp_pkg.add_pragma_elifdef(fout, MAKEFILE_FLAG_HW_ARCH & "_" & to_uppercase(farch_to_str(SUPPORTED_FPGA_ARCH(i))));
                    end if;
                    if RELATIVE_PATH then
                        futils_cpp_pkg.add_include(fout, farch_to_str(SUPPORTED_FPGA_ARCH(i)) & "/" & to_lowercase(fname) & "_" & farch_to_str(SUPPORTED_FPGA_ARCH(i)), tab=>true);
                    else
                        futils_cpp_pkg.add_include(fout, to_lowercase(fname) & "_" & farch_to_str(SUPPORTED_FPGA_ARCH(i)), tab=>true);
                    end if;
                end loop;
                -- Generate default architecture
                futils_cpp_pkg.add_pragma_else(fout);
                if RELATIVE_PATH then
                    futils_cpp_pkg.add_include(fout, farch_to_str(SUPPORTED_FPGA_ARCH(0)) & "/" & to_lowercase(fname) & "_" & farch_to_str(SUPPORTED_FPGA_ARCH(0)), tab=>true);
                else
                    futils_cpp_pkg.add_include(fout, to_lowercase(fname) & "_" & farch_to_str(SUPPORTED_FPGA_ARCH(0)), tab=>true);
                end if;
                futils_cpp_pkg.add_pragma_endif(fout);
                futils_cpp_pkg.add_blank_line(fout);

                futils_cpp_pkg.add_include_guard_bot(fout);
                file_close(fout);
            else
                return false;
            end if;
        end if;

        return gen;
    end function;
    
end package body fpga_arch_pkg;