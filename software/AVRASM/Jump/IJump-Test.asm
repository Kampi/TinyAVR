// First:
//	- Write the jump address into the Z register
ldi ZL, low(start)
ldi ZH, high(start)

// Second:
//	- Jump to the destination address
ijmp
nop
nop
nop
ldi r16, 1

start:
	nop