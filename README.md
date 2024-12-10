# SoC FPGA Sandbox

* **bench_dma_aer**: PL<->PS transfers of AER format spikes through  AXI DMA
  * Send dummy stream to PL
  * PL forward stream to PS at a given time step
  * VHDL hardware configuration linked to C++ application by exporting header files

| **Tool**             | **Version**       | **Supported Architectures**      | **Notes**                                                                                   |
|----------------------|-------------------|----------------------------------|---------------------------------------------------------------------------------------------|
| **Vivado**           | 2023.2    | ZynqMP (KR260)   | GUI or command line |
| **Petalinux**        | 2023.2    | ZynqMP (KR260)   | Self-hosted to build in target's userspace|
