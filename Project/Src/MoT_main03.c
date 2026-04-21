//MoT_main03.c wmh 2025-04-26 : adds libTIM2_PA5_PWM_IRQ.a and demo to MoT

#include "stdint-gcc.h"	//for uint8_t, uint16_t, uint32_t  etc.
#include <stddef.h>
#include "MoTstructures.h"

//system functions
void SystemClock_init2();
void SysTick_init();
void LPUART1_init(); 						//initialize LPUART1 for STLINK VCOM at 115200N81
void LPUART1_RX_interrupt_enable(); 		//what it says
void HW_userCOM_init(); 					//initializes MoT console communication

//system data
uint32_t SysTick_msecs = 0; 		//0-999; updated by Systick_Handler() 'SysTick_48MHz.S'
uint64_t SysTick_absmsecs = 0; 		//0 - 2**64; ""
uint32_t SysTick_secs = 0;			//0 - 2**32; ""

//MoT configuration values (required!)-- adjustable
#define COUNT 100
uint32_t userCOM_RXDATACOUNT= COUNT;			//'COUNT' is number of characters that can be buffered
uint32_t userCOM_RXDATASTORAGE[COUNT/4+1+9]; 	//allocation is for composite character data buffer + control values struct
uint32_t *userCOM_RXbufHANDLEp = userCOM_RXDATASTORAGE + 9; //'handle' points to address 9 words 'above' allocation region


//debug access to device control structures (you can use these in debug's 'Expressions' to cast register pointers)
extern MoT_core_t device0;	//1st device is the system device for MoT command '0' and starting tasks
extern MoT_core_t userLED;	//example device/task
extern MoT_core_t blueBUTTON;	// ""
extern MoT_core_t device3;	//for demo of how to add a new device
extern MoT_core_t device4; //homework 7 device 4
extern MoT_core_t device5; //DAC1_OUT2 device homework8
extern MoT_core_t device6; //TIM2_OUT device homework9
extern MoT_core_t deviceN;	//last device is the system device for ending tasks and returning to command loop
extern MoT_msgLink_t INITIALIZED_msg;
extern MoT_msgLink_t STARTING_msg;
extern MoT_listAnchor_t consoleMsgs;

//arrays for device 5 usage
uint16_t sine_wave[256] = {
2048,2098,2148,2198,2248,2298,2347,2396,2445,2493,2541,2589,2636,2683,2729,2775,
2820,2865,2909,2952,2995,3037,3078,3119,3159,3198,3236,3274,3311,3347,3382,3416,
3449,3482,3513,3544,3573,3602,3629,3656,3681,3706,3729,3751,3772,3792,3811,3829,
3845,3861,3875,3888,3900,3911,3920,3928,3935,3941,3945,3949,3951,3952,3952,3951,
3949,3945,3941,3935,3928,3920,3911,3900,3888,3875,3861,3845,3829,3811,3792,3772,
3751,3729,3706,3681,3656,3629,3602,3573,3544,3513,3482,3449,3416,3382,3347,3311,
3274,3236,3198,3159,3119,3078,3037,2995,2952,2909,2865,2820,2775,2729,2683,2636,
2589,2541,2493,2445,2396,2347,2298,2248,2198,2148,2098,2048,1997,1947,1897,1847,
1797,1747,1698,1649,1600,1552,1504,1456,1409,1362,1316,1270,1225,1180,1136,1093,
1050,1008,967,926,886,847,809,771,734,698,663,629,595,562,531,500,
470,441,414,387,362,337,314,292,271,252,233,216,199,184,170,157,
145,134,125,117,110,104,100,96,94,93,93,94,96,100,104,110,
117,125,134,145,157,170,184,199,216,233,252,271,292,314,337,362,
387,414,441,470,500,531,562,595,629,663,698,734,771,809,847,886,
926,967,1008,1050,1093,1136,1180,1225,1270,1316,1362,1409,1456,1504,1552,1600,
1649,1698,1747,1797,1847,1897,1947,1997
};

