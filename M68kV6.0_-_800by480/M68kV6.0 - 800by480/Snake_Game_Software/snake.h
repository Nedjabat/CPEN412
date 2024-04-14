
#define NUM_VGA_COLUMNS   (80)
#define NUM_VGA_ROWS      (40)
#define BORDER '#'
#define FOOD '@'
#define SNAKE 'S'
#define INITIAL_SNAKE_SPEED (2)
#define INITIAL_SNAKE_LENGTH (3)
#define SNAKE_SPEED_INCREASE (1)
#define SNAKE_LENGTH_LIMIT (2048)
#define MILLISECONDS_PER_SEC (1000)

/*********************************************************************************************
**	VGA addresses
*********************************************************************************************/
#define VGA_START (0x00F00000)
#define VGA_END (0x00F0FFFF)

#define VGA_ocrx (0x00F0F012)
#define VGA_ocry (0x00F0F022)
#define VGA_octl (0x00F0F044)

/**********************************************************************************************
**	Parallel port addresses
**********************************************************************************************/

#define PortA   *(volatile unsigned char *)(0x00400000)
#define PortB   *(volatile unsigned char *)(0x00400002)
#define PortC   *(volatile unsigned char *)(0x00400004)
#define PortD   *(volatile unsigned char *)(0x00400006)
#define PortE   *(volatile unsigned char *)(0x00400008)

/*********************************************************************************************
**	Timer Port Addresses
*********************************************************************************************/
#define Timer8Data      *(volatile unsigned char *)(0x0040013C)
#define Timer8Control   *(volatile unsigned char *)(0x0040013E)
#define Timer8Status    *(volatile unsigned char *)(0x0040013E)

/*********************************************************************************************
**	RS232 port addresses
*********************************************************************************************/

#define RS232_Control     *(volatile unsigned char *)(0x00400040)
#define RS232_Status      *(volatile unsigned char *)(0x00400040)
#define RS232_TxData      *(volatile unsigned char *)(0x00400042)
#define RS232_RxData      *(volatile unsigned char *)(0x00400042)
#define RS232_Baud        *(volatile unsigned char *)(0x00400044)

typedef struct {
    int x;
    int y;
} coord_t;

typedef enum {north, south, west, east} dir_t;