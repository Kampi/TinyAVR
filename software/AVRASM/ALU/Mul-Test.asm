// Unsigned x Unsigned multiplication with overflow
ldi r16, 255
ldi r17, 255
mul r16, r17
nop

// Unsigned x Unsigned multiplication with zero
ldi r16, 255
ldi r17, 0
mul r16, r17
nop

// Signed x Signed multiplication
ldi r16, 255
ldi r17, 255
muls r16, r17
nop

// Signed x Unsigned multiplication
ldi r16, 255
ldi r17, 255
mulsu r16, r17
nop

// Signed x Unsigned multiplication
ldi r16, 255
ldi r17, 10
mulsu r16, r17
nop

// Signed x Unsigned multiplication
ldi r16, 1
ldi r17, 10
mulsu r16, r17
nop