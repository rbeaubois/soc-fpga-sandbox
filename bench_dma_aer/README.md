# Bench DMA AER

* Width of buffer length of DMA is for now set to 16 to allow buffer transfers of maximum size 65,536 bytes

## Generate firmware

### Generate hardware

**GUI**
* Launch Vivado
* Run project creation tcl script `Tools > Run Tcl Script` select `create_vivado_prj_KR260_v2023_2.tcl`
* Run generate bitstream `Program and Debug > Generate Bitstream`
* Export hardware `File > Export > Export Hardware`
  - [x] include bitstream

**Command line**
```tcl
vivado -mode tcl
source create_vivado_prj_KR260_v2023_2.tcl
set nb_jobs 8
generate_xsa $nb_jobs
```

> **Generation parameters in `system_pkg.vhd`**
> :warning: Update hardware unique identifier `HW_UID` if regenerating.
> :warning: Check if `PRJ_ROOT_PATH` is correct.
> :warning: Check if `FPGA_ARCH` matches the target architecture.
> :warning: Check if hwconfig files are generated, otherwise refresh hierarchy in Vivado with `H_HWCONFIG_GEN` set to `true`. (In case of Vivado crash with no errors and TCL console dumping segfault non sense, set it to false and relaunch bitstream generation)

> :exclamation: **Update tcl generating block design**
> ```tcl
> # Function added by the custom tcl
> update_tcl_bd
> # Manually
> write_bd_tcl -include_layout -force new_bd.tcl
> ```

### Generate device-tree

* Generate device tree using xsct

```bash
source <xilinx_tools_path>/Vitis/<version>/settings64.sh 
xsct

# KR260
createdts -hw system_wrapper.xsa -platform-name KR260 -git-branch xlnx_rel_v2024.1 -overlay -zocl -compile -out dtc 
```

* Extract dtsi

```
# KR260
cp ./dtc/KR260/psu_cortexa53_0/device_tree_domain/bsp/pl.dtsi system_wrapper.dtsi   
```

### Update device-tree

* Add dma_proxy driver node:


```c
dma_proxy_driver_node: dma_proxy {
    compatible ="xlnx,dma_proxy";
	dmas = <&axi_dma_spk 0 &axi_dma_spk 1>;
	dma-names = "dma_proxy_spk_to_pl", "dma_proxy_spk_to_ps";
	//dma-coherent; // dma-coherent doesn't work properly with SG for tx
};
```

* Rename axi gpio node name (displayed as UIO device name) to match C++ application bindings
	* axi_gpio_free_slots_to_pl: <del>axigpio_dualch_intr</del> `axi_gpio_free_slots_to_pl`@a0010000
	* axi_gpio_ready_ev_to_ps: <del>axigpio_dualch_intr</del> `axi_gpio_ready_ev_to_ps`@a0011000

* Change compatibility to UIO driver `compatible = "generic-uio";` for:
    * axi_gpio_free_slots_to_pl
    * axi_gpio_ready_ev_to_ps
    * bench_dma_aer

## Build software

* Copy `sw/target` on target

* Rename `target` to project name `bench_dma_aer`

* Move to project directory

```bash
cd bench_dma_aer
```
* Initialize project

```bash
chmod u+x ./init.sh
source ./init.sh kr260
```

> :exclamation: If reinstalling, you want to check if previous env variable is remove in `~/.bashrc`

* Build project

```bash
./build.sh
```

> :exclamation: On Ubuntu, if the C++ application build crashes with some libraries, clean and rebuild application
> :warning: Check if depedencies are installed 
> * PetaLinux: `sudo dnf install zeromq-dev`
> * Ubuntu: `sudo apt-get install libzmq3-dev`

* Run the thing

```bash
./launch_app.sh ./config/swconfig_test.json
```

> :warning: Check if `launch_app.sh` runs debug or release mode and whether C++ application was build for release or debug

* Check results (if save enabled)

```bash
cat ./data/send_spk.csv
cat ./data/recv_spk.csv
```

> **Some useful debug checks**
> * Check if interrupts listed correctly
> `cat /proc/interrupts`
> * Check if device-tree loaded correctly
> `sudo dmesg`
> * Use ILA (debug core) with Vivado
> 	* Start the board
> 	* Connect to target and program device with vivado
> 	* Comment `firmware/activate.sh` and `firmware/deactivate.sh` statement in `app/run.sh`
> 	* Activate firmware `firmware/activate.sh`
> 	* Arm ILA in Vivado
> 	* Launch application `./launch_app.sh <swconfig_*.json>`