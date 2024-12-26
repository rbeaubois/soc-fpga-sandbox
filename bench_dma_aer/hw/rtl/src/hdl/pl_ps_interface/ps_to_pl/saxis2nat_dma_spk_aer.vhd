--! @title     Slave AXI-Stream to native from DMA
--! @file      nat2maxis_dma_spk_aer.vhd
--! @author    Romain Beaubois
--! @date      29 Nov 2024
--! @copyright
--! SPDX-FileCopyrightText: © 2024 Romain Beaubois <refbeaubois@yahoo.com>
--! SPDX-License-Identifier: MIT
--!
--! @brief Slave AXI-Stream to native from DMA
--! * Stores stream from PS via DMA in CDC FIFO (AXI clk domain -> PL clk domain)
--! * Returns word count of CDC FIFO to notify PS of available space in FIFO
--! * Decode stream as native spike AER at each time step
--! 
--! @details 
--! > **29 Nov 2024** : file creation (RB)
--! > **12 Dec 2024** : remove unecessary sufix in signal name, add handling for fwft fifo (RB)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity saxis2nat_dma_spk_aer is
    generic (
        DWIDTH              : integer :=    32;
        AWIDTH_FIFO         : integer :=    10;
        LAT_RD_CDC_FIFO     : integer :=     2;
        MAX_SPK_PER_TS      : integer :=  1000
    );
    port (
        -- Clocks and reset
        clk_pl            : in std_logic;
        srst_pl           : in std_logic;
        srst_axi          : in std_logic;
        en_core           : in std_logic;
        ts_tick           : in std_logic;
        ps_tx_dma_rdy     : in std_logic;
        count_fifo : out std_logic_vector(AWIDTH_FIFO-1 downto 0);

        -- Axis stream from DMA
        s_axis_aclk     : in std_logic;
        s_axis_aresetn  : in std_logic;
        s_axis_tready   : out std_logic;
        s_axis_tdata    : in std_logic_vector(DWIDTH-1 downto 0);
        s_axis_tlast    : in std_logic;
        s_axis_tvalid   : in std_logic;

        -- PL stream
        rdy_events  : out std_logic;
        ts_event    : out std_logic_vector(DWIDTH-1 downto 0);
        nb_event    : out std_logic_vector(DWIDTH-1 downto 0);
        id_event    : out std_logic_vector(DWIDTH-1 downto 0)
    );
end entity;

architecture rtl of saxis2nat_dma_spk_aer is
    -- ========================================
    -- Decode spike in stream from PS
    -- ========================================
    type fsm_decode_spk_stream_t is (
        IDLE,
        WAIT_LAT_READ0,
        WAIT_LAT_READ1,
        READ_TS,
        READ_NB,
        READ_ID
    );
    signal fsm_decode_spk_stream : fsm_decode_spk_stream_t := IDLE;
    
    -- ========================================
    -- FIFO CDC to temporize stream from PS
    -- ========================================
    signal fifo_cdc_din           : std_logic_vector(DWIDTH-1 downto 0);
    signal fifo_cdc_wr_en         : std_logic;
    signal fifo_cdc_rd_en         : std_logic;
    signal fifo_cdc_dout          : std_logic_vector(DWIDTH-1 downto 0);
    signal fifo_cdc_full          : std_logic;
    signal fifo_cdc_empty         : std_logic;
    signal fifo_cdc_wr_data_count : std_logic_vector(AWIDTH_FIFO-1 downto 0);
