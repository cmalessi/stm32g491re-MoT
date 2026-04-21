//SystemClock_init2.S wmh 2024-08-24 : sets HCLK system clock rate at 72MHz and make adjustments to flash wait-states and peripheral bus clocks
// Derives from CubeMX project of "SystemClock_Config()" example in D:\_umd\2024-09-01\ENEE440_F24\_work\0816_STM32G491_TODOs\STM32G491_CubeMXproject_ws2
// Goal is to reach a particular clock configuration state regardless of the starting state (reset, different configuration) of the processor 
// Notes on method: 
//	- magic numbers: 
//		Every magic number (register addresses, configuration bit location and values, etc) is a constant defined in the device's header file (stm32G491xx.h)
//	- update and confirm:
//		Every configuration update which changes a register or bit value is followed by an attempt to confirm the change
//		Many of these confirmation steps will be unnecessary in the production version and will be eliminated, but we need them here for debug.
//  - Configuration road map (preliminary):
//		The step-by-step operations listed below derive from the STM32G491_CubeMXproject_ws2 and the RM0440 manual and are not final. '*' denotes optional. 
//		 (TODO: update the below when working)
//       )	update and confirm : turn HSI16 oscillator 'ON' (RCC_CR_HSION, RCC_CR_HSIRDY)
//       )	update and confirm : change SysClk source to HSI16 (RCC_CFGR_SW,RCC_CFGR_SWS)
//       )	update and confirm : turn PLL 'OFF' (RCC_CR_PLLON=0, RCC_CR_PLLRDY=0)
//       )	update and confirm : FLASH wait state setting for anticipated clock frequencies  (FLASH_ACR_LATENCY)
//       *)	update and confirm : set FLASH prefetch enable (FLASH_ACR_PRFTEN)
//       )	update and confirm : power setting for anticipated CPU clock frequency (PWR_CR5_R1MODE)
//       )	update and confirm : PLL reference clock prescaler (RCC_PLLCFGR_PLLM) 
//       )	update and confirm : VCO frequency multiplier (RCC_PLLCFGR_PLLN)
//       )	update and confirm : VCO divider for PLLRCLK (RCC_PLLCFGR_PLLR) (RCLK to be used as SysClk when PLL is clock source)
//       *)	update and confirm : VCO divider for PLLPCLK (RCC_PLLCFGR_PLLP) (PCLK is alternate to SysClk for driving ADCs)
//       *)	update and confirm : VCO divider for PLLPCLK (RCC_PLLCFGR_PLLQ)	(QCLK is alternate to SysClk or PCLK for driving various peripherals)
//       )	update and confirm : turn PLL 'ON' (RCC_CR_PLLON=1, RCC_CR_PLLRDY=1)
//       )	update and confirm : enable RCLK clock as main domain clock (RCC_PLLCFGR_PLLREN) (RCLK will used as SysClk when PLL is clock source)
//       *)	update and confirm : enable PCLK clock as subdomain clock (RCC_PLLCFGR_PLLPEN) (make PCLK alternative to SysClk for driving ADCs)
//       *)	update and confirm : enable QCLK clock as subdomain clock (RCC_PLLCFGR_PLLQEN) (make QCLK alternative to SysClk for driving various peripherals)
//       *)	update and confirm : AHB bus clock prescaler (RCC_CFGR_HPRE)  (reset value is 0xxx = not prescaled)
//       *)	update and confirm : PPRE1 bus clock prescaler (RCC_CFGR_PPRE1)  (reset value is 0xxx = not prescaled)
//       *)	update and confirm : PPRE2 bus clock prescaler (RCC_CFGR_PPRE2)  (reset value is 0xxx = not prescaled)
//       *)	update and confirm : power scaling mode if necessary (PWR_CR5_R1MODE_SW,PWR_CR5_R1MODE_SWS)
//       )	update and confirm : change SysClk source to PLL (RCC_CFGR_SW,RCC_CFGR_SWS)
//       )	software delay
//       *)	update SysTick and SystemCoreClock value

	.syntax unified					@; ARM Unified Assembler Language (UAL) is allowed
	.thumb							@; we're using thumb instructions only
	.text

	#include "stm32G491xx_RCC.h"
	#include "stm32G491xx_FLASH.h"
	#include "stm32G491xx_PWR.h"
	
	#include "bit-op_macros.S"

	.global SystemClock_init2	@ make SystemClock_init() visible everywhere
	.thumb_func					@; make linker set bit0 =1 in any absolute indirect references (function pointers) to this function
SystemClock_init2:
	push {r7,lr}

	@; )	update and confirm : turn HSI16 oscillator 'ON' (RCC_CR_HSION, RCC_CR_HSIRDY) (mSET_DEVICREG_BIT ok) 
	mUPDATE_DEVICEREG_BIT_TO_1 	RCC_BASE, RCC_CR, 	RCC_CR_HSION_Pos, 	RCC_CR_HSION_Msk
