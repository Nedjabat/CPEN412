#include <stdio.h>
#include "Canbus-Controller.h"
#include "DebugMonitor.h"

#define TEMP 0
#define POTENTIAL 1
#define LIGHT 2
#define SWITCHES 3

/*********************************************************************************************
** These addresses and definitions were taken from Appendix 7 of the Can Controller
** application note and adapted for the 68k assignment
*********************************************************************************************/

/*
** definition for the SJA1000 registers and bits based on 68k address map areas
** assume the addresses for the 2 can controllers given in the assignment
**
** Registers are defined in terms of the following Macro for each Can controller,
** where (i) represents an registers number
*/


/*  bus timing values for
**  bit-rate : 100 kBit/s
**  oscillator frequency : 25 MHz, 1 sample per bit, 0 tolerance %
**  maximum tolerated propagation delay : 4450 ns
**  minimum requested propagation delay : 500 ns
**
**  https://www.kvaser.com/support/calculators/bit-timing-calculator/
**  T1 	T2 	BTQ 	SP% 	SJW 	BIT RATE 	ERR% 	BTR0 	BTR1
**  17	8	25	    68	     1	      100	    0	      04	7f
*/


// initialisation for Can controller 0
void Init_CanBus_Controller0(void)
{
    // TODO - put your Canbus initialisation code for CanController 0 here
    // See section 4.2.1 in the application note for details (PELICAN MODE)

    /* set reset mode/request (Note: after power-on SJA1000 is in BasicCAN mode)
    leave loop after a time out and signal an error */
    while((Can0_ModeControlReg & RM_RR_Bit ) == ClrByte)
    {
        /* other bits than the reset mode/request bit are unchanged */
        Can0_ModeControlReg = Can0_ModeControlReg | RM_RR_Bit ;
    }
    /* set the Clock Divider Register according to the given hardware of Figure 3
    select PeliCAN mode
    bypass CAN input comparator as external transceiver is used
    select the clock for the controller S87C654 */
    Can0_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy2;

    /* disable CAN interrupts, if required (always necessary after power-on)
    (write to SJA1000 Interrupt Enable / Control Register) */
    Can0_InterruptEnReg = ClrIntEnSJA;
    /* define acceptance code and mask */
    Can0_AcceptCode0Reg = ClrByte;
    Can0_AcceptCode1Reg = ClrByte;
    Can0_AcceptCode2Reg = ClrByte;
    Can0_AcceptCode3Reg = ClrByte;
    Can0_AcceptMask0Reg = DontCare; /* every identifier is accepted */
    Can0_AcceptMask1Reg = DontCare; /* every identifier is accepted */
    Can0_AcceptMask2Reg = DontCare; /* every identifier is accepted */
    Can0_AcceptMask3Reg = DontCare; /* every identifier is accepted */
    /* configure bus timing */
    /* bit-rate = 1 Mbit/s @ 24 MHz, the bus is sampled once */
    Can0_BusTiming0Reg = 0x04;
    Can0_BusTiming1Reg = 0x7F;
    /* configure CAN outputs: float on TX1, Push/Pull on TX0,
    normal output mode */
    Can0_OutControlReg = Tx1Float | Tx0PshPull | NormalMode;
    /* leave the reset mode/request i.e. switch to operating mode,
    the interrupts of the S87C654 are enabled
    but not the CAN interrupts of the SJA1000, which can be done separately
    for the different tasks in a system */
    /* clear Reset Mode bit, select dual Acceptance Filter Mode,
    switch off Self Test Mode and Listen Only Mode,
    clear Sleep Mode (wake up) */
    /* wait until RM_RR_Bit is cleared */
    /* break loop after a time out and signal an error */
    do{
        Can0_ModeControlReg = ClrByte;
    } while((Can0_ModeControlReg & RM_RR_Bit ) != ClrByte);
    /*----- end of Initialization Example of the SJA1000 ------------------------*/
}

