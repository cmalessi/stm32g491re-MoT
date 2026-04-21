@; MoTdevice_device3.S wmh 2022-10-16 : renamed for clarity (its now the 3rd device in the device list)
@;	Uses tasks to send commands to userLED to blink; command sets blink interval. 
@; commands: 
@; ":03000DF0000000"  -- device3_start initializes with argument 0xF00D and starts device3_runtask
@; ":0301FC"          -- device3_pause pauses device3_runtask
@; ":0302FB"          -- device3_resume resumes device3_runtask
@; ":0303FA"          -- NOP
@; tasks:
@; device3_runtask	  -- executes device3_COUNT (=argument of command 0) task-cycles then prints a message and sends a command to the userLED device
@; device3_skiptask	  -- transfers control to next task

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

@; ----- device3 command dispatch 
@; Definitions of device3's command functions and tasks follow 
	.global device3_cmdHandler		@;this is a void/void* function listed in the devicelist[] defined in main()
	.thumb_func
device3_cmdHandler:	@; void device3_cmdHandler(void *); //first byte at void* is the secondary dispatch index. 
	@; The command dispatcher in device0 branches here from a devicelist entry after receiving a valid command string 
	@; This function is dispatched using the 1st byte in the command buffer.  
	@; The first byte in a MoT command is the index into the devicelist[] which selected this device to be dispatched 
	@; The value of the second byte in the MoT command buffer selects the command in device3_cmds[] jump table below 
	@; subsequent bytes in the command buffer may be arguments of any type depending on the device specification. 
	@; See device3_cmds (below) for the actions of various command device3 command codes.
	push {r7,lr}		@; 'push' balanced with a matching 'pop' at exit of the routines in the dispatch table below
	ldrb r1,[r0],#1		@; read command from the command buffer and advance r0 to point to the argument list (if any) 
	and r1,0x03			@; limit range of command codes to 0-3 (size of dispatch table)	
	tbb [pc,r1]
device3_cmds:
	.byte (device3_start - device3_cmds)/2			@; device3 command #0 sends device3 hello message, start device3 task0
	.byte (device3_pause - device3_cmds)/2			@; device3 command #1 pauses device3 task and sends a message
	.byte (device3_resume - device3_cmds)/2			@; device3 command #2 resumes device3 task and sends a message
	.byte (device3_NOP - device3_cmds)/2			@; device3 command #3 does nothing (included to get table size up to power of 2)
	.align 1 @;I do this for safety, where odd-byte alignment is possible 

@; ----- device3 data structure allocations (see MoTstructures.h for insight on how the macros useaed below operate)
@; '_m' macros  below (MoT_core_m, MoT_msgLink_m, MoT_cmdLink_m) generate initialized data structures for this device in .data

@; IMPORTANT! The 'MoT_core_m' macro must be palced first to create the first variable defined in the device's data structure
@; its arguments are: our name for the device, the name of the device's command handler, and the name of the default task of the device
	MoT_core_m device3, device3_cmdHandler, device3_skiptask	@; creates 'device3' control with initialized command & task ptrs

@;create local variables for use by commands and tasks 
	MoT_varAlloc_m device3_cyclecount, device3_CYCLES	@; ..
	MoT_varAlloc_m device3_reload, device3_RELOAD		@; ..
	MoT_varAlloc_m device3_count, device3_COUNT			@; ..

@; create a message link for reporting device state and initialize it with a 'started' message
	MoT_msgLink_m device3_msg, device3_startedtxt, device3_startedmsglen,
	device3_startedtxt: 
	.ascii "device3 has started\n\r\0"
	.equ device3_startedmsglen, ( . - device3_startedtxt)

@; create some alternate messages without custom links.  Demonstrates how message links can be shared to different messages
	device3_pausedtxt: 
	.ascii "device3 has paused\n\r\0"
	.equ device3_pausedmsglen, ( . - device3_pausedtxt)

	device3_oddtxt: 
	.ascii "device3_CYCLES count is odd\n\r\0"
	.equ device3_oddmsglen, ( . - device3_oddtxt)

@; create custom message links. Using custom links is faster, only costs 16 bytes of .data, and saves 6 extra instruction's storage and execution time
	MoT_msgLink_m device3_evenmsg, device3_eventxt, device3_evenmsglen,
	device3_eventxt: 
	.ascii "device3_CYCLES count is even\n\r\0"
	.equ device3_evenmsglen, ( . - device3_eventxt)

	MoT_msgLink_m device3_resumemsg, device3_resumetxt, device3_resumemsglen,
	device3_resumetxt: 
	.ascii "device3 has resumed\n\r\0"
	.equ device3_resumemsglen, ( . - device3_resumetxt)

@; create separate initialized command links for different commands. cmdLink struct is identical to msgLink but renamed to help keep context straight
	MoT_cmdLink_m userLEDon_cmd, userLEDon_cmdbin, userLEDon_cmdlen,
	userLEDon_cmdbin: 
	.byte 1,1	@;device1,fn1 is device_userLED 'userLED_ONcmd' in device_userLED.S 
	.equ userLEDon_cmdlen, ( . - userLEDon_cmdbin)
	.align 1

	MoT_cmdLink_m userLEDoff_cmd, userLEDoff_cmdbin, userLEDoff_cmdlen,
	userLEDoff_cmdbin: 
	.byte 1,2	@;device1,fn2 is device_userLED 'userLED_OFFcmd' in device_userLED.S 
	.equ userLEDoff_cmdlen, ( . - userLEDoff_cmdbin)
	.align 1

