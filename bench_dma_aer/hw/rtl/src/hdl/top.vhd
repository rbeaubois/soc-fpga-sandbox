library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.axidma_pkg.dma_opmode;
use work.axilite_mapper_pkg.MAX_DWIDTH_AXIL;
use work.axilite_mapper_pkg.MAX_AWIDTH_AXIL;

entity top is
    generic (
        DWIDTH_GPIO         : integer :=       32;
        DWIDTH_DATA         : integer :=       32;
        DWIDTH_SPK_IN       : integer :=       32;
        DWIDTH_SPK_MON      : integer :=       32;
        DWIDTH_AXIL_CONTROL : integer :=       32;
		AWDITH_AXIL_CONTROL : integer :=       16;
        DWIDTH_AXIL_STATUS  : integer :=       32;
		AWDITH_AXIL_STATUS  : integer :=       16;
        AWIDTH_FIFO_SPK_IN  : integer :=       10;
        LAT_RD_CDC_FIFO     : integer :=        2;
        MAX_SPK_PER_TS      : integer :=     1000;
        TIME_STEP_CCY       : integer :=    12500
    );
    port (
        -- Clock
        clk_pl          : in std_logic;
        clk_axi         : in std_logic;

        -- AXI-Lite: Control
        S_AXI_LITE_CONTROL_ACLK        : in std_logic;
        S_AXI_LITE_CONTROL_ARESETN     : in std_logic;
        S_AXI_LITE_CONTROL_AWADDR      : in std_logic_vector(AWDITH_AXIL_CONTROL-1 downto 0);
        S_AXI_LITE_CONTROL_AWPROT      : in std_logic_vector(2 downto 0);
        S_AXI_LITE_CONTROL_AWVALID     : in std_logic;
        S_AXI_LITE_CONTROL_AWREADY     : out std_logic;
        S_AXI_LITE_CONTROL_WDATA       : in std_logic_vector(DWIDTH_AXIL_CONTROL-1 downto 0);
        S_AXI_LITE_CONTROL_WSTRB       : in std_logic_vector((DWIDTH_AXIL_CONTROL/8)-1 downto 0);
        S_AXI_LITE_CONTROL_WVALID      : in std_logic;
        S_AXI_LITE_CONTROL_WREADY      : out std_logic;
        S_AXI_LITE_CONTROL_BRESP       : out std_logic_vector(1 downto 0);
        S_AXI_LITE_CONTROL_BVALID      : out std_logic;
        S_AXI_LITE_CONTROL_BREADY      : in std_logic;
        S_AXI_LITE_CONTROL_ARADDR      : in std_logic_vector(AWDITH_AXIL_CONTROL-1 downto 0);
        S_AXI_LITE_CONTROL_ARPROT      : in std_logic_vector(2 downto 0);
        S_AXI_LITE_CONTROL_ARVALID     : in std_logic;
        S_AXI_LITE_CONTROL_ARREADY     : out std_logic;
        S_AXI_LITE_CONTROL_RDATA       : out std_logic_vector(DWIDTH_AXIL_CONTROL-1 downto 0);
        S_AXI_LITE_CONTROL_RRESP       : out std_logic_vector(1 downto 0);
        S_AXI_LITE_CONTROL_RVALID      : out std_logic;
        S_AXI_LITE_CONTROL_RREADY      : in std_logic;
        
        -- AXI-Lite: Status
        S_AXI_LITE_STATUS_ACLK        : in std_logic;
        S_AXI_LITE_STATUS_ARESETN     : in std_logic;
        S_AXI_LITE_STATUS_AWADDR      : in std_logic_vector(AWDITH_AXIL_STATUS-1 downto 0);
        S_AXI_LITE_STATUS_AWPROT      : in std_logic_vector(2 downto 0);
        S_AXI_LITE_STATUS_AWVALID     : in std_logic;
        S_AXI_LITE_STATUS_AWREADY     : out std_logic;
        S_AXI_LITE_STATUS_WDATA       : in std_logic_vector(DWIDTH_AXIL_STATUS-1 downto 0);
        S_AXI_LITE_STATUS_WSTRB       : in std_logic_vector((DWIDTH_AXIL_STATUS/8)-1 downto 0);
        S_AXI_LITE_STATUS_WVALID      : in std_logic;
        S_AXI_LITE_STATUS_WREADY      : out std_logic;
        S_AXI_LITE_STATUS_BRESP       : out std_logic_vector(1 downto 0);
        S_AXI_LITE_STATUS_BVALID      : out std_logic;
        S_AXI_LITE_STATUS_BREADY      : in std_logic;
        S_AXI_LITE_STATUS_ARADDR      : in std_logic_vector(AWDITH_AXIL_STATUS-1 downto 0);
        S_AXI_LITE_STATUS_ARPROT      : in std_logic_vector(2 downto 0);
        S_AXI_LITE_STATUS_ARVALID     : in std_logic;
        S_AXI_LITE_STATUS_ARREADY     : out std_logic;
        S_AXI_LITE_STATUS_RDATA       : out std_logic_vector(DWIDTH_AXIL_STATUS-1 downto 0);
        S_AXI_LITE_STATUS_RRESP       : out std_logic_vector(1 downto 0);
        S_AXI_LITE_STATUS_RVALID      : out std_logic;
        S_AXI_LITE_STATUS_RREADY      : in std_logic;

        -- Spike stream from PS via DMA
        S_AXIS_SPK_IN_ACLK     : in std_logic;
        S_AXIS_SPK_IN_ARESETN  : in std_logic;
        S_AXIS_SPK_IN_TREADY   : out std_logic;
        S_AXIS_SPK_IN_TDATA    : in std_logic_vector(DWIDTH_SPK_IN-1 downto 0);
        S_AXIS_SPK_IN_TLAST    : in std_logic;
        S_AXIS_SPK_IN_TVALID   : in std_logic;

        -- Spike monitoring to DMA
        M_AXIS_SPK_MON_ACLK     : in std_logic;
        M_AXIS_SPK_MON_ARESETN  : in std_logic;
        M_AXIS_SPK_MON_TVALID   : out std_logic;
        M_AXIS_SPK_MON_TREADY   : in std_logic;
        M_AXIS_SPK_MON_TDATA    : out std_logic_vector(DWIDTH_SPK_MON-1 downto 0);
        M_AXIS_SPK_MON_TLAST    : out std_logic;

        -- AXI GPIO: free slots DMA spikes transfers to PL
        dma_spk_i_fifo2pl_free_slots_pl      : out std_logic_vector(DWIDTH_GPIO-1 downto 0);
        dma_spk_i_fifo2pl_used_slots_ps      : in  std_logic_vector(DWIDTH_GPIO-1 downto 0);
        dma_spk_i_fifo2pl_free_slots_pl_intr : out std_logic;
        dma_spk_i_fifo2pl_used_slots_ps_intr : in  std_logic;

        -- AXI GPIO: events available DMA spikes transfers to PS
        dma_spk_o_fifo2ps_size_wr_ev_pl      : out std_logic_vector(DWIDTH_GPIO-1 downto 0);
        dma_spk_o_fifo2ps_size_rd_ev_ps      : in  std_logic_vector(DWIDTH_GPIO-1 downto 0);
        dma_spk_o_fifo2ps_wr_ev_pl_intr      : out std_logic;
        dma_spk_o_fifo2ps_rd_ev_ps_intr      : in  std_logic;
        
        -- User LEDs
        uled_uf1 : out std_logic;
        uled_uf2 : out std_logic;

        -- PMODS (debug)
        pmod1: out std_logic_vector(7 downto 0);
        pmod2: out std_logic_vector(7 downto 0);
        pmod3: out std_logic_vector(7 downto 0);
        pmod4: out std_logic_vector(7 downto 0)
    );
