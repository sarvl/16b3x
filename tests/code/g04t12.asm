#common pattern of pushing and poping LR 

	jmp 	start

f1:
	add 	R0, 2
	ret

f2:
	rdx 	R7, LR
	psh 	R7

	add 	R0, 1

	cal 	f1

	add 	R0, 3


	pop 	R7
	wrx 	LR, R7
	ret


start:
	mov 	R0, 0
	cal 	f2

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
