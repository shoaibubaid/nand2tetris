
# PYNQ-Z2 PL reference clock: 125 MHz
set_property -dict { PACKAGE_PIN H16 IOSTANDARD LVCMOS33 } [get_ports ref_clk_125]
create_clock -name ref_clk_125 -period 8.000 [get_ports ref_clk_125]

# HDMI output clock pair
set_property -dict { PACKAGE_PIN L16 IOSTANDARD TMDS_33 } [get_ports hdmi_clk_p]
set_property -dict { PACKAGE_PIN L17 IOSTANDARD TMDS_33 } [get_ports hdmi_clk_n]

# HDMI data lane 0: Blue
set_property -dict { PACKAGE_PIN K17 IOSTANDARD TMDS_33 } [get_ports {hdmi_data_p[0]}]
set_property -dict { PACKAGE_PIN K18 IOSTANDARD TMDS_33 } [get_ports {hdmi_data_n[0]}]

# HDMI data lane 1: Green
set_property -dict { PACKAGE_PIN K19 IOSTANDARD TMDS_33 } [get_ports {hdmi_data_p[1]}]
set_property -dict { PACKAGE_PIN J19 IOSTANDARD TMDS_33 } [get_ports {hdmi_data_n[1]}]

# HDMI data lane 2: Red
set_property -dict { PACKAGE_PIN J18 IOSTANDARD TMDS_33 } [get_ports {hdmi_data_p[2]}]
set_property -dict { PACKAGE_PIN H18 IOSTANDARD TMDS_33 } [get_ports {hdmi_data_n[2]}]
