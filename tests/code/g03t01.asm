#tests whether bytes are saved to stack in the right order
#failure means that LSB is saved to lower address instead of higher

	wrx 	UI, 18
	mov 	R0, 52
	psh 	R0
	
	mov 	R1, 0
	sub 	R1, 2 
	rdm 	R3, R1
	pop 	R4

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt 
