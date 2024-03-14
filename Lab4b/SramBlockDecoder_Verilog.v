module SramBlockDecoder_Verilog( 
		input unsigned [16:0] Address, // lower 17 lines of address bus from 68k
		input SRamSelect_H,				 // from main (top level) address decoder indicating 68k is talking to Sram
		
		// 4 separate block select signals that parition 256kbytes (128k words) into 4 blocks of 64k (32 k words)
		output reg Block0_H, 
		output reg Block1_H, 
		output reg Block2_H, 
		output reg Block3_H 
);	

	always@(*)	begin
	
		// check whether SRamSelect_H is enabled
		// Divide Address into 4 different ranges that correspond to a Block
		// Enable corresponding block ?
		
		
	
		// default block selects are inactive - override as appropriate later
		
		Block0_H <= 0; 
		Block1_H <= 0;
		Block2_H <= 0; 
		Block3_H <= 0;
		
		case({SRamSelect_H, Address[16:15]})
			3'b100: Block0_H <= 1;
			3'b101: Block1_H <= 1;
			3'b110: Block2_H <= 1;
			3'b111: Block3_H <= 1;
		endcase
	
		// decode the top two address lines plus SRamSelect to provide 4 block select signals
		// for 4 blocks of 64k bytes (32k words) to give 256k bytes in total
	
		// TODO
		
	end
endmodule
