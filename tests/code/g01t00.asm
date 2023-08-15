#basic test of unconditional branching 
#failure indicates not working branching

	tst  	R0, R0
	jmp 	LEG start
	mov 	R0, 123
mid:
	jmp 	LEG end
	mov 	R1, 45
start:
	jmp 	LEG mid
	mov 	R2, 67
end:
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt 	LEG
