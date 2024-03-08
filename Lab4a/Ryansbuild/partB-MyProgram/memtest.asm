; C:\M68K\PARTB-MYPROGRAM\MEMTEST.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include <string.h>
; #include <ctype.h>
; //IMPORTANT
; //
; // Uncomment one of the two #defines below
; // Define StartOfExceptionVectorTable as 08030000 if running programs from sram or
; // 0B000000 for running programs from dram
; //
; // In your labs, you will initially start by designing a system with SRam and later move to
; // Dram, so these constants will need to be changed based on the version of the system you have
; // building
; //
; // The working 68k system SOF file posted on canvas that you can use for your pre-lab
; // is based around Dram so #define accordingly before building
; //#define StartOfExceptionVectorTable 0x08030000
; //#define StartOfExceptionVectorTable 0x0B000000
; /**********************************************************************************************
; **	Parallel port addresses
; **********************************************************************************************/
; #define PortA   *(volatile unsigned char *)(0x00400000)
; #define PortB   *(volatile unsigned char *)(0x00400002)
; #define PortC   *(volatile unsigned char *)(0x00400004)
; #define PortD   *(volatile unsigned char *)(0x00400006)
; #define PortE   *(volatile unsigned char *)(0x00400008)
; /*********************************************************************************************
; **	Hex 7 seg displays port addresses
; *********************************************************************************************/
; #define HEX_A        *(volatile unsigned char *)(0x00400010)
; #define HEX_B        *(volatile unsigned char *)(0x00400012)
; #define HEX_C        *(volatile unsigned char *)(0x00400014)    // de2 only
; #define HEX_D        *(volatile unsigned char *)(0x00400016)    // de2 only
; /**********************************************************************************************
; **	LCD display port addresses
; **********************************************************************************************/
; #define LCDcommand   *(volatile unsigned char *)(0x00400020)
; #define LCDdata      *(volatile unsigned char *)(0x00400022)
; /********************************************************************************************
; **	Timer Port addresses
; *********************************************************************************************/
; #define Timer1Data      *(volatile unsigned char *)(0x00400030)
; #define Timer1Control   *(volatile unsigned char *)(0x00400032)
; #define Timer1Status    *(volatile unsigned char *)(0x00400032)
; #define Timer2Data      *(volatile unsigned char *)(0x00400034)
; #define Timer2Control   *(volatile unsigned char *)(0x00400036)
; #define Timer2Status    *(volatile unsigned char *)(0x00400036)
; #define Timer3Data      *(volatile unsigned char *)(0x00400038)
; #define Timer3Control   *(volatile unsigned char *)(0x0040003A)
; #define Timer3Status    *(volatile unsigned char *)(0x0040003A)
; #define Timer4Data      *(volatile unsigned char *)(0x0040003C)
; #define Timer4Control   *(volatile unsigned char *)(0x0040003E)
; #define Timer4Status    *(volatile unsigned char *)(0x0040003E)
; /*********************************************************************************************
; **	RS232 port addresses
; *********************************************************************************************/
; #define RS232_Control     *(volatile unsigned char *)(0x00400040)
; #define RS232_Status      *(volatile unsigned char *)(0x00400040)
; #define RS232_TxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_RxData      *(volatile unsigned char *)(0x00400042)
; #define RS232_Baud        *(volatile unsigned char *)(0x00400044)
; /*********************************************************************************************
; **	PIA 1 and 2 port addresses
; *********************************************************************************************/
; #define PIA1_PortA_Data     *(volatile unsigned char *)(0x00400050)         // combined data and data direction register share same address
; #define PIA1_PortA_Control *(volatile unsigned char *)(0x00400052)
; #define PIA1_PortB_Data     *(volatile unsigned char *)(0x00400054)         // combined data and data direction register share same address
; #define PIA1_PortB_Control *(volatile unsigned char *)(0x00400056)
; #define PIA2_PortA_Data     *(volatile unsigned char *)(0x00400060)         // combined data and data direction register share same address
; #define PIA2_PortA_Control *(volatile unsigned char *)(0x00400062)
; #define PIA2_PortB_data     *(volatile unsigned char *)(0x00400064)         // combined data and data direction register share same address
; #define PIA2_PortB_Control *(volatile unsigned char *)(0x00400066)
; /*********************************************************************************************************************************
; (( DO NOT initialise global variables here, do it main even if you want 0
; (( it's a limitation of the compiler
; (( YOU HAVE BEEN WARNED
; *********************************************************************************************************************************/
; unsigned int i, x, y, z, PortA_Count;
; unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;
; /*******************************************************************************************
; ** Function Prototypes
; *******************************************************************************************/
; void Wait1ms(void);
; void Wait3ms(void);
; void Init_LCD(void) ;
; void LCDOutchar(int c);
; void LCDOutMess(char *theMessage);
; void LCDClearln(void);
; void LCDline1Message(char *theMessage);
; void LCDline2Message(char *theMessage);
; int sprintf(char *out, const char *format, ...) ;
; /*****************************************************************************************
; **	Interrupt service routine for Timers
; **
; **  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
; **  out which timer is producing the interrupt
; **
; *****************************************************************************************/
; void Timer_ISR()
; {
       section   code
       xdef      _Timer_ISR
_Timer_ISR:
; if(Timer1Status == 1) {         // Did Timer 1 produce the Interrupt?
       move.b    4194354,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_1
; Timer1Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194354
; PortA = Timer1Count++ ;     // increment an LED count on PortA with each tick of Timer 1
       move.b    _Timer1Count.L,D0
       addq.b    #1,_Timer1Count.L
       move.b    D0,4194304
Timer_ISR_1:
; }
; if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
       move.b    4194358,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_3
; Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194358
; PortC = Timer2Count++ ;     // increment an LED count on PortC with each tick of Timer 2
       move.b    _Timer2Count.L,D0
       addq.b    #1,_Timer2Count.L
       move.b    D0,4194308
Timer_ISR_3:
; }
; if(Timer3Status == 1) {         // Did Timer 3 produce the Interrupt?
       move.b    4194362,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_5
; Timer3Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194362
; HEX_A = Timer3Count++ ;     // increment a HEX count on Port HEX_A with each tick of Timer 3
       move.b    _Timer3Count.L,D0
       addq.b    #1,_Timer3Count.L
       move.b    D0,4194320
Timer_ISR_5:
; }
; if(Timer4Status == 1) {         // Did Timer 4 produce the Interrupt?
       move.b    4194366,D0
       cmp.b     #1,D0
       bne.s     Timer_ISR_7
; Timer4Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
       move.b    #3,4194366
; HEX_B = Timer4Count++ ;     // increment a HEX count on HEX_B with each tick of Timer 4
       move.b    _Timer4Count.L,D0
       addq.b    #1,_Timer4Count.L
       move.b    D0,4194322
Timer_ISR_7:
       rts
; }
; }
; /*****************************************************************************************
; **	Interrupt service routine for ACIA. This device has it's own dedicate IRQ level
; **  Add your code here to poll Status register and clear interrupt
; *****************************************************************************************/
; void ACIA_ISR()
; {}
       xdef      _ACIA_ISR
