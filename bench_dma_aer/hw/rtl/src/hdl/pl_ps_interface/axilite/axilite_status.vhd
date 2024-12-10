--! @title		Axi lite communication for mhh calculation core
--! @file		axilite_control.vhd
--! @author		Romain Beaubois
--! @date		07 Feb 2022
--! @copyright
--! SPDX-FileCopyrightText: © 2018 Xilinx
--! SPDX-FileCopyrightText: © 2022 Romain Beaubois <refbeaubois@yahoo.com>
--! SPDX-License-Identifier: MIT
--!
--! @brief Wrapper Generic axilite wrapper inspired from Xilinx AXI IP generator
--! * Part to edit labeled with <EDIT>
--! (1) Declare package to use
--! (2) Declare generics
--! (3) Declare ports
--! (4) Map signals
--!
--! WARNING: Ensure that Vivado Adress Editor allocates 64k
--! 
--! @details
--! > **18 Nov 2024** : updated from Vivado 2024.1 AXI-Lite IP generation (RB)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.axilite_mapper_pkg.MAX_NB_REGS_AXIL;
use work.axilite_mapper_pkg.MAX_DWIDTH_AXIL;
use work.axilite_mapper_pkg.MAX_AWIDTH_AXIL;

-- <EDIT> (1) Declare package to use
-- ####################################################
use work.axlmap_status.axlmap;
-- ####################################################

entity axilite_status is
	generic (
        -- <EDIT> (2) User generic parameters
		-- ####################################################
		-- ####################################################

        C_S_AXI_DATA_WIDTH	: integer := MAX_DWIDTH_AXIL;
		C_S_AXI_ADDR_WIDTH	: integer := MAX_AWIDTH_AXIL;

        OPT_MEM_ADDR_BITS   : integer := axlmap.OPT_MEM_BITS;
        NB_PL_READ_REGS     : integer := axlmap.NB_PS_REGW;
        NB_PL_WRITE_REGS    : integer := axlmap.NB_PS_REGR
	);
	port (
        -- <EDIT> (3) User ports
		-- ####################################################
		-- From PS
            --
		-- To PS
            --
		-- ####################################################
		S_AXI_ACLK    : in std_logic;
		S_AXI_ARESETN : in std_logic;
		S_AXI_AWADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT  : in std_logic_vector(2 downto 0);
		S_AXI_AWVALID : in std_logic;
		S_AXI_AWREADY : out std_logic;
		S_AXI_WDATA   : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB   : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID  : in std_logic;
		S_AXI_WREADY  : out std_logic;
		S_AXI_BRESP   : out std_logic_vector(1 downto 0);
		S_AXI_BVALID  : out std_logic;
		S_AXI_BREADY  : in std_logic;
		S_AXI_ARADDR  : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT  : in std_logic_vector(2 downto 0);
		S_AXI_ARVALID : in std_logic;
		S_AXI_ARREADY : out std_logic;
		S_AXI_RDATA   : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP   : out std_logic_vector(1 downto 0);
		S_AXI_RVALID  : out std_logic;
		S_AXI_RREADY  : in std_logic
	);
end axilite_status;

