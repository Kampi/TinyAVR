// First:
//	- Load R20 with 0x01
//	- Load memory address (0x01) into Z
//	- Store R20 at the given memory address
//	- Load R21 from the given memory address
ldi r20, 0x01
ldi ZL, 0x01
ldi ZH, 0x00
st Z, r20
ld r21, Z
nop

// Second:
//	- Load R20 with 0x02
//	- Load memory address (0x02) into Z
//	- Store R20 at the given memory address with increment after
//	- Pre decrement the address and load R21 from the given memory address
ldi r20, 0x02
ldi ZL, 0x02
ldi ZH, 0x00
st Z+, r20
ld r21, -Z
nop

// Third:
//	- Load R20 with 0x03
//	- Load memory address (0x04) into Z
//	- Store R20 at the given memory address with decrement before
//	- Post increment the address and load R21 from the given memory address
ldi r20, 0x03
ldi ZL, 0x04
ldi ZH, 0x00
st -Z, r20
ld r21, Z+
nop