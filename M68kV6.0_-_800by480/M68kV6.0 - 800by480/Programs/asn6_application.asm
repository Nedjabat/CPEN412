; C:\CPEN412\ASN6\ASN6B_THREADS\ASN6_APPLICATION.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; /*
; * EXAMPLE_1.C
; *
; * This is a minimal program to verify multitasking.
; *
; */
; #include <stdio.h>
; #include "Bios.h"
; #include "ucos_ii.h"
; #define STACKSIZE 256
; /*
; ** Stacks for each task are allocated here in the application in this case = 256 bytes
; ** but you can change size if required
; */
; OS_STK Task1Stk[STACKSIZE];
; OS_STK Task2Stk[STACKSIZE];
; OS_STK Task3Stk[STACKSIZE];
; OS_STK Task4Stk[STACKSIZE];
; OS_STK Task5Stk[STACKSIZE];
; OS_STK Task6Stk[STACKSIZE];
; /* Prototypes for our tasks/threads*/
; void Task1(void *); /* (void *) means the child task expects no data from parent*/
; void Task2(void *);
; void Task3(void *);
; void Task4(void *);
; void Task5(void *);
; void Task6(void *);
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
; /* display welcome message on LCD display */
; Oline0("Altera DE1/68K");
       pea       @asn6_a~1_1.L
       jsr       _Oline0
       addq.w    #4,A7
; Oline1("Micrium uC/OS-II RTOS");
       pea       @asn6_a~1_2.L
       jsr       _Oline1
       addq.w    #4,A7
; OSInit(); // call to initialise the OS
       jsr       _OSInit
; /*
; ** Now create the 4 child tasks and pass them no data.
; ** the smaller the numerical priority value, the higher the task priority
; */
; OSTaskCreate(Task1, OS_NULL, &Task1Stk[STACKSIZE], 12);
       pea       12
       lea       _Task1Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task1.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task2, OS_NULL, &Task2Stk[STACKSIZE], 11); // highest priority task
       pea       11
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
; OSTaskCreate(Task5, OS_NULL, &Task5Stk[STACKSIZE], 15); 
       pea       15
       lea       _Task5Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task5.L
       jsr       (A2)
       add.w     #16,A7
; OSTaskCreate(Task6, OS_NULL, &Task6Stk[STACKSIZE], 16); // lowest priority task
       pea       16
       lea       _Task6Stk.L,A0
       add.w     #512,A0
       move.l    A0,-(A7)
       clr.l     -(A7)
       pea       _Task6.L
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
       link      A6,#0
       move.l    D2,-(A7)
; unsigned char count = 0;
       clr.b     D2
; // must start timer ticker here
; Timer1_Init() ; // this function is in BIOS.C and written by us to start timer
       jsr       _Timer1_Init
