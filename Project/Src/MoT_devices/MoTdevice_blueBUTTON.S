@; device_blueBUTTON.S wmh 2024-02-26 : demonstrates use of device commands and tasks to control other devices
@; Uses button events to send commands to userLED. Pressing button turns LED on, releasing turns LED off
@; Provides weak tests of internal-command queueing
@; MoT 'devices' are typically hardware or software subsystems on the micro which are controlled by sending commands to them.
@; We can integrate individual MoT devices to provide higher level functions through MoT internal-command messages. 
@; The MoT 'command' concept is very flexible -- devices may request other devices to perform actions by sending a command,
@; and the command's recipient may send the result back as a another command. ( operate as a callback )   

	.equ NULL,0						@;for returning NULL pointer at various places
	#define __ASSEMBLY__
	#include "MoTstructures.h"		

	rLISTP 		.req r4				@;points to the device_list[] defined in main()
	rDEVP		.req r5				@;points to data of current active task 

	.macro MOV_imm32 reg, constant
		movw \reg, #:lower16:\constant
		movt \reg, #:upper16:\constant
	.endm

	.syntax unified					@; ARM Unified Assembler Language (UAL) is allowed 
	.thumb							@; thumb-only opcodes
							 
	.text							@; default section -- 

	@;constants derived from those defined in the STM32L476 manual (RM0351) for blue button at port PC13 (default)
	.equ	RCC_BASE,0x40021000 	@;origin of RCC register struct (manual pg 79 )
	.equ 	RCC_AHB2ENR,0x4C		@;GPIOx peripheral clock enable register offset (manual pg 251)
	.equ	GPIOxEN,2				@;GPIOCEN bit location in clock enable register (manual pg 251)

	.equ	GPIOx_BASE,0x48000800	@;origin of GPIOC register struct (manual pg 83)
	.equ	MODER,	0x00			@;GPIOx configuration register offsets (manual pg 585-586)      
	.equ	OTYPER,	0x04	    	@; .. 
	.equ	OSPEEDR,0x08	    	@; .. 
	.equ	OPUPDR,	0x0C	    	@; .. 	
	.equ	IDR,	0x10	    	@; .. 	      
	.equ	ODR,	0x14	    	@; .. 	
	.equ	BSRR,	0x18	    	@; .. 	      
	.equ	LCKR,	0x1C	    	@; .. 	
	.equ	AFRL,	0x20	    	@; .. 	
	.equ	AFRH,	0x24	    	@; .. 	
	.equ	BRR,	0x28	    	@; .. 
	.equ	ASCR,	0x2C	    	@; .. 

	.equ	BITn,13					@; portbit number 0 of GPIOx
	
@; ----- blueBUTTON command handler and commands 
	.text
	.align 2

	.global blueBUTTON_cmdHandler			@;this is a void/void* function listed in the devicelist[] defined in main()
	.thumb_func
blueBUTTON_cmdHandler:	// void blueBUTTON_cmdHandler(void *); //first byte at void* is the secondary dispatch index. 
	@; The command dispatcher in device0 branches here from a devicelist entry after receiving a valid command string 
	@; This function is dispatched using the 1st byte in the command buffer.  
	@; The first byte in a MoT command is the index into the devicelist[] which selected this device to be dispatched 
	@; The value of the second byte in the MoT command buffer selects the command in userLED_cmds[] jump table below 
	@; subsequent bytes in the command buffer may be arguments of any type depending on the device specification. 
	push {r7,lr}		@;this 'push' is balanced with a 'pop' at exit of each of the routines of the dispatch table below
	ldrb r1,[r0],#1		@;read function code from the command buffer and advance r0 to point to the command's argument list (if any) 
	and r1,0x03			@;limit range of function codes to 0-3 for safety (error-checking would be nice but isnt done here)	
	tbb [pc,r1]
fns_blueBUTTON:	@; commands
	.byte (initPC13 - fns_blueBUTTON)/2	  				@;initialize blue button hardware (left in for future blue button applications)
	.byte (bBuserLED_on - fns_blueBUTTON)/2	 			@; send commands to userLED to turn LED on
	.byte (bBuserLED_off - fns_blueBUTTON)/2	 		@; send commands to userLED to turn LED off
	.byte (blueBUTTON_monitor - fns_blueBUTTON)/2	  	@; monitors blueBUTTON, send commands to userLED to turn LED on or off
	.align 1 @;!!important to do this where odd-byte alignment is possible 


