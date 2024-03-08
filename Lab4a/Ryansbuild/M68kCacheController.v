///////////////////////////////////////////////////////////////////////////////////////
// Simple Cache controller
//
// designed to work with TG68 (68000 based) cpu with 16 bit data bus and 32 bit address bus
// separate upper and lowe data stobes for individual byte and also 16 bit word access
//
// Copyright PJ Davies August 2017
///////////////////////////////////////////////////////////////////////////////////////

module M68kCacheController_Verilog (
		input Clock,											// used to drive the state machine - state changes occur on positive edge
		input Reset_L,     									// active low reset 
		input CacheHit_H,										// high when cache contains matching address during read
		input ValidBitIn_H,									// indicates if the cache line is valid

		// signals to 68k
		
		input DramSelect68k_H,     						// active high signal indicating Dram is being addressed by 68000
		input unsigned [31:0] AddressBusInFrom68k,  	// address bus from 68000
		input unsigned [15:0] DataBusInFrom68k, 		// data bus in from 68000
		output reg unsigned [15:0] DataBusOutTo68k, 	// data bus out from Cache controller back to 68000 (during read)
		input UDS_L,											// active low signal driven by 68000 when 68000 transferring data over data bit 15-8
		input LDS_L, 											// active low signal driven by 68000 when 68000 transferring data over data bit 7-0
		input WE_L,  											// active low write signal, otherwise assumed to be read
		input AS_L,
		input DtackFromDram_L,								// dtack back from Dram
		input CAS_Dram_L,										// cas to Dram so we can count 2 clock delays before 1st data
		input RAS_Dram_L,										// so we can detect diference between a read and a refresh command

		input unsigned [15:0] DataBusInFromDram, 							// data bus in from Dram
		output reg unsigned [15:0] DataBusOutToDramController, 		// data bus out to Dram (during write)
		input unsigned [15:0] DataBusInFromCache, 						// data bus in from Cache
		output reg UDS_DramController_L, 									// active low signal driven by 68000 when 68000 transferring data over data bit 7-0
		output reg LDS_DramController_L,										// active low signal driven by 68000 when 68000 transferring data over data bit 15-8
		output reg DramSelectFromCache_L,
		output reg WE_DramController_L,  									// active low Dram controller write signal
		output reg AS_DramController_L,
		output reg DtackTo68k_L, 												// Dtack back to 68k at end of operation
		
		// Cache memory write signals
		output reg TagCache_WE_L,												// to store an address in Cache
		output reg DataCache_WE_L,												// to store data in Cache
		output reg ValidBit_WE_L,												// to store a valid bit
		
		output reg unsigned [31:0] AddressBusOutToDramController,  	// address bus from Cache to Dram controller
		output reg unsigned [22:0] TagDataOut,  							// tag data to store in the tag Cache
		output reg unsigned [2:0] WordAddress,								// upto 8 bytes in a Cache line
		output reg ValidBitOut_H,												// indicates the cache line is valid
		output reg unsigned [8:4] Index,										// 5 bit index in this example cache

		output unsigned [4:0] CacheState										// for debugging
	);


