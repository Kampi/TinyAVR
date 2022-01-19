// First: 
//	- Jump to _main
rjmp _main

// Second:
//	- Load R20 with 0x01
ldi r20, 0x01

// Third:
//	- Main-Loop
//	- Increase R20 with every cycle
_main:
	inc r20
	rjmp _main