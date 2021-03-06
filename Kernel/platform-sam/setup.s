;
;	This block is loaded over the start of the video space we
;	will use and moves everything into the right places
;
;	On entry our mapping is going to be
;	ROM 1 6 7
;
;	Our kernel is in 2/3/4/5 and other bits in the start of 6 (ie us)
; 	We use 7 as a buffer
;
;
	.globl _fontdata_8x8_exp2
	
	.area _BOOTSTRAP

MODE3	.equ	0x40		; I think ?

bootstrap:
	; Blue border for debugging
	ld a,#1
	out (254),a
;
;	The kernel low 32K is currently sitting in 4/5 not 0/1 so
;	move it. The upper 32K is already in 2/3
;
	ld de,#0x2420
	call copy16k
	ld de,#0x2521
	call copy16k
;
;	The font follows us and is 4K long but belongs in 4/5 after
;	the mode 3 screen
;
	; Map bank 4/5 low
	ld a,#0x24
	out (250),a
	; Put the font data where it belongs
	ld hl,#_fontdata_8x8_exp2
	ld de,#0xE000-0x8000
	ld bc,#0x1000
	ldir
;
;	In theory we are now ready to actually go live
;
	; Put the video in the right place and set the mode
	ld a,#4 + MODE3
	out (252),a
	xor a
	; Map the kernel low
	out (250),a
	; Black border to hint where we got to
	out (254),a
	jp 0x100
;
;	Move 16K via a bounce buffer
;
copy16k:
	ld a,d			; soure bank
	out (250),a
	ld a,e
	ld hl,#0x0000
	ld de,#0xC000		; buffer via bank 7
	ld bc,#0x4000
	ldir
	out (250),a		; dest bank
	ld hl,#0xC000
	ld de,#0x0000
	ld bc,#0x4000
	ldir
	ret
