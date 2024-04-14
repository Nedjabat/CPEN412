; C:\CPEN412\ASN3\SPI_CONTROLLER.C - Compiled by CC68K  Version 5.00 (c) 1991-2005  Peter J. Fondse
; /*************************************************************
; ** SPI Controller registers
; **************************************************************/
; // SPI Registers
; #define SPI_Control (*(volatile unsigned char *)(0x00408020))
; #define SPI_Status (*(volatile unsigned char *)(0x00408022))
; #define SPI_Data (*(volatile unsigned char *)(0x00408024))
; #define SPI_Ext (*(volatile unsigned char *)(0x00408026))
; #define SPI_CS (*(volatile unsigned char *)(0x00408028))
; // these two macros enable or disable the flash memory chip enable off SSN_O[7..0]
; // in this case we assume there is only 1 device connected to SSN_O[0] so we can
; // write hex FE to the SPI_CS to enable it (the enable on the flash chip is active low)
; // and write FF to disable it
; #define Enable_SPI_CS() SPI_CS = 0xFE
; #define Disable_SPI_CS() SPI_CS = 0xFF
; /******************************************************************************************
; ** The following code is for the SPI controller
; *******************************************************************************************/
; // return true if the SPI has finished transmitting a byte (to say the Flash chip) return false otherwise
; // this can be used in a polling algorithm to know when the controller is busy or idle.
; int TestForSPITransmitDataComplete(void) {
       section   code
       xdef      _TestForSPITransmitDataComplete
_TestForSPITransmitDataComplete:
       move.l    D2,-(A7)
; /* TODO replace 0 below with a test for status register SPIF bit and if set, return true */
; int status_bit = (SPI_Status >> 7) & 0x01;      //Used bit-shift to read Bit 7 of the SPI_Status (SPIF)
       move.b    4227106,D0
       and.l     #255,D0
       lsr.l     #7,D0
       and.l     #1,D0
       move.l    D0,D2
; //Return 1 if SPIF = 1, Return 0 if SPIF = 0 or others
; if(status_bit == 1)
       cmp.l     #1,D2
       bne.s     TestForSPITransmitDataComplete_1
; return 1;
       moveq     #1,D0
       bra.s     TestForSPITransmitDataComplete_3
TestForSPITransmitDataComplete_1:
; else if (status_bit == 0)
       tst.l     D2
       bne.s     TestForSPITransmitDataComplete_4
; return 0;
       clr.l     D0
       bra.s     TestForSPITransmitDataComplete_3
TestForSPITransmitDataComplete_4:
; else
; return 0;
       clr.l     D0
TestForSPITransmitDataComplete_3:
       move.l    (A7)+,D2
       rts
; }
; /************************************************************************************
; ** initialises the SPI controller chip to set speed, interrupt capability etc.
; ************************************************************************************/
; void SPI_Init(void)
; {
       xdef      _SPI_Init
_SPI_Init:
; //TODO
; //
; // Program the SPI Control, EXT, CS and Status registers to initialise the SPI controller
; // Don't forget to call this routine from main() before you do anything else with SPI
; //
; // Here are some settings we want to create
; //
; // Control Reg - interrupts disabled, core enabled, Master mode, Polarity and Phase of clock = [0,0], speed = divide by 32 = approx 700Khz
; // Ext Reg - in conjunction with control reg, sets speed above and also sets interrupt flag after every completed transfer (each byte)
; // SPI_CS Reg - control selection of slave SPI chips via their CS# signals
; // Status Reg - status of SPI controller chip and used to clear any write collision and interrupt on transmit complete flag
; // SPI_CS Reg - control selection of slave SPI chips via their CS# signals
; Enable_SPI_CS();                        //1111 1110       PROBABLY DONT NEED, LEAVE IT FOR NOW, UNCOMMENT IF WRONG BEHAVIOUR
       move.b    #254,4227112
; // Control Reg - interrupts disabled, core enabled, Master mode, Polarity and Phase of clock = [0,0], speed = divide by 32 = approx 700Khz
; SPI_Control = (unsigned char) 0x53;     //01_1 0011
       move.b    #83,4227104
; // Ext Reg - in conjunction with control reg, sets speed above and also sets interrupt flag after every completed transfer (each byte)
; SPI_Ext = (unsigned char) 0x0;          //00__ __00
       clr.b     4227110
; // Status Reg - status of SPI controller chip and used to clear any write collision and interrupt on transmit complete flag
; SPI_Status = (unsigned char) 0xC0;      //1100 0000
       move.b    #192,4227106
; //Disable SPI_CS after every command
; Disable_SPI_CS();                       //1111 1111
       move.b    #255,4227112
; return;
       rts
; }
; /************************************************************************************
; ** return ONLY when the SPI controller has finished transmitting a byte
; ************************************************************************************/
; void WaitForSPITransmitComplete(void)
; {
       xdef      _WaitForSPITransmitComplete
_WaitForSPITransmitComplete:
       link      A6,#-4
; // TODO : poll the status register SPIF bit looking for completion of transmission
; // once transmission is complete, clear the write collision and interrupt on transmit complete flags in the status register (read documentation)
; // just in case they were set
; int status_bit;
; do{
WaitForSPITransmitComplete_1:
; status_bit = (SPI_Status >> 7) & 0x01; 
       move.b    4227106,D0
       and.l     #255,D0
       lsr.l     #7,D0
       and.l     #1,D0
       move.l    D0,-4(A6)
       move.l    -4(A6),D0
       cmp.l     #1,D0
       bne       WaitForSPITransmitComplete_1
; }while( status_bit != 1);
; SPI_Status = (unsigned char) 0xC0;      //1100 0000
       move.b    #192,4227106
; return;
       unlk      A6
       rts
; }
; /************************************************************************************
; ** Write a byte to the SPI flash chip via the controller and returns (reads) whatever was
; ** given back by SPI device at the same time (removes the read byte from the FIFO)
; ************************************************************************************/
; unsigned char WriteSPIChar(unsigned char c)
; {
       xdef      _WriteSPIChar
_WriteSPIChar:
       link      A6,#0
; // todo - write the byte in parameter 'c' to the SPI data register, this will start it transmitting to the flash device
; // wait for completion of transmission
; // return the received data from Flash chip (which may not be relevent depending upon what we are doing)
; // by reading fom the SPI controller Data Register.
; // note however that in order to get data from an SPI slave device (e.g. flash) chip we have to write a dummy byte to it
; //
; // modify '0' below to return back read byte from data register
; //
; SPI_Data = c;
       move.b    11(A6),4227108
; WaitForSPITransmitComplete();
       jsr       _WaitForSPITransmitComplete
; return SPI_Data;
       move.b    4227108,D0
       unlk      A6
       rts
; }
; void EraseSPIFlashChip(void)
; {
       xdef      _EraseSPIFlashChip
_EraseSPIFlashChip:
       move.l    A2,-(A7)
       lea       _WriteSPIChar.L,A2
; Enable_SPI_CS();
       move.b    #254,4227112
; WriteSPIChar(0x06); //Enabling the Device for Writing/Erasing
       pea       6
       jsr       (A2)
       addq.w    #4,A7
; Disable_SPI_CS();
       move.b    #255,4227112
; Enable_SPI_CS();
       move.b    #254,4227112
; WriteSPIChar(0x60); //Erasing the chip or 0x60?
       pea       96
       jsr       (A2)
       addq.w    #4,A7
; Disable_SPI_CS();
       move.b    #255,4227112
; Enable_SPI_CS();
       move.b    #254,4227112
; WriteSPIChar(0x05); //Polling for completion of commands in the Flash Memory chip
       pea       5
       jsr       (A2)
       addq.w    #4,A7
; while(WriteSPIChar(0xEE) & 1){}; //Using random data to write and test until we get an idle response back
EraseSPIFlashChip_1:
       pea       238
       jsr       (A2)
       addq.w    #4,A7
       and.b     #1,D0
       beq.s     EraseSPIFlashChip_3
       bra       EraseSPIFlashChip_1
EraseSPIFlashChip_3:
; Disable_SPI_CS();
       move.b    #255,4227112
; return;
       move.l    (A7)+,A2
       rts
; }
; void WriteSPIFlashData(int FlashAddress, unsigned char *MemoryAddress, int size)
; {
       xdef      _WriteSPIFlashData
_WriteSPIFlashData:
       link      A6,#0
       movem.l   D2/D3/D4/A2,-(A7)
       lea       _WriteSPIChar.L,A2
       move.l    8(A6),D2
; int count;
; int w_count;
; for(count = 0; count < 1000; count++){
       clr.l     D4
WriteSPIFlashData_1:
       cmp.l     #1000,D4
       bge       WriteSPIFlashData_3
; Enable_SPI_CS();
       move.b    #254,4227112
; WriteSPIChar(0x06); //Enabling the Device for Writing/Erasing
       pea       6
       jsr       (A2)
       addq.w    #4,A7
; Disable_SPI_CS();
       move.b    #255,4227112
; Enable_SPI_CS();
       move.b    #254,4227112
; WriteSPIChar(0x02);
       pea       2
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar((FlashAddress >> 16)&0xFF);
       move.l    D2,D1
       asr.l     #8,D1
       asr.l     #8,D1
       and.l     #255,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar((FlashAddress >> 8)&0xFF);
       move.l    D2,D1
       asr.l     #8,D1
       and.l     #255,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar(FlashAddress & 0x00);
       move.l    D2,D1
       and.l     #0,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; for(w_count = 0;w_count<256;w_count++){
       clr.l     D3
WriteSPIFlashData_4:
       cmp.l     #256,D3
       bge.s     WriteSPIFlashData_6
; WriteSPIChar(*MemoryAddress);
       move.l    12(A6),A0
       move.b    (A0),D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; MemoryAddress++;
       addq.l    #1,12(A6)
       addq.l    #1,D3
       bra       WriteSPIFlashData_4
WriteSPIFlashData_6:
; }
; Disable_SPI_CS();
       move.b    #255,4227112
; Enable_SPI_CS();
       move.b    #254,4227112
; WriteSPIChar(0x05);
       pea       5
       jsr       (A2)
       addq.w    #4,A7
; while(WriteSPIChar(0xFF));
WriteSPIFlashData_7:
       pea       255
       jsr       (A2)
       addq.w    #4,A7
       tst.b     D0
       beq.s     WriteSPIFlashData_9
       bra       WriteSPIFlashData_7
WriteSPIFlashData_9:
; Disable_SPI_CS();
       move.b    #255,4227112
; FlashAddress = FlashAddress + 256;
       add.l     #256,D2
       addq.l    #1,D4
       bra       WriteSPIFlashData_1
WriteSPIFlashData_3:
; }
; return;
       movem.l   (A7)+,D2/D3/D4/A2
       unlk      A6
       rts
