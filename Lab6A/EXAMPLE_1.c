/*
 * EXAMPLE_1.C
 *
 * This is a minimal program to verify multitasking.
 *
 */

#include <stdio.h>
#include <Bios.h>
#include <ucos_ii.h>

#define STACKSIZE  256

/* 
** Stacks for each task are allocated here in the application in this case = 256 bytes
** but you can change size if required
*/

OS_STK Task1Stk[STACKSIZE];
OS_STK Task2Stk[STACKSIZE];
OS_STK Task3Stk[STACKSIZE];
OS_STK Task4Stk[STACKSIZE];


/* Prototypes for our tasks/threads*/
void Task1(void *);	/* (void *) means the child task expects no data from parent*/
void Task2(void *);
void Task3(void *);
void Task4(void *);


INT8U led70;
INT8U led89;
INT8U hex12;
INT8U hex34;
INT8U hex56;
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

    OSInit();		// call to initialise the OS

/* 
** Now create the 4 child tasks and pass them no data.
** the smaller the numerical priority value, the higher the task priority 
*/

    OSTaskCreate(Task1, OS_NULL, &Task1Stk[STACKSIZE], 12);     
    OSTaskCreate(Task2, OS_NULL, &Task2Stk[STACKSIZE], 11);     // highest priority task
    OSTaskCreate(Task3, OS_NULL, &Task3Stk[STACKSIZE], 13);
    OSTaskCreate(Task4, OS_NULL, &Task4Stk[STACKSIZE], 14);	    // lowest priority task

    OSStart();  // call to start the OS scheduler, (never returns from this function)
}


void Task1(void *pdata)
{

    for (;;) {
       printf("This is Task #1\n");
        PortA = led70;
        PortB = led89;
        if(led70 == 0xff){
            led70 = 0;
            if (led89 == 0x3){
                led89 = 0;
            }
            else{
                led89++;
            }
        }
        else led70++;
       OSTimeDly(30);
    }
}


void Task2(void *pdata)
{
    // must start timer ticker here 

    Timer1_Init() ;    

    for (;;) {
       printf("....This is Task #2\n");
       if (hex34 == 0xff){
        HEX_C = hex56++;
       }
        if (hex12 == 0xff){
            HEX_B = hex34++;
        }
       HEX_A = hex12++;
       OSTimeDly(10);
    }
}

void Task3(void *pdata)
{
    for (;;) {
       printf("........This is Task #3\n");
       OSTimeDly(40);
    }
}

void Task4(void *pdata)
{

    for (;;) {
       printf("............This is Task #4\n");
       OSTimeDly(50);
    }
}

