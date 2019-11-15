; Documentation
;
; 320x240 4bpp
; 160 bytes per line


	SPEED = 1

;***************************************************
; Includes

	!SRC "VERA.INC"

;***************************************************
; Zero page variables

	!macro reserve ~.address, .amount {
		.address = reserve_offset
		!set reserve_offset = reserve_offset + .amount
	}

	!set reserve_offset = $00

;	Scratch arithmetic
	+reserve ~A8, 	1
	+reserve ~B8, 	1
	+reserve ~A16, 	2
	+reserve ~B16, 	2

;	Psuedo random number xor+shift
	+reserve ~RAND,	2
;	After calling GENRAND will have a radom -4 to +4 (not inc 0) value
	+reserve ~RANDF, 1

;	Envelope prescaler
	+reserve ~ENVELOPE, 1

;	Angles
	+reserve ~QA, 1
	+reserve ~QB, 1
	+reserve ~QC, 1
	+reserve ~QD, 1

;	Envelope Q's
	+reserve ~QEA, 1
	+reserve ~QEB, 1
	+reserve ~QEC, 1
	+reserve ~QED, 1

;	Envelopes
	+reserve ~EA, 1
	+reserve ~EB, 1
	+reserve ~EC, 1
	+reserve ~ED, 1

;	Frequencies
	+reserve ~FA, 1
	+reserve ~FB, 1
	+reserve ~FC, 1
	+reserve ~FD, 1

	+reserve ~SUM_X, 2
	+reserve ~SUM_Y, 2

;	Coordinates unsigned 8 bit from top left
	+reserve ~PSET_XU8, 1
	+reserve ~PSET_YU8, 1

;	Pset colour
	+reserve ~PSET_C, 1

;	Pset history index
	+reserve ~PHIST, 1

;***************************************************
; Low RAM variables

	*=$0801
		!byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00
		JMP	START

; unsigned 8-bit sin values, full circle 256 brads
SIN_TABLE:
		!SRC "SIN.INC"

	!set reserve_offset = *

	+reserve ~PHISTMID, 256
	+reserve ~PHISTLO, 256
	+reserve ~PHISTMSK, 256

	* = reserve_offset

;***************************************************
; Macros
;

; Add a vector to the SUM_X,SUM_Y with some envelope offset
!macro ADDVECT .QVECT, .QENV {

			LDA		.QVECT			; add SIN(QVECT) to SUM_X
			TAX 
			LDA		SIN_TABLE,X
			CLC
			ADC 	SUM_X+0
			STA  	SUM_X+0
			LDA		#0
			ADC 	SUM_X+1
			STA  	SUM_X+1

			LDA		.QVECT			; add SIN(QVECT+64) to SUM_Y  (64=90deg)
			CLC
			ADC		#64
			TAX
			LDA		SIN_TABLE,X
			CLC
			ADC 	SUM_Y+0
			STA  	SUM_Y+0
			LDA		#0
			ADC 	SUM_Y+1
			STA  	SUM_Y+1

			LDA		.QVECT			; add SIN(QVECT+ENV) to SUM_X
			CLC
			ADC 	.QENV
			TAX
			LDA		SIN_TABLE,X
			CLC
			ADC 	SUM_X+0
			STA  	SUM_X+0
			LDA		#0
			ADC 	SUM_X+1
			STA  	SUM_X+1

			LDA		.QVECT			; add SIN(QVECT+ENV+64) to SUM_Y
			CLC
			ADC 	.QENV
			CLC
			ADC		#64
			TAX
			LDA		SIN_TABLE,X
			CLC
			ADC 	SUM_Y+0
			STA  	SUM_Y+0
			LDA		#0
			ADC 	SUM_Y+1
			STA  	SUM_Y+1
}

;***************************************************
; Main program
;***************************************************

