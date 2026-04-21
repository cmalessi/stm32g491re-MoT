@;SysTick_definitions.S wmh 2024-08-28 : Systick initialization and handler for STM32G491re
@; - gets reload register value (ST)RVR) from global variable
@; - SysTick_Handler updates SysTick_absmsecs (uint64_t), SysTick_msecs (uint32_t), SysTick_secs (uint32_t).

	.syntax unified				@; ARM Unified Assembler Language (UAL). 
	.thumb						@; use thumb instructions only

	.equ SYSTICK_PRI,0x80	@;medium priority interrupt for SysTick (0xF0=lowest, 0x00=highest)
	
@; --- handy macros
 
	.macro MOV_imm32 reg, constant
		movw \reg, #:lower16:\constant
		movt \reg, #:upper16:\constant
	.endm

	.macro SET_bit addr, bit_num
		push {r0-r1}			@;preserve registers for unwary macro users
		MOV_imm32 r0, \addr
		ldr r1, [r0]
		orr r1, r1, #(0x01<<\bit_num)
		str r1, [r0]
		pop {r0-r1}				@;restore registers
	.endm

@; --- registers used for SysTick, SVC, and PendSV initializations, drawn from DDI0439 and DDI0403D
	.equ SCR,0xE000ED10			@;System Control Register
	.equ CCR,0xE000ED14			@;Configuration and Control Register.
	.equ SHPR1,0xE000ED18		@;System Handler Priority Register 1
	.equ SHPR2,0xE000ED1C		@;System Handler Priority Register 2
	.equ SHPR3,0xE000ED20		@;System Handler Priority Register 3
	.equ SHCSR,0xE000ED24		@;System Handler Control and State Register
	
	.equ SYST_CSR,0xE000E010 	@;SysTick Control and Status Register ref: DDI0403D B3.3.2
	.equ SYST_RVR,0xE000E014	@;SysTick Reload Value Register
	.equ SYST_CVR,0xE000E018	@;SysTick Current Value Register
	.equ SYST_CALIB,0xE000E01C	@;SysTick Calibration Value Register
	
	.equ ICSR,0xE000ED04		@;Interrupt Control and State Register
	.equ PENDSVSET,28			@; bit location in ICSR to set PendSV interrupt pending
	.equ PENDSVCLR,27			@; ""					 clear PendSV ""
	
	.equ SysTick_PR,SHPR3+3		@;SysTick Interrupt Priority byte address
	.equ PendSV_PR,SHPR3+2		@;PendSV 		""
	.equ SvcHandler_PR,SHPR2+3	@;SvcHandler	""

@; --- SysTick default system variables
@; If these are (re)defined elsewhere for visibilty as globals, those definitions will superced these
	.section .bss
	.align 2
	.global SysTick_absmsecs, SysTick_msecs,SysTick_secs
	.weak	SysTick_absmsecs
	SysTick_absmsecs:	.skip 8
	.weak SysTick_msecs
	SysTick_msecs:		.skip 4
	.weak SysTick_secs
	SysTick_secs:		.skip 4
	

	.text					

@; --- SysTick initialization function
	.syntax unified				@; ARM Unified Assembler Language (UAL). 
	.thumb						@; Use thumb instructions only

	.global SysTick_init
	.thumb_func