// initialisation for Can controller 1
void Init_CanBus_Controller1(void)
{
    // TODO - put your Canbus initialisation code for CanController 1 here
    // See section 4.2.1 in the application note for details (PELICAN MODE)

    /* set reset mode/request (Note: after power-on SJA1000 is in BasicCAN mode)
    leave loop after a time out and signal an error */
    while((Can1_ModeControlReg & RM_RR_Bit ) == ClrByte)
    {
        /* other bits than the reset mode/request bit are unchanged */
        Can1_ModeControlReg = Can1_ModeControlReg | RM_RR_Bit ;
    }
    /* set the Clock Divider Register according to the given hardware of Figure 3
    select PeliCAN mode
    bypass CAN input comparator as external transceiver is used
    select the clock for the controller S87C654 */
    Can1_ClockDivideReg = CANMode_Bit | CBP_Bit | DivBy2;

    /* disable CAN interrupts, if required (always necessary after power-on)
    (write to SJA1000 Interrupt Enable / Control Register) */
    Can1_InterruptEnReg = ClrIntEnSJA;
    /* define acceptance code and mask */
    Can1_AcceptCode0Reg = ClrByte;
    Can1_AcceptCode1Reg = ClrByte;
    Can1_AcceptCode2Reg = ClrByte;
    Can1_AcceptCode3Reg = ClrByte;
    Can1_AcceptMask0Reg = DontCare; /* every identifier is accepted */
    Can1_AcceptMask1Reg = DontCare; /* every identifier is accepted */
    Can1_AcceptMask2Reg = DontCare; /* every identifier is accepted */
    Can1_AcceptMask3Reg = DontCare; /* every identifier is accepted */
    /* configure bus timing */
    /* bit-rate = 1 Mbit/s @ 24 MHz, the bus is sampled once */
    Can1_BusTiming0Reg = 0x04;
    Can1_BusTiming1Reg = 0x7F;
    /* configure CAN outputs: float on TX1, Push/Pull on TX0,
    normal output mode */
    Can1_OutControlReg = Tx1Float | Tx0PshPull | NormalMode;
    /* leave the reset mode/request i.e. switch to operating mode,
    the interrupts of the S87C654 are enabled
    but not the CAN interrupts of the SJA1000, which can be done separately
    for the different tasks in a system */
    /* clear Reset Mode bit, select dual Acceptance Filter Mode,
    switch off Self Test Mode and Listen Only Mode,
    clear Sleep Mode (wake up) */
    /* wait until RM_RR_Bit is cleared */
    /* break loop after a time out and signal an error */
    do{
        Can1_ModeControlReg = ClrByte;
    } while((Can1_ModeControlReg & RM_RR_Bit ) != ClrByte);
    /*----- end of Initialization Example of the SJA1000 ------------------------*/
}

// Transmit for sending a message via Can controller 0
void CanBus0_Transmit(unsigned char data)
{
    // TODO - put your Canbus transmit code for CanController 0 here
    // See section 4.2.2 in the application note for details (PELICAN MODE)

    /* wait until the Transmit Buffer is released */
    do{
    /* start a polling timer and run some tasks while waiting
    break the loop and signal an error if time too long */
    } while((Can0_StatusReg & TBS_Bit ) != TBS_Bit );
    /* Transmit Buffer is released, a message may be written into the buffer */
    /* in this example a Standard Frame message shall be transmitted */
    Can0_TxFrameInfo = 0x08; /* SFF (data), DLC=8 */
    Can0_TxBuffer1 = data; /*Data that will be sent*/
    
    /* Start the transmission */
    Can0_CommandReg = TR_Bit ; /* Set Transmission Request bit */
}

// Transmit for sending a message via Can controller 1
void CanBus1_Transmit(unsigned char data)
{
    // TODO - put your Canbus transmit code for CanController 1 here
    // See section 4.2.2 in the application note for details (PELICAN MODE)

    /* wait until the Transmit Buffer is released */
    do{
    /* start a polling timer and run some tasks while waiting
    break the loop and signal an error if time too long */
    } while((Can1_StatusReg & TBS_Bit ) != TBS_Bit );
    /* Transmit Buffer is released, a message may be written into the buffer */
    /* in this example a Standard Frame message shall be transmitted */
    Can1_TxFrameInfo = 0x08; /* SFF (data), DLC=8 */
    Can1_TxBuffer1 = data; /*Data that will be sent*/
    
    /* Start the transmission */
    Can1_CommandReg = TR_Bit ; /* Set Transmission Request bit */
}

