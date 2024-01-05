#this code is indented to make sure that branch predictor correctly predicts 2 branches, one T one NT 

start:
	mov 	R0, 0
	nop
	
	wrx 	UI, 0x1
	mov 	R1,   0 

loop:
	#always not taken
	cmp 	R1, 0
	jmp 	E skip

	add 	R0, 1

	sub 	R1, 1
	#always taken
	jmp 	GE loop
skip:
	
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
