-- Top module

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.system_pkg.HW_UID;

entity top is
    generic (
        DWIDTH_UUID : integer := 32  
    );
    port (
        -- ================================
        -- Clocks
        -- ================================
        clk_rtl : in std_logic; -- Main RTL clock        
        clk_axi : in std_logic; -- Main AXI clock
        clk_ext : in std_logic; -- Main external peripheral clock

        -- ================================
        -- AXI GPIO: UUID
        -- ================================
        -- User LEDs
        uuid : out std_logic_vector(DWIDTH_UUID-1 downto 0);

        -- ================================
        -- GPIOs
        -- ================================
        -- User LEDs
        uled_uf1 : out std_logic;
        uled_uf2 : out std_logic
    );
end entity top;

architecture rtl of top is

begin
    uuid <= std_logic_vector(to_unsigned(HW_UID, DWIDTH_UUID));
    uled_uf1 <= '1';
    uled_uf2 <= '0';
end architecture;