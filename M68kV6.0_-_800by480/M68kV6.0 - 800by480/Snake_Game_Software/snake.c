#include <stdio.h>
#include <stdlib.h>
#include <limits.h>
#include <string.h>
#include "snake.h"

int score;
int timer;
unsigned long long Timer8ISRCount;

struct
{
    coord_t xy[SNAKE_LENGTH_LIMIT];
    int length;
    dir_t direction;
    int speed;
    int speed_increase;
    coord_t food;
} Snake;

const coord_t screensize = {NUM_VGA_COLUMNS,NUM_VGA_ROWS};

int waiting_for_direction_to_be_implemented;


/////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//                        functions to implement
//
//
/////////////////////////////////////////////////////////////////////////////////////////////////////


void putcharxy(int x, int y, char ch) {
	//display on the VGA char ch at column x, line y
    //00F0 0000 - 00F0 FFFF
    unsigned char * pointer = VGA_START;
    pointer = pointer + (NUM_VGA_COLUMNS * y + x);

    *pointer = (unsigned char)ch;
}

void print_at_xy(int x, int y, const char* str) {
	//print a string on the VGA, starting at column x, line y. 
	//Wrap around to the next line if we reach the edge of the screen
    
    int i, j, len;
    char ch;

    len = strlen(str);
    for(i = 0; i < len; i++){
        ch = str[i];

        putcharxy(x, y, ch);
        if(x == (NUM_VGA_COLUMNS - 1)){
            x = 0;
            y++;
        }else{
            x++;
        }
    }

}

void cls()
{
	//clear the screen
    int x,y;

    for(x = 0; x < NUM_VGA_COLUMNS; x++){
        for(y = 0; y < NUM_VGA_ROWS; y++){
            putcharxy(x, y, ' ');
        }
    }
};


void gotoxy(int x, int y)
{
	//move the cursor to location column = x, row = y
    unsigned char * x_ptr = VGA_ocrx;
    unsigned char * y_ptr = VGA_ocry;

    *x_ptr = x;
    *y_ptr = y;
}

void set_vga_control_reg(char x) 
{
	//Set the VGA control (OCTL) value
    unsigned char * octl_ptr = VGA_octl;

    *octl_ptr = x;
}

char get_vga_control_reg()
{
	//return the VGA control (OCTL) value
    unsigned char * octl_ptr = VGA_octl;

    return *octl_ptr;
}

int clock() {
	//return the current value of a milliseconds counter, with a resolution of 10ms or better
    return (Timer8ISRCount * 10);
}

void Timer_IRQ()
{
    if (Timer8Status == 1) {        
        Timer8Control = 3;      	
        PortC = Timer8ISRCount++;
    }
}

void initTimer(){
    //initialize parameters for timer
    Timer8ISRCount = 0;
    InstallExceptionHandler(Timer_IRQ, 30);
    Timer8Data = 0x03;
    Timer8Control = 3;
}

void delay_ms(int num_ms) {
	//delay a certain number of milliseconds
    int i;
    for(i = 0; i < 75 * num_ms; i++);
}

