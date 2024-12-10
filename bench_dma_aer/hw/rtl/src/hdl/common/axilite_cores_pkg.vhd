--!	@title		AXI-Lite cores
--!	@file		axilite_cores_pkg.vhd
--!	@author		Romain Beaubois
--!	@date		24 Oct 2024
--!	@copyright
--! SPDX-FileCopyrightText: © 2024 Romain Beaubois <refbeaubois@yahoo.com>
--! SPDX-License-Identifier: MIT
--! 
--! @brief Define mapping of axilite cores in the design
--! /!\ Always start by PS WRITE registers before PS READ registers
--!
--! At first glance it looks super verbose but it's mainly
--! copy pasta, linter checks for duplicate and you get autocompletion
--!
--! 1 core = 1 package so you can copy pasta without worrying about
--! changing variables names
--! 
--! If you want to reuse, just remove user dependencies and
--! associated variables/constants/types
--! 
--! @details 
--! > **10 Oct 2024** : file creation (RB)

---------------------------------------------------------------------------------------
--                                                                                     
--   ██████  ██████  ███    ██ ████████ ██████   ██████  ██      
--  ██      ██    ██ ████   ██    ██    ██   ██ ██    ██ ██      
--  ██      ██    ██ ██ ██  ██    ██    ██████  ██    ██ ██      
--  ██      ██    ██ ██  ██ ██    ██    ██   ██ ██    ██ ██      
--   ██████  ██████  ██   ████    ██    ██   ██  ██████  ███████ 
--                                                               
-- AXI-Lite core: control
---------------------------------------------------------------------------------------
-- Standard
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- AXI-Lite mapper object
use work.axilite_mapper_pkg.axl_mapper_t;

-- User dependencies
use work.system_pkg.H_HWCONFIG_DIRPATH;
use work.system_pkg.H_HWCONFIG_GEN;
use work.system_pkg.FPGA_ARCH;
use work.fpga_arch_pkg.farch_to_str;

package axlmap_control is
    subtype int16_t is integer range 0 to 2**16-1;
    type axl_map_t is record
        -- Generics
        NB_REGS      : int16_t;
        NB_PS_REGW   : int16_t;
        NB_PS_REGR   : int16_t;

        DWIDTH       : int16_t;
        AWIDTH       : int16_t;
        OPT_MEM_BITS : int16_t;

        -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        -- PS Write registers
        REGW_CONTROL                      : int16_t; -- Enable, reset, ...
        REGW_INTR_THRESH_FREE_SLOTS_TO_PL : int16_t; -- Set threhsold for interrupt FREE_SLOTS_TO_PL
        REGW_INTR_THRESH_READY_EV_TO_PS   : int16_t; -- Set threhsold for interrupt READY_EV_TO_PS

        -- PS Read registers
        REGR_HW_UID  : int16_t;

        -- Bit labels
        BIT_RESET_REGW_CONTROL               : int16_t;
        BIT_EN_CORE_REGW_CONTROL             : int16_t;
        BIT_OPMODE_RECV_DMA_SPK_REGW_CONTROL : int16_t;
        BIT_OPMODE_SEND_DMA_SPK_REGW_CONTROL : int16_t;
        -- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    end record axl_map_t;

    impure function map_axilite_regs return axl_map_t;
    constant axlmap : axl_map_t := map_axilite_regs;
end package axlmap_control;

package body axlmap_control is
    impure function map_axilite_regs return axl_map_t is
        variable axlmapper : axl_mapper_t;
        variable axlmap    : axl_map_t;
        variable r         : boolean;
    begin
        -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        -- (1) Initialize
        r := axlmapper.init( max_nb_regs => 4,
                             gen         => H_HWCONFIG_GEN,
                             cname       => "control",
                             dirpath     => H_HWCONFIG_DIRPATH,
                             fname       => "hwconfig_axil",
                             fpga_arch   => farch_to_str(FPGA_ARCH)
                            );
        axlmap.DWIDTH       := axlmapper.get_data_width;   -- DON'T TOUCH
        axlmap.AWIDTH       := axlmapper.get_addr_width;   -- DON'T TOUCH
        axlmap.OPT_MEM_BITS := axlmapper.get_opt_mem_bits; -- DON'T TOUCH
    
        -- (2) Registers written by PS
        r := axlmapper.add_comment("Index registers written by PS"); -- DON'T TOUCH
        axlmap.REGW_CONTROL                      := axlmapper.add_ps_write_register("REGW_CONTROL", 1);
        axlmap.REGW_INTR_THRESH_FREE_SLOTS_TO_PL := axlmapper.add_ps_write_register("REGW_INTR_THRESH_FREE_SLOTS_TO_PL", 1);
        axlmap.REGW_INTR_THRESH_READY_EV_TO_PS   := axlmapper.add_ps_write_register("REGW_INTR_THRESH_READY_EV_TO_PS",   1);
    
        -- (3) Registers read by PS
        r := axlmapper.add_comment("Index registers read by PS"); -- DON'T TOUCH
        axlmap.REGR_HW_UID        := axlmapper.add_ps_read_register("REGR_HW_UID", 1);
    
        -- (4) Bit labels PS write registers
        r := axlmapper.add_comment("Bit labels PS write registers"); -- DON'T TOUCH
        axlmap.BIT_RESET_REGW_CONTROL               := axlmapper.add_bit_label("BIT_RESET_REGW_CONTROL",               axlmap.REGW_CONTROL);
        axlmap.BIT_EN_CORE_REGW_CONTROL             := axlmapper.add_bit_label("BIT_EN_CORE_REGW_CONTROL",             axlmap.REGW_CONTROL);
        axlmap.BIT_OPMODE_RECV_DMA_SPK_REGW_CONTROL := axlmapper.add_bit_label("BIT_OPMODE_RECV_DMA_SPK_REGW_CONTROL", axlmap.REGW_CONTROL);
        axlmap.BIT_OPMODE_SEND_DMA_SPK_REGW_CONTROL := axlmapper.add_bit_label("BIT_OPMODE_SEND_DMA_SPK_REGW_CONTROL", axlmap.REGW_CONTROL);
    
        -- (5) Bit labels PS read  registers
        r := axlmapper.add_comment("Bit labels PS read registers"); -- DON'T TOUCH
        -- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

        r := axlmapper.close;
    
        -- Extract number of registers
        axlmap.NB_REGS    := axlmapper.get_nb_regs;
        axlmap.NB_PS_REGW := axlmapper.get_nb_regw;
        axlmap.NB_PS_REGR := axlmapper.get_nb_regr;

        return axlmap;
    end function map_axilite_regs;
