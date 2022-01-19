// First:
//	- Load R16 with 0x01
//	- Copy the value into R17
ldi r16, 1
mov r17, r16
nop

// Second:
//	- Load the X register with 0x0201
//	- Copy the value into the Y register
ldi XL, 1
ldi XH, 2
movw Y, X
nop