_ACIA_ISR:
       rts
; /***************************************************************************************
; **	Interrupt service routine for PIAs 1 and 2. These devices share an IRQ level
; **  Add your code here to poll Status register and clear interrupt
; *****************************************************************************************/
; void PIA_ISR()
; {}
       xdef      _PIA_ISR
_PIA_ISR:
       rts
; /***********************************************************************************
; **	Interrupt service routine for Key 2 on DE1 board. Add your own response here
; ************************************************************************************/
; void Key2PressISR()
; {}
       xdef      _Key2PressISR
_Key2PressISR:
       rts
; /***********************************************************************************
; **	Interrupt service routine for Key 1 on DE1 board. Add your own response here
; ************************************************************************************/
; void Key1PressISR()
; {}
       xdef      _Key1PressISR
_Key1PressISR:
       rts
; /************************************************************************************
; **   Delay Subroutine to give the 68000 something useless to do to waste 1 mSec
; ************************************************************************************/
; void Wait1ms(void)
; {
       xdef      _Wait1ms
_Wait1ms:
       move.l    D2,-(A7)
; int  i ;
; for(i = 0; i < 1000; i ++)
       clr.l     D2
Wait1ms_1:
       cmp.l     #1000,D2
       bge.s     Wait1ms_3
       addq.l    #1,D2
       bra       Wait1ms_1
Wait1ms_3:
       move.l    (A7)+,D2
       rts
; ;
; }
; /************************************************************************************
; **  Subroutine to give the 68000 something useless to do to waste 3 mSec
; **************************************************************************************/
; void Wait3ms(void)
; {
       xdef      _Wait3ms
_Wait3ms:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 3; i++)
       clr.l     D2
Wait3ms_1:
       cmp.l     #3,D2
       bge.s     Wait3ms_3
; Wait1ms() ;
       jsr       _Wait1ms
       addq.l    #1,D2
       bra       Wait3ms_1
