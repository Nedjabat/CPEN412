; C:\CPEN412\ASN6\ASN6B_THREADS\CANBUS-CONTROLLER.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include "Canbus-Controller.h"
; #include "DebugMonitor.h"
; #define TEMP 0
; #define POTENTIAL 1
; #define LIGHT 2
; #define SWITCHES 3
; /*********************************************************************************************
; ** These addresses and definitions were taken from Appendix 7 of the Can Controller
; ** application note and adapted for the 68k assignment
; *********************************************************************************************/
; /*
; ** definition for the SJA1000 registers and bits based on 68k address map areas
; ** assume the addresses for the 2 can controllers given in the assignment
; **
; ** Registers are defined in terms of the following Macro for each Can controller,
; ** where (i) represents an registers number
; */
; /*  bus timing values for
; **  bit-rate : 100 kBit/s
; **  oscillator frequency : 25 MHz, 1 sample per bit, 0 tolerance %
; **  maximum tolerated propagation delay : 4450 ns
; **  minimum requested propagation delay : 500 ns
; **
; **  https://www.kvaser.com/support/calculators/bit-timing-calculator/
; **  T1 	T2 	BTQ 	SP% 	SJW 	BIT RATE 	ERR% 	BTR0 	BTR1
; **  17	8	25	    68	     1	      100	    0	      04	7f
; */
; // initialisation for Can controller 0
; void Init_CanBus_Controller0(void)
; {
       section   code
       xdef      _Init_CanBus_Controller0
_Init_CanBus_Controller0:
; // TODO - put your Canbus initialisation code for CanController 0 here
; // See section 4.2.1 in the application note for details (PELICAN MODE)
; /* set reset mode/request (Note: after power-on SJA1000 is in BasicCAN mode)
; leave loop after a time out and signal an error */
; while((Can0_ModeControlReg & RM_RR_Bit ) == ClrByte)
Init_CanBus_Controller0_1:
       move.b    5242880,D0
       and.b     #1,D0
       bne.s     Init_CanBus_Controller0_3
; {
; /* other bits than the reset mode/request bit are unchanged */
; Can0_ModeControlReg = Can0_ModeControlReg | RM_RR_Bit ;
       move.b    5242880,D0
       or.b      #1,D0
       move.b    D0,5242880
       bra       Init_CanBus_Controller0_1
Init_CanBus_Controller0_3:
; }
; /* set the Clock Divider Register according to the given hardware of Figure 3
; select PeliCAN mode
; bypass CAN input comparator as external transceiver is used
; select the clock for the controller S87C654 */
; Can0_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy2;
       move.b    #192,5242942
; /* disable CAN interrupts, if required (always necessary after power-on)
; (write to SJA1000 Interrupt Enable / Control Register) */
; Can0_InterruptEnReg = ClrIntEnSJA;
       clr.b     5242888
; /* define acceptance code and mask */
; Can0_AcceptCode0Reg = ClrByte;
       clr.b     5242912
; Can0_AcceptCode1Reg = ClrByte;
       clr.b     5242914
; Can0_AcceptCode2Reg = ClrByte;
       clr.b     5242916
; Can0_AcceptCode3Reg = ClrByte;
       clr.b     5242918
; Can0_AcceptMask0Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5242920
; Can0_AcceptMask1Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5242922
; Can0_AcceptMask2Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5242924
; Can0_AcceptMask3Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5242926
; /* configure bus timing */
; /* bit-rate = 1 Mbit/s @ 24 MHz, the bus is sampled once */
; Can0_BusTiming0Reg = 0x04;
       move.b    #4,5242892
; Can0_BusTiming1Reg = 0x7F;
       move.b    #127,5242894
; /* configure CAN outputs: float on TX1, Push/Pull on TX0,
; normal output mode */
; Can0_OutControlReg = Tx1Float | Tx0PshPull | NormalMode;
       move.b    #26,5242896
; /* leave the reset mode/request i.e. switch to operating mode,
; the interrupts of the S87C654 are enabled
; but not the CAN interrupts of the SJA1000, which can be done separately
; for the different tasks in a system */
; /* clear Reset Mode bit, select dual Acceptance Filter Mode,
; switch off Self Test Mode and Listen Only Mode,
; clear Sleep Mode (wake up) */
; /* wait until RM_RR_Bit is cleared */
; /* break loop after a time out and signal an error */
; do{
Init_CanBus_Controller0_4:
; Can0_ModeControlReg = ClrByte;
       clr.b     5242880
       move.b    5242880,D0
       and.b     #1,D0
       bne       Init_CanBus_Controller0_4
       rts
; } while((Can0_ModeControlReg & RM_RR_Bit ) != ClrByte);
; /*----- end of Initialization Example of the SJA1000 ------------------------*/
; }
; // initialisation for Can controller 1
; void Init_CanBus_Controller1(void)
; {
       xdef      _Init_CanBus_Controller1
_Init_CanBus_Controller1:
; // TODO - put your Canbus initialisation code for CanController 1 here
; // See section 4.2.1 in the application note for details (PELICAN MODE)
; /* set reset mode/request (Note: after power-on SJA1000 is in BasicCAN mode)
; leave loop after a time out and signal an error */
; while((Can1_ModeControlReg & RM_RR_Bit ) == ClrByte)
Init_CanBus_Controller1_1:
       move.b    5243392,D0
       and.b     #1,D0
       bne.s     Init_CanBus_Controller1_3
; {
; /* other bits than the reset mode/request bit are unchanged */
; Can1_ModeControlReg = Can1_ModeControlReg | RM_RR_Bit ;
       move.b    5243392,D0
       or.b      #1,D0
       move.b    D0,5243392
       bra       Init_CanBus_Controller1_1
Init_CanBus_Controller1_3:
; }
; /* set the Clock Divider Register according to the given hardware of Figure 3
; select PeliCAN mode
; bypass CAN input comparator as external transceiver is used
; select the clock for the controller S87C654 */
; Can1_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy2;
       move.b    #192,5243454
; /* disable CAN interrupts, if required (always necessary after power-on)
; (write to SJA1000 Interrupt Enable / Control Register) */
; Can1_InterruptEnReg = ClrIntEnSJA;
       clr.b     5243400
; /* define acceptance code and mask */
; Can1_AcceptCode0Reg = ClrByte;
       clr.b     5243424
; Can1_AcceptCode1Reg = ClrByte;
       clr.b     5243426
; Can1_AcceptCode2Reg = ClrByte;
       clr.b     5243428
; Can1_AcceptCode3Reg = ClrByte;
       clr.b     5243430
; Can1_AcceptMask0Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5243432
; Can1_AcceptMask1Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5243434
; Can1_AcceptMask2Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5243436
; Can1_AcceptMask3Reg = DontCare; /* every identifier is accepted */
       move.b    #255,5243438
; /* configure bus timing */
; /* bit-rate = 1 Mbit/s @ 24 MHz, the bus is sampled once */
; Can1_BusTiming0Reg = 0x04;
       move.b    #4,5243404
; Can1_BusTiming1Reg = 0x7F;
       move.b    #127,5243406
; /* configure CAN outputs: float on TX1, Push/Pull on TX0,
; normal output mode */
; Can1_OutControlReg = Tx1Float | Tx0PshPull | NormalMode;
       move.b    #26,5243408
; /* leave the reset mode/request i.e. switch to operating mode,
; the interrupts of the S87C654 are enabled
; but not the CAN interrupts of the SJA1000, which can be done separately
; for the different tasks in a system */
; /* clear Reset Mode bit, select dual Acceptance Filter Mode,
; switch off Self Test Mode and Listen Only Mode,
; clear Sleep Mode (wake up) */
; /* wait until RM_RR_Bit is cleared */
; /* break loop after a time out and signal an error */
; do{
Init_CanBus_Controller1_4:
; Can1_ModeControlReg = ClrByte;
       clr.b     5243392
       move.b    5243392,D0
       and.b     #1,D0
       bne       Init_CanBus_Controller1_4
       rts
; } while((Can1_ModeControlReg & RM_RR_Bit ) != ClrByte);
; /*----- end of Initialization Example of the SJA1000 ------------------------*/
; }
; // Transmit for sending a message via Can controller 0
; void CanBus0_Transmit(unsigned char data)
; {
       xdef      _CanBus0_Transmit
_CanBus0_Transmit:
       link      A6,#0
; // TODO - put your Canbus transmit code for CanController 0 here
; // See section 4.2.2 in the application note for details (PELICAN MODE)
; /* wait until the Transmit Buffer is released */
; do{
CanBus0_Transmit_1:
; /* start a polling timer and run some tasks while waiting
; break the loop and signal an error if time too long */
; } while((Can0_StatusReg & TBS_Bit ) != TBS_Bit );
       move.b    5242884,D0
       and.b     #4,D0
       cmp.b     #4,D0
       bne       CanBus0_Transmit_1
; /* Transmit Buffer is released, a message may be written into the buffer */
; /* in this example a Standard Frame message shall be transmitted */
; Can0_TxFrameInfo = 0x08; /* SFF (data), DLC=8 */
       move.b    #8,5242912
; Can0_TxBuffer1 = data; /*Data that will be sent*/
       move.b    11(A6),5242914
; /* Start the transmission */
; Can0_CommandReg = TR_Bit ; /* Set Transmission Request bit */
       move.b    #1,5242882
       unlk      A6
       rts
; }
; // Transmit for sending a message via Can controller 1
; void CanBus1_Transmit(unsigned char data)
; {
       xdef      _CanBus1_Transmit
_CanBus1_Transmit:
       link      A6,#0
; // TODO - put your Canbus transmit code for CanController 1 here
; // See section 4.2.2 in the application note for details (PELICAN MODE)
; /* wait until the Transmit Buffer is released */
; do{
CanBus1_Transmit_1:
; /* start a polling timer and run some tasks while waiting
; break the loop and signal an error if time too long */
; } while((Can1_StatusReg & TBS_Bit ) != TBS_Bit );
       move.b    5243396,D0
       and.b     #4,D0
       cmp.b     #4,D0
       bne       CanBus1_Transmit_1
; /* Transmit Buffer is released, a message may be written into the buffer */
; /* in this example a Standard Frame message shall be transmitted */
; Can1_TxFrameInfo = 0x08; /* SFF (data), DLC=8 */
       move.b    #8,5243424
; Can1_TxBuffer1 = data; /*Data that will be sent*/
       move.b    11(A6),5243426
; /* Start the transmission */
; Can1_CommandReg = TR_Bit ; /* Set Transmission Request bit */
       move.b    #1,5243394
       unlk      A6
       rts
; }
; // Receive for reading a received message via Can controller 0
; void CanBus0_Receive(int type)
; {
       xdef      _CanBus0_Receive
_CanBus0_Receive:
       link      A6,#-4
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _printf.L,A2
       move.l    8(A6),D4
; unsigned char data;
; unsigned char c = 0xFF;
       move.b    #255,-1(A6)
; unsigned int i = 0;
       clr.l     D3
; // TODO - put your Canbus receive code for CanController 0 here
; // See section 4.2.4 in the application note for details (PELICAN MODE)
; //Bottom of page 35
; /* enable the receive interrupt */
; //Can0_InterruptEnReg = RIE_Bit; ////
; /* wait until the Receiver Buffer is released */
; do{
CanBus0_Receive_1:
; /* start a polling timer and run some tasks while waiting
; break the loop and signal an error if time too long */
; } while((Can0_StatusReg & RBS_Bit) != RBS_Bit );
       move.b    5242884,D0
       and.b     #1,D0
       cmp.b     #1,D0
       bne       CanBus0_Receive_1
; /* read the Interrupt Register content from SJA1000 and save temporarily
; all interrupt flags are cleared (in PeliCAN mode the Receive
; Interrupt (RI) is cleared first, when giving the Release Buffer command)
; */
; /* get the content of the Receive Buffer from SJA1000 and store the
; message into internal memory of the controller,
; it is possible at once to decode the FrameInfo and Data Length Code
; and adapt the fetch appropriately */
; data = Can0_RxBuffer1;
       move.b    5242914,D2
; if(type == TEMP){
       tst.l     D4
       bne.s     CanBus0_Receive_3
; printf("Value of Thermistor (CAN0): %d\n", data);
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       @canbus~1_1.L
       jsr       (A2)
       addq.w    #8,A7
       bra       CanBus0_Receive_10
CanBus0_Receive_3:
; }else if(type == POTENTIAL){
       cmp.l     #1,D4
       bne.s     CanBus0_Receive_5
; printf("Value of Potentiometer (CAN0): %d\n", data);
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       @canbus~1_2.L
       jsr       (A2)
       addq.w    #8,A7
       bra       CanBus0_Receive_10
CanBus0_Receive_5:
; }else if(type == LIGHT){
       cmp.l     #2,D4
       bne.s     CanBus0_Receive_7
; printf("Value of Photo-resister (CAN0): %d\n", data);
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       @canbus~1_3.L
       jsr       (A2)
       addq.w    #8,A7
       bra       CanBus0_Receive_10
CanBus0_Receive_7:
; }else if(type == SWITCHES){
       cmp.l     #3,D4
       bne       CanBus0_Receive_9
; printf("Value of SW[7-0] (CAN0): ");
       pea       @canbus~1_4.L
       jsr       (A2)
       addq.w    #4,A7
; for (i = (int)(0x00000080); i > 0; i = i >> 1) {
       move.l    #128,D3
CanBus0_Receive_11:
       cmp.l     #0,D3
       bls.s     CanBus0_Receive_13
; if ((data & i) == 0)
       move.b    D2,D0
       and.l     #255,D0
       and.l     D3,D0
       bne.s     CanBus0_Receive_14
; printf("0");
       pea       @canbus~1_5.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     CanBus0_Receive_15
CanBus0_Receive_14:
; else
; printf("1");
       pea       @canbus~1_6.L
       jsr       (A2)
       addq.w    #4,A7
CanBus0_Receive_15:
       lsr.l     #1,D3
       bra       CanBus0_Receive_11
CanBus0_Receive_13:
; }
; printf("\n");
       pea       @canbus~1_7.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     CanBus0_Receive_10
CanBus0_Receive_9:
; }else{
; printf("ERROR");
       pea       @canbus~1_8.L
       jsr       (A2)
       addq.w    #4,A7
CanBus0_Receive_10:
; }
; /* release the Receive Buffer, now the Receive Interrupt flag is cleared,
; further messages will generate a new interrupt */
; Can0_CommandReg = RRB_Bit; /* Release Receive Buffer */
       move.b    #4,5242882
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; // Receive for reading a received message via Can controller 1
; void CanBus1_Receive(int type)
; {
       xdef      _CanBus1_Receive
_CanBus1_Receive:
       link      A6,#-4
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _printf.L,A2
       move.l    8(A6),D4
; unsigned char data;
; unsigned char c = 0xFF;
       move.b    #255,-1(A6)
; unsigned int i = 0;        
       clr.l     D3
; // TODO - put your Canbus receive code for CanController 1 here
; // See section 4.2.4 in the application note for details (PELICAN MODE)
; //Bottom of page 35
; // TODO - put your Canbus receive code for CanController 0 here
; // See section 4.2.4 in the application note for details (PELICAN MODE)
; /* enable the receive interrupt */
; //Can1_InterruptEnReg = RIE_Bit;
; /* wait until the Receiver Buffer is released */
; do{
CanBus1_Receive_1:
; /* start a polling timer and run some tasks while waiting
; break the loop and signal an error if time too long */
; } while((Can1_StatusReg & RBS_Bit) != RBS_Bit );
       move.b    5243396,D0
       and.b     #1,D0
       cmp.b     #1,D0
       bne       CanBus1_Receive_1
; /* read the Interrupt Register content from SJA1000 and save temporarily
; all interrupt flags are cleared (in PeliCAN mode the Receive
; Interrupt (RI) is cleared first, when giving the Release Buffer command)
; */
; /* get the content of the Receive Buffer from SJA1000 and store the
; message into internal memory of the controller,
; it is possible at once to decode the FrameInfo and Data Length Code
; and adapt the fetch appropriately */
; data = Can1_RxBuffer1;
       move.b    5243426,D2
; if(type == TEMP){
       tst.l     D4
       bne.s     CanBus1_Receive_3
; printf("Value of Thermistor (CAN1): %d\n", data);
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       @canbus~1_9.L
       jsr       (A2)
       addq.w    #8,A7
       bra       CanBus1_Receive_10
CanBus1_Receive_3:
; }else if(type == POTENTIAL){
       cmp.l     #1,D4
       bne.s     CanBus1_Receive_5
; printf("Value of Potentiometer (CAN1): %d\n", data);
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       @canbus~1_10.L
       jsr       (A2)
       addq.w    #8,A7
       bra       CanBus1_Receive_10
CanBus1_Receive_5:
; }else if(type == LIGHT){
       cmp.l     #2,D4
       bne.s     CanBus1_Receive_7
; printf("Value of Photo-resister (CAN1): %d\n", data);
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       @canbus~1_11.L
       jsr       (A2)
       addq.w    #8,A7
       bra       CanBus1_Receive_10
CanBus1_Receive_7:
; }else if(type == SWITCHES){
       cmp.l     #3,D4
       bne       CanBus1_Receive_9
; printf("Value of SW[7-0] (CAN1): ");
       pea       @canbus~1_12.L
       jsr       (A2)
       addq.w    #4,A7
; for (i = (int)(0x00000080); i > 0; i = i >> 1) {
       move.l    #128,D3
CanBus1_Receive_11:
       cmp.l     #0,D3
       bls.s     CanBus1_Receive_13
; if ((data & i) == 0)
       move.b    D2,D0
       and.l     #255,D0
       and.l     D3,D0
       bne.s     CanBus1_Receive_14
; printf("0");
       pea       @canbus~1_5.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     CanBus1_Receive_15
CanBus1_Receive_14:
; else
; printf("1");
       pea       @canbus~1_6.L
       jsr       (A2)
       addq.w    #4,A7
CanBus1_Receive_15:
       lsr.l     #1,D3
       bra       CanBus1_Receive_11
CanBus1_Receive_13:
; }
; printf("\n");
       pea       @canbus~1_7.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     CanBus1_Receive_10
CanBus1_Receive_9:
; }else{
; printf("ERROR");
       pea       @canbus~1_8.L
       jsr       (A2)
       addq.w    #4,A7
CanBus1_Receive_10:
; }
; /* release the Receive Buffer, now the Receive Interrupt flag is cleared,
; further messages will generate a new interrupt */
; Can1_CommandReg = RRB_Bit; /* Release Receive Buffer */
       move.b    #4,5243394
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; void CanBusTest(void)
; {
       xdef      _CanBusTest
_CanBusTest:
       movem.l   D2/A2,-(A7)
       lea       _printf.L,A2
; unsigned char data = 0xFF;
       move.b    #255,D2
; // initialise the two Can controllers
; Init_CanBus_Controller0();
       jsr       _Init_CanBus_Controller0
; Init_CanBus_Controller1();
       jsr       _Init_CanBus_Controller1
; printf("\r\n\r\n---- CANBUS Test ----\r\n") ;
       pea       @canbus~1_13.L
       jsr       (A2)
       addq.w    #4,A7
; // simple application to alternately transmit and receive messages from each of two nodes
; while(1)    {
CanBusTest_1:
; WaitHalfSecond();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly
       jsr       _WaitHalfSecond
; CanBus0_Transmit(data) ;       // transmit a message via Controller 0
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _CanBus0_Transmit
       addq.w    #4,A7
; CanBus1_Receive(TEMP) ;        // receive a message via Controller 1 (and display it)
       clr.l     -(A7)
       jsr       _CanBus1_Receive
       addq.w    #4,A7
; printf("\r\n") ;
       pea       @canbus~1_14.L
       jsr       (A2)
       addq.w    #4,A7
; WaitHalfSecond();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly
       jsr       _WaitHalfSecond
; CanBus1_Transmit(data) ;        // transmit a message via Controller 1
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _CanBus1_Transmit
       addq.w    #4,A7
; CanBus0_Receive(TEMP) ;         // receive a message via Controller 0 (and display it)
       clr.l     -(A7)
       jsr       _CanBus0_Receive
       addq.w    #4,A7
; printf("\r\n") ;
       pea       @canbus~1_14.L
       jsr       (A2)
       addq.w    #4,A7
       bra       CanBusTest_1
; }
; }
; /************************************************************************************
; *Subroutine to give the 68000 something useless to do to waste 1 x 500 mSec = 500mSec = 0.5sec therefore 500000
; ************************************************************************************/
; void WaitHalfSecond(void)
; {
       xdef      _WaitHalfSecond
_WaitHalfSecond:
       move.l    D2,-(A7)
; long int  i;
; for (i = 0; i < 500000; i++)
       clr.l     D2
WaitHalfSecond_1:
       cmp.l     #500000,D2
       bge.s     WaitHalfSecond_3
       addq.l    #1,D2
       bra       WaitHalfSecond_1
WaitHalfSecond_3:
       move.l    (A7)+,D2
       rts
; ;
; }
; /************************************************************************************
; ** Subfunctions for I2C
; ************************************************************************************/
; void Enable_SCL_Clock(void){
       xdef      _Enable_SCL_Clock
_Enable_SCL_Clock:
; I2C_Clock_PrerLo = 0x31;
       move.b    #49,4227072
; I2C_Clock_PrerHi = 0x00;
       clr.b     4227074
; return;
       rts
; }
; void WaitForI2C_TIP(void){
       xdef      _WaitForI2C_TIP
_WaitForI2C_TIP:
       link      A6,#-4
; int TIP_bit;
; do{
WaitForI2C_TIP_1:
; TIP_bit = (I2C_Status >> 1) & 0x01; 
       move.b    4227080,D0
       and.l     #255,D0
       lsr.l     #1,D0
       and.l     #1,D0
       move.l    D0,-4(A6)
       move.l    -4(A6),D0
       bne       WaitForI2C_TIP_1
; }while(TIP_bit != 0);
; return;
       unlk      A6
       rts
; }
; void WaitForI2C_RxACK(void){
       xdef      _WaitForI2C_RxACK
_WaitForI2C_RxACK:
       link      A6,#-4
; int RxACK_bit;
; do{
WaitForI2C_RxACK_1:
; RxACK_bit = (I2C_Status >> 7) & 0x01;
       move.b    4227080,D0
       and.l     #255,D0
       lsr.l     #7,D0
       and.l     #1,D0
       move.l    D0,-4(A6)
       move.l    -4(A6),D0
       bne       WaitForI2C_RxACK_1
; }while(RxACK_bit != 0);
; return;
       unlk      A6
       rts
; }
; /************************************************************************************
; ** initialises the I2C controller 
; ************************************************************************************/
; void I2C_Init(void){
       xdef      _I2C_Init
_I2C_Init:
; //Enabling 100Khz SCL Clock Line
; Enable_SCL_Clock();
       jsr       _Enable_SCL_Clock
; //Enabling I2C for no interupts and enabling core
; Enable_I2C_CS();
       move.b    #128,4227076
; return;
       rts
; }
; /************************************************************************************
; ** ADC Write Function to measure Thermistor, Potentimeter, Photo-resistor
; ************************************************************************************/
; unsigned char ADCWrite(int type){
       xdef      _ADCWrite
_ADCWrite:
       link      A6,#-24
       movem.l   D2/D3/A2/A3,-(A7)
       lea       _WaitForI2C_TIP.L,A2
       move.l    8(A6),D3
       lea       _WaitForI2C_RxACK.L,A3
; int i;
; unsigned char c;
; unsigned char* data[3];
; unsigned char temp, light, potential;
; unsigned int delay = 0xFFFFF;
       move.l    #1048575,-4(A6)
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Send data to Transmit register
; I2C_Transmit = ADC_DAC_WRITE_ADDRESS;
       move.b    #146,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Send data to Transmit register
; I2C_Transmit = ADC_ENABLE_COMMAND;
       move.b    #68,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Send data to Transmit register
; I2C_Transmit = ADC_READ_ADDRESS;
       move.b    #147,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Set Command register to skip
; I2C_Command = I2C_Slave_Read_Command;
       move.b    #33,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Set Command register to skip
; I2C_Command = I2C_Slave_Read_Command;
       move.b    #33,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Grabbing read data from Receive Register for Thermistor
; c = I2C_Receive;
       move.b    4227078,D2
; temp = c;
       move.b    D2,-7(A6)
; //Set Command register to skip
; I2C_Command = I2C_Slave_Read_Command;
       move.b    #33,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Grabbing read data from Receive Register for Potentiometer
; c = I2C_Receive;
       move.b    4227078,D2
; potential = c;
       move.b    D2,-5(A6)
; //Set Command register to skip
; I2C_Command = I2C_Slave_Read_Command;
       move.b    #33,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Grabbing read data from Receive Register for Photo-resister
; c = I2C_Receive;
       move.b    4227078,D2
; light = c;
       move.b    D2,-6(A6)
; c = 0xFF; //Give garabage value after in case
       move.b    #255,D2
; if(type == TEMP){
       tst.l     D3
       bne.s     ADCWrite_1
; return temp;
       move.b    -7(A6),D0
       bra.s     ADCWrite_3
ADCWrite_1:
; }else if(type == POTENTIAL){
       cmp.l     #1,D3
       bne.s     ADCWrite_4
; return potential;
       move.b    -5(A6),D0
       bra.s     ADCWrite_3
ADCWrite_4:
; }else if(type == LIGHT){
       cmp.l     #2,D3
       bne.s     ADCWrite_6
; return light;
       move.b    -6(A6),D0
       bra.s     ADCWrite_3
ADCWrite_6:
; }else{
; return c;
       move.b    D2,D0
ADCWrite_3:
       movem.l   (A7)+,D2/D3/A2/A3
       unlk      A6
       rts
; }
; }
       section   const
@canbus~1_1:
       dc.b      86,97,108,117,101,32,111,102,32,84,104,101,114
       dc.b      109,105,115,116,111,114,32,40,67,65,78,48,41
       dc.b      58,32,37,100,10,0
@canbus~1_2:
       dc.b      86,97,108,117,101,32,111,102,32,80,111,116,101
       dc.b      110,116,105,111,109,101,116,101,114,32,40,67
       dc.b      65,78,48,41,58,32,37,100,10,0
@canbus~1_3:
       dc.b      86,97,108,117,101,32,111,102,32,80,104,111,116
       dc.b      111,45,114,101,115,105,115,116,101,114,32,40
       dc.b      67,65,78,48,41,58,32,37,100,10,0
@canbus~1_4:
       dc.b      86,97,108,117,101,32,111,102,32,83,87,91,55
       dc.b      45,48,93,32,40,67,65,78,48,41,58,32,0
@canbus~1_5:
       dc.b      48,0
@canbus~1_6:
       dc.b      49,0
@canbus~1_7:
       dc.b      10,0
@canbus~1_8:
       dc.b      69,82,82,79,82,0
@canbus~1_9:
       dc.b      86,97,108,117,101,32,111,102,32,84,104,101,114
       dc.b      109,105,115,116,111,114,32,40,67,65,78,49,41
       dc.b      58,32,37,100,10,0
@canbus~1_10:
       dc.b      86,97,108,117,101,32,111,102,32,80,111,116,101
       dc.b      110,116,105,111,109,101,116,101,114,32,40,67
       dc.b      65,78,49,41,58,32,37,100,10,0
@canbus~1_11:
       dc.b      86,97,108,117,101,32,111,102,32,80,104,111,116
       dc.b      111,45,114,101,115,105,115,116,101,114,32,40
       dc.b      67,65,78,49,41,58,32,37,100,10,0
@canbus~1_12:
       dc.b      86,97,108,117,101,32,111,102,32,83,87,91,55
       dc.b      45,48,93,32,40,67,65,78,49,41,58,32,0
@canbus~1_13:
       dc.b      13,10,13,10,45,45,45,45,32,67,65,78,66,85,83
       dc.b      32,84,101,115,116,32,45,45,45,45,13,10,0
@canbus~1_14:
       dc.b      13,10,0
       xref      _printf