START:		+VREG	VERA_CTRL, $80	; Reset & default VERA
			+VREG	DC_VIDEO, 1		; VGA mode

			+VREG	L0_CTRL0, $D1	; Layer 0 mode 6 enabled (4bpp)
			+VREG	L1_CTRL0, $00	; Layer 1 disabled

			+VACTIVE	0,0,640,480	; Active area 

			+VREG	DC_HSCALE, 64	;	320x240
			+VREG	DC_VSCALE, 64	;

			+VADDR0	$00000 | ADDR_INC_1

			LDA 	#$AC			; Init RAND
			STA 	RAND+1
			LDA 	#$E1
			STA 	RAND+0

			LDA		#$00			; init envelope offsets
			STA 	QEA
			LDA		#$40
			STA 	QEB
			LDA		#$80
			STA 	QEC
			LDA		#$C0
			STA 	QED

			LDA		#$69			; Clear screen
			STA		A16+1
			LDA 	#$FF
			STA		A16+0
			LDA		#0
LOOP0:		STA		VERA_DATA0
			INC 	A16+0
			BNE		LOOP0
			INC 	A16+1
			BNE		LOOP0

			LDX		#0				; 0 history buffer
LOOP1:		LDA		#$00
			STA		PHISTMID,X
			STA		PHISTLO,X
			LDA		#$FF
			STA		PHISTMSK,X
			INX 	
			BNE 	LOOP1

			LDA		#$1
			STA		PSET_C

MAINLOOP:	CLC						; advance envelope
			LDA		ENVELOPE
			ADC		#SPEED
			STA 	ENVELOPE
			BCC 	NOTD

			INC 	QEA
			INC 	QEB
			INC 	QEC
			INC 	QED

			LDX		QEA
			LDA		SIN_TABLE,X
			CLC
			ROR		
			CLC
			ADC		#1
			STA 	EA 

			LDX		QEB
			LDA		SIN_TABLE,X
			CLC
			ROR		
			CLC
			ADC		#1
			STA 	EB
			
			LDX		QEC
			LDA		SIN_TABLE,X
			CLC
			ROR		
			CLC
			ADC		#1
			STA 	EC 
			
			LDX		QED
			LDA		SIN_TABLE,X
			CLC
			ROR		
			CLC
			ADC		#1
			STA 	ED 

			LDA 	QEA
			CMP		#$40				; select new random freqencies 
			BNE		NOTA
			JSR		GENRAND
			LDA 	RANDF
			STA 	FA
			JMP		NOTD

NOTA:		LDA 	QEB
			CMP		#$40				; select new random freqencies 
			BNE		NOTB
			JSR		GENRAND
			LDA 	RANDF
			STA 	FB
			JMP		NOTD

NOTB:		LDA 	QEC
			CMP		#$40
			BNE		NOTC
			JSR		GENRAND
			LDA 	RANDF
			STA 	FC
			JMP		NOTD

NOTC:		LDA 	QED
			CMP		#$40
			BNE		NOTD
			JSR		GENRAND
			LDA 	RANDF
			STA 	FD
NOTD:

			LDA 	QA
			CLC
			ADC 	FA
			STA 	QA
			
			LDA 	QB
			CLC
			ADC 	FB
			STA 	QB

			LDA 	QC
			CLC
			ADC 	FC
			STA 	QC

			LDA 	QD
			CLC
			ADC 	FD
			STA 	QD

			LDA		#0				; clear sum
			STA 	SUM_X+0
			STA 	SUM_X+1
			STA 	SUM_Y+0
			STA 	SUM_Y+1

			+ADDVECT QA, EA			; add vectors
			+ADDVECT QB, EB
			+ADDVECT QC, EC
			+ADDVECT QD, ED

