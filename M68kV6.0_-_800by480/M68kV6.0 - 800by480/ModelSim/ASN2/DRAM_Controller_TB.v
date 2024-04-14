`timescale 1ns/1ns

module DRAM_Controller_TB;

    reg Clock;
    reg Reset_L;
    reg unsigned [31:0] Address;
    reg unsigned [15:0] DataIn;
    reg UDS_L;
    reg LDS_L;
    reg DramSelect_L;
    reg WE_L;
    reg AS_L;

    wire unsigned[15:0] DataOut; 				// data bus out to 68000
	reg SDram_CKE_H;								// active high clock enable for dram chip
	reg SDram_CS_L;								// active low chip select for dram chip
	reg SDram_RAS_L;								// active low RAS select for dram chip
	reg SDram_CAS_L;								// active low CAS select for dram chip		
	reg SDram_WE_L;								// active low Write enable for dram chip
	wire unsigned [12:0] SDram_Addr;			// 13 bit address bus dram chip	
	wire unsigned [1:0] SDram_BA;				// 2 bit bank address
	//inout  reg unsigned [15:0] SDram_DQ,			// 16 bit bi-directional data lines to dram chip
			
	reg Dtack_L;									// Dtack back to CPU at end of bus cycle
	reg ResetOut_L;								// reset out to the CPU
	
	// Use only if you want to simulate dram controller state (e.g. for debugging)
	reg [4:0] DramState;

    //Instantiate Module to test
    M68kDramController_Verilog DUT (.*);

    //Clock Testbench
    always
        begin
            Clock <= 1; #10;
            Clock <= 0; #10;
        end

    //Reset Testbench
    initial
        begin
            {Reset_L, UDS_L, LDS_L, DramSelect_L, WE_L, AS_L} <= 6'b011111; 
            Address <= 32'h0;
            DataIn <= 16'h0;

            #10;

            Reset_L = 1;


            #120000

            Reset_L = 0;

            #1000;

            Reset_L = 1;

        end

endmodule   