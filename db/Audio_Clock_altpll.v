//altpll CBX_DECLARE_ALL_CONNECTED_PORTS="OFF" clk0_divide_by=4 clk0_duty_cycle=50 clk0_multiply_by=1 clk0_phase_shift="0" compensate_clock="CLK0" device_family="Cyclone V" inclk0_input_frequency=20000 intended_device_family="Cyclone II" lpm_hint="CBX_MODULE_PREFIX=Audio_Clock" operation_mode="normal" port_clk0="PORT_USED" port_clk1="PORT_UNUSED" port_clk2="PORT_UNUSED" port_clk3="PORT_UNUSED" port_clk4="PORT_UNUSED" port_clk5="PORT_UNUSED" port_extclk0="PORT_UNUSED" port_extclk1="PORT_UNUSED" port_extclk2="PORT_UNUSED" port_extclk3="PORT_UNUSED" port_inclk1="PORT_UNUSED" port_phasecounterselect="PORT_UNUSED" port_phasedone="PORT_UNUSED" port_scandata="PORT_UNUSED" port_scandataout="PORT_UNUSED" areset clk inclk locked CARRY_CHAIN="MANUAL" CARRY_CHAIN_LENGTH=48
//VERSION_BEGIN 24.1 cbx_altclkbuf 2025:03:05:20:03:09:SC cbx_altiobuf_bidir 2025:03:05:20:03:09:SC cbx_altiobuf_in 2025:03:05:20:03:09:SC cbx_altiobuf_out 2025:03:05:20:03:09:SC cbx_altpll 2025:03:05:20:03:09:SC cbx_cycloneii 2025:03:05:20:03:09:SC cbx_lpm_add_sub 2025:03:05:20:03:09:SC cbx_lpm_compare 2025:03:05:20:03:09:SC cbx_lpm_counter 2025:03:05:20:03:09:SC cbx_lpm_decode 2025:03:05:20:03:09:SC cbx_lpm_mux 2025:03:05:20:03:09:SC cbx_mgl 2025:03:05:20:10:25:SC cbx_nadder 2025:03:05:20:03:09:SC cbx_stratix 2025:03:05:20:03:09:SC cbx_stratixii 2025:03:05:20:03:09:SC cbx_stratixiii 2025:03:05:20:03:09:SC cbx_stratixv 2025:03:05:20:03:09:SC cbx_util_mgl 2025:03:05:20:03:09:SC  VERSION_END
//CBXI_INSTANCE_NAME="de1soc_wrapper_Audio_Controller_driver_Audio_Clock_Audio_Clock_altpll_altpll_component"
// synthesis VERILOG_INPUT_VERSION VERILOG_2001
// altera message_off 10463



// Copyright (C) 2025  Altera Corporation. All rights reserved.
//  Your use of Altera Corporation's design tools, logic functions 
//  and other software and tools, and any partner logic 
//  functions, and any output files from any of the foregoing 
//  (including device programming or simulation files), and any 
//  associated documentation or information are expressly subject 
//  to the terms and conditions of the Altera Program License 
//  Subscription Agreement, the Altera Quartus Prime License Agreement,
//  the Altera IP License Agreement, or other applicable license
//  agreement, including, without limitation, that your use is for
//  the sole purpose of programming logic devices manufactured by
//  Altera and sold by Altera or its authorized distributors.  Please
//  refer to the Altera Software License Subscription Agreements 
//  on the Quartus Prime software download page.



//synthesis_resources = generic_pll 1 
//synopsys translate_off
`timescale 1 ps / 1 ps
//synopsys translate_on
module  Audio_Clock_altpll
	( 
	areset,
	clk,
	fbout,
	inclk,
	locked) /* synthesis synthesis_clearbox=1 */;
	input   areset;
	output   [5:0]  clk;
	output   fbout;
	input   [1:0]  inclk;
	output   locked;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_off
`endif
	tri0   areset;
	tri0   [1:0]  inclk;
`ifndef ALTERA_RESERVED_QIS
// synopsys translate_on
`endif

	wire  wire_generic_pll1_fboutclk;
	wire  wire_generic_pll1_locked;
	wire  wire_generic_pll1_outclk;
	wire  fb_clkin;

	generic_pll   generic_pll1
	( 
	.fbclk(fb_clkin),
	.fboutclk(wire_generic_pll1_fboutclk),
	.locked(wire_generic_pll1_locked),
	.outclk(wire_generic_pll1_outclk),
	.refclk(inclk[0]),
	.rst(areset));
	defparam
		generic_pll1.duty_cycle = 50,
		generic_pll1.output_clock_frequency = "80000 ps",
		generic_pll1.phase_shift = "0 ps",
		generic_pll1.reference_clock_frequency = "20000 ps",
		generic_pll1.lpm_type = "generic_pll";
	assign
		clk = {{5{1'b0}}, wire_generic_pll1_outclk},
		fb_clkin = wire_generic_pll1_fboutclk,
		fbout = fb_clkin,
		locked = wire_generic_pll1_locked;
endmodule //Audio_Clock_altpll
//VALID FILE
