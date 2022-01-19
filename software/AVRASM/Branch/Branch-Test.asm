// Carry not set - skip next two instructions
brbc 0, One_NotSet
ldi r16, 2
inc r16
One_NotSet:
	ldi r16, 1

// Carry set - don´t skip next two instructions
sec
brbc 0, One_IsSet
ldi r16, 2
inc r16
One_IsSet:
	ldi r16, 1

// Carry not set - don´t skip next two instructions
clc
brbs 0, Two_NotSet
ldi r16, 2
inc r16
Two_NotSet:
	ldi r16, 1

// Carry set - skip next two instructions
sec
brbs 0, Two_IsSet
ldi r16, 2
inc r16
Two_IsSet:
	ldi r16, 1