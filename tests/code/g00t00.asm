#basic test of all alu functions, specifically avoiding hazards for short pipelines
#failure probably indicates not working alu 

	mov 	R0, 0
	mov 	R1, 1
	mov 	R2, 3
	mov 	R3, 6
	mov 	R4, 10
	mov 	R5, 15
	mov 	R6, 21
	mov 	R7, 28

	add 	R0, R1
	sub 	R1, R2
	not 	R2, R3
	and 	R3, R4
	orr 	R4, R5
	xor 	R5, R6
	sll 	R6, R7
	slr 	R7, R0

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt

