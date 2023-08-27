#tests whether jump to register works 

	mov 	R5, mid
	mov 	R6, end
	mov 	R7, start
	tst  	R0, R0
	jmp 	R7	
	mov 	R0, 123
mid:
	jmp 	R6
	mov 	R1, 45
start:
	jmp 	R5
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
