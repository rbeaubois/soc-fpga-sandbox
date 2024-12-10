--!	@title		AXI-Lite register mapper
--!	@file		axilite_mapper_pkg.vhd
--!	@author		Romain Beaubois
--!	@date		24 Oct 2024
--!	@copyright
--! SPDX-FileCopyrightText: © 2024 Romain Beaubois <refbeaubois@yahoo.com>
--! SPDX-License-Identifier: MIT
--! 
--! @brief Associate register index to label and write in .h config file
--! /!\ Always start by adding PS write registers then PS read registers
--! /!\ The mapper is from PS pov
--!
--! I tried different handling (protected, strings, enum,  ...) but they
--! turned out to be really slow when synthetizing (Quartus do much better 
--! than Vivado though) and actually add extensive amount of code to handle 
--! the poor support of unconstrained string with VHDL.
--!
--! Another solution considered was to use Python with a GUI to generate the module.
--! Overall good option but adds extra python sources + extensive amount of code
--! to make your GUI somewhat acceptable (checks, usability, edits, custom cases ...).
--! 
--! In the end, this solutions is the most """user friendly""" for a HDL design flow.
--! 
--! @details 
--! > **10 Oct 2024** : file creation (RB)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;

use work.futils_cpp_pkg;
use work.fpga_arch_pkg.gen_selector_hwconfig_hfile;

package axilite_mapper_pkg is
    constant MAX_NB_REGS_AXIL : integer := 512;
    constant MAX_DWIDTH_AXIL  : integer :=  32;
    constant MAX_AWIDTH_AXIL  : integer :=  16;

    type axl_mapper_t is protected
        impure function init(max_nb_regs:integer; gen:boolean; cname:string; dirpath:string; fname:string; fpga_arch:string) return boolean;
        impure function add_ps_write_register(reg_label:string; nb_regs:integer) return integer;
        impure function add_ps_read_register(reg_label:string; nb_regs:integer) return integer;
        impure function add_bit_label(bit_label:string; reg_index:integer) return integer;
        impure function add_comment(comment:string) return boolean;
        impure function add_comment(comment:string; add_blank_line:boolean) return boolean;
        impure function get_nb_regs return integer;
        impure function get_nb_regr return integer;
        impure function get_nb_regw return integer;
        impure function get_data_width return integer;
        impure function get_addr_width return integer;
        impure function get_opt_mem_bits return integer;
        impure function close return boolean;
    end protected axl_mapper_t;
end package axilite_mapper_pkg;

