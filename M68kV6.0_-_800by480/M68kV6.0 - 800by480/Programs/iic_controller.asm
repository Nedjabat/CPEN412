; C:\CPEN412\ASN5\IIC_CONTROLLER.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; #include <stdio.h>
; /*************************************************************
; ** I2C Controller registers
; **************************************************************/
; // I2C Registers
; #define I2C_Clock_PrerLo (*(volatile unsigned char *)(0x00408000))
; #define I2C_Clock_PrerHi (*(volatile unsigned char *)(0x00408002))
; #define I2C_Control (*(volatile unsigned char *)(0x00408004))
; #define I2C_Transmit (*(volatile unsigned char *)(0x00408006))
; #define I2C_Receive (*(volatile unsigned char *)(0x00408006))
; #define I2C_Command (*(volatile unsigned char *)(0x00408008))
; #define I2C_Status (*(volatile unsigned char *)(0x00408008))
; /************************************************************************************/
; /*************************************************************
; ** I2C Commands
; **************************************************************/
; // I2C Commands
; #define I2C_Slave_Write_Start_Command 0x91  //1001 0001
; #define I2C_Slave_Read_Start_Command 0xA9   //1010 1001
; #define I2C_Slave_Write_Stop_Command 0x51   //0101 0001
; #define I2C_Slave_Read_Stop_Command 0x69    //0110 1001
; #define I2C_Slave_Write_Command 0x11        //0001 0001
; #define I2C_Slave_Read_Command 0x21         //0010 1001
; /************************************************************************************/
; /*************************************************************
; ** EEPROM Commands
; **************************************************************/
; // EEPROM Commands
; #define EEPROM_READ_HI_BLK 0xA3     //1010 0011
; #define EEPROM_READ_LO_BLK 0xA1     //1010 0001
; #define EEPROM_WRITE_HI_BLK 0xA2    //1010 0010
; #define EEPROM_WRITE_LO_BLK 0xA0    //1010 0000
; /************************************************************************************/
; /*************************************************************
; ** ADC/DAC Commands
; **************************************************************/
; // ADC/DAC Commands
; #define ADC_DAC_WRITE_ADDRESS 0x92      //1001 0010
; #define DAC_ENABLE_COMMAND 0x40         //0100 0000
; #define ADC_ENABLE_COMMAND 0x44         //0100 0100
; #define ADC_READ_ADDRESS 0x93           //1001 0011
; /************************************************************************************/
; /************************************************************************************
; ** 
; This register is used to prescale the SCL clock line. Due to the structure of the I2C
; interface, the core uses a 5*SCL clock internally. The prescale register must be
; programmed to this 5*SCL frequency (minus 1). Change the value of the prescale
; register only when the ‘EN’ bit is cleared.
; The core responds to new commands only when the ‘EN’ bit is set. Pending commands
; are finished. Clear the ‘EN’ bit only when no transfer is in progress, i.e. after a STOP
; command, or when the command register has the STO bit set. When halted during a
; transfer, the core can hang the I2
; C bus. 
; for 25Mhz, 100KHz SCL Clock line 
; ************************************************************************************/
; #define Enable_I2C_CS() I2C_Control = 0x80 // 0x80 | 1000 0000 | 00xx xxxx
; /***********************************************************************************/
; /************************************************************************************
; ** Subfunctions for I2C
; ************************************************************************************/
; void Enable_SCL_Clock(void){
       section   code
       xdef      _Enable_SCL_Clock
_Enable_SCL_Clock:
; I2C_Clock_PrerLo = 0x31;
       move.b    #49,4227072
; I2C_Clock_PrerHi = 0x00;
       clr.b     4227074
; return;
       rts
; }
; void WaitForI2C_TIP(void){
       xdef      _WaitForI2C_TIP
_WaitForI2C_TIP:
       link      A6,#-4
; int TIP_bit;
; do{
WaitForI2C_TIP_1:
; TIP_bit = (I2C_Status >> 1) & 0x01; 
       move.b    4227080,D0
       and.l     #255,D0
       lsr.l     #1,D0
       and.l     #1,D0
       move.l    D0,-4(A6)
       move.l    -4(A6),D0
       bne       WaitForI2C_TIP_1
; }while(TIP_bit != 0);
; return;
       unlk      A6
       rts
; }
; void WaitForI2C_RxACK(void){
       xdef      _WaitForI2C_RxACK
_WaitForI2C_RxACK:
       link      A6,#-4
; int RxACK_bit;
; do{
WaitForI2C_RxACK_1:
; RxACK_bit = (I2C_Status >> 7) & 0x01;
       move.b    4227080,D0
       and.l     #255,D0
       lsr.l     #7,D0
       and.l     #1,D0
       move.l    D0,-4(A6)
       move.l    -4(A6),D0
       bne       WaitForI2C_RxACK_1
; }while(RxACK_bit != 0);
; return;
       unlk      A6
       rts
; }
; /************************************************************************************
; ** initialises the I2C controller 
; ************************************************************************************/
; void I2C_Init(void){
       xdef      _I2C_Init
_I2C_Init:
; //Enabling 100Khz SCL Clock Line
; Enable_SCL_Clock();
       jsr       _Enable_SCL_Clock
; //Enabling I2C for no interupts and enabling core
; Enable_I2C_CS();
       move.b    #128,4227076
; return;
       rts
; }
; /************************************************************************************
; ** Write with I2C (byte)
; ************************************************************************************/
; void WriteI2CInteraction(int block, unsigned int Address, unsigned char AddressMSB, unsigned char AddressLSB, unsigned char c, int flag){
       xdef      _WriteI2CInteraction
_WriteI2CInteraction:
       link      A6,#0
       movem.l   D2/A2/A3,-(A7)
       lea       _WaitForI2C_TIP.L,A2
       lea       _WaitForI2C_RxACK.L,A3
; //////////////////////////////Control Byte//////////////////////////////
; unsigned char controlByte;
; if(block == 1){
       move.l    8(A6),D0
       cmp.l     #1,D0
       bne.s     WriteI2CInteraction_1
; controlByte = EEPROM_WRITE_HI_BLK;
       move.b    #162,D2
       bra.s     WriteI2CInteraction_2
WriteI2CInteraction_1:
; }else{
; controlByte = EEPROM_WRITE_LO_BLK;
       move.b    #160,D2
WriteI2CInteraction_2:
; }
; //Wait for TIP and RxACK bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Send data to Transmit register
; I2C_Transmit = controlByte;
       move.b    D2,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //////////////////////////////MSB of Address//////////////////////////////
; //Send data to Transmit register
; I2C_Transmit = AddressMSB;
       move.b    19(A6),4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; ////////////////////////////LSB of Address////////////////////////////////
; //Send data to Transmit register
; I2C_Transmit = AddressLSB;
       move.b    23(A6),4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //////////////////////////////Data//////////////////////////////
; //Send data to Transmit register
; I2C_Transmit = c;
       move.b    27(A6),4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Stop_Command;
       move.b    #81,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; if(flag == 0){
       move.l    28(A6),D0
       bne.s     WriteI2CInteraction_3
; printf("\r\nWrote [%x] to Address[%x]", c, Address);
       move.l    12(A6),-(A7)
       move.b    27(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @iic_co~1_1.L
       jsr       _printf
       add.w     #12,A7
WriteI2CInteraction_3:
; }
; return;
       movem.l   (A7)+,D2/A2/A3
       unlk      A6
       rts
; }
; /************************************************************************************
; ** Write with I2C (Page)
; ************************************************************************************/
; void PageWriteI2CInteraction(unsigned int AddressFrom, unsigned int AddressTo, unsigned char c){
       xdef      _PageWriteI2CInteraction
_PageWriteI2CInteraction:
       link      A6,#-8
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3/A4/A5,-(A7)
       move.l    8(A6),D2
       lea       _WaitForI2C_TIP.L,A2
       lea       _WaitForI2C_RxACK.L,A3
       move.b    19(A6),D7
       and.l     #255,D7
       move.l    12(A6),A4
; int flag = 0;
       move.w    #0,A5
; int flag_special = 0;
       clr.l     -8(A6)
; int i = 0;
       clr.l     D3
; unsigned char controlByte;
; unsigned char AddressFromMSB, AddressFromLSB;
; unsigned int AddressFrom_Initial;
; AddressFrom_Initial = AddressFrom;
       move.l    D2,-4(A6)
; while(AddressFrom < AddressTo){
PageWriteI2CInteraction_1:
       cmp.l     A4,D2
       bhs       PageWriteI2CInteraction_3
; if(AddressFrom + 128 > AddressTo){
       move.l    D2,D0
       add.l     #128,D0
       cmp.l     A4,D0
       bls.s     PageWriteI2CInteraction_4
; flag = 1;
       move.w    #1,A5
PageWriteI2CInteraction_4:
; }
; if(AddressFrom > 63999){
       cmp.l     #63999,D2
       bls.s     PageWriteI2CInteraction_6
; controlByte = EEPROM_WRITE_HI_BLK;
       move.b    #162,D6
; AddressFromMSB = ((AddressFrom - 0xFA00) >> 8) & 0xFF;
       move.l    D2,D0
       sub.l     #64000,D0
       lsr.l     #8,D0
       and.l     #255,D0
       move.b    D0,D5
; AddressFromLSB = (AddressFrom - 0xFA00) & 0xFF;         
       move.l    D2,D0
       sub.l     #64000,D0
       and.l     #255,D0
       move.b    D0,D4
       bra.s     PageWriteI2CInteraction_7
PageWriteI2CInteraction_6:
; }else{
; controlByte = EEPROM_WRITE_LO_BLK;
       move.b    #160,D6
; AddressFromMSB = (AddressFrom >> 8) & 0xFF;
       move.l    D2,D0
       lsr.l     #8,D0
       and.l     #255,D0
       move.b    D0,D5
; AddressFromLSB = AddressFrom & 0xFF;
       move.l    D2,D0
       and.l     #255,D0
       move.b    D0,D4
PageWriteI2CInteraction_7:
; }
; //Wait for TIP and RxACK bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Send data to Transmit register
; I2C_Transmit = controlByte;
       move.b    D6,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Send data to Transmit register
; I2C_Transmit = AddressFromMSB;
       move.b    D5,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Send data to Transmit register
; I2C_Transmit = AddressFromLSB;
       move.b    D4,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; if(flag == 0){
       move.l    A5,D0
       bne       PageWriteI2CInteraction_8
; for(i = 0; i < 128; i++){
       clr.l     D3
PageWriteI2CInteraction_10:
       cmp.l     #128,D3
       bge       PageWriteI2CInteraction_12
; //Send data to Transmit register
; I2C_Transmit = c;
       move.b    D7,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; if((AddressFrom + i) % 128 == 0){
       move.l    D2,D0
       add.l     D3,D0
       move.l    D0,-(A7)
       pea       128
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     PageWriteI2CInteraction_13
; break;
       bra.s     PageWriteI2CInteraction_12
PageWriteI2CInteraction_13:
; }
; //Checking if required to switch blocks
; if(AddressFrom + i == 63999){
       move.l    D2,D0
       add.l     D3,D0
       cmp.l     #63999,D0
       bne.s     PageWriteI2CInteraction_15
; break;
       bra.s     PageWriteI2CInteraction_12
PageWriteI2CInteraction_15:
       addq.l    #1,D3
       bra       PageWriteI2CInteraction_10
PageWriteI2CInteraction_12:
; }
; }
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Stop_Command;
       move.b    #81,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; do{
PageWriteI2CInteraction_17:
; I2C_Transmit = controlByte;
       move.b    D6,4227078
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; WaitForI2C_TIP();
       jsr       (A2)
       move.b    4227080,D0
       lsr.b     #7,D0
       and.b     #1,D0
       bne       PageWriteI2CInteraction_17
       bra       PageWriteI2CInteraction_9
PageWriteI2CInteraction_8:
; }while(((I2C_Status >> 7) & 0x01) != 0);
; }else{
; for(i = 0; i < ((AddressTo - AddressFrom)); i++){
       clr.l     D3
PageWriteI2CInteraction_19:
       move.l    A4,D0
       sub.l     D2,D0
       cmp.l     D0,D3
       bhs       PageWriteI2CInteraction_21
; //Send data to Transmit register
; I2C_Transmit = c;
       move.b    D7,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; if((AddressFrom + i) % 128 == 0){
       move.l    D2,D0
       add.l     D3,D0
       move.l    D0,-(A7)
       pea       128
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne.s     PageWriteI2CInteraction_22
; break;
       bra.s     PageWriteI2CInteraction_21
PageWriteI2CInteraction_22:
; }
; //Checking if required to switch blocks
; if(AddressFrom + i == 63999){
       move.l    D2,D0
       add.l     D3,D0
       cmp.l     #63999,D0
       bne.s     PageWriteI2CInteraction_24
; break;
       bra.s     PageWriteI2CInteraction_21
PageWriteI2CInteraction_24:
       addq.l    #1,D3
       bra       PageWriteI2CInteraction_19
PageWriteI2CInteraction_21:
; }
; }
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Stop_Command;
       move.b    #81,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; do{
PageWriteI2CInteraction_26:
; I2C_Transmit = controlByte;
       move.b    D6,4227078
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; WaitForI2C_TIP();
       jsr       (A2)
       move.b    4227080,D0
       lsr.b     #7,D0
       and.b     #1,D0
       bne       PageWriteI2CInteraction_26
PageWriteI2CInteraction_9:
; }while(((I2C_Status >> 7) & 0x01) != 0);
; }
; //Special case for end address being the first byte of the next/last page
; if(((AddressFrom + i) % 128 == 0) && (flag == 1)){
       move.l    D2,D0
       add.l     D3,D0
       move.l    D0,-(A7)
       pea       128
       jsr       ULDIV
       move.l    4(A7),D0
       addq.w    #8,A7
       tst.l     D0
       bne       PageWriteI2CInteraction_31
       move.l    A5,D0
       cmp.l     #1,D0
       bne       PageWriteI2CInteraction_31
; if((AddressFrom + i) > 63999){
       move.l    D2,D0
       add.l     D3,D0
       cmp.l     #63999,D0
       bls       PageWriteI2CInteraction_30
; controlByte = EEPROM_WRITE_HI_BLK;
       move.b    #162,D6
; AddressFromMSB = (((AddressFrom + i) - 0xFA00) >> 8) & 0xFF;
       move.l    D2,D0
       add.l     D3,D0
       sub.l     #64000,D0
       lsr.l     #8,D0
       and.l     #255,D0
       move.b    D0,D5
; AddressFromLSB = ((AddressFrom + i) - 0xFA00) & 0xFF;   
       move.l    D2,D0
       add.l     D3,D0
       sub.l     #64000,D0
       and.l     #255,D0
       move.b    D0,D4
; WriteI2CInteraction(1, (AddressFrom + i), AddressFromMSB, AddressFromLSB, c, 1);     
       pea       1
       and.l     #255,D7
       move.l    D7,-(A7)
       and.l     #255,D4
       move.l    D4,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       move.l    D2,D1
       add.l     D3,D1
       move.l    D1,-(A7)
       pea       1
       jsr       _WriteI2CInteraction
       add.w     #24,A7
       bra       PageWriteI2CInteraction_31
PageWriteI2CInteraction_30:
; }else{
; controlByte = EEPROM_WRITE_LO_BLK;
       move.b    #160,D6
; AddressFromMSB = ((AddressFrom + i) >> 8) & 0xFF;
       move.l    D2,D0
       add.l     D3,D0
       lsr.l     #8,D0
       and.l     #255,D0
       move.b    D0,D5
; AddressFromLSB = (AddressFrom + i) & 0xFF;
       move.l    D2,D0
       add.l     D3,D0
       and.l     #255,D0
       move.b    D0,D4
; WriteI2CInteraction(0, (AddressFrom + i), AddressFromMSB, AddressFromLSB, c, 1); 
       pea       1
       and.l     #255,D7
       move.l    D7,-(A7)
       and.l     #255,D4
       move.l    D4,-(A7)
       and.l     #255,D5
       move.l    D5,-(A7)
       move.l    D2,D1
       add.l     D3,D1
       move.l    D1,-(A7)
       clr.l     -(A7)
       jsr       _WriteI2CInteraction
       add.w     #24,A7
PageWriteI2CInteraction_31:
; }
; }
; AddressFrom += (i + 1);
       move.l    D3,D0
       addq.l    #1,D0
       add.l     D0,D2
       bra       PageWriteI2CInteraction_1
PageWriteI2CInteraction_3:
; }
; printf("\r\nWrote [%x] from Address[%x] to Address[%x]", c, AddressFrom_Initial, AddressTo);
       move.l    A4,-(A7)
       move.l    -4(A6),-(A7)
       and.l     #255,D7
       move.l    D7,-(A7)
       pea       @iic_co~1_2.L
       jsr       _printf
       add.w     #16,A7
; return;
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3/A4/A5
       unlk      A6
       rts
; }
; void ReadI2CByteInteraction(int block, unsigned int Address, unsigned char AddressMSB, unsigned char AddressLSB, unsigned char c){
       xdef      _ReadI2CByteInteraction
_ReadI2CByteInteraction:
       link      A6,#-4
       movem.l   D2/D3/A2/A3,-(A7)
       lea       _WaitForI2C_TIP.L,A2
       lea       _WaitForI2C_RxACK.L,A3
; unsigned char controleByte_ForWrite;
; unsigned char controlByte_ForRead;
; unsigned char readData;
; if(block == 1){
       move.l    8(A6),D0
       cmp.l     #1,D0
       bne.s     ReadI2CByteInteraction_1
; controleByte_ForWrite= EEPROM_WRITE_HI_BLK;
       move.b    #162,D3
; controlByte_ForRead = EEPROM_READ_HI_BLK;
       move.b    #163,D2
       bra.s     ReadI2CByteInteraction_2
ReadI2CByteInteraction_1:
; }else{
; controleByte_ForWrite = EEPROM_WRITE_LO_BLK;
       move.b    #160,D3
; controlByte_ForRead = EEPROM_READ_LO_BLK;
       move.b    #161,D2
ReadI2CByteInteraction_2:
; }
; //////////////////////////////???//////////////////////////////
; //Wait for TIP and RxACK bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Send data to Transmit register
; I2C_Transmit = controleByte_ForWrite;
       move.b    D3,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //////////////////////////////???//////////////////////////////
; //Send data to Transmit register
; I2C_Transmit = AddressMSB;
       move.b    19(A6),4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //////////////////////////////???//////////////////////////////
; //Send data to Transmit register
; I2C_Transmit = AddressLSB;
       move.b    23(A6),4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //////////////////////////////???//////////////////////////////
; //Send data to Transmit register
; I2C_Transmit = controlByte_ForRead;
       move.b    D2,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Read_Stop_Command;
       move.b    #105,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //////////////////////////////???//////////////////////////////
; //poll for reading and clear after
; while((I2C_Status & 0x01) != 0x01) {
ReadI2CByteInteraction_3:
       move.b    4227080,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     ReadI2CByteInteraction_5
; // Do nothing and wait for I2C_Status[0] to become 1
; }   
       bra       ReadI2CByteInteraction_3
ReadI2CByteInteraction_5:
; I2C_Status = 0;
       clr.b     4227080
; //Grab data from Receive Register
; readData = I2C_Receive;
       move.b    4227078,-1(A6)
; printf("\r\nRead [%x] from Address[%x]", readData, Address);
       move.l    12(A6),-(A7)
       move.b    -1(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @iic_co~1_3.L
       jsr       _printf
       add.w     #12,A7
; return;
       movem.l   (A7)+,D2/D3/A2/A3
       unlk      A6
       rts
; }
; void ReadI2CSequential(int block, int AddressTo, int AddressFrom,  unsigned int ChipAddress){
       xdef      _ReadI2CSequential
_ReadI2CSequential:
       link      A6,#-8
       movem.l   D2/D3/D4/D5/D6/D7/A2/A3,-(A7)
       lea       _WaitForI2C_TIP.L,A2
       move.l    20(A6),D2
       lea       _WaitForI2C_RxACK.L,A3
; unsigned char controleWriteByte;
; unsigned char controlReadByte;
; unsigned char readData;
; unsigned char AddressLSB;
; unsigned char AddressMSB;
; int i;
; int size;
; size = AddressTo - AddressFrom;
       move.l    12(A6),D0
       sub.l     16(A6),D0
       move.l    D0,-4(A6)
; AddressMSB = (ChipAddress >> 8) & 0xFF;
       move.l    D2,D0
       lsr.l     #8,D0
       and.l     #255,D0
       move.b    D0,D6
; AddressLSB = ChipAddress & 0xFF;
       move.l    D2,D0
       and.l     #255,D0
       move.b    D0,D5
; if(block == 1){
       move.l    8(A6),D0
       cmp.l     #1,D0
       bne.s     ReadI2CSequential_1
; controleWriteByte = EEPROM_WRITE_HI_BLK;
       move.b    #162,D4
; controlReadByte = EEPROM_READ_HI_BLK;
       move.b    #163,D3
; AddressMSB = ((ChipAddress-0xFA00) >> 8) & 0xFF;
       move.l    D2,D0
       sub.l     #64000,D0
       lsr.l     #8,D0
       and.l     #255,D0
       move.b    D0,D6
; AddressLSB = (ChipAddress-0xFA00) & 0xFF;
       move.l    D2,D0
       sub.l     #64000,D0
       and.l     #255,D0
       move.b    D0,D5
       bra.s     ReadI2CSequential_2
ReadI2CSequential_1:
; }else{
; controleWriteByte = EEPROM_WRITE_LO_BLK;
       move.b    #160,D4
; controlReadByte = EEPROM_READ_LO_BLK;
       move.b    #161,D3
ReadI2CSequential_2:
; }
; //Wait for TIP and RxACK bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Send data to Transmit register
; I2C_Transmit = controleWriteByte;
       move.b    D4,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Send data to Transmit register
; I2C_Transmit = AddressMSB;
       move.b    D6,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //////////////////////////////???//////////////////////////////
; //Send data to Transmit register
; I2C_Transmit = AddressLSB;
       move.b    D5,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Send data to Transmit register
; I2C_Transmit = controlReadByte;
       move.b    D3,4227078
; //Set Control Register to start read
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; for (i = 0; i<=size; i++){
       moveq     #0,D7
ReadI2CSequential_3:
       cmp.l     -4(A6),D7
       bgt       ReadI2CSequential_5
; if(ChipAddress == 64000 && (controlReadByte == EEPROM_READ_LO_BLK)){
       cmp.l     #64000,D2
       bne       ReadI2CSequential_6
       and.w     #255,D3
       cmp.w     #161,D3
       bne       ReadI2CSequential_6
; //Stop command to switch blocks
; I2C_Command = I2C_Slave_Read_Stop_Command;
       move.b    #105,4227080
; WaitForI2C_TIP();
       jsr       (A2)
; AddressMSB = (ChipAddress - 0xFA00) >> 8;
       move.l    D2,D0
       sub.l     #64000,D0
       lsr.l     #8,D0
       move.b    D0,D6
; AddressLSB = (ChipAddress - 0xFA00);     
       move.l    D2,D0
       sub.l     #64000,D0
       move.b    D0,D5
; controleWriteByte = EEPROM_WRITE_HI_BLK;
       move.b    #162,D4
; controlReadByte = EEPROM_READ_HI_BLK;
       move.b    #163,D3
; I2C_Transmit = controleWriteByte;
       move.b    D4,4227078
; I2C_Command = I2C_Slave_Write_Start_Command; 
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Send data to Transmit register
; I2C_Transmit = AddressMSB;
       move.b    D6,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //////////////////////////////???//////////////////////////////
; //Send data to Transmit register
; I2C_Transmit = AddressLSB;
       move.b    D5,4227078
; //Set Control Register to start write
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Send data to Transmit register
; I2C_Transmit = controlReadByte;
       move.b    D3,4227078
; //Set Control Register to start read
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
ReadI2CSequential_6:
; }
; //Wait for TIP bit in Status Register 
; //Wait RxACK bit in Status Register 
; I2C_Command = I2C_Slave_Read_Command;
       move.b    #33,4227080
; WaitForI2C_TIP();
       jsr       (A2)
; // WaitForI2C_RxACK();
; //poll for reading and clear after
; while((I2C_Status & 0x01) != 0x01) {
ReadI2CSequential_8:
       move.b    4227080,D0
       and.b     #1,D0
       cmp.b     #1,D0
       beq.s     ReadI2CSequential_10
; // Do nothing and wait for I2C_Status[0] to become 1
; }   
       bra       ReadI2CSequential_8
ReadI2CSequential_10:
; // I2C_Status  &= ~(1<<0);
; //Grab data from Receive Register
; readData = I2C_Receive;
       move.b    4227078,-5(A6)
; printf("\r\nRead [%x] from Address[%x]", readData, ChipAddress);
       move.l    D2,-(A7)
       move.b    -5(A6),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       pea       @iic_co~1_3.L
       jsr       _printf
       add.w     #12,A7
; ChipAddress++;
       addq.l    #1,D2
       addq.l    #1,D7
       bra       ReadI2CSequential_3
ReadI2CSequential_5:
; }
; I2C_Command = I2C_Slave_Read_Stop_Command;
       move.b    #105,4227080
; WaitForI2C_TIP();
       jsr       (A2)
       movem.l   (A7)+,D2/D3/D4/D5/D6/D7/A2/A3
       unlk      A6
       rts
; }
; void DACWrite(void) {
       xdef      _DACWrite
_DACWrite:
       movem.l   D2/D3/D4/A2/A3,-(A7)
       lea       _WaitForI2C_TIP.L,A2
       lea       _WaitForI2C_RxACK.L,A3
; int i;
; unsigned int delay = 0xFFFFF;
       move.l    #1048575,D4
; unsigned int val;
; printf("\nI2C DAC Write: Please check LED\n");
       pea       @iic_co~1_4.L
       jsr       _printf
       addq.w    #4,A7
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Send data to Transmit register
; I2C_Transmit = ADC_DAC_WRITE_ADDRESS;
       move.b    #146,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Send data to Transmit register
; I2C_Transmit = DAC_ENABLE_COMMAND;
       move.b    #64,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Send data to Transmit register
; I2C_Transmit = 0xFF;
       move.b    #255,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; while(1){
DACWrite_1:
; val = 0xFF;
       move.l    #255,D3
; //Send data to Transmit register
; I2C_Transmit = val;
       move.b    D3,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Add a delay
; for(i = 0; i < delay; i++);
       clr.l     D2
DACWrite_4:
       cmp.l     D4,D2
       bhs.s     DACWrite_6
       addq.l    #1,D2
       bra       DACWrite_4
DACWrite_6:
; val = 0x00;
       clr.l     D3
; //Send data to Transmit register
; I2C_Transmit = val;
       move.b    D3,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A3)
; //Add a delay
; for(i = 0; i < delay; i++);
       clr.l     D2
DACWrite_7:
       cmp.l     D4,D2
       bhs.s     DACWrite_9
       addq.l    #1,D2
       bra       DACWrite_7
DACWrite_9:
       bra       DACWrite_1
; }
; }
; void ADCWrite(void){
       xdef      _ADCWrite
_ADCWrite:
       link      A6,#-4
       movem.l   D2/D3/A2/A3/A4,-(A7)
       lea       _WaitForI2C_TIP.L,A2
       lea       _printf.L,A3
       lea       _WaitForI2C_RxACK.L,A4
; int i;
; unsigned char c;
; unsigned int delay = 0xFFFFF;
       move.l    #1048575,-4(A6)
; printf("I2C ADC Read:\n");
       pea       @iic_co~1_5.L
       jsr       (A3)
       addq.w    #4,A7
; while(1){
ADCWrite_1:
; printf("\n==============================Measuring==============================\n");
       pea       @iic_co~1_6.L
       jsr       (A3)
       addq.w    #4,A7
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Send data to Transmit register
; I2C_Transmit = ADC_DAC_WRITE_ADDRESS;
       move.b    #146,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A4)
; //Send data to Transmit register
; I2C_Transmit = ADC_ENABLE_COMMAND;
       move.b    #68,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Command;
       move.b    #17,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A4)
; //Send data to Transmit register
; I2C_Transmit = ADC_READ_ADDRESS;
       move.b    #147,4227078
; //Set Command register
; I2C_Command = I2C_Slave_Write_Start_Command;
       move.b    #145,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Wait RxACK bit in Status Register 
; WaitForI2C_RxACK();
       jsr       (A4)
; //Set Command register to skip
; I2C_Command = I2C_Slave_Read_Command;
       move.b    #33,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Set Command register to skip
; I2C_Command = I2C_Slave_Read_Command;
       move.b    #33,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Grabbing read data from Receive Register for Thermistor
; c = I2C_Receive;
       move.b    4227078,D2
; printf("Value of Thermistor: %d\n", c);
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       @iic_co~1_7.L
       jsr       (A3)
       addq.w    #8,A7
; //Set Command register to skip
; I2C_Command = I2C_Slave_Read_Command;
       move.b    #33,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Grabbing read data from Receive Register for Potentiometer
; c = I2C_Receive;
       move.b    4227078,D2
; printf("Value of Potentiometer: %d\n", c);
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       @iic_co~1_8.L
       jsr       (A3)
       addq.w    #8,A7
; //Set Command register to skip
; I2C_Command = I2C_Slave_Read_Command;
       move.b    #33,4227080
; //Wait for TIP bit in Status Register 
; WaitForI2C_TIP();
       jsr       (A2)
; //Grabbing read data from Receive Register for Photo-resister
; c = I2C_Receive;
       move.b    4227078,D2
; printf("Value of Photo-resister: %d\n", c);
       and.l     #255,D2
       move.l    D2,-(A7)
       pea       @iic_co~1_9.L
       jsr       (A3)
       addq.w    #8,A7
; //Add a delay
; for(i = 0; i < delay; i++);
       clr.l     D3
ADCWrite_4:
       cmp.l     -4(A6),D3
       bhs.s     ADCWrite_6
       addq.l    #1,D3
       bra       ADCWrite_4
ADCWrite_6:
       bra       ADCWrite_1
; }
; }
       section   const
