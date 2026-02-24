-- Some module that is intended to be
-- instanciated in block design (requires VHDL 93)

library ieee;
use ieee.std_logic_1164.all;

entity dummy_extra_instance_in_bd is
    port (
        a : in std_logic;
        b : in std_logic;
        c : out std_logic
    );
end entity dummy_extra_instance_in_bd;

architecture rtl of dummy_extra_instance_in_bd is

begin
    c <= a or b;
end architecture;