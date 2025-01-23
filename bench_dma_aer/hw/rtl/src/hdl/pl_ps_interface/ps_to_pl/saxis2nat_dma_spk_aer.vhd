--! @title     Slave AXI-Stream to native from DMA for AER spikes
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
--! > **23 Jan 2025** : fix fifo read for single frames by adding time stamp coutner instead of using data_counts (RB)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity saxis2nat_dma_spk_aer is
    generic (
        DWIDTH              : integer :=    32;
        AWIDTH_FIFO         : integer :=    10;
        MAX_SPK_PER_TS      : integer :=  1000
    );
    port (
        -- Clocks and reset
        clk_pl            : in std_logic;
        srst_pl           : in std_logic;
        srst_axi          : in std_logic;
        ts_tick           : in std_logic;
        ps_tx_dma_rdy     : in std_logic;
        count_fifo        : out std_logic_vector(AWIDTH_FIFO-1 downto 0);

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
    -- Count time stamp stored
    -- ========================================
    type fsm_cnt_tstamp_t is (
        IDLE,
        PREFETCH_NB_EV,
        WAIT_WRITE,
        WRITE_DONE
    );
    signal fsm_cnt_tstamp         : fsm_cnt_tstamp_t := IDLE;
    signal nb_tstamp_recv_dom_axi : unsigned(DWIDTH-1 downto 0) := (others => '0');
    signal nb_tstamp_recv_dom_pl  : unsigned(DWIDTH-1 downto 0) := (others => '0');
    signal rdy_new_frames         : std_logic := '0';

    -- ========================================
    -- Decode spike in stream from PS
    -- ========================================
    type fsm_decode_spk_stream_t is (
        IDLE,
        READ_TS,
        READ_NB,
        READ_ID
    );
    signal nb_tstamp_proc_dom_pl : unsigned(DWIDTH-1 downto 0) := (others => '0');
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
    signal fifo_cdc_rd_data_count : std_logic_vector(AWIDTH_FIFO-1 downto 0);
    signal fifo_cdc_wr_data_count : std_logic_vector(AWIDTH_FIFO-1 downto 0);
begin
    -- ========================================
    -- Module assertions
    -- 
    -- * Checks if FIFO IP has correct signal width
    -- ========================================
    assert fifo_cdc_wr_data_count'length = count_fifo'length
    report "Discrepancy in depth of [axis_data_fifo_spk_stream_ps], please verify IP generation"
    severity error;

    -- ========================================
    -- FIFO CDC to temporize stream from PS
    --
    -- * Redirect AXIS to CDC FIFO (AXIS <-> Native signals)
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
    nat_fifo_spk_stream_from_ps_inst: entity work.farch_fifo_cdc_dma_spk2pl
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
        rd_data_count   => fifo_cdc_rd_data_count,
        wr_data_count   => fifo_cdc_wr_data_count,
        wr_rst_busy     => open,
        rd_rst_busy     => open
    );

    -- ========================================
    -- Count time stamps written
    --
    -- * Count all time steps written in FIFO (cumulative)
    -- * Move counter from write domain (AXI clock) to read domain (PL clock)
    -- ========================================

    -- Count the number of time stamps that have been written in FIFO (total)
    proc_cnt_tstamp: process (s_axis_aclk)
        variable cnt : integer range 0 to MAX_SPK_PER_TS := 0;
    begin
        if rising_edge(s_axis_aclk) then
            if s_axis_aresetn = '0' then
                cnt := 0;
                fsm_cnt_tstamp <= IDLE;
            else
                case fsm_cnt_tstamp is
                    -- Wait for PS write
                    when IDLE =>
                        cnt := 0;
                        fsm_cnt_tstamp <= PREFETCH_NB_EV when fifo_cdc_wr_en = '1';
                    
                    -- Read number of events
                    when PREFETCH_NB_EV =>
                        cnt := to_integer(unsigned(fifo_cdc_din));

                        if cnt > 1 then
                            fsm_cnt_tstamp <= WAIT_WRITE;
                        else
                            fsm_cnt_tstamp <= WRITE_DONE;
                        end if;

                    -- Wait for events to be written
                    when WAIT_WRITE =>
                        -- Anticipate last write to update counter
                        if cnt > 2 then
                            cnt := cnt -1;
                        else
                            cnt := 0;
                            fsm_cnt_tstamp <= WRITE_DONE;
                        end if;
                    
                    -- Frame completely written in FIFO
                    when WRITE_DONE =>
                        fsm_cnt_tstamp <= IDLE;
                end case;
            end if;
        end if;
    end process;
    
    -- Update time stamp counter in AXI clock domain
    update_tstamp_counter_dom_axi : process (s_axis_aclk) is
    begin
        if rising_edge(s_axis_aclk) then
            if s_axis_aresetn = '0' then
                nb_tstamp_recv_dom_axi <= (others => '0');
            else
                if fsm_cnt_tstamp = WRITE_DONE then
                    nb_tstamp_recv_dom_axi <= nb_tstamp_recv_dom_axi +1;
                end if;
            end if;
        end if;
    end process update_tstamp_counter_dom_axi;

    -- Update time stamp counter in PL clock domain
    cdc_tstamp_counter_dom_pl : if true generate
        signal ff1 : unsigned(DWIDTH-1 downto 0) := (others => '0');
        signal ff2 : unsigned(DWIDTH-1 downto 0) := (others => '0');
    begin
        process (clk_pl) is
        begin
            if rising_edge(clk_pl) then
                if srst_pl = '1' then
                    ff1 <= (others => '0');
                    ff2 <= (others => '0');  
                else
                    ff1 <= nb_tstamp_recv_dom_axi;
                    ff2 <= ff1;
                end if;
            end if;
        end process;

        nb_tstamp_recv_dom_pl <= ff2;
    end generate cdc_tstamp_counter_dom_pl;

    -- ========================================
    -- Decode spike in stream from FIFO
    --
    -- * Read data from FIFO
    -- * Stream FIFO data as a "structured" stream
    -- ========================================
    decode_stream_cdc_fifo: process (clk_pl)
        variable rd_cnt : integer range 0 to MAX_SPK_PER_TS := 0;
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                rd_cnt           := 0;
                
                fifo_cdc_rd_en <= '0';
                fsm_decode_spk_stream <= IDLE;
            else
                case fsm_decode_spk_stream is
                    -- Wait for time step tick
                    when IDLE =>
                        rd_cnt := 0;
                        
                        -- Read samples @ time step if data available in FIFO
                        if rdy_new_frames = '1' and ts_tick = '1' then
                            fifo_cdc_rd_en        <= '1';
                            fsm_decode_spk_stream <= READ_TS;
                        else
                            fifo_cdc_rd_en        <= '0';
                        end if;
                    
                    -- Read time stamp
                    when READ_TS =>
                        fsm_decode_spk_stream <= READ_NB;

                    -- Read number of events
                    when READ_NB =>
                        rd_cnt                := to_integer(unsigned(fifo_cdc_dout));
                        fsm_decode_spk_stream <= READ_ID;
                    
                    -- Read events
                    when READ_ID =>
                        -- Disable read from fifo (considering fifo reading latency)
                        if rd_cnt <= 1 then -- +1 for ccy
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

    -- Count frames processed
    update_frames_processed : process (clk_pl) is
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                nb_tstamp_proc_dom_pl <= (others => '0');
            else
                if fsm_decode_spk_stream = READ_TS then
                    nb_tstamp_proc_dom_pl <= nb_tstamp_proc_dom_pl +1;
                end if;
            end if;
        end if;
    end process update_frames_processed;
    
    -- Notify if new frames available to read
    rdy_new_frames <=  '1' when nb_tstamp_recv_dom_pl > nb_tstamp_proc_dom_pl
                           else '0'; 

    -- MUX FIFO ouptput
    rdy_events <= '1' when fsm_decode_spk_stream = READ_TS or
                           fsm_decode_spk_stream = READ_NB or
                           fsm_decode_spk_stream = READ_ID 
                      else '0';
    ts_event   <= fifo_cdc_dout when fsm_decode_spk_stream = READ_TS else (others=>'0');
    nb_event   <= fifo_cdc_dout when fsm_decode_spk_stream = READ_NB else (others=>'0');
    id_event   <= fifo_cdc_dout when fsm_decode_spk_stream = READ_ID else (others=>'0');

end architecture;