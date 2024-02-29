#include <stdio.h>
#include <string.h>
#include <ctype.h>


//IMPORTANT
//
// Uncomment one of the two #defines below
// Define StartOfExceptionVectorTable as 08030000 if running programs from sram or
// 0B000000 for running programs from dram
//
// In your labs, you will initially start by designing a system with SRam and later move to
// Dram, so these constants will need to be changed based on the version of the system you have
// building
//
// The working 68k system SOF file posted on canvas that you can use for your pre-lab
// is based around Dram so #define accordingly before building

//#define StartOfExceptionVectorTable 0x08030000
#define StartOfExceptionVectorTable 0x0B000000

/**********************************************************************************************
**	Parallel port addresses
**********************************************************************************************/

#define PortA   *(volatile unsigned char *)(0x00400000)
#define PortB   *(volatile unsigned char *)(0x00400002)
#define PortC   *(volatile unsigned char *)(0x00400004)
#define PortD   *(volatile unsigned char *)(0x00400006)
#define PortE   *(volatile unsigned char *)(0x00400008)

/*********************************************************************************************
**	Hex 7 seg displays port addresses
*********************************************************************************************/

#define HEX_A        *(volatile unsigned char *)(0x00400010)
#define HEX_B        *(volatile unsigned char *)(0x00400012)
#define HEX_C        *(volatile unsigned char *)(0x00400014)    // de2 only
#define HEX_D        *(volatile unsigned char *)(0x00400016)    // de2 only

/**********************************************************************************************
**	LCD display port addresses
**********************************************************************************************/

#define LCDcommand   *(volatile unsigned char *)(0x00400020)
#define LCDdata      *(volatile unsigned char *)(0x00400022)

/********************************************************************************************
**	Timer Port addresses
*********************************************************************************************/

#define Timer1Data      *(volatile unsigned char *)(0x00400030)
#define Timer1Control   *(volatile unsigned char *)(0x00400032)
#define Timer1Status    *(volatile unsigned char *)(0x00400032)

#define Timer2Data      *(volatile unsigned char *)(0x00400034)
#define Timer2Control   *(volatile unsigned char *)(0x00400036)
#define Timer2Status    *(volatile unsigned char *)(0x00400036)

#define Timer3Data      *(volatile unsigned char *)(0x00400038)
#define Timer3Control   *(volatile unsigned char *)(0x0040003A)
#define Timer3Status    *(volatile unsigned char *)(0x0040003A)

#define Timer4Data      *(volatile unsigned char *)(0x0040003C)
#define Timer4Control   *(volatile unsigned char *)(0x0040003E)
#define Timer4Status    *(volatile unsigned char *)(0x0040003E)

/*********************************************************************************************
**	RS232 port addresses
*********************************************************************************************/

#define RS232_Control     *(volatile unsigned char *)(0x00400040)
#define RS232_Status      *(volatile unsigned char *)(0x00400040)
#define RS232_TxData      *(volatile unsigned char *)(0x00400042)
#define RS232_RxData      *(volatile unsigned char *)(0x00400042)
#define RS232_Baud        *(volatile unsigned char *)(0x00400044)

/*********************************************************************************************
**	PIA 1 and 2 port addresses
*********************************************************************************************/

#define PIA1_PortA_Data     *(volatile unsigned char *)(0x00400050)         // combined data and data direction register share same address
#define PIA1_PortA_Control *(volatile unsigned char *)(0x00400052)
#define PIA1_PortB_Data     *(volatile unsigned char *)(0x00400054)         // combined data and data direction register share same address
#define PIA1_PortB_Control *(volatile unsigned char *)(0x00400056)

#define PIA2_PortA_Data     *(volatile unsigned char *)(0x00400060)         // combined data and data direction register share same address
#define PIA2_PortA_Control *(volatile unsigned char *)(0x00400062)
#define PIA2_PortB_data     *(volatile unsigned char *)(0x00400064)         // combined data and data direction register share same address
#define PIA2_PortB_Control *(volatile unsigned char *)(0x00400066)

/******************************************************************************
**  SPI Controller Registers
*******************************************************************************/
#define SPI_Control     (*(volatile unsigned char *)(0x00408020))
#define SPI_Status      (*(volatile unsigned char *)(0x00408022))
#define SPI_Data        (*(volatile unsigned char *)(0x00408024))
#define SPI_Ext         (*(volatile unsigned char *)(0x00408026)) 
#define SPI_CS          (*(volatile unsigned char *)(0x00408028))

