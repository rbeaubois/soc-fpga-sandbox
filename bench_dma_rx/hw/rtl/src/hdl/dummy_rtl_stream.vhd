library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dummy_rtl_stream is
    generic(
        PERIOD_CCY  : integer;
        PACKET_SIZE : integer;
        DWIDTH      : integer
    );
    port(
        clk_rtl  : in std_logic;
        srst_rtl : in std_logic;
        en_core  : in std_logic;

        nats_dvalid  : out std_logic;
        nats_tstamp  : out std_logic_vector(DWIDTH-1 downto 0);
        nats_data    : out std_logic_vector(DWIDTH-1 downto 0)
    );
end entity dummy_rtl_stream;

architecture RTL of dummy_rtl_stream is
    signal ts_tick : std_logic := '0';

    type fsm_datagen_t is (IDLE, GENERATING_TS, GENERATING_DATA, UPDATE_TS);
    signal fsm_datagen : fsm_datagen_t               := IDLE;
    signal tstamp_cnt  : unsigned(DWIDTH-1 downto 0) := (others => '0');
    signal data_cnt    : unsigned(DWIDTH-1 downto 0) := (others => '0');
begin
   
    -- ========================================
    -- Time step generation
    -- ========================================
    timer_proc : process(clk_rtl)
        variable cnt : integer range 0 to PERIOD_CCY;
    begin
        if rising_edge(clk_rtl) then
            if srst_rtl = '1' then
                cnt     := PERIOD_CCY;
                ts_tick <= '0';
            else
                if en_core = '1' then
                    if cnt > PERIOD_CCY-1 then
                        ts_tick <= '1';
                        cnt     := 0;
                    else
                        ts_tick <= '0';
                        cnt     := cnt + 1;
                    end if;
                else
                    ts_tick <= '0';
                    cnt     := PERIOD_CCY;
                end if;
            end if;
        end if;
    end process;

    -- ========================================
    -- Data stream
    -- ========================================
    process (clk_rtl)
        constant NB_WORD_TO_GENERATE : integer := PACKET_SIZE;
        variable word_cnt            : integer range 0 to NB_WORD_TO_GENERATE-1 := 0;
    begin
        if rising_edge(clk_rtl) then
            if srst_rtl = '1' then
                word_cnt    := 0;
                fsm_datagen <= IDLE;

                tstamp_cnt  <= (others => '0');
                data_cnt    <= (others => '0');
            else
                case fsm_datagen is
                    when IDLE =>
                        word_cnt := NB_WORD_TO_GENERATE-1;

                        if ts_tick = '1' then
                            fsm_datagen <= GENERATING_TS;
                        end if;
                    
                    when GENERATING_TS =>
                        fsm_datagen <= GENERATING_DATA;

                    when GENERATING_DATA =>
                        data_cnt <= data_cnt + 1;

                        if word_cnt > 0 then
                            word_cnt := word_cnt - 1;
                        else
                            fsm_datagen <= UPDATE_TS;
                        end if;

                    when UPDATE_TS =>
                        tstamp_cnt  <= tstamp_cnt + 1;
                        fsm_datagen <= IDLE;

                end case;
            end if;
        end if;
    end process;

    nats_dvalid <= '1' when fsm_datagen = GENERATING_TS or fsm_datagen = GENERATING_DATA else '0';
    nats_data   <= std_logic_vector(data_cnt) when fsm_datagen = GENERATING_DATA else (others => '0');
    nats_tstamp <= std_logic_vector(tstamp_cnt);

end architecture RTL;
