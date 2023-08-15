#specifically designed to test whether jump to misaligned branch works
#this test failing while g01t04 working means that misaligned jumps do not work 

	mov 	R0, 1
	mov 	R1, 2
	mov 	R2, 4
	mov 	R3, 8


	cmp 	R3, R2
	jmp 	G, misaligned_address
	
	mov 	R4, 100
	mov 	R5, 104

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt 	

misaligned_address:
	mov 	R4, 16
	mov 	R5, 32

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt 	
