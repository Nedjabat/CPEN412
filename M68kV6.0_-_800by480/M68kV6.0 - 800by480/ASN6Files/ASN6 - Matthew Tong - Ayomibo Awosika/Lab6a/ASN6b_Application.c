/*
* EXAMPLE_1.C
*
* This is a minimal program to verify multitasking.
*
*/
#include <stdio.h>
#include "Bios.h"
#include "ucos_ii.h"
#include "Canbus-Controller.h"

#define STACKSIZE 256

/*
** Stacks for each task are allocated here in the application in this case = 256 bytes
** but you can change size if required
*/
OS_STK Task1Stk[STACKSIZE];
OS_STK Task2Stk[STACKSIZE];
OS_STK Task3Stk[STACKSIZE];
OS_STK Task4Stk[STACKSIZE];
OS_STK Task5Stk[STACKSIZE];
OS_STK Task6Stk[STACKSIZE];

/* Prototypes for our tasks/threads*/
void Task1(void *); /* (void *) means the child task expects no data from parent*/
void Task2(void *);
void Task3(void *);
void Task4(void *);
void Task5(void *);
void Task6(void *);

/*
** Our main application which has to
** 1) Initialise any peripherals on the board, e.g. RS232 for hyperterminal + LCD
** 2) Call OSInit() to initialise the OS
** 3) Create our application task/threads
** 4) Call OSStart()
*/
void main(void)
{
    // initialise board hardware by calling our routines from the BIOS.C source file
    Init_RS232();
    Init_LCD();
    /* display welcome message on LCD display */
    Oline0("Altera DE1/68K");
    Oline1("Micrium uC/OS-II RTOS");
    OSInit(); // call to initialise the OS
    /*
    ** Now create the 4 child tasks and pass them no data.
    ** the smaller the numerical priority value, the higher the task priority
    */
    OSTaskCreate(Task1, OS_NULL, &Task1Stk[STACKSIZE], 12);
    OSTaskCreate(Task2, OS_NULL, &Task2Stk[STACKSIZE], 11); // highest priority task
    OSTaskCreate(Task3, OS_NULL, &Task3Stk[STACKSIZE], 13);
    OSTaskCreate(Task4, OS_NULL, &Task4Stk[STACKSIZE], 14); 
    OSTaskCreate(Task5, OS_NULL, &Task5Stk[STACKSIZE], 15); 
    OSTaskCreate(Task6, OS_NULL, &Task6Stk[STACKSIZE], 16); // lowest priority task
    OSStart(); // call to start the OS scheduler, (never returns from this function)

}

/*
** IMPORTANT : Timer 1 interrupts must be started by the highest priority task
** that runs first which is Task2
*/
void Task1(void *pdata)
{
    unsigned char count = 0;

    // must start timer ticker here
    Timer1_Init() ; // this function is in BIOS.C and written by us to start timer
    for (;;) {
        //printf("RANDOM HEX DISPLAY\n");

        HEX_A = ((count << 4) + (count & 0x0f));
        count++;

        OSTimeDly(200);
    }
}

/*
** Task 2 below was created with the highest priority so it must start timer1
** so that it produces interrupts for the 100hz context switches
*/
void Task2(void *pdata)
{
    unsigned char count = 0;

    for (;;) {
        //printf("RANDOM LED DISPLAY\n");
        
        PortA = ((count << 4) + (count & 0x0f)); //LED0-7
        count++;

        OSTimeDly(100);
    }
}

void Task3(void *pdata)
{
    unsigned char count = 0;

    // must start timer ticker here
    Timer1_Init() ; // this function is in BIOS.C and written by us to start timer
    for (;;) {
        //printf("RANDOM HEX DISPLAY\n");

        HEX_B = ((count << 4) + (count & 0x0f));
        count++;

        OSTimeDly(50);
    }
}

void Task4(void *pdata)
{
    unsigned char count = 0;

    for (;;) {
        //printf("RANDOM LED DISPLAY\n");
        
        PortB = ((count << 4) + (count & 0x0f)); //LED8-9
        count++;

        OSTimeDly(25);
    }
}

void Task5(void *pdata)
{
    unsigned char count = 0;

    for (;;) {
        //printf("RANDOM HEX DISPLAY\n");
        
        HEX_C = ((count << 4) + (count & 0x0f)); //LED8-9
        count++;

        OSTimeDly(10);
    }
}

void Task6(void *pdata)
{
    unsigned char count = 0;

    for (;;) {
        //printf("RANDOM HEX DISPLAY\n");
    

        OSTimeDly(10);
    }
}