/*********************************************************************************************************************************
(( DO NOT initialise global variables here, do it main even if you want 0
(( it's a limitation of the compiler
(( YOU HAVE BEEN WARNED
*********************************************************************************************************************************/

unsigned int i, x, y, z, PortA_Count;
unsigned char Timer1Count, Timer2Count, Timer3Count, Timer4Count ;

/*******************************************************************************************
** Function Prototypes
*******************************************************************************************/
void Wait1ms(void);
void Wait3ms(void);
void Init_LCD(void) ;
void LCDOutchar(int c);
void LCDOutMess(char *theMessage);
void LCDClearln(void);
void LCDline1Message(char *theMessage);
void LCDline2Message(char *theMessage);
int sprintf(char *out, const char *format, ...) ;


// SPI Function Prototypes
int TestForSPITransmitDataComplete(void);
void SPI_Init(void);
void WaitForSPITransmitComplete(void);
int WriteSPIChar(int c);

void WriteDataToSPI(char *MemAddress, int FlashAddress, int size);
void WaitForSPIWriteComplete();
void WriteCommandSPI(int cmd);
void ReadDataFromSPI(char *MemAddress, int FlashAddress, int size);
void EraseFlashChip(void);

/*****************************************************************************************
**	Interrupt service routine for Timers
**
**  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
**  out which timer is producing the interrupt
**
*****************************************************************************************/

void Timer_ISR()
{
   	if(Timer1Status == 1) {         // Did Timer 1 produce the Interrupt?
   	    Timer1Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
   	    PortA = Timer1Count++ ;     // increment an LED count on PortA with each tick of Timer 1
   	}

  	if(Timer2Status == 1) {         // Did Timer 2 produce the Interrupt?
   	    Timer2Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
   	    PortC = Timer2Count++ ;     // increment an LED count on PortC with each tick of Timer 2
   	}

   	if(Timer3Status == 1) {         // Did Timer 3 produce the Interrupt?
   	    Timer3Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        HEX_A = Timer3Count++ ;     // increment a HEX count on Port HEX_A with each tick of Timer 3
   	}

   	if(Timer4Status == 1) {         // Did Timer 4 produce the Interrupt?
   	    Timer4Control = 3;      	// reset the timer to clear the interrupt, enable interrupts and allow counter to run
        HEX_B = Timer4Count++ ;     // increment a HEX count on HEX_B with each tick of Timer 4
   	}
}

/*****************************************************************************************
**	Interrupt service routine for ACIA. This device has it's own dedicate IRQ level
**  Add your code here to poll Status register and clear interrupt
*****************************************************************************************/

void ACIA_ISR()
{}

/***************************************************************************************
**	Interrupt service routine for PIAs 1 and 2. These devices share an IRQ level
**  Add your code here to poll Status register and clear interrupt
*****************************************************************************************/

void PIA_ISR()
{}

/***********************************************************************************
**	Interrupt service routine for Key 2 on DE1 board. Add your own response here
************************************************************************************/
void Key2PressISR()
{}

/***********************************************************************************
**	Interrupt service routine for Key 1 on DE1 board. Add your own response here
************************************************************************************/
void Key1PressISR()
{}

/************************************************************************************
**   Delay Subroutine to give the 68000 something useless to do to waste 1 mSec
************************************************************************************/
void Wait1ms(void)
{
    int  i ;
    for(i = 0; i < 1000; i ++)
        ;
}

/************************************************************************************
**  Subroutine to give the 68000 something useless to do to waste 3 mSec
**************************************************************************************/
void Wait3ms(void)
{
    int i ;
    for(i = 0; i < 3; i++)
        Wait1ms() ;
}

/*********************************************************************************************
**  Subroutine to initialise the LCD display by writing some commands to the LCD internal registers
**  Sets it for parallel port and 2 line display mode (if I recall correctly)
*********************************************************************************************/
void Init_LCD(void)
{
    LCDcommand = 0x0c ;
    Wait3ms() ;
    LCDcommand = 0x38 ;
    Wait3ms() ;
}

