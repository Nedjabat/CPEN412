; C:\CPEN412\ASN6\ASN6B_THREADS\ASN6B_APPLICATION.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; /*
; * EXAMPLE_1.C
; *
; * This is a minimal program to verify multitasking.
; *
; */
; #include <stdio.h>
; #include "Bios.h"
; #include "ucos_ii.h"
; #include "Canbus-Controller.h"
; #define STACKSIZE 256
; /*******************************************************************************************
; ** ADC Types
; *******************************************************************************************/
; #define TEMP        0
; #define POTENTIAL   1
; #define LIGHT       2
; #define SWITCHES    3
; /*******************************************************************************************
; ** Task Priority for Mutex
; Ref: https://www.intel.com/content/www/us/en/support/programmable/support-resources/design-examples/horizontal/exm-micro-mutex.html?fbclid=IwAR2KdOFtTFDJYERh3MYIPLRbH80BVaIo9fdZTChviTEgzZ-bAJwRikO9maE
; *******************************************************************************************/
; #define MUTEX_PRIORITY 5
; /*
; ** Stacks for each task are allocated here in the application in this case = 256 bytes
; ** but you can change size if required
; */
; OS_STK Task1Stk[STACKSIZE];
; OS_STK Task2Stk[STACKSIZE];
; OS_STK Task3Stk[STACKSIZE];
; OS_STK Task4Stk[STACKSIZE];
; OS_STK Task5Stk[STACKSIZE];
; /* Declaration of the mutex*/
; OS_EVENT  *mutex;
; /* Prototypes for our tasks/threads*/
; void Task1(void *); /* (void *) means the child task expects no data from parent*/
; void Task2(void *);
; void Task3(void *);
; void Task4(void *);
; void Task5(void *);
; /*******************************************************************************************
; ** Global Variables
; *******************************************************************************************/
; unsigned char temp, potential, light;
; int switches;
; /*
; ** Our main application which has to
; ** 1) Initialise any peripherals on the board, e.g. RS232 for hyperterminal + LCD
; ** 2) Call OSInit() to initialise the OS
; ** 3) Create our application task/threads
; ** 4) Call OSStart()
; */
; void main(void)
; {
       section   code
       xdef      _main
_main:
       move.l    A2,-(A7)
       lea       _OSTaskCreate.L,A2
; // initialise board hardware by calling our routines from the BIOS.C source file
; Init_RS232();
       jsr       _Init_RS232
; Init_LCD();
       jsr       _Init_LCD
; // initialise CanBus controllers
; Init_CanBus_Controller0();
       jsr       _Init_CanBus_Controller0
; Init_CanBus_Controller1();
       jsr       _Init_CanBus_Controller1
; /* display welcome message on LCD display */
; Oline0("Altera DE1/68K");
       pea       @asn6b_~1_1.L
       jsr       _Oline0
       addq.w    #4,A7
; Oline1("Micrium uC/OS-II RTOS");
       pea       @asn6b_~1_2.L
       jsr       _Oline1
       addq.w    #4,A7
; OSInit(); // call to initialise the OS
       jsr       _OSInit
; //initialise mutex
; initOSDataStructs();
       jsr       _initOSDataStructs
; /*
; ** Now create the 4 child tasks and pass them no data.
; ** the smaller the numerical priority value, the higher the task priority
; */
; OSTaskCreate(Task1, OS_NULL, &Task1Stk[STACKSIZE], 11); // highest priority task
       pea       11
       lea       _Task1Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task1.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task2, OS_NULL, &Task2Stk[STACKSIZE], 12); 
       pea       12
       lea       _Task2Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task2.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task3, OS_NULL, &Task3Stk[STACKSIZE], 13);
       pea       13
       lea       _Task3Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task3.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task4, OS_NULL, &Task4Stk[STACKSIZE], 14); 
       pea       14
       lea       _Task4Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task4.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task5, OS_NULL, &Task5Stk[STACKSIZE], 15); // lowest priority task
       pea       15
       lea       _Task5Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task5.L
       jsr       (A2)
       add.w     #16,A7
; OSStart(); // call to start the OS scheduler, (never returns from this function)
       jsr       _OSStart
       move.l    (A7)+,A2
       rts
