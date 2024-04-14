module VGA_Decoder (
	
    input Reset,
	 input unsigned [31:0] Address, 	//[7:0] Address = [7:0] octl
												//[15:8] Address = [7:0] ocry
												//[23:16] Address = [7:0] ocrx
    input VGASelect_H,
	 input [7:0] DataIn,

    output reg [7:0] ocrx,
	 output reg [7:0] ocry,
	 output reg [7:0] octl,
	 
	 output reg VGA_Enable_H
);

always@(*) begin
	
	if(Address[23:16] == 8'b11110000 && VGASelect_H == 1) begin
       VGA_Enable_H <= 1;
	end
	else begin
		 VGA_Enable_H <= 0;
	end
	
	
	
	if(Reset == 1) begin
		ocrx <= 8'd40;
		ocry <= 8'd20;
		octl <= 8'b11110010;
	end
	
	
	
	//////00F0 F012////////
	
	if(Address[23:0] == 24'b111100001111000000010010 && VGASelect_H == 1) begin
		ocrx <= DataIn;
	end
	
	//////00F0 F022////////
	
	if(Address[23:0] == 24'b111100001111000000100010 && VGASelect_H == 1) begin
		ocry <= DataIn;
	end
	
	//////00F0 F044////////
	
	if(Address[23:0] == 24'b111100001111000001000100 && VGASelect_H == 1) begin
		octl <= DataIn;
	end
			
end

endmodule