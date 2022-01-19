// First:
//	- Load R20 with 1
//	- Load R21 with 1
//	- Load R22 with 0
//	- R20 & R21 = 1, SREG = 0x00
//	- R20 & R22 = 0, SREG = 0x02
ldi r20, 1
ldi r21, 1
ldi r22, 0
and r20, r21
and r20, r22
nop

// Second:
//	- Load R20 with 1
//	- Load R21 with 1
//	- Load R22 with 0
//	- R20 | R21 = 1, SREG = 0x00
//	- R20 | R22 = 1, SREG = 0x00
ldi r20, 1
ldi r21, 1
ldi r22, 0
or r20, r21
or r20, r22
nop

// Third:
//	- Load R20 with 1
//	- !R20 = 0xFE, SREG = 0x15
ldi r20, 1
com r20
nop

// Fourth:
//	- Load R20 with 10
//	- 0 - R20 = 0xF6, SREG = 0x35
ldi r20, 10
neg r20
nop