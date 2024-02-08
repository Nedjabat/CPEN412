//////////////////////////////////////////////////////////////////////////////////////-
// Simple DRAM controller for the DE1 board, assuming a 50MHz controller/memory clock
// Assuming 64Mbytes SDRam organised as 32Meg x16 bits with 8192 rows (13 bit row addr
// 1024 columns (10 bit column address) and 4 banks (2 bit bank address)
// CAS latency is 2 clock periods
//
// designed to work with 68000 cpu using 16 bit data bus and 32 bit address bus
// separate upper and lower data stobes for individual byte and 16 bit word access
//
// Copyright PJ Davies June 2020
//////////////////////////////////////////////////////////////////////////////////////-


module M68kDramController_Verilog (
			input Clock,								// used to drive the state machine- stat changes occur on positive edge
			input Reset_L,     						// active low reset 
			input unsigned [31:0] Address,		// address bus from 68000
			input unsigned [15:0] DataIn,			// data bus in from 68000
			input UDS_L,								// active low signal driven by 68000 when 68000 transferring data over data bit 15-8
			input LDS_L, 								// active low signal driven by 68000 when 68000 transferring data over data bit 7-0
			input DramSelect_L,     				// active low signal indicating dram is being addressed by 68000
			input WE_L,  								// active low write signal, otherwise assumed to be read
			input AS_L,									// Address Strobe
			
			output reg unsigned[15:0] DataOut, 				// data bus out to 68000
			output reg SDram_CKE_H,								// active high clock enable for dram chip
			output reg SDram_CS_L,								// active low chip select for dram chip
			output reg SDram_RAS_L,								// active low RAS select for dram chip
			output reg SDram_CAS_L,								// active low CAS select for dram chip		
			output reg SDram_WE_L,								// active low Write enable for dram chip
			output reg unsigned [12:0] SDram_Addr,			// 13 bit address bus dram chip	
			output reg unsigned [1:0] SDram_BA,				// 2 bit bank address
			inout  reg unsigned [15:0] SDram_DQ,			// 16 bit bi-directional data lines to dram chip
			
			output reg Dtack_L,									// Dtack back to CPU at end of bus cycle
			output reg ResetOut_L,								// reset out to the CPU
	
			// Use only if you want to simulate dram controller state (e.g. for debugging)
			output reg [4:0] DramState
		); 	
		
		// WIRES and REGs
		
		reg  	[4:0] Command;										// 5 bit signal containing Dram_CKE_H, SDram_CS_L, SDram_RAS_L, SDram_CAS_L, SDram_WE_L

		reg	TimerLoad_H ;										// logic 1 to load Timer on next clock
		reg   TimerDone_H ;										// set to logic 1 when timer reaches 0
		reg 	unsigned	[15:0] Timer;							// 16 bit timer value
		reg 	unsigned	[15:0] TimerValue;					// 16 bit timer preload value

		reg	RefreshTimerLoad_H;								// logic 1 to load refresh timer on next clock
		reg   RefreshTimerDone_H ;								// set to 1 when refresh timer reaches 0
		reg 	unsigned	[15:0] RefreshTimer;					// 16 bit refresh timer value
		reg 	unsigned	[15:0] RefreshTimerValue;			// 16 bit refresh timer preload value

		reg   unsigned [4:0] CurrentState;					// holds the current state of the dram controller
		reg   unsigned [4:0] NextState;						// holds the next state of the dram controller
		
		reg  	unsigned [1:0] BankAddress;
		reg  	unsigned [12:0] DramAddress;
		
		reg	DramDataLatch_H;									// used to indicate that data from SDRAM should be latched and held for 68000 after the CAS latency period
		reg  	unsigned [15:0]SDramWriteData;
		
		reg  FPGAWritingtoSDram_H;								// When '1' enables FPGA data out lines leading to SDRAM to allow writing, otherwise they are set to Tri-State "Z"
		reg  CPU_Dtack_L;											// Dtack back to CPU
		reg  CPUReset_L;

		reg unsigned [15:0] RefreshCount;
		reg unsigned [15:0] NOPCount;
		reg unsigned [15:0] ProgNOPCount;
		reg unsigned [15:0] RefreshNOPCount;		

		// 5 bit Commands to the SDRam

		parameter PoweringUp = 5'b00000 ;					// take CKE & CS low during power up phase, address and bank address = dont'care
		parameter DeviceDeselect  = 5'b11111;				// address and bank address = dont'care
		parameter NOP = 5'b10111;								// address and bank address = dont'care
		parameter BurstStop = 5'b10110;						// address and bank address = dont'care
		parameter ReadOnly = 5'b10101; 						// A10 should be logic 0, BA0, BA1 should be set to a value, other addreses = value
		parameter ReadAutoPrecharge = 5'b10101; 			// A10 should be logic 1, BA0, BA1 should be set to a value, other addreses = value
		parameter WriteOnly = 5'b10100; 						// A10 should be logic 0, BA0, BA1 should be set to a value, other addreses = value
		parameter WriteAutoPrecharge = 5'b10100 ;			// A10 should be logic 1, BA0, BA1 should be set to a value, other addreses = value
		parameter AutoRefresh = 5'b10001;
	
		parameter BankActivate = 5'b10011;					// BA0, BA1 should be set to a value, address A11-0 should be value
		parameter PrechargeSelectBank = 5'b10010;			// A10 should be logic 0, BA0, BA1 should be set to a value, other addreses = don't care
		
		parameter PrechargeAllBanks = 5'b10010;			// A10 should be logic 1, BA0, BA1 are dont'care, other addreses = don't care
		parameter ModeRegisterSet = 5'b10000;				// A10=0, BA1=0, BA0=0, Address = don't care
		parameter ExtModeRegisterSet = 5'b10000;			// A10=0, BA1=1, BA0=0, Address = value
		
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////-
// Define some states for our dram controller add to these as required - only 5 will be defined at the moment - add your own as required
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////-
	
		parameter InitialisingState = 5'h00;				// power on initialising state
		parameter WaitingForPowerUpState = 5'h01	;		// waiting for power up state to complete
		parameter IssueFirstNOP = 5'h02;						// issuing 1st NOP after power up
		parameter PrechargingAllBanks = 5'h03;
		parameter Idled = 5'h04;			
		
		
		// TODO - Add your own states as per your own design
		//parameter OneMoreNOP = 5'h05;
      parameter IssueNOP = 5'h06;
    	parameter Refresh = 5'h07;
      parameter NOPCheck = 5'h08;
      parameter ProgMode = 5'h09;
      parameter IssueNOPPostProg = 5'h0A;
      parameter LoadRefreshTimer = 5'h0B;
      parameter RefreshPrecharge = 5'h0C;
      parameter RefreshOneNOP = 5'h0D;
		parameter RefreshRefresh = 5'h0E;
		parameter RefreshNOPCheck = 5'h0F;


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// General Timer for timing and counting things: Loadable and counts down on each clock then produced a TimerDone signal and stops counting
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	always@(posedge Clock)
		if(TimerLoad_H == 1) 				// if we get the signal from another process to load the timer
			Timer <= TimerValue ;			// Preload timer
		else if(Timer != 16'd0) 			// otherwise, provided timer has not already counted down to 0, on the next rising edge of the clock		
			Timer <= Timer - 16'd1 ;		// subtract 1 from the timer value

	always@(Timer) begin
		TimerDone_H <= 0 ;					// default is not done
	
		if(Timer == 16'd0) 					// if timer has counted down to 0
			TimerDone_H <= 1 ;				// output '1' to indicate time has elapsed
	end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Refresh Timer: Loadable and counts down on each clock then produces a RefreshTimerDone signal and stops counting
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	always@(posedge Clock)
		if(RefreshTimerLoad_H == 1) 						// if we get the signal from another process to load the timer
			RefreshTimer  <= RefreshTimerValue ;		// Preload timer
		else if(RefreshTimer != 16'd0) 					// otherwise, provided timer has not already counted down to 0, on the next rising edge of the clock		
			RefreshTimer <= RefreshTimer - 16'd1 ;		// subtract 1 from the timer value

	always@(RefreshTimer) begin
		RefreshTimerDone_H <= 0 ;							// default is not done

		if(RefreshTimer == 16'd0) 								// if timer has counted down to 0
			RefreshTimerDone_H <= 1 ;						// output '1' to indicate time has elapsed
	end
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////-
// concurrent process state registers
// this process RECORDS the current state of the system.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

   always@(posedge Clock, negedge Reset_L)
	begin
		if(Reset_L == 0) 							// asynchronous reset
			CurrentState <= InitialisingState ;
			
		else 	begin									// state can change only on low-to-high transition of clock
			CurrentState <= NextState;		

			// these are the raw signals that come from the dram controller to the dram memory chip. 
			// This process expects the signals in the form of a 5 bit bus within the signal Command. The various Dram commands are defined above just beneath the architecture)

			SDram_CKE_H <= Command[4];			// produce the Dram clock enable
			SDram_CS_L  <= Command[3];			// produce the Dram Chip select
			SDram_RAS_L <= Command[2];			// produce the dram RAS
			SDram_CAS_L <= Command[1];			// produce the dram CAS
			SDram_WE_L  <= Command[0];			// produce the dram Write enable
			
			SDram_Addr  <= DramAddress;		// output the row/column address to the dram
			SDram_BA   	<= BankAddress;		// output the bank address to the dram

			// signals back to the 68000

			Dtack_L 		<= CPU_Dtack_L ;			// output the Dtack back to the 68000
			ResetOut_L 	<= CPUReset_L ;			// output the Reset out back to the 68000
			
			// The signal FPGAWritingtoSDram_H can be driven by you when you need to turn on or tri-state the data bus out signals to the dram chip data lines DQ0-15
			// when you are reading from the dram you have to ensure they are tristated (so the dram chip can drive them)
			// when you are writing, you have to drive them to the value of SDramWriteData so that you 'present' your data to the dram chips
			// of course during a write, the dram WE signal will need to be driven low and it will respond by tri-stating its outputs lines so you can drive data in to it
			// remember the Dram chip has bi-directional data lines, when you read from it, it turns them on, when you write to it, it turns them off (tri-states them)

			if(FPGAWritingtoSDram_H == 1) 			// if CPU is doing a write, we need to turn on the FPGA data out lines to the SDRam and present Dram with CPU data 
				SDram_DQ	<= SDramWriteData ;
			else
				SDram_DQ	<= 16'bZZZZZZZZZZZZZZZZ;			// otherwise tri-state the FPGA data output lines to the SDRAM for anything other than writing to it
		
			DramState <= CurrentState ;					// output current state - useful for debugging so you can see you state machine changing states etc
		end
	end	
	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////-
// Concurrent process to Latch Data from Sdram after Cas Latency during read
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////-

// this process will latch whatever data is coming out of the dram data lines on the FALLING edge of the clock you have to drive DramDataLatch_H to logic 1
// remember there is a programmable CAS latency for the Zentel dram chip on the DE1 board it's 2 or 3 clock cycles which has to be programmed by you during the initialisation
// phase of the dram controller following a reset/power on
//
// During a read, after you have presented CAS command to the dram chip you will have to wait 2 clock cyles and then latch the data out here and present it back
// to the 68000 until the end of the 68000 bus cycle

	always@(negedge Clock)
	begin
		if(DramDataLatch_H == 1)      			// asserted during the read operation
			DataOut <= SDram_DQ ;					// store 16 bits of data regardless of width - don't worry about tri state since that will be handled by buffers outside dram controller
	end
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////-
// next state and output logic
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	always@(*)
	begin
	
	// In Verilog/VHDL - you will recall - that combinational logic (i.e. logic with no storage) is created as long as you
	// provide a specific value for a signal in each and every possible path through a process
	// 
	// You can do this of course, but it gets tedious to specify a value for each signal inside every process state and every if-else test within those states
	// so the common way to do this is to define default values for all your signals and then override them with new values as and when you need to.
	// By doing this here, right at the start of a process, we ensure the compiler does not infer any storage for the signal, i.e. it creates
	// pure combinational logic (which is what we want)
	//
	// Let's start with default values for every signal and override as necessary, 
	//
	
		Command 	<= NOP ;												// assume no operation command for Dram chip
		NextState <= InitialisingState ;							// assume next state will always be idle state unless overridden the value used here is not important, we cimple have to assign something to prevent storage on the signal so anything will do
		
		//TimerValue <= 16'h0000;										// no timer value 
		//RefreshTimerValue <= 16'h0000 ;							// no refresh timer value
		TimerLoad_H <= 0;												// don't load Timer
		RefreshTimerLoad_H <= 0 ;									// don't load refresh timer
		DramAddress <= 13'h0000 ;									// no particular dram address
		BankAddress <= 2'b00 ;										// no particular dram bank address
		DramDataLatch_H <= 0;										// don't latch data yet
		CPU_Dtack_L <= 1 ;											// don't acknowledge back to 68000
		SDramWriteData <= 16'h0000 ;								// nothing to write in particular
		//CPUReset_L <= 0 ;												// default is reset to CPU (for the moment, though this will change when design is complete so that reset-out goes high at the end of the dram initialisation phase to allow CPU to resume)
		FPGAWritingtoSDram_H <= 0 ;								// default is to tri-state the FPGA data lines leading to bi-directional SDRam data lines, i.e. assume a read operation

		// put your current state/next state decision making logic here - here are a few states to get you started
		// during the initialising state, the drams have to power up and we cannot access them for a specified period of time (100 us)
		// we are going to load the timer above with a value equiv to 100us and then wait for timer to time out
	
		if(CurrentState == InitialisingState ) //0000
		begin
			CPUReset_L <= 0;
			TimerValue <= 16'd8;	
			TimerLoad_H <= 1;
			RefreshTimerValue <= 16'h0000;	
			//NOPCount <= 16'd0;							// chose a value equivalent to 100us at 50Mhz clock - you might want to shorten it to somthing small for simulation purposes
			//RefreshCount <= 16'd0;
			//RefreshNOPCount <= 0;			// on next edge of clock, timer will be loaded and start to time out
			TimerLoad_H <= 1 ;
			Command <= PoweringUp ;									// clock enable and chip select to the Zentel Dram chip must be held low (disabled) during a power up phase
			NextState <= WaitingForPowerUpState ;				// once we have loaded the timer, go to a new state where we wait for the 100us to elapse
		end
		else if(CurrentState == WaitingForPowerUpState) //0001
		begin
			Command <= PoweringUp ;
			CPUReset_L <= 0;			// no DRam clock enable or CS while witing for 100us timer
			if(TimerDone_H == 1) 
			begin					// if timer has timed out i.e. 100us have elapsed
				NextState <= IssueFirstNOP ;				// take CKE and CS to active and issue a 1st NOP command
			end
			else begin
				NextState <= WaitingForPowerUpState ;			// otherwise stay here until power up time delay finished
			end
		end
		else if(CurrentState == IssueFirstNOP) //0010
		begin	 		// issue a valid NOP
			CPUReset_L <= 0;
			Command <= NOP ;											// send a valid NOP command to the dram chip
			NextState <= PrechargingAllBanks;
		end		
		else if(CurrentState == PrechargingAllBanks) //0011
		begin
			CPUReset_L <= 0;
			Command <= PrechargeAllBanks;
			NextState <= IssueNOP;
			DramAddress[10] <= 1;
		end
		else if(CurrentState == IssueNOP) //0110
		begin
			CPUReset_L <= 0;
			Command <= NOP;
			NextState <= Refresh;
			DramAddress[10] <= 0;
		end
		else if(CurrentState == Refresh) //0111
		begin
			CPUReset_L <= 0;
			Command <= AutoRefresh;
			//RefreshCount = RefreshCount + 16'd1;
			if(RefreshCount == (16'd10)) 
			begin
				NextState <= ProgMode;
				//RefreshCount = 16'd0;
			end
			else 
			begin
				NextState <= NOPCheck;
			end
		end
		else if (CurrentState == NOPCheck) //1000
		begin
		CPUReset_L <= 0;
			Command <= NOP;
			//NOPCount <= NOPCount + 16'd1;
			if(NOPCount < (16'd3)) 
			begin
				NextState <= NOPCheck;
			end
			else 
			begin
				NextState <= Refresh;
				//NOPCount <= 16'd0;
			end
		end	
		else if (CurrentState == ProgMode) //1001
		begin
			CPUReset_L <= 0;
			Command <= ModeRegisterSet;
			NextState <= IssueNOPPostProg;
												//unsure if need to write load data
			DramAddress[10] <= 0;
			BankAddress <= 2'b00;
		end
		else if (CurrentState == IssueNOPPostProg) //1010
		begin
			CPUReset_L <= 0;
			Command <= NOP;
			if (ProgNOPCount < 16'd3) 
			begin
				NextState <= IssueNOPPostProg;
			end
			else 
			begin
				//ProgNOPCount <= 16'd0;
				NextState <= LoadRefreshTimer;
			end
		end
		else if (CurrentState == LoadRefreshTimer) //1011
		begin
			CPUReset_L <= 0;
			Command <= NOP;
			NextState <= Idled;
			RefreshTimerLoad_H <= 1;
			RefreshTimerValue <= 16'd375;
		end
		else if (CurrentState == Idled) //0100
			begin
			CPUReset_L <= 1;
			RefreshTimerLoad_H <= 0;
			Command <= NOP;
			CPUReset_L <= 1;
			//RefreshNOPCount <= 0;
			if(RefreshTimerDone_H == 1) 
			begin
				NextState <= RefreshPrecharge;
			end
			//else if ((DramSelect_L == 0) && (AS_L == 0)) begin
				//DramAddress <= Address[23:11];
				//BankAddress <= Address[25:24];
				//Command <= BankActivate;
			else 
			begin
				NextState <= Idled;	
			end
		end
		else if (CurrentState == RefreshPrecharge) //1100
		begin
			Command <= PrechargeAllBanks;
			NextState <= RefreshOneNOP;
			DramAddress[10] <= 1;
		end
		else if (CurrentState == RefreshOneNOP) //1101
			begin
			Command <= NOP;
			NextState <= RefreshRefresh;
			end
		else if (CurrentState == RefreshRefresh) //1110
			begin
			Command <= AutoRefresh;		
			NextState <= RefreshNOPCheck;
			end
		else if (CurrentState == RefreshNOPCheck) //1111
			begin
			Command <= NOP;
			//RefreshNOPCount <= RefreshNOPCount + 16'd1;
			if(RefreshNOPCount < (16'd3)) 
			begin
				NextState <= RefreshNOPCheck;
			end
			else 
			begin
				RefreshTimerLoad_H <= 1;
				NextState <= Idled;
			end
		end	
		else
		begin
			Command <= NOP;
			NextState <= Idled;
		end
	end
	always@(posedge Clock)
	begin
		if(CurrentState == InitialisingState ) 
		begin	
			ProgNOPCount <= 16'd0;
			NOPCount <= 16'd0;							// chose a value equivalent to 100us at 50Mhz clock - you might want to shorten it to somthing small for simulation purposes
			RefreshCount <= 16'd0;
			RefreshNOPCount <= 0;			// on next edge of clock, timer will be loaded and start to time out
			// once we have loaded the timer, go to a new state where we wait for the 100us to elapse
		end	
		else if(CurrentState == Refresh) 
		begin
			RefreshCount = RefreshCount + 16'd1;
			NOPCount <= 16'd0;
		end
		else if (CurrentState == NOPCheck) 
		begin
			NOPCount <= NOPCount + 16'd1;
		end	
		else if (CurrentState == ProgMode) 
		begin
			RefreshCount = 16'd0;
		end
		else if (CurrentState == IssueNOPPostProg) 
		begin
			ProgNOPCount <= ProgNOPCount + 16'd1;
		end
		else if (CurrentState == LoadRefreshTimer) 
		begin
			ProgNOPCount <= 16'd0;
		end
		else if (CurrentState == Idled) 
		begin
			RefreshNOPCount <= 0;
		end
		else if (CurrentState == RefreshNOPCheck) 
		begin
			RefreshNOPCount <= RefreshNOPCount + 16'd1;
		end	
	end
endmodule