; }
; /*
; ** IMPORTANT : Timer 1 interrupts must be started by the highest priority task
; ** that runs first which is Task2
; */
; void Task1(void *pdata)
; {
       xdef      _Task1
_Task1:
       link      A6,#-4
       movem.l   A2/A3,-(A7)
       lea       _CanBus1_Receive.L,A2
       lea       _CanBus0_Transmit.L,A3
; INT8U  return_code = OS_ERR_NONE;
       clr.b     -1(A6)
; // must start timer ticker here
; Timer1_Init() ; // this function is in BIOS.C and written by us to start timer
       jsr       _Timer1_Init
; for (;;) {
Task1_1:
; printf("|=========MEASURING==========|\n");
       pea       @asn6b_~1_3.L
       jsr       _printf
       addq.w    #4,A7
; /*Acquire Mutex*/
; OSMutexPend(mutex, 0, &return_code);
       pea       -1(A6)
       clr.l     -(A7)
       move.l    _mutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; CanBus0_Transmit(temp) ;       // transmit a message via Controller 0
       move.b    _temp.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; CanBus1_Receive(TEMP) ;        // receive a message via Controller 1 (and display it)
       clr.l     -(A7)
       jsr       (A2)
       addq.w    #4,A7
; CanBus0_Transmit(potential) ;       // transmit a message via Controller 0
       move.b    _potential.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; CanBus1_Receive(POTENTIAL) ;        // receive a message via Controller 1 (and display it)
       pea       1
       jsr       (A2)
       addq.w    #4,A7
; CanBus0_Transmit(light) ;       // transmit a message via Controller 0
       move.b    _light.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; CanBus1_Receive(LIGHT) ;        // receive a message via Controller 1 (and display it)
       pea       2
       jsr       (A2)
       addq.w    #4,A7
; CanBus0_Transmit(switches) ;       // transmit a message via Controller 0
       move.l    _switches.L,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A3)
       addq.w    #4,A7
; CanBus1_Receive(SWITCHES) ;        // receive a message via Controller 1 (and display it)
       pea       3
       jsr       (A2)
       addq.w    #4,A7
; /*Release Mutex*/
; return_code = OSMutexPost(mutex);
       move.l    _mutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
       move.b    D0,-1(A6)
; printf("|===========================|\n");
       pea       @asn6b_~1_4.L
       jsr       _printf
       addq.w    #4,A7
; OSTimeDly(100); //OS Delay for half a second = 500ms 
       pea       100
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task1_1
; }
; }
; /*
; ** Task 2 below was created with the highest priority so it must start timer1
; ** so that it produces interrupts for the 100hz context switches
; */
; void Task2(void *pdata)
; {
       xdef      _Task2
_Task2:
       link      A6,#-8
; unsigned int i = 0;
       clr.l     -6(A6)
; INT8U  return_code = OS_ERR_NONE;
       clr.b     -1(A6)
; for (;;) {
Task2_1:
; /*Acquire Mutex*/
; OSMutexPend(mutex, 0, &return_code);
       pea       -1(A6)
       clr.l     -(A7)
       move.l    _mutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; switches = (PortB << 8) | (PortA);
       move.b    4194306,D0
       and.l     #255,D0
       lsl.l     #8,D0
       move.b    4194304,D1
       and.l     #255,D1
       or.l      D1,D0
       move.l    D0,_switches.L
; /*Release Mutex*/
; return_code = OSMutexPost(mutex);    
       move.l    _mutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
       move.b    D0,-1(A6)
; OSTimeDly(10);
       pea       10
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task2_1
; }
; }
; void Task3(void *pdata)
; {
       xdef      _Task3
_Task3:
       link      A6,#-4
; INT8U  return_code = OS_ERR_NONE;
       clr.b     -1(A6)
; for (;;) {
Task3_1:
; /*Acquire Mutex*/
; OSMutexPend(mutex, 0, &return_code);
       pea       -1(A6)
       clr.l     -(A7)
       move.l    _mutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; potential = ADCWrite(POTENTIAL);
       pea       1
       jsr       _ADCWrite
       addq.w    #4,A7
       move.b    D0,_potential.L
; /*Release Mutex*/
; return_code = OSMutexPost(mutex);
       move.l    _mutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
       move.b    D0,-1(A6)
; OSTimeDly(20);
       pea       20
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task3_1
; }
; }
; void Task4(void *pdata)
; {
       xdef      _Task4
_Task4:
       link      A6,#-4
; INT8U  return_code = OS_ERR_NONE;
       clr.b     -1(A6)
; for (;;) {
Task4_1:
; /*Acquire Mutex*/
; OSMutexPend(mutex, 0, &return_code);
       pea       -1(A6)
       clr.l     -(A7)
       move.l    _mutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; light = ADCWrite(LIGHT);
       pea       2
       jsr       _ADCWrite
       addq.w    #4,A7
       move.b    D0,_light.L
; /*Release Mutex*/
; return_code = OSMutexPost(mutex);
       move.l    _mutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
       move.b    D0,-1(A6)
; OSTimeDly(50);
       pea       50
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task4_1
; }
; }
; void Task5(void *pdata)
; {
       xdef      _Task5
_Task5:
       link      A6,#-4
; INT8U  return_code = OS_ERR_NONE;
       clr.b     -1(A6)
; for (;;) {
Task5_1:
; /*Acquire Mutex*/
; OSMutexPend(mutex, 0, &return_code);
       pea       -1(A6)
       clr.l     -(A7)
       move.l    _mutex.L,-(A7)
       jsr       _OSMutexPend
       add.w     #12,A7
; temp = ADCWrite(TEMP);
       clr.l     -(A7)
       jsr       _ADCWrite
       addq.w    #4,A7
       move.b    D0,_temp.L
; /*Release Mutex*/
; return_code = OSMutexPost(mutex);
       move.l    _mutex.L,-(A7)
       jsr       _OSMutexPost
       addq.w    #4,A7
       move.b    D0,-1(A6)
; OSTimeDly(200);
       pea       200
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task5_1
; }
; }
; /* This function simply creates the Mutex*/
; void initOSDataStructs(void)
; {
       xdef      _initOSDataStructs
_initOSDataStructs:
       link      A6,#-4
; INT8U return_code = OS_ERR_NONE;
       clr.b     -1(A6)
; mutex = OSMutexCreate(MUTEX_PRIORITY, &return_code);
       pea       -1(A6)
       pea       5
       jsr       _OSMutexCreate
       addq.w    #8,A7
       move.l    D0,_mutex.L
; return;
       unlk      A6
       rts
; }
       section   const
