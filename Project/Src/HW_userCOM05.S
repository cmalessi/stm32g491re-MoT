@;  LPUART1_functions0x.S wmh 2024-09-21 : initialize STM32G491 at 72MHZ for LPUART1 at 115200N81 w/ test with blocking getchar/putchar
@; Configuration roadmap from stm32g4xx_hal_usart.c
        @;+) Enable the USARTx interface clock.
          @;+) USART pins configuration:
            @;++) Enable the clock for the USART GPIOs.
            @;++) Configure these USART pins as alternate function pull-up.
          @;+) NVIC configuration if you need to use interrupt process (HAL_USART_Transmit_IT(),
            @;    HAL_USART_Receive_IT() and HAL_USART_TransmitReceive_IT() APIs):
            @;++) Configure the USARTx interrupt priority.
            @;++) Enable the NVIC USART IRQ handle.
            @;+) USART interrupts handling:
            @;  -@@-   The specific USART interrupts (Transmission complete interrupt,
            @;      RXNE interrupt and Error Interrupts) will be managed using the macros
            @;      __HAL_USART_ENABLE_IT() and __HAL_USART_DISABLE_IT() inside the transmit and receive process.
          @;+) DMA Configuration if you need to use DMA process (HAL_USART_Transmit_DMA()
            @; HAL_USART_Receive_DMA() and HAL_USART_TransmitReceive_DMA() APIs):
            @;++) Declare a DMA handle structure for the Tx/Rx channel.
            @;++) Enable the DMAx interface clock.
            @;++) Configure the declared DMA handle structure with the required Tx/Rx parameters.
            @;++) Configure the DMA Tx/Rx channel.
            @;++) Associate the initialized DMA handle to the USART DMA Tx/Rx handle.
            @;++) Configure the priority and enable the NVIC for the transfer
            @;      complete interrupt on the DMA Tx/Rx channel.

      @;#) Program the Baud Rate, Word Length, Stop Bit, Parity, and Mode
          
	.syntax unified					@; ARM Unified Assembler Language (UAL) is allowed
	.thumb							@; we're using thumb instructions only
	.text

	#include "stm32G491xx_RCC.h"
	#include "stm32G491xx_USART1.h"
	#include "stm32G491xx_GPIO.h"
	#include "bit-op_macros.S"
/*  macros in bit-op_macros.S are below.  'CONFIRM' macros return Z=1 if success of operation or state is confirmed  
	mUPDATE_DEVICEREG_BIT_TO_1 structbase, offset, fieldpos, fieldmask
	mCONFIRM_DEVICEREG_BIT_EQ_1 structbase, offset, fieldpos, fieldmask
	mUPDATE_DEVICEREG_BIT_TO_0 structbase, offset, fieldpos, fieldmask
	mCONFIRM_DEVICEREG_BIT_EQ_0 structbase, offset, fieldpos, fieldmask
	mUPDATE_DEVICEREG_FIELD structbase, offset, fieldpos, fieldmask, fieldvalue
	mCONFIRM_DEVICEREG_FIELD structbase, offset, fieldpos, fieldmask, fieldvalue 
*/

@;------------------
.global LPUART1_init	@;void LPUART1_init(); //initialize LPUART1 for ST-Link VCOM
.thumb_func
LPUART1_init:
	push {r7,lr}
	
@; --- configuration for LPUART1
@;	enable the USARTx interface clock.
	mUPDATE_DEVICEREG_BIT_TO_1 		RCC_BASE,	RCC_APB1ENR2,	RCC_APB1ENR2_LPUART1EN_Pos,	RCC_APB1ENR2_LPUART1EN  
1:	mCONFIRM_DEVICEREG_BIT_EQ_1 	RCC_BASE,	RCC_APB1ENR2,	RCC_APB1ENR2_LPUART1EN_Pos,	RCC_APB1ENR2_LPUART1EN
	bne 1b