1:	mCONFIRM_DEVICEREG_BIT_EQ_1	RCC_BASE, RCC_CR, 	RCC_CR_HSIRDY_Pos, 	RCC_CR_HSIRDY_Msk	
	bne 1b

	@; )	update and confirm : change SysClk source to HSI16 (RCC_CFGR_SW,RCC_CFGR_SWS)
	mUPDATE_DEVICEREG_FIELD RCC_BASE, RCC_CFGR, RCC_CFGR_SWS_Pos, RCC_CFGR_SWS_Msk, RCC_CFGR_SW_HSI
1:	mCONFIRM_DEVICEREG_FIELD RCC_BASE, RCC_CFGR, RCC_CFGR_SWS_Pos, RCC_CFGR_SWS_Msk, RCC_CFGR_SWS_HSI
	bne 1b

	@; )	update and confirm : turn PLL 'OFF' (RCC_CR_PLLON=0, RCC_CR_PLLRDY=0)
	mUPDATE_DEVICEREG_BIT_TO_0 	RCC_BASE, RCC_CR, 	RCC_CR_PLLON_Pos, 	RCC_CR_PLLON_Msk
1:	mCONFIRM_DEVICEREG_BIT_EQ_0	RCC_BASE, RCC_CR, 	RCC_CR_PLLRDY_Pos, 	RCC_CR_PLLRDY_Msk	
	bne 1b

	@; )	update and confirm : FLASH wait state setting for anticipated clock frequencies < 150MHz (FLASH_ACR_LATENCY)
	mUPDATE_DEVICEREG_FIELD FLASH_BASE, FLASH_ACR, FLASH_ACR_LATENCY_Pos, FLASH_ACR_LATENCY_Msk, FLASH_ACR_LATENCY_4WS
1:	mCONFIRM_DEVICEREG_FIELD FLASH_BASE, FLASH_ACR, FLASH_ACR_LATENCY_Pos, FLASH_ACR_LATENCY_Msk, FLASH_ACR_LATENCY_4WS
//!!	bne 1b

	@; )	confirm : power settings for anticipated CPU clock frequencies < 150MHz (PWR_CR5_R1MODE)
1:	mCONFIRM_DEVICEREG_FIELD PWR_BASE, PWR_CR1, PWR_CR1_VOS_Pos, PWR_CR1_VOS_Msk, PWR_CR1_VOS_0
	bne 1b
1:	mCONFIRM_DEVICEREG_BIT_EQ_1	PWR_BASE, PWR_CR5, 	PWR_CR5_R1MODE_Pos, PWR_CR5_R1MODE_Msk	
	bne 1b

	@; )	update and confirm : PLL reference clock prescaler (RCC_PLLCFGR_PLLM) scales PLL reference input by 4
	mUPDATE_DEVICEREG_FIELD RCC_BASE, RCC_PLLCFGR, RCC_PLLCFGR_PLLM_Pos, RCC_PLLCFGR_PLLM_Msk, ( 3 << RCC_PLLCFGR_PLLM_Pos ) 
1:	mCONFIRM_DEVICEREG_FIELD RCC_BASE, RCC_PLLCFGR, RCC_PLLCFGR_PLLM_Pos, RCC_PLLCFGR_PLLM_Msk,( 3 << RCC_PLLCFGR_PLLM_Pos ) 
	bne 1b

	@; )	update and confirm : VCO frequency multiplier (RCC_PLLCFGR_PLLN) with PLLM, multiplies PLL reference input by 36/4 =9
	mUPDATE_DEVICEREG_FIELD RCC_BASE, RCC_PLLCFGR, RCC_PLLCFGR_PLLN_Pos, RCC_PLLCFGR_PLLN_Msk, ( 36 << RCC_PLLCFGR_PLLN_Pos ) 
1:	mCONFIRM_DEVICEREG_FIELD RCC_BASE, RCC_PLLCFGR, RCC_PLLCFGR_PLLN_Pos, RCC_PLLCFGR_PLLN_Msk,( 36 << RCC_PLLCFGR_PLLN_Pos ) 
	bne 1b

	@; )	update and confirm : VCO divider for PLLRCLK (RCC_PLLCFGR_PLLR) RCLK frequency to be 1/2 of PLL VCO frequency, or (16 * (36/4))/2 =72
	mUPDATE_DEVICEREG_FIELD RCC_BASE, RCC_PLLCFGR, RCC_PLLCFGR_PLLR_Pos, RCC_PLLCFGR_PLLR_Msk, ( 0 << RCC_PLLCFGR_PLLR_Pos ) 
1:	mCONFIRM_DEVICEREG_FIELD RCC_BASE, RCC_PLLCFGR, RCC_PLLCFGR_PLLR_Pos, RCC_PLLCFGR_PLLR_Msk,( 0 << RCC_PLLCFGR_PLLR_Pos ) 
	bne 1b

	@; *)	update and confirm : VCO divider for PLLPCLK (RCC_PLLCFGR_PLLP) (PCLK is alternate to SysClk for driving ADCs)
	@; *)	update and confirm : VCO divider for PLLPCLK (RCC_PLLCFGR_PLLQ)	(QCLK is alternate to SysClk or PCLK for driving various peripherals)

	@; )    update and confirm : source of PLL reference clock input ( RCC_PLLCFGR_PLLSRC ) 
	@; !!wmh Header file has hinky separate definitions for individual bits in the bit-field and also as bit-codes.  Why? 
	mUPDATE_DEVICEREG_FIELD RCC_BASE, RCC_PLLCFGR, RCC_PLLCFGR_PLLSRC_Pos, RCC_PLLCFGR_PLLSRC_Msk, RCC_PLLCFGR_PLLSRC_HSI
