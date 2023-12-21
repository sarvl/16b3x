#check whether data gets properly arbitrated when writeback writes evicted AND wants to store read

	mov 	R0, 1
	mov 	R1, 2
	mov 	R2, 4
	mov 	R3, 8

	wrx 	UI, 0x80
	wrm 	R0, 0x00
	wrx 	UI, 0x90
	wrm 	R1, 0x00

	wrx 	UI, 0x80
	wrm 	R0, 0x00
	wrx 	UI, 0x90
	rdm 	R5, 0x00


	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt

