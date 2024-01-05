#test whether BP can properly predict alternating branches

start:
	mov 	R0, 0
	nop
	
	wrx 	UI, 0x1
	mov 	R1,   0 

loop:
	#alternates
	tst 	R1, 1
	jmp 	LG skip
	add 	R0, 1
skip:
	sub 	R1, 1
	#always taken
	jmp 	GE loop
	
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
