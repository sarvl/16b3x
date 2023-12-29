#this code tests what happens when jump  goes directly between wrx and use of imm
#mainly to make sure arch is not cheating by merging all wrx and suceeding use


	mov 	R0, 0
	mov 	R1, 1

	wrx 	UI, 0xFF
lp:
	add 	R0, 3

	sub 	R1, 1
	jmp 	GE lp 

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
