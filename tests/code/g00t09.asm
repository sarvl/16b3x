#basic tests of dependencies in alu

	mov 	R0, 1
	mov 	R1, 2
	mov 	R2, 4
	mov 	R3, 8

	add 	R0, R2
	add 	R3, R0
	add 	R4, R3

	add 	R5, R1
	add 	R6, R5

	hlt
	nop