end entity top;

architecture rtl of top is
    -- ========================
    -- DUT
    -- ========================
    -- Clock domain in module
    signal ts_pl_wr_ev_intr_dom_pl   : std_logic;
    signal ts_tick_dom_pl            : std_logic;
    signal pl_wr_events_size_dom_pl  : std_logic_vector(DWIDTH_GPIO-1 downto 0);
    signal count_fifo_spk_in_dom_axi : std_logic_vector(AWIDTH_FIFO_SPK_IN-1 downto 0);
    -- CDC to external modules
    signal ts_tick_dom_axi           : std_logic;
    signal ts_pl_wr_ev_intr_dom_axi  : std_logic;
    signal pl_wr_events_size_dom_axi : std_logic_vector(DWIDTH_GPIO-1 downto 0);

    -- ========================
    -- AXI GPIO
    -- ========================
    signal en_ps_rd_events_dom_axi   : std_logic := '0';
    signal ps_rd_events_size_dom_axi : std_logic_vector(DWIDTH_GPIO-1 downto 0) := (others => '0');

    -- ========================
    -- AXI-Lite control
    -- ========================
    -- From PS
        -- Control --
        signal en_core_dom_axi                     : std_logic;
        signal srst_axi_dom_axi                    : std_logic;
        signal opmode_ps_recv_dma_spk_dom_axi      : std_logic;
        signal opmode_ps_send_dma_spk_dom_axi      : std_logic;
        signal irq_thresh_free_slots_to_pl_dom_axi : std_logic_vector(MAX_DWIDTH_AXIL-1 downto 0);
        signal irq_thresh_ready_ev_to_ps_dom_axi   : std_logic_vector(MAX_DWIDTH_AXIL-1 downto 0);
    -- To PS
    
    -- CCD to external modules
        signal srst_pl_dom_pl : std_logic;
        signal en_core_dom_pl : std_logic;