architecture arch_imp of axilite_status is
	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 512
    type slv_regs_t is array(integer range <>) of std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
    signal slv_regr : slv_regs_t(0 to NB_PL_READ_REGS-1)  := (others => (others => '0'));
    signal slv_regw : slv_regs_t(0 to NB_PL_WRITE_REGS-1) := (others => (others => '0'));

	signal mem_logic    : std_logic_vector(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

    type fsm_axilite_slave_write_t is (IDLE, WADDR, WDATA);
    type fsm_axilite_slave_read_t  is (IDLE, RADDR, RDATA);
	signal state_read : fsm_axilite_slave_read_t  := IDLE;
	signal state_write: fsm_axilite_slave_write_t := IDLE;
begin    
	-- I/O Connections assignments
	S_AXI_AWREADY <= axi_awready;
	S_AXI_WREADY  <= axi_wready;
	S_AXI_BRESP   <= axi_bresp;
	S_AXI_BVALID  <= axi_bvalid;
	S_AXI_ARREADY <= axi_arready;
	S_AXI_RRESP   <= axi_rresp;
	S_AXI_RVALID  <= axi_rvalid;
	mem_logic     <= S_AXI_AWADDR(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB) when (S_AXI_AWVALID = '1') else axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);

	-- Implement Write state machine
	-- Outstanding write transactions are not supported by the slave i.e., master should assert bready to receive response on or before it starts sending the new transaction
    fsm_write_axilite: process (S_AXI_ACLK)
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                --asserting initial values to all 0's during reset
                axi_awready <= '0';
                axi_wready  <= '0';
                axi_bvalid  <= '0';
                axi_bresp   <= (others => '0');
                state_write <= IDLE;
            else
                case (state_write) is
                    when IDLE =>		--Initial state inidicating reset is done and ready to receive read/write transactions
                        if (S_AXI_ARESETN = '1') then
                            axi_awready <= '1';
                            axi_wready <= '1';
                            state_write <= WADDR;
                        else 
                            state_write <= state_write;
                        end if;

                    when WADDR =>		--At this state, slave is ready to receive address along with corresponding control signals and first data packet. Response valid is also handled at this state
                        if (S_AXI_AWVALID = '1' and axi_awready = '1') then
                            axi_awaddr <= S_AXI_AWADDR(axi_awaddr'length-1 downto 0);
                            if (S_AXI_WVALID = '1') then
                                axi_awready <= '1';
                                state_write <= WADDR;
                                axi_bvalid <= '1';
                            else
                                axi_awready <= '0';
                                state_write <= WDATA;
                            
                                if (S_AXI_BREADY = '1' and axi_bvalid = '1') then
                                    axi_bvalid <= '0';
                                end if;                    
                            end if;
                        else
                            state_write <= state_write;
                            if (S_AXI_BREADY = '1' and axi_bvalid = '1') then
                                axi_bvalid <= '0';
                            end if;
                        end if;

                    when WDATA =>		--At this state, slave is ready to receive the data packets until the number of transfers is equal to burst length
                        if (S_AXI_WVALID = '1') then
                            state_write <= WADDR;
                            axi_bvalid <= '1';
                            axi_awready <= '1';
                        else
                            state_write <= state_write;
                            if (S_AXI_BREADY ='1' and axi_bvalid = '1') then
                                axi_bvalid <= '0';
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process fsm_write_axilite;
                               
	-- Implement memory mapped register select and write logic generation
	map_axil_wdata: process (S_AXI_ACLK)
	begin
        if rising_edge(S_AXI_ACLK) then 
            if S_AXI_ARESETN = '0' then
                slv_regr <= (others => (others => '0'));
            else
                if (S_AXI_WVALID = '1') then
                    for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
                        if ( S_AXI_WSTRB(byte_index) = '1' ) then
                            slv_regr(to_integer(unsigned(mem_logic)))(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
                        end if;
                    end loop;
                end if;
            end if;
        end if;
	end process map_axil_wdata;

	-- Implement read state machine
    fsm_read_axilite: process (S_AXI_ACLK)                                          
    begin
        if rising_edge(S_AXI_ACLK) then
            if S_AXI_ARESETN = '0' then
                --asserting initial values to all 0's during reset
                axi_arready <= '0';
                axi_rvalid <= '0';
                axi_rresp <= (others => '0');
                state_read <= IDLE;
            else
                case (state_read) is
                    when IDLE =>		--Initial state inidicating reset is done and ready to receive read/write transactions
                        if (S_AXI_ARESETN = '1') then
                            axi_arready <= '1';
                            state_read <= RADDR;
                        else 
                            state_read <= state_read;
                        end if;

                    when RADDR =>		--At this state, slave is ready to receive address along with corresponding control signals
                        if (S_AXI_ARVALID = '1' and axi_arready = '1') then
                            state_read <= RDATA;
                            axi_rvalid <= '1';
                            axi_arready <= '0';
                            axi_araddr <= S_AXI_ARADDR(axi_araddr'length-1 downto 0);
                        else
                            state_read <= state_read;
                        end if;

                    when RDATA =>		--At this state, slave is ready to send the data packets until the number of transfers is equal to burst length
                        if (axi_rvalid = '1' and S_AXI_RREADY = '1') then
                            axi_rvalid <= '0';
                            axi_arready <= '1';
                            state_read <= RADDR;
                        else
                            state_read <= state_read;
                        end if;
                end case;
            end if;
        end if;
    end process fsm_read_axilite;

	-- Implement memory mapped register select and read logic generation
    map_axil_rdata : process(axi_araddr, slv_regr, slv_regw) is
        variable loc_addr : unsigned(OPT_MEM_ADDR_BITS downto 0);
    begin
        loc_addr := unsigned(axi_araddr(ADDR_LSB+OPT_MEM_ADDR_BITS downto ADDR_LSB));
        S_AXI_RDATA <= slv_regr(to_integer(loc_addr))                 when loc_addr < NB_PL_READ_REGS else
                       slv_regw(to_integer(loc_addr)-NB_PL_READ_REGS) when loc_addr < NB_PL_READ_REGS+NB_PL_WRITE_REGS else
                       ((others => '0'));
    end process map_axil_rdata;

    -- <EDIT> (4) Signal mapping
    -- ########################################################################################################
    map_registers: process (all)
        variable example_out_ports : slv_regs_t(0 to axlmap.NB_DUMMY_REGS-1);
    begin        
        --------------------------------------------------------------------------------------------------------------------------------
        --
        --  ███████ ██████   ██████  ███    ███     ██████  ███████ 
        --  ██      ██   ██ ██    ██ ████  ████     ██   ██ ██      
        --  █████   ██████  ██    ██ ██ ████ ██     ██████  ███████ 
        --  ██      ██   ██ ██    ██ ██  ██  ██     ██           ██ 
        --  ██      ██   ██  ██████  ██      ██     ██      ███████ 
        -- 
        --------------------------------------------------------------------------------------------------------------------------------
        for I in 0 to axlmap.NB_DUMMY_REGS-1 loop
            example_out_ports(I) := slv_regr(axlmap.REGW_DUMMY_BASE + I);
        end loop;

        --------------------------------------------------------------------------------------------------------------------------------
        --
        --  ████████  ██████      ██████  ███████ 
        --     ██    ██    ██     ██   ██ ██      
        --     ██    ██    ██     ██████  ███████ 
        --     ██    ██    ██     ██           ██ 
        --     ██     ██████      ██      ███████ 
        -- 
        --------------------------------------------------------------------------------------------------------------------------------
        for I in 0 to axlmap.NB_DUMMY_REGS-1 loop
            slv_regw(axlmap.REGR_DUMMY_BASE_LB + I) <= slv_regr(axlmap.REGW_DUMMY_BASE + I); -- directly from slv_regr for loopback makes more sense
        end loop;

    end process map_registers;
    -- ########################################################################################################
end arch_imp;