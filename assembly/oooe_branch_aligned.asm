	mov 	R0, 1
	mov 	R1, 2
	mov 	R2, 4
	mov 	R3, 8


	cmp 	R3, R2
	jmp 	G, aligned_address
	
	mov 	R4, 100
	mov 	R5, 104

	hlt 

[ALIGN 2]
aligned_address:
	mov 	R4, 16
	mov 	R5, 32

	hlt