@; ----- device3 commands 
@; device3_cmdHandler() (above) dispatches the functions below

	.thumb_func
device3_start: 	@; The device3_start command expects a uint32_t value as the command argument; this will be used to time the device3 tasks
//	push {r7,lr}								@; done above at command entry (ln 31), so don't do here
	@; gathering device commands arguments. This command expects a single uint32_t argument 
	ldr r1,[r0]									@; read the command argument from the command tail
	str r1,[rDEVP,#device3_RELOAD]				@; and save it in variable 'device3_reload' at offset device3_RELOAD in the device struct (see ln 49)
	str r1,[rDEVP,#device3_COUNT]				@; and in the count 
	mov r1,#0									@; and start a cycle count
	str r1,[rDEVP,#device3_CYCLES]				@; (these are all used by the device3 task defined below)
	@; installing a device task by calling 'MoT_taskUpdate(arg1, arg2)' with the task's execution vectors as arguments 
	MOV_imm32 r0,device3_runtask				@; MoT_taskUpdate arg1: 'device3_runtask()' (defined below)
	mov r1,#NULL								@; MoT_taskUpdate arg2: 'NULL' means device3_runtask() is written in assembly, not C 
	bl MoT_taskUpdate
	@; posting a message by calling MoT_msgPost(arg1, arg2) with the message's link and queue address 
	add r0,rDEVP,#device3_msg_OFFSET			@; MoT_msgPost arg1: address of the 'device3_msg' link which on first use holds the 'device3_started' info
	MOV_imm32 r1,consoleMsgs						@; MoT_msgPost arg2: consoleMsgs is the message queue managed by device0 which connects to the serial port
	bl MoT_msgPost								@; returns here with r0 == 0 : success, r0 == -1 failed to post. return value not used at present
	@; command is complete. Because device3_cmdHandler() saves its entering context with 'push {r7,lr}', the commands must exit with 'pop {r7,pc}'
	pop {r7,pc}									@; reverses push{} on entry to device3_cmdHandler() (ln31 above) 

	.thumb_func
device3_pause: 	@; The device3_pause installs task 'device3_skiptask'
//	push {r7,lr}								@; done above at command entry (ln 31), so don't do here
	@; installing a device task by calling 'MoT_taskUpdate(arg1, arg2)' with the task's execution vectors as arguments 
	MOV_imm32 r0,device3_skiptask				@; MoT_taskUpdate arg1: 'device3_runtask()' (defined below)
	mov r1,#NULL								@; MoT_taskUpdate arg2: 'NULL' means device3_runtask() is written in assembly, not C 
	bl MoT_taskUpdate
	@; prepare to send the 'device3_paused' message using a shared link. This is slower than using a custom link, but is done for the example
	MOV_imm32 r0,device3_pausedtxt				@; update shared message link's pointer to message text
	str r0,[rDEVP,#device3_msg_ELADDR]  		@; .. (see macro MoT_listLink_m in MoTstructures.h to understand this)
	MOV_imm32 r0,device3_pausedmsglen			@; update shared message link's length parameter
	str r0,[rDEVP,#device3_msg_ELSIZE]  		@; ..	
	add r0,rDEVP,#device3_msg_OFFSET			@; MoT_msgPost arg1 : 'device3_msg' link's address 
	MOV_imm32 r1,consoleMsgs						@; MoT_msgPost arg2 : 'consoleMsgs' is the message queue managed by device0 which connects to the serial port
	bl MoT_msgPost								@; returns here with r0 == 0 : success, r0 == -1 failed to post. Return value not used at present
	@; command is complete. Because device3_cmdHandler() saves its entering context with 'push {r7,lr}', the commands must exit with 'pop {r7,pc}'
	pop {r7,pc}									@; reverses push{} on entry to device3_cmdHandler() (ln31 above) 

	.thumb_func
device3_resume: 	@; The device3_resume reinstalls task 'device3_runtask'
//	push {r7,lr}								@; done above at command entry (ln 31), so don't do here
	@; installing a device task by calling 'MoT_taskUpdate(arg1, arg2)' with the task's execution vectors as arguments 
	MOV_imm32 r0,device3_runtask				@; MoT_taskUpdate arg1: 'device3_runtask()' (defined below)
	mov r1,#NULL								@; MoT_taskUpdate arg2: 'NULL' means device3_runtask() is written in assembly, not C 
	bl MoT_taskUpdate
	@; send the 'device3_resumed' message using a shared link. This is slower than using a custom link, but is done for the example
	add r0,rDEVP,#device3_resumemsg				@; MoT_msgPost arg1 : device3_resume message's link address 
	MOV_imm32 r1,consoleMsgs						@; MoT_msgPost arg2 : 'consoleMsgs' is the message queue managed by device0 which connects to the serial port
	bl MoT_msgPost								@; returns here with r0 == 0 : success, r0 == -1 failed to post. Return value not used at present
	@; command is complete. Because device3_cmdHandler() saves its entering context with 'push {r7,lr}', the commands must exit with 'pop {r7,pc}'
	pop {r7,pc}									@; reverses push{} on entry to device3_cmdHandler() (ln31 above) 

	.thumb_func
device3_NOP: 	@; return immediately from device3_cmdHandler
	@; nothing to do
	pop {r7,pc}									@; reverses push{} on entry to device3_cmdHandler() (ln31 above) 

@; ----- device3  tasks 
@; The currently selected task of each/every device runs once per system task-cycle. This device has tasks 'device3_skiptask' and 'device3_runtask'

	@; device3_skiptask -- does nothing.  When a device has nothing to do, a 'skiptask' must execute to continue the task sequence of the task-cycle
	.global device3_skiptask 					@;installed by default as part of device definition (ln 45 above)
	.thumb_func
device3_skiptask:								@; the device3 default task as installed above
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get rDEVP of next device on task list
	ldr pc,[rDEVP,#XEQTASK]						@; 	 and proceed to execute the next task on the devicelist

	@; device3_runtask -- every device3_RELOAD execution cycles while this task is running, send an adminMsg and send a command to userLED to toggle the LED    
	.global device3_runtask   
	.thumb_func
device3_runtask: @;  arrives here with rDEVP pointing to this device's data
	ldr r1,[rDEVP,#device3_COUNT]				@; update count
	subs r1,#1									@; ..
	str r1,[rDEVP,#device3_COUNT]				@; ..
	cbnz r1,3f									@; is count finished? if so, skip updates
	@; here when countdown is done: restart count, increment cycles, send message to admin, and send command to userLED
	ldr r1,[rDEVP,#device3_RELOAD]				@; restart count
	str r1,[rDEVP,#device3_COUNT]				@; ..
	ldr r1,[rDEVP,#device3_CYCLES]				@; increment cycles
	add r1,#1									@; ..
	str r1,[rDEVP,#device3_CYCLES]				@; ..
	@; choosing which message to send: 'even cycles' or 'odd cycles'
	ands r1,#1									@; is new device3_CYCLES value even or odd?
	beq 2f										@; 	 it's even: go send 'even' message and userLED 'off' command
1:	@; here to send the 'odd' message using a shared link. This is slower than using a custom link, but is done to demo the method for this example
	MOV_imm32 r0,device3_oddtxt					@; update device3's shared message link with new message info. 
	str r0,[rDEVP,#device3_msg_ELADDR]  		@; .. (see macro MoT_listLink_m in MoTstructures.h to understand this)
	MOV_imm32 r0,device3_oddmsglen				@; ..
	str r0,[rDEVP,#device3_msg_ELSIZE]  		@; ..	
	add r0,rDEVP,#device3_msg_OFFSET			@; MoT_msgPost arg1: address of the 'device3_msg' link which previousky held the 'device3_started' message info
	MOV_imm32 r1,consoleMsgs						@; MoT_msgPost arg2: 'consoleMsgs' is the message queue managed by device0 which connects to the serial port
	bl MoT_msgPost								@; returns here with r0 == 0 : success, r0 == -1 failed to post. Return value not used at present
	@; here to send the userLED 'on' command using a custom message link. We usually send fixed messages this way because it's faster as we don't need to first update the link 
	MOV_imm32 r0,userLEDon_cmd					@; MoT_cmdPost arg1: defined at top 
	MOV_imm32 r1,internalCmds					@; MoT_cmdPost arg2: 'internalCmds' is the message queue managed by device0 which dispatches commands on any MoT device
	bl MoT_cmdPost								@; in MoTservices_xx.S
	@; here with all jobs of this task finished 
	b 3f
2:	@; here to send the 'even' message using a custom link. This is done for speed and is how things are usually done in tasks. 	
	add r0,rDEVP,#device3_evenmsg_OFFSET		@; MoT_msgPost arg1: address of the custom 'device3_msg' link which holds the device3_evenmsg info
	MOV_imm32 r1,consoleMsgs						@; MoT_msgPost arg2: 'consoleMsgs' is the message queue managed by device0 which connects to the serial port
	bl MoT_msgPost								@; returns here with r0 == 0 : success, r0 == -1 failed to post. Return value not used at present
	@; here to send the userLED 'off' command using a custom message link. We usually send fixed messages this way because it's faster as we don't need to first update the link 
	MOV_imm32 r0,userLEDoff_cmd					@; MoT_cmdPost arg1: defined above
	MOV_imm32 r1,internalCmds					@; MoT_cmdPost arg2: 'internalCmds' is the message queue managed by device0 which dispatches commands on any MoT device
	bl MoT_cmdPost								@; returns with r0 == 0 : success, r0 == -1 failed to post. Unused.  
3:	@; task for this device is done for now -- proceed to next device/task on list
	ldr rDEVP,[rDEVP,#NEXTTASK]					@; get new rDEVP
	ldr pc,[rDEVP,#XEQTASK]						@; start task of new device
