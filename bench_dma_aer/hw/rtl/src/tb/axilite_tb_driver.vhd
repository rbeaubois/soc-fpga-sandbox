library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axilite_tb_driver is
    generic(
        DWIDTH : integer := 32;
        AWIDTH : integer := 16
    );
    port(
        cmd_write   : in std_logic;
        cmd_waddr   : in integer;
        cmd_wdata   : in integer;
        write_done  : out std_logic;

        cmd_read    : in  std_logic;
        cmd_raddr   : in  integer;
        cmd_rdata   : out integer;
        read_done   : out std_logic;

        aclk        : in  std_logic;
        aresetn     : in  std_logic;
        awaddr      : out std_logic_vector(AWIDTH-1 downto 0);
        awprot      : out std_logic_vector(2 downto 0);
        awvalid     : out std_logic;
        awready     : in  std_logic;
        wdata       : out std_logic_vector(DWIDTH-1 downto 0);
        wstrb       : out std_logic_vector((DWIDTH/8)-1 downto 0);
        wvalid      : out std_logic;
        wready      : in  std_logic;
        bresp       : in  std_logic_vector(1 downto 0);
        bvalid      : in  std_logic;
        bready      : out std_logic;
        araddr      : out std_logic_vector(AWIDTH-1 downto 0);
        arprot      : out std_logic_vector(2 downto 0);
        arvalid     : out std_logic;
        arready     : in  std_logic;
        rdata       : in  std_logic_vector(DWIDTH-1 downto 0);
        rresp       : in  std_logic_vector(1 downto 0);
        rvalid      : in  std_logic;
        rready      : out std_logic
    );
end entity axilite_tb_driver;

architecture sim of axilite_tb_driver is
    type fsm_axilite_write_t is (IDLE, WRITE, WAIT_RESPONSE, DONE);
    signal fsm_axilite_write : fsm_axilite_write_t := IDLE;

    type fsm_axilite_read_t is (IDLE, READ, WAIT_RESPONSE, DONE);
    signal fsm_axilite_read : fsm_axilite_read_t := IDLE;
begin
    awprot <= (others => '0');
    wstrb  <= (others => '0');

    proc_axilite_write : process (aclk) is
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                fsm_axilite_write <= IDLE;

                wdata       <= (others => '0');
                wvalid      <= '0';
                awaddr      <= (others => '0');
                awvalid     <= '0';
                write_done  <= '0';
                bready      <= '0';
            else
                case fsm_axilite_write is
                    when IDLE =>
                        wdata       <= (others => '0');
                        wvalid      <= '0';
                        awaddr      <= (others => '0');
                        awvalid     <= '0';
                        write_done  <= '0';
                        bready      <= '0';

                        if cmd_write = '1' then
                            fsm_axilite_write <= WRITE;
                        end if;
                        
                    when write =>
                        awvalid <= '1';
                        awaddr  <= std_logic_vector(to_unsigned(cmd_waddr, AWIDTH));
                        wvalid  <= '1';
                        wdata   <= std_logic_vector(to_unsigned(cmd_wdata, DWIDTH));

                        if awready = '1' and wready = '1' then
                            fsm_axilite_write <= WAIT_RESPONSE;
                        end if;

                    when WAIT_RESPONSE =>
                        if bvalid = '1' then
                            bready  <= '1';
                            awvalid <= '0';
                            wvalid  <= '0';
                            fsm_axilite_write <= DONE;
                        end if;
                        
                    when DONE =>
                        write_done <= '1';
                        fsm_axilite_write <= IDLE;

                end case;
            end if;
        end if;
    end process proc_axilite_write;

    proc_axilite_read : process (aclk) is
    begin
        if rising_edge(aclk) then
            if aresetn = '0' then
                fsm_axilite_read <= IDLE;

                arvalid    <= '0';
                araddr     <= (others => '0');
                rready     <= '0';
                read_done  <= '0';
                cmd_rdata  <= 0;
            else
                case fsm_axilite_read is
                    when IDLE =>
                        arvalid    <= '0';
                        araddr     <= (others => '0');
                        read_done  <= '0';

                        if cmd_read = '1' then
                            fsm_axilite_read <= READ;
                        end if;
                        
                    when READ =>
                        arvalid <= '1';
                        araddr  <= std_logic_vector(to_unsigned(cmd_raddr, AWIDTH));

                        if arready = '1' then
                            fsm_axilite_read <= WAIT_RESPONSE;
                        end if;

                    when WAIT_RESPONSE =>
                        if rvalid = '1' then
                            rready <= '1';
                            arvalid <= '1';
                            cmd_rdata <= to_integer(unsigned(rdata));
                            fsm_axilite_read <= DONE;
                        end if;
                        
                    when DONE =>
                        read_done <= '1';
                        rready    <= '0';
                        arvalid   <= '0';
                        fsm_axilite_read <= IDLE;

                end case;
            end if;
        end if;
    end process proc_axilite_read;
end architecture sim;

-- -- ========================================
-- -- AXI-Lite Control
-- -- ========================================
-- axilite_sim: entity work.axilite_tb_driver
-- generic map(
--     DWIDTH => DWIDTH_AXIL_CONTROL,
--     AWIDTH => AWDITH_AXIL_CONTROL
-- )
-- port map(
--     cmd_write   => axil_cmd_write,
--     cmd_waddr   => axil_cmd_waddr,
--     cmd_wdata   => axil_cmd_wdata,
--     write_done  => axil_write_done,
    
--     cmd_read    => axil_cmd_read,
--     cmd_raddr   => axil_cmd_raddr,
--     cmd_rdata   => axil_cmd_rdata,
--     read_done   => axil_read_done,
    
--     aclk        => s_axi_lite_control_aclk,
--     aresetn     => s_axi_lite_control_aresetn,
--     awaddr      => s_axi_lite_control_awaddr,
--     awprot      => s_axi_lite_control_awprot,
--     awvalid     => s_axi_lite_control_awvalid,
--     awready     => s_axi_lite_control_awready,
--     wdata       => s_axi_lite_control_wdata,
--     wstrb       => s_axi_lite_control_wstrb,
--     wvalid      => s_axi_lite_control_wvalid,
--     wready      => s_axi_lite_control_wready,
--     bresp       => s_axi_lite_control_bresp,
--     bvalid      => s_axi_lite_control_bvalid,
--     bready      => s_axi_lite_control_bready,
--     araddr      => s_axi_lite_control_araddr,
--     arprot      => s_axi_lite_control_arprot,
--     arvalid     => s_axi_lite_control_arvalid,
--     arready     => s_axi_lite_control_arready,
--     rdata       => s_axi_lite_control_rdata,
--     rresp       => s_axi_lite_control_rresp,
--     rvalid      => s_axi_lite_control_rvalid,
--     rready      => s_axi_lite_control_rready
-- );

-- drive_axilite_bus : process
-- begin
--     axil_cmd_read  <= '0';
--     axil_cmd_write <= '0';

--     wait until rising_edge(rst_over);
--         axil_cmd_write <= '1';
--         axil_cmd_waddr <= 1;
--         axil_cmd_wdata <= 1;
--         wait until rising_edge(axil_write_done);
--         axil_cmd_write <= '0';
--     wait for 20*clk_period_axi;
--         axil_cmd_read <= '1';
--         axil_cmd_raddr <= 1;
--         wait until rising_edge(axil_read_done);
--         axil_cmd_read <= '0';
--     wait for 20*clk_period_axi;
--     std.env.finish;
-- end process;