begin
    ---------------------------------------------------------------------------------------
    --
    --  ██████  ███    ███  ██████  ██████  
    --  ██   ██ ████  ████ ██    ██ ██   ██ 
    --  ██████  ██ ████ ██ ██    ██ ██   ██ 
    --  ██      ██  ██  ██ ██    ██ ██   ██ 
    --  ██      ██      ██  ██████  ██████  
    --
    -- Debug PMOD
    ---------------------------------------------------------------------------------------
    -- PMOD 1
    pmod1 <= (others => '0');
    -- PMOD 2
    pmod2 <= (others => '0');
    -- PMOD 3
    pmod3 <= (others => '0');
    -- PMOD 4
    pmod4 <= (others => '0');

    ---------------------------------------------------------------------------------------
    --
    --   █████  ██   ██ ██      ██████  ██████  ██  ██████  
    --  ██   ██  ██ ██  ██     ██       ██   ██ ██ ██    ██ 
    --  ███████   ███   ██     ██   ███ ██████  ██ ██    ██ 
    --  ██   ██  ██ ██  ██     ██    ██ ██      ██ ██    ██ 
    --  ██   ██ ██   ██ ██      ██████  ██      ██  ██████  
    --
    -- DMA Status
    ---------------------------------------------------------------------------------------
    -- ========================
    -- AXI GPIO: free slots to write spikes to PL
    -- ========================
    -- Generate interrupt when free slots cross threhsold and return nb free slots
    free_slots_to_pl : process (clk_axi) is
        constant FIFO_DEPTH : unsigned(DWIDTH_GPIO-1 downto 0) := to_unsigned(work.axidma_pkg.DEPTH_FIFO_SPK_IN, DWIDTH_GPIO);
        variable free_slots : unsigned(DWIDTH_GPIO-1 downto 0); 
    begin
        if rising_edge(clk_axi) then
            if srst_axi_dom_axi = '1' then
                free_slots := (others => '0');
                dma_spk_i_fifo2pl_free_slots_pl_intr <= '0';
            else
                -- Calculate number of free slots
                free_slots := FIFO_DEPTH - unsigned(count_fifo_spk_in_dom_axi);

                -- Generate interrupt if crossing threshold
                if free_slots > unsigned(irq_thresh_free_slots_to_pl_dom_axi) and S_AXIS_SPK_IN_TVALID = '0' then
                    dma_spk_i_fifo2pl_free_slots_pl_intr <= '1';
                else
                    dma_spk_i_fifo2pl_free_slots_pl_intr <= '0';
                end if;
            end if;
        end if;
        -- Map free slots to signal
        dma_spk_i_fifo2pl_free_slots_pl <= std_logic_vector(free_slots);
    end process free_slots_to_pl;

    -- ========================
    -- AXI GPIO: events status to read from PS
    -- ========================
    -- Map module ports
    en_ps_rd_events_dom_axi   <= dma_spk_o_fifo2ps_rd_ev_ps_intr;
    ps_rd_events_size_dom_axi <= dma_spk_o_fifo2ps_size_rd_ev_ps;

    -- Generate interrupt when size events ready cross threhsold and return size events
    available_events_to_ps : process (clk_axi) is
        variable word_cnt : unsigned(DWIDTH_GPIO-1 downto 0);
    begin
        if rising_edge(clk_axi) then
            if srst_axi_dom_axi = '1' then
                word_cnt                := (others => '0');
                dma_spk_o_fifo2ps_wr_ev_pl_intr <= '0';
            else
                -- Get number of events written
                word_cnt := unsigned(pl_wr_events_size_dom_axi);

                if opmode_ps_recv_dma_spk_dom_axi = dma_opmode.PERIODIC(0) then
                    -- Generate periodic interrupt when pl writes data
                    dma_spk_o_fifo2ps_wr_ev_pl_intr <= ts_pl_wr_ev_intr_dom_axi;
                else
                    -- Generate interrupt if crossing threshold
                    if word_cnt > unsigned(irq_thresh_ready_ev_to_ps_dom_axi) then
                        dma_spk_o_fifo2ps_wr_ev_pl_intr <= '1';
                    else
                        dma_spk_o_fifo2ps_wr_ev_pl_intr <= '0';
                    end if;
                end if;
            end if;
        end if;
        -- Map free slots to signal
        dma_spk_o_fifo2ps_size_wr_ev_pl <= std_logic_vector(word_cnt);
    end process available_events_to_ps;

    ---------------------------------------------------------------------------------------
    --                                                
    --   █████  ██   ██ ██ ██      ██ ████████ ███████
    --  ██   ██  ██ ██  ██ ██      ██    ██    ██     
    --  ███████   ███   ██ ██      ██    ██    █████  
    --  ██   ██  ██ ██  ██ ██      ██    ██    ██     
    --  ██   ██ ██   ██ ██ ███████ ██    ██    ███████
    --                                                
    -- HH neuron computation core
    ---------------------------------------------------------------------------------------
    -- AXI-Lite control: reset and setup
    axilite_control_inst : entity work.axilite_control
    port map (
        rst                         => srst_axi_dom_axi,
        en_core                     => en_core_dom_axi,
        opmode_ps_recv_dma_spk      => opmode_ps_recv_dma_spk_dom_axi,
        opmode_ps_send_dma_spk      => opmode_ps_send_dma_spk_dom_axi,
        irq_thresh_free_slots_to_pl => irq_thresh_free_slots_to_pl_dom_axi,
        irq_thresh_ready_ev_to_ps   => irq_thresh_ready_ev_to_ps_dom_axi,
        S_AXI_ACLK                  => S_AXI_LITE_CONTROL_ACLK,
        S_AXI_ARESETN               => S_AXI_LITE_CONTROL_ARESETN,
		S_AXI_AWADDR                => S_AXI_LITE_CONTROL_AWADDR,
        S_AXI_AWPROT                => S_AXI_LITE_CONTROL_AWPROT,
        S_AXI_AWVALID               => S_AXI_LITE_CONTROL_AWVALID,
        S_AXI_AWREADY               => S_AXI_LITE_CONTROL_AWREADY,
        S_AXI_WDATA                 => S_AXI_LITE_CONTROL_WDATA,
        S_AXI_WSTRB                 => S_AXI_LITE_CONTROL_WSTRB,
        S_AXI_WVALID                => S_AXI_LITE_CONTROL_WVALID,
        S_AXI_WREADY                => S_AXI_LITE_CONTROL_WREADY,
        S_AXI_BRESP                 => S_AXI_LITE_CONTROL_BRESP,
        S_AXI_BVALID                => S_AXI_LITE_CONTROL_BVALID,
        S_AXI_BREADY                => S_AXI_LITE_CONTROL_BREADY,
        S_AXI_ARADDR                => S_AXI_LITE_CONTROL_ARADDR,
        S_AXI_ARPROT                => S_AXI_LITE_CONTROL_ARPROT,
        S_AXI_ARVALID               => S_AXI_LITE_CONTROL_ARVALID,
        S_AXI_ARREADY               => S_AXI_LITE_CONTROL_ARREADY,
        S_AXI_RDATA                 => S_AXI_LITE_CONTROL_RDATA,
        S_AXI_RRESP                 => S_AXI_LITE_CONTROL_RRESP,
        S_AXI_RVALID                => S_AXI_LITE_CONTROL_RVALID,
        S_AXI_RREADY                => S_AXI_LITE_CONTROL_RREADY
    );

    -- AXI-Lite status: loopback registers for demo
    axilite_status_inst : entity work.axilite_status
    port map (
        S_AXI_ACLK           => S_AXI_LITE_STATUS_ACLK,
        S_AXI_ARESETN        => S_AXI_LITE_STATUS_ARESETN,
		S_AXI_AWADDR         => S_AXI_LITE_STATUS_AWADDR,
        S_AXI_AWPROT         => S_AXI_LITE_STATUS_AWPROT,
        S_AXI_AWVALID        => S_AXI_LITE_STATUS_AWVALID,
        S_AXI_AWREADY        => S_AXI_LITE_STATUS_AWREADY,
        S_AXI_WDATA          => S_AXI_LITE_STATUS_WDATA,
        S_AXI_WSTRB          => S_AXI_LITE_STATUS_WSTRB,
        S_AXI_WVALID         => S_AXI_LITE_STATUS_WVALID,
        S_AXI_WREADY         => S_AXI_LITE_STATUS_WREADY,
        S_AXI_BRESP          => S_AXI_LITE_STATUS_BRESP,
        S_AXI_BVALID         => S_AXI_LITE_STATUS_BVALID,
        S_AXI_BREADY         => S_AXI_LITE_STATUS_BREADY,
        S_AXI_ARADDR         => S_AXI_LITE_STATUS_ARADDR,
        S_AXI_ARPROT         => S_AXI_LITE_STATUS_ARPROT,
        S_AXI_ARVALID        => S_AXI_LITE_STATUS_ARVALID,
        S_AXI_ARREADY        => S_AXI_LITE_STATUS_ARREADY,
        S_AXI_RDATA          => S_AXI_LITE_STATUS_RDATA,
        S_AXI_RRESP          => S_AXI_LITE_STATUS_RRESP,
        S_AXI_RVALID         => S_AXI_LITE_STATUS_RVALID,
        S_AXI_RREADY         => S_AXI_LITE_STATUS_RREADY
    );

    ---------------------------------------------------------------------------------------
    --
    --   ██████  ██████ ██████  
    --  ██      ██      ██   ██ 
    --  ██      ██      ██   ██ 
    --  ██      ██      ██   ██ 
    --   ██████  ██████ ██████  
    --                          
    -- Crossing clock domain
    ---------------------------------------------------------------------------------------    
    -- CDC Slow to Fast: Reset specific handling
    ccd_slow_to_fast_srst : if true generate
        constant CCD_PIPE_DEPTH : integer := 2;
        subtype pipe_sl_t is std_logic_vector(CCD_PIPE_DEPTH-1 downto 0);
        signal pipe_ccd_srst_pl : pipe_sl_t  := (others => '0');
    begin        
        process (clk_pl)
        begin
            if rising_edge(clk_pl) then
                pipe_ccd_srst_pl <= pipe_ccd_srst_pl(CCD_PIPE_DEPTH-1 downto 1) & srst_axi_dom_axi;
            end if;
        end process;
        srst_pl_dom_pl <= pipe_ccd_srst_pl(CCD_PIPE_DEPTH-1);
    end generate;

    -- CDC Fast to Slow: Generic
    ccd_fast_to_slow : if true generate
        signal ts_tick_ext_dom_pl : std_logic := '0';
    begin
        ccd_fast_to_slow_latched_values: process(clk_axi)
        begin
            if rising_edge(clk_axi) then
                pl_wr_events_size_dom_axi <= pl_wr_events_size_dom_pl;
            end if;
        end process;

        ccd_fast_to_slow_sig_extension : process (clk_pl) is
            constant NB_CCY_EXTENSION : integer := 8;
            variable cnt_ccy_sig_ext  : integer range 0 to NB_CCY_EXTENSION;
        begin
            if rising_edge(clk_pl) then
                if srst_pl_dom_pl = '1' then
                    cnt_ccy_sig_ext := 0;
                    ts_tick_ext_dom_pl <= '0';
                else
                    if ts_tick_dom_pl = '1' then
                        cnt_ccy_sig_ext := NB_CCY_EXTENSION;
                    else
                        if cnt_ccy_sig_ext > 0 then
                            cnt_ccy_sig_ext := cnt_ccy_sig_ext - 1;
                        end if;
                    end if;

                    if cnt_ccy_sig_ext > 0 then
                        ts_tick_ext_dom_pl <= '1';
                    else
                        ts_tick_ext_dom_pl <= '0';
                    end if;
                end if;
            end if;
        end process ccd_fast_to_slow_sig_extension;

        ccd_fast_to_slow_edge_values : process (clk_axi) is
        begin
            if rising_edge(clk_axi) then
                ts_tick_dom_axi          <= ts_tick_ext_dom_pl;
                ts_pl_wr_ev_intr_dom_axi <= ts_pl_wr_ev_intr_dom_pl;
            end if;
        end process ccd_fast_to_slow_edge_values;
    end generate ccd_fast_to_slow;
    
    -- CDC Slow to fast: Generic handling with double flip-flop
    dff_0: entity work.dff_sync_arst_sl port map(clk=>clk_pl, rst=>srst_pl_dom_pl, din=>en_core_dom_axi, dout=>en_core_dom_pl);
    
    ---------------------------------------------------------------------------------------
    --
    --  ██████  ██    ██ ████████ 
    --  ██   ██ ██    ██    ██    
    --  ██   ██ ██    ██    ██    
    --  ██   ██ ██    ██    ██    
    --  ██████   ██████     ██    
    --                            
    -- Device under test
    ---------------------------------------------------------------------------------------
    dut_inst: entity work.dut
        generic map(
            DWIDTH_GPIO         => DWIDTH_GPIO,
            DWIDTH_DATA         => DWIDTH_DATA,
            DWIDTH_SPK_IN       => DWIDTH_SPK_IN,
            DWIDTH_SPK_MON      => DWIDTH_SPK_MON,
            AWIDTH_FIFO_SPK_IN  => AWIDTH_FIFO_SPK_IN,
            LAT_RD_CDC_FIFO     => LAT_RD_CDC_FIFO,
            MAX_SPK_PER_TS      => MAX_SPK_PER_TS,
            TIME_STEP_CCY       => TIME_STEP_CCY
        )
        port map(
            -- Clock
            clk_pl   => clk_pl,
            clk_axi  => clk_axi,
            srst_pl  => srst_pl_dom_pl,
            srst_axi => srst_axi_dom_axi,
            ts_tick  => ts_tick_dom_pl,
    
            -- AXI-Lite Control
            en_core           => en_core_dom_pl,

            -- AXI GPIO
            en_ps_rd_events   => en_ps_rd_events_dom_axi,
            ps_rd_events_size => ps_rd_events_size_dom_axi,
            ps_tx_dma_rdy     => dma_spk_i_fifo2pl_used_slots_ps_intr,
            pl_wr_events_size => pl_wr_events_size_dom_pl,
            count_fifo_spk_in => count_fifo_spk_in_dom_axi,
    
            -- Spike stream from PS via DMA
            S_AXIS_SPK_IN_ACLK     => S_AXIS_SPK_IN_ACLK,
            S_AXIS_SPK_IN_ARESETN  => S_AXIS_SPK_IN_ARESETN,
            S_AXIS_SPK_IN_TREADY   => S_AXIS_SPK_IN_TREADY,
            S_AXIS_SPK_IN_TDATA    => S_AXIS_SPK_IN_TDATA,
            S_AXIS_SPK_IN_TLAST    => S_AXIS_SPK_IN_TLAST,
            S_AXIS_SPK_IN_TVALID   => S_AXIS_SPK_IN_TVALID,
    
            -- Spike monitoring to DMA
            M_AXIS_SPK_MON_ACLK     => M_AXIS_SPK_MON_ACLK,
            M_AXIS_SPK_MON_ARESETN  => M_AXIS_SPK_MON_ARESETN,
            M_AXIS_SPK_MON_TVALID   => M_AXIS_SPK_MON_TVALID,
            M_AXIS_SPK_MON_TREADY   => M_AXIS_SPK_MON_TREADY,
            M_AXIS_SPK_MON_TDATA    => M_AXIS_SPK_MON_TDATA,
            M_AXIS_SPK_MON_TLAST    => M_AXIS_SPK_MON_TLAST,

            ts_pl_wr_ev_intr        => ts_pl_wr_ev_intr_dom_pl,
            
            -- User LEDs
            uled_uf1 => uled_uf1,
            uled_uf2 => uled_uf2
        );

end architecture;