/*********************************************************************************************
**  Subroutine to initialise the RS232 Port by writing some commands to the internal registers
*********************************************************************************************/
void Init_RS232(void)
{
    RS232_Control = 0x15 ; //  %00010101 set up 6850 uses divide by 16 clock, set RTS low, 8 bits no parity, 1 stop bit, transmitter interrupt disabled
    RS232_Baud = 0x1 ;      // program baud rate generator 001 = 115k, 010 = 57.6k, 011 = 38.4k, 100 = 19.2, all others = 9600
}

/*********************************************************************************************************
**  Subroutine to provide a low level output function to 6850 ACIA
**  This routine provides the basic functionality to output a single character to the serial Port
**  to allow the board to communicate with HyperTerminal Program
**
**  NOTE you do not call this function directly, instead you call the normal putchar() function
**  which in turn calls _putch() below). Other functions like puts(), printf() call putchar() so will
**  call _putch() also
*********************************************************************************************************/

int _putch( int c)
{
    while((RS232_Status & (char)(0x02)) != (char)(0x02))    // wait for Tx bit in status register or 6850 serial comms chip to be '1'
        ;

    RS232_TxData = (c & (char)(0x7f));                      // write to the data register to output the character (mask off bit 8 to keep it 7 bit ASCII)
    return c ;                                              // putchar() expects the character to be returned
}

/*********************************************************************************************************
**  Subroutine to provide a low level input function to 6850 ACIA
**  This routine provides the basic functionality to input a single character from the serial Port
**  to allow the board to communicate with HyperTerminal Program Keyboard (your PC)
**
**  NOTE you do not call this function directly, instead you call the normal getchar() function
**  which in turn calls _getch() below). Other functions like gets(), scanf() call getchar() so will
**  call _getch() also
*********************************************************************************************************/
int _getch( void )
{
    char c ;
    while((RS232_Status & (char)(0x01)) != (char)(0x01))    // wait for Rx bit in 6850 serial comms chip status register to be '1'
        ;

    return (RS232_RxData & (char)(0x7f));                   // read received character, mask off top bit and return as 7 bit ASCII character
}

/******************************************************************************
**  Subroutine to output a single character to the 2 row LCD display
**  It is assumed the character is an ASCII code and it will be displayed at the
**  current cursor position
*******************************************************************************/
void LCDOutchar(int c)
{
    LCDdata = (char)(c);
    Wait1ms() ;
}

/**********************************************************************************
*subroutine to output a message at the current cursor position of the LCD display
************************************************************************************/
void LCDOutMessage(char *theMessage)
{
    char c ;
    while((c = *theMessage++) != 0)     // output characters from the string until NULL
        LCDOutchar(c) ;
}

/******************************************************************************
*subroutine to clear the line by issuing 24 space characters
*******************************************************************************/
void LCDClearln(void)
{
    int i ;
    for(i = 0; i < 24; i ++)
        LCDOutchar(' ') ;       // write a space char to the LCD display
}

/******************************************************************************
**  Subroutine to move the LCD cursor to the start of line 1 and clear that line
*******************************************************************************/
void LCDLine1Message(char *theMessage)
{
    LCDcommand = 0x80 ;
    Wait3ms();
    LCDClearln() ;
    LCDcommand = 0x80 ;
    Wait3ms() ;
    LCDOutMessage(theMessage) ;
}

/******************************************************************************
**  Subroutine to move the LCD cursor to the start of line 2 and clear that line
*******************************************************************************/
void LCDLine2Message(char *theMessage)
{
    LCDcommand = 0xC0 ;
    Wait3ms();
    LCDClearln() ;
    LCDcommand = 0xC0 ;
    Wait3ms() ;
    LCDOutMessage(theMessage) ;
}

/*********************************************************************************************************************************
**  IMPORTANT FUNCTION
**  This function install an exception handler so you can capture and deal with any 68000 exception in your program
**  You pass it the name of a function in your code that will get called in response to the exception (as the 1st parameter)
**  and in the 2nd parameter, you pass it the exception number that you want to take over (see 68000 exceptions for details)
**  Calling this function allows you to deal with Interrupts for example
***********************************************************************************************************************************/

void InstallExceptionHandler( void (*function_ptr)(), int level)
{
    volatile long int *RamVectorAddress = (volatile long int *)(StartOfExceptionVectorTable) ;   // pointer to the Ram based interrupt vector table created in Cstart in debug monitor

    RamVectorAddress[level] = (long int *)(function_ptr);                       // install the address of our function into the exception table
}

