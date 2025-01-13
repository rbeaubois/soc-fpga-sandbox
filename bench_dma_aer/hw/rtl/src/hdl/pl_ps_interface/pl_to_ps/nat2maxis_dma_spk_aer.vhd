--! @title     Native stream to Master AXI-Stream to DMA
--! @file      nat2maxis_dma_spk_aer.vhd
--! @author    Romain Beaubois
--! @date      29 Nov 2024
--! @copyright
--! SPDX-FileCopyrightText: © 2024 Romain Beaubois <refbeaubois@yahoo.com>
--! SPDX-License-Identifier: MIT
--!
--! @brief Native PL stream to Master AXI-Stream to S2MM DMA
--! * Stores PL stream in CDC FIFO (PL clk domain -> AXI clk domain)
--! * Update event counter at the end of each PL write (every time step)
--! * Update event counter when PS read initiated (from AXI GPIO)
--! * Generate Master AXI-Stream from data stored in FIFO on PS read request
--!
--!          +------------------------------+
--!          | RTL Stream (Native)          |
--!          | PL Domain                    |
--!          +------------------------------+
--!                     | - PL periodic write
--!                     v
--!          +------------------------------+
--!          | FIFO CDC Native              |
--!          +------------------------------+
--!                     | - PS command read
--!                     v
--!          +------------------------------+
--!          | RTL Stream (Native)          |
--!          | PS Domain                    |
--!          +------------------------------+
--!                     |
--!                     v
--!          +------------------------------+
--!          | Convert to MAXIS RTL         |
--!          +------------------------------+
--!                     | MAXIS RTL <-> S2MM DMA
--!                     v
--!
--! @details 
--! > **29 Nov 2024** : file creation (RB)
--! > **13 Jan 2025** : patch event counter (RB)

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity nat2maxis_dma_spk_aer is
    generic (
        MAX_SPK_PER_TS  : integer := 1000;
        DWIDTH_GPIO     : integer := 32;
        DWIDTH_DMA      : integer := 32
    );
    port (
        -- Clocks & resets
        clk_pl   : in std_logic;
        clk_axi  : in std_logic;
        srst_pl  : in std_logic;
        srst_axi : in std_logic;

        -- Control from PS
        rdy_in_events : in std_logic;
        ts_event      : in std_logic_vector(DWIDTH_DMA-1 downto 0);
        nb_event      : in std_logic_vector(DWIDTH_DMA-1 downto 0);
        id_event      : in std_logic_vector(DWIDTH_DMA-1 downto 0);

        -- AXI GPIO control DMA stream
        en_ps_rd_events   : in std_logic;
        pl_wr_events_size : out std_logic_vector(DWIDTH_GPIO-1 downto 0);
        ps_rd_events_size : in  std_logic_vector(DWIDTH_GPIO-1 downto 0);

        -- AXI Stream to DMA
        m_axis_aclk     : in std_logic;
        m_axis_aresetn  : in std_logic;
        m_axis_tvalid   : out std_logic;
        m_axis_tready   : in std_logic;
        m_axis_tdata    : out std_logic_vector(DWIDTH_DMA-1 downto 0);
        m_axis_tlast    : out std_logic;

        -- Interrupt PL write in chunk wrote in CDC FIFO
        ts_pl_wr_ev_intr : out std_logic
    );
end entity nat2maxis_dma_spk_aer;

