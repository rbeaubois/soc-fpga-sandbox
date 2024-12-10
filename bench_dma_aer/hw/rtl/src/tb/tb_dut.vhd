
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_dut is
end;

architecture bench of tb_dut is
    -- ========================================
    -- Clock period
    -- ========================================
    constant clk_period_pl  : time := 2.5 ns; -- 2.5 ns -> 400MHz
    constant clk_period_axi : time := 5.0 ns; -- 5 ns -> 200 MHz
    
    -- ========================================
    -- Generics
    -- ========================================
    constant DWIDTH_SPK_IN       : integer := 32;
    constant DWIDTH_SPK_MON      : integer := 32;
    constant DWIDTH_GPIO         : integer := 32;
    constant DWIDTH_AXIL_CONTROL : integer := 32;
    constant AWDITH_AXIL_CONTROL : integer := 16;
    constant LAT_RD_CDC_FIFO     : integer := 2;
    constant MAX_SPK_PER_TS      : integer := 1000;
    constant TIME_STEP_CCY       : integer := 200;
    
    -- ========================================
    -- Ports
    -- ========================================
    -- Clocks
    signal clk_pl  : std_logic := '1';
    signal clk_axi : std_logic := '1';

    -- Control AXI-Lite
    signal srst_pl           : std_logic := '0';
    signal srst_axi          : std_logic := '0';
    signal en_core           : std_logic;
    signal en_ps_rd_events   : std_logic;
    signal ps_tx_dma_rdy     : std_logic;
    signal ps_rd_events_size : std_logic_vector(DWIDTH_AXIL_CONTROL-1 downto 0) := (others => '0');
    signal pl_wr_events_size : std_logic_vector(DWIDTH_AXIL_CONTROL-1 downto 0) := (others => '0');

    -- DMA spike stream from PS to PL
    signal s_axis_spk_in_aclk    : std_logic;
    signal s_axis_spk_in_aresetn : std_logic;
    signal s_axis_spk_in_tready  : std_logic;
    signal s_axis_spk_in_tdata   : std_logic_vector(DWIDTH_SPK_IN-1 downto 0);
    signal s_axis_spk_in_tlast   : std_logic;
    signal s_axis_spk_in_tvalid  : std_logic;

    -- DMA spike stream from PL to PS
    signal m_axis_spk_mon_aclk    : std_logic;
    signal m_axis_spk_mon_aresetn : std_logic := '1';
    signal m_axis_spk_mon_tvalid  : std_logic;
    signal m_axis_spk_mon_tready  : std_logic;
    signal m_axis_spk_mon_tdata   : std_logic_vector(DWIDTH_SPK_MON-1 downto 0);
    signal m_axis_spk_mon_tlast   : std_logic;
    signal ts_pl_wr_ev_intr       : std_logic;

    -- GPIO
    signal uled_uf1 : std_logic;
    signal uled_uf2 : std_logic;

    -- ========================================
    -- Testbench internals
    -- ========================================
    signal rst_over      : std_logic := '0';
    signal dma_read_over : std_logic := '0';
