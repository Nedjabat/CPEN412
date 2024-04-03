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
**  I2C Controller Registers
*******************************************************************************/
//for Lab 5, address range from 0x00408000 - 0040800F has been chosen to avoid conflict
//with any other IO devices already in system

#define I2C_PRERlo      (*(volatile unsigned char *)(0x00408000))
#define I2C_PRERhi      (*(volatile unsigned char *)(0x00408002))
#define I2C_CTR         (*(volatile unsigned char *)(0x00408004))

//transmit and receive registers share same address
#define I2C_TXR         (*(volatile unsigned char *)(0x00408006))
#define I2C_RXR         (*(volatile unsigned char *)(0x00408006))

//command and status registers share same address
#define I2C_CR          (*(volatile unsigned char *)(0x00408008))
#define I2C_SR          (*(volatile unsigned char *)(0x00408008))

// I2C_CR[7] = STA, [4] = W, [0] = IACK --> 0x91 (hex)
#define WRITE_STA 0x91
// I2C_CR[6] = STO, [4] = W --> 0x50 (hex)
#define WRITE_STO 0x50
// I2C_CR[4] = W --> 0x10
#define WRITING 0x10

// EEPROM bank addresses
#define EEPROM_BANK_0 0xA0
#define EEPROM_BANK_1 0xA8

#define ADC_DAC_SLAVE 0x90

#define DAC_ENABLE 0x40
#define DAC_DISABLE 0x00
#define ADC_INCREMENT 0x04

// I2C[5] = read, [3] = ACK, [0] = IACK --> 00100001 = 0x21
#define READ_ACK 0x21
//set RD bit and ACK in command reg; [5] = RD, [3] = NACK, [0] = IACK
#define READ_NACK 0x29

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
//void Timer_ISR(void);

void I2C_Init(void);
void I2C_WaitTIP(void);
void I2C_WaitRxACK(void);
void I2C_Transmit(char data, char command);
void I2C_WriteByte(char data, char slaveAddr, char memoryAddrHigh, char memoryAddrLow);
void I2C_ReadByte(char *data, char slaveAddr, char memoryAddrHigh, char memoryAddrLow);
void DAC_test(void);
void ADC_test(void);
char select_bank(char *bank);
void select_mem_addr(char *mem_addr_high, char *mem_addr_low);

/*****************************************************************************************
**	Interrupt service routine for Timers
**
**  Timers 1 - 4 share a common IRQ on the CPU  so this function uses polling to figure
**  out which timer is producing the interrupt
**
*****************************************************************************************/
char xtod(int c)
{
    if ((char)(c) <= (char)('9'))
        return c - (char)(0x30);    // 0 - 9 = 0x30 - 0x39 so convert to number by sutracting 0x30
    else if((char)(c) > (char)('F'))    // assume lower case
        return c - (char)(0x57);    // a-f = 0x61-66 so needs to be converted to 0x0A - 0x0F so subtract 0x57
    else
        return c - (char)(0x37);    // A-F = 0x41-46 so needs to be converted to 0x0A - 0x0F so subtract 0x37
}

int Get2HexDigits(char *CheckSumPtr)
{
    register int i = (xtod(_getch()) << 4) | (xtod(_getch()));

    if(CheckSumPtr)
        *CheckSumPtr += i ;

    return i ;
}

void Timer_ISR(void)
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

void Wait500ms(void)
{
    int i ;
    for(i = 0; i < 500; i++)
        Wait1ms() ;
}