// Receive for reading a received message via Can controller 0
void CanBus0_Receive(int type)
{
    unsigned char data;
    unsigned char c = 0xFF;

    unsigned int i = 0;

    // TODO - put your Canbus receive code for CanController 0 here
    // See section 4.2.4 in the application note for details (PELICAN MODE)
    //Bottom of page 35

    /* enable the receive interrupt */
    //Can0_InterruptEnReg = RIE_Bit; ////

    /* wait until the Receiver Buffer is released */
    do{
        /* start a polling timer and run some tasks while waiting
        break the loop and signal an error if time too long */
    } while((Can0_StatusReg & RBS_Bit) != RBS_Bit );

    /* read the Interrupt Register content from SJA1000 and save temporarily
    all interrupt flags are cleared (in PeliCAN mode the Receive
    Interrupt (RI) is cleared first, when giving the Release Buffer command)
    */
    
    /* get the content of the Receive Buffer from SJA1000 and store the
    message into internal memory of the controller,
    it is possible at once to decode the FrameInfo and Data Length Code
    and adapt the fetch appropriately */
    data = Can0_RxBuffer1;
    if(type == TEMP){
        printf("Value of Thermistor (CAN0): %d\n", data);
    }else if(type == POTENTIAL){
        printf("Value of Potentiometer (CAN0): %d\n", data);
    }else if(type == LIGHT){
        printf("Value of Photo-resister (CAN0): %d\n", data);
    }else if(type == SWITCHES){
        printf("Value of SW[7-0] (CAN0): ");
        for (i = (int)(0x00000080); i > 0; i = i >> 1) {
            if ((data & i) == 0)
                printf("0");
            else
                printf("1");
        }
        printf("\n");
    }else{
        printf("ERROR");
    }
    
    /* release the Receive Buffer, now the Receive Interrupt flag is cleared,
    further messages will generate a new interrupt */
    Can0_CommandReg = RRB_Bit; /* Release Receive Buffer */
}

// Receive for reading a received message via Can controller 1
void CanBus1_Receive(int type)
{
    unsigned char data;
    unsigned char c = 0xFF;
    unsigned int i = 0;        

    // TODO - put your Canbus receive code for CanController 1 here
    // See section 4.2.4 in the application note for details (PELICAN MODE)
    //Bottom of page 35

    // TODO - put your Canbus receive code for CanController 0 here
    // See section 4.2.4 in the application note for details (PELICAN MODE)

    /* enable the receive interrupt */
    //Can1_InterruptEnReg = RIE_Bit;

    /* wait until the Receiver Buffer is released */
    do{
        /* start a polling timer and run some tasks while waiting
        break the loop and signal an error if time too long */
    } while((Can1_StatusReg & RBS_Bit) != RBS_Bit );

    /* read the Interrupt Register content from SJA1000 and save temporarily
    all interrupt flags are cleared (in PeliCAN mode the Receive
    Interrupt (RI) is cleared first, when giving the Release Buffer command)
    */
    
    /* get the content of the Receive Buffer from SJA1000 and store the
    message into internal memory of the controller,
    it is possible at once to decode the FrameInfo and Data Length Code
    and adapt the fetch appropriately */

    data = Can1_RxBuffer1;
    if(type == TEMP){
        printf("Value of Thermistor (CAN1): %d\n", data);
    }else if(type == POTENTIAL){
        printf("Value of Potentiometer (CAN1): %d\n", data);
    }else if(type == LIGHT){
        printf("Value of Photo-resister (CAN1): %d\n", data);
    }else if(type == SWITCHES){
        printf("Value of SW[7-0] (CAN1): ");
        for (i = (int)(0x00000080); i > 0; i = i >> 1) {
            if ((data & i) == 0)
                printf("0");
            else
                printf("1");
        }
        printf("\n");
    }else{
        printf("ERROR");
    }

    /* release the Receive Buffer, now the Receive Interrupt flag is cleared,
    further messages will generate a new interrupt */
    Can1_CommandReg = RRB_Bit; /* Release Receive Buffer */
}


void CanBusTest(void)
{
    unsigned char data = 0xFF;
    // initialise the two Can controllers
    Init_CanBus_Controller0();
    Init_CanBus_Controller1();
    
    printf("\r\n\r\n---- CANBUS Test ----\r\n") ;

    // simple application to alternately transmit and receive messages from each of two nodes

    while(1)    {
        WaitHalfSecond();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly

        CanBus0_Transmit(data) ;       // transmit a message via Controller 0
        CanBus1_Receive(TEMP) ;        // receive a message via Controller 1 (and display it)

        printf("\r\n") ;

        WaitHalfSecond();                    // write a routine to delay say 1/2 second so we don't flood the network with messages to0 quickly

        CanBus1_Transmit(data) ;        // transmit a message via Controller 1
        CanBus0_Receive(TEMP) ;         // receive a message via Controller 0 (and display it)
        
        printf("\r\n") ;

    }
}

