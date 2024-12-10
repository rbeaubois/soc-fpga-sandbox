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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity saxis2nat_dma_spk_aer is
    generic (
        DWIDTH_SPK_IN       : integer :=    32;
        AWIDTH_FIFO_SPK_IN  : integer :=    10;
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
        count_fifo_spk_in : out std_logic_vector(AWIDTH_FIFO_SPK_IN-1 downto 0);

        -- Axis stream from DMA
        s_axis_spk_in_aclk     : in std_logic;
        s_axis_spk_in_aresetn  : in std_logic;
        s_axis_spk_in_tready   : out std_logic;
        s_axis_spk_in_tdata    : in std_logic_vector(DWIDTH_SPK_IN-1 downto 0);
        s_axis_spk_in_tlast    : in std_logic;
        s_axis_spk_in_tvalid   : in std_logic;

        -- PL stream
        rdy_events  : out std_logic;
        ts_event    : out std_logic_vector(DWIDTH_SPK_IN-1 downto 0);
        nb_event    : out std_logic_vector(DWIDTH_SPK_IN-1 downto 0);
        id_event    : out std_logic_vector(DWIDTH_SPK_IN-1 downto 0)
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
    signal fifo_cdc_din           : std_logic_vector(31 downto 0);
    signal fifo_cdc_wr_en         : std_logic;
    signal fifo_cdc_rd_en         : std_logic;
    signal fifo_cdc_dout          : std_logic_vector(31 downto 0);
    signal fifo_cdc_full          : std_logic;
    signal fifo_cdc_empty         : std_logic;
    signal fifo_cdc_wr_data_count : std_logic_vector(9 downto 0);

    component nat_fifo_spk_stream_from_ps_ip
    port (
        rst           : in std_logic;
        wr_clk        : in std_logic;
        rd_clk        : in std_logic;
        din           : in std_logic_vector(31 downto 0);
        wr_en         : in std_logic;
        rd_en         : in std_logic;
        dout          : out std_logic_vector(31 downto 0);
        full          : out std_logic;
        empty         : out std_logic;
        wr_rst_busy   : out std_logic;
        rd_rst_busy   : out std_logic;
        wr_data_count : out std_logic_vector(9 downto 0)
    );
    end component;
begin
    -- ========================================
    -- Module assertions
    -- ========================================
    assert fifo_cdc_wr_data_count'length = count_fifo_spk_in'length
    report "Discrepancy in depth of [axis_data_fifo_spk_stream_ps], please verify IP generation"
    severity error;
    
    -- ========================================
    -- Decode spike in stream from FIFO
    -- ========================================
    decode_stream_cdc_fifo: process (clk_pl)
        variable rd_cnt : integer range 0 to MAX_SPK_PER_TS := 0;
        variable this_events_size : integer range 0 to MAX_SPK_PER_TS+2 := 0;
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                rdy_events       <= '0';
                ts_event         <= (others => '0');
                nb_event         <= (others => '0');
                id_event         <= (others => '0');
                rd_cnt           := 0;
                this_events_size := 0;
                
                fifo_cdc_rd_en <= '0';
                fsm_decode_spk_stream <= IDLE;
            else
                case fsm_decode_spk_stream is
                    when IDLE =>
                        rdy_events  <= '0';
                        ts_event    <= (others => '0');
                        nb_event    <= (others => '0');
                        id_event    <= (others => '0');
                        rd_cnt      := 0;
                        this_events_size := 0;
                        
                        if fifo_cdc_empty = '0' and ts_tick = '1' then
                            fifo_cdc_rd_en        <= '1';
                            fsm_decode_spk_stream <= WAIT_LAT_READ0;
                        else
                            fifo_cdc_rd_en        <= '0';
                        end if;

                    when WAIT_LAT_READ0 =>                        
                        if LAT_RD_CDC_FIFO = 1 then
                            fsm_decode_spk_stream <= READ_TS;
                        else
                            fsm_decode_spk_stream <= WAIT_LAT_READ1;
                        end if;

                    when WAIT_LAT_READ1 =>
                        fsm_decode_spk_stream <= READ_TS;
                    
                    when READ_TS =>
                        rdy_events            <= '1';
                        ts_event              <= fifo_cdc_dout;
                        fsm_decode_spk_stream <= READ_NB;

                    when READ_NB =>
                        rdy_events            <= '1';
                        nb_event              <= fifo_cdc_dout;
                        rd_cnt                := to_integer(unsigned(fifo_cdc_dout));
                        this_events_size      := to_integer(unsigned(fifo_cdc_dout)) + 2;

                        if this_events_size > 1 then
                            fifo_cdc_rd_en <= '1';
                            fsm_decode_spk_stream <= READ_ID;
                        else
                            fifo_cdc_rd_en <= '0';
                            fsm_decode_spk_stream <= IDLE;
                        end if;
                        

                    when READ_ID =>
                        rdy_events <= '1';
                        id_event   <= fifo_cdc_dout;

                        if rd_cnt <= LAT_RD_CDC_FIFO+1 then -- +1 for ccy
                            fifo_cdc_rd_en <= '0';
                        end if;

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
    

    -- ========================================
    -- FIFO CDC to temporize stream from PS
    -- ========================================
    -- Store AXI stream from DMA in the CDC FIFO
    axi_stream_to_native_fifo: process (s_axis_spk_in_aclk)
    begin
    if rising_edge(s_axis_spk_in_aclk) then
        if s_axis_spk_in_aresetn = '0' then
            fifo_cdc_din <= (others=>'0');
            fifo_cdc_wr_en <= '0';
        else
            if s_axis_spk_in_tvalid = '1' and ps_tx_dma_rdy = '1' then
                fifo_cdc_din   <= s_axis_spk_in_tdata;
                fifo_cdc_wr_en <= '1';
            else
                fifo_cdc_wr_en <= '0';
            end if;
        end if;
    end if;
    end process;
    s_axis_spk_in_tready <= not(fifo_cdc_full);

    -- Store stream in FIFO (as block but could be as builtin)
    count_fifo_spk_in <= fifo_cdc_wr_data_count;
    axis_data_fifo_spk_stream_ps_inst: nat_fifo_spk_stream_from_ps_ip
    port map (        
        rst             => srst_axi or not(s_axis_spk_in_aresetn),
        wr_clk          => s_axis_spk_in_ACLK,
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
end architecture;