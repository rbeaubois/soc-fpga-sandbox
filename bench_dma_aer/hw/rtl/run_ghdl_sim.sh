STANDARD='08'
ghdl -a --std=$STANDARD src/hdl/common/utils/futils_pkg.vhd
ghdl -a --std=$STANDARD src/hdl/common/utils/fpga_arch_pkg.vhd
ghdl -a --std=$STANDARD src/hdl/common/utils/axilite_mapper_pkg.vhd
ghdl -a --std=$STANDARD src/hdl/common/system_pkg.vhd
ghdl -a --std=$STANDARD src/hdl/common/axilite_cores_pkg.vhd
ghdl -a --std=$STANDARD src/tb/tb_ghdl.vhd
ghdl -e --std=$STANDARD tb_ghdl
ghdl -r --std=$STANDARD tb_ghdl