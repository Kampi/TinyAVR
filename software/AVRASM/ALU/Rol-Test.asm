// First:
//	- Set carry
//	- Load R20 with 1
//	- ror R20 = 0x80, SREG = 0x15
sec
ldi r20, 1
ror r20
nop

// Second:
//	- Set carry
//	- Load R20 with 0x80
//	- rol R20 = 0x01, SREG = 0x19
sec
ldi r20, 0x80
rol r20
nop

// Third:
//	- Load R20 with 0x81
//	- rol R20 = 0xC0, SREG = 0x15
ldi r20, 0x81
asr r20
nop

// Fourth:
//	- Clear carry
//	- Load R20 with 0xFF
//	- lsl R20 = 0xFE, SREG = 0x35
//	- Clear carry, SREG = 0x34
//	- Load R20 with 0x01
//	- lsl R20 = 0x00, SREG = 0x3B
clc
ldi r20, 0xFF
lsl r20
clc
ldi r20, 0x01
lsr r20
nop