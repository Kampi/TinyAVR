.include "m8def.inc"

// First: 
//	- Initialize the Stack Pointer
ldi r16, 0x00
out SPH, r16
ldi r16, 0x80
out SPL, r16

// Second:
//	- Clear the register R20
clr r20

// Third:
//	- Main-Loop
//	- Increase R20 with every cycle
_main:
	inc r20
	rjmp _main