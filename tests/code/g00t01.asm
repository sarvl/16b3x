#basic tests of dependencies in alu
#failure probably indicates wrong OOOE/pipeline implementation

	mov 	R0, 1
	mov 	R1, 2
	mov 	R2, 4
	mov 	R3, 8

	add 	R0, R2
	add 	R3, R0

	add 	R2, R1
	add 	R2, R3


	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114


	hlt

