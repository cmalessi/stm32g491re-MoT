// bit-op_macros.S wmh 2024-09-28 : rename 'offset' arguent of macros to 'wordoffset' as a reminder of what the macro is operating on 
// bit-op_macros.S wmh 2024-08-21 : macros designed to operate on STM32 device registers using definitions from the device header file
// One improvement here is putting switches in the macro which detect the size of constant arguments.
// This takes advantage of the ARMv7-m 'flexible second operand' variations rather than always using the MOV_imm32 macro
//	which should really only be necessary when the constant is greater than an imm16 or can't be written as imm8<<n

	.macro MOV_imm32 reg, constant								@; initialize register 'reg' with 32-bit constant value
		movw \reg, #:lower16:\constant
		movt \reg, #:upper16:\constant
	.endm

	.macro MOV_any reg, fieldpos, fieldmask, fieldvalue			@; initialize register 'reg' with a constant value from the device file
	@; takes arguments fieldpos, fieldmask, fieldvalue are the xxx_Pos, xxx_Msk, and values in files like stm32G491xx.h
		.if ( (\fieldmask) >> (\fieldpos) ) < 256				@; fieldvalue is 8 bits or fewer
			mov \reg,\fieldvalue								@; --> 'mov' is ok for any imm8 value shifted to any place in word
		.else
			.if \fieldvalue < 65536 							@; fieldvalue is 16 bits or fewer
				movw \reg,\fieldvalue							@; --> movw is ok for any imm16 value
			.else
				MOV_imm32 \reg,\fieldvalue						@; last resort -- will occasionally require two instructions to do the job
			.endif
		.endif
	.endm

	//macro to update some field of some register of some device. macro uses all predefined identifications (no string construction)
	// note: fieldvalues provided in stm32G491xx.h are mostly shifted to the correct location; 'homemade' vallues should be constructed as (value << fieldpos)
	// this is wasteful if just setting or resetting a single bit; use mSET_DEVICEREG_BIT or mRSET_DEVICEREG_BIT instead
	.macro mUPDATE_DEVICEREG_FIELD structbase, wordoffset, fieldpos, fieldmask, fieldvalue
		MOV_imm32 r3,\structbase
		MOV_any r2, \fieldpos, \fieldmask, \fieldmask
		MOV_any r1, \fieldpos, \fieldmask, \fieldvalue
		ldr r0,[r3,#(\wordoffset)]	// get device register contents
		bic r0,r2				//zero bits in mask		
		orr r0,r1				//replace bits in mask
		str r0,[r3,#(\wordoffset)]	//store back
	.endm

	.macro mCONFIRM_DEVICEREG_FIELD structbase, wordoffset, fieldpos, fieldmask, fieldvalue 
	//returns Z=1 if target register field matcheds fieldvalue ( beq is taken if target matches)
	//this is wasteful if we are just checking a single bit; use mTEST_DEVICEREG_BIT instead
		MOV_imm32 r3,\structbase
		MOV_any r2, \fieldpos, \fieldmask, \fieldmask
		MOV_any r1, \fieldpos, \fieldmask, \fieldvalue
		ldr r0,[r3,#(\wordoffset)]	// get device register contents
		and r0,r2				//expose bits in mask
		eors r0,r1				//test bits in mask and update flags
	.endm

	.macro mCONFIRM_DEVICEREG_BIT_EQ_0 structbase, wordoffset, fieldpos, fieldmask	
	// returns Z=1 if target bit=0 ( beq  is taken if target bit is 0)
	//for use only on 1-bit mask values; 
		.if ( (\fieldmask) >> (\fieldpos) ) > 1					@; fieldvalue is more than imm1
			.error " ERROR: 'mTEST_DEVICEREG_BIT' macro should only be used with 1-bit status or mask "  
		.endif
		MOV_imm32 r0,\structbase
		ldr r0,[r0,#(\wordoffset)]	// get device register contents
		tst r0,\fieldmask		// 'tst' also works
	.endm

	.macro mCONFIRM_DEVICEREG_BIT_EQ_1 structbase, wordoffset, fieldpos, fieldmask
	// returns Z=1 if target bit=1 ( beq  is taken if target bit is 1)
	//for use only on 1-bit mask values; returns Z=1 if target bit=1, (beq taken)
		.if ( (\fieldmask) >> (\fieldpos) ) > 1					@; fieldvalue is more than imm1
			.error " ERROR: 'mTEST_DEVICEREG_BIT' macro should only be used with 1-bit status or mask "  
		.endif
		MOV_imm32 r0,\structbase
		ldr r0,[r0,#(\wordoffset)]	// get device register contents
		and r0,\fieldmask		// expose just the target bit
		eors r0,\fieldmask		// if the target bit=1, register is cleared and Z=1
	.endm

	.macro mUPDATE_DEVICEREG_BIT_TO_1 structbase, wordoffset, fieldpos, fieldmask
		.if ( (\fieldmask) >> (\fieldpos) ) > 1					@; fieldvalue is more than imm1
			.error " ERROR: 'mRESET_DEVICEREG_BIT' macro should only be used with 1-bit controls  "
		.endif
		MOV_imm32 r0,\structbase
		ldr r1,[r0,#(\wordoffset)]	// get device register contents
		orr r1,\fieldmask		// set selected bit location in register
		str r1,[r0,#(\wordoffset)]	// update register contents
	.endm

	.macro mUPDATE_DEVICEREG_BIT_TO_0 structbase, wordoffset, fieldpos, fieldmask
		.if ( (\fieldmask) >> (\fieldpos) ) > 1					@; fieldvalue is more than imm1
			.error " ERROR: 'mRESET_DEVICEREG_BIT' macro should only be used with 1-bit controls  "
		.endif
		MOV_imm32 r0,\structbase
		ldr r1,[r0,#(\wordoffset)]	// get device register contents
		bic r1,\fieldmask		// clear selected bit location in register
		str r1,[r0,#(\wordoffset)]	// update register contents
	.endm

	.macro mBITSET_DEVICEREG structbase, wordoffset, bitpos /* For read/set (rs) registers where writing 0 has no effect on the bit value */ 	
		MOV_imm32 r3,\structbase
		mov r2,#(1<<(\bitpos))
		str r2,[r3,#(\wordoffset)]
	.endm
//example use for NVIC with INT_NN
// .set NVIC_ISER_wordoffset,(INT_NN>>5)
// .set NVIC_ISER_bitpos, (INT_NN&0x1F)
// mWRITEBIT_DEVICEREG NVIC_ISER0, NVIC_ISER_wordoffset, NVIC_ISER_bitpos

	.macro mBYTEWRITE_DEVICEREG structbase, byteoffset, byteval /* For read/set (rs) registers where writing 0 has no effect on the bit value */ 	
		MOV_imm32 r3,\structbase
		mov r2,#(\byteval)
		strb r2,[r3,#(\byteoffset)]
	.endm


//example use for NVIC with INT_NN
//	.set NVIC_IPR_byteoffset, (INT_NN>>3)
//	mWRITEBYTE_DEVICEREG NVIC_IPR0, NVIC_IPR_byteoffset, 0x80