@; ----- blueBUTTON data structure allocations
@; '_m' macros  below (MoT_core_m, MoT_msgLink_m, MoT_cmdLink_m) generate initialized data structures for this device in .data

	@; IMPORTANT! The 'MoT_core_m' macro must create the first variable defined in the device's data structure
	@; macro arguments: name for the device, name of the device's command handler, name of the default task
	MoT_core_m blueBUTTON, blueBUTTON_cmdHandler, blueBUTTON_skiptask	

	@; The 'Link_m' macros create generic data structures to hold the elements of various types of singly-linked lists
	@; arguments of the MoT_msgLink_m and MoT_cmdLink_m macros are: link name, link data, link length

	@; Message link(s)
	MoT_msgLink_m bBINITIALIZED_msg, bBINITIALIZED_msgtxt, bBINITIALIZED_msglen,
	bBINITIALIZED_msgtxt: 
	.ascii "blueBUTTON is initialized\n\r\0"
	.equ bBINITIALIZED_msglen, ( . - bBINITIALIZED_msgtxt)

	MoT_msgLink_m bBMONITORED_msg, bBMONITORED_msgtxt, bBMONITORED_msglen,
	bBMONITORED_msgtxt: 
	.ascii "blueBUTTON is monitored\n\r\0"
	.equ bBMONITORED_msglen, ( . - bBMONITORED_msgtxt)


	@; Test of command queueing -- we have created multiple MoT_cmdLink_m command message links below
	@; These will be sent in bursts to test command queuing 
	@; The commands being sent turn userLED on and off repeatedly within a single execution cycle of device0

	@; Command link(s) : contain decoded binary commands which are placed in a list for immediate dispatch by the target
	MoT_cmdLink_m bBuserLEDon_cmd, bBuserLEDon_cmdbin, bBuserLEDon_cmdlen,
	bBuserLEDon_cmdbin: 
	.byte 1,1	@;device1,fn1 is device_userLED 'userLED_ONcmd' in device_userLED.S 
	.equ bBuserLEDon_cmdlen, ( . - bBuserLEDon_cmdbin)

	MoT_cmdLink_m bBuserLEDoff_cmd, bBuserLEDoff_cmdbin, bBuserLEDoff_cmdlen,
	bBuserLEDoff_cmdbin: 
	.byte 1,2	@;device1,fn2 is device_userLED 'userLED_OFFcmd' in device_userLED.S 
	.equ bBuserLEDoff_cmdlen, ( . - bBuserLEDoff_cmdbin)

	MoT_cmdLink_m bBuserLEDoff_cmd1, bBuserLEDoff_cmd1bin, bBuserLEDoff_cmd1len,
	bBuserLEDoff_cmd1bin: 
	.byte 1,2	@;device1,fn2 is device_userLED 'userLED_OFFcmd' in device_userLED.S 
	.equ bBuserLEDoff_cmd1len, ( . - bBuserLEDoff_cmd1bin)

	MoT_cmdLink_m bBuserLEDon_cmd2, bBuserLEDon_cmd2bin, bBuserLEDon_cmd2len,
	bBuserLEDon_cmd2bin: 
	.byte 1,1	@;device1,fn1 is device_userLED 'userLED_ONcmd' in device_userLED.S 
	.equ bBuserLEDon_cmd2len, ( . - bBuserLEDon_cmd2bin)

	MoT_cmdLink_m bBuserLEDoff_cmd3, bBuserLEDoff_cmd3bin, bBuserLEDoff_cmd3len,
	bBuserLEDoff_cmd3bin: 
	.byte 1,2	@;device1,fn2 is device_userLED 'userLED_OFFcmd' in device_userLED.S 
	.equ bBuserLEDoff_cmd3len, ( . - bBuserLEDoff_cmd3bin)


	@; --- blueBUTTON device commands
	@; functions below are those being dispatched by blueBUTTON_cmdHandler() defined above
	.global init_blueBUTTON
	.thumb_func
init_blueBUTTON:	//wrapper provided for use of initPC13() MoT command without cmd_blueBUTTON dispatcher
	push {r7,lr}	@;this 'push' balances the 'pop' at exit of the MoT command below
	.thumb_func
