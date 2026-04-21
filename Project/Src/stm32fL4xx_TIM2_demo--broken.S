#include "bit-op_macros.S"
@; --- characterize target syntax, processor
	.syntax unified				@; ARM Unified Assembler Language (UAL). 
	.thumb						@; but here we'll use thumb instructions only
 	
@;.equ 	PERIPH_BASE,		0x40000000 @; Base address of : AHB/ABP Peripherals 
@;.equ	AHB1PERIPH_BASE,	(PERIPH_BASE + 0x00020000)
.equ	RCC_BASE,           0x40021000
.equ 	APB1RSTR1,			0x38		@; RCC APB1 peripheral reset register; TIM2 is bit0
.equ	APB1ENR1,			0x58		@; RCC APB1 peripheral clock enable register; TIM2 is bit0
.equ 	AHB2ENR,			0x4C		@; RCC AHB2 peripheral clock enable register; GPIOA is bit0

.equ 	TIM2_BASE,			(0x40000000)	@; origin of TIM2 control register array
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


@; --- definitions for alternate function assignment of TIM2 to PA5
.equ 	GPIOA_BASE, 0x48000000 @; origin of GPIOA control register array
@; offsets to registers in GPIO control array
.equ	MODER,	0x00	@;  GPIO port mode register,	Address offset:	0x00	      
.equ	OTYPER,	0x04	@;  GPIO port output type register,	Address offset:	0x04	      
.equ	OSPEEDR,0x08	@;  GPIO port output speed register,	Address offset:	0x08	      
.equ	PUPDR,	0x0C	@;  GPIO port pull-up/pull-down register,	Address offset:	0x0C	      
.equ	IDR,	0x10	@;  GPIO port input data register,	Address offset:	0x10	      
.equ	ODR,	0x14	@;  GPIO port output data register,	Address offset:	0x14	      
.equ	BSRR,	0x18	@;  GPIO port bit set/reset register,	Address offset:	0x18	      
.equ	LCKR,	0x1C	@;  GPIO port configuration lock register,	Address offset:	0x1C	      
.equ	AFRL,	0x20	@;  GPIO alternate function register low,	Address offset:	0x20
.equ	AFRH,	0x24	@;  GPIO alternate function register high,	Address offset:	0x24 

@; --- NVIC register array base addresses
.equ	NVIC_ISER,	0xE000E100	@; Interrupt Set-Enable Registers, NVIC_ISER0-NVIC_ISER15
.equ	NVIC_ICER,	0xE000E180	@; Interrupt Clear-Enable Registers, NVIC_ICER0-NVIC_ICER15
.equ	NVIC_ISPR,	0xE000E200	@; Interrupt Set-Pending Registers, NVIC_ISPR0-NVIC_ISPR15
.equ	NVIC_ICPR,	0xE000E280	@; Interrupt CLR-Pending Registers, NVIC_ICPR0-NVIC_ICPR15
.equ 	NVIC_IABR,	0xE000E300	@; Interrupt Active Bit Registers, NVIC_IABR0-NVIC_IABR15
.equ 	NVIC_IPR,	0xE000E400	@; Interrupt Priority Registers, NVIC_IPR0-NVIC_IPR123


@; --- TIM2 demo code
	.text						
	.align 2

	.global NVIC_init	@; general interrupt enable and priority setting
						@; 	called first, configures NVIC for all active interrupts
	.thumb_func
