@; MoTdevice_device5.S DAC1OUT2 homework 8
@; commands:
@; ":050000FB OR :050001FA" init command (mode 0 or mode 1)
@; ":0501FA" deinit command
@; ":0502XXXXYY" output dac command where XXXX is some 12 bit value to be output to the dac and YY is the checksum
@; ":0503XXXXYYYYZZ" wait a delay of 16-bit YYYY ms, then output some 12 bit value XXXX to the dac. ZZ is the checksum
@; ":0504WWXXYYYYZZ" iterate through array# WW step size XX with YYYYms between steps. ZZ is the checksum
@; ":0505VVWWXXXXYYZZ" iterate through array# (0-2) VV step size WW with XXXXms between steps iterating through the array YY times. ZZ is the checksum
@; ":0506XXXXYY" output dac (cmd 2) with button trigger
@; ":0507WWXXYYYYZZ" outburst (cmd 4) with button trigger
@; ":0508VVWWXXXXYYZZ" outrepeat (cmd 5) with button trigger
@; tasks:
@; device5_skiptask	  -- transfers control to next task
@; device5_delaytask  -- waits a delay (by either polling or by an interrupt from systick) then outputs a new dac value
@; device5_bursttask  -- iterates through an array and outputs to the dac of size N with a given step size and speed
@; device5_repeattask -- iterates through an array count# of times and outputs to the dac of size N with a given step size and speed
@; device5_waitbuttontask -- waits until blue button is pressed and then installs task stored in MoT var nexttask
@; device5_outtask -- outputs a value to the dac

@the constant "N" 256 is the array size of arrays used by the burst and repeat commands
	#define __ASSEMBLY__
	#define N 256
	#include "MoTstructures.h"
	#include "bit-op_macros.S"
	#include "stm32g491xx_defines.h"
	#include "stm32g491xx_RCC.h"
	#include "stm32g491xx_GPIO.h"

	.equ NULL,0						@;for returning NULL pointr various places

	@constant DAC register offsets
	.equ DAC_CR, 0x00
	.equ DAC_DHR12R2, 0x14

	@;register equates
	rLISTP 		.req r4				@;points to the device_list[] defined in main()
	rDEVP		.req r5				@;points to the device data of the current active task.

	.syntax unified					@; ARM Unified Assembler Language (UAL) is allowed
	.thumb							@; we are using thumb instructions only

	.text							@; macros below place variable data in initialized .data, the rest in .text

@; ----- device5 command dispatch
@; Definitions of device5's command functions and tasks follow
	.global device5_cmdHandler
	.thumb_func
device5_cmdHandler:
	push {r7,lr}
	ldrb r1,[r0],#1
	and r1,0x0F
	tbh [pc,r1]
device5_cmds: @needed to change from tbb to tbh because a byte couldnt reach the last couple commands
	.hword (device5_initDAC1_OUT2 - device5_cmds)/2
	.hword (device5_deinitDAC1_OUT2 - device5_cmds)/2
	.hword (device5_outDAC1_OUT2 - device5_cmds)/2
	.hword (device5_outDAC1_OUT2_delay - device5_cmds)/2
	.hword(device5_outburstDAC1_OUT2 - device5_cmds)/2
	.hword (device5_outrepeatDAC1_OUT2 - device5_cmds)/2
	.hword(device5_triggeredoutDAC1_OUT2 - device5_cmds)/2
	.hword (device5_triggeredoutburstDAC1_OUT2 - device5_cmds)/2
	.hword (device5_triggeredoutrepeatDAC1_OUT2 - device5_cmds)/2
	.hword (device5_NOP - device5_cmds)/2
	.hword (device5_NOP - device5_cmds)/2
	.hword (device5_NOP - device5_cmds)/2
	.hword (device5_NOP - device5_cmds)/2
	.hword (device5_NOP - device5_cmds)/2
	.hword (device5_NOP - device5_cmds)/2
	.hword (device5_NOP - device5_cmds)/2
	.align 2

@DISCLAIMER: MOT VARIABLE AND MESSAGE DEFINITIONS BELOW COMMANDS SUCH THAT EACH OF THE TBB BYTES DONT BECOME TOO BIG
@commands
	@no process
	.thumb_func
device5_NOP:
	pop {r7, pc}

@intiialize the DAC1 with output OUT2
	.thumb_func