initPC13: @;configure bit 13 of GPIOC as input
	@; set port enable bit (manual pg 492)
	ldr r3,=RCC_BASE			@;load RCC struct address
	ldr r2,[r3,#RCC_AHB2ENR]	@;get current values of device enables
	orr r2,#(1<<GPIOxEN)		@;enable port
	str r2,[r3,#RCC_AHB2ENR]	@; ..
	
	@; configure as an input (manual pg 578)
	ldr r3,=GPIOx_BASE			@;load GPIOx struct address
	ldr r2,[r3,#MODER]			@;get current mode values of port
	bic r2,#(3<<(2*BITn))		@;clear current mode value of port bit
	orr	r2,#(0<<(2*BITn))		@;set new mode value of port bit to input
	str r2,[r3,#MODER]			@; ..
	
	@; configure with no pullup, pulldown
	ldr r2,[r3,#OPUPDR]			@;get current pu/pd settings of port
	bic r2,#(3<<(2*BITn))		@;clear current pupd value of port bit (=no pu/pd)
	str r2,[r3,#OPUPDR]			@; ..
	
	@; post message about change	
	add r0,rDEVP,#bBINITIALIZED_msg			@; r0= address of message descriptor
	MOV_imm32 r1,consoleMsgs					@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost							@; and post it. MoT_msgPost must only be called from device command or task so rDEVP is implicit
	pop {r7,pc}								@;  to balance command dispatch

	.global bBuserLED_on @;unnecessary extra calls to  MoT_cmdPost(MoT_cmdLink_t *, MoTlistAnchor_t *) to test internal-command queuing 
	.thumb_func
 bBuserLED_on:
	MOV_imm32 r0,bBuserLEDon_cmd			@;defined above
	MOV_imm32 r1,internalCmds				@; in MoTdevice_device0.S (in libMoTsystem.a)
	bl MoT_cmdPost							@; in MoTservices_v5_04.S (in libMoTsystem.a)
.ifdef SEND_MULTIPLE
	MOV_imm32 r0,bBuserLEDoff_cmd1			@; etc.
	MOV_imm32 r1,internalCmds				@; ..
	bl MoT_cmdPost							@; ..
	MOV_imm32 r0,bBuserLEDon_cmd2			@; ..
	MOV_imm32 r1,internalCmds				@; ..
	bl MoT_cmdPost							@; ..
.endif
	@; return value is don't care for test
	pop {r7,pc}								@; to balance command dispatch 

	.global bBuserLED_off @;many unnecessary extra calls to  MoT_cmdPost(MoT_cmdLink_t *, MoTlistAnchor_t *) to test internal-command queuing 
	.thumb_func
 bBuserLED_off:
	MOV_imm32 r0,bBuserLEDoff_cmd			@;defined above
	MOV_imm32 r1,internalCmds				@; in MoTdevice_device0.S
	bl MoT_cmdPost							@; in MoTservices_xx.S
.ifdef SEND_MULTIPLE
	MOV_imm32 r0,bBuserLEDon_cmd			@; etc.
	MOV_imm32 r1,internalCmds				@; ..
	bl MoT_cmdPost							@; ..
	MOV_imm32 r0,bBuserLEDoff_cmd1			@; ..
	MOV_imm32 r1,internalCmds				@; ..
	bl MoT_cmdPost							@; ..
	MOV_imm32 r0,bBuserLEDon_cmd2			@; ..
	MOV_imm32 r1,internalCmds				@; ..
	bl MoT_cmdPost							@; ..
	MOV_imm32 r0,bBuserLEDoff_cmd3			@; .
	MOV_imm32 r1,internalCmds				@; ..
	bl MoT_cmdPost							@; ..
.endif
	@; return value is don't care for test
	pop {r7,pc}								@; to balance command dispatch 

	.global blueBUTTON_monitor
	.thumb_func
blueBUTTON_monitor:  	@; install button monitoring task
	MOV_imm32 r0,blueBUTTON_wait_for_press 	@;change blueBUTTON task to 'wait for press'  
	mov r1,#NULL							@; ..
	bl MoT_taskUpdate						@; .. 
	@; post message about change	
	add r0,rDEVP,#bBMONITORED_msg			@; r0= address of message descriptor
	MOV_imm32 r1,consoleMsgs					@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost							@; and post it. MoT_msgPost must only be called from device command or task so rDEVP is implicit
	pop {r7,pc}								@;  to balance command dispatch

						


	@; --- blueBUTTON tasks

	.global blueBUTTON_skiptask 			@;default blueBUTTON initial task. global for debug
	.thumb_func
blueBUTTON_skiptask:		
	ldr rDEVP,[rDEVP,#NEXTTASK]				@;proceed to next device/task on list 
	ldr pc,[rDEVP,#XEQTASK]					@;  ..

	.global blueBUTTON_wait_for_press
	.thumb_func
 blueBUTTON_wait_for_press:
	ldr r3,=GPIOx_BASE						@;load button GPIO struct address
	ldr r0,[r3,#IDR]						@;get current button value
	ands r0,r0,#(1<<(1*BITn))				@;mask it
	bne 1f									@;if button is not pressed
	@; here if button is pressed
	MOV_imm32 r0,bBuserLEDon_cmd			@;send command to turn LED on
	MOV_imm32 r1,internalCmds				@; ..
	bl MoT_cmdPost							@; ..
	MOV_imm32 r0,blueBUTTON_wait_for_release@;change blueBUTTON task to 'wait for release'  
	mov r1,#NULL							@; ..
	bl MoT_taskUpdate						@; .. 
1:	ldr rDEVP,[rDEVP,#NEXTTASK]				@; proceed to next device/task on list
	ldr pc,[rDEVP,#XEQTASK]					@; ..

	
	.global blueBUTTON_wait_for_release
	.thumb_func
 blueBUTTON_wait_for_release:
	ldr r3,=GPIOx_BASE						@;load button GPIO struct address
	ldr r0,[r3,#IDR]						@;get current button value
	ands r0,r0,#(1<<(1*BITn))				@;mask it
	beq 1f									@;if button is pressed
	@; here if button was released
	MOV_imm32 r0,bBuserLEDoff_cmd			@;send command to turn LED off
	MOV_imm32 r1,internalCmds				@; ..
	bl MoT_cmdPost							@; ..
	MOV_imm32 r0,blueBUTTON_wait_for_press 	@;change blueBUTTON task to 'wait for press'  
	mov r1,#NULL							@; ..
	bl MoT_taskUpdate						@; .. 
1:	ldr rDEVP,[rDEVP,#NEXTTASK]				@; proceed to next device/task on list
	ldr pc,[rDEVP,#XEQTASK]					@; ..

	

