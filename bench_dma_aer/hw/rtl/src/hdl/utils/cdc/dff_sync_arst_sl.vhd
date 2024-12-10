--!	@title		Double flip-flop synchro with asynchronous rst for std logic
--!	@file		dff_sync_arst_sl.vhd
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

entity dff_sync_arst_sl is
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        din         : in  std_logic;
        dout        : out std_logic
    );
end entity dff_sync_arst_sl;

architecture rtl of dff_sync_arst_sl is
    signal ff1 : std_logic := '0'; --! First flip-flop (metastable output)
    signal ff2 : std_logic := '0'; --! Second flip-flop (stable output)
begin
    --! Module output as second flip-flop output
    dout <= ff2;

    --! Double flip flop data
    process (clk, rst) begin
        if rst = '1' then
            ff1 <= '0';
            ff2 <= '0';
        elsif rising_edge(clk) then
            ff1 <= din;
            ff2 <= ff1;
        end if;
    end process;
end architecture rtl;