1:	mCONFIRM_DEVICEREG_FIELD RCC_BASE, RCC_PLLCFGR, RCC_PLLCFGR_PLLSRC_Pos, RCC_PLLCFGR_PLLSRC_Msk, RCC_PLLCFGR_PLLSRC_HSI
	bne 1b

	@; )	update and confirm : turn PLL 'ON' (RCC_CR_PLLON=1, RCC_CR_PLLRDY=1)
	mUPDATE_DEVICEREG_BIT_TO_1 	RCC_BASE, RCC_CR, 	RCC_CR_PLLON_Pos, 	RCC_CR_PLLON_Msk
1:	mCONFIRM_DEVICEREG_BIT_EQ_1	RCC_BASE, RCC_CR, 	RCC_CR_PLLRDY_Pos, 	RCC_CR_PLLRDY_Msk	
	bne 1b

	@; )	update and confirm : switch over to clock as the main domain clock (RCC_PLLCFGR_PLLREN) (RCLK will used as SysClk when PLL is clock source)
	mUPDATE_DEVICEREG_BIT_TO_1 	RCC_BASE, RCC_PLLCFGR, 	RCC_PLLCFGR_PLLREN_Pos, 	RCC_PLLCFGR_PLLREN_Msk
1:	mCONFIRM_DEVICEREG_BIT_EQ_1	RCC_BASE, RCC_PLLCFGR, 	RCC_PLLCFGR_PLLREN_Pos, 	RCC_PLLCFGR_PLLREN_Msk
	bne 1b

	@; *)	update and confirm : enable PCLK clock as subdomain clock (RCC_PLLCFGR_PLLPEN) (make PCLK alternative to SysClk for driving ADCs)
	@; *)	update and confirm : enable QCLK clock as subdomain clock (RCC_PLLCFGR_PLLQEN) (make QCLK alternative to SysClk for driving various peripherals)
	@; *)	update and confirm : AHB bus clock prescaler (RCC_CFGR_HPRE)  (reset value is 0xxx = not prescaled)
	@; *)	update and confirm : PPRE1 bus clock prescaler (RCC_CFGR_PPRE1)  (reset value is 0xxx = not prescaled)
	@; *)	update and confirm : PPRE2 bus clock prescaler (RCC_CFGR_PPRE2)  (reset value is 0xxx = not prescaled)
	@; *)	update and confirm : power scaling mode if necessary (PWR_CR5_R1MODE_SW,PWR_CR5_R1MODE_SWS)

	@; )	update and confirm : change SysClk source to PLL (RCC_CFGR_SW,RCC_CFGR_SWS)		               !!TODO check recent for bit vs field
	mUPDATE_DEVICEREG_FIELD  RCC_BASE, RCC_CFGR, 	RCC_CFGR_SW_Pos, RCC_CFGR_SW_Msk, RCC_CFGR_SW_PLL
1:	mCONFIRM_DEVICEREG_FIELD  RCC_BASE, RCC_CFGR, 	RCC_CFGR_SWS_Pos, RCC_CFGR_SWS_Msk, RCC_CFGR_SWS_PLL
	bne 1b

	@;	mystery software delay
	@; ) At this point in our attempt to follow operations found in the function "SystemClock_Config(void)"
	@; defined in ENEE440_F24\_work\0816_STM32G491_TODOs\STM32G491_CubeMXproject_ws2\Project\Core\Src\main.c  
	@; there is the following mystery software delay which we'll emulate 
	@;	/* Insure 1us transition state at intermediate medium speed clock*/
	@; 	for (__IO uint32_t i = (170 >> 1); i !=0; i--);
	@; I (wmh) assume this is to give the hardware time to get the clock switched over, and that too much time is better than too little time 
	mov r0,0x400	@; software delay
1:	subs r0,1
	bne 1b

	@; remaining operations of "SystemClock_Config(void)" in \STM32G491_CubeMXproject_ws2\Project\Core\Src\main.c  which are skipped for now	
	@; 	/* Set AHB prescaler*/
	@; 	LL_RCC_SetAHBPrescaler(LL_RCC_SYSCLK_DIV_1);
	@; 	LL_RCC_SetAPB1Prescaler(LL_RCC_APB1_DIV_1);
	@; 	LL_RCC_SetAPB2Prescaler(LL_RCC_APB2_DIV_1);

	@; and things still to do
	@; 	*)	update SysTick and SystemCoreClock value

	pop {r7,pc}


	@; System clock info based on HSI16, M, N, and R values used above. (see comment above for "update and confirm : VCO divider for PLLRCLK") 
	.pushsection .data
	.align 2
	.global SysTick_ReloadValue
		SysTick_ReloadValue: .word 72000
	.global SystemCoreClock
		SystemCoreClock: .word 72000000
	.popsection



