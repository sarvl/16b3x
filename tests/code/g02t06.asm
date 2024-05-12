#this code makes sure that self modifying code works 
#failure indicates improper handling of self modification
#same as g02t05 but self modifying instruction is not aligned

	mov 	R1, 0 
	mov 	R2, 1 
loop:
	rdm 	R0, {modify 2 *}
	xor 	R0, 0xAA
	nop 
modify:
	wrm 	R0, {modify 2 *}

	sub 	R2, 1
	jmp 	GE loop

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
	
