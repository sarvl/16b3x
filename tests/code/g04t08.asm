#this tests detects problem with forwarding that may occur due to memory operations

	mov 	R0, 1
	mov 	R1, 2

	wrx 	UI, 0x5
	wrm 	R0, 0
	wrx 	UI, 0x6
	wrm 	R1, 0

	wrx 	UI, 0x5
	rdm 	R2, 0
	wrx 	UI, 0x6
	rdm 	R3, 0

	wrx 	UI, 0x7
	wrm 	R3, 0
	wrx 	UI, 0x8
	rdx 	R5, UI

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