/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Initialisation States
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	parameter	Reset	= 5'b00000;
	parameter	InvalidateCache = 5'b00001 ;
	parameter 	Idle = 5'b00010;	
	parameter	CheckForCacheHit = 5'b00011;	
	parameter	ReadDataFromDramIntoCache = 5'b00100 ;
	parameter	CASDelay1 = 5'b00101;
	parameter	CASDelay2 = 5'b00110;
	parameter	BurstFill = 5'b00111;
	parameter	EndBurstFill = 5'b01000 ;
	parameter	WriteDataToDram = 5'b01001 ;
	parameter	WaitForEndOfCacheRead = 5'b01010 ;
	
	
	// 5 bit variables to hold current and next state of the state machine
	reg unsigned [4:0]  CurrentState;						// holds the current state of the Cache controller
	reg unsigned [4:0]  NextState;							// holds the next state of the Cache controller
	
	// counter for the read burst fill
	reg unsigned [15:0] BurstCounter;						// counts for at least 8 during a burst Dram read also counts lines when flusing the cache
	reg BurstCounterReset_L;									// reset for the above counter

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// concurrent process state registers
// this process RECORDS the current state of the system.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	assign CacheState = CurrentState;						// for debugging purposes only

   always@(posedge Clock, negedge Reset_L)
	begin
		if(Reset_L == 0) 
			CurrentState <= Reset ;
		else
			CurrentState <= NextState;	
	end
	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Burst read counter: Used to provide a 3 bit address to the data Cache during burst reads from Dram and upto 2^12 cache lines
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	always@(posedge Clock)
	begin
		if(BurstCounterReset_L == 0) 						// synchronous reset
			BurstCounter <= 0;
		else
			BurstCounter <= BurstCounter + 1;
	end
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// next state and output logic
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	always@(*) begin
		// start with default inactive values for everything and override as necessary, so we do not infer storage for signals inside this process
	
		NextState 						<= Idle ;
		DataBusOutTo68k 				<= DataBusInFromCache;
		DataBusOutToDramController <= DataBusInFrom68k;

		// default is to give the Dram the 68k's signals directly (unless we want to change something)	
		
		AddressBusOutToDramController[31:4]	<= AddressBusInFrom68k[31:4];
		AddressBusOutToDramController[3:1]  <= 0;								// all reads to Dram have lower 3 address lines set to 0 for a Cache line regardless of 68k address
		AddressBusOutToDramController[0] 	<= 0;								// to avoid inferring a latch for this bit
		
		TagDataOut						<= AddressBusInFrom68k[31:9];
		Index								<= AddressBusInFrom68k[8:4];			// cache index is 68ks address bits [8:4]
		
		UDS_DramController_L			<= UDS_L;
		LDS_DramController_L	   	<= LDS_L;
		WE_DramController_L 			<= WE_L;
		AS_DramController_L			<= AS_L;
		
		DtackTo68k_L					<= 1;									// don't supply until we are ready
		TagCache_WE_L 					<= 1;									// don't write Cache address
		DataCache_WE_L 				<= 1;									// don't write Cache data
		ValidBit_WE_L					<= 1;									// don't write valid data
		ValidBitOut_H					<= 0;									// line invalid
		DramSelectFromCache_L 		<= 1;									// don't give the Dram controller a select signal since we might not always want to cycle the Dram if we have a hit during a read
		WordAddress						<= 0;									// default is byte 0 in 8 byte Cache line	
		
		BurstCounterReset_L 			<= 1;									// default is that burst counter can run (and wrap around if needed), we'll control when to reset it		
		NextState 						<= Idle ;							// default is to go to this state
			
//////////////////////////////////////////////////////////////////
// Initial State following a reset
//////////////////////////////////////////////////////////////////
		
		if(CurrentState == Reset) begin	  								// if we are in the Reset state				
			BurstCounterReset_L 				<= 0;							// reset the burst counter (synchronously)
			NextState							<= InvalidateCache;				// go flush the cache
		end

/////////////////////////////////////////////////////////////////
// This state will flush the cache before entering idle state
/////////////////////////////////////////////////////////////////	
		else if(CurrentState == InvalidateCache) begin	  						
			
			// burst counter should now be 0 when we first enter this state, as it was reset in state above
			
			if(BurstCounter == 32) 											// if we have done all cache lines
				NextState 						<= Idle;
			else begin
				NextState						<= InvalidateCache;				// assume we stay here
				Index	 							<= BurstCounter[4:0];	// 5 bit address for Index for 32 lines of cache
				
				// clear the validity bit for each cache line
				ValidBitOut_H 					<=	0;		
				ValidBit_WE_L					<= 0;
			end
		end

///////////////////////////////////////////////
// Main IDLE state: 
///////////////////////////////////////////////
		else if(CurrentState == Idle) begin	  							// if we are in the idle state				
			/*Otherwise if we are in the Idle state {				
			if AS_L is active and DramSelect68_H  is active {
				if the 68k's access is a read, i.e. WE_L is high 
					activate UDS and LDS to the Dram Controller to grab both bytes from Cache or Dram regardless of what 68k asks
					Next state = CheckForCacheHit					
				}
				else { 		-- must be a write, so write the 68k data to Dram and invalidate the line as we don’t cache written data
					if(ValidBitIn_H  is active) {
						Set ValidBitOut_H to invalid
						Activate ValidBit_WE_L to perform the write to the Valid memory in the cache. This occurs  on next clock edge 
					}
					Activate DramSelectFromCache_L to zero to start the Dram controller to perform the write a.s.a.p.
					Next state = WriteDataToDram to perform the write
				}
			} 
			*/
			if ((AS_L == 0) && (DramSelect68k_H == 1)) begin
				if (WE_L == 1) begin
					UDS_DramController_L			<= 0;
					LDS_DramController_L	   	<= 0;
					NextState 						<= CheckForCacheHit;
				end
				else begin
					if(ValidBitIn_H == 1) begin
						ValidBitOut_H 					<= 0;
						ValidBit_WE_L					<= 0;
					end
					DramSelectFromCache_L 		<= 0;
					NextState 						<= WriteDataToDram;
				end
			end
		end

