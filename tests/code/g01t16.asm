#detects whether NT jmp + T jmp are fetched properly 

#first make sure branch predictor really thinks that branch is not taken 
	mov 	R0, 0
	mov 	R1, 10

skew:
	cmp 	R0, 0
#16k + 3
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
#16k
	jmp 	G, fake
	jmp 	G, fake
	jmp 	G, fake
#16k + 3
	sub 	R1, 1
#predict taken jmp is at 16k + 4
#so it has to be avoided but that is not a problem
	jmp 	G skew
#align as well as do a comparison
	cmp 	R0, 0

	#NT, correctly
	jmp 	G, fake 
	jmp 	E, avoid_bad

	wrx 	UI, 0xBE
	mov 	R3, 0xEF
avoid_bad:
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt


fake:
#just so waveform looks nicer
	nop 	
	nop 	
	nop 	
	nop 	
	nop 	
	nop 	
	nop 	
