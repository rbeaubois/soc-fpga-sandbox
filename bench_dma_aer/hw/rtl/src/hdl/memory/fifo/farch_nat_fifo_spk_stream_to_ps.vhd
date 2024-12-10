library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.system_pkg.FPGA_ARCH;
use work.fpga_arch_pkg.fpga_arch_t;

entity farch_nat_fifo_spk_stream_to_ps is
    generic(
        DWIDTH: integer
    );
    port(
        rst        : in std_logic;
        wr_clk     : in std_logic;
        rd_clk     : in std_logic;
        din        : in std_logic_vector(DWIDTH-1 downto 0);
        wr_en      : in std_logic;
        rd_en      : in std_logic;
        dout       : out std_logic_vector(DWIDTH-1 downto 0);
        full       : out std_logic;
        empty      : out std_logic;
        wr_rst_busy: out std_logic;
        rd_rst_busy: out std_logic
    );
end entity farch_nat_fifo_spk_stream_to_ps;

architecture RTL of farch_nat_fifo_spk_stream_to_ps is
    -- Instanciation templates from IP catalog
    -- depending on FPGA architecture

    -- ==============================
    -- ZynqMP
    -- ==============================
    component nat_fifo_spk_stream_to_ps_ip_zynqmp
    port (
        rst         : in std_logic;
        wr_clk      : in std_logic;
        rd_clk      : in std_logic;
        din         : in std_logic_vector(DWIDTH-1 downto 0);
        wr_en       : in std_logic;
        rd_en       : in std_logic;
        dout        : out std_logic_vector(DWIDTH-1 downto 0);
        full        : out std_logic;
        empty       : out std_logic;
        wr_rst_busy : out std_logic;
        rd_rst_busy : out std_logic 
    );
    end component;
    
    -- ==============================
    -- Versal
    -- ==============================
    component nat_fifo_spk_stream_to_ps_ip_versal
    port (
        rst             : in std_logic;
        wr_clk          : in std_logic;
        wr_en           : in std_logic;
        rd_en           : in std_logic;
        din             : in std_logic_vector(31 downto 0);
        dout            : out std_logic_vector(31 downto 0);
        wr_rst_busy     : out std_logic;
        rd_rst_busy     : out std_logic;
        full            : out std_logic;
        empty           : out std_logic;
        wr_data_count   : out std_logic_vector(0 downto 0) 
    );
    end component;
begin
    gen_farch_nat_fifo_spk_stream_to_ps : if FPGA_ARCH = ZYNQMP generate
        nat_fifo_spk_stream_to_ps_ip_zynqmp_inst : nat_fifo_spk_stream_to_ps_ip_zynqmp
        port map (
            rst         => rst,
            wr_clk      => wr_clk,
            rd_clk      => rd_clk,
            din         => din,
            wr_en       => wr_en,
            rd_en       => rd_en,
            dout        => dout,
            full        => full,
            empty       => empty,
            wr_rst_busy => wr_rst_busy,
            rd_rst_busy => rd_rst_busy
        );
    elsif FPGA_ARCH = VERSAL generate
        nat_fifo_spk_stream_to_ps_ip_versal_inst : nat_fifo_spk_stream_to_ps_ip_versal
        port map (
            rst             => rst,
            wr_clk          => wr_clk,
            wr_en           => wr_en,
            rd_en           => rd_en,
            din             => din,
            dout            => dout,
            wr_rst_busy     => wr_rst_busy,
            rd_rst_busy     => rd_rst_busy,
            full            => full,
            empty           => empty,
            wr_data_count   => open
        );
    end generate gen_farch_nat_fifo_spk_stream_to_ps;
end architecture RTL;