SysTick_init: @;initialize SysTick timer
	push {r7,lr}				@;save callers context 	

	MOV_imm32 r1,SYST_CSR		@;get SysTick control register base
	@;stop SysTick counter and interrupt before making changes
	mov r2,0x0 					
	str r2,[r1]
	@;set SysTick period	
	MOV_imm32 r2,SysTick_ReloadValue @; as established in SystemClock_init2.S
	ldr r2,[r2]					@; ..
	str r2,[r1,#4]				@;write SysTick Reload Value Register, SYST_RVR
	@;clear current SysTick count
	str r2,[r1,#8]				@;write SysTick Current Value Register, SYST_CVR (storing any value does it)
	@;establish SysTick priority
	MOV_imm32 r3,SysTick_PR		@;byte-address of SysTick priority register
	mov r0,#SYSTICK_PRI			@;defined above
	and r0,0xF0					@;mask value -- only upper 4 bits of are used
	strb r0,[r3]				@; ..
	@;enable SysTick interrupt, enable the counter using core clock
	mov r2,0x07
	str r2,[r1,#0]

	pop {r7,pc}					@;return to caller

@; --- SysTick_Handler function
	.global SysTick_Handler		@; replaces the 'weak' equivalence to Default_Handler in 'startup'  
	.thumb_func
SysTick_Handler: @; here for each SysTick timer timeout
	@; anything goes here -- r0-r3 dont need to be preserved but everything must be not used or else preserved
	@; you can call other functions but r14 (lr)  must be preserved, e.g. pushed before any 'bl' 
	@; when you are finished, stack must be where it started
	
	push {r7,lr}				@;save return key and interruptees context

	@;update absolute msecs 
	MOV_imm32 r2,SysTick_absmsecs @; get address of global variable SysTick_absmsecs in .SysTick_shmem (defined above)
	ldr r0,[r2]					@; current value of SysTick_absmsecs low word 
	adds r0,r0,#1				@; is updated
	str r0,[r2],#4				@; 	.. and r2 points to high word of SysTick_absmsecs
	ldr r0,[r2]					@; current value of SysTick_absmsecs high word 
	adc r0,r0,#0				@; is updated
	str r0,[r2] 				@; ..
	

	@;update msecs 
	MOV_imm32 r2,SysTick_msecs	@; get address of global variable SysTick_msecs in .SysTick_shmem (defined above)
	ldr r0,[r2]					@; current value of SysTick_msecs in r0
	add r0,r0,#1				@; is updated
	str r0,[r2]					@; ..
	cmp r0,#1000				@; has one second elapsed?
	blo SysTick_device5     	@;	no -- skip past second update
								@;  yes -- do updates for new second
	mov r0,#0					@;		reset msec count
	str r0,[r2]					@; 		..

	@;update secs counter
	MOV_imm32 r2,SysTick_secs	@; get address of global variable SysTick_secs in .SysTick_shmem (defined above)
	ldr r0,[r2]					@; current value of SysTick_secs in r0 (max: 2**32= 136 years) 
	add r0,r0,#1				@; is updated
	str r0,[r2]					@; ..
	
	@;here with SysTick counters updated
SysTick_device5:
	@device5 interrupt mode check
	MOV_imm32 r0, device5_mode
	ldr r0, [r0]
	cmp r0, #1
	bne SysTick_Handler_exit     @not interrupt mode, skip

	@check if flag already set
	MOV_imm32 r0, device5_flag
	ldr r1, [r0]
	cmp r1, #0
	bne SysTick_Handler_exit     @flag already set, task hasn't used it yet

	@compare current absmsecs to target time, high words first
	MOV_imm32 r0, device5_targettime_hi
	ldr r1, [r0]                 @target high word
	MOV_imm32 r2, SysTick_absmsecs
	ldr r3, [r2, #4]             @current high word
	cmp r3, r1
	blo SysTick_Handler_exit     @if lower still need to wait

	@high words match or exceeded, check low words
	MOV_imm32 r0, device5_targettime_lo
	ldr r1, [r0]                 @ target low word
	ldr r3, [r2]                 @ current low word
	cmp r3, r1
	blo SysTick_Handler_exit     @still need to wait

	@time reached so set flag
	MOV_imm32 r0, device5_flag
	mov r1, #1
	str r1, [r0]

SysTick_Handler_exit:
	@;SystTick doesnt require resetting an interrupt flag like normal interrupts do
	pop {r7,pc}					@;magic Cortex-M interrupt kludge takes you back to the interrupted program
	
