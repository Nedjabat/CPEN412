; C:\M68K\CPEN412\M68K_25MHZ_BACKUP\LAB5_USERPROGRAM\LAB5.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
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
; **  I2C Controller Registers
; *******************************************************************************/
; //for Lab 5, address range from 0x00408000 - 0040800F has been chosen to avoid conflict
; //with any other IO devices already in system
; #define I2C_PRERlo      (*(volatile unsigned char *)(0x00408000))
; #define I2C_PRERhi      (*(volatile unsigned char *)(0x00408002))
; #define I2C_CTR         (*(volatile unsigned char *)(0x00408004))
; //transmit and receive registers share same address
; #define I2C_TXR         (*(volatile unsigned char *)(0x00408006))
; #define I2C_RXR         (*(volatile unsigned char *)(0x00408006))
; //command and status registers share same address
; #define I2C_CR          (*(volatile unsigned char *)(0x00408008))
; #define I2C_SR          (*(volatile unsigned char *)(0x00408008))
; // I2C_CR[7] = STA, [4] = W, [0] = IACK --> 0x91 (hex)
; #define WRITE_STA 0x91
; // I2C_CR[6] = STO, [4] = W --> 0x50 (hex)
; #define WRITE_STO 0x50
; // I2C_CR[4] = W --> 0x10
; #define WRITING 0x10
; // EEPROM bank addresses
; #define EEPROM_BANK_0 0xA0
; #define EEPROM_BANK_1 0xA8
; #define ADC_DAC_SLAVE 0x90
; #define DAC_ENABLE 0x40
; #define DAC_DISABLE 0x00
; #define ADC_INCREMENT 0x04
; // I2C[5] = read, [3] = ACK, [0] = IACK --> 00100001 = 0x21
; #define READ_ACK 0x21
; //set RD bit and ACK in command reg; [5] = RD, [3] = NACK, [0] = IACK
; #define READ_NACK 0x29
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
; //void Timer_ISR(void);
; void I2C_Init(void);
; void I2C_WaitTIP(void);
; void I2C_WaitRxACK(void);
; void I2C_Transmit(char data, char command);
; void I2C_WriteByte(char data, char slaveAddr, char memoryAddrHigh, char memoryAddrLow);
; void I2C_ReadByte(char *data, char slaveAddr, char memoryAddrHigh, char memoryAddrLow);
; void DAC_test(void);
; void ADC_test(void);
; char select_bank(char *bank);
; void select_mem_addr(char *mem_addr_high, char *mem_addr_low);
; /*****************************************************************************************
; **	Interrupt service routine for Timers
; **
; **  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
; **  out which timer is producing the interrupt
; **
; *****************************************************************************************/
; char xtod(int c)
; {
       section   code
       xdef      _xtod
_xtod:
       link      A6,#0
       move.l    D2,-(A7)
       move.l    8(A6),D2
; if ((char)(c) <= (char)('9'))
       cmp.b     #57,D2
       bgt.s     xtod_1
; return c - (char)(0x30);    // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
       move.b    D2,D0
       sub.b     #48,D0
       bra.s     xtod_3
xtod_1:
; else if((char)(c) > (char)('F'))    // assume lower case
       cmp.b     #70,D2
       ble.s     xtod_4
; return c - (char)(0x57);    // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
       move.b    D2,D0
       sub.b     #87,D0
       bra.s     xtod_3
xtod_4:
; else
; return c - (char)(0x37);    // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
       move.b    D2,D0
       sub.b     #55,D0
xtod_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; int Get2HexDigits(char *CheckSumPtr)
; {
       xdef      _Get2HexDigits
_Get2HexDigits:
       link      A6,#0
       move.l    D2,-(A7)
; register int i = (xtod(_getch()) << 4) | (xtod(_getch()));
       move.l    D0,-(A7)
       jsr       __getch
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    D1,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       and.l     #255,D0
       asl.l     #4,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       __getch
       move.l    (A7)+,D1
       move.l    D0,-(A7)
       jsr       _xtod
       addq.w    #4,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,D2
; if(CheckSumPtr)
       tst.l     8(A6)
       beq.s     Get2HexDigits_1
; *CheckSumPtr += i ;
       move.l    8(A6),A0
       add.b     D2,(A0)
Get2HexDigits_1:
; return i ;
       move.l    D2,D0
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; void Timer_ISR(void)
; {
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
; void Wait500ms(void)
; {
       xdef      _Wait500ms
_Wait500ms:
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < 500; i++)
       clr.l     D2
Wait500ms_1:
       cmp.l     #500,D2
       bge.s     Wait500ms_3
; Wait1ms() ;
       jsr       _Wait1ms
       addq.l    #1,D2
       bra       Wait500ms_1
Wait500ms_3:
       move.l    (A7)+,D2
       rts
; }
; void WaitUserms(int ms)
; {
       xdef      _WaitUserms
_WaitUserms:
       link      A6,#0
       move.l    D2,-(A7)
; int i ;
; for(i = 0; i < ms; i++)
       clr.l     D2
WaitUserms_1:
       cmp.l     8(A6),D2
       bge.s     WaitUserms_3
; Wait1ms() ;
       jsr       _Wait1ms
       addq.l    #1,D2
       bra       WaitUserms_1
WaitUserms_3:
       move.l    (A7)+,D2
       unlk      A6
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
; **  I2C Functions
; *******************************************************************************/
; void I2C_Init(void){
       xdef      _I2C_Init
_I2C_Init:
; // TODO: set for no interrupts, and clock frequency for 100kHz
; I2C_CTR = 0x00; //turn off core
       clr.b     4227076
; // setting clock frequency for 100kHz: prescale = ((25MHz)/(5*100kHz))-1 = 49 (dec) = 31 (hex)
; I2C_PRERlo = 0x31;
       move.b    #49,4227072
; I2C_PRERhi = 0x00;
       clr.b     4227074
; //turn on core and disable interrupts b1000_0000 = 0x80
; I2C_CTR = 0x80;
       move.b    #128,4227076
       rts
; }
; void I2C_WaitTIP(void){
       xdef      _I2C_WaitTIP
_I2C_WaitTIP:
; // check I2C_SR[1] and wait until previous transmits are finished
; //'1' when transferring data, '0' when transfer complete
; while((I2C_SR >> 1)&1){}
I2C_WaitTIP_1:
       move.b    4227080,D0
       lsr.b     #1,D0
       and.b     #1,D0
       beq.s     I2C_WaitTIP_3
       bra       I2C_WaitTIP_1
I2C_WaitTIP_3:
       rts
; }
; void I2C_WaitRxACK(void){
       xdef      _I2C_WaitRxACK
_I2C_WaitRxACK:
; // check I2C_SR[7] and wait for ACK after writing anything over I2C to slave
; // '1' when no ACK received, '0' when ACK received
; while((I2C_SR >> 7)&1){}
I2C_WaitRxACK_1:
       move.b    4227080,D0
       lsr.b     #7,D0
       and.b     #1,D0
       beq.s     I2C_WaitRxACK_3
       bra       I2C_WaitRxACK_1
I2C_WaitRxACK_3:
       rts
; }
; void I2C_Transmit(char data, char command){
       xdef      _I2C_Transmit
_I2C_Transmit:
       link      A6,#0
; // this function just helps simplify transmission process
; I2C_TXR = data;
       move.b    11(A6),4227078
; I2C_CR = command;
       move.b    15(A6),4227080
; I2C_WaitTIP();
       jsr       _I2C_WaitTIP
; I2C_WaitRxACK();
       jsr       _I2C_WaitRxACK
       unlk      A6
       rts
; }
; void I2C_WriteByte(char data, char slaveAddr, char memoryAddrHigh, char memoryAddrLow){
       xdef      _I2C_WriteByte
_I2C_WriteByte:
       link      A6,#0
       move.l    A2,-(A7)
       lea       _I2C_Transmit.L,A2
; // to write data, put transmit data into TX register
; // tell I2C_CR that we are in writing mode
; // if want to generate start or stop condition with each byte written, set STA or STO bits in command register when you write to it
; // similarly, clear ACK bit if you want to generate ACK when reading data back from slave
; I2C_WaitTIP(); //check that nothing is currently in transmission
       jsr       _I2C_WaitTIP
; I2C_Transmit(slaveAddr, WRITE_STA);     //want to write to slave, start cmd
       pea       145
       move.b    15(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_Transmit(memoryAddrHigh, WRITING);  //write 2 bytes corresponding to 2 byte internal addr
       pea       16
       move.b    19(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_Transmit(memoryAddrLow, WRITING);
       pea       16
       move.b    23(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_Transmit(data, WRITE_STO);          //finishing write operation
       pea       80
       move.b    11(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; void I2C_ReadByte(char *data, char slaveAddr, char memoryAddrHigh, char memoryAddrLow){
       xdef      _I2C_ReadByte
_I2C_ReadByte:
       link      A6,#0
       move.l    A2,-(A7)
       lea       _I2C_Transmit.L,A2
; I2C_WaitTIP(); //check that nothing is currently in transmission
       jsr       _I2C_WaitTIP
; I2C_Transmit(slaveAddr, WRITE_STA);     //set write to slave, start cmd
       pea       145
       move.b    15(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_Transmit(memoryAddrHigh, WRITING);  //write 2 bytes corresponding to 2 byte internal addr
       pea       16
       move.b    19(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_Transmit(memoryAddrLow, WRITING);
       pea       16
       move.b    23(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_Transmit(slaveAddr|1, WRITE_STA);   //send repeated start condition
       pea       145
       move.b    15(A6),D1
       or.b      #1,D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; I2C_CR = READ_NACK;
       move.b    #41,4227080
; while(!(I2C_SR & 1)){}                  //check status reg [0] = interrupt flag --> if '1', data has been received
I2C_ReadByte_1:
       move.b    4227080,D0
       and.b     #1,D0
       bne.s     I2C_ReadByte_3
       bra       I2C_ReadByte_1
I2C_ReadByte_3:
; *data = I2C_RXR;                        //received data found in received register
       move.l    8(A6),A0
       move.b    4227078,(A0)
; I2C_CR = 0x41;                          //finish operation and clear pending interrupt; [6] = STO, [0] = IACK
       move.b    #65,4227080
; I2C_CR = 0x50;
       move.b    #80,4227080
       move.l    (A7)+,A2
       unlk      A6
       rts
; }
; void DAC_test(){
       xdef      _DAC_test
_DAC_test:
       movem.l   D2/A2,-(A7)
       lea       _I2C_Transmit.L,A2
; int count = 0;
       clr.l     D2
; I2C_WaitTIP(); //check that nothing is currently in transmission
       jsr       _I2C_WaitTIP
; //I2C_WaitRxACK();
; I2C_Transmit(0x90, WRITE_STA);
       pea       145
       pea       144
       jsr       (A2)
       addq.w    #8,A7
; I2C_Transmit(0x40, WRITING);
       pea       16
       pea       64
       jsr       (A2)
       addq.w    #8,A7
; while(1){
DAC_test_1:
; for(count = 0; count < 255; count++){
       clr.l     D2
DAC_test_4:
       cmp.l     #255,D2
       bge.s     DAC_test_6
; I2C_Transmit(count, WRITING);
       pea       16
       ext.w     D2
       ext.l     D2
       move.l    D2,-(A7)
       jsr       (A2)
       addq.w    #8,A7
; WaitUserms(15);
       pea       15
       jsr       _WaitUserms
       addq.w    #4,A7
       addq.l    #1,D2
       bra       DAC_test_4
DAC_test_6:
       bra       DAC_test_1
; }
; }
; }
; void ADC_test(void){
       xdef      _ADC_test
_ADC_test:
       link      A6,#-4
       movem.l   A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _I2C_Transmit.L,A3
; char garbage, thermistor, potentiometer, photoresist;
; while(1){
ADC_test_1:
; I2C_WaitTIP(); //check that nothing is currently in transmission
       jsr       _I2C_WaitTIP
; I2C_Transmit(ADC_DAC_SLAVE, WRITE_STA);
       pea       145
       pea       144
       jsr       (A3)
       addq.w    #8,A7
; I2C_Transmit(ADC_INCREMENT, WRITING);
       pea       16
       pea       4
       jsr       (A3)
       addq.w    #8,A7
; I2C_Transmit(ADC_DAC_SLAVE | 1, WRITE_STA);
       pea       145
       pea       145
       jsr       (A3)
       addq.w    #8,A7
; I2C_CR = READ_ACK;
       move.b    #33,4227080
; while(!(I2C_SR & 1)){}                  //check status reg [0] = interrupt flag --> if '1', data has been received
ADC_test_4:
       move.b    4227080,D0
       and.b     #1,D0
       bne.s     ADC_test_6
       bra       ADC_test_4
ADC_test_6:
; garbage = I2C_RXR;                    //AN0: External analog source
       move.b    4227078,-4(A6)
; I2C_CR = READ_ACK;
       move.b    #33,4227080
; while(!(I2C_SR & 1)){}                  //check status reg [0] = interrupt flag --> if '1', data has been received
ADC_test_7:
       move.b    4227080,D0
       and.b     #1,D0
       bne.s     ADC_test_9
       bra       ADC_test_7
ADC_test_9:
; thermistor = I2C_RXR;                    //AN1: On board thermistor
       move.b    4227078,-3(A6)
; I2C_CR = READ_ACK;
       move.b    #33,4227080
; while(!(I2C_SR & 1)){}                  //check status reg [0] = interrupt flag --> if '1', data has been received
ADC_test_10:
       move.b    4227080,D0
       and.b     #1,D0
       bne.s     ADC_test_12
       bra       ADC_test_10
ADC_test_12:
; potentiometer = I2C_RXR;                    //AN2: On board potentiometer
       move.b    4227078,-2(A6)
; I2C_CR = READ_ACK;
       move.b    #33,4227080
; while(!(I2C_SR & 1)){}                  //check status reg [0] = interrupt flag --> if '1', data has been received
ADC_test_13:
       move.b    4227080,D0
       and.b     #1,D0
       bne.s     ADC_test_15
       bra       ADC_test_13
ADC_test_15:
; photoresist = I2C_RXR;                    //AN3: On board photoresistor
       move.b    4227078,-1(A6)
; I2C_CR = 0x41;                          //finish operation and clear pending interrupt; [6] = STO, [0] = IACK
       move.b    #65,4227080
; printf("\r\nAN1 - On board potentiometer: %d", potentiometer);
       move.b    -2(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @lab5_1.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nAN2 - On board thermistor: %d", thermistor);
       move.b    -3(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @lab5_2.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\nAN3 - On board photoresist: %d", photoresist);
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       pea       @lab5_3.L
       jsr       (A2)
       addq.w    #8,A7
; printf("\r\n************************************");
       pea       @lab5_4.L
       jsr       (A2)
       addq.w    #4,A7
; WaitUserms(1000);
       pea       1000
       jsr       _WaitUserms
       addq.w    #4,A7
       bra       ADC_test_1
; }
; }
; int select_bank(char *bank){
       xdef      _select_bank
_select_bank:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; unsigned char selection;
; int bank_select;
; while(1){
select_bank_1:
; printf("\r\nEnter digit 0 or 1 to select desired bank.");
       pea       @lab5_5.L
       jsr       _printf
       addq.w    #4,A7
; selection = getchar();
       jsr       _getch
       move.b    D0,D2
; putchar(selection);
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _putch
       addq.w    #4,A7
; //bank_select = selection;
; if(selection == '0'){
       cmp.b     #48,D2
       bne.s     select_bank_4
; *bank = EEPROM_BANK_0;
       move.l    8(A6),A0
       move.b    #160,(A0)
; bank_select = 0;
       clr.l     D3
; break;
       bra.s     select_bank_3
select_bank_4:
; }
; else if(selection == '1'){
       cmp.b     #49,D2
       bne.s     select_bank_6
; *bank = EEPROM_BANK_1;
       move.l    8(A6),A0
       move.b    #168,(A0)
; bank_select = 1;
       moveq     #1,D3
; break;
       bra.s     select_bank_3
select_bank_6:
; }
; else {
; printf("\r\nInvalid selection, please try again.");
       pea       @lab5_6.L
       jsr       _printf
       addq.w    #4,A7
       bra       select_bank_1
select_bank_3:
; }
; }
; return bank_select;
       move.l    D3,D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; void select_mem_addr(char *mem_addr_high, char *mem_addr_low){
       xdef      _select_mem_addr
_select_mem_addr:
       link      A6,#0
; printf("\r\nPlease enter memory address high: ");
       pea       @lab5_7.L
       jsr       _printf
       addq.w    #4,A7
; *mem_addr_high = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    8(A6),A0
       move.b    D0,(A0)
; printf("\r\nPlease enter memory address low: ");
       pea       @lab5_8.L
       jsr       _printf
       addq.w    #4,A7
; *mem_addr_low = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.l    12(A6),A0
       move.b    D0,(A0)
       unlk      A6
       rts
; }
; /******************************************************************************************************************************
; * Start of user program
; ******************************************************************************************************************************/
; void main()
; {
       xdef      _main
_main:
       link      A6,#-172
       movem.l   D2/D3/D4/A2/A3,-(A7)
       lea       _printf.L,A2
       lea       _InstallExceptionHandler.L,A3
; unsigned int row, i=0, count=0, counter1=1;
       clr.l     -168(A6)
       clr.l     -164(A6)
       move.l    #1,-160(A6)
; char c, text[150];
; // Variables used for Lab 5
; unsigned char selection, data_write, data_read, bank, mem_addr_high, mem_addr_low;
; int bank_select;
; //End of variables used for Lab 5
; i = x = y = z = PortA_Count =0;
       clr.l     _PortA_Count.L
       clr.l     _z.L
       clr.l     _y.L
       clr.l     _x.L
       clr.l     -168(A6)
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
; Init_RS232() ;          // initialise the RS232 port for use with hyper terminal
       jsr       _Init_RS232
; /*************************************************************************************************
; **  CPEN 412 Lab 5: I2C UserProgram
; *************************************************************************************************/
; I2C_Init();
       jsr       _I2C_Init
; printf("\r\nCPEN - 412 Lab 5");
       pea       @lab5_9.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nAnna Yun #94902673 - Ryan Nedjabat #67501510");
       pea       @lab5_10.L
       jsr       (A2)
       addq.w    #4,A7
; while(1){ //enter infinite loop
main_1:
; printf("\r\nPlease enter the number corresponding to the desired test:");
       pea       @lab5_11.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nWrite Byte  - 1");
       pea       @lab5_12.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nRead Byte   - 2");
       pea       @lab5_13.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nWrite Page  - 3");
       pea       @lab5_14.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nRead Page   - 4");
       pea       @lab5_15.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nDAC Test    - 5");
       pea       @lab5_16.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nADC Test    - 6\r\n");
       pea       @lab5_17.L
       jsr       (A2)
       addq.w    #4,A7
; selection = getchar();
       jsr       _getch
       move.b    D0,D2
; putchar(selection);
       and.l     #255,D2
       move.l    D2,-(A7)
       jsr       _putch
       addq.w    #4,A7
; //testing write byte
; if(selection == '1'){
       cmp.b     #49,D2
       bne       main_4
; printf("\r\nEnter byte sized data to be written: ");
       pea       @lab5_18.L
       jsr       (A2)
       addq.w    #4,A7
; data_write = Get2HexDigits(0);
       clr.l     -(A7)
       jsr       _Get2HexDigits
       addq.w    #4,A7
       move.b    D0,D4
; //need to select slave bank
; bank_select = select_bank(&bank);
       pea       -3(A6)
       jsr       _select_bank
       addq.w    #4,A7
       and.l     #255,D0
       move.l    D0,D3
; //need to select memory address
; select_mem_addr(&mem_addr_high, &mem_addr_low);
       pea       -1(A6)
       pea       -2(A6)
       jsr       _select_mem_addr
       addq.w    #8,A7
; I2C_WriteByte(data_write, bank, mem_addr_high, mem_addr_low);
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    -2(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    -3(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       ext.w     D4
       ext.l     D4
       move.l    D4,-(A7)
       jsr       _I2C_WriteByte
       add.w     #16,A7
; printf("\r\nWriting %x from EEPROM bank %d. Mem_addr_high = %x. Mem_addr_low = %x", data_write, bank_select, mem_addr_high, mem_addr_low);
       move.b    -1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    -2(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       and.l     #255,D4
       move.l    D4,-(A7)
       pea       @lab5_19.L
       jsr       (A2)
       add.w     #20,A7
       bra       main_15
main_4:
; }
; //testing read byte
; else if(selection == '2'){
       cmp.b     #50,D2
       bne       main_6
; //need to select slave bank
; bank_select = select_bank(&bank);
       pea       -3(A6)
       jsr       _select_bank
       addq.w    #4,A7
       and.l     #255,D0
       move.l    D0,D3
; //need to select memory address
; select_mem_addr(&mem_addr_high, &mem_addr_low);
       pea       -1(A6)
       pea       -2(A6)
       jsr       _select_mem_addr
       addq.w    #8,A7
; I2C_ReadByte(data_read, bank, mem_addr_high, mem_addr_low);
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    -2(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    -3(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.b    -4(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       _I2C_ReadByte
       add.w     #16,A7
; printf("\r\nReading %x from EEPROM bank %d. Mem_addr_high = %x. Mem_addr_low = %x", data_write, bank_select, mem_addr_high, mem_addr_low);
       move.b    -1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.b    -2(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       move.l    D3,-(A7)
       and.l     #255,D4
       move.l    D4,-(A7)
       pea       @lab5_20.L
       jsr       (A2)
       add.w     #20,A7
       bra       main_15
main_6:
; }
; //testing write page
; else if(selection == '3'){
       cmp.b     #51,D2
       bne.s     main_8
; break;
       bra       main_3
main_8:
; }
; //testing read page
; else if(selection == '4'){
       cmp.b     #52,D2
       bne.s     main_10
; break;
       bra       main_3
main_10:
; }
; //testing DAC (LED blinking)
; else if(selection == '5'){
       cmp.b     #53,D2
       bne.s     main_12
; printf("\r\nInitiating DAC test, LED should gradually brighten, before abruptly turning off.");
       pea       @lab5_21.L
       jsr       (A2)
       addq.w    #4,A7
; printf("\r\nThis sequence will repeat infinitely until user presses Key[0]");
       pea       @lab5_22.L
       jsr       (A2)
       addq.w    #4,A7
; DAC_test();
       jsr       _DAC_test
       bra.s     main_15
main_12:
; }
; //testing ADC (reading analog values)
; else if(selection == '6'){
       cmp.b     #54,D2
       bne.s     main_14
; printf("\r\nInitiating ADC test, channel readings are as below: ");
       pea       @lab5_23.L
       jsr       (A2)
       addq.w    #4,A7
; ADC_test();
       jsr       _ADC_test
       bra.s     main_15
main_14:
; }
; //invalid/mistaken selection
; else{
; printf("\r\nInvalid Selection - Please choose of the listed options.");
       pea       @lab5_24.L
       jsr       (A2)
       addq.w    #4,A7
main_15:
       bra       main_1
main_3:
       movem.l   (A7)+,D2/D3/D4/A2/A3
       unlk      A6
       rts
; }
; }
; // programs should NOT exit as there is nothing to Exit TO !!!!!!
; // There is no OS - just press the reset button to end program and call debug
; }
       section   const
@lab5_1:
       dc.b      13,10,65,78,49,32,45,32,79,110,32,98,111,97
       dc.b      114,100,32,112,111,116,101,110,116,105,111,109
       dc.b      101,116,101,114,58,32,37,100,0
@lab5_2:
       dc.b      13,10,65,78,50,32,45,32,79,110,32,98,111,97
       dc.b      114,100,32,116,104,101,114,109,105,115,116,111
       dc.b      114,58,32,37,100,0
@lab5_3:
       dc.b      13,10,65,78,51,32,45,32,79,110,32,98,111,97
       dc.b      114,100,32,112,104,111,116,111,114,101,115,105
       dc.b      115,116,58,32,37,100,0
@lab5_4:
       dc.b      13,10,42,42,42,42,42,42,42,42,42,42,42,42,42
       dc.b      42,42,42,42,42,42,42,42,42,42,42,42,42,42,42
       dc.b      42,42,42,42,42,42,42,42,0
@lab5_5:
       dc.b      13,10,69,110,116,101,114,32,100,105,103,105
       dc.b      116,32,48,32,111,114,32,49,32,116,111,32,115
       dc.b      101,108,101,99,116,32,100,101,115,105,114,101
       dc.b      100,32,98,97,110,107,46,0
@lab5_6:
       dc.b      13,10,73,110,118,97,108,105,100,32,115,101,108
       dc.b      101,99,116,105,111,110,44,32,112,108,101,97
       dc.b      115,101,32,116,114,121,32,97,103,97,105,110
       dc.b      46,0
@lab5_7:
       dc.b      13,10,80,108,101,97,115,101,32,101,110,116,101
       dc.b      114,32,109,101,109,111,114,121,32,97,100,100
       dc.b      114,101,115,115,32,104,105,103,104,58,32,0
@lab5_8:
       dc.b      13,10,80,108,101,97,115,101,32,101,110,116,101
       dc.b      114,32,109,101,109,111,114,121,32,97,100,100
       dc.b      114,101,115,115,32,108,111,119,58,32,0
@lab5_9:
       dc.b      13,10,67,80,69,78,32,45,32,52,49,50,32,76,97
       dc.b      98,32,53,0
@lab5_10:
       dc.b      13,10,65,110,110,97,32,89,117,110,32,35,57,52
       dc.b      57,48,50,54,55,51,32,45,32,82,121,97,110,32
       dc.b      78,101,100,106,97,98,97,116,32,35,54,55,53,48
       dc.b      49,53,49,48,0
@lab5_11:
       dc.b      13,10,80,108,101,97,115,101,32,101,110,116,101
       dc.b      114,32,116,104,101,32,110,117,109,98,101,114
       dc.b      32,99,111,114,114,101,115,112,111,110,100,105
       dc.b      110,103,32,116,111,32,116,104,101,32,100,101
       dc.b      115,105,114,101,100,32,116,101,115,116,58,0
@lab5_12:
       dc.b      13,10,87,114,105,116,101,32,66,121,116,101,32
       dc.b      32,45,32,49,0
@lab5_13:
       dc.b      13,10,82,101,97,100,32,66,121,116,101,32,32
       dc.b      32,45,32,50,0
@lab5_14:
       dc.b      13,10,87,114,105,116,101,32,80,97,103,101,32
       dc.b      32,45,32,51,0
@lab5_15:
       dc.b      13,10,82,101,97,100,32,80,97,103,101,32,32,32
       dc.b      45,32,52,0
@lab5_16:
       dc.b      13,10,68,65,67,32,84,101,115,116,32,32,32,32
       dc.b      45,32,53,0
@lab5_17:
       dc.b      13,10,65,68,67,32,84,101,115,116,32,32,32,32
       dc.b      45,32,54,13,10,0
@lab5_18:
       dc.b      13,10,69,110,116,101,114,32,98,121,116,101,32
       dc.b      115,105,122,101,100,32,100,97,116,97,32,116
       dc.b      111,32,98,101,32,119,114,105,116,116,101,110
       dc.b      58,32,0
@lab5_19:
       dc.b      13,10,87,114,105,116,105,110,103,32,37,120,32
       dc.b      102,114,111,109,32,69,69,80,82,79,77,32,98,97
       dc.b      110,107,32,37,100,46,32,77,101,109,95,97,100
       dc.b      100,114,95,104,105,103,104,32,61,32,37,120,46
       dc.b      32,77,101,109,95,97,100,100,114,95,108,111,119
       dc.b      32,61,32,37,120,0
@lab5_20:
       dc.b      13,10,82,101,97,100,105,110,103,32,37,120,32
       dc.b      102,114,111,109,32,69,69,80,82,79,77,32,98,97
       dc.b      110,107,32,37,100,46,32,77,101,109,95,97,100
       dc.b      100,114,95,104,105,103,104,32,61,32,37,120,46
       dc.b      32,77,101,109,95,97,100,100,114,95,108,111,119
       dc.b      32,61,32,37,120,0
@lab5_21:
       dc.b      13,10,73,110,105,116,105,97,116,105,110,103
       dc.b      32,68,65,67,32,116,101,115,116,44,32,76,69,68
       dc.b      32,115,104,111,117,108,100,32,103,114,97,100
       dc.b      117,97,108,108,121,32,98,114,105,103,104,116
       dc.b      101,110,44,32,98,101,102,111,114,101,32,97,98
       dc.b      114,117,112,116,108,121,32,116,117,114,110,105
       dc.b      110,103,32,111,102,102,46,0
@lab5_22:
       dc.b      13,10,84,104,105,115,32,115,101,113,117,101
       dc.b      110,99,101,32,119,105,108,108,32,114,101,112
       dc.b      101,97,116,32,105,110,102,105,110,105,116,101
       dc.b      108,121,32,117,110,116,105,108,32,117,115,101
       dc.b      114,32,112,114,101,115,115,101,115,32,75,101
       dc.b      121,91,48,93,0
@lab5_23:
       dc.b      13,10,73,110,105,116,105,97,116,105,110,103
       dc.b      32,65,68,67,32,116,101,115,116,44,32,99,104
       dc.b      97,110,110,101,108,32,114,101,97,100,105,110
       dc.b      103,115,32,97,114,101,32,97,115,32,98,101,108
       dc.b      111,119,58,32,0
@lab5_24:
       dc.b      13,10,73,110,118,97,108,105,100,32,83,101,108
       dc.b      101,99,116,105,111,110,32,45,32,80,108,101,97
       dc.b      115,101,32,99,104,111,111,115,101,32,111,102
       dc.b      32,116,104,101,32,108,105,115,116,101,100,32
       dc.b      111,112,116,105,111,110,115,46,0
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
       xref      _putch
       xref      _getch
       xref      _printf
