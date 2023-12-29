#this code makes sure that self modifying code works 
#failure indicates improper caching

	mov 	R1, 0 
	mov 	R2, 1 
instr:
	add 	R1, 0xFF

	rdm 	R0, {instr 2 *}
	xor 	R0, 0xAA
	wrm 	R0, {instr 2 *}

	sub 	R2, 1
	jmp 	GE instr

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
	
