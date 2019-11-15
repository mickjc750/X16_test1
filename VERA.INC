
; VERA header


; Macro examples:

; Load address register (port 0/1 determined by existing VERA_CTRL.0)
; +VADDR	PALETTE_BASE | ADDR_INC_1	; Address start of palette, auto-inc by 1

; Load address for port 0
; +VADDR0	VRAM_BASE | ADDR_INC_1		; Address start of video ram via port 0, auto-inc by 1

; Load address for port 1
; +VADDR1	VRAM_BASE | ADDR_INC_1		; Address start of video ram via port 1, auto-inc by 1

; Load register (using port 0)
; +VREG		L1_CTRL0, $00				; Layer 1 disabled

; Set active display area (left, top, right, bottom), (via port0)
; +VACTIVE	0,0,640,480					; Active area


;***************************************************
; Constants

	ADDR_INC_0  	= $000000
	ADDR_INC_1  	= $100000
	ADDR_INC_2  	= $200000
	ADDR_INC_4  	= $300000
	ADDR_INC_8  	= $400000
	ADDR_INC_16  	= $500000
	ADDR_INC_32 	= $600000
	ADDR_INC_64  	= $700000
	ADDR_INC_128  	= $800000
	ADDR_INC_256  	= $900000
	ADDR_INC_512  	= $A00000
	ADDR_INC_1024  	= $B00000
	ADDR_INC_2048  	= $C00000
	ADDR_INC_4096  	= $D00000
	ADDR_INC_8192  	= $E00000
	ADDR_INC_16384 	= $F00000

;***************************************************
;	VERA external address space

	VERA_BASE 		= $9F20
	VERA_ADDR_LO  	= VERA_BASE + 0
	VERA_ADDR_MID 	= VERA_BASE + 1
	VERA_ADDR_HI  	= VERA_BASE + 2
	VERA_DATA0		= VERA_BASE + 3
	VERA_DATA1		= VERA_BASE + 4
	VERA_CTRL 	 	= VERA_BASE + 5
	VERA_IEN 	 	= VERA_BASE + 6
	VERA_ISR 	 	= VERA_BASE + 7

;***************************************************
;	VERA internal registers

;	Video RAM
	VRAM_BASE		= $00000

;	Display composer
	DC_BASE			= $F0000
	DC_VIDEO		= DC_BASE + 0
	DC_HSCALE		= DC_BASE + 1
	DC_VSCALE		= DC_BASE + 2
	DC_BORDER_COLOR	= DC_BASE + 3
	DC_HSTART_L		= DC_BASE + 4
	DC_HSTOP_L		= DC_BASE + 5
	DC_VSTART_L		= DC_BASE + 6
	DC_VSTOP_L		= DC_BASE + 7
	DC_STARTSTOP_H	= DC_BASE + 8
	DC_IRQ_LINE_L	= DC_BASE + 9
	DC_IRQ_LINE_H	= DC_BASE + 10

;	Palette
	PALETTE_BASE	= $F1000

;	Layer 0 
	L0_BASE 		= $F2000
	L0_CTRL0		= L0_BASE + 0
	L0_CTRL1		= L0_BASE + 1
	L0_MAP_BASE_L	= L0_BASE + 2
	L0_MAP_BASE_H	= L0_BASE + 3
	L0_TILE_BASE_L	= L0_BASE + 4
	L0_TILE_BASE_H	= L0_BASE + 5
	L0_HSCROLL_L	= L0_BASE + 6
	L0_HSCROLL_H	= L0_BASE + 7
	L0_VSCROLL_L	= L0_BASE + 8
	L0_VSCROLL_H	= L0_BASE + 9

;	Layer 1
	L1_BASE 		= $F3000
	L1_CTRL0		= L1_BASE + 0
	L1_CTRL1		= L1_BASE + 1
	L1_MAP_BASE_L	= L1_BASE + 2
	L1_MAP_BASE_H	= L1_BASE + 3
	L1_TILE_BASE_L	= L1_BASE + 4
	L1_TILE_BASE_H	= L1_BASE + 5
	L1_HSCROLL_L	= L1_BASE + 6
	L1_HSCROLL_H	= L1_BASE + 7
	L1_VSCROLL_L	= L1_BASE + 8
	L1_VSCROLL_H	= L1_BASE + 9



;***************************************************
;	Macros

; Load address register (port 0/1 determined by existing VERA_CTRL.0)
!MACRO VADDR .ADDR {
	LDA 	#<(.ADDR >> 16)
	STA 	VERA_ADDR_HI
	LDA 	#<(.ADDR >> 8)
	STA 	VERA_ADDR_MID
	LDA 	#<(.ADDR)
	STA 	VERA_ADDR_LO
}

; Load address for port 0
!MACRO VADDR0 .ADDR {
	LDA		#0
	STA		VERA_CTRL
	LDA 	#<(.ADDR >> 16)
	STA 	VERA_ADDR_HI
	LDA 	#<(.ADDR >> 8)
	STA 	VERA_ADDR_MID
	LDA 	#<(.ADDR)
	STA 	VERA_ADDR_LO
}

; Load address for port 1
!MACRO VADDR1 .ADDR {
	LDA		#1
	STA		VERA_CTRL
	LDA 	#<(.ADDR >> 16)
	STA 	VERA_ADDR_HI
	LDA 	#<(.ADDR >> 8)
	STA 	VERA_ADDR_MID
	LDA 	#<(.ADDR)
	STA 	VERA_ADDR_LO
}

; Load register (using port 0)
!MACRO VREG .ADDR, .DATA {
	+VADDR0	.ADDR
	LDA 	#(.DATA)
	STA 	VERA_DATA0
}

; Set active display area (left, top, right, bottom), (via port0)
!MACRO VACTIVE .HSTART, .VSTART, .HSTOP, .VSTOP {
	+VREG	DC_VSTART_L, <(.VSTART)
	+VREG	DC_HSTART_L, <(.HSTART)
	+VREG	DC_VSTOP_L, <(.VSTOP)
	+VREG	DC_HSTOP_L, <(.HSTOP)
	+VREG	DC_STARTSTOP_H, <((.VSTOP>>3)&$20 | (.VSTART>>4)&$10 | (.HSTOP>>6)&$0C | (.HSTART>>8)&$03)
}
