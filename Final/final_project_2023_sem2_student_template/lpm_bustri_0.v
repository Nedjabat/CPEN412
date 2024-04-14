// Copyright (C) 2018  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and its AMPP partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 18.1.0 Build 625 09/12/2018 SJ Standard Edition"
// CREATED		"Mon Jan 03 18:14:04 2022"


module lpm_bustri_0(enabledt,enabletr,data,result);
input enabledt;
input enabletr;
input [15:0] data;
output [15:0] result;

lpm_bustri	lpm_instance(.enabledt(enabledt),.enabletr(enabletr),.data(data),.result(result));
	defparam	lpm_instance.LPM_WIDTH = 16;

endmodule