device5_initDAC1_OUT2:

	@read mode from input
	ldrb r1, [r0]
	str r1, [rDEVP, #DEVICE5_MODE]

	@ensure flag is 0
	mov r2, #0
	str r2, [rDEVP, #DEVICE5_FLAG]

	@enable PA5 to see clock and be in analog mode
	mUPDATE_DEVICEREG_BIT_TO_1 RCC_BASE, RCC_AHB2ENR, RCC_AHB2ENR_GPIOAEN_Pos, RCC_AHB2ENR_GPIOAEN_Msk
	mUPDATE_DEVICEREG_FIELD GPIOA_BASE, GPIO_MODER, GPIO_MODER_MODE5_Pos, GPIO_MODER_MODE5_Msk, 3 << GPIO_MODER_MODE5_Pos

	@reset DAC1
	mUPDATE_DEVICEREG_BIT_TO_1 RCC_BASE, RCC_AHB2RSTR, RCC_AHB2RSTR_DAC1RST_Pos, RCC_AHB2RSTR_DAC1RST_Msk
	mUPDATE_DEVICEREG_BIT_TO_0 RCC_BASE, RCC_AHB2RSTR, RCC_AHB2RSTR_DAC1RST_Pos, RCC_AHB2RSTR_DAC1RST_Msk

	@clock enable and enable out2
	mUPDATE_DEVICEREG_BIT_TO_1 RCC_BASE, RCC_AHB2ENR, RCC_AHB2ENR_DAC1EN_Pos, RCC_AHB2ENR_DAC1EN_Msk
	mUPDATE_DEVICEREG_BIT_TO_1 DAC1_BASE, DAC_CR, DAC_CR_EN2_Pos, DAC_CR_EN2_Msk

	@also intialize for use of trigger commands, taken from bluebutton mot device
	@; set port enable bit (manual pg 492)
	ldr r3,=RCC_BASE			@;load RCC struct address
	ldr r2,[r3,#RCC_AHB2ENR]	@;get current values of device enables
	orr r2,#(1<<2)		@;enable port
	str r2,[r3,#RCC_AHB2ENR]	@; ..

	@; configure as an input (manual pg 578)
	ldr r3,=GPIOC_BASE			@;load GPIOx struct address
	ldr r2,[r3,#GPIO_MODER]			@;get current mode values of port
	bic r2,#(3<<(2*13))		@;clear current mode value of port bit
	orr	r2,#(0<<(2*13))		@;set new mode value of port bit to input
	str r2,[r3,#GPIO_MODER]			@; ..

	@; configure with no pullup, pulldown
	ldr r2,[r3,#GPIO_PUPDR]			@;get current pu/pd settings of port
	bic r2,#(3<<(2*13))		@;clear current pupd value of port bit (=no pu/pd)
	orr r2,#(2<<(2*13))     @set to pulldown
	str r2,[r3,#GPIO_PUPDR]			@; ..

	@print mode dependent message
	ldr r1, [rDEVP, #DEVICE5_MODE]
	cmp r1, #0
	beq poll_init
	b interrupt_init
poll_init:
	add r0, rDEVP, #INITDAC1_OUT2P_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost
	pop {r7, pc}
interrupt_init:
	add r0, rDEVP, #INITDAC1_OUT2I_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost
	pop {r7, pc}

	.thumb_func
device5_deinitDAC1_OUT2:

	@reset DAC1
	mUPDATE_DEVICEREG_BIT_TO_1 RCC_BASE, RCC_AHB2RSTR, RCC_AHB2RSTR_DAC1RST_Pos, RCC_AHB2RSTR_DAC1RST_Msk
	mUPDATE_DEVICEREG_BIT_TO_0 RCC_BASE, RCC_AHB2RSTR, RCC_AHB2RSTR_DAC1RST_Pos, RCC_AHB2RSTR_DAC1RST_Msk

	add r0, rDEVP, #DEINITDAC1_OUT2_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost
	pop {r7, pc}

	.thumb_func
device5_outDAC1_OUT2:

	@read 16-bit value from input
	ldrh r1, [r0]

	@mask to 12-bit value and shift to correct position
	MOV_imm32 r2, 0x0FFF
	and r1, r1, r2
	lsl r1, r1, #DAC_DHR12R2_DACC2DHR_Pos

	@store value in DHR12R2 data holding register
	ldr r3, =DAC1_BASE
	str r1, [r3, #DAC_DHR12R2]

	add r0, rDEVP, #OUTDAC1_OUT2_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

	pop {r7, pc}

    .thumb_func
device5_outDAC1_OUT2_delay:

	@load command arguments
    ldrh r1, [r0], #2
    str r1, [rDEVP, #DEVICE5_VALUE]
    ldrh r3, [r0], #2

    @store lower 32 bits of absmsecs in r0 and upper bits in r1
    MOV_imm32 r2, SysTick_absmsecs
	ldr r0, [r2]
	ldr r1, [r2, #4]

	@calculate target time = current time + delay parameter
	adds r0, r0, r3
	adc r1, r1, #0

	@store target time in MoT variables
	str r0, [rDEVP, #DEVICE5_TARGET_LO]
	str r1, [rDEVP, #DEVICE5_TARGET_HI]

	@clear flag before installing task
	mov r2, #0
	str r2, [rDEVP, #DEVICE5_FLAG]

  	@install delay task to wait out delay and update value
    MOV_imm32 r0, device5_delaytask
    mov r1, #NULL
    bl MoT_taskUpdate

    add r0, rDEVP, #OUTDAC1_OUT2_DELAY_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

    pop {r7, pc}

    .thumb_func
device5_outburstDAC1_OUT2:
	@load input parameters and set MoT variables
	ldrb r1, [r0], #1
	ldrb r2, [r0], #1
	str r2, [rDEVP, #DEVICE5_STEP]
	ldrh r2, [r0], #2
	str r2, [rDEVP, #DEVICE5_SPEED]
	mov r2, #0
	str r2, [rDEVP, #DEVICE5_ARRIDX]

	@load arrayptr based on array# from input
	cmp r1, #0
	beq outburst_sine
	cmp r1, #1
	beq outburst_triangle
	cmp r1, #2
	beq outburst_sawtooth
	b finish_outburst
outburst_sine:
	ldr r2, =sine_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_outburst
outburst_triangle:
	ldr r2, =triangle_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_outburst
outburst_sawtooth:
	ldr r2, =sawtooth_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_outburst
finish_outburst:

    @store lower 32 bits of absmsecs in r0 and upper bits in r1
    MOV_imm32 r2, SysTick_absmsecs
	ldr r0, [r2]
	ldr r1, [r2, #4]

	@calculate first target time = current time + speed parameter
	ldr r3, [rDEVP, #DEVICE5_SPEED]
	adds r0, r0, r3
	adc r1, r1, #0

	@store target time in MoT variables
	str r0, [rDEVP, #DEVICE5_TARGET_LO]
	str r1, [rDEVP, #DEVICE5_TARGET_HI]

	@clear flag before installing task
	mov r2, #0
	str r2, [rDEVP, #DEVICE5_FLAG]

	@install burst task to iterate through array
    MOV_imm32 r0, device5_bursttask
    mov r1, #NULL
    bl MoT_taskUpdate

    add r0, rDEVP, #OUTBURSTOUTDAC1_OUT2_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

	pop {r7, pc}


	.thumb_func
device5_outrepeatDAC1_OUT2:
	@load input parameters and set MoT variables
	ldrb r1, [r0], #1
	ldrb r2, [r0], #1
	str r2, [rDEVP, #DEVICE5_STEP]
	ldrh r2, [r0], #2
	str r2, [rDEVP, #DEVICE5_SPEED]
	ldrb r2, [r0], #1
	str r2, [rDEVP, #DEVICE5_COUNT]
	mov r2, #0
	str r2, [rDEVP, #DEVICE5_ARRIDX]

	@load arrayptr based on array# from input
	cmp r1, #0
	beq outrepeat_sine
	cmp r1, #1
	beq outrepeat_triangle
	cmp r1, #2
	beq outrepeat_sawtooth
	b finish_outrepeat
outrepeat_sine:
	ldr r2, =sine_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_outrepeat
outrepeat_triangle:
	ldr r2, =triangle_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_outrepeat
outrepeat_sawtooth:
	ldr r2, =sawtooth_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_outrepeat
finish_outrepeat:
    @store lower 32 bits of absmsecs in r0 and upper bits in r1
    MOV_imm32 r2, SysTick_absmsecs
	ldr r0, [r2]
	ldr r1, [r2, #4]

	@calculate first target time = current time + speed parameter
	ldr r3, [rDEVP, #DEVICE5_SPEED]
	adds r0, r0, r3
	adc r1, r1, #0

	@store target time in MoT variables
	str r0, [rDEVP, #DEVICE5_TARGET_LO]
	str r1, [rDEVP, #DEVICE5_TARGET_HI]

	@clear flag before installing task
	mov r2, #0
	str r2, [rDEVP, #DEVICE5_FLAG]

	@install repeat task to iterate through array count# of times
    MOV_imm32 r0, device5_repeattask
    mov r1, #NULL
    bl MoT_taskUpdate

    add r0, rDEVP, #OUTREPEATOUTDAC1_OUT2_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

	pop {r7, pc}

	.thumb_func
device5_triggeredoutDAC1_OUT2:
	@load dacval and store to MoT variable
	ldrh r1, [r0], #2
    str r1, [rDEVP, #DEVICE5_VALUE]
    @store task to go to after button trigger
    MOV_imm32 r1, device5_outtask
    str r1, [rDEVP, #DEVICE5_NEXTTASK]
    @install button task
    MOV_imm32 r0, device5_waitbuttontask
    mov r1, #NULL
    bl MoT_taskUpdate

    add r0, rDEVP, #TRIGGEREDOUTDAC1_OUT2_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

	pop {r7, pc}

	.thumb_func
device5_triggeredoutburstDAC1_OUT2:
	@load input parameters and set MoT variables
	ldrb r1, [r0], #1
	ldrb r2, [r0], #1
	str r2, [rDEVP, #DEVICE5_STEP]
	ldrh r2, [r0], #2
	str r2, [rDEVP, #DEVICE5_SPEED]
	mov r2, #0
	str r2, [rDEVP, #DEVICE5_ARRIDX]

	@load arrayptr based on array# from input
	cmp r1, #0
	beq triggeredoutburst_sine
	cmp r1, #1
	beq triggeredoutburst_triangle
	cmp r1, #2
	beq triggeredoutburst_sawtooth
	b finish_triggeredoutburst
triggeredoutburst_sine:
	ldr r2, =sine_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_triggeredoutburst
triggeredoutburst_triangle:
	ldr r2, =triangle_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_triggeredoutburst
triggeredoutburst_sawtooth:
	ldr r2, =sawtooth_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_triggeredoutburst
finish_triggeredoutburst:

    @store lower 32 bits of absmsecs in r0 and upper bits in r1
    MOV_imm32 r2, SysTick_absmsecs
	ldr r0, [r2]
	ldr r1, [r2, #4]

	@calculate first target time = current time + speed parameter
	ldr r3, [rDEVP, #DEVICE5_SPEED]
	adds r0, r0, r3
	adc r1, r1, #0

	@store target time in MoT variables
	str r0, [rDEVP, #DEVICE5_TARGET_LO]
	str r1, [rDEVP, #DEVICE5_TARGET_HI]

	MOV_imm32 r1, device5_bursttask
    str r1, [rDEVP, #DEVICE5_NEXTTASK]

    @clear flag before installing task
	mov r2, #0
	str r2, [rDEVP, #DEVICE5_FLAG]

	MOV_imm32 r0, device5_waitbuttontask
    mov r1, #NULL
    bl MoT_taskUpdate

    add r0, rDEVP, #TRIGGEREDOUTBURSTOUTDAC1_OUT2_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

	pop {r7, pc}

	.thumb_func
device5_triggeredoutrepeatDAC1_OUT2:
	@load input parameters and set MoT variables
	ldrb r1, [r0], #1
	ldrb r2, [r0], #1
	str r2, [rDEVP, #DEVICE5_STEP]
	ldrh r2, [r0], #2
	str r2, [rDEVP, #DEVICE5_SPEED]
	ldrb r2, [r0], #1
	str r2, [rDEVP, #DEVICE5_COUNT]
	mov r2, #0
	str r2, [rDEVP, #DEVICE5_ARRIDX]

	@load arrayptr based on array# from input
	cmp r1, #0
	beq triggeredoutrepeat_sine
	cmp r1, #1
	beq triggeredoutrepeat_triangle
	cmp r1, #2
	beq triggeredoutrepeat_sawtooth
	b finish_triggeredoutrepeat
triggeredoutrepeat_sine:
	ldr r2, =sine_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_triggeredoutrepeat
triggeredoutrepeat_triangle:
	ldr r2, =triangle_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_triggeredoutrepeat
triggeredoutrepeat_sawtooth:
	ldr r2, =sawtooth_wave
	str r2, [rDEVP, #DEVICE5_ARRPTR]
	b finish_triggeredoutrepeat
finish_triggeredoutrepeat:

    @store lower 32 bits of absmsecs in r0 and upper bits in r1
    MOV_imm32 r2, SysTick_absmsecs
	ldr r0, [r2]
	ldr r1, [r2, #4]

	@calculate first target time = current time + speed parameter
	ldr r3, [rDEVP, #DEVICE5_SPEED]
	adds r0, r0, r3
	adc r1, r1, #0

	@store target time in MoT variables
	str r0, [rDEVP, #DEVICE5_TARGET_LO]
	str r1, [rDEVP, #DEVICE5_TARGET_HI]

	@store task to be triggered by button
	MOV_imm32 r1, device5_repeattask
    str r1, [rDEVP, #DEVICE5_NEXTTASK]

    @clear flag before installing task
	mov r2, #0
	str r2, [rDEVP, #DEVICE5_FLAG]

	@install wait button task
	MOV_imm32 r0, device5_waitbuttontask
    mov r1, #NULL
    bl MoT_taskUpdate

    @print message
    add r0, rDEVP, #TRIGGEREDOUTREPEATOUTDAC1_OUT2_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

	pop {r7, pc}


	@needed by SysTick_definitions.S
	.global device5_mode
    .global device5_targettime_lo
    .global device5_targettime_hi
    .global device5_flag

    MoT_core_m device5, device5_cmdHandler, device5_skiptask
	MoT_varAlloc_m device5_mode, DEVICE5_MODE
	MoT_varAlloc_m device5_value, DEVICE5_VALUE  @DAC value to output
	MoT_varAlloc_m device5_targettime_lo, DEVICE5_TARGET_LO @low bits of target absmsecs
	MoT_varAlloc_m device5_targettime_hi, DEVICE5_TARGET_HI @high bits of target absmsecs
	MoT_varAlloc_m device5_flag, DEVICE5_FLAG @for interrupt mode
	MoT_varAlloc_m device5_arrptr, DEVICE5_ARRPTR @pointer to start of array
	MoT_varAlloc_m device5_arridx, DEVICE5_ARRIDX @current index into array
	MoT_varAlloc_m device5_step, DEVICE5_STEP @index step size for burst and repeat
	MoT_varAlloc_m device5_speed, DEVICE5_SPEED @ms between updates
	MoT_varAlloc_m device5_count, DEVICE5_COUNT @repeat count for cmd 5
	MoT_varAlloc_m device5_nexttask, DEVICE5_NEXTTASK @next task for blue button triggering

	@initalized message (polling)
	MoT_msgLink_m INITDAC1_OUT2P_msg, INITDAC1_OUT2P_msgtxt, INITDAC1_OUT2P_msglen,
	INITDAC1_OUT2P_msgtxt:
	.ascii "DAC1 initialized to output OUT2 (LD2 LED or GPIO pin A5) in POLLING mode\n\r\0"
	.equ INITDAC1_OUT2P_msglen, ( . - INITDAC1_OUT2P_msgtxt)

	@initalized message (interrupt)
	MoT_msgLink_m INITDAC1_OUT2I_msg, INITDAC1_OUT2I_msgtxt, INITDAC1_OUT2I_msglen,
	INITDAC1_OUT2I_msgtxt:
	.ascii "DAC1 initialized to output OUT2 (LD2 LED or GPIO pin A5) in INTERRUPT mode \n\r\0"
	.equ INITDAC1_OUT2I_msglen, ( . - INITDAC1_OUT2I_msgtxt)

	@deinitialized message
	MoT_msgLink_m DEINITDAC1_OUT2_msg, DEINITDAC1_OUT2_msgtxt, DEINITDAC1_OUT2_msglen,
	DEINITDAC1_OUT2_msgtxt:
	.ascii "DAC1 deinitialized\n\r\0"
	.equ DEINITDAC1_OUT2_msglen, ( . - DEINITDAC1_OUT2_msgtxt)

	@outdac message
	MoT_msgLink_m OUTDAC1_OUT2_msg, OUTDAC1_OUT2_msgtxt, OUTDAC1_OUT2_msglen,
	OUTDAC1_OUT2_msgtxt:
	.ascii "Value output to LD2 through DAC1 \n\r\0"
	.equ OUTDAC1_OUT2_msglen, ( . - OUTDAC1_OUT2_msgtxt)

	@outdac with delay message
	MoT_msgLink_m OUTDAC1_OUT2_DELAY_msg, OUTDAC1_OUT2_DELAY_msgtxt, OUTDAC1_OUT2_DELAY_msglen,
	OUTDAC1_OUT2_DELAY_msgtxt:
	.ascii "Delay started. Value will output to LD2 through DAC1 afted delay\n\r\0"
	.equ OUTDAC1_OUT2_DELAY_msglen, ( . - OUTDAC1_OUT2_DELAY_msgtxt)

	@outburst message
	MoT_msgLink_m OUTBURSTOUTDAC1_OUT2_msg, OUTBURSTOUTDAC1_OUT2_msgtxt, OUTBURSTOUTDAC1_OUT2_msglen,
	OUTBURSTOUTDAC1_OUT2_msgtxt:
	.ascii "Outburst intialized. \n\r\0"
	.equ OUTBURSTOUTDAC1_OUT2_msglen, ( . - OUTBURSTOUTDAC1_OUT2_msgtxt)

	@outrepeat message
	MoT_msgLink_m OUTREPEATOUTDAC1_OUT2_msg, OUTREPEATOUTDAC1_OUT2_msgtxt, OUTREPEATOUTDAC1_OUT2_msglen,
	OUTREPEATOUTDAC1_OUT2_msgtxt:
	.ascii "Repeat intialized. \n\r\0"
	.equ OUTREPEATOUTDAC1_OUT2_msglen, ( . - OUTREPEATOUTDAC1_OUT2_msgtxt)

	@triggered outdac message
	MoT_msgLink_m TRIGGEREDOUTDAC1_OUT2_msg, TRIGGEREDOUTDAC1_OUT2_msgtxt, TRIGGEREDOUTDAC1_OUT2_msglen,
	TRIGGEREDOUTDAC1_OUT2_msgtxt:
	.ascii "Value will output to LD2 through DAC1 after button trigger\n\r\0"
	.equ TRIGGEREDOUTDAC1_OUT2_msglen, ( . - TRIGGEREDOUTDAC1_OUT2_msgtxt)

	@triggered outburst message
	MoT_msgLink_m TRIGGEREDOUTBURSTOUTDAC1_OUT2_msg, TRIGGEREDOUTBURSTOUTDAC1_OUT2_msgtxt, TRIGGEREDOUTBURSTOUTDAC1_OUT2_msglen,
	TRIGGEREDOUTBURSTOUTDAC1_OUT2_msgtxt:
	.ascii "Press blue button to intialize outburst. \n\r\0"
	.equ TRIGGEREDOUTBURSTOUTDAC1_OUT2_msglen, ( . - TRIGGEREDOUTBURSTOUTDAC1_OUT2_msgtxt)

	@triggered outrepeat message
	MoT_msgLink_m TRIGGEREDOUTREPEATOUTDAC1_OUT2_msg, TRIGGEREDOUTREPEATOUTDAC1_OUT2_msgtxt, TRIGGEREDOUTREPEATOUTDAC1_OUT2_msglen,
	TRIGGEREDOUTREPEATOUTDAC1_OUT2_msgtxt:
	.ascii "Press blue button to initialize outrepeat. \n\r\0"
	.equ TRIGGEREDOUTREPEATOUTDAC1_OUT2_msglen, ( . - TRIGGEREDOUTREPEATOUTDAC1_OUT2_msgtxt)

@task definitions
@delay task that waits a delay then updates the DAC to the next value
    .global device5_delaytask
    .thumb_func
device5_delaytask:
	@check which mode we're in and branch to the corresponding logic
    ldr r1, [rDEVP, #DEVICE5_MODE]
    cmp r1, #0
    beq device5_delaytask_poll
    b device5_delaytask_irq

device5_delaytask_poll:
	@for polling we compare start + delay (target time) to current time and skiptask until the delay is over
    ldr r0, [rDEVP, #DEVICE5_TARGET_HI]
	MOV_imm32 r2, SysTick_absmsecs
	ldr r1, [r2, #4]
	cmp r1, r0
	blo device5_skiptask
	ldr r0, [rDEVP, #DEVICE5_TARGET_LO]
	ldr r1, [r2]
	cmp r1, r0
	blo device5_skiptask
	b device5_delaytask_done

device5_delaytask_irq:
	@for interrupts we wait until the flag is raised to execute logic
	ldr r0, [rDEVP, #DEVICE5_FLAG]
	cmp r0, #0
	beq device5_skiptask
	@clear flag
	mov r0, #0
	str r0, [rDEVP, #DEVICE5_FLAG]
	b device5_delaytask_done

device5_delaytask_done:
	ldr r0, [rDEVP, #DEVICE5_VALUE]

	@mask to 12-bit value and shift to correct position
	MOV_imm32 r2, 0x0FFF
	and r0, r0, r2
	lsl r0, r0, #DAC_DHR12R2_DACC2DHR_Pos

	@store value in DHR12R2 data holding register
	ldr r3, =DAC1_BASE
	str r0, [r3, #DAC_DHR12R2]

	@reinstall skiptask
	MOV_imm32 r0, device5_skiptask
    mov r1, #NULL
    bl MoT_taskUpdate

    b device5_skiptask

    .global device5_bursttask
    .thumb_func
device5_bursttask:
	@check which mode we're in and branch to the corresponding logic
    ldr r1, [rDEVP, #DEVICE5_MODE]
    cmp r1, #0
    beq device5_bursttask_poll
    b device5_bursttask_irq

device5_bursttask_poll:
	@for polling we compare start + delay (target time) to current time and skiptask until the delay is over
    ldr r0, [rDEVP, #DEVICE5_TARGET_HI]
	MOV_imm32 r2, SysTick_absmsecs
	ldr r1, [r2, #4] @current absmsecs high bits
	cmp r1, r0 @compare high bits
	blo device5_skiptask
	ldr r0, [rDEVP, #DEVICE5_TARGET_LO]
	ldr r1, [r2] @current absmsecs lower bits
	cmp r1, r0 @compare low bits
	blo device5_skiptask
	b device5_bursttask_iter

device5_bursttask_irq:
	@for interrupts we wait until the flag is raised to execute logic
	ldr r0, [rDEVP, #DEVICE5_FLAG]
	cmp r0, #0
	beq device5_skiptask
	@clear flag
	mov r0, #0
	str r0, [rDEVP, #DEVICE5_FLAG]
	b device5_bursttask_iter

device5_bursttask_iter:
	ldr r2, [rDEVP, #DEVICE5_ARRPTR]
	ldr r3, [rDEVP, #DEVICE5_ARRIDX]
	lsl r3, r3, #1  @multiply by 2 since its an array of uint16_t
	ldrh r0, [r2, r3]

	@mask to 12-bit value and shift to correct position
	MOV_imm32 r2, 0x0FFF
	and r0, r0, r2
	lsl r0, r0, #DAC_DHR12R2_DACC2DHR_Pos

	@store value in DHR12R2 data holding register
	ldr r3, =DAC1_BASE
	str r0, [r3, #DAC_DHR12R2]

	ldr r3, [rDEVP, #DEVICE5_ARRIDX]
	ldr r2, [rDEVP, #DEVICE5_STEP]
	add r3, r3, r2  @advance idx by step
	str r3, [rDEVP, #DEVICE5_ARRIDX] @save it back
	cmp r3, #N
	bge device5_bursttask_end

	@store lower 32 bits of absmsecs in r0 and upper bits in r1
    ldr r0, [rDEVP, #DEVICE5_TARGET_LO]
	ldr r1, [rDEVP, #DEVICE5_TARGET_HI]

	@calculate first target time = current time + speed parameter
	ldr r3, [rDEVP, #DEVICE5_SPEED]
	adds r0, r0, r3
	adc r1, r1, #0

	@store target time in MoT variables
	str r0, [rDEVP, #DEVICE5_TARGET_LO]
	str r1, [rDEVP, #DEVICE5_TARGET_HI]

	b device5_skiptask

device5_bursttask_end:

	@reinstall skiptask
	MOV_imm32 r0, device5_skiptask
    mov r1, #NULL
    bl MoT_taskUpdate
    b device5_skiptask

	.global device5_repeattask
	.thumb_func
device5_repeattask:
	@check which mode we're in and branch to the corresponding logic
    ldr r1, [rDEVP, #DEVICE5_MODE]
    cmp r1, #0
    beq device5_repeattask_poll
    b device5_repeattask_irq

device5_repeattask_poll:
	@for polling we compare start + delay (target time) to current time and skiptask until the delay is over
    ldr r0, [rDEVP, #DEVICE5_TARGET_HI]
	MOV_imm32 r2, SysTick_absmsecs
	ldr r1, [r2, #4] @current absmsecs high bits
	cmp r1, r0 @ compare high bits first
	blo device5_skiptask
	ldr r0, [rDEVP, #DEVICE5_TARGET_LO]
	ldr r1, [r2] @current absmsecs low bits
	cmp r1, r0 @compare low bits
	blo device5_skiptask
	b device5_repeattask_iter

device5_repeattask_irq:
	@for interrupts we wait until the flag is raised to execute logic
	ldr r0, [rDEVP, #DEVICE5_FLAG]
	cmp r0, #0
	beq device5_skiptask
	@clear flag
	mov r0, #0
	str r0, [rDEVP, #DEVICE5_FLAG]
	b device5_repeattask_iter

device5_repeattask_iter:
	ldr r2, [rDEVP, #DEVICE5_ARRPTR]
	ldr r3, [rDEVP, #DEVICE5_ARRIDX]
	lsl r3, r3, #1 @multiply by 2 since uint16_t is 2 bytes
	ldrh r0, [r2, r3]

	@mask to 12-bit value and shift to correct position
	MOV_imm32 r2, 0x0FFF
	and r0, r0, r2
	lsl r0, r0, #DAC_DHR12R2_DACC2DHR_Pos

	@store value in DHR12R2 data holding register
	ldr r3, =DAC1_BASE
	str r0, [r3, #DAC_DHR12R2]

	@advance arrayidx and branch to repeat handler if necessary
	ldr r3, [rDEVP, #DEVICE5_ARRIDX]
	ldr r2, [rDEVP, #DEVICE5_STEP]
	add r3, r3, r2   @advance by step
	cmp r3, #N
	bge repeat_loop
	str r3, [rDEVP, #DEVICE5_ARRIDX]
	b finish_iter

repeat_loop:
	@check if we have to repeat array
	ldr r1, [rDEVP, #DEVICE5_COUNT]
	cmp r1, #0
	beq device5_repeattask_end
	sub r1, r1, #1
	@set array idx to arrayidx mod arraysize
	sub r3, r3, #N
	str r3, [rDEVP, #DEVICE5_ARRIDX]
	str r1, [rDEVP, #DEVICE5_COUNT]
	@ recompute target from current time at wrap point
    MOV_imm32 r2, SysTick_absmsecs
    ldr r0, [r2]
    ldr r1, [r2, #4]
    ldr r3, [rDEVP, #DEVICE5_SPEED]
    adds r0, r0, r3
    adc r1, r1, #0
    str r0, [rDEVP, #DEVICE5_TARGET_LO]
    str r1, [rDEVP, #DEVICE5_TARGET_HI]
    b device5_skiptask          @ skip finish_iter entirely at wrap

finish_iter:
	@store lower 32 bits of absmsecs in r0 and upper bits in r1
    ldr r0, [rDEVP, #DEVICE5_TARGET_LO]
	ldr r1, [rDEVP, #DEVICE5_TARGET_HI]

	@calculate first target time = current time + speed parameter
	ldr r3, [rDEVP, #DEVICE5_SPEED]
	adds r0, r0, r3
	adc r1, r1, #0

	@store target time in MoT variables
	str r0, [rDEVP, #DEVICE5_TARGET_LO]
	str r1, [rDEVP, #DEVICE5_TARGET_HI]

	b device5_skiptask

device5_repeattask_end:

	@clear flag
	mov r0, #0
	str r0, [rDEVP, #DEVICE5_FLAG]

	@reinstall skiptask
	MOV_imm32 r0, device5_skiptask
    mov r1, #NULL
    bl MoT_taskUpdate
    b device5_skiptask

    .global device5_waitbuttontask
    .thumb_func
device5_waitbuttontask:
	ldr r3, =GPIOC_BASE
    ldr r0, [r3, #GPIO_IDR]
    tst r0, #(1<<13)
    beq device5_skiptask  @not pressed yet
    @clear flag
	mov r0, #0
	str r0, [rDEVP, #DEVICE5_FLAG]
    @button pressed so install stored next task
    ldr r0, [rDEVP, #DEVICE5_NEXTTASK]
    mov r1, #NULL
    bl MoT_taskUpdate
    b device5_skiptask

    .global device5_outtask
    .thumb_func
device5_outtask:
	ldr r0, [rDEVP, #DEVICE5_VALUE]

	@mask to 12-bit value and shift to correct position
	MOV_imm32 r2, 0x0FFF
	and r0, r0, r2
	lsl r0, r0, #DAC_DHR12R2_DACC2DHR_Pos

	@store value in DHR12R2 data holding register
	ldr r3, =DAC1_BASE
	str r0, [r3, #DAC_DHR12R2]

	MOV_imm32 r0, device5_skiptask
    mov r1, #NULL
    bl MoT_taskUpdate

	b device5_skiptask


	.global device5_skiptask
	.thumb_func
device5_skiptask:
	ldr rDEVP,[rDEVP,#NEXTTASK]
	ldr pc,[rDEVP,#XEQTASK]
