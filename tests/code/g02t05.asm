#this code makes sure that self modifying code works 
#failure indicates improper handling of self modification
#g02t04 modifies ANOTHER instruction 

	mov 	R1, 0 
	mov 	R2, 1 
loop:
	rdm 	R0, {modify 2 *}
	xor 	R0, 0xAA
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
	