/******************************************************************************
**  SPI Functions
*******************************************************************************/
// return true if the SPI has finished transmitting a byte (to say the Flash chip) return false otherwise
// this can be used in a polling algorithm to know when the controller is busy or idle.
int TestForSPITransmitDataComplete(void)    {

    /* DONE: TODO replace 0 below with a test for status register SPIF bit and if set, return true */
    // SPIF bit is 7th bit --> shift by 7
    // 1000_0000 -> 0x80
    if((SPI_Status & 0x80) >> 7)
        return true;
    else return false;
}

void SPI_Init(void)
{
    //DONE: TODO
    //
    // Program the SPI Control, EXT, CS and Status registers to initialise the SPI controller
    // Don't forget to call this routine from main() before you do anything else with SPI
    //
    // Here are some settings we want to create
    //
    // Control Reg     - interrupts disabled, core enabled, Master mode, Polarity and Phase of clock = [0,0], speed =  divide by 32 = approx 700Khz
    // Ext Reg         - in conjunction with control reg, sets speed above and also sets interrupt flag after every completed transfer (each byte)
    // SPI_CS Reg      - control selection of slave SPI chips via their CS# signals
    // Status Reg      - status of SPI controller chip and used to clear any write collision and interrupt on transmit complete flag

    // SPCR = {SPIE, SPE, x, MSTR, CPOL, CPHA, SPR} = 01x1_0011 = 0x53
    SPI_Control = 0x53;

    // SPER = {ICNT, x, x, x, x, ESPR} = 00xx_xx00 = 0x00
    SPI_Ext = 0x00;

    Disable_SPI_CS();

    // SPSR = {SPIF, WCOL, x, x, x, x, x} = 11xx_xxxx = 0xC0
    // Use bitwise OR because we dont want to overrite data in other bits, only ensure that SPIF and WCOL are 1
    SPI_Status |= 0xC0;
}

void WaitForSPITransmitComplete(void)
{
    // DONE: TODO : poll the status register SPIF bit looking for completion of transmission
    // once transmission is complete, clear the write collision and interrupt on transmit complete flags in the status register (read documentation)
    // just in case they were set

    // need to keep checking until data fully transmitted
    while(TestForSPITransmitDataComplete() == false) {}
    SPI_Status |= 0xC0;
}

int WriteSPIChar(int c)
{
    // DONE: TODO 
    // STEP 1 - Write the byte in parameter 'c' to the SPI data register, this will start it transmitting to the flash device
    // STEP 2 - wait for completion of transmission
    // STEP 3 - Return the received data from Flash chip (which may not be relevent depending upon what we are doing)
    //          by reading fom the SPI controller Data Register.
    // note however that in order to get data from an SPI slave device (e.g. flash) chip we have to write a dummy byte to it
    //
    // modify '0' below to return back read byte from data register
    
    // Dummy byte
    int received_data = 0;
    
    // STEP 1
    SPI_Data = c;
    
    // STEP 2
    WaitForSPITransmitComplete();
    received_data = SPI_Data;

    // STEP 3
    return received_data;                   
}

// User defined SPI Commands - (1) Includes Writing Data to SPI, (2) Waiting for write,
// (3) Writing commands to SPI, (4) Reading from SPI, and (5) erasing flash chip

// (1) Writing to SPI
void WriteDataToSPI(char *MemAddress, int FlashAddress, int size)
{
    int i = 0;

    // to enable writing, send command 0x06 to flash chip
    WriteCommandSPI(0x06);

    // still manually enabling/disabling CS for more complicated transmissions
    // since we dont want the actual internal memory cell writes yet
    Enable_SPI_CS();
    // getting chip to write data, Page Program to chip by sending command 0x02
    WriteSPIChar(0x02);
    // sending 3 bytes that make up the 24 bit internal flash address
    // gotta break it up into 3
    WriteSPIChar(FlashAddress >> 16);
    WriteSPIChar(FlashAddress >> 8);
    WriteSPIChar(FlashAddress);

    // can now send up to 256 bytes of data by writing one byte at a time to 
    // SPI controller data register
    for(i=0; i<size; i++)
    {
        WriteSPIChar(MemAddress[i]);
    }

    // once CS is high again, chip performs actual internal memory cell writes
    Disable_SPI_CS();
    WaitForSPIWriteComplete();
}