begin
    -- ========================================
    -- Generate clocks
    -- ========================================
    clk_pl  <= not clk_pl  after clk_period_pl/2;
    clk_axi <= not clk_axi after clk_period_axi/2;
    S_AXIS_SPK_IN_ACLK      <= clk_axi;
    M_AXIS_SPK_MON_ACLK     <= clk_axi;

    -- ========================================
    -- Instanciate top
    -- ========================================
    dut_inst : entity work.dut
    generic map (
        DWIDTH_SPK_IN              => DWIDTH_SPK_IN,
        DWIDTH_SPK_MON             => DWIDTH_SPK_MON,
        LAT_RD_CDC_FIFO            => LAT_RD_CDC_FIFO,
        MAX_SPK_PER_TS             => MAX_SPK_PER_TS,
        TIME_STEP_CCY              => TIME_STEP_CCY
    )
    port map (
        -- Clocks
        clk_pl                     => clk_pl,
        clk_axi                    => clk_axi,
        srst_pl                    => srst_pl,
        srst_axi                   => srst_axi,

        -- From AXI-Lite control
        en_core                    => en_core,
        en_ps_rd_events            => en_ps_rd_events,
        ps_tx_dma_rdy              => ps_tx_dma_rdy,
        ps_rd_events_size          => ps_rd_events_size,
        pl_wr_events_size          => pl_wr_events_size,

        -- AXI Stream spike from PS to PL
        S_AXIS_SPK_IN_ACLK         => s_axis_spk_in_aclk,
        S_AXIS_SPK_IN_ARESETN      => s_axis_spk_in_aresetn,
        S_AXIS_SPK_IN_TREADY       => s_axis_spk_in_tready,
        S_AXIS_SPK_IN_TDATA        => s_axis_spk_in_tdata,
        S_AXIS_SPK_IN_TLAST        => s_axis_spk_in_tlast,
        S_AXIS_SPK_IN_TVALID       => s_axis_spk_in_tvalid,
        -- AXI Stream spike from PL to PS
        M_AXIS_SPK_MON_ACLK        => m_axis_spk_mon_aclk,
        M_AXIS_SPK_MON_ARESETN     => m_axis_spk_mon_aresetn,
        M_AXIS_SPK_MON_TVALID      => m_axis_spk_mon_tvalid,
        M_AXIS_SPK_MON_TREADY      => m_axis_spk_mon_tready,
        M_AXIS_SPK_MON_TDATA       => m_axis_spk_mon_tdata,
        M_AXIS_SPK_MON_TLAST       => m_axis_spk_mon_tlast,
        ts_pl_wr_ev_intr           => ts_pl_wr_ev_intr,
        -- GPIO
        uled_uf1                   => uled_uf1,
        uled_uf2                   => uled_uf2
    );

    -- ========================================
    -- Reset AXI peripheral
    -- ========================================
    drive_resets: process
    begin
        rst_over              <= '0';
        S_AXIS_SPK_IN_ARESETN <= '0';
        srst_axi              <= '1';
        srst_pl               <= '1';
        wait for 15*clk_period_axi;
        
        rst_over              <= '1';
        S_AXIS_SPK_IN_ARESETN <= '1';
        srst_axi              <= '0';
        srst_pl               <= '0';
        wait;
    end process drive_resets;
    
    -- ========================================
    -- AXI-Lite control setup
    -- ========================================
    drive_axilite_control : process
    begin
        en_core             <= '0';
        wait until rising_edge(rst_over);
        en_core             <= '1';
        wait;
    end process drive_axilite_control;

    -- ========================================
    -- AXI DMA write spike stream in
    -- ========================================
    drive_dma_write_spk_in : process
        constant NB_TSTAMP      : integer := 20;
        constant NB_SPK_PER_TS  : integer := 10;
        variable tstamp         : integer := 6666;
    begin
        s_axis_spk_in_tdata   <= (others => '0');
        s_axis_spk_in_tlast   <= '0';
        s_axis_spk_in_tvalid  <= '0';

        wait until rising_edge(rst_over);
        wait for 10*clk_period_axi;
        ps_tx_dma_rdy <= '1';
        wait until s_axis_spk_in_tready = '1';

        for I in 0 to NB_TSTAMP-1 loop
            -- write time stamp
            s_axis_spk_in_tvalid    <= '1';
            s_axis_spk_in_tdata     <= std_logic_vector(to_unsigned(tstamp, DWIDTH_SPK_IN));
            s_axis_spk_in_tlast     <= '0';
            wait for clk_period_axi;

            -- write nb of events
            s_axis_spk_in_tdata     <= std_logic_vector(to_unsigned(NB_SPK_PER_TS, DWIDTH_SPK_IN));
            wait for clk_period_axi;

            -- write spk events
            for J in 0 to NB_SPK_PER_TS-1 loop

                s_axis_spk_in_tdata <= std_logic_vector(to_unsigned(J, DWIDTH_SPK_IN));
                if J = NB_SPK_PER_TS-1 then
                    s_axis_spk_in_tlast <= '1';
                end if;
                
                wait for clk_period_axi;
            end loop;
            
            s_axis_spk_in_tvalid    <= '0';
            s_axis_spk_in_tdata     <= (others => '0');
            s_axis_spk_in_tlast     <= '0';
            tstamp := tstamp + 1;
        end loop;
        wait for clk_period_axi;

        -- Emulate zeros sent by dma_proxy driver
        for I in 0 to 2-1 loop
            -- write time stamp
            s_axis_spk_in_tvalid    <= '1';
            s_axis_spk_in_tdata     <= std_logic_vector(to_unsigned(0, DWIDTH_SPK_IN));
            s_axis_spk_in_tlast     <= '0';
            wait for clk_period_axi;

            -- write nb of events
            s_axis_spk_in_tdata     <= std_logic_vector(to_unsigned(0, DWIDTH_SPK_IN));
            wait for clk_period_axi;

            -- write spk events
            for J in 0 to NB_SPK_PER_TS-1 loop

                s_axis_spk_in_tdata <= std_logic_vector(to_unsigned(0, DWIDTH_SPK_IN));
                if J = NB_SPK_PER_TS-1 then
                    s_axis_spk_in_tlast <= '1';
                end if;
                
                wait for clk_period_axi;
            end loop;
            
            s_axis_spk_in_tvalid    <= '0';
            s_axis_spk_in_tdata     <= (others => '0');
            s_axis_spk_in_tlast     <= '0';
            tstamp := tstamp + 1;
        end loop;
        wait for clk_period_axi;

        for I in 0 to NB_TSTAMP-1 loop
            -- write time stamp
            s_axis_spk_in_tvalid    <= '1';
            s_axis_spk_in_tdata     <= std_logic_vector(to_unsigned(tstamp, DWIDTH_SPK_IN));
            s_axis_spk_in_tlast     <= '0';
            wait for clk_period_axi;

            -- write nb of events
            s_axis_spk_in_tdata     <= std_logic_vector(to_unsigned(NB_SPK_PER_TS, DWIDTH_SPK_IN));
            wait for clk_period_axi;

            -- write spk events
            for J in 0 to NB_SPK_PER_TS-1 loop

                s_axis_spk_in_tdata <= std_logic_vector(to_unsigned(J, DWIDTH_SPK_IN));
                if J = NB_SPK_PER_TS-1 then
                    s_axis_spk_in_tlast <= '1';
                end if;
                
                wait for clk_period_axi;
            end loop;
            
            s_axis_spk_in_tvalid    <= '0';
            s_axis_spk_in_tdata     <= (others => '0');
            s_axis_spk_in_tlast     <= '0';
            tstamp := tstamp + 1;
        end loop;
        
    end process drive_dma_write_spk_in;
    
    
    -- ========================================
    -- Emulate PS read AXI DMA
    -- ========================================
    gen_emu_ps_read_dma : if true generate
        type fsm_ps_read_dma_t is (
            IDLE,
            READY,
            REQUEST_READ,
            WAIT_END_TRANSFER,
            ACK_READ,
            END_SIM
        );
        signal fsm_ps_read_dma : fsm_ps_read_dma_t := IDLE;
        signal cnt_dma_read    : integer           := 3;
    begin
        fsm_proc_ps_read_dma : process (clk_axi) is
            variable size_ev_to_read : unsigned(DWIDTH_GPIO-1 downto 0) := (others=>'0');
        begin
            if rising_edge(clk_axi) then
                if srst_axi = '1' then
                    dma_read_over     <= '0';
                    en_ps_rd_events   <= '0';
                    ps_rd_events_size <= (others => '0');
                    fsm_ps_read_dma   <= IDLE;
                else
                    case fsm_ps_read_dma is
                        when IDLE =>
                            M_AXIS_SPK_MON_TREADY <= '0';
                            size_ev_to_read := unsigned(pl_wr_events_size);
                            fsm_ps_read_dma <= READY when size_ev_to_read > 100;

                        when READY =>
                            M_AXIS_SPK_MON_TREADY <= '1';
                            fsm_ps_read_dma <= REQUEST_READ;
                        
                        when REQUEST_READ =>
                            en_ps_rd_events   <= '1';
                            ps_rd_events_size <= std_logic_vector(size_ev_to_read);
                            fsm_ps_read_dma <= WAIT_END_TRANSFER;
                        
                        when WAIT_END_TRANSFER =>
                            fsm_ps_read_dma <= ACK_READ when m_axis_spk_mon_tlast = '1';
                        
                        when ACK_READ =>
                            en_ps_rd_events   <= '0';
                            ps_rd_events_size <= (others => '0');

                            if cnt_dma_read > 1 then
                                cnt_dma_read    <= cnt_dma_read -1;
                                fsm_ps_read_dma <= IDLE;
                            else
                                fsm_ps_read_dma <= END_SIM;
                            end if;
                        
                        when END_SIM =>
                            dma_read_over <= '1';
                            fsm_ps_read_dma <= IDLE;
                    end case;
                end if;
            end if;
        end process fsm_proc_ps_read_dma;
        
    end generate gen_emu_ps_read_dma;
    
    wait_end_simulation : process
    begin
        wait until rising_edge(dma_read_over);
        wait for 20*clk_period_axi;
        std.env.finish;
    end process wait_end_simulation;
    
end;