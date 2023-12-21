	mov 	R0, 2
	wrx 	LR, 3
lp:
	cal 	lb0 
	pop 	R1
	cal 	lb1	
	jmp 	GE, lp 

	wrm 	R0, 80
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt

lb0:
	ret
lb1:
	sub 	R0, 1
	ret
