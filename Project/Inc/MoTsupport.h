//MoTsupport.h wmh 2021-08-24 : adding msg list pointers to standard MoT device control structure -- see '== messages between devices' in readme_wmh--NucleoBlinkyMoT_devp.txt
//MoTstructures.h wmh 2021-06-07 : adds 'MoTstructAlloc' which allows us to set the boundary and size of the allocation a named variable and gives us its offset
//MoTstructures.h wmh 2021-04-21 : yet another tweek -- we are going to do the standard device data structure allocation here
//MoTstructures.h wmh 2021-04-12 : umpteenth revison of MoT data structures
// TODO (maybe) : assembly macro to define an initialized device data structure

#ifdef __ASSEMBLY__	  //dims colorization when #ifdef is exposed 

	rLISTP 		.req r4			@;points to dev_list[] entry; always valid during execution of MoT functions (note 1)
	rDEVP		.req r5			@;points to data structure of current active device (note 2)
	rCMDP		.req r6			@;points to control structure of command parser for MoT_cmdHandler16a.S (note 3)

	// note 1: this allows MoT devices to use device# to direct access data structures of other devices to post messages
	// note 2: this was previously called 'rTASKP'
	// note 3: this is an interim step in bringing over the earlier assembly-language parser code

	//=== definitions brought over from MoT_definitions.h to quiet complaints when assembling MoT_cmdHandler16a.S
	// TODO!! because this has only to do with the MoT message parser written in assembler we can isolate it from the MoT dispatch functions

	//MoT message control structure offsets !!if any additional fields are added, update
	#define MSGPTR 		0		//!!wmh this fails when MoTsupport.h is hidden offset to element in a msgCTL_t structure
	#define MSGCOUNT	4 		//!!wmh ""
	#define MSGLINK		8		//!!wmh ""
	#define MSGBUFORG	12		//!!wmh ""
	#define MSGBUFLIMIT	16		//!!wmh ""
	#define MSGBUFSIZE	20		// ""
	#define GETCHAR_FNP	24		//!!wmh ""

	#define MSGCTL_SIZE	28		//!!if any additional fields are added, update

// Cmd_handle data structure definitions and relative offsets --
//   Cmd_handle is defined in section .data and so is initialized at compile-time ==> no need for 'init' operation
	#define CMD_DEVICETABLE -4	//holds address of device dispatch table
	#define CMD_SOURCE -8		//entry point of function reading serial input stream and returning command, byte by byte
	#define MSG_DEST -12		//??
	#define CMD_STATE -16		//holds address of resume-address of command parser
	#define CMD_WRINDX -20		//offset in command buffer to location where next byte will be written
	#define TASKLIST -24		//holds address of tasklist root

	#define C_startingSP 12		// offset in admin/userTasklist where starting SP is stored

	//=== end of definitions brought over from MoT_definitions.h


	// MoT device structure definitions (revised 2021-04-19)

	// MoT device control structure
	// Following are the required standard set of offsets relative to the origin of the data region allocated to a MoT device
	// This data in this location could be in the .data section so as to be automagically initialized to real values at startup. 
	// This standardized design of a MoT device's data structure may be used for either array-dispatch or linked-list dispatch of MoT tasks
	#define XEQCMD 0			// holds address of a device's command handler
	#define XEQTASK 4			// holds address of a device's task resumption
	#define NEXTTASK 8			// holds address of a device's successor device in linked-list task design
	#define XEQC 12				// holds execution address of device task functions written in C (void-void C functions dispatched by the XEQTASK)
	#define TASKSAVE 16			// preserves XEQTASK address when the device's XEQTASK is replaced by the skip task's execution address
	#define TASKRESUME 20		// will hold return address of the task which called an event-wait function
	#define EVENTARG 24			// will hold the event-wait function's argument (couldn't this function be muxed with the event-wait return value?) 
	#define EVENTVAL 28			// will hold the event-wait function's return value
	#define MSGLISTHEAD	32		// will hold pointer to head of list of message links received by device
	#define MSGLISTTAIL	36		// will hold pointer to tail of list of message links received by device, where we attach new messages

//	#define MSGLINK_T 32		// <<<< origin of the the default message link structure 'msgLINK__t' embedded in the device control structure
//	#define NEXTMSG 0			// (NB! offset relative to MSGLINK_T) holds offset of the device's successor message in a linked-list message design
//	#define MSGP 4				// (NB! offset relative to MSGLINK_T) holds byte pointer to bytes of a device message 
//	#define MSGCOUNT 8			// (NB! offset relative to MSGLINK_T) holds count of number of bytes in a device message

	//data that follows here can be anything required by the MoT device
	#define MOTDATA 40			// use this to reserve space at the top of each MoT task data structure for the device control struct's parameters

	//macro below is to be defined at the very top of the device code; offsets defined above are then all relative to rDEVP
	.macro MoTdevice devicename, cmdhandler, defaulttask	//create an initialized standard MoT structure for a device
		.pushsection .data			@; place in .data so initialized by startup. 
		.align 2
		.global \devicename
		\devicename:
		.equ THISDEVICE,\devicename @; scope for symbol 'THISDEVICE' is local to only the file where 'devicename' is defined
		.word \cmdhandler 			@; void (*cmdhandler)();		//with rDEVP implicit
		.word \defaulttask			@; void (*taskhandler)();		// --"--"
		.skip (MOTDATA-8)
		.popsection