@;	reset LPUART1`
	mUPDATE_DEVICEREG_BIT_TO_1 		RCC_BASE,	RCC_APB1RSTR2,	RCC_APB1RSTR2_LPUART1RST_Pos, 	RCC_APB1RSTR2_LPUART1RST
1:	mCONFIRM_DEVICEREG_BIT_EQ_1		RCC_BASE,	RCC_APB1RSTR2,	RCC_APB1RSTR2_LPUART1RST_Pos, 	RCC_APB1RSTR2_LPUART1RST
	bne 1b

@;	unreset LPUART1`
	mUPDATE_DEVICEREG_BIT_TO_0 		RCC_BASE,	RCC_APB1RSTR2,	RCC_APB1RSTR2_LPUART1RST_Pos, 	RCC_APB1RSTR2_LPUART1RST
1:	mCONFIRM_DEVICEREG_BIT_EQ_0		RCC_BASE,	RCC_APB1RSTR2,	RCC_APB1RSTR2_LPUART1RST_Pos, 	RCC_APB1RSTR2_LPUART1RST
	bne 1b

//@;	HSI16 always enable for peripheral kernels (RM0440 pg 288) !!wmh question -- this seems like a global (all peripherals, unlike LPUART1SMEN)   
	mUPDATE_DEVICEREG_BIT_TO_1 		RCC_BASE,	RCC_CR,			RCC_CR_HSIKERON_Pos, 			RCC_CR_HSIKERON
1:	mCONFIRM_DEVICEREG_BIT_EQ_1		RCC_BASE,	RCC_CR,			RCC_CR_HSIKERON_Pos, 			RCC_CR_HSIKERON
	bne 1b

@;	LPUART1 clocks disabled by the clock gating(1) during Sleep and Stop modes`(RM0440 pg 320 
	mUPDATE_DEVICEREG_BIT_TO_0 		RCC_BASE,	RCC_APB1SMENR2,	RCC_APB1SMENR2_LPUART1SMEN_Pos, RCC_APB1SMENR2_LPUART1SMEN 
1:	mCONFIRM_DEVICEREG_BIT_EQ_0		RCC_BASE,	RCC_APB1SMENR2,	RCC_APB1SMENR2_LPUART1SMEN_Pos, RCC_APB1SMENR2_LPUART1SMEN 
	bne 1b

@;	Peripherals independent clock configuration register (RM0440 pg 322): 0x2: HSI16 clock selected as LPUART1 clock
	mUPDATE_DEVICEREG_FIELD 		RCC_BASE, 	RCC_CCIPR, 		RCC_CCIPR_LPUART1SEL_Pos, 		RCC_CCIPR_LPUART1SEL_Msk,	RCC_CCIPR_LPUART1SEL_1

@;	enable GPIOA for LPUART TX/RX
	mUPDATE_DEVICEREG_BIT_TO_1 		RCC_BASE,	RCC_AHB2ENR,	RCC_AHB2ENR_GPIOAEN_Pos,		RCC_AHB2ENR_GPIOAEN

@;	configure PA2, PA3 for alternate function
	mUPDATE_DEVICEREG_FIELD 		GPIOA_BASE, GPIO_MODER, 	GPIO_MODER_MODE2_Pos,			GPIO_MODER_MODE2_Msk, 		((2)<<GPIO_MODER_MODE2_Pos)
	mUPDATE_DEVICEREG_FIELD 		GPIOA_BASE, GPIO_MODER, 	GPIO_MODER_MODE3_Pos,			GPIO_MODER_MODE3_Msk, 		((2)<<GPIO_MODER_MODE3_Pos)

@;	configure PA2 for LPUART1_TX (alternate function 12)
	mUPDATE_DEVICEREG_FIELD 		GPIOA_BASE, GPIO_AFRL, 		GPIO_AFRL_AFSEL2_Pos,			GPIO_AFRL_AFSEL2_Msk, 		((12)<<GPIO_AFRL_AFSEL2_Pos)

@;	configure PA3 for LPUART1_RX (alternate function 12)
	mUPDATE_DEVICEREG_FIELD 		GPIOA_BASE, GPIO_AFRL, 		GPIO_AFRL_AFSEL3_Pos,			GPIO_AFRL_AFSEL3_Msk, 		((12)<<GPIO_AFRL_AFSEL3_Pos)

@; configure LPUART(see RM0440 pg 1617 step-by-step) 

@;	unenable LPUART1`
	mUPDATE_DEVICEREG_BIT_TO_0 		LPUART1_BASE,	USART_CR1,	USART_CR1_UE_Pos, 	USART_CR1_UE
