
createdts -hw /home/canica/ws/soc-fpga-sandbox/template/hw/rtl/tcl/../prj/template/template.xsa -platform-name KR260  -git-branch xlnx_rel_v2023.2  -overlay -zocl -compile  -out /home/canica/ws/soc-fpga-sandbox/template/hw/rtl/tcl/../prj/template/template_dtc
file copy /home/canica/ws/soc-fpga-sandbox/template/hw/rtl/tcl/../prj/template/template_dtc/KR260/psu_cortexa53_0/device_tree_domain/bsp/pl.dtsi  /home/canica/ws/soc-fpga-sandbox/template/hw/rtl/tcl/../prj/template/template.dtsi
exec bash -c "patch /home/canica/ws/soc-fpga-sandbox/template/hw/rtl/tcl/../prj/template/template.dtsi < /home/canica/ws/soc-fpga-sandbox/template/hw/rtl/tcl/../prj/template/../../tcl/dtc.patch"
                    
