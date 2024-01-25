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
//#define StartOfExceptionVectorTable 0x0B000000

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

void main(void)
{
    unsigned int test_option = 0;
    unsigned int bit_num = 0;
    unsigned int test_pattern = 0;
    unsigned int select_pattern = 0;
    unsigned int write_data = 0;
    unsigned int start_addr = 0;
    unsigned int end_addr = 0;
    unsigned int *addr_point = NULL;
    unsigned int counter = 2000;


    //prompting user for test option BYTES, WORDS, or LONG WORDS
    while(!test_option){

        printf("\r\nPlease enter a number to choose one of the following test options:"
        "\r\n1 - Bytes"
        "\r\n2 - Words"
        "\r\n3 - Long Words\r\n");

        scanf("%d", &test_option);

        if((test_option != 1 && test_option != 2 && test_option != 3) || test_option == 0){
            printf("\r\nInvalid Selection\r\n");
            test_option = 0;
        }
    }

    //assigning bit_num based on test_option
    switch(test_option){
        case 1:
            printf("\r\nYou have selected test option BYTES\r\n");
            bit_num = 8;
            break;

        case 2:
            printf("\r\nYou have selected test option WORDS\r\n");
            bit_num = 16;
            break;

        case 3:
            printf("\r\nYou have selected test option LONG WORDS\r\n");
            bit_num = 32;
            break;

        default:
            printf("\r\nException - invalid test option\r\n");
            break;
    }

    //prompting user to enter test pattern
    while(!select_pattern){

        printf("\r\nPlease enter a number to choose one of the following test patterns:"
        "\r\n1 - 55"
        "\r\n2 - AA"
        "\r\n3 - FF"
        "\r\n4 - 00\r\n");

        scanf("%d", &select_pattern);

        if((select_pattern != 1 && select_pattern != 2 && select_pattern != 3 && select_pattern != 4) || select_pattern == 0){
            printf("\r\nInvalid Selection\r\n");
            select_pattern = 0;
        }
    }

    //assigning write_data based on test_pattern
    switch(select_pattern){
        case 1:
            printf("\r\nYou have selected test pattern 55\r\n");
            test_pattern = 0x55;
            break;

        case 2:
            printf("\r\nYou have selected test pattern AA\r\n");
            test_pattern = 0xAA;
            break;

        case 3:
            printf("\r\nYou have selected test pattern FF\r\n");
            test_pattern = 0xFF;
            break;

        case 4:
            printf("\r\nYou have selected test pattern 00\r\n");
            test_pattern = 0x00;

        default:
            printf("\r\nException - invalid test pattern\r\n");
            break;
    }

    //create appropriate data set based on select_pattern and test_option
    // ie, if select_pattern is AA and test_option is BYTES, write_data must be AAAA
    switch(test_option){
        case 1:
            write_data = test_pattern;
            break;
        case 2:
            write_data = test_pattern | test_pattern << 8;
            break;
        case 3:
            write_data = test_pattern | test_pattern << 8 | test_pattern << 16 | test_pattern << 24;
            break;
        default:
            printf("\r\nException - could not generate write_data\r\n");
            break;
    }

    //prompting user to enter start address
    while(!start_addr){
        printf("\r\nPlease enter a starting address from 08020000 to 08030000\r\n");
        scanf("%d", &start_addr);

        if(start_addr<0x08020000 || start_addr>0x08030000){
            printf("\r\nStart address is invalid\r\n");
            start_addr = 0;
        } else if(bit_num>8 && start_addr % 2 != 0){
            printf("\r\nFor words or long words, please enter an even numbered address\r\n");
            end_addr = 0;
        } else{
            printf("\r\nThe chosen starting address is: %x", start_addr);
        }
    }

    //prompting user to enter end address
    while(!end_addr){
        printf("\r\nPlease enter an end address from %x to 08030000\r\n", start_addr);
        scanf("%d", &end_addr);

        if(end_addr<start_addr || end_addr>0x08030000){
            printf("\r\nEnd address is invalid\r\n");
            end_addr = 0;
        } else if(bit_num>8 && end_addr % 2 != 0){
            printf("\r\nFor words or long words, please enter an even numbered address\r\n");
            end_addr = 0;
        } else{
            printf("\r\nThe chosen ending address is: %x", end_addr);
        }
    }

    //set address pointer to start pointer
    addr_point = start_addr;

    //writing data
    while(addr_point<end_addr){
        *addr_point = write_data;
        counter++;
        if(counter >= 2000){
            printf("\r\nWriting %x into address %x\r\n", *addr_point, addr_point);
            counter = 1;
        }

        //need to increment address pointer according to test option chosen (bytes, words, long words)
        if(test_option == 1){
            addr_point = addr_point+1;
        } else if(test_option == 2){
            addr_point = addr_point+2;
        }else if(test_option == 3){
            addr_point = addr_point+4;
        }
    }
    printf("\r\nWriting completed. Will now start reading.\r\n");
    addr_point = start_addr;
    counter = 2000;

    //reading data
    while(addr_point<end_addr){
        if(*addr_point != write_data){
            printf("\r\nAn Error has occurred: data at address %x expected to be %x, instead is reading %x", addr_point, write_data, *addr_point);
            printf("\r\nMemory test failed.\r\n");
            break;
        }
        counter++;

        if(counter >= 2000){
            printf("\r\nReading data value %x from address %x\r\n", *addr_point, addr_point);
            counter = 1;
        }

        //need to increment address pointer according to test option chosen (bytes, words, long words)
        if(test_option == 1){
            addr_point = addr_point+1;
        } else if(test_option == 2){
            addr_point = addr_point+2;
        }else if(test_option == 3){
            addr_point = addr_point+4;
        }
    }

}