// (2) Waiting for write to complete
void WaitForSPIWriteComplete()
{
    Enable_SPI_CS();
    // status register (SPSR) reset value: 0x05
    WriteSPIChar(0x05);
    // WriteSPIChar will return received data, if bit 0 (RFEMPTY) is high,
    // FIFO is empty and write is complete
    while(WriteSPIChar(0x00)&0x01);
    Disable_SPI_CS();
}

// (3) Writing commands to SPI
void WriteCommandSPI(int cmd)
{
    // need to enable flash chip before speaking to it
    // this is done by setting CS# low by writing to SPI controller CS register
    // need to disable this when we are finished each interaction
    Enable_SPI_CS();
    WriteSPIChar(cmd);
    Disable_SPI_CS();
}

// (4) Reading from SPI
void ReadDataFromSPI(char *MemAddress, int FlashAddress, int size)
{
    int i =0;

    // still manually enabling/disabling CS for more complicated transmissions
    Enable_SPI_CS();
    // issuing single read command 0x03
    WriteSPIChar(0x03);
    // followed by 24 bit internal start address broken into 3 bytes
    WriteSPIChar(FlashAddress >> 16);
    WriteSPIChar(FlashAddress >> 8);
    WriteSPIChar(FlashAddress);

    for(i=0; i<size; i++)
    {
        // can write dummy bytes to device 
        // any data is fine, they are ignored by mem chip since we are in READ mode
        // teach write will return data stored in successive incremental locations
        MemAddress[i] = (unsigned char) WriteSPIChar(0x00);
    }

    Disable_SPI_CS();
}

// (5) Erasing Flash Chip
void EraseFlashChip(void)
{
    // enabling device for writing
    WriteCommandSPI(0x06);
    // either writing hex C7 or 60 erases the chip
    WriteCommandSPI(0xC7);
    // Wait for write to complete

}

/******************************************************************************************************************************
* Start of user program
******************************************************************************************************************************/

void main()
{
    unsigned int row, i=0, count=0, counter1=1;
    char c, text[150] ;

	int PassFailFlag = 1 ;

    i = x = y = z = PortA_Count =0;
    Timer1Count = Timer2Count = Timer3Count = Timer4Count = 0;

    InstallExceptionHandler(PIA_ISR, 25) ;          // install interrupt handler for PIAs 1 and 2 on level 1 IRQ
    InstallExceptionHandler(ACIA_ISR, 26) ;		    // install interrupt handler for ACIA on level 2 IRQ
    InstallExceptionHandler(Timer_ISR, 27) ;		// install interrupt handler for Timers 1-4 on level 3 IRQ
    InstallExceptionHandler(Key2PressISR, 28) ;	    // install interrupt handler for Key Press 2 on DE1 board for level 4 IRQ
    InstallExceptionHandler(Key1PressISR, 29) ;	    // install interrupt handler for Key Press 1 on DE1 board for level 5 IRQ

    Timer1Data = 0x10;		// program time delay into timers 1-4
    Timer2Data = 0x20;
    Timer3Data = 0x15;
    Timer4Data = 0x25;

    Timer1Control = 3;		// write 3 to control register to Bit0 = 1 (enable interrupt from timers) 1 - 4 and allow them to count Bit 1 = 1
    Timer2Control = 3;
    Timer3Control = 3;
    Timer4Control = 3;

    Init_LCD();             // initialise the LCD display to use a parallel data interface and 2 lines of display
    Init_RS232() ;          // initialise the RS232 port for use with hyper terminal

/*************************************************************************************************
**  Test of scanf function
*************************************************************************************************/

    scanflush() ;                       // flush any text that may have been typed ahead
    /**printf("\r\nEnter Integer: ") ;
    scanf("%d", &i) ;
    printf("You entered %d", i) ;

    sprintf(text, "Hello CPEN 412 Student") ;
    LCDLine1Message(text) ;

    printf("\r\nHello CPEN 412 Student\r\nYour LEDs should be Flashing") ;
    printf("\r\nYour LCD should be displaying") ;

    while(1)
        ;
    **/

/*************************************************************************************************
**  CPEN 412 Lab 3: SPI UserProgram
*************************************************************************************************/
    SPI_Init();

    

   // programs should NOT exit as there is nothing to Exit TO !!!!!!
   // There is no OS - just press the reset button to end program and call debug
}