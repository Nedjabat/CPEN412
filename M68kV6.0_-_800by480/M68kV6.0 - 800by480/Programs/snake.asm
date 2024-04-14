; C:\M68KV6.0 - 800BY480\SNAKE_GAME_SOFTWARE\SNAKE.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; #include <stdlib.h>
; #include <limits.h>
; #include <string.h>
; #include "snake.h"
; int score;
; int timer;
; unsigned long long Timer8ISRCount;
; struct
; {
; coord_t xy[SNAKE_LENGTH_LIMIT];
; int length;
; dir_t direction;
; int speed;
; int speed_increase;
; coord_t food;
; } Snake;
; const coord_t screensize = {NUM_VGA_COLUMNS,NUM_VGA_ROWS};
; int waiting_for_direction_to_be_implemented;
; /////////////////////////////////////////////////////////////////////////////////////////////////////
; //
; //
; //                        functions to implement
; //
; //
; /////////////////////////////////////////////////////////////////////////////////////////////////////
; void putcharxy(int x, int y, char ch) {
       section   code
       xdef      _putcharxy
_putcharxy:
       link      A6,#0
       move.l    D2,-(A7)
; //display on the VGA char ch at column x, line y
; //00F0 0000 - 00F0 FFFF
; unsigned char * pointer = VGA_START;
       move.l    #15728640,D2
; pointer = pointer + (NUM_VGA_COLUMNS * y + x);
       move.l    12(A6),-(A7)
       pea       80
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       add.l     8(A6),D0
       add.l     D0,D2
; *pointer = (unsigned char)ch;
       move.l    D2,A0
       move.b    19(A6),(A0)
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; void print_at_xy(int x, int y, const char* str) {
       xdef      _print_at_xy
_print_at_xy:
       link      A6,#-12
       movem.l   D2/D3,-(A7)
       move.l    8(A6),D2
; //print a string on the VGA, starting at column x, line y. 
; //Wrap around to the next line if we reach the edge of the screen
; int i, j, len;
; char ch;
; len = strlen(str);
       move.l    16(A6),-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,-6(A6)
; for(i = 0; i < len; i++){
       clr.l     D3
print_at_xy_1:
       cmp.l     -6(A6),D3
       bge       print_at_xy_3
; ch = str[i];
       move.l    16(A6),A0
       move.b    0(A0,D3.L),-1(A6)
; putcharxy(x, y, ch);
       move.b    -1(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    12(A6),-(A7)
       move.l    D2,-(A7)
       jsr       _putcharxy
       add.w     #12,A7
; if(x == (NUM_VGA_COLUMNS - 1)){
       cmp.l     #79,D2
       bne.s     print_at_xy_4
; x = 0;
       clr.l     D2
; y++;
       addq.l    #1,12(A6)
       bra.s     print_at_xy_5
print_at_xy_4:
; }else{
; x++;
       addq.l    #1,D2
print_at_xy_5:
       addq.l    #1,D3
       bra       print_at_xy_1
print_at_xy_3:
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; }
; }
; void cls()
; {
       xdef      _cls
_cls:
       movem.l   D2/D3,-(A7)
; //clear the screen
; int x,y;
; for(x = 0; x < NUM_VGA_COLUMNS; x++){
       clr.l     D3
cls_1:
       cmp.l     #80,D3
       bge.s     cls_3
; for(y = 0; y < NUM_VGA_ROWS; y++){
       clr.l     D2
cls_4:
       cmp.l     #40,D2
       bge.s     cls_6
; putcharxy(x, y, ' ');
       pea       32
       move.l    D2,-(A7)
       move.l    D3,-(A7)
       jsr       _putcharxy
       add.w     #12,A7
       addq.l    #1,D2
       bra       cls_4
cls_6:
       addq.l    #1,D3
       bra       cls_1
cls_3:
       movem.l   (A7)+,D2/D3
       rts
; }
; }
; };
; void gotoxy(int x, int y)
; {
       xdef      _gotoxy
_gotoxy:
       link      A6,#-8
; //move the cursor to location column = x, row = y
; unsigned char * x_ptr = VGA_ocrx;
       move.l    #15790098,-8(A6)
; unsigned char * y_ptr = VGA_ocry;
       move.l    #15790114,-4(A6)
; *x_ptr = x;
       move.l    8(A6),D0
       move.l    -8(A6),A0
       move.b    D0,(A0)
; *y_ptr = y;
       move.l    12(A6),D0
       move.l    -4(A6),A0
       move.b    D0,(A0)
       unlk      A6
       rts
; }
; void set_vga_control_reg(char x) 
; {
       xdef      _set_vga_control_reg
_set_vga_control_reg:
       link      A6,#-4
; //Set the VGA control (OCTL) value
; unsigned char * octl_ptr = VGA_octl;
       move.l    #15790148,-4(A6)
; *octl_ptr = x;
       move.l    -4(A6),A0
       move.b    11(A6),(A0)
       unlk      A6
       rts
; }
; char get_vga_control_reg()
; {
       xdef      _get_vga_control_reg
_get_vga_control_reg:
       link      A6,#-4
; //return the VGA control (OCTL) value
; unsigned char * octl_ptr = VGA_octl;
       move.l    #15790148,-4(A6)
; return *octl_ptr;
       move.l    -4(A6),A0
       move.b    (A0),D0
       unlk      A6
       rts
; }
; int clock() {
       xdef      _clock
_clock:
; //return the current value of a milliseconds counter, with a resolution of 10ms or better
; return (Timer8ISRCount * 10);
       move.l    _Timer8ISRCount.L,-(A7)
       pea       10
       jsr       ULMUL
       move.l    (A7),D0
       addq.w    #8,A7
       rts
; }
; void Timer_IRQ()
; {
       xdef      _Timer_IRQ
_Timer_IRQ:
; if (Timer8Status == 1) {        
       move.b    4194622,D0
       cmp.b     #1,D0
       bne.s     Timer_IRQ_1
; Timer8Control = 3;      	
       move.b    #3,4194622
; PortC = Timer8ISRCount++;
       move.l    _Timer8ISRCount.L,D0
       addq.l    #1,_Timer8ISRCount.L
       move.b    D0,4194308
Timer_IRQ_1:
       rts
; }
; }
; void initTimer(){
       xdef      _initTimer
_initTimer:
; //initialize parameters for timer
; Timer8ISRCount = 0;
       clr.l     _Timer8ISRCount.L
; InstallExceptionHandler(Timer_IRQ, 30);
       pea       30
       pea       _Timer_IRQ.L
       jsr       _InstallExceptionHandler
       addq.w    #8,A7
; Timer8Data = 0x03;
       move.b    #3,4194620
; Timer8Control = 3;
       move.b    #3,4194622
       rts
; }
; void delay_ms(int num_ms) {
       xdef      _delay_ms
_delay_ms:
       link      A6,#0
       move.l    D2,-(A7)
; //delay a certain number of milliseconds
; int i;
; for(i = 0; i < 75 * num_ms; i++);
       clr.l     D2
delay_ms_1:
       move.l    8(A6),-(A7)
       pea       75
       jsr       LMUL
       move.l    (A7),D0
       addq.w    #8,A7
       cmp.l     D0,D2
       bge.s     delay_ms_3
       addq.l    #1,D2
       bra       delay_ms_1
delay_ms_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; void gameOver()
; {
       xdef      _gameOver
_gameOver:
       link      A6,#-8
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       lea       _set_vga_control_reg.L,A3
       lea       -4(A6),A4
       lea       _putcharxy.L,A5
; int i, j, z, len;
; int x, y;
; char ch;
; char score_string[3];
; const char* str = "Game Over!";
       lea       @snake_1.L,A0
       move.l    A0,D7
; x = 35;
       moveq     #35,D2
; y = 19;
       moveq     #19,D4
; cls();
       jsr       _cls
; set_vga_control_reg(0xE4);
       pea       228
       jsr       (A3)
       addq.w    #4,A7
; gotoxy(x+1,y); //Commented out due to bug, it breaks entire game
       move.l    D4,-(A7)
       move.l    D2,D1
       addq.l    #1,D1
       move.l    D1,-(A7)
       jsr       _gotoxy
       addq.w    #8,A7
; len = strlen(str);
       move.l    D7,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D6
; for(i = 0; i < len; i++){
       clr.l     D3
gameOver_1:
       cmp.l     D6,D3
       bge       gameOver_3
; ch = str[i];
       move.l    D7,A0
       move.b    0(A0,D3.L),D5
; putcharxy(x, y, ch);
       ext.w     D5
       ext.l     D5
       move.l    D5,-(A7)
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       jsr       (A5)
       add.w     #12,A7
; delay_ms(100);
       pea       100
       jsr       _delay_ms
       addq.w    #4,A7
; gotoxy(x+1,y); //Commented out due to bug, it breaks entire game
       move.l    D4,-(A7)
       move.l    D2,D1
       addq.l    #1,D1
       move.l    D1,-(A7)
       jsr       _gotoxy
       addq.w    #8,A7
; if(x == (NUM_VGA_COLUMNS - 1)){
       cmp.l     #79,D2
       bne.s     gameOver_4
; x = 0;
       clr.l     D2
; y++;
       addq.l    #1,D4
       bra.s     gameOver_5
gameOver_4:
; }else{
; x++;
       addq.l    #1,D2
gameOver_5:
       addq.l    #1,D3
       bra       gameOver_1
gameOver_3:
; }
; }
; str = "Score: ";
       lea       @snake_2.L,A0
       move.l    A0,D7
; x = 35;
       moveq     #35,D2
; y = 20;
       moveq     #20,D4
; len = strlen(str);
       move.l    D7,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D6
; for(i = 0; i < len; i++){
       clr.l     D3
gameOver_6:
       cmp.l     D6,D3
       bge       gameOver_8
; ch = str[i];
       move.l    D7,A0
       move.b    0(A0,D3.L),D5
; putcharxy(x, y, ch);
       ext.w     D5
       ext.l     D5
       move.l    D5,-(A7)
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       jsr       (A5)
       add.w     #12,A7
; delay_ms(100);
       pea       100
       jsr       _delay_ms
       addq.w    #4,A7
; gotoxy(x+1,y); //Commented out due to bug, it breaks entire game
       move.l    D4,-(A7)
       move.l    D2,D1
       addq.l    #1,D1
       move.l    D1,-(A7)
       jsr       _gotoxy
       addq.w    #8,A7
; if(x == (NUM_VGA_COLUMNS - 1)){
       cmp.l     #79,D2
       bne.s     gameOver_9
; x = 0;
       clr.l     D2
; y++;
       addq.l    #1,D4
       bra.s     gameOver_10
gameOver_9:
; }else{
; x++;
       addq.l    #1,D2
gameOver_10:
       addq.l    #1,D3
       bra       gameOver_6
gameOver_8:
; }
; }
; sprintf(score_string, "%d", score);
       move.l    _score.L,-(A7)
       pea       @snake_3.L
       move.l    A4,-(A7)
       jsr       _sprintf
       add.w     #12,A7
; len = strlen(score_string);
       move.l    A4,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D6
; for(i = 0; i < len; i++){
       clr.l     D3
gameOver_11:
       cmp.l     D6,D3
       bge       gameOver_13
; ch = score_string[i];
       move.b    0(A4,D3.L),D5
; putcharxy(x, y, ch);
       ext.w     D5
       ext.l     D5
       move.l    D5,-(A7)
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       jsr       (A5)
       add.w     #12,A7
; delay_ms(100);
       pea       100
       jsr       _delay_ms
       addq.w    #4,A7
; gotoxy(x+1,y); //Commented out due to bug, it breaks entire game
       move.l    D4,-(A7)
       move.l    D2,D1
       addq.l    #1,D1
       move.l    D1,-(A7)
       jsr       _gotoxy
       addq.w    #8,A7
; if(x == (NUM_VGA_COLUMNS - 1)){
       cmp.l     #79,D2
       bne.s     gameOver_14
; x = 0;
       clr.l     D2
; y++;
       addq.l    #1,D4
       bra.s     gameOver_15
gameOver_14:
; }else{
; x++;
       addq.l    #1,D2
gameOver_15:
       addq.l    #1,D3
       bra       gameOver_11
gameOver_13:
; }
; }
; while(!(kbhit())){
gameOver_16:
       jsr       _kbhit
       tst.l     D0
       bne       gameOver_18
; for(z = 0; z < 6; z++){
       move.w    #0,A2
gameOver_19:
       move.l    A2,D0
       cmp.l     #6,D0
       bge       gameOver_21
; if(z == 0){
       move.l    A2,D0
       bne.s     gameOver_22
; set_vga_control_reg(0xE1);
       pea       225
       jsr       (A3)
       addq.w    #4,A7
       bra       gameOver_33
gameOver_22:
; }else if(z == 1){
       move.l    A2,D0
       cmp.l     #1,D0
       bne.s     gameOver_24
; set_vga_control_reg(0xE3);
       pea       227
       jsr       (A3)
       addq.w    #4,A7
       bra       gameOver_33
gameOver_24:
; }else if(z == 2){
       move.l    A2,D0
       cmp.l     #2,D0
       bne.s     gameOver_26
; set_vga_control_reg(0xE4);
       pea       228
       jsr       (A3)
       addq.w    #4,A7
       bra       gameOver_33
gameOver_26:
; }else if(z == 3){
       move.l    A2,D0
       cmp.l     #3,D0
       bne.s     gameOver_28
; set_vga_control_reg(0xE5);
       pea       229
       jsr       (A3)
       addq.w    #4,A7
       bra       gameOver_33
gameOver_28:
; }else if(z == 4){
       move.l    A2,D0
       cmp.l     #4,D0
       bne.s     gameOver_30
; set_vga_control_reg(0xE6);
       pea       230
       jsr       (A3)
       addq.w    #4,A7
       bra.s     gameOver_33
gameOver_30:
; }else if(z == 5){
       move.l    A2,D0
       cmp.l     #5,D0
       bne.s     gameOver_32
; set_vga_control_reg(0xE7);
       pea       231
       jsr       (A3)
       addq.w    #4,A7
       bra.s     gameOver_33
gameOver_32:
; }else{
; set_vga_control_reg(0xE2);
       pea       226
       jsr       (A3)
       addq.w    #4,A7
gameOver_33:
; }
; str = "Game Over!";
       lea       @snake_1.L,A0
       move.l    A0,D7
; x = 35;
       moveq     #35,D2
; y = 19;
       moveq     #19,D4
; cls();
       jsr       _cls
; len = strlen(str);
       move.l    D7,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D6
; for(i = 0; i < len; i++){
       clr.l     D3
gameOver_34:
       cmp.l     D6,D3
       bge       gameOver_36
; ch = str[i];
       move.l    D7,A0
       move.b    0(A0,D3.L),D5
; putcharxy(x, y, ch);
       ext.w     D5
       ext.l     D5
       move.l    D5,-(A7)
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       jsr       (A5)
       add.w     #12,A7
; if(x == (NUM_VGA_COLUMNS - 1)){
       cmp.l     #79,D2
       bne.s     gameOver_37
; x = 0;
       clr.l     D2
; y++;
       addq.l    #1,D4
       bra.s     gameOver_38
gameOver_37:
; }else{
; x++;
       addq.l    #1,D2
gameOver_38:
       addq.l    #1,D3
       bra       gameOver_34
gameOver_36:
; }
; }
; str = "Score: ";
       lea       @snake_2.L,A0
       move.l    A0,D7
; x = 35;
       moveq     #35,D2
; y = 20;
       moveq     #20,D4
; len = strlen(str);
       move.l    D7,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D6
; for(i = 0; i < len; i++){
       clr.l     D3
gameOver_39:
       cmp.l     D6,D3
       bge       gameOver_41
; ch = str[i];
       move.l    D7,A0
       move.b    0(A0,D3.L),D5
; putcharxy(x, y, ch);
       ext.w     D5
       ext.l     D5
       move.l    D5,-(A7)
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       jsr       (A5)
       add.w     #12,A7
; if(x == (NUM_VGA_COLUMNS - 1)){
       cmp.l     #79,D2
       bne.s     gameOver_42
; x = 0;
       clr.l     D2
; y++;
       addq.l    #1,D4
       bra.s     gameOver_43
gameOver_42:
; }else{
; x++;
       addq.l    #1,D2
gameOver_43:
       addq.l    #1,D3
       bra       gameOver_39
gameOver_41:
; }
; }
; sprintf(score_string, "%d", score);
       move.l    _score.L,-(A7)
       pea       @snake_3.L
       move.l    A4,-(A7)
       jsr       _sprintf
       add.w     #12,A7
; len = strlen(score_string);
       move.l    A4,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,D6
; for(i = 0; i < len; i++){
       clr.l     D3
gameOver_44:
       cmp.l     D6,D3
       bge       gameOver_46
; ch = score_string[i];
       move.b    0(A4,D3.L),D5
; putcharxy(x, y, ch);
       ext.w     D5
       ext.l     D5
       move.l    D5,-(A7)
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       jsr       (A5)
       add.w     #12,A7
; if(x == (NUM_VGA_COLUMNS - 1)){
       cmp.l     #79,D2
       bne.s     gameOver_47
; x = 0;
       clr.l     D2
; y++;
       addq.l    #1,D4
       bra.s     gameOver_48
gameOver_47:
; }else{
; x++;
       addq.l    #1,D2
gameOver_48:
       addq.l    #1,D3
       bra       gameOver_44
gameOver_46:
; }
; }
; gotoxy(x+1,y); //Commented out due to bug, it breaks entire game
       move.l    D4,-(A7)
       move.l    D2,D1
       addq.l    #1,D1
       move.l    D1,-(A7)
       jsr       _gotoxy
       addq.w    #8,A7
; delay_ms(250);
       pea       250
       jsr       _delay_ms
       addq.w    #4,A7
       addq.w    #1,A2
       bra       gameOver_19
gameOver_21:
       bra       gameOver_16
gameOver_18:
; }
; }
; set_vga_control_reg(0xF2);
       pea       242
       jsr       (A3)
       addq.w    #4,A7
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; void updateScore() ///////////////////////////////////////
; {
       xdef      _updateScore
_updateScore:
       link      A6,#-16
       movem.l   D2/D3/D4/A2,-(A7)
       lea       -4(A6),A2
; //print the score at the bottom of the screen
; int i, x, y, len, offset;
; char ch;
; char score_string[3];
; x = 1;
       moveq     #1,D2
; y = 39;
       moveq     #39,D4
; print_at_xy(x, y, "Score: ");
       pea       @snake_2.L
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       jsr       _print_at_xy
       add.w     #12,A7
; sprintf(score_string, "%d", score);
       move.l    _score.L,-(A7)
       pea       @snake_3.L
       move.l    A2,-(A7)
       jsr       _sprintf
       add.w     #12,A7
; len = strlen(score_string);
       move.l    A2,-(A7)
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,-14(A6)
; offset = strlen("Score: ");
       pea       @snake_2.L
       jsr       _strlen
       addq.w    #4,A7
       move.l    D0,-10(A6)
; x+=offset;
       move.l    -10(A6),D0
       add.l     D0,D2
; for(i = 0; i < len; i++){
       clr.l     D3
updateScore_1:
       cmp.l     -14(A6),D3
       bge       updateScore_3
; ch = score_string[i];
       move.b    0(A2,D3.L),-5(A6)
; putcharxy(x, y, ch);
       move.b    -5(A6),D1
       ext.w     D1
       ext.l     D1
       move.l    D1,-(A7)
       move.l    D4,-(A7)
       move.l    D2,-(A7)
       jsr       _putcharxy
       add.w     #12,A7
; if(x == (NUM_VGA_COLUMNS - 1)){
       cmp.l     #79,D2
       bne.s     updateScore_4
; x = 0;
       clr.l     D2
; y++;
       addq.l    #1,D4
       bra.s     updateScore_5
updateScore_4:
; }else{
; x++;
       addq.l    #1,D2
updateScore_5:
       addq.l    #1,D3
       bra       updateScore_1
updateScore_3:
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; }
; }
; void drawRect(int x, int y, int x2, int y2, char ch)
; {
       xdef      _drawRect
_drawRect:
       link      A6,#0
       movem.l   D2/D3/A2,-(A7)
       move.b    27(A6),D3
       ext.w     D3
       ext.l     D3
       lea       _putcharxy.L,A2
; //draws a rectangle. Left top corner: (x1,y1) length of sides = x2,y2
; //drawRect(1,1,79,38, BORDER);
; int i;
; set_vga_control_reg(0xB2);
       pea       178
       jsr       _set_vga_control_reg
       addq.w    #4,A7
; for(i = y; i <= y2; i++){
       move.l    12(A6),D2
drawRect_1:
       cmp.l     20(A6),D2
       bgt       drawRect_3
; putcharxy(x, i, ch);
       ext.w     D3
       ext.l     D3
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       move.l    8(A6),-(A7)
       jsr       (A2)
       add.w     #12,A7
; putcharxy(x2, i, ch);
       ext.w     D3
       ext.l     D3
       move.l    D3,-(A7)
       move.l    D2,-(A7)
       move.l    16(A6),-(A7)
       jsr       (A2)
       add.w     #12,A7
       addq.l    #1,D2
       bra       drawRect_1
drawRect_3:
; }
; for(i = x; i <= x2; i++){
       move.l    8(A6),D2
drawRect_4:
       cmp.l     16(A6),D2
       bgt       drawRect_6
; putcharxy(i, y, ch);
       ext.w     D3
       ext.l     D3
       move.l    D3,-(A7)
       move.l    12(A6),-(A7)
       move.l    D2,-(A7)
       jsr       (A2)
       add.w     #12,A7
; putcharxy(i, y2, ch);
       ext.w     D3
       ext.l     D3
       move.l    D3,-(A7)
       move.l    20(A6),-(A7)
       move.l    D2,-(A7)
       jsr       (A2)
       add.w     #12,A7
       addq.l    #1,D2
       bra       drawRect_4
drawRect_6:
       movem.l   (A7)+,D2/D3/A2
       unlk      A6
       rts
; }
; }
; /////////////////////////////////////////////////////////////////////////////
; //
; //  End functions you need to implement
; //
; /////////////////////////////////////////////////////////////////////////////
; void initSnake()
; {
       xdef      _initSnake
_initSnake:
; Snake.speed          = INITIAL_SNAKE_SPEED ;         
       move.l    #2,_Snake+16390.L
; Snake.speed_increase = SNAKE_SPEED_INCREASE;
       move.l    #1,_Snake+16394.L
       rts
; }
; void drawSnake()
; {
       xdef      _drawSnake
_drawSnake:
       movem.l   D2/A2,-(A7)
       lea       _Snake.L,A2
; int i;
; for(i = 0; i < Snake.length; i++)
       clr.l     D2
drawSnake_1:
       cmp.l     16384(A2),D2
       bge.s     drawSnake_3
; {
; putcharxy(Snake.xy[i].x, Snake.xy[i].y,SNAKE);
       pea       83
       move.l    D2,D1
       lsl.l     #3,D1
       lea       0(A2,D1.L),A0
       move.l    4(A0),-(A7)
       move.l    D2,D1
       lsl.l     #3,D1
       move.l    0(A2,D1.L),-(A7)
       jsr       _putcharxy
       add.w     #12,A7
       addq.l    #1,D2
       bra       drawSnake_1
drawSnake_3:
       movem.l   (A7)+,D2/A2
       rts
; }
; }
; void drawFood()
; {
       xdef      _drawFood
_drawFood:
; putcharxy(Snake.food.x, Snake.food.y,FOOD);
       pea       64
       move.l    _Snake+16402.L,-(A7)
       move.l    _Snake+16398.L,-(A7)
       jsr       _putcharxy
       add.w     #12,A7
       rts
; }
; void moveSnake()//remove tail, move array, add new head based on direction
; {
       xdef      _moveSnake
_moveSnake:
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _Snake.L,A2
; int i;
; int x;
; int y;
; x = Snake.xy[0].x;
       move.l    (A2),D3
; y = Snake.xy[0].y;
       move.l    4(A2),D2
; //saves initial head for direction determination
; putcharxy(Snake.xy[Snake.length-1].x, Snake.xy[Snake.length-1].y,' ');
       pea       32
       move.l    16384(A2),D1
       subq.l    #1,D1
       lsl.l     #3,D1
       lea       0(A2,D1.L),A0
       move.l    4(A0),-(A7)
       move.l    16384(A2),D1
       subq.l    #1,D1
       lsl.l     #3,D1
       move.l    0(A2,D1.L),-(A7)
       jsr       _putcharxy
       add.w     #12,A7
; for(i = Snake.length; i > 1; i--)
       move.l    16384(A2),D4
moveSnake_1:
       cmp.l     #1,D4
       ble       moveSnake_3
; {
; Snake.xy[i-1] = Snake.xy[i-2];
       move.l    A2,D0
       move.l    D4,D1
       subq.l    #1,D1
       lsl.l     #3,D1
       add.l     D1,D0
       move.l    D0,A0
       move.l    A2,D0
       move.l    D4,D1
       subq.l    #2,D1
       lsl.l     #3,D1
       add.l     D1,D0
       move.l    D0,A1
       move.l    (A1)+,(A0)+
       move.l    (A1)+,(A0)+
       subq.l    #1,D4
       bra       moveSnake_1
moveSnake_3:
; }
; //moves the snake array to the right
; switch (Snake.direction)
       move.w    16388(A2),D0
       ext.l     D0
       cmp.l     #4,D0
       bhs       moveSnake_4
       asl.l     #1,D0
       move.w    moveSnake_6(PC,D0.L),D0
       jmp       moveSnake_6(PC,D0.W)
moveSnake_6:
       dc.w      moveSnake_7-moveSnake_6
       dc.w      moveSnake_8-moveSnake_6
       dc.w      moveSnake_9-moveSnake_6
       dc.w      moveSnake_10-moveSnake_6
moveSnake_7:
; {
; case north:
; if (y > 0)  { y--; }
       cmp.l     #0,D2
       ble.s     moveSnake_12
       subq.l    #1,D2
moveSnake_12:
; break;
       bra.s     moveSnake_5
moveSnake_8:
; case south:
; if (y < (NUM_VGA_ROWS-1)) { y++; }
       cmp.l     #39,D2
       bge.s     moveSnake_14
       addq.l    #1,D2
moveSnake_14:
; break;
       bra.s     moveSnake_5
moveSnake_9:
; case west:
; if (x > 0) { x--; }
       cmp.l     #0,D3
       ble.s     moveSnake_16
       subq.l    #1,D3
moveSnake_16:
; break;
       bra.s     moveSnake_5
moveSnake_10:
; case east:
; if (x < (NUM_VGA_COLUMNS-1))  { x++; }
       cmp.l     #79,D3
       bge.s     moveSnake_18
       addq.l    #1,D3
moveSnake_18:
; break;
       bra       moveSnake_5
moveSnake_4:
; default:
; break;
moveSnake_5:
; }
; //adds new snake head
; Snake.xy[0].x = x;
       move.l    D3,(A2)
; Snake.xy[0].y = y;
       move.l    D2,4(A2)
; waiting_for_direction_to_be_implemented = 0;
       clr.l     _waiting_for_direction_to_be_imp.L
; putcharxy(Snake.xy[0].x,Snake.xy[0].y,SNAKE);
       pea       83
       move.l    4(A2),-(A7)
       move.l    (A2),-(A7)
       jsr       _putcharxy
       add.w     #12,A7
       movem.l   (A7)+,D2/D3/D4/A2
       rts
; }
; /* Compute x mod y using binary long division. */
; int mod_bld(int x, int y)
; {
       xdef      _mod_bld
_mod_bld:
       link      A6,#0
       movem.l   D2/D3,-(A7)
; int modulus = x, divisor = y;
       move.l    8(A6),D3
       move.l    12(A6),D2
; while (divisor <= modulus && divisor <= 16384)
mod_bld_1:
       cmp.l     D3,D2
       bgt.s     mod_bld_3
       cmp.l     #16384,D2
       bgt.s     mod_bld_3
; divisor <<= 1;
       asl.l     #1,D2
       bra       mod_bld_1
mod_bld_3:
; while (modulus >= y) {
mod_bld_4:
       cmp.l     12(A6),D3
       blt.s     mod_bld_6
; while (divisor > modulus)
mod_bld_7:
       cmp.l     D3,D2
       ble.s     mod_bld_9
; divisor >>= 1;
       asr.l     #1,D2
       bra       mod_bld_7
mod_bld_9:
; modulus -= divisor;
       sub.l     D2,D3
       bra       mod_bld_4
mod_bld_6:
; }
; return modulus;
       move.l    D3,D0
       movem.l   (A7)+,D2/D3
       unlk      A6
       rts
; }
; void generateFood()
; {
       xdef      _generateFood
_generateFood:
       movem.l   D2/D3/A2,-(A7)
       lea       _Snake.L,A2
; int bol;
; int i;
; static int firsttime = 1;
; //removes last food
; if (!firsttime) {
       tst.l     generateFood_firsttime.L
       bne.s     generateFood_2
; putcharxy(Snake.food.x,Snake.food.y,' ');
       pea       32
       move.l    16402(A2),-(A7)
       move.l    16398(A2),-(A7)
       jsr       _putcharxy
       add.w     #12,A7
       bra.s     generateFood_3
generateFood_2:
; } else {
; firsttime = 0;
       clr.l     generateFood_firsttime.L
generateFood_3:
; }
; do
; {
generateFood_4:
; bol = 0;
       clr.l     D3
; //pseudo-randomly set food location
; //use clock instead of random function that is
; //not implemented in ide68k
; Snake.food.x = 3+ mod_bld(((clock()& 0xFFF0) >> 4),screensize.x-6); 
       moveq     #3,D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       move.l    _screensize.L,D0
       subq.l    #6,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       _clock
       move.l    (A7)+,D1
       and.l     #65520,D0
       asr.l     #4,D0
       move.l    D0,-(A7)
       jsr       _mod_bld
       addq.w    #8,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       add.l     D1,D0
       move.l    D0,16398(A2)
; Snake.food.y = 3+ mod_bld(clock()& 0xFFFF,screensize.y-6); 
       moveq     #3,D0
       ext.w     D0
       ext.l     D0
       move.l    D0,-(A7)
       move.l    D0,-(A7)
       move.l    _screensize+4.L,D0
       subq.l    #6,D0
       move.l    D0,-(A7)
       move.l    D1,-(A7)
       jsr       _clock
       move.l    (A7)+,D1
       and.l     #65535,D0
       move.l    D0,-(A7)
       jsr       _mod_bld
       addq.w    #8,A7
       move.l    D0,D1
       move.l    (A7)+,D0
       move.l    (A7)+,D0
       add.l     D1,D0
       move.l    D0,16402(A2)
; for(i = 0; i < Snake.length; i++)
       clr.l     D2
generateFood_6:
       cmp.l     16384(A2),D2
       bge.s     generateFood_8
; {
; if (Snake.food.x == Snake.xy[i].x && Snake.food.y == Snake.xy[i].y) {
       move.l    D2,D0
       lsl.l     #3,D0
       move.l    16398(A2),D1
       cmp.l     0(A2,D0.L),D1
       bne.s     generateFood_9
       move.l    D2,D0
       lsl.l     #3,D0
       lea       0(A2,D0.L),A0
       move.l    16402(A2),D0
       cmp.l     4(A0),D0
       bne.s     generateFood_9
; bol = 1; //resets loop if collision detected
       moveq     #1,D3
generateFood_9:
       addq.l    #1,D2
       bra       generateFood_6
generateFood_8:
       tst.l     D3
       bne       generateFood_4
; }
; }
; } while (bol);//while colliding with snake
; drawFood();
       jsr       _drawFood
       movem.l   (A7)+,D2/D3/A2
       rts
; }
; int getKeypress()
; {
       xdef      _getKeypress
_getKeypress:
       movem.l   A2/A3,-(A7)
       lea       _Snake.L,A2
       lea       _waiting_for_direction_to_be_imp.L,A3
; if (kbhit()) {
       jsr       _kbhit
       tst.l     D0
       beq       getKeypress_4
; switch (_getch())
       jsr       __getch
       cmp.l     #113,D0
       beq       getKeypress_10
       bgt.s     getKeypress_12
       cmp.l     #100,D0
       beq       getKeypress_8
       bgt.s     getKeypress_13
       cmp.l     #97,D0
       beq       getKeypress_7
       bra       getKeypress_3
getKeypress_13:
       cmp.l     #112,D0
       beq       getKeypress_9
       bra       getKeypress_3
getKeypress_12:
       cmp.l     #119,D0
       beq.s     getKeypress_5
       bgt       getKeypress_3
       cmp.l     #115,D0
       beq.s     getKeypress_6
       bra       getKeypress_3
getKeypress_5:
; {
; case 'w':
; if (!waiting_for_direction_to_be_implemented && (Snake.direction != south)){
       tst.l     (A3)
       bne.s     getKeypress_14
       move.w    16388(A2),D0
       ext.l     D0
       cmp.l     #1,D0
       beq.s     getKeypress_14
; Snake.direction = north;
       clr.w     16388(A2)
; waiting_for_direction_to_be_implemented = 1;
       move.l    #1,(A3)
getKeypress_14:
; }
; break;
       bra       getKeypress_4
getKeypress_6:
; case 's':
; if (!waiting_for_direction_to_be_implemented && (Snake.direction != north)){
       tst.l     (A3)
       bne.s     getKeypress_16
       move.w    16388(A2),D0
       ext.l     D0
       tst.l     D0
       beq.s     getKeypress_16
; Snake.direction = south;
       move.w    #1,16388(A2)
; waiting_for_direction_to_be_implemented = 1;
       move.l    #1,(A3)
getKeypress_16:
; }
; break;
       bra       getKeypress_4
getKeypress_7:
; case 'a':
; if (!waiting_for_direction_to_be_implemented && (Snake.direction != east)){
       tst.l     (A3)
       bne.s     getKeypress_18
       move.w    16388(A2),D0
       ext.l     D0
       cmp.l     #3,D0
       beq.s     getKeypress_18
; Snake.direction = west;
       move.w    #2,16388(A2)
; waiting_for_direction_to_be_implemented = 1;
       move.l    #1,(A3)
getKeypress_18:
; }
; break;
       bra.s     getKeypress_4
getKeypress_8:
; case 'd':
; if (!waiting_for_direction_to_be_implemented && (Snake.direction != west)){
       tst.l     (A3)
       bne.s     getKeypress_20
       move.w    16388(A2),D0
       ext.l     D0
       cmp.l     #2,D0
       beq.s     getKeypress_20
; Snake.direction = east;
       move.w    #3,16388(A2)
; waiting_for_direction_to_be_implemented = 1;
       move.l    #1,(A3)
getKeypress_20:
; }
; break;
       bra.s     getKeypress_4
getKeypress_9:
; case 'p':
; _getch();
       jsr       __getch
; break;
       bra.s     getKeypress_4
getKeypress_10:
; case 'q':
; gameOver();
       jsr       _gameOver
; return 0;
       clr.l     D0
       bra.s     getKeypress_22
getKeypress_3:
; default:
; //do nothing
; break;
getKeypress_4:
; }
; }
; return 1;
       moveq     #1,D0
getKeypress_22:
       movem.l   (A7)+,A2/A3
       rts
; }
; int detectCollision()//with self -> game over, food -> delete food add score (only head checks)
; // returns 0 for no collision, 1 for game over
; {
       xdef      _detectCollision
_detectCollision:
       movem.l   D2/D3/A2,-(A7)
       lea       _Snake.L,A2
; int i;
; int retval;
; retval = 0;
       clr.l     D3
; if (Snake.xy[0].x == Snake.food.x && Snake.xy[0].y == Snake.food.y) {
       move.l    (A2),D0
       cmp.l     16398(A2),D0
       bne       detectCollision_1
       move.l    4(A2),D0
       cmp.l     16402(A2),D0
       bne       detectCollision_1
; //detect collision with food
; Snake.length++;
       move.l    A2,D0
       add.l     #16384,D0
       move.l    D0,A0
       addq.l    #1,(A0)
; Snake.xy[Snake.length-1].x = Snake.xy[Snake.length-2].x;
       move.l    16384(A2),D0
       subq.l    #2,D0
       lsl.l     #3,D0
       move.l    16384(A2),D1
       subq.l    #1,D1
       lsl.l     #3,D1
       move.l    0(A2,D0.L),0(A2,D1.L)
; Snake.xy[Snake.length-1].y = Snake.xy[Snake.length-2].y;
       move.l    16384(A2),D0
       subq.l    #2,D0
       lsl.l     #3,D0
       lea       0(A2,D0.L),A0
       move.l    16384(A2),D0
       subq.l    #1,D0
       lsl.l     #3,D0
       lea       0(A2,D0.L),A1
       move.l    4(A0),4(A1)
; Snake.speed = Snake.speed + Snake.speed_increase;
       move.l    16390(A2),D0
       add.l     16394(A2),D0
       move.l    D0,16390(A2)
; generateFood();
       jsr       _generateFood
; score++;
       addq.l    #1,_score.L
; updateScore();
       jsr       _updateScore
detectCollision_1:
; }
; for(i = 2; i < Snake.length; i++)
       moveq     #2,D2
detectCollision_3:
       cmp.l     16384(A2),D2
       bge.s     detectCollision_5
; {
; //detects collision of the head
; if (Snake.xy[i].x == Snake.xy[0].x && Snake.xy[i].y == Snake.xy[0].y) {
       move.l    D2,D0
       lsl.l     #3,D0
       move.l    0(A2,D0.L),D1
       cmp.l     (A2),D1
       bne.s     detectCollision_6
       move.l    D2,D0
       lsl.l     #3,D0
       lea       0(A2,D0.L),A0
       move.l    4(A0),D0
       cmp.l     4(A2),D0
       bne.s     detectCollision_6
; gameOver();
       jsr       _gameOver
; retval = 1;
       moveq     #1,D3
detectCollision_6:
       addq.l    #1,D2
       bra       detectCollision_3
detectCollision_5:
; }
; }
; if (Snake.xy[0].x == 1 || Snake.xy[0].x == (screensize.x-1) || Snake.xy[0].y == 1 || Snake.xy[0].y == (screensize.y-2)) {
       move.l    (A2),D0
       cmp.l     #1,D0
       beq.s     detectCollision_10
       move.l    _screensize.L,D0
       subq.l    #1,D0
       cmp.l     (A2),D0
       beq.s     detectCollision_10
       move.l    4(A2),D0
       cmp.l     #1,D0
       beq.s     detectCollision_10
       move.l    _screensize+4.L,D0
       subq.l    #2,D0
       cmp.l     4(A2),D0
       bne.s     detectCollision_8
detectCollision_10:
; //collision with wall
; gameOver();
       jsr       _gameOver
; retval = 1;
       moveq     #1,D3
detectCollision_8:
; }
; return retval;
       move.l    D3,D0
       movem.l   (A7)+,D2/D3/A2
       rts
; }
; void mainloop()
; {
       xdef      _mainloop
_mainloop:
       link      A6,#-4
       move.l    D2,-(A7)
; int current_time;
; int got_game_over;
; while(1){    
mainloop_1:
; if (!getKeypress()) {
       jsr       _getKeypress
       tst.l     D0
       bne.s     mainloop_4
; return;
       bra       mainloop_3
mainloop_4:
; }
; current_time = clock();
       jsr       _clock
       move.l    D0,D2
; if (current_time >= ((MILLISECONDS_PER_SEC/Snake.speed) + timer)) {
       pea       1000
       move.l    _Snake+16390.L,-(A7)
       jsr       LDIV
       move.l    (A7),D0
       addq.w    #8,A7
       add.l     _timer.L,D0
       cmp.l     D0,D2
       blt.s     mainloop_7
; moveSnake(); //draws new snake position
       jsr       _moveSnake
; got_game_over = detectCollision();
       jsr       _detectCollision
       move.l    D0,-4(A6)
; if (got_game_over) {
       tst.l     -4(A6)
       beq.s     mainloop_9
; break;
       bra.s     mainloop_3
mainloop_9:
; }
; timer = current_time;
       move.l    D2,_timer.L
mainloop_7:
       bra       mainloop_1
mainloop_3:
       move.l    (A7)+,D2
       unlk      A6
       rts
; }
; }
; }
; void snake_main()
; {
       xdef      _snake_main
_snake_main:
       move.l    A2,-(A7)
       lea       _Snake.L,A2
; score = 0;
       clr.l     _score.L
; waiting_for_direction_to_be_implemented = 0;
       clr.l     _waiting_for_direction_to_be_imp.L
; Snake.xy[0].x = 4;
       move.l    #4,(A2)
; Snake.xy[0].y = 3;
       move.l    #3,4(A2)
; Snake.xy[1].x = 3;
       move.l    #3,8(A2)
; Snake.xy[1].y = 3;
       move.l    #3,12(A2)
; Snake.xy[2].x = 2;
       move.l    #2,16(A2)
; Snake.xy[2].y = 3;
       move.l    #3,20(A2)
; Snake.length = INITIAL_SNAKE_LENGTH;
       move.l    #3,16384(A2)
; Snake.direction = east;
       move.w    #3,16388(A2)
; initSnake();
       jsr       _initSnake
; initTimer();
       jsr       _initTimer
; cls();
       jsr       _cls
; drawRect(1,1,screensize.x-1,screensize.y-2, BORDER);
       pea       35
       move.l    _screensize+4.L,D1
       subq.l    #2,D1
       move.l    D1,-(A7)
       move.l    _screensize.L,D1
       subq.l    #1,D1
       move.l    D1,-(A7)
       pea       1
       pea       1
       jsr       _drawRect
       add.w     #20,A7
; drawSnake();
       jsr       _drawSnake
; generateFood();
       jsr       _generateFood
; drawFood();
       jsr       _drawFood
; timer = clock();
       jsr       _clock
       move.l    D0,_timer.L
; updateScore();
       jsr       _updateScore
; mainloop();
       jsr       _mainloop
       move.l    (A7)+,A2
       rts
; }
       section   const
@snake_1:
       dc.b      71,97,109,101,32,79,118,101,114,33,0
@snake_2:
       dc.b      83,99,111,114,101,58,32,0
@snake_3:
       dc.b      37,100,0
       xdef      _screensize
_screensize:
       dc.l      80,40
       section   data
generateFood_firsttime:
       dc.l      1
       section   bss
       xdef      _score
_score:
       ds.b      4
       xdef      _timer
_timer:
       ds.b      4
       xdef      _Timer8ISRCount
_Timer8ISRCount:
       ds.b      4
       xdef      _Snake
_Snake:
       ds.b      16406
       xdef      _waiting_for_direction_to_be_imp
_waiting_for_direction_to_be_imp:
       ds.b      4
       xref      LDIV
       xref      LMUL
       xref      _strlen
       xref      ULMUL
       xref      _kbhit
       xref      _sprintf
       xref      _InstallExceptionHandler
       xref      __getch
