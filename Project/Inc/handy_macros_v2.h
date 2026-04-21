@; handy_macros_v2.h wmh 2023-11-24 : update to remove nested macros (nesting creates problems when macro arguments are multi-stage #define calcuations)
@; Eclipse doesn't like '@' comments so warns about all such assembler comments in .h files

#ifdef __ASSEMBLY__
	#ifndef __HANDY_MACROS__
		#define __HANDY_MACROS__

		@;------ utility macros
			.macro MOV_imm32 reg, constant
				movw \reg, #:lower16:\constant
				movt \reg, #:upper16:\constant
			.endm
		
		@;------ macros to create 'container' (thing like C struct)
		
			@;macro to create symbol for a 'container' 
		.macro CONTAINER_m name
			.ifdef TEMPGLOBAL		@; make context of this label global
				.global \name		@; makes visible in the debugger (cast appropriately to view )
			.endif
			\name:
		.endm

		@; macro to create an internal element of a container 
		.macro ELEMENT_m containername nickname elementname size	@;specify an internal element of a container
			.ifdef TEMPGLOBAL										@; make context of this label global
			.global \containername\nickname\elementname				@; makes visible in the debugger (cast appropriately to view )
			.endif
			\containername\nickname\elementname: @;label of this part of the structure being built ('nickname' to distinguish from similar)
			.skip \size						     @;allocation in bytes for this element
			.ifndef \nickname\elementname 		 @;calculate offset of this element in the larger structure, and give offset a name
				.equ \nickname\elementname,(\containername\nickname\elementname - \containername ) @;define the offset of this element in the container
			.endif
		.endm

		.macro MSGCTNR_m name @;example of a container structure generator to build structures holding the link, function, and data pointers of messages
			.pushsection .bss
			.align 2
			CONTAINER_m	\name 
			ELEMENT_m  \name msg NEXTP 4 		@
			ELEMENT_m  \name msg FUNCTIONP 4 	@
			ELEMENT_m  \name msg DATAP 4 		@
			.popsection
		.endm

		
		.macro	UPDATEBITS_m structbase, regoffset, bitoffset, bitmask, newval 	@;newval must fall within (0xFF<<shift) shifted bit pattern
			@; revised -- MOV_imm32 replaced with inline 
			movw r3, #:lower16:(\structbase)								//movw \reg, #:lower16:\constant
			movt r3, #:upper16:(\structbase)								//movt \reg, #:upper16:\constant
			ldr r2,[r3,#(\regoffset)]
//			bic r2,#((\bitmask)<<(\bitoffset)) wrong -- bitmask is already shifted in stm32L476xx.h
			bic r2,#((\bitmask))
			orr r2,#((\newval)<<(\bitoffset))
			str r2,[r3,#(\regoffset)]
		.endm


		.macro	UPDATEBITS_i structbase, regoffset, bitoffset, bitmask, newval @;'_i' versions of macros are safe to use inline 
			@; revised -- MOV_imm32 replaced with inline 
			push {r2,r3}
			movw r3, #:lower16:(\structbase)								
			movt r3, #:upper16:(\structbase)								
			ldr r2,[r3,#(\regoffset)]
//			bic r2,#((\bitmask)<<(\bitoffset)) wrong -- bitmask is already shifted in stm32L476xx.h
			bic r2,#((\bitmask))
			orr r2,#((\newval)<<(\bitoffset))
			str r2,[r3,#(\regoffset)]
			pop {r2,r3}
		.endm

		.macro	UPDATEWORD_m structbase, regoffset, mask32, value32	@; used when bic/oring an entire word. modifies contents of r1-r3
			@; revised -- MOV_imm32 replaced with inline 
			movw r3, #:lower16:(\structbase)								
			movt r3, #:upper16:(\structbase)								
			ldr r2,[r3,#(\regoffset)]
			movw r1, #:lower16:(\mask32)	@;32-bit pattern of bits to be replaced (=1) and bits to be left as-is 							
			movt r1, #:upper16:(\mask32)								
			bic r2,r1
			movw r1, #:lower16:(\value32)	@;32-bit pattern of bits to be set (=1) and bits to be cleared (=0)						
			movt r1, #:upper16:(\value32)								
			orr r2,r1
			str r2,[r3,#(\regoffset)]
		.endm

		.macro	UPDATEWORD_i structbase, regoffset, mask32, value32	@;'_i' versions of macros are safe to use inline 
			@; revised -- MOV_imm32 replaced with inline
			push {r0-r3}
			movw r3, #:lower16:(\structbase)								
			movt r3, #:upper16:(\structbase)								
			ldr r2,[r3,#(\regoffset)]
			movw r1, #:lower16:(\mask32)	@;32-bit pattern of bits to be replaced (=1) and bits to be left as-is 							
			movt r1, #:upper16:(\mask32)								
			bic r2,r1
			movw r1, #:lower16:(\value32)	@;32-bit pattern of bits to be set (=1) and bits to be cleared (=0)						
			movt r1, #:upper16:(\value32)								
			orr r2,r1
			str r2,[r3,#(\regoffset)]
			pop {r0-r3}
		.endm

		.macro WRITE16_m structbase, regoffset,value16
			movw r3, #:lower16:(\structbase)								
			movt r3, #:upper16:(\structbase)								
			movw r2,#(\value16)
			strh r2,[r3,#(\regoffset)]
		.endm
		
		.macro WRITE32_m structbase, regoffset,value32
			movw r3, #:lower16:(\structbase)								
			movt r3, #:upper16:(\structbase)								
			movw r2, #:lower16:(\value32)	
			movt r2, #:upper16:(\value32)								
			str r2,[r3,#(\regoffset)]
		.endm

		.macro WRITE16_i structbase, regoffset,value16
			push {r2,r3}
			movw r3, #:lower16:(\structbase)								
			movt r3, #:upper16:(\structbase)								
			movw r2,#(\value16)
			strh r2,[r3,#(\regoffset)]
			pop {r2,r3}
		.endm
		
		.macro WRITE32_i structbase, regoffset,value32
			push {r2,r3}
			movw r3, #:lower16:(\structbase)								
			movt r3, #:upper16:(\structbase)								
			movw r2, #:lower16:(\value32)	
			movt r2, #:upper16:(\value32)								
			str r2,[r3,#(\regoffset)]
			pop {r2,r3}
		.endm


		.macro SHORTDELAY_i delaycount,delayfn											@; for safety, _i 'inline' macros protect against inadvertent register changes
			push {r0,r3}
			movw r3, #:lower16:(\delaycount)
			movt r3, #:upper16:(\delaycount)
			bl \delayfn
			pop {r0,r3}
		.endm

		@;DEVICE_m : macro to create local or global symbol for a peripheral register struct
		@; (symbol will be global when 'TEMPGLOBAL' is defined)
		.macro DEVICE_m dname dadr	@;define symbol 'dname' with value 'dadr'
			.ifdef TEMPGLOBAL		@; when this macro context has '.equ TEMPGLOBAL,1' defined
				.global \dname
			.endif
			.equiv \dname,\dadr		@; will prevent multiple definitions of symbol dname in same file, or in all files when 'TEMPGLOBAL' is defined
		.endm

		@;REG_m - macro to create a local or global symbol for a DEVICE_m struct
		@; defines a symbolic value for the offset of the REG_m within its DEVICE_m struct
		@; and provides a global symbol for access in the debugger when when 'TEMPGLOBAL' is defined
		.macro REG_m dname dtype regname offset			@;specify offset of an internal element of a dtype DEVICE_m
			.ifndef \dtype\regname
				.equiv \dtype\regname,\offset
			.endif
			.ifdef TEMPGLOBAL							@;see '.equ' at top of this file
				.global \dname\dtype\regname			@;makes visible in the debugger (cast appropriately to view )
			.endif
			.equiv \dname\dtype\regname,(\dname+\offset)
		.endm

	#endif
#endif

