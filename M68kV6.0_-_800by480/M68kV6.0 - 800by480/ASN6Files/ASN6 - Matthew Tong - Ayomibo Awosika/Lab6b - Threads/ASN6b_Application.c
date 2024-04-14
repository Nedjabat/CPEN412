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

/*******************************************************************************************
** ADC Types
*******************************************************************************************/

#define TEMP        0
#define POTENTIAL   1
#define LIGHT       2
#define SWITCHES    3

/*******************************************************************************************
** Task Priority for Mutex
Ref: https://www.intel.com/content/www/us/en/support/programmable/support-resources/design-examples/horizontal/exm-micro-mutex.html?fbclid=IwAR2KdOFtTFDJYERh3MYIPLRbH80BVaIo9fdZTChviTEgzZ-bAJwRikO9maE
*******************************************************************************************/

#define MUTEX_PRIORITY 5

/*
** Stacks for each task are allocated here in the application in this case = 256 bytes
** but you can change size if required
*/
OS_STK Task1Stk[STACKSIZE];
OS_STK Task2Stk[STACKSIZE];
OS_STK Task3Stk[STACKSIZE];
OS_STK Task4Stk[STACKSIZE];
OS_STK Task5Stk[STACKSIZE];

/* Declaration of the mutex*/
OS_EVENT  *mutex;

/* Prototypes for our tasks/threads*/
void Task1(void *); /* (void *) means the child task expects no data from parent*/
void Task2(void *);
void Task3(void *);
void Task4(void *);
void Task5(void *);

/*******************************************************************************************
** Global Variables
*******************************************************************************************/
unsigned char temp, potential, light;
int switches;

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
    // initialise CanBus controllers
    Init_CanBus_Controller0();
    Init_CanBus_Controller1();
    /* display welcome message on LCD display */
    Oline0("Altera DE1/68K");
    Oline1("Micrium uC/OS-II RTOS");
    OSInit(); // call to initialise the OS
    //initialise mutex
    initOSDataStructs();
    /*
    ** Now create the 4 child tasks and pass them no data.
    ** the smaller the numerical priority value, the higher the task priority
    */
    OSTaskCreate(Task1, OS_NULL, &Task1Stk[STACKSIZE], 11); // highest priority task
    OSTaskCreate(Task2, OS_NULL, &Task2Stk[STACKSIZE], 12); 
    OSTaskCreate(Task3, OS_NULL, &Task3Stk[STACKSIZE], 13);
    OSTaskCreate(Task4, OS_NULL, &Task4Stk[STACKSIZE], 14); 
    OSTaskCreate(Task5, OS_NULL, &Task5Stk[STACKSIZE], 15); // lowest priority task
    OSStart(); // call to start the OS scheduler, (never returns from this function)

}

/*
** IMPORTANT : Timer 1 interrupts must be started by the highest priority task
** that runs first which is Task2
*/
void Task1(void *pdata)
{
    INT8U  return_code = OS_ERR_NONE;
    
    // must start timer ticker here
    Timer1_Init() ; // this function is in BIOS.C and written by us to start timer
    for (;;) {
        printf("|=========MEASURING==========|\n");
        /*Acquire Mutex*/
        OSMutexPend(mutex, 0, &return_code);

        CanBus0_Transmit(temp) ;       // transmit a message via Controller 0
        CanBus1_Receive(TEMP) ;        // receive a message via Controller 1 (and display it)

        CanBus0_Transmit(potential) ;       // transmit a message via Controller 0
        CanBus1_Receive(POTENTIAL) ;        // receive a message via Controller 1 (and display it)

        CanBus0_Transmit(light) ;       // transmit a message via Controller 0
        CanBus1_Receive(LIGHT) ;        // receive a message via Controller 1 (and display it)

        CanBus0_Transmit(switches) ;       // transmit a message via Controller 0
        CanBus1_Receive(SWITCHES) ;        // receive a message via Controller 1 (and display it)

        /*Release Mutex*/
        return_code = OSMutexPost(mutex);
        printf("|===========================|\n");

        OSTimeDly(100); //OS Delay for half a second = 500ms 

    }
}

/*
** Task 2 below was created with the highest priority so it must start timer1
** so that it produces interrupts for the 100hz context switches
*/
void Task2(void *pdata)
{
    unsigned int i = 0;
    INT8U  return_code = OS_ERR_NONE;

    for (;;) {
        /*Acquire Mutex*/
        OSMutexPend(mutex, 0, &return_code);

        switches = (PortB << 8) | (PortA);

        /*Release Mutex*/
        return_code = OSMutexPost(mutex);    

        OSTimeDly(10);
    }
}

void Task3(void *pdata)
{
    INT8U  return_code = OS_ERR_NONE;

    for (;;) {
        /*Acquire Mutex*/
        OSMutexPend(mutex, 0, &return_code);

        potential = ADCWrite(POTENTIAL);

        /*Release Mutex*/
        return_code = OSMutexPost(mutex);

        OSTimeDly(20);
    }
}

void Task4(void *pdata)
{
    INT8U  return_code = OS_ERR_NONE;

    for (;;) {
        /*Acquire Mutex*/
        OSMutexPend(mutex, 0, &return_code);

        light = ADCWrite(LIGHT);

        /*Release Mutex*/
        return_code = OSMutexPost(mutex);

        OSTimeDly(50);
    }
}

void Task5(void *pdata)
{
    INT8U  return_code = OS_ERR_NONE;

    for (;;) {
        /*Acquire Mutex*/
        OSMutexPend(mutex, 0, &return_code);

        temp = ADCWrite(TEMP);

        /*Release Mutex*/
        return_code = OSMutexPost(mutex);

        OSTimeDly(200);
    }
}

/* This function simply creates the Mutex*/
void initOSDataStructs(void)
{
  INT8U return_code = OS_ERR_NONE;
  
  mutex = OSMutexCreate(MUTEX_PRIORITY, &return_code);
  return;
}