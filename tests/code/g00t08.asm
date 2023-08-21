#this code tests whether mul instruction is working 
#failure indicates lack of support (in which case this is NOT an error)
# or improper multiplication support

	mov 	R0, 123
	mov 	R1, 45
	mul 	R0, R1
	mul 	R3, R0

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt
