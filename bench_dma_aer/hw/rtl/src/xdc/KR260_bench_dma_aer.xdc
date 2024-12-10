set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design];

#  ███████  █████  ███    ██ 
#  ██      ██   ██ ████   ██ 
#  █████   ███████ ██ ██  ██ 
#  ██      ██   ██ ██  ██ ██ 
#  ██      ██   ██ ██   ████ 
#                            
# Fan speed enable (inverted logic -> 0 enable the fan)
set_property -dict {PACKAGE_PIN A12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {fan_pwm_ctrl}]; # Fan control (schematic HDA20)


#  ██    ██ ███████ ███████ ██████      ██      ███████ ██████  
#  ██    ██ ██      ██      ██   ██     ██      ██      ██   ██ 
#  ██    ██ ███████ █████   ██████      ██      █████   ██   ██ 
#  ██    ██      ██ ██      ██   ██     ██      ██      ██   ██ 
#   ██████  ███████ ███████ ██   ██     ███████ ███████ ██████  
#                                                               
# 
set_property -dict {PACKAGE_PIN F8 IOSTANDARD LVCMOS18} [get_ports {uled_uf1}]; # User led UF1 (schematic: HPA14_P)
set_property -dict {PACKAGE_PIN E8 IOSTANDARD LVCMOS18} [get_ports {uled_uf2}]; # User led UF2 (schematic: HPA14_N)


#  ██████  ███    ███  ██████  ██████       ██ 
#  ██   ██ ████  ████ ██    ██ ██   ██     ███ 
#  ██████  ██ ████ ██ ██    ██ ██   ██      ██ 
#  ██      ██  ██  ██ ██    ██ ██   ██      ██ 
#  ██      ██      ██  ██████  ██████       ██ 
#                                              
# PMOD1 pins in Digilent naming
# -> Digilent standard              On board pinout
# | VCC | GND | 3 | 2 | 1 | 0 |     | 11 |  9 | 7 | 5 | 3 | 1 |
# | VCC | GND | 7 | 6 | 5 | 4 |     | 12 | 10 | 8 | 6 | 4 | 2 |
# PMOD1 Digilent 0->7
set_property -dict {PACKAGE_PIN H12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod1[0]}]; # PMOD1 Digilent 0
set_property -dict {PACKAGE_PIN E10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod1[1]}]; # PMOD1 Digilent 1
set_property -dict {PACKAGE_PIN D10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod1[2]}]; # PMOD1 Digilent 2
set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod1[3]}]; # PMOD1 Digilent 3
set_property -dict {PACKAGE_PIN B10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod1[4]}]; # PMOD1 Digilent 4
set_property -dict {PACKAGE_PIN E12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod1[5]}]; # PMOD1 Digilent 5
set_property -dict {PACKAGE_PIN D11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod1[6]}]; # PMOD1 Digilent 6
set_property -dict {PACKAGE_PIN B11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod1[7]}]; # PMOD1 Digilent 7


#  ██████  ███    ███  ██████  ██████      ██████  
#  ██   ██ ████  ████ ██    ██ ██   ██          ██ 
#  ██████  ██ ████ ██ ██    ██ ██   ██      █████  
#  ██      ██  ██  ██ ██    ██ ██   ██     ██      
#  ██      ██      ██  ██████  ██████      ███████ 
#                                                  
# PMOD2 pins in Digilent naming
# -> Digilent standard              On board pinout
# | VCC | GND | 3 | 2 | 1 | 0 |     | 11 |  9 | 7 | 5 | 3 | 1 |
# | VCC | GND | 7 | 6 | 5 | 4 |     | 12 | 10 | 8 | 6 | 4 | 2 |
# PMOD1 Digilent 0->7
set_property -dict {PACKAGE_PIN J11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod2[0]}];  # PMOD1 Digilent 0
set_property -dict {PACKAGE_PIN J10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod2[1]}];  # PMOD1 Digilent 1
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod2[2]}];  # PMOD1 Digilent 2
set_property -dict {PACKAGE_PIN K12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod2[3]}];  # PMOD1 Digilent 3
set_property -dict {PACKAGE_PIN H11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod2[4]}];  # PMOD1 Digilent 4
set_property -dict {PACKAGE_PIN G10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod2[5]}];  # PMOD1 Digilent 5
set_property -dict {PACKAGE_PIN F12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod2[6]}];  # PMOD1 Digilent 6
set_property -dict {PACKAGE_PIN F11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod2[7]}];  # PMOD1 Digilent 7