void gameOver()
{
    int i, j, z, len;
    int x, y;
    char ch;
    char score_string[3];

    const char* str = "Game Over!";
    x = 35;
    y = 19;
    
    cls();
    set_vga_control_reg(0xE4);

    gotoxy(x+1,y); //Commented out due to bug, it breaks entire game

    len = strlen(str);
    for(i = 0; i < len; i++){
        ch = str[i];

        putcharxy(x, y, ch);
        delay_ms(100);

        gotoxy(x+1,y); //Commented out due to bug, it breaks entire game

        if(x == (NUM_VGA_COLUMNS - 1)){
            x = 0;
            y++;
        }else{
            x++;
        }
    }

    str = "Score: ";
    x = 35;
    y = 20;

    len = strlen(str);
    for(i = 0; i < len; i++){
        ch = str[i];

        putcharxy(x, y, ch);

        delay_ms(100);

        gotoxy(x+1,y); //Commented out due to bug, it breaks entire game

        if(x == (NUM_VGA_COLUMNS - 1)){
            x = 0;
            y++;
        }else{
            x++;
        }
    }

    sprintf(score_string, "%d", score);

    len = strlen(score_string);
    for(i = 0; i < len; i++){
        ch = score_string[i];

        putcharxy(x, y, ch);

        delay_ms(100);

        gotoxy(x+1,y); //Commented out due to bug, it breaks entire game

        if(x == (NUM_VGA_COLUMNS - 1)){
            x = 0;
            y++;
        }else{
            x++;
        }
    }

    while(!(kbhit())){
        for(z = 0; z < 6; z++){
            if(z == 0){
                set_vga_control_reg(0xE1);
            }else if(z == 1){
                set_vga_control_reg(0xE3);
            }else if(z == 2){
                set_vga_control_reg(0xE4);
            }else if(z == 3){
                set_vga_control_reg(0xE5);
            }else if(z == 4){
                set_vga_control_reg(0xE6);
            }else if(z == 5){
                set_vga_control_reg(0xE7);
            }else{
                set_vga_control_reg(0xE2);
            }

            str = "Game Over!";
            x = 35;
            y = 19;
            
            cls();

            len = strlen(str);
            for(i = 0; i < len; i++){
                ch = str[i];

                putcharxy(x, y, ch);

                if(x == (NUM_VGA_COLUMNS - 1)){
                    x = 0;
                    y++;
                }else{
                    x++;
                }
            }

            str = "Score: ";
            x = 35;
            y = 20;

            len = strlen(str);
            for(i = 0; i < len; i++){
                ch = str[i];

                putcharxy(x, y, ch);

                if(x == (NUM_VGA_COLUMNS - 1)){
                    x = 0;
                    y++;
                }else{
                    x++;
                }
            }

            sprintf(score_string, "%d", score);

            len = strlen(score_string);
            for(i = 0; i < len; i++){
                ch = score_string[i];

                putcharxy(x, y, ch);

                if(x == (NUM_VGA_COLUMNS - 1)){
                    x = 0;
                    y++;
                }else{
                    x++;
                }
            }

            gotoxy(x+1,y); //Commented out due to bug, it breaks entire game
        
            delay_ms(250);
        }
    }

    set_vga_control_reg(0xF2);
}

void updateScore() ///////////////////////////////////////
{
	//print the score at the bottom of the screen
    int i, x, y, len, offset;
    char ch;
    char score_string[3];

    x = 1;
    y = 39;

    print_at_xy(x, y, "Score: ");
    
    sprintf(score_string, "%d", score);

    len = strlen(score_string);
    offset = strlen("Score: ");
    x+=offset;

    for(i = 0; i < len; i++){
        ch = score_string[i];

        putcharxy(x, y, ch);
        if(x == (NUM_VGA_COLUMNS - 1)){
            x = 0;
            y++;
        }else{
            x++;
        }
    }
}

void drawRect(int x, int y, int x2, int y2, char ch)
{
    //draws a rectangle. Left top corner: (x1,y1) length of sides = x2,y2
    //drawRect(1,1,79,38, BORDER);
    int i;

    set_vga_control_reg(0xB2);

    for(i = y; i <= y2; i++){
        putcharxy(x, i, ch);
        putcharxy(x2, i, ch);
    }

    for(i = x; i <= x2; i++){
        putcharxy(i, y, ch);
        putcharxy(i, y2, ch);
    }
}

/////////////////////////////////////////////////////////////////////////////
//
//  End functions you need to implement
//
/////////////////////////////////////////////////////////////////////////////

void initSnake()
{
    Snake.speed          = INITIAL_SNAKE_SPEED ;         
    Snake.speed_increase = SNAKE_SPEED_INCREASE;
}

void drawSnake()
{
    int i;
    for(i = 0; i < Snake.length; i++)
    {
       	putcharxy(Snake.xy[i].x, Snake.xy[i].y,SNAKE);
    }
}

void drawFood()
{
    putcharxy(Snake.food.x, Snake.food.y,FOOD);
}

void moveSnake()//remove tail, move array, add new head based on direction
{
int i;
int x;
int y;
    x = Snake.xy[0].x;
    y = Snake.xy[0].y;
    //saves initial head for direction determination

    putcharxy(Snake.xy[Snake.length-1].x, Snake.xy[Snake.length-1].y,' ');

    for(i = Snake.length; i > 1; i--)
    {
        Snake.xy[i-1] = Snake.xy[i-2];
    }
    //moves the snake array to the right

    switch (Snake.direction)
    {
        case north:
            if (y > 0)  { y--; }
            break;
        case south:
            if (y < (NUM_VGA_ROWS-1)) { y++; }
            break;
        case west:
            if (x > 0) { x--; }
            break;
        case east:
            if (x < (NUM_VGA_COLUMNS-1))  { x++; }
            break;
        default:
            break;
    }
    //adds new snake head
    Snake.xy[0].x = x;
    Snake.xy[0].y = y;

    waiting_for_direction_to_be_implemented = 0;
    putcharxy(Snake.xy[0].x,Snake.xy[0].y,SNAKE);
}