Wait3ms_3:
       move.l    (A7)+,D2
       rts
; }
; /*********************************************************************************************
; **  Subroutine to initialise the LCD display by writing some commands to the LCD internal registers
; **  Sets it for parallel port and 2 line display mode (if I recall correctly)
; *********************************************************************************************/
; void Init_LCD(void)
; {
       xdef      _Init_LCD
_Init_LCD:
; LCDcommand = 0x0c ;
       move.b    #12,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDcommand = 0x38 ;
       move.b    #56,4194336
; Wait3ms() ;
       jsr       _Wait3ms
       rts
; }
; /*********************************************************************************************
; **  Subroutine to initialise the RS232 Port by writing some commands to the internal registers
; *********************************************************************************************/
; void Init_RS232(void)
; {
       xdef      _Init_RS232
_Init_RS232:
; RS232_Control = 0x15 ; //  %00010101 set up 6850 uses divide by 16 clock, set RTS low, 8 bits no parity, 1 stop bit, transmitter interrupt disabled
       move.b    #21,4194368
; RS232_Baud = 0x1 ;      // program baud rate generator 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
       move.b    #1,4194372
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level output function to 6850 ACIA
; **  This routine provides the basic functionality to output a single character to the serial Port
; **  to allow the board to communicate with HyperTerminal Program
; **
; **  NOTE you do not call this function directly, instead you call the normal putchar() function
; **  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
; **  call _putch() also
; *********************************************************************************************************/
; int _putch( int c)
; {
       xdef      __putch
__putch:
       link      A6,#0
; while((RS232_Status & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
_putch_1:
       move.b    4194368,D0
       and.b     #2,D0
       cmp.b     #2,D0
       beq.s     _putch_3
       bra       _putch_1
_putch_3:
; ;
; RS232_TxData = (c & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
       move.l    8(A6),D0
       and.l     #127,D0
       move.b    D0,4194370
; return c ;                                              // putchar() expects the character to be returned
       move.l    8(A6),D0
       unlk      A6
       rts
; }
; /*********************************************************************************************************
; **  Subroutine to provide a low level input function to 6850 ACIA
; **  This routine provides the basic functionality to input a single character from the serial Port
; **  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
; **
; **  NOTE you do not call this function directly, instead you call the normal getchar() function
; **  which in turn calls _getch() below). Other functions like gets(), scanf() call getchar() so will
; **  call _getch() also
; *********************************************************************************************************/
; int _getch( void )
; {
       xdef      __getch
__getch:
       link      A6,#-4
; char c ;
; while((RS232_Status & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
_getch_1:
       move.b    4194368,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     _getch_3
       bra       _getch_1
_getch_3:
; ;
; return (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
       move.b    4194370,D0
       and.l     #255,D0
       and.l     #127,D0
       unlk      A6
       rts
; }
; void main(void)
; {
       xdef      _main
_main:
       link      A6,#-16
       movem.l   D2/D3/D4/D5/D6/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _scanf.L,A3
; unsigned int test_option = 0;
       clr.l     -16(A6)
; unsigned int bit_num = 0;
       clr.l     D6
; unsigned int test_pattern = 0;
       clr.l     D3
; unsigned int select_pattern = 0;
       clr.l     -12(A6)
; unsigned int write_data = 0;
       clr.l     D5
; unsigned int start_addr = 0;
       clr.l     -8(A6)
; unsigned int end_addr = 0;
       clr.l     -4(A6)
; unsigned int *addr_point = NULL;
       clr.l     D2
; unsigned int counter = 2000;
       move.l    #2000,D4
; //prompting user for test option BYTES, WORDS, or LONG WORDS
; while(!test_option){
main_1:
       tst.l     -16(A6)
       bne       main_3
; printf("\r\nPlease enter a number to choose one of the following test options:"
       pea       @memtest_1.L
       jsr       (A2)
       addq.w    #4,A7
; "\r\n1 - Bytes"
; "\r\n2 - Words"
; "\r\n3 - Long Words\r\n");
; scanf("%d", &test_option);
       pea       -16(A6)
       pea       @memtest_2.L
       jsr       (A3)
       addq.w    #8,A7
; if((test_option != 1 && test_option != 2 && test_option != 3) || test_option == 0){
       move.l    -16(A6),D0
       cmp.l     #1,D0
       beq.s     main_7
       move.l    -16(A6),D0
       cmp.l     #2,D0
       beq.s     main_7
       move.l    -16(A6),D0
       cmp.l     #3,D0
       bne.s     main_6
main_7:
       move.l    -16(A6),D0
       bne.s     main_4
main_6:
; printf("\r\nInvalid Selection\r\n");
       pea       @memtest_3.L
       jsr       (A2)
       addq.w    #4,A7
; test_option = 0;
       clr.l     -16(A6)
main_4:
       bra       main_1
main_3:
; }
; }
; //assigning bit_num based on test_option
; switch(test_option){
       move.l    -16(A6),D0
       cmp.l     #2,D0
       beq.s     main_11
       bhi.s     main_14
       cmp.l     #1,D0
       beq.s     main_10
       bra       main_8
main_14:
       cmp.l     #3,D0
       beq.s     main_12
       bra.s     main_8
main_10:
; case 1:
; printf("\r\nYou have selected test option BYTES\r\n");
       pea       @memtest_4.L
       jsr       (A2)
       addq.w    #4,A7
; bit_num = 8;
       moveq     #8,D6
; break;
       bra.s     main_9
main_11:
; case 2:
; printf("\r\nYou have selected test option WORDS\r\n");
       pea       @memtest_5.L
       jsr       (A2)
       addq.w    #4,A7
; bit_num = 16;
       moveq     #16,D6
; break;
       bra.s     main_9
main_12:
; case 3:
; printf("\r\nYou have selected test option LONG WORDS\r\n");
       pea       @memtest_6.L
       jsr       (A2)
       addq.w    #4,A7
; bit_num = 32;
       moveq     #32,D6
; break;
       bra.s     main_9
main_8:
; default:
; printf("\r\nException - invalid test option\r\n");
       pea       @memtest_7.L
       jsr       (A2)
       addq.w    #4,A7
; break;
main_9:
; }
; //prompting user to enter test pattern
; while(!select_pattern){
main_15:
       tst.l     -12(A6)
       bne       main_17
; printf("\r\nPlease enter a number to choose one of the following test patterns:"
       pea       @memtest_8.L
       jsr       (A2)
       addq.w    #4,A7
; "\r\n1 - 55"
; "\r\n2 - AA"
; "\r\n3 - FF"
; "\r\n4 - 00\r\n");
; scanf("%d", &select_pattern);
       pea       -12(A6)
       pea       @memtest_9.L
       jsr       (A3)
       addq.w    #8,A7
; if((select_pattern != 1 && select_pattern != 2 && select_pattern != 3 && select_pattern != 4) || select_pattern == 0){
       move.l    -12(A6),D0
       cmp.l     #1,D0
       beq.s     main_21
       move.l    -12(A6),D0
       cmp.l     #2,D0
       beq.s     main_21
       move.l    -12(A6),D0
       cmp.l     #3,D0
       beq.s     main_21
       move.l    -12(A6),D0
       cmp.l     #4,D0
       bne.s     main_20
main_21:
       move.l    -12(A6),D0
       bne.s     main_18
main_20:
; printf("\r\nInvalid Selection\r\n");
       pea       @memtest_10.L
       jsr       (A2)
       addq.w    #4,A7
; select_pattern = 0;
       clr.l     -12(A6)
main_18:
       bra       main_15
main_17:
; }
; }
; //assigning write_data based on test_pattern
; switch(select_pattern){
       move.l    -12(A6),D0
       subq.l    #1,D0
       blo       main_22
       cmp.l     #4,D0
       bhs       main_22
       asl.l     #1,D0
       move.w    main_24(PC,D0.L),D0
       jmp       main_24(PC,D0.W)
main_24:
       dc.w      main_25-main_24
       dc.w      main_26-main_24
       dc.w      main_27-main_24
       dc.w      main_28-main_24
main_25:
; case 1:
; printf("\r\nYou have selected test pattern 55\r\n");
       pea       @memtest_11.L
       jsr       (A2)
       addq.w    #4,A7
; test_pattern = 0x55;
       moveq     #85,D3
; break;
       bra       main_23
main_26:
; case 2:
; printf("\r\nYou have selected test pattern AA\r\n");
       pea       @memtest_12.L
       jsr       (A2)
       addq.w    #4,A7
; test_pattern = 0xAA;
       move.l    #170,D3
; break;
       bra.s     main_23
main_27:
; case 3:
; printf("\r\nYou have selected test pattern FF\r\n");
       pea       @memtest_13.L
       jsr       (A2)
       addq.w    #4,A7
; test_pattern = 0xFF;
       move.l    #255,D3
; break;
       bra.s     main_23
main_28:
; case 4:
; printf("\r\nYou have selected test pattern 00\r\n");
       pea       @memtest_14.L
       jsr       (A2)
       addq.w    #4,A7
; test_pattern = 0x00;
       clr.l     D3
main_22:
; default:
; printf("\r\nException - invalid test pattern\r\n");
       pea       @memtest_15.L
       jsr       (A2)
       addq.w    #4,A7
; break;
main_23:
; }
; //create appropriate data set based on select_pattern and test_option
; // ie, if select_pattern is AA and test_option is BYTES, write_data must be AAAA
; switch(test_option){
       move.l    -16(A6),D0
       cmp.l     #2,D0
       beq.s     main_33
       bhi.s     main_36
       cmp.l     #1,D0
       beq.s     main_32
       bra       main_30
main_36:
       cmp.l     #3,D0
       beq.s     main_34
       bra       main_30
main_32:
; case 1:
; write_data = test_pattern;
       move.l    D3,D5
; break;
       bra       main_31
main_33:
; case 2:
; write_data = test_pattern | test_pattern << 8;
       move.l    D3,D0
       move.l    D3,D1
       lsl.l     #8,D1
       or.l      D1,D0
       move.l    D0,D5
; break;
       bra       main_31
main_34:
; case 3:
; write_data = test_pattern | test_pattern << 8 | test_pattern << 16 | test_pattern << 24;
       move.l    D3,D0
       move.l    D3,D1
       lsl.l     #8,D1
       or.l      D1,D0
       move.l    D3,D1
       lsl.l     #8,D1
       lsl.l     #8,D1
       or.l      D1,D0
       move.l    D3,D1
       lsl.l     #8,D1
       lsl.l     #8,D1
       lsl.l     #8,D1
       or.l      D1,D0
       move.l    D0,D5
; break;
       bra.s     main_31
main_30:
; default:
; printf("\r\nException - could not generate write_data\r\n");
       pea       @memtest_16.L
       jsr       (A2)
       addq.w    #4,A7
; break;
main_31:
; }
; //prompting user to enter start address
; while(!start_addr){
main_37:
       tst.l     -8(A6)
       bne       main_39
; printf("\r\nPlease enter a starting address from 08020000 to 08030000\r\n");
       pea       @memtest_17.L
       jsr       (A2)
       addq.w    #4,A7
; scanf("%x", &start_addr);
       pea       -8(A6)
       pea       @memtest_18.L
       jsr       (A3)
       addq.w    #8,A7
; if(start_addr<0x08020000 || start_addr>0x08030000){
       move.l    -8(A6),D0
       cmp.l     #134348800,D0
       blo.s     main_42
       move.l    -8(A6),D0
       cmp.l     #134414336,D0
       bls.s     main_40
main_42:
; printf("\r\nStart address is invalid\r\n");
       pea       @memtest_19.L
       jsr       (A2)
       addq.w    #4,A7
; start_addr = 0;
       clr.l     -8(A6)
       bra       main_44
main_40:
; } else if(bit_num>8 && start_addr % 2 != 0){
       cmp.l     #8,D6
       bls.s     main_43
       move.l    -8(A6),-(A7)
       pea       2
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       beq.s     main_43
; printf("\r\nFor words or long words, please enter an even numbered address\r\n");
       pea       @memtest_20.L
       jsr       (A2)
       addq.w    #4,A7
; end_addr = 0;
       clr.l     -4(A6)
       bra.s     main_44
main_43:
; } else{
; printf("\r\nThe chosen starting address is: %x\r\n", start_addr);
       move.l    -8(A6),-(A7)
       pea       @memtest_21.L
       jsr       (A2)
       addq.w    #8,A7
main_44:
       bra       main_37
main_39:
; }
; }
; //prompting user to enter end address
; while(!end_addr){
main_45:
       tst.l     -4(A6)
       bne       main_47
; printf("\r\nPlease enter an end address from %x to 08030000\r\n", start_addr);
       move.l    -8(A6),-(A7)
       pea       @memtest_22.L
       jsr       (A2)
       addq.w    #8,A7
; scanf("%x", &end_addr);
       pea       -4(A6)
       pea       @memtest_23.L
       jsr       (A3)
       addq.w    #8,A7
; if(end_addr<start_addr || end_addr>0x08030000){
       move.l    -4(A6),D0
       cmp.l     -8(A6),D0
       blo.s     main_50
       move.l    -4(A6),D0
       cmp.l     #134414336,D0
       bls.s     main_48
main_50:
; printf("\r\nEnd address is invalid\r\n");
       pea       @memtest_24.L
       jsr       (A2)
       addq.w    #4,A7
; end_addr = 0;
       clr.l     -4(A6)
       bra       main_52
main_48:
; } else if(bit_num>8 && end_addr % 2 != 0){
       cmp.l     #8,D6
       bls.s     main_51
       move.l    -4(A6),-(A7)
       pea       2
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       beq.s     main_51
; printf("\r\nFor words or long words, please enter an even numbered address\r\n");
       pea       @memtest_25.L
       jsr       (A2)
       addq.w    #4,A7
; end_addr = 0;
       clr.l     -4(A6)
       bra.s     main_52
main_51:
; } else{
; printf("\r\nThe chosen ending address is: %x\r\n", end_addr);
       move.l    -4(A6),-(A7)
       pea       @memtest_26.L
       jsr       (A2)
       addq.w    #8,A7
main_52:
       bra       main_45
main_47:
; }
; }
; //set address pointer to start pointer
; addr_point = start_addr;
       move.l    -8(A6),D2
; //writing data
; while(addr_point<end_addr){
main_53:
       cmp.l     -4(A6),D2
       bhs       main_55
; *addr_point = write_data;
       move.l    D2,A0
       move.l    D5,(A0)
; counter++;
       addq.l    #1,D4
; if(counter >= 2000){
       cmp.l     #2000,D4
       blo.s     main_56
; printf("\r\nWriting %x into address %x\r\n", *addr_point, addr_point);
       move.l    D2,-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       pea       @memtest_27.L
       jsr       (A2)
       add.w     #12,A7
; counter = 1;
       moveq     #1,D4
main_56:
; }
; //need to increment address pointer according to test option chosen (bytes, words, long words)
; if(test_option == 1){
       move.l    -16(A6),D0
       cmp.l     #1,D0
       bne.s     main_58
; addr_point = addr_point+1;
       addq.l    #4,D2
       bra.s     main_62
main_58:
; } else if(test_option == 2){
       move.l    -16(A6),D0
       cmp.l     #2,D0
       bne.s     main_60
; addr_point = addr_point+2;
       addq.l    #8,D2
       bra.s     main_62
main_60:
; }else if(test_option == 3){
       move.l    -16(A6),D0
       cmp.l     #3,D0
       bne.s     main_62
; addr_point = addr_point+4;
       add.l     #16,D2
main_62:
       bra       main_53
main_55:
; }
; }
; printf("\r\nWriting completed. Will now start reading.\r\n");
       pea       @memtest_28.L
       jsr       (A2)
       addq.w    #4,A7
; addr_point = start_addr;
       move.l    -8(A6),D2
; counter = 2000;
       move.l    #2000,D4
; //reading data
; while(addr_point<end_addr){
main_64:
       cmp.l     -4(A6),D2
       bhs       main_66
; if(*addr_point != write_data){
       move.l    D2,A0
       cmp.l     (A0),D5
       beq.s     main_67
; printf("\r\nAn Error has occurred: data at address %x expected to be %x, instead is reading %x\r\n", addr_point, write_data, *addr_point);
       move.l    D2,A0
       move.l    (A0),-(A7)
       move.l    D5,-(A7)
       move.l    D2,-(A7)
       pea       @memtest_29.L
       jsr       (A2)
       add.w     #16,A7
; printf("\r\nMemory test failed.\r\n");
       pea       @memtest_30.L
       jsr       (A2)
       addq.w    #4,A7
; break;
       bra       main_66
main_67:
; }
; counter++;
       addq.l    #1,D4
; if(counter >= 2000){
       cmp.l     #2000,D4
       blo.s     main_69
; printf("\r\nReading data value %x from address %x\r\n", *addr_point, addr_point);
       move.l    D2,-(A7)
       move.l    D2,A0
       move.l    (A0),-(A7)
       pea       @memtest_31.L
       jsr       (A2)
       add.w     #12,A7
; counter = 1;
       moveq     #1,D4
main_69:
; }
; //need to increment address pointer according to test option chosen (bytes, words, long words)
; if(test_option == 1){
       move.l    -16(A6),D0
       cmp.l     #1,D0
       bne.s     main_71
; addr_point = addr_point+1;
       addq.l    #4,D2
       bra.s     main_75
main_71:
; } else if(test_option == 2){
       move.l    -16(A6),D0
       cmp.l     #2,D0
       bne.s     main_73
; addr_point = addr_point+2;
       addq.l    #8,D2
       bra.s     main_75
main_73:
; }else if(test_option == 3){
       move.l    -16(A6),D0
       cmp.l     #3,D0
       bne.s     main_75
; addr_point = addr_point+4;
       add.l     #16,D2
main_75:
       bra       main_64
main_66:
       movem.l   (A7)+,D2/D3/D4/D5/D6/A2/A3
       unlk      A6
       rts
; }
; }
; }
       section   const
@memtest_1:
       dc.b      13,10,80,108,101,97,115,101,32,101,110,116,101
       dc.b      114,32,97,32,110,117,109,98,101,114,32,116,111
       dc.b      32,99,104,111,111,115,101,32,111,110,101,32
       dc.b      111,102,32,116,104,101,32,102,111,108,108,111
       dc.b      119,105,110,103,32,116,101,115,116,32,111,112
       dc.b      116,105,111,110,115,58,13,10,49,32,45,32,66
       dc.b      121,116,101,115,13,10,50,32,45,32,87,111,114
       dc.b      100,115,13,10,51,32,45,32,76,111,110,103,32
       dc.b      87,111,114,100,115,13,10,0
@memtest_2:
       dc.b      37,100,0
@memtest_3:
       dc.b      13,10,73,110,118,97,108,105,100,32,83,101,108
       dc.b      101,99,116,105,111,110,13,10,0
@memtest_4:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,116,101,115,116,32
       dc.b      111,112,116,105,111,110,32,66,89,84,69,83,13
       dc.b      10,0
@memtest_5:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,116,101,115,116,32
       dc.b      111,112,116,105,111,110,32,87,79,82,68,83,13
       dc.b      10,0
@memtest_6:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,116,101,115,116,32
       dc.b      111,112,116,105,111,110,32,76,79,78,71,32,87
       dc.b      79,82,68,83,13,10,0
@memtest_7:
       dc.b      13,10,69,120,99,101,112,116,105,111,110,32,45
       dc.b      32,105,110,118,97,108,105,100,32,116,101,115
       dc.b      116,32,111,112,116,105,111,110,13,10,0
@memtest_8:
       dc.b      13,10,80,108,101,97,115,101,32,101,110,116,101
       dc.b      114,32,97,32,110,117,109,98,101,114,32,116,111
       dc.b      32,99,104,111,111,115,101,32,111,110,101,32
       dc.b      111,102,32,116,104,101,32,102,111,108,108,111
       dc.b      119,105,110,103,32,116,101,115,116,32,112,97
       dc.b      116,116,101,114,110,115,58,13,10,49,32,45,32
       dc.b      53,53,13,10,50,32,45,32,65,65,13,10,51,32,45
       dc.b      32,70,70,13,10,52,32,45,32,48,48,13,10,0
@memtest_9:
       dc.b      37,100,0
@memtest_10:
       dc.b      13,10,73,110,118,97,108,105,100,32,83,101,108
       dc.b      101,99,116,105,111,110,13,10,0
@memtest_11:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,116,101,115,116,32
       dc.b      112,97,116,116,101,114,110,32,53,53,13,10,0
@memtest_12:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,116,101,115,116,32
       dc.b      112,97,116,116,101,114,110,32,65,65,13,10,0
@memtest_13:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,116,101,115,116,32
       dc.b      112,97,116,116,101,114,110,32,70,70,13,10,0
@memtest_14:
       dc.b      13,10,89,111,117,32,104,97,118,101,32,115,101
       dc.b      108,101,99,116,101,100,32,116,101,115,116,32
       dc.b      112,97,116,116,101,114,110,32,48,48,13,10,0
@memtest_15:
       dc.b      13,10,69,120,99,101,112,116,105,111,110,32,45
       dc.b      32,105,110,118,97,108,105,100,32,116,101,115
       dc.b      116,32,112,97,116,116,101,114,110,13,10,0
@memtest_16:
       dc.b      13,10,69,120,99,101,112,116,105,111,110,32,45
       dc.b      32,99,111,117,108,100,32,110,111,116,32,103
       dc.b      101,110,101,114,97,116,101,32,119,114,105,116
       dc.b      101,95,100,97,116,97,13,10,0
@memtest_17:
       dc.b      13,10,80,108,101,97,115,101,32,101,110,116,101
       dc.b      114,32,97,32,115,116,97,114,116,105,110,103
       dc.b      32,97,100,100,114,101,115,115,32,102,114,111
       dc.b      109,32,48,56,48,50,48,48,48,48,32,116,111,32
       dc.b      48,56,48,51,48,48,48,48,13,10,0
@memtest_18:
       dc.b      37,120,0
@memtest_19:
       dc.b      13,10,83,116,97,114,116,32,97,100,100,114,101
       dc.b      115,115,32,105,115,32,105,110,118,97,108,105
       dc.b      100,13,10,0
@memtest_20:
       dc.b      13,10,70,111,114,32,119,111,114,100,115,32,111
       dc.b      114,32,108,111,110,103,32,119,111,114,100,115
       dc.b      44,32,112,108,101,97,115,101,32,101,110,116
       dc.b      101,114,32,97,110,32,101,118,101,110,32,110
       dc.b      117,109,98,101,114,101,100,32,97,100,100,114
       dc.b      101,115,115,13,10,0
@memtest_21:
       dc.b      13,10,84,104,101,32,99,104,111,115,101,110,32
       dc.b      115,116,97,114,116,105,110,103,32,97,100,100
       dc.b      114,101,115,115,32,105,115,58,32,37,120,13,10
       dc.b      0
@memtest_22:
       dc.b      13,10,80,108,101,97,115,101,32,101,110,116,101
       dc.b      114,32,97,110,32,101,110,100,32,97,100,100,114
       dc.b      101,115,115,32,102,114,111,109,32,37,120,32
       dc.b      116,111,32,48,56,48,51,48,48,48,48,13,10,0
@memtest_23:
       dc.b      37,120,0
@memtest_24:
       dc.b      13,10,69,110,100,32,97,100,100,114,101,115,115
       dc.b      32,105,115,32,105,110,118,97,108,105,100,13
       dc.b      10,0
@memtest_25:
       dc.b      13,10,70,111,114,32,119,111,114,100,115,32,111
       dc.b      114,32,108,111,110,103,32,119,111,114,100,115
       dc.b      44,32,112,108,101,97,115,101,32,101,110,116
       dc.b      101,114,32,97,110,32,101,118,101,110,32,110
       dc.b      117,109,98,101,114,101,100,32,97,100,100,114
       dc.b      101,115,115,13,10,0
@memtest_26:
       dc.b      13,10,84,104,101,32,99,104,111,115,101,110,32
       dc.b      101,110,100,105,110,103,32,97,100,100,114,101
       dc.b      115,115,32,105,115,58,32,37,120,13,10,0
@memtest_27:
       dc.b      13,10,87,114,105,116,105,110,103,32,37,120,32
       dc.b      105,110,116,111,32,97,100,100,114,101,115,115
       dc.b      32,37,120,13,10,0
@memtest_28:
       dc.b      13,10,87,114,105,116,105,110,103,32,99,111,109
       dc.b      112,108,101,116,101,100,46,32,87,105,108,108
       dc.b      32,110,111,119,32,115,116,97,114,116,32,114
       dc.b      101,97,100,105,110,103,46,13,10,0
@memtest_29:
       dc.b      13,10,65,110,32,69,114,114,111,114,32,104,97
       dc.b      115,32,111,99,99,117,114,114,101,100,58,32,100
       dc.b      97,116,97,32,97,116,32,97,100,100,114,101,115
       dc.b      115,32,37,120,32,101,120,112,101,99,116,101
       dc.b      100,32,116,111,32,98,101,32,37,120,44,32,105
       dc.b      110,115,116,101,97,100,32,105,115,32,114,101
       dc.b      97,100,105,110,103,32,37,120,13,10,0
@memtest_30:
       dc.b      13,10,77,101,109,111,114,121,32,116,101,115
       dc.b      116,32,102,97,105,108,101,100,46,13,10,0
@memtest_31:
       dc.b      13,10,82,101,97,100,105,110,103,32,100,97,116
       dc.b      97,32,118,97,108,117,101,32,37,120,32,102,114
       dc.b      111,109,32,97,100,100,114,101,115,115,32,37
       dc.b      120,13,10,0
       section   bss
       xdef      _i
_i:
       ds.b      4
       xdef      _x
_x:
       ds.b      4
       xdef      _y
_y:
       ds.b      4
       xdef      _z
_z:
       ds.b      4
       xdef      _PortA_Count
_PortA_Count:
       ds.b      4
       xdef      _Timer1Count
_Timer1Count:
       ds.b      1
       xdef      _Timer2Count
_Timer2Count:
       ds.b      1
       xdef      _Timer3Count
_Timer3Count:
       ds.b      1
       xdef      _Timer4Count
_Timer4Count:
       ds.b      1
       xref      _scanf
       xref      ULDIV
       xref      _printf