;Value is now 0-2047, to get 0-224 we want /8 - /64
			CLC					; divide by 8
			ROR		SUM_X+1
			ROR		SUM_X+0
			CLC
			ROR		SUM_X+1
			ROR		SUM_X+0
			CLC
			ROR		SUM_X+1
			ROR		SUM_X+0
			CLC
			ROR		SUM_Y+1
			ROR		SUM_Y+0
			CLC
			ROR		SUM_Y+1
			ROR		SUM_Y+0
			CLC
			ROR		SUM_Y+1
			ROR		SUM_Y+0

			LDA		SUM_X+0		; X/8 to A8 Y/8 to B8 (value is now 8 bit 0-255)
			STA 	PSET_XU8
			LDA		SUM_Y+0
			STA 	PSET_YU8

			CLC					; divide by another 8 to get /64
			ROR		SUM_X+0
			CLC
			ROR		SUM_X+0
			CLC
			ROR		SUM_X+0
			CLC
			ROR		SUM_Y+0
			CLC
			ROR		SUM_Y+0
			CLC
			ROR		SUM_Y+0

			SEC					;subtract /64 from the /8
			LDA 	PSET_XU8
			SBC		SUM_X+0
			STA 	PSET_XU8

			SEC
			LDA 	PSET_YU8
			SBC		SUM_Y+0
			STA 	PSET_YU8	;Value is now 0-223

			JSR 	PSET

			INC 	PSET_C
			LDA 	PSET_C
			AND 	#$0F
			STA		PSET_C

			JMP		MAINLOOP

;***************************************************
; Subroutines
;***************************************************



;*******************
; PSET 

PSET:	
;			RAM address = X/2 + Y*(128+32)
			LDA		PSET_XU8	; X/2
			CLC
			ROR
			CLC
			ADC 	#24

			STA		A16+0		; X/2 into A16
			LDA 	#$0
			STA 	A16+1

			LDA		PSET_YU8	; Y
			STA		B16+1		; Y*256 into B16
			LDA		#$0
			STA 	B16+0

			CLC					; B16 = Y*128
			ROR 	B16+1
			ROR 	B16+0

			CLC					; ADD TO A16
			LDA		A16+0		
			ADC 	B16+0
			STA 	A16+0
			LDA		A16+1
			ADC 	B16+1
			STA 	A16+1

			CLC					; B16 = Y*32
			ROR 	B16+1
			ROR 	B16+0
			ROR 	B16+1
			ROR 	B16+0

			CLC					; ADD TO A16
			LDA		A16+0		
			ADC 	B16+0
			STA 	A16+0
			LDA		A16+1
			ADC 	B16+1
			STA 	A16+1		; A16 now holds target ram address

			LDA 	#$00			; ERASE what was done 256 calls ago
			STA 	VERA_ADDR_HI
			LDX		PHIST
			LDA 	PHISTMID,X
			STA 	VERA_ADDR_MID
			LDA 	PHISTLO,X
			STA 	VERA_ADDR_LO
			LDA		PHISTMSK,X
			STA		A8
			LDA 	VERA_DATA0
			AND 	A8
			STA 	VERA_DATA0

			LDA 	A16+1			 ; address new pixel, and store location in history
			STA 	VERA_ADDR_MID
			STA 	PHISTMID,X
			LDA 	A16+0
			STA 	VERA_ADDR_LO
			STA 	PHISTLO,X

			LDA 	PSET_XU8		; upper or lower nibble? 
			AND 	#$01
			BEQ 	PSETUN

PSETLN:		LDA 	#$F0			; lower nibble, store mask in history
			STA 	PHISTMSK,X	
			AND		VERA_DATA0		; mask current bitmap data
			ORA		PSET_C			; or in new colour
			STA 	VERA_DATA0		; and write back
			BNE		PSETDONE

PSETUN: 	LDA		PSET_C			; upper nibble
			ASL
			ASL
			ASL
			ASL
			STA		A8
			LDA 	#$0F			; store mask in history
			STA 	PHISTMSK,X	
			AND		VERA_DATA0		; mask current bitmap data
			ORA		A8				; or in new colour
			STA 	VERA_DATA0		; and write back

PSETDONE: 	INX						; advance history index and save
			TXA
			STA 	PHIST
			RTS 



;**********************
; pseudo random numbers

GENRAND:	LDA		RAND+0			
			ASL
			ASL
			EOR		RAND+0
			ASL
			EOR 	RAND+0
			ASL
			ASL
			EOR		RAND+0
			AND 	#$20
			CMP		#$20
			ROR 	RAND+1
			ROR 	RAND+0

			LDA		RAND+0
			AND		#$0F		;#$07
			CLC
			ADC		#$F8		;#$FC
			STA 	RANDF
			BNE 	GR1
			INC 	RANDF
GR1:		RTS