@iic_co~1_1:
       dc.b      13,10,87,114,111,116,101,32,91,37,120,93,32
       dc.b      116,111,32,65,100,100,114,101,115,115,91,37
       dc.b      120,93,0
@iic_co~1_2:
       dc.b      13,10,87,114,111,116,101,32,91,37,120,93,32
       dc.b      102,114,111,109,32,65,100,100,114,101,115,115
       dc.b      91,37,120,93,32,116,111,32,65,100,100,114,101
       dc.b      115,115,91,37,120,93,0
@iic_co~1_3:
       dc.b      13,10,82,101,97,100,32,91,37,120,93,32,102,114
       dc.b      111,109,32,65,100,100,114,101,115,115,91,37
       dc.b      120,93,0
@iic_co~1_4:
       dc.b      10,73,50,67,32,68,65,67,32,87,114,105,116,101
       dc.b      58,32,80,108,101,97,115,101,32,99,104,101,99
       dc.b      107,32,76,69,68,10,0
@iic_co~1_5:
       dc.b      73,50,67,32,65,68,67,32,82,101,97,100,58,10
       dc.b      0
@iic_co~1_6:
       dc.b      10,61,61,61,61,61,61,61,61,61,61,61,61,61,61
       dc.b      61,61,61,61,61,61,61,61,61,61,61,61,61,61,61
       dc.b      61,77,101,97,115,117,114,105,110,103,61,61,61
       dc.b      61,61,61,61,61,61,61,61,61,61,61,61,61,61,61
       dc.b      61,61,61,61,61,61,61,61,61,61,61,61,10,0
@iic_co~1_7:
       dc.b      86,97,108,117,101,32,111,102,32,84,104,101,114
       dc.b      109,105,115,116,111,114,58,32,37,100,10,0
@iic_co~1_8:
       dc.b      86,97,108,117,101,32,111,102,32,80,111,116,101
       dc.b      110,116,105,111,109,101,116,101,114,58,32,37
       dc.b      100,10,0
@iic_co~1_9:
       dc.b      86,97,108,117,101,32,111,102,32,80,104,111,116
       dc.b      111,45,114,101,115,105,115,116,101,114,58,32
       dc.b      37,100,10,0
       xref      ULDIV
       xref      _printf
