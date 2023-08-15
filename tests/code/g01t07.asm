#this code checks whether condition codes work on return

	jmp 	LEG start

proc:
	mov 	R0, 45
	cmp 	R0, 0
	ret 	L
	mov 	R0, 123
	ret 	LEG

start:
	cal 	LEG proc

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt 	LEG