////////////////////////////////////////////////////////////////////////////////////////////////////
// Check if we have a Cache HIT. If so give data to 68k or if not, go generate a burst fill 
////////////////////////////////////////////////////////////////////////////////////////////////////

		else if(CurrentState == CheckForCacheHit) begin	  			// if we are looking for Cache hit			
		// Otherwise if we are in the CheckForCacheHit state {	  	
			// Keep activating UDS and LDS to Dram/Cache Memory controller to grab both bytes
			
			// -- at this point, the Tag and Valid block will have clocked in the CPU address and output their Valid and Tag address
			// -- to the comparator so we can see if the cache has a hit or not
			
			// If CacheHit_H is active and the ValidBitIn_H is active {		-- give the 68k the data from the cache
			// 	-- remember by default  DataBusOutTo68k is set to DataBusInFromCache,							
			// 	-- so get the data from the Cache corresponding to the CPU address we are reading from 

			// 	Set WordAddress to AddressBusInFrom68k [3:1]		-- give the cache line the correct 3 bit word address specified by 68k
			// 	Activate the DtackTo68k_L signal
			// 	Next state = WaitForEndOfCacheRead;
			// }
			// Otherwise {						-- we don't have the data Cached so get it from the Dram and Cache data and address
			// 	activate DramSelectFromCache_L  signal			-- start the Dram controller to perform the read a.s.a.p.
			// 	Next state =  ReadDataFromDramIntoCache;
			// }
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;

			if ((CacheHit_H == 1) && (ValidBitIn_H == 1)) begin
				WordAddress <= AddressBusInFrom68k[3:1];
				DtackTo68k_L <= 0;
				NextState <= WaitForEndOfCacheRead;
			end
			else begin
				DramSelectFromCache_L <= 0;
				NextState <= ReadDataFromDramIntoCache;
			end
		end	

///////////////////////////////////////////////////////////////////////////////////////////////
// Got a Cache hit, so give the 68k the Cache data now, then wait for the 68k to end bus cycle 
///////////////////////////////////////////////////////////////////////////////////////////////

		else if(CurrentState == WaitForEndOfCacheRead) begin		
			/*Otherwise if we are in the WaitForEndOfCacheRead state {		
			Keep activating UDS and LDS to Dram/Cache Memory controller to grab both bytes
			
			--remember by default  DataBusOutTo68k is set to DataBusInFromCache,

			Set WordAddress to AddressBusInFrom68k bits [3:1]		-- give the cache line the correct 3 bit address specified by 68k
			Active the DtackTo68k_L signal
			
			If AS_L is active 	{
				Next state = WaitForEndOfCacheRead 		-- stay in this state until AS_L deactivated
			}
		}	
		*/
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			WordAddress <= AddressBusInFrom68k[3:1];
			DtackTo68k_L <= 0;
			
			if (AS_L == 0) begin
				NextState <= WaitForEndOfCacheRead;
			end
		end
			
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Start of operation to Read from Dram State : Remember that CAS latency is 2 clocks before 1st item of burst data appears
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		else if(CurrentState == ReadDataFromDramIntoCache) begin
			/*
			Otherwise if we are in the ReadDataFromDramIntoCache state {
			Set Next state =  ReadDataFromDramIntoCache			--   unless overridden below
			
			-- we need to wait for a valid CAS signal to be presented to the Dram by the Dram controller.
			-- we can’t just look at CAS, since a refresh also drives CAS low
			
			If CAS_Dram_L is active and RAS_Dram_L is INactive  {		-- a read and not a refresh
				Go to new state CASDelay1 ;					-- move to next state to wait 2 Clock period (CAS  latency) 
			}

			-- Keep Kicking the Dram controller to perform a burst read and fill a Line in the cache
			Activate the DramSelectFromCache_L signal				-- keep reading from Dram
			Deactivate DtackTo68k_L  signal					-- no dtack to 68k until burst fill complete

			-- Because we are burst filling a line of cache from Dram, we have to store the TAG (i.e. the 68k's m.s.bits of address bus)
			-- into the Tag Cache to mark the fact that we will have the data at that address and move on to next state to get Dram data

			-- By Default:  TagDataOut set to AddressBusInFrom68k(31 downto 9);
			Activate TagCache_WE_L signal			-- write the 68k's address with each clock as long as we are in this state
			
			-- we also have to set the Valid bit in the Valid Memory to indicate line in the cache is now valid
			Activate ValidBitOut_H signal			--  Make Cache Line Valid
			Activate ValidBit_WE_L signal			-- Write the above Valid Bit
			
			-- perform a Dram WORD READ(i.e. 16 bits), even if 68k is only reading a BYTE so we get both bytes as cache word is 16 bits wide
			-- By Default : Address bus to Dram is already set to the 68k's address bus by default
			-- By Default: AS_L, WE_L to Dram are already set to 68k's equivalent by default

			Keep activating UDS and LDS to Dram/Cache Memory controller to grab both bytes
		}
		*/
			NextState <= ReadDataFromDramIntoCache;			// unless overridden below
			
			if ((CAS_Dram_L == 0) && (RAS_Dram_L == 1)) begin
				NextState <= CASDelay1;
			end
			else begin
				DramSelectFromCache_L <= 0;
				DtackTo68k_L <= 1;
				TagCache_WE_L <= 0;
				ValidBitOut_H <= 1;
				ValidBit_WE_L <= 0;
				UDS_DramController_L <= 0;
				LDS_DramController_L <= 0;
			end
		end
						