//		.equ DEVICENAME,\devicename	@; TODO check this: do we need symbol 'DEVICENAME' in addtion to 'THISDEVICE'?
	.endm

	// after the above macro is invoked at the start of a device definition the .data section pointer is at a displacement of MOTDATA in the device data

	.macro myMSGLINK linkname, LINKREF	//create a link which this device can use to send messages to other devices
		.pushsection .data
		.align 2
	//	.global \msgname
		\linkname:			//'linkname' is local to this device
		.equ \LINKREF, ( \linkname - THISDEVICE) //LINKREF is a name assigned to the offset of this structure relative to rDEVP
		.word 0				//to hold 'LINKP' (link to next message link, initialized to NULL because in .data)
		.word 0				//to hold 'MSGP', (pointer to message content, initialized to NULL because in .data)
		.popsection
	.endm
	// offsets in the above struct
	#define LINKP 0			//offset of the link field relative to offset 'LINKREF' (device can have a number of differently named LINKREFs)
	#define MSGP 4			//offset of the buffer pointer field relative to offset 'LINKREF' (device can have a number of differently named LINKREFs)

	.macro myMSGBUF bufname, bufsize, BUFREF	//create a simple array message buffer belonging to this device (device can have a number of differently named BUFREFs)
		.pushsection .data
		.align 2
	//	.global \msgname
		\bufname:			//'bufname' is local to this device
		.equ \BUFREF, ( \bufname - THISDEVICE) //BUFREF is a name assigned to the offset of this structure relative to rDEVP
		.skip \bufsize
		.popsection
	.endm


/*
//	#define MSGLINK_T 32		// <<<< origin of the the default message link structure 'msgLINK__t' embedded in the device control structure
	#define NEXTMSG 0			// (NB! offset relative to MSGLINK_T) holds offset of the device's successor message in a linked-list message design
	#define MSGP 4				// (NB! offset relative to MSGLINK_T) holds byte pointer to bytes of a device message 
	#define MSGCOUNT 8			// (NB! offset relative to MSGLINK_T) holds count of number of bytes in a device message

//  internal offsets in the generic link structure for singly-linked lists
	#define ELNEXTP 0
	#define ELBODYP 4
	#define ELPARAM 8

//  internal offsets in anchor structure for singly-linked lists	
//	#define LISTHEADP 0	redefined later
//	#define LISTTAILP 4 
*/



	.macro MoTmsgAlloc msgname, msgoffset	//create a MoT general message descriptor belonging to this device
		.pushsection .data
		.align 2
	//	.global \msgname
		\msgname:
		.word 0				//to hold 'ELNEXTP' (link to next message, initialized to NULL)
		.word 0				//to hold 'ELBODYP', (pointer to message content, initialized to NULL)
		.word 0				//to hold 'ELPARAM', (message content descriptor, in this case, bytecount of message text)
		.equ \msgoffset, ( \msgname - THISDEVICE) //offset relative to rDEVP to this message descriptor
		.popsection
	.endm

	// new approach uses local device name as defined at top e.g. #define THISDEVICE greenLED
	.macro MoTmsgCreate  msgname, stringlabel=DEFAULT_MSGTXT, stringlen=DEFAULT_MSGLEN	//allocates a MoT message structure for msgname and  optionally initializes it
		.pushsection .data
		.align 2
	//	.global \msgname
		\msgname:
		.word 0				//link to next message initialized to NULL 
		.word \stringlabel	//address of message text
		.word \stringlen	//bytecount of message text initialized to 0
		.equ OFFSET\msgname, ( \msgname - THISDEVICE )
		.popsection
	.endm

	//Any data definitions required by the MoT device defined above should follow the 'MoTdevice' invocation 
	.macro MoTvarAlloc  varname, varoffset, value=0
		.global \varname
		.pushsection .data
		.align 2
		\varname: .word \value
		.equ \varoffset, (  \varname - THISDEVICE ) 
		.popsection
	.endm

	//Any data definitions required by the MoT device defined above should follow the 'MoTdevice' invocation 
	// 'structalign' parameter places struct on a 2**\structalign byte boundary, 'structsize' parameter allocates structsize bytes for the struct
	.macro MoTstructAlloc  structname, structoffsetname, structalign, structsize
		.global \structname
		.pushsection .data
		.align \structalign
		\structname: .skip \structsize
		.equ \structoffsetname, (  \structname - THISDEVICE ) 
		.popsection
	.endm
