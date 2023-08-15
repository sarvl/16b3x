#this program tests whether condition codes work on HLT instruction
	
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	mov 	R0, 1
	cmp 	R0, 0
	hlt 	L #should not halt

	wrm 	R0, 100
	hlt 	LEG