package body axilite_mapper_pkg is
    type axl_mapper_t is protected body
        -- =============
        -- Private members
        -- =============
        type reg_bit_t is array(0 to MAX_NB_REGS_AXIL-1) of std_logic_vector(0 to MAX_NB_REGS_AXIL-1);

        constant MAX_CHAR : integer := 256;
        subtype cstring_t      is string(1 to MAX_CHAR);
        subtype cstring_len_t  is integer range 1 to MAX_CHAR;

        file fout                  : text;
        variable this_fout_op      : file_open_status;
        
        variable this_gen          : boolean   := false;
        variable this_fpath        : cstring_t := (others => NUL);
        variable this_fname        : cstring_t := (others => NUL);
        variable this_cname        : cstring_t := (others => NUL);
        variable this_fpath_len    : cstring_len_t;
        variable this_fname_len    : cstring_len_t;
        variable this_cname_len    : cstring_len_t;
        variable this_done         : boolean   := false;
        
        variable this_nb_regs      : integer := 0;
        variable this_nb_regr      : integer := 0;
        variable this_nb_regw      : integer := 0;

        variable this_max_nb_regs  : integer := 0;
        constant this_datawidth    : integer := MAX_DWIDTH_AXIL;
        variable this_addrwidth    : integer := 0;
        variable this_opt_mem_bits : integer := 0;

        variable this_reg_bits     : reg_bit_t := (others => (others => '1'));

        -- =============
        -- Private methods
        -- =============
        --! Report warning if file can't be open
        procedure report_err_get_nb_regs(done:boolean) is
        begin
            assert done
            report "Number of registers accessed before mapping is done"
            severity failure;
        end procedure report_err_get_nb_regs;

        --! Report warning if file can't be open
        procedure report_err_fopen(f_status:file_open_status) is
        begin
            assert f_status = OPEN_OK
            report "Can't open file for axilite hwconfig: " & this_fpath
            severity warning;
        end procedure report_err_fopen;

        --! Append a define to file
        procedure append_comment(comment:string; add_blank_line:boolean) is
        begin
            if this_gen then            
                file_open(this_fout_op, fout, this_fpath, APPEND_MODE);
                report_err_fopen(this_fout_op);

                if this_fout_op = OPEN_OK then
                    if add_blank_line then
                        futils_cpp_pkg.add_blank_line(fout);
                    end if;
                    futils_cpp_pkg.add_comment(fout, comment);
                    file_close(fout);
                end if;
            end if;
        end procedure append_comment;

        --! Append a define to file
        procedure append_define(reg_label:string; reg_index:integer) is
        begin
            if this_gen then            
                file_open(this_fout_op, fout, this_fpath, APPEND_MODE);
                report_err_fopen(this_fout_op);

                if this_fout_op = OPEN_OK then
                    futils_cpp_pkg.add_define(fout, reg_label, reg_index);
                    file_close(fout);
                end if;
            end if;
        end procedure append_define;

        function set_awidth(max_nb_regs: integer) return integer is
            type integer_array_t is array(0 to 7) of integer;
            constant NREGS : integer_array_t := (4, 8, 16, 32, 64, 128, 256, 512);
            constant SIZE  : integer_array_t := (4, 5,  6,  7,  8,  9,   10,  11);
        begin
            for I in 0 to NREGS'length-1 loop
                if max_nb_regs <= NREGS(I) then
                    return SIZE(I);
                end if;
            end loop;
            return 0;
        end function;
    
        function set_optmem_bits(max_nb_regs: integer) return integer is
            type integer_array_t is array(0 to 7) of integer;
            constant NREGS : integer_array_t := (4, 8, 16, 32, 64, 128, 256, 512);
            constant SIZE  : integer_array_t := (1, 2,  3,  4,  5,   6,   7,   8);
        begin
            for I in 0 to NREGS'length-1 loop
                if max_nb_regs <= NREGS(I) then
                    return SIZE(I);
                end if;
            end loop;
            return 0;
        end function;

        -- =============
        -- Public methods
        -- =============
        --! Initialize export file
        impure function init(max_nb_regs:integer; gen:boolean; cname:string; dirpath:string; fname:string; fpga_arch:string) return boolean is
            constant gen_sel : boolean := gen_selector_hwconfig_hfile(gen, dirpath, fname & "_" & cname);
            constant fpath   : string := dirpath & fpga_arch & "/" & fname & "_" & cname & "_" & fpga_arch & ".h";
        begin
            assert max_nb_regs <= MAX_NB_REGS_AXIL
            report integer'image(max_nb_regs) & "registers specified for " & cname & "exceed max: " & integer'image(MAX_NB_REGS_AXIL)
            severity failure;
            this_max_nb_regs := max_nb_regs;

            this_addrwidth    := set_awidth(max_nb_regs);
            this_opt_mem_bits := set_optmem_bits(max_nb_regs);
            
            this_gen  := gen;
            this_done := false;

            this_fpath(fpath'range) := fpath;
            this_fname(fname'range) := fname;
            this_cname(cname'range) := cname;

            this_fpath_len := fpath'length;
            this_fname_len := fname'length;
            this_cname_len := cname'length;

            this_nb_regs  := 0;
            this_nb_regr  := 0;
            this_nb_regw  := 0;
            this_reg_bits := (others => (others => '1'));
            
            if gen then
                file_open(this_fout_op, fout, this_fpath, WRITE_MODE);
                report_err_fopen(this_fout_op);

                if this_fout_op = OPEN_OK then
                    futils_cpp_pkg.add_comment(fout, "*** Generated from: axilite_mapper_pkg.vhd ***");
                    futils_cpp_pkg.add_comment(fout, "*** Mapping AXI-Lite core: " & this_cname(1 to this_cname_len)  & " ***");
                    futils_cpp_pkg.add_blank_line(fout);

                    futils_cpp_pkg.add_include_guard_top(fout, this_fname(1 to this_fname_len) & "_" &this_cname(1 to this_cname_len) & '_' & fpga_arch);
                    futils_cpp_pkg.add_blank_line(fout);

                    futils_cpp_pkg.add_comment(fout, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
                    futils_cpp_pkg.add_comment(fout, "Registers mapping");
                    futils_cpp_pkg.add_comment(fout, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");

                    file_close(fout);
                    return true;
                end if;
            end if;

            return false;
        end function;
        
        --! Add ps write register: update index and write in hwconfig file
        impure function add_ps_write_register(reg_label:string; nb_regs:integer) return integer is
            constant reg_index : integer := this_nb_regw;
        begin
            append_define(reg_label, reg_index);
            this_nb_regw := this_nb_regw + nb_regs;
            this_nb_regs := this_nb_regs + nb_regs;
            return reg_index;
        end function;
        
        --! Add ps read register: update index and write in hwconfig file
        impure function add_ps_read_register(reg_label:string; nb_regs:integer) return integer is
            constant reg_index : integer := this_nb_regr;
        begin
            append_define(reg_label, reg_index + this_nb_regw);
            this_nb_regr := this_nb_regr + nb_regs;
            this_nb_regs := this_nb_regs + nb_regs;
            return reg_index;
        end function;

        impure function add_bit_label(bit_label:string; reg_index:integer) return integer is
            variable bit_index : integer range 0 to MAX_NB_REGS_AXIL-1;
            variable bind      : boolean := false;
        begin
            for i in 0 to MAX_NB_REGS_AXIL-1 loop
                if this_reg_bits(reg_index)(i) = '1' then
                    bit_index := i;
                    this_reg_bits(reg_index)(i) := '0';
                    bind := true;
                    exit;
                end if;
            end loop;

            assert bind
            report "Can't add " & bit_label & ": maximum number of bit labels reached." 
            severity warning;
            
            if bind then
                append_define(bit_label, bit_index);
            end if;

            return bit_index;
        end function;

        --! Add comment in hwconfig file
        impure function add_comment(comment:string) return boolean is
            constant add_blank_line : boolean := true;
        begin
            append_comment(comment, add_blank_line);
            return true;
        end function;

        --! Add comment in hwconfig file
        impure function add_comment(comment:string; add_blank_line:boolean) return boolean is
        begin
            append_comment(comment, add_blank_line);
            return true;
        end function;
        
        --! Close file
        impure function close return boolean is
            variable status_gen : boolean := false;
        begin
            if this_gen then
                file_open(this_fout_op, fout, this_fpath, APPEND_MODE);
                report_err_fopen(this_fout_op);

                if this_fout_op = OPEN_OK then
                    futils_cpp_pkg.add_blank_line(fout);
                    futils_cpp_pkg.add_comment(fout, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
                    futils_cpp_pkg.add_comment(fout, "Number of registers");
                    futils_cpp_pkg.add_comment(fout, "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
                    futils_cpp_pkg.add_blank_line(fout);

                    futils_cpp_pkg.add_define(fout, "NB_REGS",          this_nb_regs);
                    futils_cpp_pkg.add_define(fout, "NB_PS_WRITE_REGS", this_nb_regw);
                    futils_cpp_pkg.add_define(fout, "NB_PS_READ_REGS",  this_nb_regr);
                    futils_cpp_pkg.add_blank_line(fout);

                    futils_cpp_pkg.add_include_guard_bot(fout);
                    file_close(fout);
                    status_gen := true;
                end if;
            end if;

            assert this_max_nb_regs >= this_max_nb_regs
            report "(" & this_cname & "): specified max nb of registers exceeded, please update MAX_NB_REGS" 
            severity failure;

            this_done := true;
            return status_gen;
        end function;

        --! Get total number of registers
        impure function get_nb_regs return integer is
        begin
            report_err_get_nb_regs(this_done);
            return this_nb_regs;
        end function;
        
        --! Get number of PS read registers
        impure function get_nb_regr return integer is
        begin
            report_err_get_nb_regs(this_done);
            return this_nb_regr;
        end function;
        
        --! Get number of PS write registers
        impure function get_nb_regw return integer is
        begin
            report_err_get_nb_regs(this_done);
            return this_nb_regw;
        end function;

        --! Get data width
        impure function get_data_width return integer is
        begin
            return this_datawidth;
        end function;

        --! Return address width
        impure function get_addr_width return integer is
        begin
            return this_addrwidth;
        end function;

        --! Return opt mem bits
        impure function get_opt_mem_bits return integer is
        begin
            return this_opt_mem_bits;
        end function;

    end protected body axl_mapper_t;

end package body axilite_mapper_pkg;

