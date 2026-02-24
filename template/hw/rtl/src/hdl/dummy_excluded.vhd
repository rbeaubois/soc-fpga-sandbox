-- Some depreciated or unrelated module
-- you don't use in your project

library ieee;
use ieee.std_logic_1164.all;

entity dummy_excluded is
    port (
        a : in std_logic;
        b : in std_logic;
        c : out std_logic
    );
end entity dummy_excluded;

architecture rtl of dummy_excluded is

begin
    c <= a or b;
end architecture;