; }
; void ReadSPIFlashData( int FlashAddress, unsigned char *MemoryAddress, int size)
; {
       xdef      _ReadSPIFlashData
_ReadSPIFlashData:
       link      A6,#-4
       movem.l   D2/A2,-(A7)
       lea       _WriteSPIChar.L,A2
       move.l    8(A6),D2
; int value;
; Enable_SPI_CS();
       move.b    #254,4227112
; WriteSPIChar(0x03);
       pea       3
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar((FlashAddress >> 16)&0xFF);
       move.l    D2,D1
       asr.l     #8,D1
       asr.l     #8,D1
       and.l     #255,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar((FlashAddress >> 8)&0xFF);
       move.l    D2,D1
       asr.l     #8,D1
       and.l     #255,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar(FlashAddress & 0xFF);
       move.l    D2,D1
       and.l     #255,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; value = WriteSPIChar(0xFF);
       pea       255
       jsr       (A2)
       addq.w    #4,A7
       and.l     #255,D0
       move.l    D0,-4(A6)
; /*for(count=0;count<size;count++){
; *MemoryAddress = WriteSPIChar(0xFF);
; MemoryAddress++; 
; }*/
; Disable_SPI_CS();
       move.b    #255,4227112
; return;
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
; unsigned char ReadSPIFlashByte( int FlashAddress)
; {
       xdef      _ReadSPIFlashByte
_ReadSPIFlashByte:
       link      A6,#-4
       movem.l   D2/A2,-(A7)
       lea       _WriteSPIChar.L,A2
       move.l    8(A6),D2
; unsigned char value;
; Enable_SPI_CS();
       move.b    #254,4227112
; WriteSPIChar(0x03);
       pea       3
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar((FlashAddress >> 16)&0xFF);
       move.l    D2,D1
       asr.l     #8,D1
       asr.l     #8,D1
       and.l     #255,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar((FlashAddress >> 8)&0xFF);
       move.l    D2,D1
       asr.l     #8,D1
       and.l     #255,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; WriteSPIChar(FlashAddress & 0xFF);
       move.l    D2,D1
       and.l     #255,D1
       and.l     #255,D1
       move.l    D1,-(A7)
       jsr       (A2)
       addq.w    #4,A7
; value = WriteSPIChar(0xFF);
       pea       255
       jsr       (A2)
       addq.w    #4,A7
       move.b    D0,-1(A6)
; Disable_SPI_CS();
       move.b    #255,4227112
; return value;
       move.b    -1(A6),D0
       movem.l   (A7)+,D2/A2
       unlk      A6
       rts
; }
