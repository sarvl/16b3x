#this code tests long dependency chain with UI using registers

	wrx 	UI, 1
	mov 	R0, 0
	wrx 	UI, R0
	mov 	R0, 0
	wrx 	UI, R0
	wrx 	UI, 4
	nop
	wrx 	UI, R0
	mov 	R1, 0
	wrx 	UI, R1
	nop
	nop
	wrx 	UI, R1
	mov 	R3, 0


	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
