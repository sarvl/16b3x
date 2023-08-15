#basic test of all alu functions with dependencies
#failure probably indicates not working alu or wrong pipeline/OOOE implementaion 

	mov 	R0, 0
	mov 	R1, 1
	mov 	R2, 2
	mov 	R3, 3

	add 	R0, R1
	add 	R2, R3

	sub 	R1, R0
	sub 	R2, R3

	xor 	R0, R2
	xor 	R1, R3

	add 	R0, R0
	add 	R1, R1

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
