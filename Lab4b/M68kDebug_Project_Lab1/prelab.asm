; C:\M68K\PROGRAMS\DEBUGMONITORCODE\PRELAB.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
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
; #define StartOfExceptionVectorTable 0x0B000000
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
; /******************************************************************************
; **  SPI Controller Registers
; *******************************************************************************/
; #define SPI_Control     (*(volatile unsigned char *)(0x00408020))
; #define SPI_Status      (*(volatile unsigned char *)(0x00408022))
; #define SPI_Data        (*(volatile unsigned char *)(0x00408024))
; #define SPI_Ext         (*(volatile unsigned char *)(0x00408026))
; #define SPI_CS          (*(volatile unsigned char *)(0x00408028))
; #define   Enable_SPI_CS()             SPI_CS = 0xFE
; #define   Disable_SPI_CS()            SPI_CS = 0xFF
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
; // SPI Function Prototypes
; int TestForSPITransmitDataComplete(void);
; void SPI_Init(void);
; void WaitForSPITransmitComplete(void);
; int WriteSPIChar(int c);
; void WriteDataToSPI(char *MemAddress, int FlashAddress, int size);
; void WaitForSPIWriteComplete(void);
; void WriteCommandSPI(int cmd);
; void ReadDataFromSPI(char *MemAddress, int FlashAddress, int size);
; void EraseFlashChip(void);
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
; /******************************************************************************
; **  Subroutine to output a single character to the 2 row LCD display
; **  It is assumed the character is an ASCII code and it will be displayed at the
; **  current cursor position
; *******************************************************************************/
; void LCDOutchar(int c)
; {
       xdef      _LCDOutchar
_LCDOutchar:
       link      A6,#0
; LCDdata = (char)(c);
       move.l    8(A6),D0
       move.b    D0,4194338
; Wait1ms() ;
       jsr       _Wait1ms
       unlk      A6
       rts
; }
; /**********************************************************************************
; *subroutine to output a message at the current cursor position of the LCD display
; ************************************************************************************/
; void LCDOutMessage(char *theMessage)
; {
       xdef      _LCDOutMessage
_LCDOutMessage:
       link      A6,#-4
; char c ;
; while((c = *theMessage++) != 0)     // output characters from the string until NULL
LCDOutMessage_1:
       move.l    8(A6),A0
       addq.l    #1,8(A6)
       move.b    (A0),-1(A6)
       move.b    (A0),D0
       beq.s     LCDOutMessage_3
; LCDOutchar(c) ;
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       _LCDOutchar
       addq.w    #4,A7
       bra       LCDOutMessage_1
LCDOutMessage_3:
       unlk      A6
       rts
; }
; /******************************************************************************
; *subroutine to clear the line by issuing 24 space characters
; *******************************************************************************/
; void LCDClearln(void)
; {
       xdef      _LCDClearln
_LCDClearln:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 24; i ++)
       clr.l     D2
LCDClearln_1:
       cmp.l     #24,D2
       bge.s     LCDClearln_3
; LCDOutchar(' ') ;       // write a space char to the LCD display
       pea       32
       jsr       _LCDOutchar
       addq.w    #4,A7
       addq.l    #1,D2
       bra       LCDClearln_1
LCDClearln_3:
       move.l    (A7)+,D2
       rts
