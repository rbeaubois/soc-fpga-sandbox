library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity blackbox is
    generic(
        DWIDTH_DATA : integer := 32
    );
    port(
        -- Clocks & resets
        clk_pl  : in std_logic;
        srst_pl : in std_logic;

        -- PL input data stream
        raw_rdy_in_events : in std_logic;
        raw_ts_event      : in std_logic_vector(DWIDTH_DATA-1 downto 0);
        raw_nb_event      : in std_logic_vector(DWIDTH_DATA-1 downto 0);
        raw_id_event      : in std_logic_vector(DWIDTH_DATA-1 downto 0);
        
        -- PL output data stream
        new_rdy_in_events : out std_logic;
        new_ts_event      : out std_logic_vector(DWIDTH_DATA-1 downto 0);
        new_nb_event      : out std_logic_vector(DWIDTH_DATA-1 downto 0);
        new_id_event      : out std_logic_vector(DWIDTH_DATA-1 downto 0)
    );
end entity blackbox;

architecture RTL of blackbox is
begin
    blackbox_is_just_regs : process (clk_pl) is
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                new_rdy_in_events <= '0';
                new_ts_event      <= (others => '0');
                new_nb_event      <= (others => '0');
                new_id_event      <= (others => '0');
            else
                new_rdy_in_events <= raw_rdy_in_events;
                new_ts_event      <= raw_ts_event(new_ts_event'length-1 downto 0);
                new_nb_event      <= raw_nb_event(new_nb_event'length-1 downto 0);
                new_id_event      <= raw_id_event(new_id_event'length-1 downto 0);
            end if;
        end if;
    end process blackbox_is_just_regs;    
end architecture RTL;
