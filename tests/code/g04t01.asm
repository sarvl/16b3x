#test of SP register
#failure incidates wrong implementation

	mov 	R0, 123

	psh 	R0
	psh 	R0
	psh 	R0 

	wrx 	SP, 0
	
	mov 	R1, 42
	psh 	R1
	psh 	R1

	rdx 	R7, SP

	wrx 	SP, 0
	mov 	R2, 32
	psh 	R2

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt
