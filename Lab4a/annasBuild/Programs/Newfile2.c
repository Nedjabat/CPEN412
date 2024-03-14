#include <stdio.h>
#include <stdlib.h>


int main()
{
    unsigned int test_option = 0;
    unsigned int bit_num = 0;
    unsigned int test_pattern = 0;
    unsigned int select_pattern = 0;
    unsigned int write_data = 0;
    unsigned int start_addr = 0;
    unsigned int end_addr = 0;
    unsigned int *addr_point = NULL;
    unsigned int counter = 10000;

    //prompting user for test option BYTES, WORDS, or LONG WORDS
    while(!test_option){

        printf("\r\nPlease enter a number to choose one of the following test options:"
        "\r\n1 - Bytes"
        "\r\n2 - Words"
        "\r\n3 - Long Words\r\n");

        scanf("%d", &test_option);

        if((test_option != 1 && test_option != 2 && test_option != 3) || test_option == 0){
            printf("\r\nInvalid Selection\r\n");
            test_option = 0;
        }
    }

    //assigning bit_num based on test_option
    switch(test_option){
        case 1:
            printf("\r\nYou have selected test option BYTES\r\n");
            bit_num = 8;
            break;

        case 2:
            printf("\r\nYou have selected test option WORDS\r\n");
            bit_num = 16;
            break;

        case 3:
            printf("\r\nYou have selected test option LONG WORDS\r\n");
            bit_num = 32;
            break;

        default:
            printf("\r\nException - invalid test option\r\n");
            break;
    }

    //prompting user to enter test pattern
    while(!select_pattern){

        printf("\r\nPlease enter a number to choose one of the following test patterns:"
        "\r\n1 - 55"
        "\r\n2 - AA"
        "\r\n3 - FF"
        "\r\n4 - 00\r\n");

        scanf("%d", &select_pattern);

        if((select_pattern != 1 && select_pattern != 2 && select_pattern != 3 && select_pattern != 4) || select_pattern == 0){
            printf("\r\nInvalid Selection\r\n");
            select_pattern = 0;
        }
    }

    //assigning write_data based on test_pattern
    switch(select_pattern){
        case 1:
            printf("\r\nYou have selected test pattern 55\r\n");
            test_pattern = 0x55;
            break;

        case 2:
            printf("\r\nYou have selected test pattern AA\r\n");
            test_pattern = 0xAA;
            break;

        case 3:
            printf("\r\nYou have selected test pattern FF\r\n");
            test_pattern = 0xFF;
            break;

        case 4:
            printf("\r\nYou have selected test pattern 00\r\n");
            test_pattern = 0x00;

        default:
            printf("\r\nException - invalid test pattern\r\n");
            break;
    }

    //create appropriate data set based on select_pattern and test_option
    // ie, if select_pattern is AA and test_option is BYTES, write_data must be AAAA
    switch(test_option){
        case 1:
            write_data = test_pattern;
            break;
        case 2:
            write_data = test_pattern | test_pattern << 8;
            break;
        case 3:
            write_data = test_pattern | test_pattern << 8 | test_pattern << 16 | test_pattern << 24;
            break;
        default:
            printf("\r\nException - could not generate write_data\r\n");
            break;
    }

    //prompting user to enter start address
    while(!start_addr){
        printf("\r\nPlease enter a starting address from 08020000 to 08030000\r\n");
        scanf("%d", &start_addr);

        if(start_addr<0x08020000 || start_addr>0x08030000){
            printf("\r\nStart address is invalid\r\n");
            start_addr = 0;
        } else if(bit_num>8 && start_addr % 2 != 0){
            printf("\r\nFor words or long words, please enter an even numbered address\r\n");
            end_addr = 0;
        } else{
            printf("\r\nThe chosen starting address is: %x", start_addr);
        }
    }

    //prompting user to enter end address
    while(!end_addr){
        printf("\r\nPlease enter an end address from %x to 08030000\r\n", start_addr);
        scanf("%d", &end_addr);

        if(end_addr<start_addr || end_addr>0x08030000){
            printf("\r\nEnd address is invalid\r\n");
            end_addr = 0;
        } else if(bit_num>8 && end_addr % 2 != 0){
            printf("\r\nFor words or long words, please enter an even numbered address\r\n");
            end_addr = 0;
        } else{
            printf("\r\nThe chosen ending address is: %x", end_addr);
        }
    }

    //set address pointer to start pointer
    addr_point = start_addr;

    //writing data
    while(addr_point<end_addr){
        *addr_point = write_data;
        counter++;
        if(counter >= 10000){
            printf("\r\nWriting %x into address %x\r\n", *addr_point, addr_point);
            counter = 1;
        }

        //need to increment address pointer according to test option chosen (bytes, words, long words)
        if(test_option == 1){
            addr_point = addr_point+1;
        } else if(test_option == 2){
            addr_point = addr_point+2;
        }else if(test_option == 3){
            addr_point = addr_point+4;
        }
    }
    printf("\r\nWriting completed. Will now start reading.\r\n");
    addr_point = start_addr;
    counter = 10000;

    //reading data
    while(addr_point<end_addr){
        if(*addr_point != write_data){
            printf("\r\nAn Error has occurred: data at address %x expected to be %x, instead is reading %x", addr_point, write_data, *addr_point);
            printf("\r\nMemory test failed.\r\n");
            break;
        }
        counter++;

        if(counter >= 10000){
            printf("\r\nReading data value %x from address %x\r\n", *addr_point, addr_point);
            counter = 1;
        }

        //need to increment address pointer according to test option chosen (bytes, words, long words)
        if(test_option == 1){
            addr_point = addr_point+1;
        } else if(test_option == 2){
            addr_point = addr_point+2;
        }else if(test_option == 3){
            addr_point = addr_point+4;
        }
    }

    return 0;
}