///////////////////////////////////////////////////////////////////////////////////////
// Wait for 1st CAS clock (latency)
///////////////////////////////////////////////////////////////////////////////////////
			
		else if(CurrentState == CASDelay1) begin						// wait for Dram case signal to go low
			/*Otherwise if we are in the  CASDelay1 state  {				-- wait for Dram case signal to go low
			Keep activating UDS and LDS to Dram/Cache Memory controller to grab both bytes
			
			-- By Default : Address bus to Dram is already set to the 68k's address bus by default
			-- By Default: AS_L, WE_L to Dram are already set to 68k's equivalent by default

			Keep activating DramSelectFromCache_L 				-- keep reading from Dram
			Deactivate DtackTo68k_L  signal					-- no dtack to 68k until burst fill complete

			Next state = CASDelay2 ;					-- go and wait for 2nd CAS clock latency
		}	
		*/
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			DramSelectFromCache_L <= 0;
			DtackTo68k_L <= 1;
			NextState <= CASDelay2;
		end
				
///////////////////////////////////////////////////////////////////////////////////////
// Wait for 2nd CAS Clock Latency
///////////////////////////////////////////////////////////////////////////////////////
			
		else if(CurrentState == CASDelay2) begin						// wait for Dram case signal to go low
			/*
			Otherwise if we are in the  CASDelay2 state {				-- wait for Dram case signal to go low
			Keep activating UDS and LDS to Dram/Cache Memory controller to grab both bytes
			
			-- By Default : Address bus to Dram is already set to the 68k's address bus by default
			-- By Default: AS_L, WE_L to Dram are already set to 68k's equivalent by default

			Keep activating DramSelectFromCache_L 				-- keep reading from Dram
			Deactivate DtackTo68k_L  signal					-- no dtack to 68k until burst fill complete

			Activate BurstCounterReset_L	signal					-- reset the counter to supply 3 bit burst address to Cache memory
			Next state = BurstFill ;						
		}
		*/
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			DramSelectFromCache_L <= 0;
			DtackTo68k_L <= 1;
			BurstCounterReset_L <= 0;
			NextState <= BurstFill;
		end