architecture rtl of nat2maxis_dma_spk_aer is
    -- ========================================
    -- From IP Catalog:
    -- Crossing clock domain FIFO native interface
    -- ========================================
    -- From IP catalog and fpga arch dependent 'farch_nat_fifo_cdc_dma_spk2ps'

    -- Interface signals
    type fsm_mux_din_cdc_fifo_t is (
        SEL_TS_EVENT,  -- Assert tvalid
        SEL_NB_EVENT,  -- Send stream
        SEL_ID_EVENT   -- Send stream
    );
    signal fsm_mux_din_cdc_fifo : fsm_mux_din_cdc_fifo_t := SEL_TS_EVENT;
    signal cdc_fifo_din         : std_logic_vector(DWIDTH_DMA-1 downto 0);
    signal cdc_fifo_wr_en       : std_logic := '0';
    signal cdc_fifo_rd_en       : std_logic;
    signal cdc_fifo_dout        : std_logic_vector(DWIDTH_DMA-1 downto 0);
    signal cdc_fifo_full        : std_logic;
    signal cdc_fifo_almost_full : std_logic;
    signal cdc_fifo_overflow    : std_logic;
    signal cdc_fifo_empty       : std_logic;
    signal cdc_fifo_wr_rst_busy : std_logic;
    signal cdc_fifo_rd_rst_busy : std_logic;

    -- ========================================
    -- PS read/write status through AXI GPIO
    -- ========================================
    -- Update global event counter
    type fsm_update_ev_counter_t is(
        IDLE,
        SUB_PS_RD_EV,
        ADD_PL_WR_EV
    );
    signal fsm_update_ev_counter : fsm_update_ev_counter_t := IDLE;

    -- Count events streamed by PL
    type fsm_count_pl_events_t is(
        IDLE,
        COUNT,
        RDY
    );
    signal fsm_count_pl_events : fsm_count_pl_events_t := IDLE;
    signal pl_count_rdy : std_logic := '0';
    signal pl_ev_cnt_cur_ts : unsigned(DWIDTH_GPIO-1 downto 0) := (others => '0');

    -- Sync PS read (extra logic to handle "sync" with soft)
    type fsm_sync_ps_read_cnt_t is (
        WAIT_ASSERT_READ,
        SYNC_PS_READ_SIZE,
        WAIT_PROCCESS_READ,
        WAIT_DEASSERT_READ
    );
    signal fsm_sync_ps_read_cnt     : fsm_sync_ps_read_cnt_t := WAIT_ASSERT_READ;
    signal synced_ps_rd_events_size : std_logic_vector(DWIDTH_GPIO-1 downto 0);
    signal synced_ps_rd_events_rdy  : std_logic;

    -- ========================================
    -- RTL to AXI Stream master
    -- ========================================
    -- AXI protocol imposes:
    --  * master TDATA can't change while TVALID is HIGH and TREADY is LOW
    --  * master can't wait for TREADY HIGH to set TVALID HIGH
    type fsm_m_axis_t is (
        IDLE,           -- Wait for data valid
        ASSERT_TVALID,  -- Assert tvalid
        SEND_STREAM,    -- Send stream
        ASSERT_TLAST,   -- Assert tlast at the end of stream
        WAIT_COMPLETION -- Wait for completion notified by PS
    );
    signal fsm_m_axis    : fsm_m_axis_t := IDLE;
