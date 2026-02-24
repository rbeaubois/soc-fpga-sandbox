-- Package with global parameters

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package system_pkg is
    -- General parameters ---------------------------------------------------------------------------
        -- Hardware version --
        constant HW_VERSION : string  := "0.0.1";
        constant HW_UID     : integer := 999_999_003;
end package system_pkg;

package body system_pkg is
end package body system_pkg;