@asn6b_~1_1:
       dc.b      65,108,116,101,114,97,32,68,69,49,47,54,56,75
       dc.b      0
@asn6b_~1_2:
       dc.b      77,105,99,114,105,117,109,32,117,67,47,79,83
       dc.b      45,73,73,32,82,84,79,83,0
@asn6b_~1_3:
       dc.b      124,61,61,61,61,61,61,61,61,61,77,69,65,83,85
       dc.b      82,73,78,71,61,61,61,61,61,61,61,61,61,61,124
       dc.b      10,0
@asn6b_~1_4:
       dc.b      124,61,61,61,61,61,61,61,61,61,61,61,61,61,61
       dc.b      61,61,61,61,61,61,61,61,61,61,61,61,61,124,10
       dc.b      0
       section   bss
       xdef      _Task1Stk
_Task1Stk:
       ds.b      512
       xdef      _Task2Stk
_Task2Stk:
       ds.b      512
       xdef      _Task3Stk
_Task3Stk:
       ds.b      512
       xdef      _Task4Stk
_Task4Stk:
       ds.b      512
       xdef      _Task5Stk
_Task5Stk:
       ds.b      512
       xdef      _mutex
_mutex:
       ds.b      4
       xdef      _temp
_temp:
       ds.b      1
       xdef      _potential
_potential:
       ds.b      1
       xdef      _light
_light:
       ds.b      1
       xdef      _switches
_switches:
       ds.b      4
       xref      _CanBus0_Transmit
       xref      _Init_LCD
       xref      _Timer1_Init
       xref      _Init_RS232
       xref      _OSMutexCreate
       xref      _CanBus1_Receive
       xref      _Init_CanBus_Controller0
       xref      _Init_CanBus_Controller1
       xref      _OSInit
       xref      _OSStart
       xref      _OSTaskCreate
       xref      _ADCWrite
       xref      _OSMutexPost
       xref      _Oline0
       xref      _OSMutexPend
       xref      _Oline1
       xref      _OSTimeDly
       xref      _printf
