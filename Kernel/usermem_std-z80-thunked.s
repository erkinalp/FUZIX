        .module usermem32

	.include "platform/kernel.def"
        .include "kernel.def"

        ; exported symbols
        .globl __uget
        .globl __ugetc
        .globl __ugetw

        .globl __uput
        .globl __uputc
        .globl __uputw
        .globl __uzero
	.globl	user_mapping

	; imported memory helpers

	.globl  map_page_low
	.globl  map_kernel_low
;
;	We need these in the high bank as they switch
;
        .area _COMMONMEM


;	HL = user address, BC = length, DE = kaddr
;
;	On return
;	Z	HL = address to write to, BC = length, DE = kaddr
;
;	NZ	HL = address to write to, BC = length before split, DE = kaddr
;		HL' = user address of rest BC' = length of rest, DE' = kaddr
;		of rest (for a second call)
;
user_mapping:
	bit 7,h
	jr nz, one_high_map		; all over 32K
	push hl
	add hl,bc
	bit 7,h
	jr nz, split_map
	;
	;	Copying an area below the 32K boundary
	;
	pop hl
	ld a,(ix)
	call map_page_low
	xor a
	ret
	;
	;	Base address above 32K so copying a single block of
	;	high memory. Map page2 low, clear top bit of user address
	;	to get target
	;
one_high_map:
	res 7,h
	ld a,2(ix)
	call map_page_low
	xor a
	ret
	;
	;	The hard case - a cross boundary mapping
	;
split_map:
	push de		; target to stack for alt regs
	exx		; do the initial calculations
	pop de		; get the target address into the alt regs
	pop bc		; get the start address again
	ld hl,#0x8000
	or a
	sbc hl,bc	; HL is now bytes that we can fit, BC = start
	ld a,c		; swap HL and BC
	ld c,l
	ld l,a
	ld a,b
	ld b,h
	ld h,a		; HL is start, BC = length to do, DE = target
	push bc
	exx		; back to the main registers
	; We need to adjust DE and BC here. The start doesn't matter we know
	; the split start with always be 0x8000
	ex de,hl
	pop de
	add hl,de
	ex de,hl	; DE is now the second block target, HL is the bytes
			; done now fix up BC
	xor a		; We need to do BC -= HL without disturbing DE
	sub l		; so negate BC
	ld l,a
	sbc a,a
	sub h
	ld h,a
	add hl,bc	; add -HL to BC
	ld c,l		; and move it back
	ld b,h
	ld hl,#0x8000
	exx		; flip back to the right register set
	ld a,(ix)
	call map_page_low
	or h		; set NZ
	ret

uputget:
        ; load DE with the byte count
        ld c, 8(ix) ; byte count
        ld b, 9(ix)
	ld a, b
	or c
	ret z		; no work
        ; load HL with the source address
        ld l, 4(ix) ; src address
        ld h, 5(ix)
        ; load DE with destination address (in userspace)
        ld e, 6(ix)
        ld d, 7(ix)
	ret

__uget:
	push ix
	ld ix,#0
	add ix, sp
	call uputget
	jr z, uget_out
	call user_mapping
	jr z, uget1
	ldir
	exx
	call user_mapping
uget1:	; not split
	ldir
uget_out:
	pop ix
	jp map_kernel_low

__uput:
	push ix
	ld ix,#0
	add ix,sp
	call uputget
	jr z, uget_out
	call user_mapping
	jr z, uput1
	ex de,hl
	ldir
	exx
	call user_mapping
uput1:
	ex de,hl
	ldir
	pop ix
	jp map_kernel_low

__uzero:
	pop de
	pop hl
	pop bc
	push bc
	push hl
	push de
	ld a,b
	or c
	ret z
	call user_mapping
	jr z, zeroit
	call zeroit
	exx
	call user_mapping
zeroit:
	ld (hl),#0
	dec bc
	ld a,b
	or c
	ret z
	ld e,l
	ld d,h
	inc de
	ldir
	jp map_kernel_low

__ugetc:
	pop bc
	pop hl
	push hl
	push bc
	bit 7,(hl)
	ld a,(U_DATA__U_PAGE)
	jr z, ugetcl
	ld a,(U_DATA__U_PAGE + 2)
ugetcl:
	call map_page_low
	ld l,(hl)
	ld h,#0
	jp map_kernel_low
	

__ugetw:
	pop bc
	pop hl
	push hl
	push bc
	bit 7,(hl)
	jr z, ugetwl
	ld a,(U_DATA__U_PAGE + 2)
	call map_page_low
	res 7,h
	ld a,(hl)
	inc hl
normal_wl:
	ld h,(hl)
	ld l,a
	jp map_kernel_low
ugetwl:
	ld a,(U_DATA__U_PAGE)
	call map_page_low
	ld a,(hl)
	inc hl
	bit 7,h
	jr z, normal_wl
	ld l,a
	ld a,(0)		; Split can only mean one address
	ld h,a
	ld a,(U_DATA__U_PAGE + 2)
	jp map_kernel_low

__uputc:
	pop bc
	pop de
	pop hl
	push hl
	push de
	push bc
	bit 7,(hl)
	ld a,(U_DATA__U_PAGE)
	jr z, uputcl
	ld a,(U_DATA__U_PAGE + 2)
uputcl:
	call map_page_low
	ld (hl),e
	jp map_kernel_low

__uputw:
	pop bc
	pop de
	pop hl
	push hl
	push de
	push bc
	bit 7,(hl)
	jr z, uputwl
	ld a,(U_DATA__U_PAGE + 2)
	call map_page_low
	res 7,h
	ld (hl),e
	inc hl
normal_pwl:
	ld (hl),d
	jp map_kernel_low
uputwl:
	ld a,(U_DATA__U_PAGE)
	call map_page_low
	ld (hl),e
	inc hl
	bit 7,h
	jr z, normal_pwl
	ld a,(U_DATA__U_PAGE + 2)
	ld a,d
	ld (0),a		; Split can only mean one address
	jp map_kernel_low