1:	mCONFIRM_DEVICEREG_BIT_EQ_0		LPUART1_BASE,	USART_CR1,	USART_CR1_UE_Pos, 	USART_CR1_UE
	bne 1b

@;	enable RX
	mUPDATE_DEVICEREG_BIT_TO_1 		LPUART1_BASE,	USART_CR1,	USART_CR1_RE_Pos, 	USART_CR1_RE

@;	enable TX
	mUPDATE_DEVICEREG_BIT_TO_1 		LPUART1_BASE,	USART_CR1,	USART_CR1_TE_Pos, 	USART_CR1_TE


@;	define word length =N81 using M1:M0 = 0:0   
	mUPDATE_DEVICEREG_FIELD			LPUART1_BASE,	USART_CR1,	USART_CR1_M1_Pos,	USART_CR1_M1_Msk,		((0)<<USART_CR1_M1_Pos)
	mUPDATE_DEVICEREG_FIELD			LPUART1_BASE,	USART_CR1,	USART_CR1_M0_Pos,	USART_CR1_M0_Msk,		((0)<<USART_CR1_M0_Pos)
	@; done another way
	mUPDATE_DEVICEREG_BIT_TO_0 		LPUART1_BASE,	USART_CR1,	USART_CR1_M1_Pos,	USART_CR1_M1_Msk
	mUPDATE_DEVICEREG_BIT_TO_0 		LPUART1_BASE,	USART_CR1,	USART_CR1_M1_Pos,	USART_CR1_M1_Msk

//@;	LPUART1 input clock not divided
	mUPDATE_DEVICEREG_FIELD			LPUART1_BASE,	USART_PRESC,	USART_PRESC_PRESCALER_Pos,	USART_PRESC_PRESCALER_Msk, ((0)<< USART_PRESC_PRESCALER_Pos)

