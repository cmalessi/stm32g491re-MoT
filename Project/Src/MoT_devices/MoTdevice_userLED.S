@; MoTdevice_userLED.S wmh 2022-10-17 : commands for ON, OFF, BLINKinstall, REPORT, SKIPinstall. Tasks: skip, ON, OFF
@;	uses renamed macros from MoTstructures.h

	#define __ASSEMBLY__			@;for MoTstructures.h -- selects assembly macro definitions instead of C structs
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

@; ----- userLED command dispatch 
@; Definitions of the green LED command functions and tasks follow 
	.global userLED_cmdHandler		@;this is a void/void* function referenced in main()
	.thumb_func
userLED_cmdHandler:	@; void userLED_cmdHandler(void *); //first byte at void* is the secondary dispatch index. 
	@; The command dispatcher branches here from the devicelist entry after receiving a valid command string 
	@; The first byte of a MoT command was the index into the devicelist which dispatched this cmdHandler (see main())  
	@; The second byte in the MoT command selects and wxecutes a command in userLED_cmds[] jump table below 
	@; subsequent bytes in the command may be arguments of any type depending on the device specification. 
	@; See userLED_cmds (below) for the actions of various command userLED command codes.
	push {r7,lr}		@; 'push' balanced with a matching 'pop' at exit of the routines in the dispatch table below
	ldrb r1,[r0],#1		@; read command from the command buffer and advance r0 to point to the argument list (if any) 
	and r1,0x07			@; limit range of command codes to 0-7 for safety 	
	tbb [pc,r1]
userLED_cmds:
	.byte (userLED_INITcmd - userLED_cmds)/2			@; userLED command #0 initialize user LED hardware   
	.byte (userLED_ONcmd - userLED_cmds)/2				@; userLED command #1 turns userLED steady 'ON'  
	.byte (userLED_OFFcmd - userLED_cmds)/2				@; userLED command #2 turns userLED steady 'OFF'
	.byte (userLED_BLINKinstall - userLED_cmds)/2		@; userLED command #3 install blinking task, set blink rate 
	.byte (userLED_REPORTcmd - userLED_cmds)/2			@; userLED command #4 report userLED status (ON/OFF)
	.byte (userLED_SKIPinstall - userLED_cmds)/2		@; userLED command #5 installs userLED task skipper
	.byte (userLED_NOP - userLED_cmds)/2				@; userLED command #6 does nothing (placeholder/filler)
	.byte (userLED_NOP - userLED_cmds)/2				@; userLED command #7 does nothing (placeholder/filler)
	.align 1 @;!!important to do this where odd-byte alignment is possible 

@; ----- userLED data structure allocations
@; '_m' macros  below (MoT_core_m, MoT_msgLink_m, MoT_cmdLink_m) create data structures for this device in .data

	@; IMPORTANT! The 'MoT_core_m' macro must create the first variable defined in the device's data structure
	@; macro arguments: name for the device, name of the device's command handler, name of the default task
	MoT_core_m userLED, userLED_cmdHandler, userLED_skiptask @; create device with initialized command & task ptrs

@;create any local variables needed use by device commands and tasks using the MoT_varAlloc_m macro
	MoT_varAlloc_m userLED_cyclecount, ULED_CYCLES		@; ..
	MoT_varAlloc_m userLED_reload, ULED_RELOAD			@; ..
	MoT_varAlloc_m userLED_count, ULED_COUNT			@; ..

@;create any constant messages needed for reporting device information using the MoT_msgLink_m macro
	MoT_msgLink_m INITIALIZED_msg, INITIALIZED_msgtxt, INITIALIZED_msglen,
	INITIALIZED_msgtxt: 
	.ascii "userLED is initialized\n\r\0"
	.equ INITIALIZED_msglen, ( . - INITIALIZED_msgtxt)

	MoT_msgLink_m ON_msg,ON_msgtxt,ON_msglen,
	ON_msgtxt:
	.ascii "userLED is 'ON'\n\r\0"
	.equ ON_msglen, ( . - ON_msgtxt)

	MoT_msgLink_m OFF_msg,OFF_msgtxt,OFF_msglen,
	OFF_msgtxt:
	.ascii "userLED is 'OFF'\n\r\0"
	.equ OFF_msglen, ( . - OFF_msgtxt)	

	MoT_msgLink_m BLINKING_msg, BLINKING_msgtxt, BLINKING_msglen,
	BLINKING_msgtxt:
	.ascii "userLED is BLINKING\n\r\0"
	.equ BLINKING_msglen, ( . - BLINKING_msgtxt)	

