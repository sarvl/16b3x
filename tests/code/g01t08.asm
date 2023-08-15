#this code checks whether condition codes work on cal

	jmp 	LEG, start
	
p1:
	mov 	R0, 123
	ret 	LEG
p2:
	mov 	R0, 45
	ret 	LEG

start:
	mov 	R1, 255
	cmp 	R1, 0
	cal 	LEG p1
	cal 	E p2

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt
	
