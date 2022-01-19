// First:
//	- Load R20 with 10
//	- Load R21 with 250
//	- 250 + 10 = 4
//	- Move value 4 from R20 into R16
//	- Load R20 with 1
//	- 4 + 1 + Carry = 6
ldi r20, 10
ldi	r21, 250
add	r20, r21
mov r16, r20
ldi r20, 1
adc r16, r20
nop

// Second:
//	- Load R18 with 10
//	- Load R19 with 20
//  - 10 - 20 = -10
//	- Load R20 with 1
//  - -10 - 1 + C = -12
ldi r18, 10
ldi r19, 20
sub r18, r19
ldi r20, 1
sbc r18, r20
nop

// Third
//	- Load R17 with 1
//	- Decrement R17 by 1
//	- Increment R17 by 1
ldi r17, 1
dec r17
inc r17