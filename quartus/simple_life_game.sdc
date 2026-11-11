
create_clock -name clk -period 40.000 [get_ports {clk_in}]\

derive_clock_uncertainty

derive_pll_clocks

set_false_path -from [get_ports {RESET_BUTTON RX_DATA}]

set_false_path -to [get_ports { \
    RESET_LIGHT \
    BLINK_OUT \
    NEW_GEN_LIGHT \
    NEW_INIT_STATE_LIGHT \
    RX_BLINK \
    VGA_OUT \
    HSYNC \
    VSYNC \
    TX_DATA \
}]