; for (;;) {
Task1_1:
; printf("RANDOM HEX DISPLAY\n");
       pea       @asn6_a~1_3.L
       jsr       _printf
       addq.w    #4,A7
; HEX_A = ((count << 4) + (count & 0x0f));
       move.b    D2,D0
       lsl.b     #4,D0
       move.b    D2,D1
       and.b     #15,D1
       add.b     D1,D0
       move.b    D0,4194320
; count++;
       addq.b    #1,D2
; OSTimeDly(200);
       pea       200
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
       link      A6,#0
       move.l    D2,-(A7)
; unsigned char count = 0;
       clr.b     D2
; for (;;) {
Task2_1:
; printf("RANDOM LED DISPLAY\n");
       pea       @asn6_a~1_4.L
       jsr       _printf
       addq.w    #4,A7
; PortA = ((count << 4) + (count & 0x0f)); //LED0-7
       move.b    D2,D0
       lsl.b     #4,D0
       move.b    D2,D1
       and.b     #15,D1
       add.b     D1,D0
       move.b    D0,4194304
; count++;
       addq.b    #1,D2
; OSTimeDly(100);
       pea       100
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task2_1
; }
; }
; void Task3(void *pdata)
; {
       xdef      _Task3
_Task3:
       link      A6,#0
       move.l    D2,-(A7)
; unsigned char count = 0;
       clr.b     D2
; // must start timer ticker here
; Timer1_Init() ; // this function is in BIOS.C and written by us to start timer
       jsr       _Timer1_Init
; for (;;) {
Task3_1:
; printf("RANDOM HEX DISPLAY\n");
       pea       @asn6_a~1_3.L
       jsr       _printf
       addq.w    #4,A7
; HEX_B = ((count << 4) + (count & 0x0f));
       move.b    D2,D0
       lsl.b     #4,D0
       move.b    D2,D1
       and.b     #15,D1
       add.b     D1,D0
       move.b    D0,4194322
; count++;
       addq.b    #1,D2
; OSTimeDly(50);
       pea       50
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task3_1
; }
; }
; void Task4(void *pdata)
; {
       xdef      _Task4
_Task4:
       link      A6,#0
       move.l    D2,-(A7)
; unsigned char count = 0;
       clr.b     D2
; for (;;) {
Task4_1:
; printf("RANDOM LED DISPLAY\n");
       pea       @asn6_a~1_4.L
       jsr       _printf
       addq.w    #4,A7
; PortB = ((count << 4) + (count & 0x0f)); //LED8-9
       move.b    D2,D0
       lsl.b     #4,D0
       move.b    D2,D1
       and.b     #15,D1
       add.b     D1,D0
       move.b    D0,4194306
; count++;
       addq.b    #1,D2
; OSTimeDly(25);
       pea       25
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task4_1
; }
; }
; void Task5(void *pdata)
; {
       xdef      _Task5
_Task5:
       link      A6,#0
       move.l    D2,-(A7)
; unsigned char count = 0;
       clr.b     D2
; for (;;) {
Task5_1:
; printf("RANDOM HEX DISPLAY\n");
       pea       @asn6_a~1_3.L
       jsr       _printf
       addq.w    #4,A7
; HEX_C = ((count << 4) + (count & 0x0f)); //LED8-9
       move.b    D2,D0
       lsl.b     #4,D0
       move.b    D2,D1
       and.b     #15,D1
       add.b     D1,D0
       move.b    D0,4194324
; count++;
       addq.b    #1,D2
; OSTimeDly(10);
       pea       10
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task5_1
; }
; }
; void Task6(void *pdata)
; {
       xdef      _Task6
_Task6:
       link      A6,#-4
; unsigned char count = 0;
       clr.b     -1(A6)
; for (;;) {
Task6_1:
; printf("RANDOM HEX DISPLAY\n");
       pea       @asn6_a~1_3.L
       jsr       _printf
       addq.w    #4,A7
; OSTimeDly(10);
       pea       10
       jsr       _OSTimeDly
       addq.w    #4,A7
       bra       Task6_1
; }
; }
       section   const
@asn6_a~1_1:
       dc.b      65,108,116,101,114,97,32,68,69,49,47,54,56,75
       dc.b      0
@asn6_a~1_2:
       dc.b      77,105,99,114,105,117,109,32,117,67,47,79,83
       dc.b      45,73,73,32,82,84,79,83,0
@asn6_a~1_3:
       dc.b      82,65,78,68,79,77,32,72,69,88,32,68,73,83,80
       dc.b      76,65,89,10,0
@asn6_a~1_4:
       dc.b      82,65,78,68,79,77,32,76,69,68,32,68,73,83,80
       dc.b      76,65,89,10,0
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
       xdef      _Task6Stk
_Task6Stk:
       ds.b      512
       xref      _Init_LCD
       xref      _Timer1_Init
       xref      _Init_RS232
       xref      _OSInit
       xref      _OSStart
       xref      _OSTaskCreate
       xref      _Oline0
       xref      _Oline1
       xref      _OSTimeDly
       xref      _printf