end package body axlmap_control;
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
--                                                                                     
--  ███████ ████████  █████  ████████ ██    ██ ███████ 
--  ██         ██    ██   ██    ██    ██    ██ ██      
--  ███████    ██    ███████    ██    ██    ██ ███████ 
--       ██    ██    ██   ██    ██    ██    ██      ██ 
--  ███████    ██    ██   ██    ██     ██████  ███████ 
--                                                     
-- AXI-Lite core: status
---------------------------------------------------------------------------------------
-- Standard
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- AXI-Lite mapper object
use work.axilite_mapper_pkg.axl_mapper_t;

-- User dependencies
use work.system_pkg.H_HWCONFIG_DIRPATH;
use work.system_pkg.H_HWCONFIG_GEN;
use work.system_pkg.FPGA_ARCH;
use work.fpga_arch_pkg.farch_to_str;

package axlmap_status is
    subtype int16_t is integer range 0 to 2**16-1;
    type axl_map_t is record
        -- Generics
        NB_REGS      : int16_t;
        NB_PS_REGW   : int16_t;
        NB_PS_REGR   : int16_t;

        DWIDTH       : int16_t;
        AWIDTH       : int16_t;
        OPT_MEM_BITS : int16_t;

        -- User generics
        NB_DUMMY_REGS : int16_t;

        -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        -- PS Write registers
        REGW_DUMMY_BASE : int16_t;

        -- PS Read registers
        REGR_DUMMY_BASE_LB : int16_t;

        -- Bit labels
        -- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    end record axl_map_t;

    impure function map_axilite_regs return axl_map_t;
    constant axlmap : axl_map_t := map_axilite_regs;
end package axlmap_status;

package body axlmap_status is
    impure function map_axilite_regs return axl_map_t is
        variable axlmapper : axl_mapper_t;
        variable axlmap    : axl_map_t;
        variable r         : boolean;
    begin
        -- >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
        -- (1) Initialize
        axlmap.NB_DUMMY_REGS := 4;
        r := axlmapper.init( max_nb_regs => axlmap.NB_DUMMY_REGS*2,
                             gen         => H_HWCONFIG_GEN,
                             cname       => "status",
                             dirpath     => H_HWCONFIG_DIRPATH,
                             fname       => "hwconfig_axil",
                             fpga_arch   => farch_to_str(FPGA_ARCH)
                            );
        axlmap.DWIDTH       := axlmapper.get_data_width;   -- DON'T TOUCH
        axlmap.AWIDTH       := axlmapper.get_addr_width;   -- DON'T TOUCH
        axlmap.OPT_MEM_BITS := axlmapper.get_opt_mem_bits; -- DON'T TOUCH
    
        -- (2) Registers written by PS
        r := axlmapper.add_comment("Index registers written by PS"); -- DON'T TOUCH
    
        -- (3) Registers read by PS
        r := axlmapper.add_comment("Index registers read by PS"); -- DON'T TOUCH
        axlmap.REGW_DUMMY_BASE := axlmapper.add_ps_read_register("REGW_DUMMY_BASE", axlmap.NB_DUMMY_REGS);
    
        -- (4) Bit labels PS write registers
        r := axlmapper.add_comment("Bit labels PS write registers"); -- DON'T TOUCH
        axlmap.REGR_DUMMY_BASE_LB := axlmapper.add_ps_write_register("REGR_DUMMY_BASE_LB", axlmap.NB_DUMMY_REGS);
    
        -- (5) Bit labels PS read  registers
        r := axlmapper.add_comment("Bit labels PS read registers"); -- DON'T TOUCH
        -- <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

        r := axlmapper.close;
    
        -- Extract number of registers
        axlmap.NB_REGS    := axlmapper.get_nb_regs;
        axlmap.NB_PS_REGW := axlmapper.get_nb_regw;
        axlmap.NB_PS_REGR := axlmapper.get_nb_regr;

        return axlmap;
    end function map_axilite_regs;
end package body axlmap_status;
---------------------------------------------------------------------------------------