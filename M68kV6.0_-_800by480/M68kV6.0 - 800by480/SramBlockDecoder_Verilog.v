module SramBlockDecoder_Verilog( 
		input unsigned [16:0] Address, // lower 17 lines of address bus from 68k
		input SRamSelect_H,				 // from main (top level) address decoder indicating 68k is talking to Sram
		
		// 4 separate block select signals that parition 256kbytes (128k words) into 4 blocks of 64k (32 k words)
		output reg Block0_H, 
		output reg Block1_H, 
		output reg Block2_H, 
		output reg Block3_H 
);	

	reg [1:0] decode;
	reg [3:0] block;

	always@(*)	
		begin
			// decode the top two address lines plus SRamSelect to provide 4 block select signals
			// for 4 blocks of 64k bytes (32k words) to give 256k bytes in total
			
			decode <= Address[16:15];
			
			if(SRamSelect_H == 1) //00 for 0, 01 for 1, 10 for 2 and 11 for 3 and ensure active high
				begin
					case(decode)
						2'b00: block = 4'b0001;
						2'b01: block = 4'b0010;
						2'b10: block = 4'b0100;
						2'b11: block = 4'b1000;
						default: block = 4'b0000;
					endcase
					
					Block0_H = block[0]; 
					Block1_H = block[1];
					Block2_H = block[2];
					Block3_H = block[3];
				end
			else 
				begin
					Block0_H = 0; 
					Block1_H = 0; 
					Block2_H = 0; 
					Block3_H = 0; 
				end
		end
endmodule