@;	set LPUART1 baud rate (USART_BRR.BRR = USARTDIV = 16000000/115200 = 138 =0x8A //see example, RM0440 pg 1627) (!!wmh : USART_BRR_LPUART_Msk is 16 bits; this macro could fail when value is >256) 
//	mUPDATE_DEVICEREG_FIELD			LPUART1_BASE,	USART_BRR,	USART_BRR_LPUART_Pos,	USART_BRR_LPUART_Msk,	((0x8A)<<USART_BRR_LPUART_Pos)
// 	mUPDATE_DEVICEREG_FIELD			LPUART1_BASE,	USART_BRR,	USART_BRR_LPUART_Pos,USART_BRR_LPUART_Msk,	((0x1234)<<USART_BRR_LPUART_Pos)
 	mUPDATE_DEVICEREG_FIELD			LPUART1_BASE,	USART_BRR,	USART_BRR_LPUART_Pos,USART_BRR_LPUART_Msk,	((0x008AE4)<<USART_BRR_LPUART_Pos)

@;	set number of stop bits =1
	mUPDATE_DEVICEREG_FIELD			LPUART1_BASE,	USART_CR2,	USART_CR2_STOP_Pos,	USART_CR2_STOP_Msk,		((0x0)<<USART_CR2_STOP_Pos)
	
@;	enable LPUART1`
	mUPDATE_DEVICEREG_BIT_TO_1 		LPUART1_BASE,	USART_CR1,	USART_CR1_UE_Pos, 	USART_CR1_UE
1:	mCONFIRM_DEVICEREG_BIT_EQ_1		LPUART1_BASE,	USART_CR1,	USART_CR1_UE_Pos, 	USART_CR1_UE
	bne 1b

	pop {r7,pc}

@;------------------
@; .global LPUART1_interrupt_config			@;LPUART1_interrupt_config(); //set priority and enable
@; .thumb_func
@; LPUART1_interrupt_config:
	@; .set NVIC_ISER_wordoffset,(LPUART1_IRQn>>5)
	@; .set NVIC_ISER_bitpos,(LPUART1_IRQn&0x1F) 
	@; .set NVIC_IPR_byteoffset, (LPUART1_IRQn>>3)
	@; mSETBIT_DEVICEREG 		NVIC_ISER0,	NVIC_ISER_wordoffset,	NVIC_ISER_bitpos
	@; mWRITEBYTE_DEVICEREG 	NVIC_IPR0,	NVIC_IPR_byteoffset, 	0x80
	@; bx lr

.global LPUART1_RX_interrupt_enable		// void LPUART1_RX_interrupt_enable(); //what it says
.thumb_func
LPUART1_RX_interrupt_enable:
	@; disable RX interrupt
	mUPDATE_DEVICEREG_BIT_TO_0 		LPUART1_BASE,	USART_CR1,	USART_CR1_RXNEIE_Pos, 	USART_CR1_RXNEIE_Msk

	@; configure NVIC for LPUART1 interrupt
	.set NVIC_ISER_wordoffset,(4*(LPUART1_IRQn>>5))
	.set NVIC_ISER_bitpos,(LPUART1_IRQn&0x1F) 
	.set NVIC_IPR_byteoffset, (LPUART1_IRQn)
	mBITSET_DEVICEREG 		NVIC_ISER,	NVIC_ISER_wordoffset,	NVIC_ISER_bitpos
	mBYTEWRITE_DEVICEREG 	NVIC_IPR,	NVIC_IPR_byteoffset, 	0x80

	@; clear RX of data (if any) to reset the RXINE
	MOV_imm32 r3,LPUART1_BASE
	ldr r0,[r3,#USART_RDR]

	@; enable RX interrupt
	mUPDATE_DEVICEREG_BIT_TO_1 		LPUART1_BASE,	USART_CR1,	USART_CR1_RXNEIE_Pos, 	USART_CR1_RXNEIE_Msk

	@; done
	bx lr

@; #define adminUART_BASE LPUART1_BASE 

@; .global adminUART_nbgetchar @;conditional getchar() 
@; .thumb_func
@; adminUART_nbgetchar: @; char HW_userCOM_nbgetchar(void);	//success: return data>=0; failure: return -1
	@; push {r7,lr}

	@; mov r0,#-1					@;initialize success/fail to 'fail'	
	@; MOV_imm32 r3,adminUART_BASE	@;is new data available?
	@; ldr r2,[r3,#USART_ISR]
	@; tst r2,#(1<<USART_ISR_RXNE_Pos)
	@; beq	1f						@;	no, receiver is empty -- return -1 (no data is available)
	@; ldr r0,[r3,#USART_RDR]		@;	yes, receiver is not empty -- get new data (automatically clears RXNE)
	@; ands r0,#0xFF				@;	clean it up to 8 bits
	@; str r0,[r3,#USART_TDR]		@;  echo it back for debug
@; 1:	pop {r7,pc}					@; 	and return ( data>=0 =='success' )

@; .global LPUART1_IRQHandler	//for echo echo test
	@; .thumb_func
@; LPUART1_IRQHandler:	
	@; MOV_imm32 r3,LPUART1_BASE	@; get new data
	@; ldr r0,[r3,#USART_RDR]		@;	.. (automatically clears RXNE)
	@; ands r0,#0xFF				@;	clean it up to 8 bits
	@; str r0,[r3,#USART_TDR]		@;  echo it back for debug
	@; bx lr						@; 	and return

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	.global HW_userCOM_init // void HW_userCOM_init(); //initializes LPUART1 for asynchronous 115200N81 communication with RX interrupt enabled										
	.thumb_func
HW_userCOM_init:
	push {r7,lr}
	bl userCOM_RXbuffer_init @;initializes LPUART1 ring buffer control with main()'s values for userCOM_RXDATACOUNT,userCOM_RXDATASTORAGE
	bl LPUART1_init
	bl LPUART1_RX_interrupt_enable
	pop {r7,pc}

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	.global HW_userCOM_nbgetchar @;conditional UART getchar()
	.thumb_func
HW_userCOM_nbgetchar: @; char HW_userCOM_nbgetchar(void);	//success: return data>=0; failure: return -1
 	push {r7,lr}
	MOV_imm32 r3,LPUART1_BASE	

	@;initialize success/fail to 'fail'
	mov r0,#-1		
	@;check if new data is available
	ldr r2,[r3,#USART_ISR]			@;is receiver not empty (RXNE ==1)?
	tst r2,#(1<<5)				@; ..
	beq	1f						@;	no, receiver is empty -- return -1 (no data is available)
	ldrb r0,[r3,#USART_RDR]			@;	yes, receiver is not empty -- get new data (automatically clears RXNE)
@;	ands r0,#0xFF				@;	clean it up to 8 bits
@;	strb r0,[r3,#USART_DR]			@;  echo it back for debug
1:	pop {r7,pc}					@; 	and return ( data>=0 =='success' )

	.global HW_userCOM_okgetchar    @; non-blocking; ok to get char return non-zero; not ok: return 0
	.thumb_func
HW_userCOM_okgetchar: @; char HW_userCOM_okgetchar(void);	//success: return non-zero;  failure: return 0
 	push {r7,lr}
	MOV_imm32 r3,LPUART1_BASE	
	ldr r0,[r3,#USART_ISR]			@;is receiver not empty (RXNE ==1)?
	and r0,#(1<<5)				@; ..
	pop {r7,pc}					@; return RXNE status


	.global HW_userCOM_nbputchar		@;conditional UART putchar()
	.thumb_func
HW_userCOM_nbputchar: @;  int HW_userCOM_nbputchar(char data);	//success: return +1; failure: return -1
 	push {r7,lr}
	MOV_imm32 r3,LPUART1_BASE	

	@;check if sending is ok
	ldr r2,[r3,#USART_ISR]			@;is transmitter empty (TXE ==1)?
	tst r2,#(1<<7)				@; .. 
	beq 1f						@;	no, transmitter not empty -- return -1 (sending is blocked)
	strb r0,[r3,#USART_TDR]			@;	yes -- send data (automatically clears TXE)
	mov r0,#1					@;		mark 'success'
	pop {r7,pc}					@; 		and return +1 (data was sent)
1:	mov r0,#-1					@;mark 'failure'
	pop {r7,pc}					@; 		and return -1 (sending is blocked)

	.global HW_userCOM_okputchar		@;conditional UART putchar()
	.thumb_func
HW_userCOM_okputchar: @;  int HW_userCOM_okputchar(char data);	ok to putchar return non-zero; not ok: return 0
 	push {r7,lr}
	MOV_imm32 r3,LPUART1_BASE	
	@;check if sending is ok
	ldr r0,[r3,#USART_ISR]		@;is transmitter empty (TXE ==1)?
	ands r0,#(1<<7)				@; yes -- result is 128
	sub r0,#1					@; no -- result is -1 after the subtract
	pop {r7,pc}					@;  return TXE status: ok: 127 not ok: -1


	.global HW_userCOM_bgetchar		@; blocking UART getchar()
	.thumb_func
HW_userCOM_bgetchar: @;  int HW_userCOM_bgetchar(void);	//blocks until new data, then return data in r0
 	push {r7,lr}
	MOV_imm32 r3,LPUART1_BASE	

	@;check if new data is available
1:	ldr r2,[r3,#USART_ISR]			@;is receiver not empty (RXNE ==1)?
	tst r2,#(1<<5)				@; ..
	beq	1b						@;	no, receiver is empty -- keep testing
	ldrb r0,[r3,#USART_RDR]			@;	yes, receiver is not empty -- get new data (automatically clears RXNE)
@;	ands r0,#0xFF				@;	clean it up to 8 bits
	pop {r7,pc}					@; 	and return ( data>=0 =='success' )


	.global HW_userCOM_bputchar		@;blocking UART putchar()
	.thumb_func
HW_userCOM_bputchar: @;  void HW_userCOM_bputchar(char data);	//block until character can be sent
 	push {r7,lr}
	MOV_imm32 r3,LPUART1_BASE	

	@;check if sending is ok
1:	ldr r2,[r3,#USART_ISR]			@;is transmitter empty (TXE ==1)?
	tst r2,#(1<<7)				@; .. 
	beq 1b						@;	no, transmitter not empty -- keep testing
	strb r0,[r3,#USART_TDR]			@;	yes -- send data (automatically clears TXE)
	pop {r7,pc}					@; 		and return

	.global HW_userCOM_putchar
	.thumb_func
HW_userCOM_putchar:					@; debug: unconditional write to UART DR and return
 	push {r7,lr}
	MOV_imm32 r3,LPUART1_BASE	
	strb r0,[r3,#USART_TDR]			@;	yes -- send data (automatically clears TXE)
	pop {r7,pc}					@; 		and return



	.global LPUART1_IRQHandler			@;using label from interrupt table
	.thumb_func
LPUART1_IRQHandler: 					@; entered for both RX and TX interrupts
	push {r7,lr}	@; even though we're an interrupt, we're not a leaf function, so must do this
	@;
	@; get USART structure pointer
	MOV_imm32 r3,LPUART1_BASE			@; USART2 register structure  !!
	@;read flags to determine source of interrupt		
	ldr r1,[r3,#USART_ISR]					@;USART status in r1
	tst r1,#(0x0F)						@;break on overrun, noise-detected, framing, or parity error
	bne LPUART1_IRQHandler_error_trap	@;	yes -- 
	tst r1,#(1<<5)	@;testing RXNE		@;new RX data?
	beq LPUART1_IRQHandler_noRXdata		@;	no -- go check if we need to transmit
	@; here with new received char to save in USART2 RX ringbuffer						
										@; MOV_imm32 r0,userCOM_RXbufHANDLE@;get USART2 ringbuffer handle
	ldrh r0,[r3,#USART_RDR]					@; ldrh r1,[r3,#RDR]				@;read new RX data value
	bl userCOM_ringbufbuf_wr			@; bl ringbufbuf_wr					@; save the new character  -- ringbufbuf_wr(uint8_t *bufHANDLE,  uint8_t data ); )
	@;here with new data saved in USART2 RX ringbuffer. No warning if buffer is full; oldest data is overwritten.  
	@;
	pop {r7,pc}							@;done -- if USART2 TX interrupt is enabled and TXE=1 we'll get a followon interrupt that goes to LPUART1_IRQHandler_noRXdata below

	@;here if source of interrupt is not error or RXNE so could be TXE  
LPUART1_IRQHandler_noRXdata: @;if TX interrupt and messages not empty, send next character 
	tst r1,#(1<<7)						@;test TXE -- r1 retains image of SR from above
	beq LPUART1_IRQHandler_unknown_trap	@;we've eliminated all of the possible interrupt sources, so we have a mystery
@; <snip> broken code which trasmits from message queue
	b LPUART1_IRQHandler_TXcompleted		@;!!FIX ME: currently we are not not using TX interrupts -- task1 is polling ok_userCOM_putchar and sending with HW_userCOM_putchar
	b LPUART1_IRQHandler_TXcontinues 
	LPUART1_IRQHandler_TXcontinues:		@; current message is not finished or new message is installed on list -- return from interrupt
	pop {r7,pc}														

	@;here if message is completed and no more messages on list. Clear message pointers and turn interrupt off. 
LPUART1_IRQHandler_TXcompleted:	
	mov r0,#0							@;clear task messages list
@!!	MOV_imm32 r2,userCOM_MsgCtl			@; future fixup - if TX ever gets connected to message queue
@!!	str r0,[r2,#(MSGHEAD_PTR)]			@; ..
@!!	str r0,[r2,#(MSGTAIL_PTR)]			@; ..
	ldr r0,[r3,#USART_CR1]					@; disable transmit interrupt 
	bic r0,#( (1<<7) ) @; TXEIE=bit7	@; ..
	str r0,[r3,#USART_CR1]					@; .. 
	pop {r7,pc}							@; return from interrupt

	@;here with SR in r1 when one or more of ORE, NF, FE, PE (overrun, noise, framing or parity) error bits are set
LPUART1_IRQHandler_error_trap:
	mov r0,0x0F							@;clear error bits 
	str r0,[r3,#USART_ICR]					@; ..
	@;record this incident
@!!	bl userCOM_updateRXBUF_NUMERRORS																							
	pop {r7,pc}							@; returns from interrupt
										
LPUART1_IRQHandler_unknown_trap:	@;kludge 'fix' for debugging question of why we got an interrupt without any flags set. !!?? maybe because the NVIC pending flag is set?
	@; record this event						
@!!	bl userCOM_updateRXBUF_NUMUNKNOWNS			
	pop {r7,pc}							@; returns from interrupt

LPUART1_IRQHandler_putchar_failure_trap: @;  not called in this text but easy enough to implement, so done
	@; record this incident
@!!	bl userCOM_updateRXBUF_NUMPUTFAILS														
	pop {r7,pc}							@; returns from interrupt

@; @ --- USART2 interrupt initialization functions

	@; .global userCOM__IRQinit 	@;sets up USART2 interrupt and enables RX interrupt  !!WMH isn't this alredy done by LPUART1_RX_interrupt_enable(0 called in HW_userCOM_init??
    @; .thumb_func
@; userCOM_IRQinit: @; void LPUART1_IRQinit(void); 
	@; @; this initializes and enables the receive but does not enable transmit interrupt.  The transmit interrupt will be turned on and off
	@; @; to modulate packet sending.  

	@; push {r7,lr}
	
	@; @;turn off all interrupts
	@; CPSID i	

	@; @;initialize USART2 ring buffer control and status; see LPUART1_RXbufStruct defined above
	@; bl userCOM_RXbuffer_init
	
	@; @;NVIC: make sure USART2 interrupt enable is off in NVIC before changing things
	@; ldr r3,=(NVIC_ICER+4*LPUART1_NVICwordoffset)	
	@; mov r2,#(1<<(LPUART1_NVICbitoffset-32*LPUART1_NVICwordoffset))
	@; str r2,[r3]

	@; @;USART: begin update of USART2 configuration
	@; ldr r3,=LPUART1_BASE

	@; @;USART: turn off USART2 error-interrupt enables
	@; ldr r2,[r3,#CR3]
	@; bic r2,#(1<<0)	@;clearing EIE (enables fault-interrupts if DMAR is also on -- see ???. "USART interrupt mapping diagram")
	@; str r2,[r3,#CR3]

	@; @;USART: clear any error flags that might currently be on (see ??? Status register (USART_ISR) description) 
	@; mov r0,0x0F							@;clear error bits 
	@; str r0,[r3,#ICR]					@; ..

	@; @;NVIC: set USART2 interrupt priority to highest (=0)
	@; ldr r3,=NVIC_IPR	
	@; mov r2,#0x00						@;priority is in upper nybble of byte
	@; strb r2,[r3,#LPUART1_NVICbyteoffset]	@; byte access is allowed for priority	

	@; @;NVIC: clear USART2 pending interrupt in NVIC in case something got through previously
	@; ldr r3,=(NVIC_ICPR+4*LPUART1_NVICwordoffset)	
	@; mov r2,#(1<<(LPUART1_NVICbitoffset-32*LPUART1_NVICwordoffset)) //!!check this
	@; str r2,[r3]	//was observed storing ?? at ???; 

	@; @;NVIC: enable USART2 interrupt
	@; ldr r3,=(NVIC_ISER+4*LPUART1_NVICwordoffset)	
	@; mov r2,#(1<<(LPUART1_NVICbitoffset-32*LPUART1_NVICwordoffset))
	@; str r2,[r3] //observed storing ?? at ???

	@; @;USART: resume update of USART2 configuration
	@; ldr r3,=LPUART1_BASE
	
	@; @;USART: enable USART2 RX interrupt
	@; ldr r2,[r3,#CR1]
	@; orr r2,#( (1<<5) ) @; RXNEIE=bit5
	@; str r2,[r3,#CR1]

	@; @;SYSTEM: set TX enable function for use by Msg_post()
	@; mov r0,#0
@; @!!	MOV_imm32 r3,userCOM_MsgCtl @;future fixup - if TX ever gets connected to message queue
@; @!!	str r0,[r3,#MSGHEAD_PTR]	@;clear the message list TODO : figure out how to clear off devices which might be on the list (system reset?)
@; @!!	str r0,[r3,#MSGTAIL_PTR]	@; (maybe this argues for data in .bss so its cleared at startup.

	@; @;turn interrupts back on
	@; CPSIE i

	@;here with USART2 interrupt configured and RX interrupt enabled
@;	pop {r7,pc}



// stuff added to connect with MoT_userCOM0x.S !!wmh : don't know where this gets used (if at all)
	.global userCOM_IRQenable
	.thumb_func
userCOM_IRQenable: @; int LPUART1_IRQinit(void); //returns 0 indicating success
	push {r7,lr}
	MOV_imm32 r3,LPUART1_BASE
	ldr r2,[r3,#USART_CR1]
	orr r2,#( (1<<7) ) @; TXEIE=bit7
	str r2,[r3,#USART_CR1]
	mov r0,#0 
	pop {r7,pc}
