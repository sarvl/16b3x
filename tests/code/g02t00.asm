#test designed to test whether memory read/write works
#failure here if previous tests work indicates that either read doesnt work or oooe/pipeline implementation is wrong

	mov 	R0, 100
	mov 	R1, 104

	wrm 	R0, 100
	wrm 	R1, 104 

	rdm 	R5, 100
	rdm 	R6, 104 

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