#  ██████  ███    ███  ██████  ██████      ██████  
#  ██   ██ ████  ████ ██    ██ ██   ██          ██ 
#  ██████  ██ ████ ██ ██    ██ ██   ██      █████  
#  ██      ██  ██  ██ ██    ██ ██   ██          ██ 
#  ██      ██      ██  ██████  ██████      ██████  
#                                                  
# PMOD3 pins in Digilent naming
# -> Digilent standard              On board pinout
# | VCC | GND | 3 | 2 | 1 | 0 |     | 11 |  9 | 7 | 5 | 3 | 1 |
# | VCC | GND | 7 | 6 | 5 | 4 |     | 12 | 10 | 8 | 6 | 4 | 2 |
set_property -dict {PACKAGE_PIN AE12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod3[0]}]; # PMOD3 Digilent 0
set_property -dict {PACKAGE_PIN AF12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod3[1]}]; # PMOD3 Digilent 1
set_property -dict {PACKAGE_PIN AG10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod3[2]}]; # PMOD3 Digilent 2
set_property -dict {PACKAGE_PIN AH10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod3[3]}]; # PMOD3 Digilent 3
set_property -dict {PACKAGE_PIN AF11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod3[4]}]; # PMOD3 Digilent 4
set_property -dict {PACKAGE_PIN AG11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod3[5]}]; # PMOD3 Digilent 5
set_property -dict {PACKAGE_PIN AH12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod3[6]}]; # PMOD3 Digilent 6
set_property -dict {PACKAGE_PIN AH11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod3[7]}]; # PMOD3 Digilent 7


#  ██████  ███    ███  ██████  ██████      ██   ██ 
#  ██   ██ ████  ████ ██    ██ ██   ██     ██   ██ 
#  ██████  ██ ████ ██ ██    ██ ██   ██     ███████ 
#  ██      ██  ██  ██ ██    ██ ██   ██          ██ 
#  ██      ██      ██  ██████  ██████           ██ 
#                                                  
# PMOD4 pins in Digilent naming
# -> Digilent standard              On board pinout
# | VCC | GND | 3 | 2 | 1 | 0 |     | 11 |  9 | 7 | 5 | 3 | 1 |
# | VCC | GND | 7 | 6 | 5 | 4 |     | 12 | 10 | 8 | 6 | 4 | 2 |
set_property -dict {PACKAGE_PIN AC12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod4[0]}]; # PMOD4 Digilent 0
set_property -dict {PACKAGE_PIN AD12 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod4[1]}]; # PMOD4 Digilent 1
set_property -dict {PACKAGE_PIN AE10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod4[2]}]; # PMOD4 Digilent 2
set_property -dict {PACKAGE_PIN AF10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod4[3]}]; # PMOD4 Digilent 3
set_property -dict {PACKAGE_PIN AD11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod4[4]}]; # PMOD4 Digilent 4
set_property -dict {PACKAGE_PIN AD10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod4[5]}]; # PMOD4 Digilent 5
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod4[6]}]; # PMOD4 Digilent 6
set_property -dict {PACKAGE_PIN AA10 IOSTANDARD LVCMOS33 SLEW SLOW DRIVE 4} [get_ports {pmod4[7]}]; # PMOD4 Digilent 7