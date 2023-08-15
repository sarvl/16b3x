#progam computing fibonacci number
#failure indicates not working flags/branching

	mov 	R0, 0
	mov 	R1, 1

	mov 	R7, 7

	cmp 	R7, 0
	jmp 	LE, end

loop: 
	mov 	R2, R0
	mov 	R0, R1
	add 	R1, R2

	sub 	R7, 1
	jmp 	GE, loop

end:
	wrm 	R0, 80
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt 	LEG