begin
    ---------------------------------------------------------------------------------------
    --
    --  ███████ ██ ███████  ██████       ██████ ██████   ██████ 
    --  ██      ██ ██      ██    ██     ██      ██   ██ ██      
    --  █████   ██ █████   ██    ██     ██      ██   ██ ██      
    --  ██      ██ ██      ██    ██     ██      ██   ██ ██      
    --  ██      ██ ██       ██████       ██████ ██████   ██████ 
    --
    -- FIFO CDC: PL clk domain -> AXI clk domain + buffering
    ---------------------------------------------------------------------------------------
    
    -- ========================================
    -- Write data to CDC FIFO
    -- ========================================
    -- Map FIFO control
    cdc_fifo_map : process(all)
    begin    
        cdc_fifo_wr_en  <= rdy_in_events;
        cdc_fifo_din    <= nb_event when fsm_mux_din_cdc_fifo = SEL_NB_EVENT else
                           id_event when fsm_mux_din_cdc_fifo = SEL_ID_EVENT else
                           ts_event;
    end process cdc_fifo_map;

    -- Mux din data FIFO
    fsm_mux_din_cdc_fifo_proc: process (clk_pl)
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                fsm_mux_din_cdc_fifo <= SEL_TS_EVENT;
            else
                case fsm_mux_din_cdc_fifo is
                    when SEL_TS_EVENT => fsm_mux_din_cdc_fifo  <= SEL_NB_EVENT when rdy_in_events = '1';
                    when SEL_NB_EVENT => fsm_mux_din_cdc_fifo  <= SEL_ID_EVENT;
                    when SEL_ID_EVENT => fsm_mux_din_cdc_fifo  <= SEL_TS_EVENT when rdy_in_events = '0';
                end case;
            end if;
        end if;
    end process;

    -- ========================================
    -- Instanciate IP generated CDC FIFO
    -- ========================================
    fifo_cdc_buffer_to_dma_s2mm : entity work.farch_nat_fifo_cdc_dma_spk2ps
    generic map(
        DWIDTH      => DWIDTH_DMA
    )
    port map (
        rst         => srst_axi,
        wr_clk      => clk_pl,
        rd_clk      => clk_axi,
        din         => cdc_fifo_din,
        wr_en       => cdc_fifo_wr_en,
        rd_en       => cdc_fifo_rd_en,
        dout        => cdc_fifo_dout,
        full        => cdc_fifo_full,
        empty       => cdc_fifo_empty,
        wr_rst_busy => cdc_fifo_wr_rst_busy,
        rd_rst_busy => cdc_fifo_rd_rst_busy
    );

    ---------------------------------------------------------------------------------------
    --
    --  ███████ ██    ██     ███████ ████████  █████  ████████ ██    ██ ███████ 
    --  ██      ██    ██     ██         ██    ██   ██    ██    ██    ██ ██      
    --  █████   ██    ██     ███████    ██    ███████    ██    ██    ██ ███████ 
    --  ██       ██  ██           ██    ██    ██   ██    ██    ██    ██      ██ 
    --  ███████   ████       ███████    ██    ██   ██    ██     ██████  ███████ 
    --                                                                          
    -- Native stream to master axis
    ---------------------------------------------------------------------------------------
    -- ========================================
    -- Update event counter
    -- 
    -- * Update event counter at each PL write (add new events)
    -- * Update event counter at each PS read (sub events read)
    -- * Generate interrupt on PL write
    -- ========================================
    -- Global fsm event counter status
    proc_fsm_update_ev_counter : process (clk_pl) is
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                fsm_update_ev_counter <= IDLE;
            else
                case fsm_update_ev_counter is
                    when IDLE =>
                        fsm_update_ev_counter <= SUB_PS_RD_EV when synced_ps_rd_events_rdy = '1' else
                                                 ADD_PL_WR_EV when pl_count_rdy = '1' else
                                                 IDLE;

                    when SUB_PS_RD_EV =>
                        fsm_update_ev_counter <= ADD_PL_WR_EV when pl_count_rdy = '1' 
                                                              else IDLE;
                    
                    when ADD_PL_WR_EV =>
                        fsm_update_ev_counter <= IDLE;
                end case;
            end if;
        end if;
    end process proc_fsm_update_ev_counter;

    -- Update counter value
    update_counter : process (clk_pl) is
        variable cnt : unsigned(DWIDTH_GPIO-1 downto 0);
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                cnt := (others => '0');
                pl_wr_events_size <= (others => '0');
            else
                if fsm_update_ev_counter = SUB_PS_RD_EV then
                    cnt := cnt - unsigned(synced_ps_rd_events_size);
                elsif fsm_update_ev_counter = ADD_PL_WR_EV then
                    cnt := cnt + pl_ev_cnt_cur_ts;
                end if;
                pl_wr_events_size <= std_logic_vector(cnt);
            end if;
        end if;
    end process update_counter;

    -- Generate interrupt at each write
    ts_pl_wr_ev_intr <= '1' when fsm_update_ev_counter = ADD_PL_WR_EV
                            else '0';
    
    -- ========================================
    -- Count events streamed by PL in current time step
    --
    -- * Count continuously pl events from the rdy rise to fall
    -- ========================================
    -- Control counter pl event 
    proc_fsm_count_pl_events : process (clk_pl) is
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                fsm_count_pl_events <= IDLE;
            else
                case fsm_count_pl_events is
                    when IDLE =>
                        fsm_count_pl_events <= COUNT when rdy_in_events = '1';

                    when COUNT =>
                        fsm_count_pl_events <= RDY when rdy_in_events = '0';

                    when RDY =>
                        fsm_count_pl_events <= IDLE;
                end case;
            end if;
        end if;
    end process proc_fsm_count_pl_events;

    pl_count_rdy <= '1' when fsm_count_pl_events = RDY 
                        else '0';

    count_current_ts_pl_wr_ev : process (clk_pl) is
        variable cnt : integer range 0 to MAX_SPK_PER_TS+2-1 := 0;
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                cnt := 0;
                pl_ev_cnt_cur_ts <= (others => '0');
            else
                if fsm_count_pl_events = IDLE then
                    cnt := 0;
                elsif fsm_count_pl_events = COUNT then
                    cnt := cnt + 1;
                else
                    pl_ev_cnt_cur_ts <= to_unsigned(cnt, pl_ev_cnt_cur_ts'length);
                end if;
            end if;
        end if;
    end process count_current_ts_pl_wr_ev;
    
    -- ========================================
    -- Synchronize ps read event size
    --
    -- PS soft operation:
    -- (1) Set read size with axi_gpio (write_to_pl())
    -- (2) Set flag high to request read (set_flag_write_to_pl())
    -- (3) Read GPIO data and start transfer (read_from_pl())
    -- (4) Wait for transfer completed
    -- (5) Set read size to 0 (write_to_pl())
    -- (6) Clear flag low to rearm (clear_flag_write_to_pl())
    -- 
    -- PL operation:
    -- * Wait for flag rise
    -- * Latch read size
    -- * Wait for event counter to process read
    -- * Wait for clear of flag
    -- ========================================
    update_event_size_proc : process (clk_pl) is
    begin
        if rising_edge(clk_pl) then
            if srst_pl = '1' then
                synced_ps_rd_events_size <= (others => '0');
                fsm_sync_ps_read_cnt <= WAIT_ASSERT_READ;
            else
                case fsm_sync_ps_read_cnt is
                    when WAIT_ASSERT_READ =>
                        synced_ps_rd_events_size <= (others => '0');

                        if en_ps_rd_events = '1' then
                            fsm_sync_ps_read_cnt <= SYNC_PS_READ_SIZE;
                        end if;
                        
                    when SYNC_PS_READ_SIZE =>
                        synced_ps_rd_events_size <= ps_rd_events_size;

                        if unsigned(ps_rd_events_size) > 0 then
                            fsm_sync_ps_read_cnt <= WAIT_PROCCESS_READ;
                        end if;

                    when WAIT_PROCCESS_READ =>
                        if fsm_update_ev_counter = SUB_PS_RD_EV then
                            fsm_sync_ps_read_cnt <= WAIT_DEASSERT_READ;
                        end if;

                    when WAIT_DEASSERT_READ =>
                        if en_ps_rd_events = '0' then
                            fsm_sync_ps_read_cnt <= WAIT_ASSERT_READ;
                        end if;
                end case;
            end if;
        end if;
    end process update_event_size_proc;

    synced_ps_rd_events_rdy <= '1' when fsm_sync_ps_read_cnt = WAIT_PROCCESS_READ 
                                   else '0';

    ---------------------------------------------------------------------------------------
    --
    --  ███    ██  █████  ████████     ██████      ███    ███  █████  ██   ██ ██ ███████ 
    --  ████   ██ ██   ██    ██             ██     ████  ████ ██   ██  ██ ██  ██ ██      
    --  ██ ██  ██ ███████    ██         █████      ██ ████ ██ ███████   ███   ██ ███████ 
    --  ██  ██ ██ ██   ██    ██        ██          ██  ██  ██ ██   ██  ██ ██  ██      ██ 
    --  ██   ████ ██   ██    ██        ███████     ██      ██ ██   ██ ██   ██ ██ ███████ 
    --                                                                                   
    -- Native stream to master axis
    ---------------------------------------------------------------------------------------

    -- ========================================
    -- Native stream to maxis
    -- ========================================
    -- CDC fifo controls
    cdc_fifo_rd_en <= '1' when ((fsm_m_axis = ASSERT_TVALID) or 
                                (fsm_m_axis = SEND_STREAM) or
                                (fsm_m_axis = ASSERT_TLAST)) and 
                                (m_axis_tready = '1')
                          else '0';

    -- Map maxis
    map_maxis_mon : process(all)
    begin    
        m_axis_tdata   <= std_logic_vector(resize(unsigned(cdc_fifo_dout), DWIDTH_DMA));
        m_axis_tvalid  <= '1' when fsm_m_axis = ASSERT_TVALID or
                                   fsm_m_axis = SEND_STREAM   or
                                   fsm_m_axis = ASSERT_TLAST
                                  else '0';
        m_axis_tlast   <= '1' when fsm_m_axis = ASSERT_TLAST
                                  else '0';
    end process map_maxis_mon;

    -- Generate controls
    fsm_m_axis_proc: process (m_axis_aclk)
        variable word_cnt : integer range 0 to MAX_SPK_PER_TS+2-1 := 0;
    begin
        if rising_edge(m_axis_aclk) then
            if m_axis_aresetn = '0' then
                word_cnt  := 0;
                fsm_m_axis <= IDLE;
            else
                case fsm_m_axis is
                    when IDLE =>
                        if en_ps_rd_events = '1' then
                            word_cnt := to_integer(unsigned(ps_rd_events_size));
                            fsm_m_axis <= ASSERT_TVALID;
                        end if;

                    when ASSERT_TVALID =>
                        fsm_m_axis <= SEND_STREAM when m_axis_tready = '1';

                    when SEND_STREAM =>
                        if word_cnt > 3 then -- (1) next state ccy (1) start from bound and not bound-1 (1) tlast
                            word_cnt := word_cnt -1;
                        else
                            fsm_m_axis <= ASSERT_TLAST;
                        end if;

                    when ASSERT_TLAST =>
                        fsm_m_axis <= WAIT_COMPLETION;

                    when WAIT_COMPLETION =>
                        if en_ps_rd_events = '0' then
                            fsm_m_axis <= IDLE;
                        end if;
                end case;
            end if;
        end if;
    end process;

end architecture;