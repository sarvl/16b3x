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
	nop
	hlt
