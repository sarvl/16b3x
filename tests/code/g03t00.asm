#code to test whether psh/pop work
#failure incidates generally wrong push/pop implementation

	mov 	R0, 100

loopa:
	psh 	R0
	sub 	R0, 1
	jmp 	GE loopa

loopb:
	pop 	R1
	cmp 	R1, 100
	jmp 	LG, loopb

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt
