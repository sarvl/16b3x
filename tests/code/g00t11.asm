#long sequence of writes to the same reg

	mov 	R0, 1

	add 	R0, R0
	add 	R0, R0
	add 	R0, R0
	add 	R0, R0
	add 	R0, R0
	add 	R0, R0
	add 	R0, R0
	add 	R0, R0

	wrm 	R0, 80
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt 	LEG