uint16_t triangle_wave[256] = {
0,32,64,96,128,160,192,224,256,288,320,352,384,416,448,480,
512,544,576,608,640,672,704,736,768,800,832,864,896,928,960,992,
1024,1056,1088,1120,1152,1184,1216,1248,1280,1312,1344,1376,1408,1440,1472,1504,
1536,1568,1600,1632,1664,1696,1728,1760,1792,1824,1856,1888,1920,1952,1984,2016,
2048,2080,2112,2144,2176,2208,2240,2272,2304,2336,2368,2400,2432,2464,2496,2528,
2560,2592,2624,2656,2688,2720,2752,2784,2816,2848,2880,2912,2944,2976,3008,3040,
3072,3104,3136,3168,3200,3232,3264,3296,3328,3360,3392,3424,3456,3488,3520,3552,
3584,3616,3648,3680,3712,3744,3776,3808,3840,3872,3904,3936,3968,4000,4032,4063,
4063,4032,4000,3968,3936,3904,3872,3840,3808,3776,3744,3712,3680,3648,3616,3584,
3552,3520,3488,3456,3424,3392,3360,3328,3296,3264,3232,3200,3168,3136,3104,3072,
3040,3008,2976,2944,2912,2880,2848,2816,2784,2752,2720,2688,2656,2624,2592,2560,
2528,2496,2464,2432,2400,2368,2336,2304,2272,2240,2208,2176,2144,2112,2080,2048,
2016,1984,1952,1920,1888,1856,1824,1792,1760,1728,1696,1664,1632,1600,1568,1536,
1504,1472,1440,1408,1376,1344,1312,1280,1248,1216,1184,1152,1120,1088,1056,1024,
992,960,928,896,864,832,800,768,736,704,672,640,608,576,544,512,
480,448,416,384,352,320,288,256,224,192,160,128,96,64,32,0
};

uint16_t sawtooth_wave[256] = {
0,16,32,48,64,80,96,112,128,144,160,176,192,208,224,240,
256,272,288,304,320,336,352,368,384,400,416,432,448,464,480,496,
512,528,544,560,576,592,608,624,640,656,672,688,704,720,736,752,
768,784,800,816,832,848,864,880,896,912,928,944,960,976,992,1008,
1024,1040,1056,1072,1088,1104,1120,1136,1152,1168,1184,1200,1216,1232,1248,1264,
1280,1296,1312,1328,1344,1360,1376,1392,1408,1424,1440,1456,1472,1488,1504,1520,
1536,1552,1568,1584,1600,1616,1632,1648,1664,1680,1696,1712,1728,1744,1760,1776,
1792,1808,1824,1840,1856,1872,1888,1904,1920,1936,1952,1968,1984,2000,2016,2032,
2048,2064,2080,2096,2112,2128,2144,2160,2176,2192,2208,2224,2240,2256,2272,2288,
2304,2320,2336,2352,2368,2384,2400,2416,2432,2448,2464,2480,2496,2512,2528,2544,
2560,2576,2592,2608,2624,2640,2656,2672,2688,2704,2720,2736,2752,2768,2784,2800,
2816,2832,2848,2864,2880,2896,2912,2928,2944,2960,2976,2992,3008,3024,3040,3056,
3072,3088,3104,3120,3136,3152,3168,3184,3200,3216,3232,3248,3264,3280,3296,3312,
3328,3344,3360,3376,3392,3408,3424,3440,3456,3472,3488,3504,3520,3536,3552,3568,
3584,3600,3616,3632,3648,3664,3680,3696,3712,3728,3744,3760,3776,3792,3808,3824,
3840,3856,3872,3888,3904,3920,3936,3952,3968,3984,4000,4016,4032,4048,4064,4079
};

//!! IMPORTANT: position of a 'device' in the device control list (below) is also the device ID  (0,1,...)
MoT_core_t *devicelist[] = {&device0, &userLED, &blueBUTTON, &device3, &device4, &device5, &device6, &deviceN};	 //device0, deviceN must be first, last

void * MoT_doTasks(MoT_core_t *list[] ); // in MoTservices_xx.S; dispatches device tasks

// note: MoT uses an exhaustive linked list of tasks for speed. 'link_devicetasks()' below initializes the device-task list
void link_tasks(MoT_core_t *list[], int num ) {
	int i;
	for(i=0;i<num-1;i++) {				//'num-1' because the final device (deviceN) does not have a successor.
		list[i]->nexttask = list[i+1];	//style-trial
	}
}

int main(void)
{
	int devnum=sizeof(devicelist)/sizeof(&devicelist[0]);

	SystemClock_init2();							//initialize millisecond interrupt and timers
	SysTick_init();
	HW_userCOM_init();								//initialize user USART, USART interrupt, and message buffers
	link_tasks(devicelist,devnum);
	while (1)
	{
		MoT_doTasks(devicelist);	//in MoTservices*.S
	}

}
