--! @title     Trigger pulse once from constant
--! @file      trig_pulse_once_const.vhd
--! @author    Romain Beaubois
--! @date      15 Aug 2022
--! @copyright
--! SPDX-FileCopyrightText: © 2022 Romain Beaubois <refbeaubois@yahoo.com>
--! SPDX-License-Identifier: GPL-3.0-or-later
--!
--! @brief Trigger pulse once from constant
--! 
--! @details 
--! > **15 Aug 2022** : file creation (RB)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity trig_pulse_once_const is
    Generic(
        WIDTH_CCY   : integer           --! Period in ccy
    );
    Port ( 
        clk         : in  std_logic;    --! Clock
        rst         : in  std_logic;    --! Reset (active high)
        trig_in     : in  std_logic;    --! Input trigger
        trig_out    : out  std_logic    --! Output pulse
    );
end trig_pulse_once_const;

architecture Behavioral of trig_pulse_once_const is
    type fsm_pulse_t is (IDLE, PULSE);
    signal fsm_pulse : fsm_pulse_t := IDLE;
begin

    process (clk)
        variable cnt : integer range 0 to WIDTH_CCY := 0;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                fsm_pulse   <= IDLE;
                cnt         := 0;
                trig_out    <= '0';
            else
                case fsm_pulse is
                    when IDLE =>
                        cnt := 0;

                        if trig_in = '1' then
                            trig_out  <= '1';
                            fsm_pulse <= PULSE;
                        else
                            trig_out  <= '0';
                        end if;
                        
                    when PULSE =>
                        if cnt > WIDTH_CCY-2 then
                            trig_out    <= '0';
                            cnt         := 0;
                            fsm_pulse   <= IDLE;
                        else
                            trig_out    <= '1';
                            cnt         := cnt + 1;
                        end if;

                    when others =>
                        null;
                end case;
            end if;
        end if;
    end process;

end Behavioral;