@;create a default message for messages created with MoT_msgLink_m which lack explicit initial message references
	DEFAULT_MSGTXT:	@;note: labels 'DEFAULT_MSGTXT' and 'DEFAULT_MSGLEN' are required by default message macro
	.ascii "this is the default message\n\r\0"
	.equ DEFAULT_MSGLEN, ( . - DEFAULT_MSGTXT)


@; ----- userLED commands 
@; userLED_cmdHandler() (above) dispatches the commands below.
@; Upon execution, commands perform some operation and then post a message on the message queue 'consoleMsgs'   
@; IMPORTANT: userLED_cmdHandler() saves its entering context with 'push {r7,lr}', so commands below must exit with 'pop {r7,pc}'

	.thumb_func
userLED_INITcmd: 
//	push {r7,lr}								@; done above at command entry, so dont do here!
	bl userLED_init								@; in \LL_device_support\userLED.S
	@; post the 'initialized' message
	add r0,rDEVP,#INITIALIZED_msg				@; r0= address of the 'initialized' message
	MOV_imm32 r1,consoleMsgs						@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks (rDEVP is needed)
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	pop {r7,pc}									@; command is completed

	.thumb_func
userLED_ONcmd: 
//	push {r7,lr}								@; done above at command entry, so dont do here!
	bl userLED_ON								@; in userLED.S
	@; post the 'ON' message
	add r0,rDEVP,#ON_msg						@; r0= address of the 'initialized' message
	MOV_imm32 r1,consoleMsgs						@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks (rDEVP is needed)
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	pop {r7,pc}									@; command is completed

	.thumb_func
userLED_OFFcmd: 
//	push {r7,lr}								@; done above at command entry, so dont do here!
	bl userLED_OFF								@; in userLED.S
	@; post the 'OFF' message
	add r0,rDEVP,#OFF_msg						@; r0= address of the 'initialized' message
	MOV_imm32 r1,consoleMsgs						@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks (rDEVP is needed)
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	pop {r7,pc}									@; command is completed									

	.global userLED_BLINKinstall				@;made global for debug
	.thumb_func	
userLED_BLINKinstall: @;function sets blink rate and installs userLED_ONtask
	@;here with r0 pointing to 32bit uint32_t in command tail ":0103FFFF0000FE" (ULED_RELOAD=0xFFFF) gives ~1Hz