; }
; /******************************************************************************
; **  Subroutine to move the LCD cursor to the start of line 1 and clear that line
; *******************************************************************************/
; void LCDLine1Message(char *theMessage)
; {
       xdef      _LCDLine1Message
_LCDLine1Message:
       link      A6,#0
; LCDcommand = 0x80 ;
       move.b    #128,4194336
; Wait3ms();
       jsr       _Wait3ms
; LCDClearln() ;
       jsr       _LCDClearln
; LCDcommand = 0x80 ;
       move.b    #128,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDOutMessage(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _LCDOutMessage
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /******************************************************************************
; **  Subroutine to move the LCD cursor to the start of line 2 and clear that line
; *******************************************************************************/
; void LCDLine2Message(char *theMessage)
; {
       xdef      _LCDLine2Message
_LCDLine2Message:
       link      A6,#0
; LCDcommand = 0xC0 ;
       move.b    #192,4194336
; Wait3ms();
       jsr       _Wait3ms
; LCDClearln() ;
       jsr       _LCDClearln
; LCDcommand = 0xC0 ;
       move.b    #192,4194336
; Wait3ms() ;
       jsr       _Wait3ms
; LCDOutMessage(theMessage) ;
       move.l    8(A6),-(A7)
       jsr       _LCDOutMessage
       addq.w    #4,A7
       unlk      A6
       rts
; }
; /*********************************************************************************************************************************
; **  IMPORTANT FUNCTION
; **  This function install an exception handler so you can capture and deal with any 68000 exception in your program
; **  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
; **  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
; **  Calling this function allows you to deal with Interrupts for example
; ***********************************************************************************************************************************/
; void InstallExceptionHandler( void (*function_ptr)(), int level)
; {
       xdef      _InstallExceptionHandler
_InstallExceptionHandler:
       link      A6,#-4
; volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor
       move.l    #184549376,-4(A6)
; RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
       move.l    -4(A6),A0
       move.l    12(A6),D0
       lsl.l     #2,D0
       move.l    8(A6),0(A0,D0.L)
       unlk      A6
       rts
; }
; /******************************************************************************
; **  SPI Functions
; *******************************************************************************/
; /******************************************************************************************
; ** The following code is for the
; controller
; *******************************************************************************************/
; // return true if the SPI has finished transmitting a byte (to say the Flash chip) return false otherwise
; // this can be used in a polling algorithm to know when the controller is busy or idle.
; int TestForSPITransmitDataComplete(void)    {
       xdef      _TestForSPITransmitDataComplete
_TestForSPITransmitDataComplete:
; /* DONE: TODO replace 0 below with a test for status register SPIF bit and if set, return true */
; return (SPI_Status & 0x80);
       move.b    4227106,D0
       and.l     #255,D0
       and.l     #128,D0
       rts
; }
; /************************************************************************************
; ** initialises the SPI controller chip to set speed, interrupt capability etc.
; ************************************************************************************/
; void SPI_Init(void)
; {
       xdef      _SPI_Init
_SPI_Init:
; //DONE: TODO
; //
; // Program the SPI Control, EXT, CS and Status registers to initialise the SPI controller
; // Don't forget to call this routine from main() before you do anything else with SPI
; //
; // Here are some settings we want to create
; //
; // Control Reg     - interrupts disabled, core enabled, Master mode, Polarity and Phase of clock = [0,0], speed =  divide by 32 = approx 700Khz
; // Ext Reg         - in conjunction with control reg, sets speed above and also sets interrupt flag after every completed transfer (each byte)
; // SPI_CS Reg      - control selection of slave SPI chips via their CS# signals
; // Status Reg      - status of SPI controller chip and used to clear any write collision and interrupt on transmit complete flag
; // SPCR = {SPIE, SPE, x, MSTR, CPOL, CPHA, SPR} = 01x1_0011 = 0x53
; SPI_Control = 0x53;
       move.b    #83,4227104
; // SPER = {ICNT, x, x, x, x, ESPR} = 00xx_xx00 = 0x00
; SPI_Ext = 0x00;
       clr.b     4227110
; Disable_SPI_CS();
       move.b    #255,4227112
       rts
; // SPSR = {SPIF, WCOL, x, x, x, x, x} = 11xx_xxxx = 0xC0
; // Use bitwise OR because we dont want to overrite data in other bits, only ensure that SPIF and WCOL are 1
; //SPI_Status |= 0xC0;
; }
; /************************************************************************************
; ** return ONLY when the SPI controller has finished transmitting a byte
; ************************************************************************************/
; void WaitForSPITransmitComplete(void)
; {
       xdef      _WaitForSPITransmitComplete
_WaitForSPITransmitComplete:
; // DONE: TODO : poll the status register SPIF bit looking for completion of transmission
; // once transmission is complete, clear the write collision and interrupt on transmit complete flags in the status register (read documentation)
; // just in case they were set
; // need to keep checking until data fully transmitted
; // printf("\r\nChecking for SPI transmit complete");
; while(!TestForSPITransmitDataComplete()) {}
WaitForSPITransmitComplete_1:
       jsr       _TestForSPITransmitDataComplete
       tst.l     D0
       bne.s     WaitForSPITransmitComplete_3
       bra       WaitForSPITransmitComplete_1
WaitForSPITransmitComplete_3:
; SPI_Status |= 0xC0;
       or.b      #192,4227106
       rts
; // printf("\r\nSPI transmit complete!");
; }
; /************************************************************************************
; ** Write a byte to the SPI flash chip via the controller and returns (reads) whatever was
; ** given back by SPI device at the same time (removes the read byte from the FIFO)
; ************************************************************************************/
; int WriteSPIChar(int c)
; {
       xdef      _WriteSPIChar
_WriteSPIChar:
       link      A6,#-4
; // DONE: TODO
; // STEP 1 - Write the byte in parameter 'c' to the SPI data register, this will start it transmitting to the flash device
; // STEP 2 - wait for completion of transmission
; // STEP 3 - Return the received data from Flash chip (which may not be relevent depending upon what we are doing)
; //          by reading fom the SPI controller Data Register.
; // note however that in order to get data from an SPI slave device (e.g. flash) chip we have to write a dummy byte to it
; //
; // modify '0' below to return back read byte from data register
; // Dummy byte
; int received_data;
; // STEP 1
; SPI_Data = c;
       move.l    8(A6),D0
       move.b    D0,4227108
; // STEP 2
; WaitForSPITransmitComplete();
       jsr       _WaitForSPITransmitComplete
; received_data = SPI_Data;
       move.b    4227108,D0
       and.l     #255,D0
       move.l    D0,-4(A6)
; // STEP 3
; // printf("\r\nchar hooray");
; return received_data;
       move.l    -4(A6),D0
       unlk      A6
       rts
; }
; /************************************************************************************
; ** User defined SPI Commands - (1) Includes Writing Data to SPI, (2) Waiting for write,
; ** (3) Writing commands to SPI, (4) Reading from SPI, and (5) erasing flash chip
; ************************************************************************************/
; // (1) Writing to SPI
; void WriteDataToSPI(unsigned char *MemAddress, int FlashAddress, int size)
; {
       xdef      _WriteDataToSPI
_WriteDataToSPI:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       lea       _WriteSPIChar.L,A2
       move.l    12(A6),D3
; int i = 0;
       clr.l     D2
; // to enable writing, send command 0x06 to flash chip
; WriteCommandSPI(0x06);
       pea       6
       jsr       _WriteCommandSPI
       addq.w    #4,A7
; // still manually enabling/disabling CS for more complicated transmissions
; // since we dont want the actual internal memory cell writes yet
; Enable_SPI_CS();
       move.b    #254,4227112
; // getting chip to write data, Page Program to chip by sending command 0x02
; WriteSPIChar(0x02);
       pea       2
       jsr       (A2)
       addq.w    #4,A7
; // sending 3 bytes that make up the 24 bit internal flash address
; // gotta break it up into 3
; WriteSPIChar(FlashAddress >> 16);
       move.l    D3,D1
       asr.l     #8,D1
       asr.l     #8,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar(FlashAddress >> 8);
       move.l    D3,D1
       asr.l     #8,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar(FlashAddress);
       move.l    D3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; // can now send up to 256 bytes of data by writing one byte at a time to
; // SPI controller data register
; for(i=0; i<size; i++)
       clr.l     D2
WriteDataToSPI_1:
       cmp.l     16(A6),D2
       bge.s     WriteDataToSPI_3
; {
; WriteSPIChar(MemAddress[i]);
       move.l    8(A6),A0
       move.b    0(A0,D2.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
       addq.l    #1,D2
       bra       WriteDataToSPI_1
WriteDataToSPI_3:
; }
; // once CS is high again, chip performs actual internal memory cell writes
; Disable_SPI_CS();
       move.b    #255,4227112
; WaitForSPIWriteComplete();
       jsr       _WaitForSPIWriteComplete
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; // (2) Waiting for write to complete
; void WaitForSPIWriteComplete(void)
; {
       xdef      _WaitForSPIWriteComplete
_WaitForSPIWriteComplete:
; Enable_SPI_CS();
       move.b    #254,4227112
; // status register (SPSR) reset value: 0x05
; WriteSPIChar(0x05);
       pea       5
       jsr       _WriteSPIChar
       addq.w    #4,A7
; // WriteSPIChar will return received data, if bit 0 (RFEMPTY) is high,
; // FIFO is empty and write is complete
; // printf("\r\nWAITING FOR FIFO EMPTY");
; while(WriteSPIChar(0x00)&0x01){
WaitForSPIWriteComplete_1:
       clr.l     -(A7)
       jsr       _WriteSPIChar
       addq.w    #4,A7
       and.l     #1,D0
       beq.s     WaitForSPIWriteComplete_3
; }
       bra       WaitForSPIWriteComplete_1
WaitForSPIWriteComplete_3:
; // printf("\r\nFIFO EMPTY!");
; Disable_SPI_CS();
       move.b    #255,4227112
       rts
; }
; // (3) Writing commands to SPI
; void WriteCommandSPI(int cmd)
; {
       xdef      _WriteCommandSPI
_WriteCommandSPI:
       link      A6,#0
; // need to enable flash chip before speaking to it
; // this is done by setting CS# low by writing to SPI controller CS register
; // need to disable this when we are finished each interaction
; // printf("\r\nEnabling CS");
; Enable_SPI_CS();
       move.b    #254,4227112
; // printf("\r\nWriting command via WriteSPIChar");
; WriteSPIChar(cmd);
       move.l    8(A6),-(A7)
       jsr       _WriteSPIChar
       addq.w    #4,A7
; // printf("\r\nDisabling CS");
; Disable_SPI_CS();
       move.b    #255,4227112
       unlk      A6
       rts
; }
; // (4) Reading from SPI
; void ReadDataFromSPI(unsigned char *MemAddress, int FlashAddress, int size)
; {
       xdef      _ReadDataFromSPI
_ReadDataFromSPI:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _WriteSPIChar.L,A2
       move.l    12(A6),D3
; int i =0;
       clr.l     D2
; int dummy = 0;
       clr.l     D4
; // still manually enabling/disabling CS for more complicated transmissions
; Enable_SPI_CS();
       move.b    #254,4227112
; // issuing single read command 0x03
; WriteSPIChar(0x03);
       pea       3
       jsr       (A2)
       addq.w    #4,A7
; // followed by 24 bit internal start address broken into 3 bytes
; WriteSPIChar(FlashAddress >> 16);
       move.l    D3,D1
       asr.l     #8,D1
       asr.l     #8,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar(FlashAddress >> 8);
       move.l    D3,D1
       asr.l     #8,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar(FlashAddress);
       move.l    D3,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; for(i=0; i<size; i++)
       clr.l     D2
ReadDataFromSPI_1:
       cmp.l     16(A6),D2
       bge.s     ReadDataFromSPI_3
; {
; // can write dummy bytes to device
; // any data is fine, they are ignored by mem chip since we are in READ mode
; // teach write will return data stored in successive incremental locations
; dummy = WriteSPIChar(0x00);
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #4,A7
       move.l    D0,D4
; MemAddress[i] = (unsigned char) dummy;
       move.l    8(A6),A0
       move.b    D4,0(A0,D2.L)
       addq.l    #1,D2
       bra       ReadDataFromSPI_1
ReadDataFromSPI_3:
; }
; Disable_SPI_CS();
       move.b    #255,4227112
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; // (5) Erasing Flash Chip
; void EraseFlashChip(void)
; {
       xdef      _EraseFlashChip
_EraseFlashChip:
; // enabling device for writing
; // printf("\r\nErase Sequence: writing 06");
; WriteCommandSPI(0x06);
       pea       6
       jsr       _WriteCommandSPI
       addq.w    #4,A7
; // either writing hex C7 or 60 erases the chip
; // printf("\r\nErase Sequence: writing C7");
; WriteCommandSPI(0xC7);
       pea       199
       jsr       _WriteCommandSPI
       addq.w    #4,A7
; // Wait for write to complete
; // printf("\r\nSTARTING WAIT FOR SPI WRITE COMPLETE");
; WaitForSPIWriteComplete();
       jsr       _WaitForSPIWriteComplete
; printf("\r\nSPI flash chip has been erased!");
       pea       @prelab_1.L
       jsr       _printf
       addq.w    #4,A7
       rts
; }
; /******************************************************************************************************************************
; * Start of user program
; ******************************************************************************************************************************/
; void main()
; {
       xdef      _main
_main:
       link      A6,#-676
       movem.l   D2/D3/D4/D5/A2/A3/A4/A5,-(A7)
       lea       _printf.L,A2
       lea       _InstallExceptionHandler.L,A3
       lea       -256(A6),A4
       lea       -512(A6),A5
; unsigned int row, i=0, count=0, counter1=1;
       clr.l     D2
       clr.l     -672(A6)
       move.l    #1,-668(A6)
; char c, text[150] ;
; unsigned char writeBuffer[256];
; unsigned char readBuffer[256];
; int j = 0;
       clr.l     D3
; int passfailflag =1;
       moveq     #1,D5
; int flashAddress = 2048;
       move.l    #2048,D4
; i = x = y = z = PortA_Count =0;
       clr.l     _PortA_Count.L
       clr.l     _z.L
       clr.l     _y.L
       clr.l     _x.L
       clr.l     D2
; Timer1Count = Timer2Count = Timer3Count = Timer4Count = 0;
       clr.b     _Timer4Count.L
       clr.b     _Timer3Count.L
       clr.b     _Timer2Count.L
       clr.b     _Timer1Count.L
; InstallExceptionHandler(PIA_ISR, 25) ;          // install interrupt handler for PIAs 1 and 2 on level 1 IRQ
       pea       25
       pea       _PIA_ISR.L
       jsr       (A3)
       addq.w    #8,A7
; InstallExceptionHandler(ACIA_ISR, 26) ;		    // install interrupt handler for ACIA on level 2 IRQ
       pea       26
       pea       _ACIA_ISR.L
       jsr       (A3)
       addq.w    #8,A7
; InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-4 on level 3 IRQ
       pea       27
       pea       _Timer_ISR.L
       jsr       (A3)
       addq.w    #8,A7
; InstallExceptionHandler(Key2PressISR, 28) ;	    // install interrupt handler for Key Press 2 on DE1 board for level 4 IRQ
       pea       28
       pea       _Key2PressISR.L
       jsr       (A3)
       addq.w    #8,A7
; InstallExceptionHandler(Key1PressISR, 29) ;	    // install interrupt handler for Key Press 1 on DE1 board for level 5 IRQ
       pea       29
       pea       _Key1PressISR.L
       jsr       (A3)
       addq.w    #8,A7
; Timer1Data = 0x10;		// program time delay into timers 1-4
       move.b    #16,4194352
; Timer2Data = 0x20;
       move.b    #32,4194356
; Timer3Data = 0x15;
       move.b    #21,4194360
; Timer4Data = 0x25;
       move.b    #37,4194364
; Timer1Control = 3;		// write 3 to control register to Bit0 = 1 (enable interrupt from timers) 1 - 4 and allow them to count Bit 1 = 1
       move.b    #3,4194354
; Timer2Control = 3;
       move.b    #3,4194358
; Timer3Control = 3;
       move.b    #3,4194362
; Timer4Control = 3;
       move.b    #3,4194366
; Init_LCD();             // initialise the LCD display to use a parallel data interface and 2 lines of display
       jsr       _Init_LCD
; Init_RS232();          // initialise the RS232 port for use with hyper terminal
       jsr       _Init_RS232
; SPI_Init();
       jsr       _SPI_Init
; printf("\r\nRunning Automatic Test");
       pea       @prelab_2.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nThis test will write numbers 0 to 255 into flash chip.");
       pea       @prelab_3.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nThe program will then read back the data from flash chip to validate whether they have been correctly written into.");
       pea       @prelab_4.L
       jsr       (A2)
       addq.w    #4,A7
; // first need to erase SPI flash chip
; printf("\r\nFirst, Erasing SPI flash chip....");
       pea       @prelab_5.L
       jsr       (A2)
       addq.w    #4,A7
; EraseFlashChip();
       jsr       _EraseFlashChip
; // creating a buffer of what we WANT to write into flash chip
; for (i=0; i<sizeof(writeBuffer); ++i)
       clr.l     D2
main_1:
       cmp.l     #256,D2
       bhs.s     main_3
; {
; writeBuffer[i] = i;
       move.b    D2,0(A5,D2.L)
       addq.l    #1,D2
       bra       main_1
main_3:
; }
; printf("\r\nWriting into SPI flash chip.");
       pea       @prelab_6.L
       jsr       (A2)
       addq.w    #4,A7
; for(i=0; i<2048; i++)
       clr.l     D2
main_4:
       cmp.l     #2048,D2
       bhs       main_6
; {
; WriteDataToSPI(writeBuffer, flashAddress, sizeof(writeBuffer));
       pea       256
       move.l    D4,-(A7)
       move.l    A5,-(A7)
       jsr       _WriteDataToSPI
       add.w     #12,A7
; flashAddress = flashAddress + 256;
       add.l     #256,D4
; // get some feedback
; if((i%128) == 0)
       move.l    D2,-(A7)
       pea       128
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     main_7
; printf(". ");
       pea       @prelab_7.L
       jsr       (A2)
       addq.w    #4,A7
main_7:
       addq.l    #1,D2
       bra       main_4
main_6:
; }
; printf("\r\nCompleted writing into SPI flash chip.");
       pea       @prelab_8.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nReading from SPI flash chip.");
       pea       @prelab_9.L
       jsr       (A2)
       addq.w    #4,A7
; // creating an empty read buffer that we will later pull data from SPI
; for (i=0; i<sizeof(readBuffer); ++i)
       clr.l     D2
main_9:
       cmp.l     #256,D2
       bhs.s     main_11
; {
; readBuffer[i] = 0;
       clr.b     0(A4,D2.L)
       addq.l    #1,D2
       bra       main_9
main_11:
; }
; flashAddress = 2048;
       move.l    #2048,D4
; for(i = 0; i<2048; i++)
       clr.l     D2
main_12:
       cmp.l     #2048,D2
       bhs       main_14
; {
; ReadDataFromSPI(readBuffer, flashAddress, sizeof(readBuffer));
       pea       256
       move.l    D4,-(A7)
       move.l    A4,-(A7)
       jsr       _ReadDataFromSPI
       add.w     #12,A7
; for(j = 0; j < sizeof(readBuffer); j++)
       clr.l     D3
main_15:
       cmp.l     #256,D3
       bge       main_17
; {
; if(writeBuffer[j] != readBuffer[j])
       move.b    0(A5,D3.L),D0
       cmp.b     0(A4,D3.L),D0
       beq.s     main_18
; {
; printf("\r\nERROR: Data mismatch found at address %d", j);
       move.l    D3,-(A7)
       pea       @prelab_10.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nWrite Buffer: 0x%08x      Read Buffer: 0x%08x", writeBuffer[j], readBuffer[j]);
       move.b    0(A4,D3.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    0(A5,D3.L),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @prelab_11.L
       jsr       (A2)
       add.w     #12,A7
; passfailflag = 0;
       clr.l     D5
main_18:
       addq.l    #1,D3
       bra       main_15
main_17:
; }
; }
; flashAddress = flashAddress +  256;
       add.l     #256,D4
; // getting some feedback while its programming
; if((i%128) == 0) printf(". ");
       move.l    D2,-(A7)
       pea       128
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     main_20
       pea       @prelab_12.L
       jsr       (A2)
       addq.w    #4,A7
main_20:
       addq.l    #1,D2
       bra       main_12
main_14:
; }
; printf("\r\nReading from flash chip complete.");
       pea       @prelab_13.L
       jsr       (A2)
       addq.w    #4,A7
; if(passfailflag) printf("\r\nProgramming chip SUCCESS.\r\n");
       tst.l     D5
       beq.s     main_22
       pea       @prelab_14.L
       jsr       (A2)
       addq.w    #4,A7
       bra.s     main_23
main_22:
; else printf("\r\nProgramming chip FAILURE.\r\n");
       pea       @prelab_15.L
       jsr       (A2)
       addq.w    #4,A7
main_23:
; printf("\r\nPress KEY[0] to reset.");
       pea       @prelab_16.L
       jsr       (A2)
       addq.w    #4,A7
; while(1)
main_24:
; {}
       bra       main_24
; // programs should NOT exit as there is nothing to Exit TO !!!!!!
; // There is no OS - just press the reset button to end program and call debug
; }
       section   const
@prelab_1:
       dc.b      13,10,83,80,73,32,102,108,97,115,104,32,99,104
       dc.b      105,112,32,104,97,115,32,98,101,101,110,32,101
       dc.b      114,97,115,101,100,33,0
@prelab_2:
       dc.b      13,10,82,117,110,110,105,110,103,32,65,117,116
       dc.b      111,109,97,116,105,99,32,84,101,115,116,0
@prelab_3:
       dc.b      13,10,84,104,105,115,32,116,101,115,116,32,119
       dc.b      105,108,108,32,119,114,105,116,101,32,110,117
       dc.b      109,98,101,114,115,32,48,32,116,111,32,50,53
       dc.b      53,32,105,110,116,111,32,102,108,97,115,104
       dc.b      32,99,104,105,112,46,0
@prelab_4:
       dc.b      13,10,84,104,101,32,112,114,111,103,114,97,109
       dc.b      32,119,105,108,108,32,116,104,101,110,32,114
       dc.b      101,97,100,32,98,97,99,107,32,116,104,101,32
       dc.b      100,97,116,97,32,102,114,111,109,32,102,108
       dc.b      97,115,104,32,99,104,105,112,32,116,111,32,118
       dc.b      97,108,105,100,97,116,101,32,119,104,101,116
       dc.b      104,101,114,32,116,104,101,121,32,104,97,118
       dc.b      101,32,98,101,101,110,32,99,111,114,114,101
       dc.b      99,116,108,121,32,119,114,105,116,116,101,110
       dc.b      32,105,110,116,111,46,0
@prelab_5:
       dc.b      13,10,70,105,114,115,116,44,32,69,114,97,115
       dc.b      105,110,103,32,83,80,73,32,102,108,97,115,104
       dc.b      32,99,104,105,112,46,46,46,46,0
@prelab_6:
       dc.b      13,10,87,114,105,116,105,110,103,32,105,110
       dc.b      116,111,32,83,80,73,32,102,108,97,115,104,32
       dc.b      99,104,105,112,46,0
@prelab_7:
       dc.b      46,32,0
@prelab_8:
       dc.b      13,10,67,111,109,112,108,101,116,101,100,32
       dc.b      119,114,105,116,105,110,103,32,105,110,116,111
       dc.b      32,83,80,73,32,102,108,97,115,104,32,99,104
       dc.b      105,112,46,0
@prelab_9:
       dc.b      13,10,82,101,97,100,105,110,103,32,102,114,111
       dc.b      109,32,83,80,73,32,102,108,97,115,104,32,99
       dc.b      104,105,112,46,0
@prelab_10:
       dc.b      13,10,69,82,82,79,82,58,32,68,97,116,97,32,109
       dc.b      105,115,109,97,116,99,104,32,102,111,117,110
       dc.b      100,32,97,116,32,97,100,100,114,101,115,115
       dc.b      32,37,100,0
@prelab_11:
       dc.b      13,10,87,114,105,116,101,32,66,117,102,102,101
       dc.b      114,58,32,48,120,37,48,56,120,32,32,32,32,32
       dc.b      32,82,101,97,100,32,66,117,102,102,101,114,58
       dc.b      32,48,120,37,48,56,120,0
@prelab_12:
       dc.b      46,32,0
@prelab_13:
       dc.b      13,10,82,101,97,100,105,110,103,32,102,114,111
       dc.b      109,32,102,108,97,115,104,32,99,104,105,112
       dc.b      32,99,111,109,112,108,101,116,101,46,0
@prelab_14:
       dc.b      13,10,80,114,111,103,114,97,109,109,105,110
       dc.b      103,32,99,104,105,112,32,83,85,67,67,69,83,83
       dc.b      46,13,10,0
@prelab_15:
       dc.b      13,10,80,114,111,103,114,97,109,109,105,110
       dc.b      103,32,99,104,105,112,32,70,65,73,76,85,82,69
       dc.b      46,13,10,0
@prelab_16:
       dc.b      13,10,80,114,101,115,115,32,75,69,89,91,48,93
       dc.b      32,116,111,32,114,101,115,101,116,46,0
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
       xref      ULDIV
       xref      _printf