/*
	.macro MoTcmdLink_m  linkname, cmdadr=0, cmdlen	//allocates a link for linkname and  optionally initializes it
		.pushsection .data
		.align 2
	//	.global \linkname	//these links are usually private to a device and only externally accessed by using their address
		\linkname:
		.word 0				//holds NEXTCMDLINK (address of another cmdLink)
		.word \cmdadr		//holds CMDP (address of a command)
		.word \cmdlen		//CMDLEN (bytecount of a command -- not used)
		.equ OFFSET\linkname, ( \linkname - THISDEVICE )
		.popsection
	.endm
*/
	//offsets in MoTcmdLink struct are defined at point of use to avoid conflicts
//	#define  NEXT 0 
//	#define  CMDP 4
//	#define  CMDLEN 8
/*
	.macro MoTcmdList_m  listname \shortname  //allocates a link for linkname and  optionally initializes it
		.pushsection .data
		.align 2
		.global \listname	//this link will be used by other devices to post commands
		\listname:
		.word	0			//holds address of first command link
		.word 	0			//holds address of last command link
		.word   0			//holds address of boundary where next cycle of commands starts 
		.equ OFFSET\listname, ( \listname - THISDEVICE )
		.popsection
	.endm
*/
	//offsets in MoTcmdList struct are defined at point of use to avoid conflicts
//	#define  HEADP 0 
//	#define  TAILP 4

// !!NEW  -- macro for creating generic linked list elements
	.macro MoTstruct3_m  globalname, localname, param0, param1, param2	//allocates a generic list element 'linkname' and  initializes it with default '0' values
		.pushsection .data
		.align 2
		.global \globalname	//
		\globalname:
		\globalname\param0:
		.word	0			
		\globalname\param1:
		.word   0			
		\globalname\param2:
		.word	0			
		//named offsets 
		.equ \localname, ( \globalname - THISDEVICE )
		.equ \localname\param0, (\globalname\param0 - THISDEVICE)
		.equ \localname\param1, (\globalname\param1 - THISDEVICE)
		.equ \localname\param2, (\globalname\param2 - THISDEVICE)

		.popsection
	.endm

	.macro MoTcmdLink_m  linkname, offsetname, nextp, bodyp, param	//allocates a command list element 'linkname' and  initializes it with default '0' values
		MoTstruct3_m \linkname, \offsetname, \nextp, \bodyp, \param
	.endm

	.macro MoTcmdList_m  listname, offsetname, headp, tailp, stopp //allocates a command list  'listname' and  initializes it with default '0' values
		MoTstruct3_m \listname, \offsetname, \headp, \tailp, \stopp
	.endm



// !!NEW -- macro for creating linked list anchors
	.macro MoTlistAnchor_m  anchorname, offset, headp, tailp 	//allocates a list anchor structure and initializes it
		.pushsection .data
		.align 2
		.global \anchorname	//define anchor for list of MotlistElements. This anchor will be defined in the list manager's device data and referenced by name by any device using the list 
		\anchorname:
		.word	0			//holds address of  1st element of the list
		.word 	0			//holds address of last element of the list
		.equ \offset, ( \anchorname - THISDEVICE )
		.equ \offset\headp, ( (\anchorname + 0) - THISDEVICE )
		.equ \offset\tailp, ( (\anchorname + 4)  - THISDEVICE )
		
		.popsection
	.endm





	// Following are standard offsets relative to the origin of a MoT message list control structure msgLIST_t
	// moved around 2021-06-20 for compatibility with cmd list struct

	#define BYTEP 8			
	#define BYTECOUNT 12
	#define LISTHEADP 0
	#define LISTTAILP 4




#else	//not assembly, C !!TODO some mechanism for initializing MoT C-device data structure

#include <stdint.h>

typedef struct msgLINK {
	struct msgLINK *nextmsg;	//,0	holds address of the device's successor device in a linked-list message design
	char *msgp;					//,4	pointer to bytes of a device message 
	uint32_t msgcount;			//,8	count of number of bytes in message
} msgLINK_t; 


typedef struct cmdLINK {
	struct 	cmdLINK *nextcmdlink;	// next command in cmdlist
	uint8_t *cmdbufp;				// MoT command byte array
	uint32_t cmdlen;				// length of valid cmdbuf content 
} cmdLINK_t;


//Master control structure for devices. Each device will have the following data structure at its data origin. 
typedef struct deviceCTL {		//task control structure common to all tasks
	void (*xeqcmd)(void *);		//,0	execution address of a device command
	void (*xeqtask)(void);		//,4	coninuation address of a device task
	struct deviceCTL *nexttask;	//,8	holds address of the device's successor device in linked-list task design 
	void (*xeqC)(void);			//,12	holds address of a c task's execution address
	void (*tasksave)(void);		//,16	holds xeqtask value of a waiting task
	void (*taskresume)(void);	//,20	holds return address of the call to the event-wait function
	void * eventarg;			//,24	holds address of the event argument	
	void * eventval;			//,28	holds address of the event return value 
//	msgLINK_t devmsg;			//,32,36,40	holds device default nextmsg, msgp and msgcount 
} deviceCTL_t;

typedef struct MoTstruct3 {
	uint32_t param0;
	uint32_t param1;
	uint32_t param2;
} MoTstruct3_t;


#endif
