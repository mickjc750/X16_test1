; Documentation
;
; 320x240 4bpp
; 160 bytes per line


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
	+reserve ~A8, 	1
	+reserve ~A16, 	2
	+reserve ~B16, 	2

;	Coordinates signed 8 bit from screen center 
	+reserve ~PSET_X8, 	1
	+reserve ~PSET_Y8, 	1

;	Pset colour
	+reserve ~PSET_C,	1

;***************************************************
; Low RAM variables

	*=$0801
		!byte $0b,$08,$01,$00,$9e,$32,$30,$36,$31,$00,$00,$00
		JMP	START

	!set reserve_offset = *

	+reserve ~HISTORYX8, 256
	+reserve ~HISTORYY8, 256

	* = reserve_offset

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

			LDA		#$69
			STA		A16+1
			LDA 	#$FF
			STA		A16+0
			LDA		#$00
LOOP0:		STA		VERA_DATA0
			INC 	A16+0
			BNE		LOOP0
			INC 	A16+1
			BNE		LOOP0

			LDA		#$1
			STA		PSET_C

			LDA 	#-127
			STA 	PSET_X8
			STA 	PSET_Y8
			LDX		#0
LOOP1:		JSR 	PSET
			INC 	PSET_X8
			INC 	PSET_Y8
			INC 	PSET_C
			LDA 	PSET_C
			AND 	#$0F
			STA		PSET_C
			DEX
			BNE		LOOP1

			JMP		*



;***************************************************
; Subroutines
;***************************************************

PSET:	
;			RAM address = X/2 + 19280 + Y*(128+32)
			LDA		PSET_X8		; X/2
			CMP		#$80
			ROR

			STA		A16+0		; sign extend X/2 into A16
			CMP		#$80
			LDA		#$FF
			ADC 	#$0
			EOR		#$FF
			STA 	A16+1

			LDA		A16+0		; +19280
			CLC					
			ADC 	#<19280
			STA		A16+0		
			LDA		A16+1
			ADC		#>19280
			STA		A16+1

			LDA		PSET_Y8		; Y
			STA		B16+0		; sign extend Y into B16
			CMP		#$80
			LDA		#$FF
			ADC 	#$0
			EOR		#$FF
			STA 	B16+1		

			ASL		B16+0		; B16*32
			ROL		B16+1
			ASL		B16+0
			ROL		B16+1
			ASL		B16+0
			ROL		B16+1
			ASL		B16+0
			ROL		B16+1
			ASL		B16+0
			ROL		B16+1

			CLC					; ADD TO A16
			LDA		A16+0		
			ADC 	B16+0
			STA 	A16+0
			LDA		A16+1
			ADC 	B16+1
			STA 	A16+1

			ASL		B16+0		; B16*128
			ROL		B16+1
			ASL		B16+0
			ROL		B16+1

			CLC					; ADD TO A16
			LDA		A16+0		
			ADC 	B16+0
			STA 	A16+0
			LDA		A16+1
			ADC 	B16+1
			STA 	A16+1

			LDA 	#$00
			STA 	VERA_ADDR_HI
			LDA 	A16+1
			STA 	VERA_ADDR_MID
			LDA 	A16+0
			STA 	VERA_ADDR_LO

			LDA 	PSET_X8
			AND 	#$01
			BEQ 	PSETUN
			LDA		VERA_DATA0
			AND 	#$F0
			ORA		PSET_C
			STA 	VERA_DATA0
			BNE		PSETDONE
PSETUN: 	LDA		PSET_C
			ASL
			ASL
			ASL
			ASL
			STA		A8
			LDA		VERA_DATA0
			AND 	#$0F
			ORA		A8
			STA 	VERA_DATA0
PSETDONE: 	RTS 