/************************************************************************************
*Subroutine to give the 68000 something useless to do to waste 1 x 500 mSec = 500mSec = 0.5sec therefore 500000
************************************************************************************/
void WaitHalfSecond(void)
{
    long int  i;
    for (i = 0; i < 500000; i++)
        ;
}


/************************************************************************************
** Subfunctions for I2C
************************************************************************************/

void Enable_SCL_Clock(void){

    I2C_Clock_PrerLo = 0x31;
    I2C_Clock_PrerHi = 0x00;

    return;
}

void WaitForI2C_TIP(void){
    int TIP_bit;

    do{
        TIP_bit = (I2C_Status >> 1) & 0x01; 
    }while(TIP_bit != 0);

    return;
}

void WaitForI2C_RxACK(void){
    int RxACK_bit;

    do{
        RxACK_bit = (I2C_Status >> 7) & 0x01;
    }while(RxACK_bit != 0);

    return;
}

/************************************************************************************
** initialises the I2C controller 
************************************************************************************/
void I2C_Init(void){

    //Enabling 100Khz SCL Clock Line
    Enable_SCL_Clock();

    //Enabling I2C for no interupts and enabling core
    Enable_I2C_CS();

    return;
}

/************************************************************************************
** ADC Write Function to measure Thermistor, Potentimeter, Photo-resistor
************************************************************************************/

unsigned char ADCWrite(int type){
    int i;
    unsigned char c;
    unsigned char* data[3];
    unsigned char temp, light, potential;
    unsigned int delay = 0xFFFFF;

        //Wait for TIP bit in Status Register 
        WaitForI2C_TIP();
        //Send data to Transmit register
        I2C_Transmit = ADC_DAC_WRITE_ADDRESS;
        //Set Command register
        I2C_Command = I2C_Slave_Write_Start_Command;
        //Wait for TIP bit in Status Register 
        WaitForI2C_TIP();
        //Wait RxACK bit in Status Register 
        WaitForI2C_RxACK();

        //Send data to Transmit register
        I2C_Transmit = ADC_ENABLE_COMMAND;
        //Set Command register
        I2C_Command = I2C_Slave_Write_Command;
        //Wait for TIP bit in Status Register 
        WaitForI2C_TIP();
        //Wait RxACK bit in Status Register 
        WaitForI2C_RxACK();

        //Send data to Transmit register
        I2C_Transmit = ADC_READ_ADDRESS;
        //Set Command register
        I2C_Command = I2C_Slave_Write_Start_Command;
        //Wait for TIP bit in Status Register 
        WaitForI2C_TIP();
        //Wait RxACK bit in Status Register 
        WaitForI2C_RxACK();

        //Set Command register to skip
        I2C_Command = I2C_Slave_Read_Command;
        //Wait for TIP bit in Status Register 
        WaitForI2C_TIP();

        //Set Command register to skip
        I2C_Command = I2C_Slave_Read_Command;
        //Wait for TIP bit in Status Register 
        WaitForI2C_TIP();

        //Grabbing read data from Receive Register for Thermistor
        c = I2C_Receive;
        temp = c;

        //Set Command register to skip
        I2C_Command = I2C_Slave_Read_Command;
        //Wait for TIP bit in Status Register 
        WaitForI2C_TIP();

        //Grabbing read data from Receive Register for Potentiometer
        c = I2C_Receive;
        potential = c;

        //Set Command register to skip
        I2C_Command = I2C_Slave_Read_Command;
        //Wait for TIP bit in Status Register 
        WaitForI2C_TIP();

        //Grabbing read data from Receive Register for Photo-resister
        c = I2C_Receive;
        light = c;

        c = 0xFF; //Give garabage value after in case

        if(type == TEMP){
            return temp;
        }else if(type == POTENTIAL){
            return potential;
        }else if(type == LIGHT){
            return light;
        }else{
            return c;
        }
}