/////////////////////////////////////////////////////////////////////////////////////////////
// Start of burst fill from Dram into Cache (data should be available at Dram in this  state)
/////////////////////////////////////////////////////////////////////////////////////////////
		
		else if(CurrentState == BurstFill) begin						// wait for Dram case signal to go low
			/*
			Otherwise if we are in the BurstFill state {					-- wait for Dram case signal to go low
			Keep activating UDS and LDS to Dram/Cache Memory controller to grab both bytes
			
			-- By Default : Address bus to Dram is already set to the 68k's address bus by default
			-- By Default: AS_L, WE_L to Dram are already set to 68k's equivalent by default

			Keep activating DramSelectFromCache_L  signal			-- keep reading from Dram
			Deactivate DtackTo68k_L signal						-- no dtack to 68k until burst fill complete

			-- burst counter should now be 0 when we first enter this state, as reset was synchronous and will count with each clock
			If BurstCounter = 8  {							-- if we have read 8 words, it's time to stop
				Next state = EndBurstFill;
			}
			else {
				Set WordAddress to cache memory to lowest 3 bits of BurstCounter
				
				-- By Default: Index address to cache Memory is bits [8:4] of the 68ks address bus for a 32 line cache
				
				Activate DataCache_WE_L to store  next word from Dram into data Cache on next clock edge
				Next state = BurstFill					-- stay in this state until counter reaches 8 above
			}
		}	 
		*/
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			DramSelectFromCache_L <= 0;
			DtackTo68k_L <= 1;
			if (BurstCounter == 8) begin
				NextState <= EndBurstFill;
			end
			else begin
				WordAddress <= BurstCounter[2:0];
				DataCache_WE_L <= 0;
				NextState <= BurstFill;
			end
		end
			
///////////////////////////////////////////////////////////////////////////////////////
// End Burst fill
///////////////////////////////////////////////////////////////////////////////////////
		else if(CurrentState == EndBurstFill) begin							// wait for Dram case signal to go low
			/*
			Otherwise if we are in the EndBurstFill state {					-- wait for Dram case signal to go low
			Deactivate DramSelectFromCache_L 	signal					-- deactivate Dram controller
			Activate DtackTo68k_L signal							-- give dtack to 68k until end of 68k's bus cycle
			
			Keep activating UDS and LDS to Dram/Cache Memory controller to grab both bytes

			-- get the data from the Cache corresponding the REAL 68k address we are reading from			
			Set WordAddress (to cache memory) to AddressBusInFrom68k bits [3:1]
			Set DataBusOutTo68k to DataBusInFromCache;				-- get data from the Cache and give to cpu

			-- now wait for the 68k to terminate the read by removing either AS_L or DRamSelect68k_H			
			if AS_L is INactive or DramSelect68k_H is INactive { 
				Next state = IDLE;								-- go to Idle state ending the Dram access
			}	
			else	{
				Next state = EndBurstFill							-- else stay in this state
			}
		}
		*/
			DramSelectFromCache_L <= 1;
			DtackTo68k_L <= 0;
			UDS_DramController_L <= 0;
			LDS_DramController_L <= 0;
			WordAddress <= AddressBusInFrom68k[3:1];
			DataBusOutTo68k <= DataBusInFromCache;
			
			if ((AS_L == 1) || (DramSelect68k_H == 0)) begin
				NextState <= Idle;
			end
			else begin
				NextState <= EndBurstFill;
			end
		end

///////////////////////////////////////////////
// Write Data to Dram State (no Burst)
///////////////////////////////////////////////
		else if(CurrentState == WriteDataToDram) begin	  					// if we are writing data to Dram
			/*
			Otherwise if we are in the WriteDataToDram state {	  				-- if we are writing data to Dram
			Set AddressBusOutToDramController	to AddressBusInFrom68k;		-- override lower 3 bits
			
			-- Data Bus out to Dram is already set to 68k's data bus out by default
			-- By Default: AS_L, WE_L to Dram are already set to 68k's equivalent by default
			
			Keep Activating  DramSelectFromCache_L  signal					-- keep kicking the Dram controller to perform the write
			Set  DtackTo68k_L 	=  DtackFromDram_L;						-- give the 68k the dtack from the Dram controller
			
			-- now wait for the 68k to terminate the read by removing either AS_L or DRamSelect68k_H			
			if AS_L is INactive or DramSelect68k_H is INactive { 
				Next state = IDLE;								-- go to Idle state ending the Dram access
			}
			else	{
				Next state = WriteDataToDram						-- else stay in this state until the 68k finishes the write	
			}
		}
		*/
			AddressBusOutToDramController[31:3] <= AddressBusInFrom68k[31:4];		// override lower 3 bits
			AddressBusOutToDramController[2:0] <= 0;								// all writes to Dram have lower 3 address lines set to 0 for a Cache line regardless of 68k address
			DramSelectFromCache_L <= 0;
			DtackTo68k_L <= DtackFromDram_L;
			
			if ((AS_L == 1) || (DramSelect68k_H == 0)) begin
				NextState <= Idle;
			end
			else begin
				NextState <= WriteDataToDram;
			end
		end
	end
endmodule