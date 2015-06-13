	.module dragonvideo

	; Methods provided
	.globl _vid256x192
	.globl _plot_char
	.globl _scroll_up
	.globl _scroll_down
	.globl _clear_across
	.globl _clear_lines
	.globl _cursor_on
	.globl _cursor_off
	;
	; Imports
	;
	.globl _fontdata_8x8
	.globl _vidattr

	include "kernel.def"
	include "../kernel09.def"

	.area .text

;
;	Dragon video drivers
;
;	SAM V2=1 V1=1 V0=-
;	6847 A/G=1 GM2=1 GM1=1 GM0=1
;
_vid256x192:
	sta $ffc0
	sta $ffc3
	sta $ffc5
	lda $ff22
	anda #$07
	ora #$f0
	sta $ff22
	rts

;
;	Compute the video base address
;	A = X, B = Y
;
vidaddr:
	ldy #VIDEO_BASE
	exg a,b
	leay d,y		; 256 x Y + X
	rts
;
;	plot_char(int8_t y, int8_t x, uint16_t c)
;
_plot_char:
	pshs y
	lda 4,s
	bsr vidaddr		; preserves X (holding the char)
	tfr x,d
	rolb			; multiply by 8
	rola
	rolb
	rola
	rolb
	rola
	tfr d,x
	leax _fontdata_8x8,x		; relative to font
	ldb _vtattr
	andb #0x3F		; drop the bits that don't affect our video
	beq plot_fast

	;
	;	General purpose plot with attributes, we only fastpath
	;	the simple case
	;
	clra
plot_loop:
	sta _vtrow
	ldb _vtattr
	cmpa #7		; Underline only applies on the bottom row
	beq ul_this
	andb #0xFD
ul_this:
	cmpa #3		; italic shift right for < 3
	blt ital_1
	andb #0xFB
	bra maskdone
ital_1:
	cmpa #5		; italic shift right for >= 5
	blt maskdone
	bitb #0x04
	bne maskdone
	orb #0x40		; spare bit borrow for bottom of italic
	andb #0xFB
maskdone:
	lda ,x+			; now throw the row away for a bit
	bitb #0x10
	bne notbold
	lsra
	ora -1,x		; shift and or to make it bold
notbold:
	bitb #0x04		; italic by shifting top and bottom
	beq notital1
	lsra
notital1:
	bitb #0x40
	beq notital2
	lsla
notital2:
	bitb #0x02
	beq notuline
	lda #0xff		; underline by setting bottom row
notuline:
	bitb #0x01		; inverse or not: we are really in inverse
	bne plot_inv		; by default so we complement except if
	coma			; inverted
plot_inv:
	bitb #0x20		; overstrike or plot ?
	bne overstrike
	sta ,y
	bra plotnext
overstrike:
	anda ,y
	sta ,y
plotnext:
	leay 32,y
	lda _vtrow
	inca
	cmpa #8
	bne plot_loop
	puls y,pc
;
;	Fast path for normal attributes
;
plot_fast:
	lda ,x+			; simple 8x8 renderer for now
	coma
	sta 0,y
	lda ,x+
	coma
	sta 32,y
	lda ,x+
	coma
	sta 64,y
	lda ,x+
	coma
	sta 96,y
	lda ,x+
	coma
	sta 128,y
	lda ,x+
	coma
	sta 160,y
	lda ,x+
	coma
	sta 192,y
	lda ,x+
	coma
	sta 224,y
	puls y,pc

;
;	void scroll_up(void)
;
_scroll_up:
	pshs y
	ldy #VIDEO_BASE
	leax 256,y
vscrolln:
	; Unrolled line by line copy
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	ldd ,x++
	std ,y++
	cmpx video_endptr
	bne vscrolln
	puls y,pc

;
;	void scroll_down(void)
;
_scroll_down:
	pshs y
	ldy #VIDEO_END
	leax -256,y
vscrolld:
	; Unrolled line by line loop
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	ldd ,--x
	std ,--y
	cmpx video_startptr
	bne vscrolld
	puls y,pc

video_startptr:
	.dw	VIDEO_BASE
video_endptr:
	.dw	VIDEO_END

;
;	clear_across(int8_t y, int8_t x, uint16_t l)
;
_clear_across:
	pshs y
	lda 4,s		; x into A, B already has y
	jsr vidaddr	; Y now holds the address
	tfr x,d		; Shuffle so we are writng to X and the counter
	tfr y,x		; l is in d
	lda #$ff
clearnext:
	sta ,x
	sta 32,x
	sta 64,x
	sta 96,x
	sta 128,x
	sta 160,x
	sta 192,x
	sta 224,x
	leax 1,x
	decb
	bne clearnext
	puls y,pc
;
;	clear_lines(int8_t y, int8_t ct)
;
_clear_lines:
	pshs y
	clra			; b holds Y pos already
	jsr vidaddr		; y now holds ptr to line start
	tfr y,x
	ldd #$ffff
	lsl 4,s
	lsl 4,s
	lsl 4,s
wipel:
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	std ,x++
	dec 4,s			; count of lines
	bne wipel
	puls y,pc

_cursor_on:
	pshs y
	lda  4,s
	jsr vidaddr
	tfr y,x
	puls y
	stx cursor_save
	; Fall through
_cursor_off:
	ldb _vtattr
	bitb #0x80
	bne nocursor
	ldx cursor_save
	com ,x
	com 32,x
	com 64,x
	com 96,x
	com 128,x
	com 160,x
	com 192,x
	com 224,x
nocursor:
	rts

	.area .data
cursor_save:
	.dw	0
_vtrow:
	.db	0