void WaitUserms(int ms)
{
    int i ;
    for(i = 0; i < ms; i++)
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
**  I2C Functions
*******************************************************************************/

void I2C_Init(void){
    // TODO: set for no interrupts, and clock frequency for 100kHz

    I2C_CTR = 0x00; //turn off core

    // setting clock frequency for 100kHz: prescale = ((25MHz)/(5*100kHz))-1 = 49 (dec) = 31 (hex)
    I2C_PRERlo = 0x31;
    I2C_PRERhi = 0x00;

    //turn on core and disable interrupts b1000_0000 = 0x80
    I2C_CTR = 0x80;
}

void I2C_WaitTIP(void){
    // check I2C_SR[1] and wait until previous transmits are finished
    //'1' when transferring data, '0' when transfer complete
    while((I2C_SR >> 1)&1){}
}

void I2C_WaitRxACK(void){
    // check I2C_SR[7] and wait for ACK after writing anything over I2C to slave
    // '1' when no ACK received, '0' when ACK received
    while((I2C_SR >> 7)&1){}
}

void I2C_Transmit(char data, char command){
    // this function just helps simplify transmission process
    I2C_TXR = data;
    I2C_CR = command;

    I2C_WaitTIP();
    I2C_WaitRxACK();
}

void I2C_WriteByte(char data, char slaveAddr, char memoryAddrHigh, char memoryAddrLow){
    // to write data, put transmit data into TX register
    // tell I2C_CR that we are in writing mode
    // if want to generate start or stop condition with each byte written, set STA or STO bits in command register when you write to it
    // similarly, clear ACK bit if you want to generate ACK when reading data back from slave

    I2C_WaitTIP(); //check that nothing is currently in transmission

    I2C_Transmit(slaveAddr, WRITE_STA);     //want to write to slave, start cmd
    I2C_Transmit(memoryAddrHigh, WRITING);  //write 2 bytes corresponding to 2 byte internal addr
    I2C_Transmit(memoryAddrLow, WRITING);
    I2C_Transmit(data, WRITE_STO);          //finishing write operation
}

void I2C_ReadByte(char *data, char slaveAddr, char memoryAddrHigh, char memoryAddrLow){
    I2C_WaitTIP(); //check that nothing is currently in transmission

    I2C_Transmit(slaveAddr, WRITE_STA);     //set write to slave, start cmd
    I2C_Transmit(memoryAddrHigh, WRITING);  //write 2 bytes corresponding to 2 byte internal addr
    I2C_Transmit(memoryAddrLow, WRITING);

    I2C_Transmit(slaveAddr|1, WRITE_STA);   //send repeated start condition
    I2C_CR = READ_NACK;
    while(!(I2C_SR & 1)){}                  //check status reg [0] = interrupt flag --> if '1', data has been received

    *data = I2C_RXR;                        //received data found in received register
    I2C_CR = 0x41;                          //finish operation and clear pending interrupt; [6] = STO, [0] = IACK
    I2C_CR = 0x50;
}

void DAC_test(){
    int count = 0;
    I2C_WaitTIP(); //check that nothing is currently in transmission
    //I2C_WaitRxACK();

    I2C_Transmit(0x90, WRITE_STA);
    I2C_Transmit(0x40, WRITING);

    while(1){
        for(count = 0; count < 255; count++){
            I2C_Transmit(count, WRITING);
            WaitUserms(15);
        }
    }
}

void ADC_test(void){
    char garbage, thermistor, potentiometer, photoresist;

    while(1){
        I2C_WaitTIP(); //check that nothing is currently in transmission

        I2C_Transmit(ADC_DAC_SLAVE, WRITE_STA);
        I2C_Transmit(ADC_INCREMENT, WRITING);

        I2C_Transmit(ADC_DAC_SLAVE | 1, WRITE_STA);

        I2C_CR = READ_ACK;
        while(!(I2C_SR & 1)){}                  //check status reg [0] = interrupt flag --> if '1', data has been received
        garbage = I2C_RXR;                    //AN0: External analog source

        I2C_CR = READ_ACK;
        while(!(I2C_SR & 1)){}                  //check status reg [0] = interrupt flag --> if '1', data has been received
        thermistor = I2C_RXR;                    //AN1: On board thermistor

        I2C_CR = READ_ACK;
        while(!(I2C_SR & 1)){}                  //check status reg [0] = interrupt flag --> if '1', data has been received
        potentiometer = I2C_RXR;                    //AN2: On board potentiometer

        I2C_CR = READ_ACK;
        while(!(I2C_SR & 1)){}                  //check status reg [0] = interrupt flag --> if '1', data has been received
        photoresist = I2C_RXR;                    //AN3: On board photoresistor

        I2C_CR = 0x41;                          //finish operation and clear pending interrupt; [6] = STO, [0] = IACK

        printf("\r\nAN1 - On board potentiometer: %d", potentiometer);
        printf("\r\nAN2 - On board thermistor: %d", thermistor);
        printf("\r\nAN3 - On board photoresist: %d", photoresist);
        printf("\r\n************************************");
        WaitUserms(1000);
    }
}

int select_bank(char *bank){
    unsigned char selection;
    int bank_select;
    while(1){
                printf("\r\nEnter digit 0 or 1 to select desired bank.");
                selection = getchar();
                putchar(selection);
                //bank_select = selection;
                if(selection == '0'){
                    *bank = EEPROM_BANK_0;
                    bank_select = 0;
                    break;
                }
                else if(selection == '1'){
                    *bank = EEPROM_BANK_1;
                    bank_select = 1;
                    break;
                }
                else {
                    printf("\r\nInvalid selection, please try again.");
                }
    }
    return bank_select;
}

void select_mem_addr(char *mem_addr_high, char *mem_addr_low){
    printf("\r\nPlease enter memory address high: ");
    *mem_addr_high = Get2HexDigits(0);
    printf("\r\nPlease enter memory address low: ");
    *mem_addr_low = Get2HexDigits(0);
}

/******************************************************************************************************************************
* Start of user program
******************************************************************************************************************************/

void main()
{
    unsigned int row, i=0, count=0, counter1=1;
    char c, text[150];

    // Variables used for Lab 5
    unsigned char selection, data_write, data_read, bank, mem_addr_high, mem_addr_low;
    int bank_select;
    //End of variables used for Lab 5

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
**  CPEN 412 Lab 5: I2C UserProgram
*************************************************************************************************/
    I2C_Init();

    printf("\r\nCPEN - 412 Lab 5");
    printf("\r\nAnna Yun #94902673 - Ryan Nedjabat #67501510");

    while(1){ //enter infinite loop
        printf("\r\nPlease enter the number corresponding to the desired test:");
        printf("\r\nWrite Byte  - 1");
        printf("\r\nRead Byte   - 2");
        printf("\r\nWrite Page  - 3");
        printf("\r\nRead Page   - 4");
        printf("\r\nDAC Test    - 5");
        printf("\r\nADC Test    - 6\r\n");

        selection = getchar();
        putchar(selection);

        //testing write byte
        if(selection == '1'){
            printf("\r\nEnter byte sized data to be written: ");
            data_write = Get2HexDigits(0);

            //need to select slave bank
            bank_select = select_bank(&bank);

            //need to select memory address
            select_mem_addr(&mem_addr_high, &mem_addr_low);

            I2C_WriteByte(data_write, bank, mem_addr_high, mem_addr_low);
            printf("\r\nWriting %x from EEPROM bank %d. Mem_addr_high = %x. Mem_addr_low = %x", data_write, bank_select, mem_addr_high, mem_addr_low);
        }

        //testing read byte
        else if(selection == '2'){
            //need to select slave bank
            bank_select = select_bank(&bank);

            //need to select memory address
            select_mem_addr(&mem_addr_high, &mem_addr_low);

            I2C_ReadByte(data_read, bank, mem_addr_high, mem_addr_low);
            printf("\r\nReading %x from EEPROM bank %d. Mem_addr_high = %x. Mem_addr_low = %x", data_write, bank_select, mem_addr_high, mem_addr_low);
        }

        //testing write page
        else if(selection == '3'){
            break;
        }

        //testing read page
        else if(selection == '4'){
            break;
        }

        //testing DAC (LED blinking)
        else if(selection == '5'){
            printf("\r\nInitiating DAC test, LED should gradually brighten, before abruptly turning off.");
            printf("\r\nThis sequence will repeat infinitely until user presses Key[0]");
            DAC_test();
        }

        //testing ADC (reading analog values)
        else if(selection == '6'){
            printf("\r\nInitiating ADC test, channel readings are as below: ");
            ADC_test();
        }

        //invalid/mistaken selection
        else{
            printf("\r\nInvalid Selection - Please choose of the listed options.");
        }
    }

   // programs should NOT exit as there is nothing to Exit TO !!!!!!
   // There is no OS - just press the reset button to end program and call debug
}