begin
    -- ========================================
    -- Module assertions
    -- ========================================
    assert fifo_cdc_wr_data_count'length = count_fifo'length
    report "Discrepancy in depth of [axis_data_fifo_spk_stream_ps], please verify IP generation"
    severity error;

    -- ========================================
    -- FIFO CDC to temporize stream from PS
    -- ========================================
    -- Store AXI stream from DMA in the CDC FIFO
    axi_stream_to_native_fifo: process (s_axis_aclk)
    begin
    if rising_edge(s_axis_aclk) then
        if s_axis_aresetn = '0' then
            fifo_cdc_din <= (others=>'0');
            fifo_cdc_wr_en <= '0';
        else
            if s_axis_tvalid = '1' and ps_tx_dma_rdy = '1' then
                fifo_cdc_din   <= s_axis_tdata;
                fifo_cdc_wr_en <= '1';
            else
                fifo_cdc_wr_en <= '0';
            end if;
        end if;
    end if;
    end process;
    s_axis_tready <= not(fifo_cdc_full);

    -- Store stream in FIFO (as block but could be as builtin)
    count_fifo <= fifo_cdc_wr_data_count;
    nat_fifo_spk_stream_from_ps_inst: entity work.farch_nat_fifo_spk_stream_from_ps
    generic map(
        DWIDTH => DWIDTH,
        AWIDTH => AWIDTH_FIFO
    )
    port map (
        rst             => srst_axi or not(s_axis_aresetn),
        wr_clk          => s_axis_ACLK,
        rd_clk          => clk_pl,
        din             => fifo_cdc_din,
        wr_en           => fifo_cdc_wr_en,
        rd_en           => fifo_cdc_rd_en,
        dout            => fifo_cdc_dout,
        full            => fifo_cdc_full,
        empty           => fifo_cdc_empty,
        wr_data_count   => fifo_cdc_wr_data_count,
        wr_rst_busy     => open,
        rd_rst_busy     => open
    );

    -- ========================================
    -- Decode spike in stream from FIFO
    -- ========================================
    decode_stream_cdc_fifo: process (clk_pl)
        variable rd_cnt : integer range 0 to MAX_SPK_PER_TS := 0;
        variable this_events_size : integer range 0 to MAX_SPK_PER_TS+2 := 0;
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                rd_cnt           := 0;
                this_events_size := 0;
                
                fifo_cdc_rd_en <= '0';
                fsm_decode_spk_stream <= IDLE;
            else
                case fsm_decode_spk_stream is
                    -- Wait for time step tick
                    when IDLE =>
                        rd_cnt := 0;
                        this_events_size := 0;
                        
                        -- Read samples @ time step if data available in FIFO
                        if fifo_cdc_empty = '0' and ts_tick = '1' then
                            fifo_cdc_rd_en        <= '1';

                            -- No read latency (FWFT FIFO)
                            if LAT_RD_CDC_FIFO = 0 then
                                fsm_decode_spk_stream <= READ_TS;
                            -- Wait read latency
                            else
                                fsm_decode_spk_stream <= WAIT_LAT_READ0;
                            end if;
                        else
                            fifo_cdc_rd_en        <= '0';
                        end if;

                    -- Wait read latency 1 ccy
                    when WAIT_LAT_READ0 =>                        
                        if LAT_RD_CDC_FIFO = 1 then
                            fsm_decode_spk_stream <= READ_TS;
                        else
                            fsm_decode_spk_stream <= WAIT_LAT_READ1;
                        end if;

                    -- Wait read latency 2 ccy
                    when WAIT_LAT_READ1 =>
                        fsm_decode_spk_stream <= READ_TS;
                    
                    -- Read time stamp
                    when READ_TS =>
                        fsm_decode_spk_stream <= READ_NB;

                    -- Read number of events
                    when READ_NB =>
                        rd_cnt                := to_integer(unsigned(fifo_cdc_dout));
                        this_events_size      := to_integer(unsigned(fifo_cdc_dout)) + 2;

                        if this_events_size > 1 then
                            fifo_cdc_rd_en <= '1';
                            fsm_decode_spk_stream <= READ_ID;
                        else
                            fifo_cdc_rd_en <= '0';
                            fsm_decode_spk_stream <= IDLE;
                        end if;

                    -- Read channel index
                    when READ_ID =>
                        -- Disable read from fifo (considering fifo reading latency)
                        if rd_cnt <= LAT_RD_CDC_FIFO+1 then -- +1 for ccy
                            fifo_cdc_rd_en <= '0';
                        end if;

                        -- Return to idle when finished reading
                        if rd_cnt > 1 then
                            rd_cnt := rd_cnt -1;
                        else
                            rd_cnt := 0;
                            fsm_decode_spk_stream <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- MUX FIFO ouptput
    rdy_events <= '1' when fsm_decode_spk_stream = READ_TS or
                           fsm_decode_spk_stream = READ_NB or
                           fsm_decode_spk_stream = READ_ID 
                      else '0';
    ts_event   <= fifo_cdc_dout when fsm_decode_spk_stream = READ_TS else (others=>'0');
    nb_event   <= fifo_cdc_dout when fsm_decode_spk_stream = READ_NB else (others=>'0');
    id_event   <= fifo_cdc_dout when fsm_decode_spk_stream = READ_ID else (others=>'0');

end architecture;