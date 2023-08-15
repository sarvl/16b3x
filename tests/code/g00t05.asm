#basic test of alu functinos with dependencies
#failure probably indicates wrong ALU or OOOE/pipeline implementation

	mov 	R1, 0
	mov 	R0, 16
	sll 	R0, 2
	mov 	R2, R0
	slr 	R0, 2
	mov 	R3, R0
	add 	R0, 1
	sub 	R0, 2
	slr 	R0, 1
	mov 	R4, R0


	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt

