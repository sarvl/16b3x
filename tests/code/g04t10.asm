#this code tests long dependency chain with UI


	wrx 	UI, 1
	wrx 	UI, 2
	wrx 	UI, 3
	wrx 	UI, 4
	wrx 	UI, 5
	wrx 	UI, 6
	wrx 	UI, 7
	add 	R0, 8


	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
