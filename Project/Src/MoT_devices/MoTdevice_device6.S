@; MoTdevice_device6.S DAC1OUT2 homework 8
@; commands:
@; :0600FA -- initialize TIM2 to 1MHz and leave interupts off
@; :0601tttttttt<chksum> -- set interrupt interval to tttttttt us and INTcount to 0
@; :0602F8 -- start interrupt driven led toggle and start incrementing intcount
@; :0603F7 -- set cyclecount to 0 and install cyclecount task to start incrementing cycle count
@; :0604F6 -- output cycle count and int count to console
@; :0605tttttttt<chksum> -- after blue button press, wait tttttttt us then turn led on
@; :0606ttttttttssssssss<chksum> -- after blue button press, wait tttttttt us then led on, ssssssss us then turn led off
@; tasks:
@; device6_skiptask	  -- transfers control to next task
@; device6_TIM2_CYCLEcount_task -- increments cycle count once per MoT cycle
@; device6_waitbuttontask -- waits for the blue button to be pressed then starts TIM2

	#define __ASSEMBLY__
	#include "MoTstructures.h"
	#include "bit-op_macros.S"
	#include "stm32g491xx_defines.h"
	#include "stm32g491xx_RCC.h"
	#include "stm32g491xx_GPIO.h"

	.equ NULL,0						@;for returning NULL pointr various places

	@; offsets to registers in TIM2 control array
	.equ	CR1,	0x00	@;	  __IO uint32_t CR1;              TIM control register 1,              Address offset: 0x00
	.equ	CR2,	0x04	@;	  __IO uint32_t CR2;              TIM control register 2,              Address offset: 0x04
	.equ	SMCR,	0x08	@;	  __IO uint32_t SMCR;             TIM slave mode control register,     Address offset: 0x08
	.equ	DIER,	0x0C	@;	  __IO uint32_t DIER;             TIM DMA/interrupt enable register,   Address offset: 0x0C
	.equ	SR,		0x10	@;	  __IO uint32_t SR;               TIM status register,                 Address offset: 0x10
	.equ	EGR,	0x14	@;	  __IO uint32_t EGR;              TIM event generation register,       Address offset: 0x14
	.equ	CCMR1,	0x18	@;	  __IO uint32_t CCMR1;            TIM capture/compare mode register 1, Address offset: 0x18
	.equ	CCMR2,	0x1C	@;	  __IO uint32_t CCMR2;            TIM capture/compare mode register 2, Address offset: 0x1C
	.equ	CCER,	0x20	@;	  __IO uint32_t CCER;             TIM capture/compare enable register, Address offset: 0x20
	.equ	CNT,	0x24	@;	  __IO uint32_t CNT;              TIM counter register,                Address offset: 0x24
	.equ	PSC,	0x28	@;	  __IO uint32_t PSC;              TIM prescaler,                       Address offset: 0x28
	.equ	ARR,	0x2C	@;	  __IO uint32_t ARR;              TIM auto-reload register,            Address offset: 0x2C
	.equ	RCR,	0x30	@;	  __IO uint32_t RCR;              TIM repetition counter register,     Address offset: 0x30
	.equ	CCR1,	0x34	@;	  __IO uint32_t CCR1;             TIM capture/compare register 1,      Address offset: 0x34
	.equ	CCR2,	0x38	@;	  __IO uint32_t CCR2;             TIM capture/compare register 2,      Address offset: 0x38
	.equ	CCR3,	0x3C	@;	  __IO uint32_t CCR3;             TIM capture/compare register 3,      Address offset: 0x3C
	.equ	CCR4,	0x40	@;	  __IO uint32_t CCR4;             TIM capture/compare register 4,      Address offset: 0x40
	.equ	BDTR,	0x44	@;	  __IO uint32_t BDTR;             TIM break and dead-time register,    Address offset: 0x44
	.equ	DCR,	0x48	@;	  __IO uint32_t DCR;              TIM DMA control register,            Address offset: 0x48
	.equ	DMAR,	0x4C	@;	  __IO uint32_t DMAR;             TIM DMA address for full transfer,   Address offset: 0x4C
	.equ	OR,		0x50	@;	  __IO uint32_t OR;               TIM option register,                 Address offset: 0x50
	.equ	CCMR3,	0x54	@;	  __IO uint32_t CCMR3;            TIM capture/compare mode register 3,      Address offset: 0x54
	.equ	CCR5,	0x58	@;	  __IO uint32_t CCR5;             TIM capture/compare mode register5,       Address offset: 0x58
	.equ	CCR6,	0x5C	@;	  __IO uint32_t CCR6;             TIM capture/compare mode register6,       Address offset: 0x5C
	.equ	AF1,	0x60	@;	  __IO uint32_t AF1;              TIM Alternate function option register 1, Address offset: 0x60
	.equ	AF2,	0x64	@;	  __IO uint32_t AF2;              TIM Alternate function option register 2, Address offset: 0x64

	@;register equates
	rLISTP 		.req r4				@;points to the device_list[] defined in main()
	rDEVP		.req r5				@;points to the device data of the current active task.

	.syntax unified					@; ARM Unified Assembler Language (UAL) is allowed
	.thumb							@; we are using thumb instructions only

	.text							@; macros below place variable data in initialized .data, the rest in .text

