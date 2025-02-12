library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.system_pkg.FPGA_ARCH;
use work.fpga_arch_pkg.fpga_arch_t;

entity farch_fifo_cdc_dma_sps2ps is
    generic(
        DWIDTH: integer
    );
    port(
        s_axis_aresetn      : in std_logic;
        s_axis_aclk         : in std_logic;
        s_axis_tvalid       : in std_logic;
        s_axis_tready       : out std_logic;
        s_axis_tdata        : in std_logic_vector( DWIDTH-1 downto 0 );
        s_axis_tlast        : in std_logic;
        m_axis_aclk         : in std_logic;
        m_axis_tvalid       : out std_logic;
        m_axis_tready       : in std_logic;
        m_axis_tdata        : out std_logic_vector( DWIDTH-1 downto 0 );
        m_axis_tlast        : out std_logic;
        axis_rd_data_count  : out std_logic_vector( DWIDTH-1 downto 0)
    );
end entity farch_fifo_cdc_dma_sps2ps;

architecture RTL of farch_fifo_cdc_dma_sps2ps is
    -- Instanciation templates from IP catalog
    -- depending on FPGA architecture

    -- ==============================
    -- ZynqMP
    -- ==============================
    component axis_data_fifo_cdc_dma_sps2ps_ip_zynqmp is
        port ( 
            s_axis_aresetn      : in std_logic;
            s_axis_aclk         : in std_logic;
            s_axis_tvalid       : in std_logic;
            s_axis_tready       : out std_logic;
            s_axis_tdata        : in std_logic_vector( DWIDTH-1 downto 0 );
            s_axis_tlast        : in std_logic;
            m_axis_aclk         : in std_logic;
            m_axis_tvalid       : out std_logic;
            m_axis_tready       : in std_logic;
            m_axis_tdata        : out std_logic_vector( DWIDTH-1 downto 0 );
            m_axis_tlast        : out std_logic;
            axis_rd_data_count  : out std_logic_vector( DWIDTH-1 downto 0)
        );
    end component;
    
    -- ==============================
    -- Versal
    -- ==============================
    component axis_data_fifo_cdc_dma_sps2ps_ip_versal is
        port ( 
            s_axis_aresetn      : in std_logic;
            s_axis_aclk         : in std_logic;
            s_axis_tvalid       : in std_logic;
            s_axis_tready       : out std_logic;
            s_axis_tdata        : in std_logic_vector( DWIDTH-1 downto 0 );
            s_axis_tlast        : in std_logic;
            m_axis_aclk         : in std_logic;
            m_axis_tvalid       : out std_logic;
            m_axis_tready       : in std_logic;
            m_axis_tdata        : out std_logic_vector( DWIDTH-1 downto 0 );
            m_axis_tlast        : out std_logic;
            axis_rd_data_count  : out std_logic_vector( DWIDTH-1 downto 0)
        );
    end component;
begin
    gen_farch_fifo_cdc_dma_sps2ps : if FPGA_ARCH = ZYNQMP generate
        nat_fifo_cdc_dma_spk2ps_ip_zynqmp_inst : axis_data_fifo_cdc_dma_sps2ps_ip_zynqmp
        port map (
            s_axis_aresetn      => s_axis_aresetn,
            s_axis_aclk         => s_axis_aclk,
            s_axis_tvalid       => s_axis_tvalid,
            s_axis_tready       => s_axis_tready,
            s_axis_tdata        => s_axis_tdata,
            s_axis_tlast        => s_axis_tlast,
            m_axis_aclk         => m_axis_aclk,
            m_axis_tvalid       => m_axis_tvalid,
            m_axis_tready       => m_axis_tready,
            m_axis_tdata        => m_axis_tdata,
            m_axis_tlast        => m_axis_tlast,
            axis_rd_data_count  => axis_rd_data_count
        );
    elsif FPGA_ARCH = VERSAL generate
        nat_fifo_cdc_dma_spk2ps_ip_versal_inst : axis_data_fifo_cdc_dma_sps2ps_ip_versal
        port map (
            s_axis_aresetn      => s_axis_aresetn,
            s_axis_aclk         => s_axis_aclk,
            s_axis_tvalid       => s_axis_tvalid,
            s_axis_tready       => s_axis_tready,
            s_axis_tdata        => s_axis_tdata,
            s_axis_tlast        => s_axis_tlast,
            m_axis_aclk         => m_axis_aclk,
            m_axis_tvalid       => m_axis_tvalid,
            m_axis_tready       => m_axis_tready,
            m_axis_tdata        => m_axis_tdata,
            m_axis_tlast        => m_axis_tlast,
            axis_rd_data_count  => axis_rd_data_count
        );
    end generate gen_farch_fifo_cdc_dma_sps2ps;
end architecture RTL;