NVIC_init:
	push {r7,lr}
	
	@;NVIC configuration values for TIM2 interrupt
	.equ position,28 		@;TIM2 location in table
	.equ byteoffset,3		@;# of bytes from origin to the bit at 'position', for any of the NVIC bit-registers
	.equ bitposition,4		@;position of enable/clear/active bit in byte at byteoffset, e.g. position=8*byteoffset+bitposition

	@;enable TIM2 in NVIC (will also need to be enable in TIM configuration)
	ldr r3,=NVIC_ISER	
	ldrb r2,[r3,#byteoffset]
	orr r2,#(1<<bitposition)
	strb r2,[r3,#byteoffset]

	@;set TIM2 interrupt priority mid-level (8)
	ldr r3,=NVIC_IPR	
	mov r2,#0x80			@;priority is in upper nybble
	strb r2,[r3,#position]	

	pop {r7,pc}
	
	.global NVIC_deinit
	.thumb_func
NVIC_deinit:
	push {r7, lr}
	@;reset TIM2 in NVIC (will also need to be enable in TIM configuration)
	ldr r3,=NVIC_ICER
	ldrb r2,[r3,#byteoffset]
	bic r2,#(1<<bitposition)
	strb r2,[r3,#byteoffset]

	pop {r7,pc}

    @; functions to freeze/unfreeze TIM2
@; --- definitions for DBGMCU control of TIM2
.equ    DBGMCU_BASE,    0xE0042000  @; Debug MCU registers base address 
.equ	APB1FZR1,	0x08	@;	   __IO uint32_t APB1FZR1;  /*!< Debug MCU APB1 freeze register,   Address offset: 0x08 */
.equ    DBGMCU_APB1FZR1_DBG_TIM2_STOP_Pos,  0x0   @;position of bit in APB1FZR1; setting this bit will cause TIM2 to 'freeze' when CPU stops at breakpoints

	.global DBGMCU_FREEZE_TIM2
	.thumb_func
DBGMCU_FREEZE_TIM2:	@;freeze TIM2 when stopped in debug mode
	ldr r3,=DBGMCU_BASE 		@; ..
	ldr r2,[r3,#APB1FZR1]		@; ..
    orr r2,#(1<<DBGMCU_APB1FZR1_DBG_TIM2_STOP_Pos) @; ..
	str r2,[r3,#APB1FZR1]		@; ..    
    bx lr

	.global DBGMCU_UNFREEZE_TIM2
	.thumb_func
DBGMCU_UNFREEZE_TIM2:			@;unfreeze TIM2 in debug mode
	ldr r3,=DBGMCU_BASE 		@; ..
	ldr r2,[r3,#APB1FZR1]		@; ..
    bic r2,#(1<<DBGMCU_APB1FZR1_DBG_TIM2_STOP_Pos) @; ..
	str r2,[r3,#APB1FZR1]		@; ..    
    bx lr

	.equ RCC_APB1SMENR1_TIM2SMEN_Pos, 0x0

	.global TIM2_init
	.thumb_func
TIM2_init:	@;TIM2 initialized as a simple up-counter
    push {r7,lr}

	@;(re-)enable TIM2 and then reset it
	ldr r3,=RCC_BASE			@;enable TIM2
	ldr r2,[r3,#APB1ENR1]		@; ..
	orr	r2,r2, (0x1 << RCC_APB1SMENR1_TIM2SMEN_Pos)				@; ..  
	str r2,[r3,#APB1ENR1]		@; ..
	ldr r2,[r3,#APB1RSTR1]		@;reset TIM2
	orr r2,r2,0x1				@; ..
	str r2,[r3,#APB1RSTR1]		@; ..  
	bic	r2,r2,0x1				@; ..  manual: APB1RSTR bits are "set _and_ cleared by software"
	str r2,[r3,#APB1RSTR1]		@; ..  

@; here with TIM2 enabled and reset
    ldr r3,=TIM2_BASE       	@;select TIM2 for register operations

	@;set TIM2 prescaler reload value
	mov	r2,#71					@; prescale 72MHz clock
	strh r2,[r3,#PSC]			@; ..

	@;set TIM2 counter reload value
	movw r2,#0xE7					@; counter reloads after 1msec, 0x03E7 = 999, 0-999us (0 inclusive) = 1ms
	movt r2,#0x03					@; ..
	str r2,[r3,#ARR]			@; ..
	
	@;initialize the comparitor register with its value
	mov r2,#1
	str r2,[r3,#EGR]	
	@;!! here with UIF in SR=1 as a side effect of the above instruction
	ldr r2, [r3, #SR]
	bic r2, r2, #1
	str r2, [r3, #SR] @clear UIF

	/*
	@;enable TIM2 interrupt on CH1 
	mov r2, #1			@; set UIE: update interrupt enable
	str r2,[r3, #DIER]

	@;enable TIM2 as up-counting edge-aligned overflow-triggered repeating counter
	movw r2,#1				@; ..
	strh r2,[r3,#CR1]			@; done last, as counter starts immediately
	*/
	@; here with TIM2 running
	pop {r7,pc}

	.global TIM2_IRQHandler
	.thumb_func
TIM2_IRQHandler:
    push {r7,lr}

    @clear UIF
    ldr r3, =TIM2_BASE
    ldr r2, [r3, #SR]
    bic r2, r2, #1
    str r2, [r3, #SR]

    @check state
    MOV_imm32 r3, device6_irq_state
    ldr r2, [r3]

    cmp r2, #0
    beq irq_state0 @command 2
    cmp r2, #1
    beq irq_state1 @command 5
    cmp r2, #2
    beq irq_state2 @command 6 part 1
    cmp r2, #3
    beq irq_state3 @command 6 part 2
    b irq_done

irq_state0:
	@toggle LED
    bl userLED_toggle
    @increment INTcount
    MOV_imm32 r3, device6_TIM2_INTcount
    ldr r2, [r3]
    add r2, r2, #1
    str r2, [r3]
    b irq_done

irq_state1:
	@turn on led
    bl userLED_ON
    ldr r3, =TIM2_BASE
    mov r2, #0
    @stop TIM2 and go back to state0
    str r2, [r3, #CR1]
    MOV_imm32 r3, device6_irq_state
    mov r2, #0
    str r2, [r3]
    b irq_done

irq_state2:
    bl userLED_ON
    @stop TIM2 before resetting arr
    ldr r3, =TIM2_BASE
    mov r2, #0
    str r2, [r3, #CR1]
    @load second delay and reset ARR
    MOV_imm32 r3, device6_offdelay
    ldr r2, [r3]
    sub r2, r2, #1
    ldr r3, =TIM2_BASE
    str r2, [r3, #ARR]
    @reset counter and restart
    mov r2, #1
    str r2, [r3, #EGR]
    ldr r2, [r3, #SR]
    bic r2, r2, #1
    str r2, [r3, #SR]
    @clear pending TIM2 interrupt in NVIC
    MOV_imm32 r2, 0xE000E280 @ NVIC_ICPR
    mov r3, #(1<<28)
    str r3, [r2]
    @restart TIM2
    ldr r3, =TIM2_BASE
    mov r2, #1
    str r2, [r3, #CR1]
    @go to state 3 for last part
    MOV_imm32 r3, device6_irq_state
    mov r2, #3
    str r2, [r3]
    b irq_done

irq_state3:
	@same as state1 but for off for last part of command6
    bl userLED_OFF
    ldr r3, =TIM2_BASE
    mov r2, #0
    str r2, [r3, #CR1]
    MOV_imm32 r3, device6_irq_state
    mov r2, #0
    str r2, [r3]
    b irq_done

irq_done:
    pop {r7,pc}


