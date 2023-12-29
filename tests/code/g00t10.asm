#this code tests whether all dependencies are properly forwarded in case of long dependency chain

	mov 	R0, 1
	mov 	R1, 2

	mov 	R3, R0
	mov 	R4, R3
	mov 	R0, R1
	mov 	R4, R4
	mov 	R5, R4
	mov 	R6, R5
	mov 	R7, R6
	mov 	R1, R7

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114


	hlt
