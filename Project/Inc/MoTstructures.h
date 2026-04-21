//2024-10-06_MoTstructures.h wmh 2024-10-06 : rename some things, absorb definitions from MoT_definitions.h and MoTsupport.h
// Another attempt to collect all MoT defintions in one place and avoid breakage when something is added to or change in MoT's code. 
//MoTstructures.h wmh 2023-11-12 : update MoT_buffer_m, _t structure definition to contain buffer size info
//MoTstructures.h wmh 2022-10-17 : macro/struct renaming 
//MoTstructures.h wmh 2021-10-23 : continues structure cleanup and rationalization, with focus on messaging (reviewed below)
// MoT devices may contain structures which anchor singly-linked lists of elements which can be used by other devices to request services from the device.
// Messages posted on a device's list are processed by device tasks or commands but are not themselves device commands, e.g. aren't dispatched from the command table. 
// ( "" is an important distinction regarding the MoT authority hierarchy, e.g. the tether is supreme )
// We have named the four fields of a list link 'NEXTLINK', 'ELADDR', 'ELSIZE', and 'ELINFO' but the only fixed requirement is NEXTLINK.  
//
// --- Macros and typedefs being used, functions using them 
//	MoT_listAnchor_m, MoT_listAnchor_t 	//where  defined ?
//	MoT_listLink_m,  MoT_listLink_t 	// generic list element
//	MoT_msgLink_m, Mot_msgLink_t		// alias of MoT_listLink
//	MoT_cmdLink_m, Mot_cmdLink_t		// ""

#ifdef __ASSEMBLY__	  //dims colorization when #ifdef is exposed 

	rLISTP 		.req r4			@;points to dev_list[] entry; always valid during execution of MoT functions (note 1)
	rDEVP		.req r5			@;points to data structure of current active device (note 2)
	rCMDP		.req r6			@;points to control structure of command parser for MoT_cmdHandler16a.S (note 3)

	// note 1: this allows MoT devices to use device# to direct access data structures of other devices to post messages
	// note 2: this was previously called 'rTASKP'
	// note 3: this is an interim step in bringing over the earlier assembly-language parser code

// --- MoT device structure definitions (revised 2021-04-19, 2021-09-18)

	// --- MoT device control structure
	//'MoT_core_m' is invoked at the top of a device definition; offsets that follow then reference internal elements of the structure 
	#define MOT_CORESIZE 32	//reserves space in MoT_core data structure for the device control parameters
	.macro MoT_core_m devicename, cmdhandler, defaulttask	//create the standard MoT structure for a device
		.pushsection .data
		.align 2
		.global \devicename
		\devicename:
		.equ THISDEVICE,\devicename
		.word \cmdhandler 
		.word \defaulttask
		.skip (MOT_CORESIZE-8)
		.popsection
		.equ DEVICENAME,\devicename
	.endm

	// --- standard offsets of MoT_core control variables
	// data in MoT_core is in .data section and could be automagically initialized to real values at startup. 
	#define XEQCMD 0			// holds address of the device's command handler
	#define XEQTASK 4			// holds address of the device's task handler
	#define NEXTTASK 8			// holds address of the device's successor device in linked-list task design
	#define XEQC 12				// holds execution address of device task functions written in C (void-void functions to be dispatched by the XEQCMD)
	#define TASKSAVE 16			// preserves XEQTASK address when the device's XEQTASK is replaced by the skip task's execution address
	#define TASKRESUME 20		// will hold return address of the task which called the event-wait function
	#define EVENTARG 24			// will hold the event-wait function's argument 
	#define EVENTVAL 28			// will hold the event-wait function's return value
	//data that follows  can be anything required by the MoT device

#else //Master control structure for C devices. Each device will have the following data structure at its data origin. 
	typedef struct MoT_core {		//task control structure common to all tasks
		void (*xeqcmd)(void *);		//,0	execution address of a device command
		void (*xeqtask)(void);		//,4	coninuation address of a device task
		struct MoT_core *nexttask;	//,8	holds address of the device's successor device in linked-list task design 
		void (*xeqC)(void);			//,12	holds address of a c task's execution address
		void (*tasksave)(void);		//,16	holds xeqtask value of a waiting task
		void (*taskresume)(void);	//,20	holds return address of the call to the event-wait function
		void * eventarg;			//,24	holds address of the event-wait argument	
		void * eventval;			//,28	holds address of the event-wait return value 
	//	msgLINK_t devmsg;			//,32,36,40	holds device default nextmsg, msgp and msgcount 
		}MoT_core_t;		

#endif

