--!	@title		Double flip-flop synchro with asynchronous rst
--!	@file		dff_sync_arst.vhd
--!	@author     Romain Beaubois
--!	@date		12 Nov 2021
--!	@version	0.1
--!	@copyright
--! SPDX-FileCopyrightText: © 2021 Romain Beaubois <refbeaubois@yahoo.com>
--! SPDX-License-Identifier: GPL-3.0-or-later
--!
--! @brief Double flip-flop synchro with asynchronous rst
--! 
--! @details 
--! > **12 Nov 2021** : file creation (RB)

library ieee;
use ieee.std_logic_1164.all;

entity dff_sync_arst is
    generic (
        DATAWIDTH   : integer
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        din         : in  std_logic_vector(DATAWIDTH-1 downto 0);
        dout        : out std_logic_vector(DATAWIDTH-1 downto 0)
    );
end entity dff_sync_arst;

architecture rtl of dff_sync_arst is
    signal ff1 : std_logic_vector(DATAWIDTH-1 downto 0) := (others => '0'); --! First flip-flop (metastable output)
    signal ff2 : std_logic_vector(DATAWIDTH-1 downto 0) := (others => '0'); --! Second flip-flop (stable output)
begin
    --! Module output as second flip-flop output
    dout <= ff2;

    --! Double flip flop data
    process (clk, rst) begin
        if rst = '1' then
            ff1 <= (others => '0');
            ff2 <= (others => '0');
        elsif rising_edge(clk) then
            ff1 <= din;
            ff2 <= ff1;
        end if;
    end process;
end architecture rtl;