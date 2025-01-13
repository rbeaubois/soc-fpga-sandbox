library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.system_pkg.FPGA_ARCH;
use work.fpga_arch_pkg.fpga_arch_t;

entity farch_fifo_cdc_dma_spk2pl is
    generic(
        DWIDTH: integer;
        AWIDTH: integer
    );
    port(
        rst           : in std_logic;
        wr_clk        : in std_logic;
        rd_clk        : in std_logic;
        din           : in std_logic_vector(DWIDTH-1 downto 0);
        wr_en         : in std_logic;
        rd_en         : in std_logic;
        dout          : out std_logic_vector(DWIDTH-1 downto 0);
        full          : out std_logic;
        empty         : out std_logic;
        wr_rst_busy   : out std_logic;
        rd_rst_busy   : out std_logic;
        rd_data_count : out std_logic_vector(AWIDTH-1 downto 0);
        wr_data_count : out std_logic_vector(AWIDTH-1 downto 0)
    );
end entity farch_fifo_cdc_dma_spk2pl;

architecture RTL of farch_fifo_cdc_dma_spk2pl is
    -- Instanciation templates from IP catalog
    -- depending on FPGA architecture

    -- ==============================
    -- ZynqMP
    -- ==============================
    component nat_fifo_cdc_dma_spk2pl_ip_zynqmp
    port (
        rst           : in std_logic;
        wr_clk        : in std_logic;
        rd_clk        : in std_logic;
        din           : in std_logic_vector(DWIDTH-1 downto 0);
        wr_en         : in std_logic;
        rd_en         : in std_logic;
        dout          : out std_logic_vector(DWIDTH-1 downto 0);
        full          : out std_logic;
        empty         : out std_logic;
        wr_rst_busy   : out std_logic;
        rd_rst_busy   : out std_logic;
        rd_data_count : out std_logic_vector(AWIDTH-1 downto 0);
        wr_data_count : out std_logic_vector(AWIDTH-1 downto 0)
    );
    end component;
    
    -- ==============================
    -- Versal
    -- ==============================
    component nat_fifo_cdc_dma_spk2pl_ip_versal
    port (
        rst             : in std_logic;
        wr_clk          : in std_logic;
        rd_clk          : in std_logic;
        wr_en           : in std_logic;
        rd_en           : in std_logic;
        din             : in std_logic_vector(DWIDTH-1 downto 0);
        dout            : out std_logic_vector(DWIDTH-1 downto 0);
        wr_rst_busy     : out std_logic;
        rd_rst_busy     : out std_logic;
        full            : out std_logic;
        empty           : out std_logic;
        rd_data_count   : out std_logic_vector(AWIDTH-1 downto 0);
        wr_data_count   : out std_logic_vector(AWIDTH-1 downto 0)
    );
    end component;
begin
    gen_farch_fifo_cdc_dma_spk2pl : if FPGA_ARCH = ZYNQMP generate
        farch_fifo_cdc_dma_spk2pl_zynqmp : nat_fifo_cdc_dma_spk2pl_ip_zynqmp
        port map (
            rst             => rst,
            wr_clk          => wr_clk,
            rd_clk          => rd_clk,
            din             => din,
            wr_en           => wr_en,
            rd_en           => rd_en,
            dout            => dout,
            full            => full,
            empty           => empty,
            rd_data_count   => rd_data_count,
            wr_data_count   => wr_data_count,
            wr_rst_busy     => open,
            rd_rst_busy     => open
        );
    elsif FPGA_ARCH = VERSAL generate
        farch_fifo_cdc_dma_spk2pl_versal : nat_fifo_cdc_dma_spk2pl_ip_versal
        port map (
            rst             => rst,
            wr_clk          => wr_clk,
            rd_clk          => rd_clk,
            wr_en           => wr_en,
            rd_en           => rd_en,
            din             => din,
            dout            => dout,
            wr_rst_busy     => wr_rst_busy,
            rd_rst_busy     => rd_rst_busy,
            full            => full,
            empty           => empty,
            rd_data_count   => rd_data_count,
            wr_data_count   => wr_data_count
        );
    end generate gen_farch_fifo_cdc_dma_spk2pl;
end architecture RTL;