@; ----- device6 command dispatch
@; Definitions of device6's command functions and tasks follow
	.global device6_cmdHandler
	.thumb_func
device6_cmdHandler:
	push {r7,lr}
	ldrb r1,[r0],#1
	and r1,0x07
	tbh [pc,r1]
device6_cmds:
	.hword (device6_cmd0 - device6_cmds)/2
	.hword (device6_cmd1 - device6_cmds)/2
	.hword (device6_cmd2 - device6_cmds)/2
	.hword (device6_cmd3 - device6_cmds)/2
	.hword (device6_cmd4 - device6_cmds)/2
	.hword (device6_cmd5 - device6_cmds)/2
	.hword (device6_cmd6 - device6_cmds)/2
	.hword (device6_NOP - device6_cmds)/2
	.align 1


	.global device6_TIM2_INTcount
	.global device6_TIM2_CYCLEcount
	.global device6_irq_state
	.global device6_offdelay

	MoT_core_m device6, device6_cmdHandler, device6_skiptask
	MoT_varAlloc_m device6_TIM2_INTcount, DEVICE6_TIM2_INTCOUNT
	MoT_varAlloc_m device6_TIM2_CYCLEcount, DEVICE6_TIM2_CYCLECOUNT
	MoT_varAlloc_m device6_irq_state, DEVICE6_IRQ_STATE
	MoT_varAlloc_m device6_offdelay, DEVICE6_OFFDELAY

	@manually create MoT_msgLink_m structure for cmd4
	.section .data
	.align 2
device6_printbuf_link:
    .word 0 @next pointer
    .word device6_printbuf_txt @pointer to text, populated in cmd4
    .word 24 @length
device6_printbuf_txt:
    .space 24

    .text

	MoT_msgLink_m DEVICE6_CMD0_msg, DEVICE6_CMD0_msgtxt, DEVICE6_CMD0_msglen,
	DEVICE6_CMD0_msgtxt:
	.ascii "TIM2 initialized to 1MHz. Interrupts are off.\n\r\0"
	.equ DEVICE6_CMD0_msglen, ( . - DEVICE6_CMD0_msgtxt)

	MoT_msgLink_m DEVICE6_CMD1_msg, DEVICE6_CMD1_msgtxt, DEVICE6_CMD1_msglen,
	DEVICE6_CMD1_msgtxt:
	.ascii "Interrupt interval updated. INTcount set to 0.\n\r\0"
	.equ DEVICE6_CMD1_msglen, ( . - DEVICE6_CMD1_msgtxt)

	MoT_msgLink_m DEVICE6_CMD2_msg, DEVICE6_CMD2_msgtxt, DEVICE6_CMD2_msglen,
	DEVICE6_CMD2_msgtxt:
	.ascii "Interrupt driven toggle started. INTcount is being incremented.\n\r\0"
	.equ DEVICE6_CMD2_msglen, ( . - DEVICE6_CMD2_msgtxt)

	MoT_msgLink_m DEVICE6_CMD3_msg, DEVICE6_CMD3_msgtxt, DEVICE6_CMD3_msglen,
	DEVICE6_CMD3_msgtxt:
	.ascii "CYCLEcount set to 0. CYCLEcount_task installed. CYCLEcount is being incremented.\n\r\0"
	.equ DEVICE6_CMD3_msglen, ( . - DEVICE6_CMD3_msgtxt)

	MoT_msgLink_m DEVICE6_CMD4_msg, DEVICE6_CMD4_msgtxt, DEVICE6_CMD4_msglen,
	DEVICE6_CMD4_msgtxt:
	.ascii "CYCLEcount and INTcount printed above respectively.\n\r\0"
	.equ DEVICE6_CMD4_msglen, ( . - DEVICE6_CMD4_msgtxt)

	MoT_msgLink_m DEVICE6_CMD5_msg, DEVICE6_CMD5_msgtxt, DEVICE6_CMD5_msglen,
	DEVICE6_CMD5_msgtxt:
	.ascii "When blue button is pressed, LED will be turned on after delay.\n\r\0"
	.equ DEVICE6_CMD5_msglen, ( . - DEVICE6_CMD5_msgtxt)

	MoT_msgLink_m DEVICE6_CMD6_msg, DEVICE6_CMD6_msgtxt, DEVICE6_CMD6_msglen,
	DEVICE6_CMD6_msgtxt:
	.ascii "When blue button is pressed, LED will be turned on after delay, and then off after another delay.\n\r\0"
	.equ DEVICE6_CMD6_msglen, ( . - DEVICE6_CMD6_msgtxt)

	@no process
	.thumb_func