#ifdef __ASSEMBLY__

	// --- singly-linked list element
	// macro defining a generic linked list element, used for lists of messages, commands, etc
	.macro MoT_listLink_m LINKname, eladdr=0, elsize=0, elinfo=0
		.pushsection .data
		.align 2		//word alignment 
		// storage allocations within the current device
		\LINKname:		// label of the data structure being defined by the macro (only visible in the local (same file) code)
		.word 0			// word in the data structure will hold link to next list element; initially 0 to indicate not-in-use
		.word \eladdr	// word in the data structure will hold pointer to body of message, command, etc; null if not specified
		.word \elsize	// word in the data structure will hold # of bytes in the body of the message, command, etc; 0 if not specified	
		.word \elinfo	// word in the data structure will hold future applications
		// device-relative offsets in a  'LINKname' data structure to the device's data origin (rDEVP relative)
		.equ \LINKname\()_OFFSET,	( \LINKname - THISDEVICE)
		.equ \LINKname\()_, 		( \LINKname - THISDEVICE + NEXTLINK)		 
		.equ \LINKname\()_ELADDR, 	( \LINKname - THISDEVICE + ELADDR)		 
		.equ \LINKname\()_ELSIZE, 	( \LINKname - THISDEVICE + ELSIZE)	
		.equ \LINKname\()_ELINFO, 	( \LINKname - THISDEVICE + ELINFO)	
		.popsection
	.endm

	// --- standard offsets within the structure of listLINK, 
	.equ NEXTLINK,0		// offset in this link of pointer to next subject link
	.equ ELADDR,4		//       --''--        of subject element address
	.equ ELSIZE,8		//       --''--        of subject element size in bytes
	.equ ELINFO,12		//       --''--        for any use desired


	// --- readymade macros for standard MoT list types
	.macro MoT_msgLink_m msgname, msgaddr, msgsize, msginfo
		MoT_listLink_m \msgname, \msgaddr, \msgsize, 0
	.endm

	.macro MoT_cmdLink_m cmdname, cmdaddr, cmdsize, cmdinfo
		MoT_listLink_m \cmdname, \cmdaddr, \cmdsize, 0
	.endm

#else // struct defining a generic linked list element, used for lists of messages, commands, etc
	//IMPORTANT : so that C or debug can access device structures defined in assembler (and vice-versa) it is necessary that the C structs for a device
	// be created _inside_ a 'super struct' for the device which contains the same struct elements defined in the same order as those in assembly.
	// The compiler will hopefully not rearrange any of the struct's internal elements or their order in the super struct, as all are multiples of sizeof(word). 

	typedef struct MoT_listLink {		// TODO rationalize names of msgLINK and cmdLINK elements
		struct MoT_listLink *nextlink;	// offset 0	in link holds address of a successor link in a linked-list message design
		uint8_t *eladdr;				// offset 4	in link holds pointer to origin of the referenced element 
		uint32_t elsize;				// offset 8	in link holds size in bytes of the referenced element 
		uint32_t elinfo;				// offset 12 in link for future use
	} MoT_listLink_t; 

	typedef MoT_listLink_t MoT_msgLink_t;
	typedef MoT_listLink_t MoT_cmdLink_t;

#endif

#ifdef __ASSEMBLY__

	// offsets within the structure of a generic list anchor as defined by the MoT_listAnchor_m macro
	.equ LISTHEADP,0
	.equ LISTTAILP,4
	.equ BYTEP,8
	.equ BYTECOUNT,12

	// macro defining a generic singly-linked list anchor, used for lists of messages, commands, etc
	.macro MoT_listAnchor_m anchorname, listheadp=0, listtailp=0, bytep=0, bytecount=0
		.pushsection .data
		.align 2			//word alignment 
		\anchorname:		// label of the data structure being defined by the macro (only visible in the local (same file) code)
		.word \listheadp	// will hold address of head entry of list
		.word \listtailp	// will hold address of tail entry of list
		.word \bytep		// will hold current play-position in the buffer of the head entry of the list
		.word \bytecount	// will hold remains-to-play count of the buffer of head entry of list
		// offsets in an individual 'anchorname' data structure relative to a device's data origin (rDEVP-relative so device code can have one-step access to individual registers)
		.equ \anchorname\()_OFFSET,	( \anchorname - THISDEVICE)
		.equ \anchorname\()_LISTHEADP, ( \anchorname - THISDEVICE + LISTHEADP)		 
		.equ \anchorname\()_LISTTAILP, ( \anchorname - THISDEVICE + LISTTAILP)	
		.equ \anchorname\()_BYTEP, ( \anchorname - THISDEVICE + BYTEP)	
		.equ \anchorname\()_BYTECOUNT, ( \anchorname - THISDEVICE + BYTECOUNT)	

		.popsection
	.endm

#else
	typedef struct MoT_listAnchor {		// creates device-local data structures for list of messages or commands
		MoT_listLink_t *listheadp;		// offset 0	in link holds address of head link in a linked-list design
		MoT_listLink_t *listtailp;		// offset 4	in link holds address of tail link in a linked-list design
		uint8_t * bytep;				// holds current play-position in the buffer of the head entry of the list
		uint32_t bytecount;				// holds remains-to-play count of the buffer of head entry of list
	} MoT_listAnchor_t; 

#endif

#ifdef __ASSEMBLY__
//MoT_buffer_t replacement for MoT_structAlloc_m . Assumes align is always on word boundary and leaves end of buffer on word boundary also
	.macro MoT_printbuffer_m  bufname, bufsize=100
		.pushsection .data
		.align 2
		.global \bufname\()_size									//buffer size is a separate global variable created simultaneously with buffer
		\bufname\()_size:
		.equ \bufname\()_SIZE, (\bufname\()_size - THISDEVICE )		//offset in device data
		.word \bufsize												//default size is 100 which can be altered at instantiation
		.global \bufname											// "\bufname" evaluates to address of the data buffer
		\bufname: .skip \bufsize									//buffer size is in bytes
		.equ \bufname\()_DATA, (\bufname - THISDEVICE )				//offset of buffer data in this device's data
		.align 2													//data following this definition starts on word boundary
		.popsection
	.endm
#else
	typedef struct MoT_printbuffer {
		uint32_t	size;		//_count_ of characters in MoT printbuffer ( contents of \bufname\()_size)
		char  *	data;			//_address_ of data in MoT printbuffer (at \bufname\()_data)
	} MoT_printbuffer_t;
#endif

#ifdef __ASSEMBLY__

	//Any data definitions required by the MoT device defined above should follow the 'MoTdevice' invocation 
	.macro MoT_varAlloc_m  varname, varoffset, value=0
		.global \varname
		.pushsection .data
		.align 2
		\varname: .word \value
		.equ \varoffset, (  \varname - THISDEVICE ) 
		.popsection
	.endm

	//Any data definitions required by the MoT device defined above should follow the 'MoTdevice' invocation 
	// 'structalign' parameter places struct on a 2**\structalign byte boundary, 'structsize' parameter allocates structsize bytes for the struct
	.macro MoT_structAlloc_m  structname, structoffsetname, structalign, structsize
		.global \structname
		.pushsection .data
		.align \structalign
		\structname: .skip \structsize
		.equ \structoffsetname, (  \structname - THISDEVICE ) 
		.popsection
	.endm

	//MoT bufAlloc replacement for structAlloc . Assumes align is always on word boundary
	.macro MoT_bufAlloc_m  bufname, bufoffsetname, bufalign=2, bufsize
		.global \bufname
		.pushsection .data
		.align \bufalign
		\bufname: .skip \bufsize
		.equ \bufoffsetname, (  \bufname - THISDEVICE ) 
		.popsection
	.endm


	.macro MoT_struct3Alloc_m  globalname, localname, param0, param1, param2	//used in deviceN for managing device-to-device commands 
	//allocates a generic list element 'linkname' and  initializes it with default '0' values
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
/* not used anywhere
	.macro MoT_cmdlinkAlloc_m  linkname, offsetname, nextp, bodyp, param	//allocates a command list element 'linkname' and  initializes it with default '0' values
		MoTstruct3_m \linkname, \offsetname, \nextp, \bodyp, \param
	.endm

	.macro MoTcmdlistAlloc_m  listname, offsetname, headp, tailp, stopp //allocates a command list  'listname' and  initializes it with default '0' values
		MoTstruct3_m \listname, \offsetname, \headp, \tailp, \stopp
	.endm

*/
	// Following are standard offsets relative to the origin of a MoT message list control structure msgLIST_t
	// moved around 2021-06-20 for compatibility with cmd list struct
	#define LISTHEADP 0
	#define LISTTAILP 4
	#define BYTEP 8			
	#define BYTECOUNT 12

#else	//not assembly, C !!TODO some mechanism for initializing MoT C-device data structure

	#include <stdint.h>

	//message list control structure (reorganized 2021-06-20 for compatibility with cmd list) 
	typedef struct msgLIST {		//C equivlent of  MoT_msgCreate_m /  MoT_msgLink_m 
		MoT_msgLink_t *listheadp;	//,0	pointer to 1st device in the list of devices having messages (where we get characters for sending)
		MoT_msgLink_t *listtailp;	//,4	pointer to final device in the list of devices having messages (where we append new messages)
		uint8_t *bytep;				//,8	pointer to remaining bytes of a device message 
		uint32_t bytecount;			//,12	count of number of bytes remaining in message
	} msgLIST_t;

	typedef struct MoTstruct3 {
		uint32_t param0;
		uint32_t param1;
		uint32_t param2;
	} MoTstruct3_t;

#endif

//#ifdef __ASSEMBLY__
//=== 2024-10-06 additions brought over from from MoTsupport.h
// Cmd_handle data structure definitions and relative offsets --
//   Cmd_handle is defined in section .data and so is initialized at compile-time ==> no need for 'init' operation
/*
	#define CMD_DEVICETABLE -4	//holds address of device dispatch table
 	#define CMD_SOURCE -8		//entry point of function reading serial input stream and returning command, byte by byte
 	#define MSG_DEST -12		//??
//because of conflict with name defined by macro on line 39	#define CMD_STATE -16		//holds address of resume-address of command parser
 	#define CMD_WRINDX -20		//offset in command buffer to location where next byte will be written
	#define TASKLIST -24		//holds address of tasklist root

 	#define C_startingSP 12		// offset in admin/userTasklist where starting SP is stored
*/
//=== end of definitions brought over from MoT_definitions.h
//#endif