/* Compute x mod y using binary long division. */
int mod_bld(int x, int y)
{
    int modulus = x, divisor = y;

    while (divisor <= modulus && divisor <= 16384)
        divisor <<= 1;

    while (modulus >= y) {
        while (divisor > modulus)
            divisor >>= 1;
        modulus -= divisor;
    }

    return modulus;
}

void generateFood()
{
    int bol;
    int i;
	static int firsttime = 1;

	//removes last food
    if (!firsttime) {
         putcharxy(Snake.food.x,Snake.food.y,' ');
	} else {
	     firsttime = 0;
	}

    do
    {
        bol = 0;
		
		//pseudo-randomly set food location
		//use clock instead of random function that is
		//not implemented in ide68k
		
        Snake.food.x = 3+ mod_bld(((clock()& 0xFFF0) >> 4),screensize.x-6); 
        Snake.food.y = 3+ mod_bld(clock()& 0xFFFF,screensize.y-6); 
        for(i = 0; i < Snake.length; i++)
        {
            if (Snake.food.x == Snake.xy[i].x && Snake.food.y == Snake.xy[i].y) {
                bol = 1; //resets loop if collision detected
            }

        }

    } while (bol);//while colliding with snake
    drawFood();

}

int getKeypress()
{
    if (kbhit()) {
        switch (_getch())
        {
            case 'w':
                if (!waiting_for_direction_to_be_implemented && (Snake.direction != south)){
				Snake.direction = north;
				waiting_for_direction_to_be_implemented = 1;
				}
                break;
            case 's':
                if (!waiting_for_direction_to_be_implemented && (Snake.direction != north)){
				Snake.direction = south;
				waiting_for_direction_to_be_implemented = 1;
				}
                break;
            case 'a':
                if (!waiting_for_direction_to_be_implemented && (Snake.direction != east)){
				Snake.direction = west;
				waiting_for_direction_to_be_implemented = 1;
                }
                break;
            case 'd':
                if (!waiting_for_direction_to_be_implemented && (Snake.direction != west)){
				 Snake.direction = east;
				 waiting_for_direction_to_be_implemented = 1;
                }
                break;
            case 'p':
                _getch();
                break;
            case 'q':
                gameOver();
                return 0;
            default:
                //do nothing
                break;
        }
    }
    return 1;
}

int detectCollision()//with self -> game over, food -> delete food add score (only head checks)
                     // returns 0 for no collision, 1 for game over
{
    int i;
	int retval;
	retval = 0;
    if (Snake.xy[0].x == Snake.food.x && Snake.xy[0].y == Snake.food.y) {
	    //detect collision with food
        Snake.length++;
		Snake.xy[Snake.length-1].x = Snake.xy[Snake.length-2].x;
		Snake.xy[Snake.length-1].y = Snake.xy[Snake.length-2].y;
        Snake.speed = Snake.speed + Snake.speed_increase;
        generateFood();
        score++;
        updateScore();
    }

    for(i = 2; i < Snake.length; i++)
    {
	    //detects collision of the head
        if (Snake.xy[i].x == Snake.xy[0].x && Snake.xy[i].y == Snake.xy[0].y) {
            gameOver();
			retval = 1;
        }

    }

    if (Snake.xy[0].x == 1 || Snake.xy[0].x == (screensize.x-1) || Snake.xy[0].y == 1 || Snake.xy[0].y == (screensize.y-2)) {
	    //collision with wall
        gameOver();
		retval = 1;
    }
	return retval;
}



void mainloop()
{
	int current_time;
	int got_game_over;

    while(1){    
        if (!getKeypress()) {
            return;
        }

		current_time = clock();

        if (current_time >= ((MILLISECONDS_PER_SEC/Snake.speed) + timer)) {
            moveSnake(); //draws new snake position
            got_game_over = detectCollision();
			if (got_game_over) {
			   break;
			}

            timer = current_time;
        }
    }
}

void snake_main()
{
	score = 0;
	waiting_for_direction_to_be_implemented = 0;
   	Snake.xy[0].x = 4;
    Snake.xy[0].y = 3;
    Snake.xy[1].x = 3;
    Snake.xy[1].y = 3;
    Snake.xy[2].x = 2;
    Snake.xy[2].y = 3;
    Snake.length = INITIAL_SNAKE_LENGTH;
    Snake.direction = east;
    initSnake();
    initTimer();
	cls();
    drawRect(1,1,screensize.x-1,screensize.y-2, BORDER);
    drawSnake();
    generateFood();
    drawFood();
    timer = clock();
	updateScore();
    mainloop();
}