device6_NOP:
	pop {r7, pc}

	.thumb_func
device6_cmd0:
	@initialize TIM2 and deinitialize interrupt
	bl TIM2_init
	bl NVIC_deinit
	@initialize PA5 LED for output
	bl userLED_init
	@turn led off in case its on
	bl userLED_OFF

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

	@install skiptask
	MOV_imm32 r0, device6_skiptask
    mov r1, #NULL
    bl MoT_taskUpdate

    add r0, rDEVP, #DEVICE6_CMD0_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

	pop {r7, pc}

	.thumb_func
device6_cmd1:
	@load input and set interrupt interval
	ldr r1, [r0]
	subs r1, r1, #1 @subtract 1 since 0 inclusive count
	ldr r3, =TIM2_BASE
	str r1, [r3, #ARR]

	@turn led off
	bl userLED_OFF

	@clear INTcount
	mov r1, #0
	str r1, [rDEVP, #DEVICE6_TIM2_INTCOUNT]

	add r0, rDEVP, #DEVICE6_CMD1_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

	pop {r7, pc}

	.thumb_func
device6_cmd2:

	ldr r3, =TIM2_BASE

	mov r2, #1			@; set UIE: update interrupt enable
	str r2,[r3, #DIER]

	@;enable TIM2 as up-counting edge-aligned overflow-triggered repeating counter
	movw r2,#1				@; ..
	strh r2,[r3,#CR1]			@; done last, as counter starts immediately

	bl NVIC_init

	add r0, rDEVP, #DEVICE6_CMD2_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

	pop {r7, pc}

	.thumb_func
device6_cmd3:
    @clear cycle count
    mov r1, #0
    str r1, [rDEVP, #DEVICE6_TIM2_CYCLECOUNT]

    @install cyclecount task
    MOV_imm32 r0, device6_TIM2_CYCLEcount_task
    mov r1, #NULL
    bl MoT_taskUpdate

    add r0, rDEVP, #DEVICE6_CMD3_msg @print task message
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost

    pop {r7, pc}

	.thumb_func
device6_cmd4:
    push {r8-r10}

    @ load both counts
    ldr r8, [rDEVP, #DEVICE6_TIM2_INTCOUNT]
    ldr r9, [rDEVP, #DEVICE6_TIM2_CYCLECOUNT]

    @move to end of buffer to print newline, carriage return, and null terminator \n\r\0
    MOV_imm32 r10, device6_printbuf_txt
    add r10, r10, #21

    @write \n\r\0 to buffer
    mov r2, #'\n'
    strb r2, [r10, #0]
    mov r2, #'\r'
    strb r2, [r10, #1]
    mov r2, #0
    strb r2, [r10, #2]

    @convert CYCLEcount right to left
    mov r0, r9
    mov r3, #10
cycle_loop:
    udiv r2, r0, r3
    mls r1, r2, r3, r0
    add r1, r1, #0x30
    strb r1, [r10], #-1
    mov r0, r2
    cmp r0, #0
    bne cycle_loop

    @add space to separate counts
    mov r2, #' '
    strb r2, [r10], #-1

    @ onvert INTcount right to left
    mov r0, r8
int_loop:
    udiv r2, r0, r3
    mls r1, r2, r3, r0
    add r1, r1, #0x30
    strb r1, [r10], #-1
    mov r0, r2
    cmp r0, #0
    bne int_loop

    @we went one past start of buffer so move back to start of buffer
    add r10, r10, #1

    @update text pointer and length in link struct
    MOV_imm32 r2, device6_printbuf_link
    str r10, [r2, #4]       @ update text pointer

    @calculate length = end of buffer - start of string
    MOV_imm32 r1, device6_printbuf_txt
    add r1, r1, #24 @end of buffer
    sub r1, r1, r10 @length
    str r1, [r2, #8] @update length field

    @print counts
    MOV_imm32 r0, device6_printbuf_link
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost

    add r0, rDEVP, #DEVICE6_CMD4_msg @print task message
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost

    pop {r8-r10}
    pop {r7, pc}

	.thumb_func
device6_cmd5:
    @load and program delay
    ldr r1, [r0]
    sub r1, r1, #1
    ldr r3, =TIM2_BASE

    @stop TIM2
    mov r2, #0
    str r2, [r3, #CR1]

    @set delay
    str r1, [r3, #ARR]

    @reset counter, clear UIF
    mov r2, #1
    str r2, [r3, #EGR]
    ldr r2, [r3, #SR]
    bic r2, r2, #1
    str r2, [r3, #SR]

    @enable interrupt
    mov r2, #1
    str r2, [r3, #DIER]
    bl NVIC_init

    @set irq state
    mov r2, #1
    str r2, [rDEVP, #DEVICE6_IRQ_STATE]

    @install waitbuttontask
    MOV_imm32 r0, device6_waitbuttontask
    mov r1, #NULL
    bl MoT_taskUpdate

    add r0, rDEVP, #DEVICE6_CMD5_msg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost

    pop {r7, pc}

	.thumb_func
device6_cmd6:

	@load and program delay
    ldr r1, [r0], #4
    sub r1, r1, #1
    ldr r3, =TIM2_BASE

    @load and store off delay from input
    ldr r2, [r0]
    str r2, [rDEVP, #DEVICE6_OFFDELAY]

    @stop TIM2
    mov r2, #0
    str r2, [r3, #CR1]

    @write ARR
    str r1, [r3, #ARR]

    @reset counter, clear UIF
    mov r2, #1
    str r2, [r3, #EGR]
    ldr r2, [r3, #SR]
    bic r2, r2, #1
    str r2, [r3, #SR]

    @enable interrupt
    mov r2, #1
    str r2, [r3, #DIER]
    bl NVIC_init

    @set irq state
    mov r2, #2
    str r2, [rDEVP, #DEVICE6_IRQ_STATE]

    @install waitbuttontask
    MOV_imm32 r0, device6_waitbuttontask
    mov r1, #NULL
    bl MoT_taskUpdate

    add r0, rDEVP, #DEVICE6_CMD6_msg
    MOV_imm32 r1, consoleMsgs
    bl MoT_msgPost

	pop {r7, pc}

	.global device6_skiptask
	.thumb_func
device6_skiptask:
	ldr rDEVP,[rDEVP,#NEXTTASK]
	ldr pc,[rDEVP,#XEQTASK]

	.global device6_TIM2_CYCLEcount_task
	.thumb_func
device6_TIM2_CYCLEcount_task:
	ldr r1, [rDEVP, #DEVICE6_TIM2_CYCLECOUNT]
    add r1, r1, #1
    str r1, [rDEVP, #DEVICE6_TIM2_CYCLECOUNT]
	b device6_skiptask

	.global device6_waitbuttontask
	.thumb_func
device6_waitbuttontask:
    ldr r3, =GPIOC_BASE
    ldr r0, [r3, #GPIO_IDR]
    tst r0, #(1<<13)
    beq device6_skiptask @not pressed yet
    @button pressed so start TIM2
    ldr r3, =TIM2_BASE
    mov r2, #1
    str r2, [r3, #CR1]
    @reinstall skiptask
    MOV_imm32 r0, device6_skiptask
    mov r1, #NULL
    bl MoT_taskUpdate
    b device6_skiptask

