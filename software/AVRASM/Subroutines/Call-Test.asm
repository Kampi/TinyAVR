.include "m8def.inc"

// First: 
//	- Initialize the Stack Pointer
ldi r16, 0x00
out SPH, r16
ldi r16, 0x80
out SPL, r16
nop

// Second:
//	- Load a value into R20
in	r20, SPL
nop

// Third:
//	- Load the address of the subroutine into the Z register
//	- Call the subroutine
ldi ZL, low(start)
ldi ZH, high(start)
icall

// Fourth:
//	- The subroutine was leaved. Load R17 with 0x01
ldi r17, 1
nop
nop
nop
nop
nop
nop

start:
	push r20
	ldi r16, 2
	ldi r20, 17
	pop r20
	ret