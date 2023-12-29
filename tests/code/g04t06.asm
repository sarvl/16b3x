#tests whether UI register works when instructions are not aligned
#failure indicates that value is not properly cleared or not properly used by next instruction

	wrx 	UI, 123
	mov 	R0, 123
	nop
	wrx 	UI, 1
	mov 	R1, 1

	sub 	R0, R1
	xor 	R3, R0 
	add 	R0, R3
	mov 	R4, R0
	and 	R4, R3
	orr 	R5, R3

	wrx 	UI, 42 
	rdx 	R7, UI

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt
	