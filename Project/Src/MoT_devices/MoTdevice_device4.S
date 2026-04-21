@; MoTdevice_device4.S homework 7
@; commands:
@; ":0400FC"  prints Task 1 message to terminal
@; ":0401FB"  prints Task 2 message to terminal
@; ":0402FA"  prints Task 3 message to terminal
@; ":0403F9"  prints Task 4 message to terminal
@; tasks:
@; device4_skiptask	  -- transfers control to next task

	#define __ASSEMBLY__
	#include "MoTstructures.h"
	.equ NULL,0						@;for returning NULL pointr various places

	@;register equates
	rLISTP 		.req r4				@;points to the device_list[] defined in main()
	rDEVP		.req r5				@;points to the device data of the current active task.

	.macro MOV_imm32 reg, constant
		movw \reg, #:lower16:\constant
		movt \reg, #:upper16:\constant
	.endm

	.syntax unified					@; ARM Unified Assembler Language (UAL) is allowed
	.thumb							@; we are using thumb instructions only

	.text							@; macros below place variable data in initialized .data, the rest in .text

@; ----- device4 command dispatch
@; Definitions of device4's command functions and tasks follow
	.global device4_cmdHandler
	.thumb_func
device4_cmdHandler:
	push {r7,lr}
	ldrb r1,[r0],#1
	and r1,0x03
	tbb [pc,r1]
device4_cmds:
	.byte (device4_task1 - device4_cmds)/2
	.byte (device4_task2 - device4_cmds)/2
	.byte (device4_task3 - device4_cmds)/2
	.byte (device4_task4 - device4_cmds)/2
	.align 1

	MoT_core_m device4, device4_cmdHandler, device4_skiptask


@messages for each task
	MoT_msgLink_m device4_msgt1, device4_msg1, device4_msg1len,
	device4_msg1:
	.ascii "Task 1 message.\n\r\0"
	.equ device4_msg1len, ( . - device4_msg1)

	MoT_msgLink_m device4_msgt2, device4_msg2, device4_msg2len,
	device4_msg2:
	.ascii "Task 2 message.\n\r\0"
	.equ device4_msg2len, ( . - device4_msg2)

	MoT_msgLink_m device4_msgt3, device4_msg3, device4_msg3len,
	device4_msg3:
	.ascii "Task 3 message.\n\r\0"
	.equ device4_msg3len, ( . - device4_msg3)

	MoT_msgLink_m device4_msgt4, device4_msg4, device4_msg4len,
	device4_msg4:
	.ascii "Task 4 message.\n\r\0"
	.equ device4_msg4len, ( . - device4_msg4)

@each task just prints a message upon execution
	.thumb_func
device4_task1:
	add r0, rDEVP, #device4_msgt1_OFFSET
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost
	pop {r7, pc}

	.thumb_func
device4_task2:
	add r0, rDEVP, #device4_msgt2_OFFSET
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost
	pop {r7, pc}

	.thumb_func
device4_task3:
	add r0, rDEVP, #device4_msgt3_OFFSET
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost
	pop {r7, pc}

	.thumb_func
device4_task4:
	add r0, rDEVP, #device4_msgt4_OFFSET
	MOV_imm32 r1, consoleMsgs
	bl MoT_msgPost
	pop {r7, pc}

	.global device4_skiptask
	.thumb_func
device4_skiptask:
	ldr rDEVP,[rDEVP,#NEXTTASK]
	ldr pc,[rDEVP,#XEQTASK]


