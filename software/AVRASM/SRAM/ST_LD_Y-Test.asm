// First:
//	- Load R20 with 0x01
//	- Load memory address (0x01) into Y
//	- Store R20 at the given memory address
//	- Load R21 from the given memory address
ldi r20, 0x01
ldi YL, 0x01
ldi YH, 0x00
st Y, r20
ld r21, Y
nop

// Second:
//	- Load R20 with 0x02
//	- Load memory address (0x02) into Y
//	- Store R20 at the given memory address with increment after
//	- Pre decrement the address and load R21 from the given memory address
ldi r20, 0x02
ldi YL, 0x02
ldi YH, 0x00
st Y+, r20
ld r21, -Y
nop

// Third:
//	- Load R20 with 0x03
//	- Load memory address (0x04) into Y
//	- Store R20 at the given memory address with decrement before
//	- Post increment the address and load R21 from the given memory address
ldi r20, 0x03
ldi YL, 0x04
ldi YH, 0x00
st -Y, r20
ld r21, Y+
nop