//	push {r7,lr}								@; done above at command entry, so dont do here
	ldr r1,[r0]									@; get count value from command-tail
	str r1,[rDEVP,#ULED_RELOAD]					@; set devices reload and count values
	str r1,[rDEVP,#ULED_COUNT]					@;	..
	@;set tasks initial execution vectors 
	MOV_imm32 r0,userLED_ONtask
	mov r1,#NULL
	bl MoT_taskUpdate
	bl userLED_ON								@; turn the LED on
	@; post the 'blinking' message
	add r0,rDEVP,#BLINKING_msg					@; r0= address of the 'blinking' message
	MOV_imm32 r1,consoleMsgs						@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks 
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed							

	.global userLED_REPORTcmd					@; made global for debug
	.thumb_func
userLED_REPORTcmd: @;
//	push {r7,lr}								@; done above at command entry, so dont do here
	bl userLED_status							@; get masked image of LED port bit in r0
	cbnz r0,1f
	@;here if BITn in r0 is '0'
	@; post the 'OFF' message
	add r0,rDEVP,#OFF_msg						@; r0= address of the 'initialized' message
	MOV_imm32 r1,consoleMsgs						@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called by commands or tasks 
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed
1:	@;here if BITn in r0 is '1'
	@; post the 'ON' message
	add r0,rDEVP,#ON_msg						@; r0= address of the 'initialized' message
	MOV_imm32 r1,consoleMsgs						@; consoleMsgs is defined in MoTdevice_device0
	bl MoT_msgPost								@; msgPost is only called bu commands or tasks 
	@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; return to command dispatcher
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed							

	.global userLED_SKIPinstall					@; made global for debug
	.thumb_func
userLED_SKIPinstall:
	MOV_imm32 r0,userLED_skiptask
	mov r1,#NULL
	bl MoT_taskUpdate
	@;return to cmdHandlers caller
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed							

	.thumb_func
userLED_NOP:  @; userLED command #6 and  #7 are placeholders for unimplemented commands
	@;return to cmdHandlers caller
//	push {r7,lr}								@; done above at command entry, so dont do here
	mov r0,#0									@; set 'no follow-on command' marker (obsolete?) 
	pop {r7,pc}									@; command is completed							

@; ----- userLED  tasks
@; One of the tasks below always executes on each cycle of the while(1) in main().
@; userLED_skiptask is installed by default at device definition time (see MoT_core_m at top)
@; userLED_ONtask is installed by the userLED_BLINKinstall command above 
@; userLED_OFFtask is installed by userLED_ONtask
@; The currently selected task of each/every device runs once per system task-cycle (one cycle of main's while(1))

@; When a device has nothing to do, a 'skiptask' must execute to continue the task sequence of the task-cycle
	.global userLED_skiptask 					@;default userLED initial task. made global for debug
	.thumb_func
userLED_skiptask:								@; the userLED default task
	@; proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device

	@; cycle-counting version of a blinking LED task
	.global userLED_ONtask  @; changes to the alternate userLED_OFFtask after every ULED_RELOAD task cycles 
	.thumb_func
userLED_ONtask: @;  arrive here with rDEVP pointing to this device's data
	ldr r1,[rDEVP,#ULED_COUNT]					@; update cycle count
	subs r1,#1									@; ..
	str r1,[rDEVP,#ULED_COUNT]					@; ..
	cbnz r1,1f									@; 
	@; here when countdown is done
	ldr r1,[rDEVP,#ULED_RELOAD]					@; restart cycle countdown
	str r1,[rDEVP,#ULED_COUNT]					@; ..
	@; void MoT_taskUpdate( void (*Sfn)(), void (*Cfn)() ); //function called by a task to switch to a different task 
	MOV_imm32 r0,userLED_OFFtask				@; MoT_taskUpdate() arguments are the execution address of another task 
	mov r1,#NULL								@;  The other task might be in asm (see line above) or C (not shown). 
	bl MoT_taskUpdate							@;    MoT_taskUpdate(userLED_OFFtask,NULL) will install the LED 'OFF' task 
	bl userLED_OFF								@; turn the Green LED off in preparation for next task cycle
1:	@; task for this device is done for now -- proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device

	@; alternate cycle-counting version of a blinking LED task
	.global userLED_OFFtask @; task cycle-count version. changes state every ULED_RELOAD task cycles 
	.thumb_func
userLED_OFFtask: @;  arrive here with rDEVP pointing to this device's data
	ldr r1,[rDEVP,#ULED_COUNT]					@; update cycle count
	subs r1,#1									@; ..
	str r1,[rDEVP,#ULED_COUNT]					@; ..
	cbnz r1,1f									@; 
	@; here when countdown is done
	ldr r1,[rDEVP,#ULED_RELOAD]					@; restart cycle countdown
	str r1,[rDEVP,#ULED_COUNT]					@; ..
	MOV_imm32 r0,userLED_ONtask					@; setup for MoT_taskUpdate( void (*Sfn)(), void (*Cfn)() ) call. (see above)
	mov r1,#NULL								@; ..
	bl MoT_taskUpdate							@; ..
	bl userLED_ON								@; turn the Green LED on in preparation for next task cycle
1:	@; task for this device is done for now -- proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device

