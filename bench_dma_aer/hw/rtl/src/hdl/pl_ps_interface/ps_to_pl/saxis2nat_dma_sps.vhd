--! @title     Slave AXI-Stream to native from DMA for samples
--! @file      nat2maxis_dma_spk_aer.vhd
--! @author    Romain Beaubois
--! @date      29 Nov 2024
--! @copyright
--! SPDX-FileCopyrightText: © 2024 Romain Beaubois <refbeaubois@yahoo.com>
--! SPDX-License-Identifier: MIT
--!
--! @brief Slave AXI-Stream to native from DMA for samples
--! 
--! @details 
--! > **29 Nov 2024** : file creation (RB)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity saxis2nat_dma_sps is
    generic (
        DWIDTH_SPS  : integer :=    32;
        DWIDTH_TS   : integer :=    32;
        DWIDTH_ID   : integer :=    16;
        AWIDTH_FIFO : integer :=    10;
        NB_CHANNELS : integer :=    10 -- TODO: should be axilite value
    );
    port (
        -- Clocks and reset
        clk_pl            : in std_logic;
        srst_pl           : in std_logic;
        srst_axi          : in std_logic;
        en_core           : in std_logic;
        ts_tick           : in std_logic;
        ps_tx_dma_rdy     : in std_logic;
        count_fifo        : out std_logic_vector(AWIDTH_FIFO-1 downto 0);

        -- Axis stream from DMA
        s_axis_aclk     : in std_logic;
        s_axis_aresetn  : in std_logic;
        s_axis_tready   : out std_logic;
        s_axis_tdata    : in std_logic_vector(DWIDTH_SPS-1 downto 0);
        s_axis_tlast    : in std_logic;
        s_axis_tvalid   : in std_logic;

        -- PL stream
        rdy      : out std_logic;
        ts       : out std_logic_vector(DWIDTH_TS-1 downto 0);
        chan_id  : out std_logic_vector(DWIDTH_ID-1 downto 0);
        sample   : out std_logic_vector(DWIDTH_SPS-1 downto 0)
    );
end entity;

architecture rtl of saxis2nat_dma_sps is
    -- ========================================
    -- Decode spike in stream from PS
    -- ========================================
    type fsm_decode_spk_stream_t is (
        IDLE,
        STREAM_DATA
    );
    signal fsm_decode_spk_stream : fsm_decode_spk_stream_t := IDLE;
    signal ts_cnt           : unsigned(DWIDTH_TS-1 downto 0) := (others => '0');
    signal chan_id_cnt      : unsigned(DWIDTH_ID-1 downto 0) := (others => '0');
    
    -- ========================================
    -- FIFO CDC to temporize stream from PS
    -- ========================================
    signal fifo_cdc_din           : std_logic_vector(DWIDTH_SPS-1 downto 0);
    signal fifo_cdc_wr_en         : std_logic;
    signal fifo_cdc_rd_en         : std_logic;
    signal fifo_cdc_dout          : std_logic_vector(DWIDTH_SPS-1 downto 0);
    signal fifo_cdc_full          : std_logic;
    signal fifo_cdc_empty         : std_logic;
    signal fifo_cdc_rd_data_count : std_logic_vector(AWIDTH_FIFO-1 downto 0);
    signal fifo_cdc_wr_data_count : std_logic_vector(AWIDTH_FIFO-1 downto 0);
begin
    -- ========================================
    -- Module assertions
    -- ========================================
    assert fifo_cdc_wr_data_count'length = count_fifo'length
    report "Discrepancy in depth of fifo, please verify IP generation"
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
    farch_fifo_cdc_dma_sps2pl_inst: entity work.farch_fifo_cdc_dma_sps2pl
    generic map(
        DWIDTH => DWIDTH_SPS,
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
        rd_data_count   => fifo_cdc_rd_data_count,
        wr_data_count   => fifo_cdc_wr_data_count,
        wr_rst_busy     => open,
        rd_rst_busy     => open
    );

    -- ========================================
    -- Decode spike in stream from FIFO
    -- ========================================
    decode_stream_cdc_fifo: process (clk_pl)
        variable rd_cnt         : integer range 0 to NB_CHANNELS-1 := 0;
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                rd_cnt      := 0;
                ts_cnt      <= (others => '0');
                chan_id_cnt <= (others => '0');
                fsm_decode_spk_stream <= IDLE;
            else
                case fsm_decode_spk_stream is
                    -- Wait for time step tick
                    when IDLE =>
                        chan_id_cnt <= (others => '0');
                        rd_cnt := NB_CHANNELS-1;
                        
                        -- Read samples @ time step if data available in FIFO
                        if NB_CHANNELS >= 2 and ts_tick = '1' then
                            fsm_decode_spk_stream <= STREAM_DATA;
                        end if;
                    
                    -- Read time stamp
                    when STREAM_DATA =>
                        chan_id_cnt <= chan_id_cnt +1;
                        if rd_cnt <= 1 then
                            ts_cnt <= ts_cnt +1;
                            fsm_decode_spk_stream <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- MUX FIFO ouptput
    rdy     <= '1' when fsm_decode_spk_stream = STREAM_DATA
                   else '0';
    ts      <= std_logic_vector(ts_cnt);
    chan_id <= std_logic_vector(chan_id_cnt);
    sample  <= fifo_cdc_dout when fsm_decode_spk_stream = STREAM_DATA 
                             else (others => '0');
end architecture;