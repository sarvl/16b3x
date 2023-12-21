#check whether cache properly differentiates tags 
#and whether data does not get overwritten while in cache
#not sure how to differentiate this two cases without relying on mem content which may be ZZZZ or 0000
	
	mov 	R0, 1
	mov 	R1, 2
	
#2MSb are def in same set
	wrx 	UI, 0x80
	wrm 	R0, 0x00

	wrx 	UI, 0x90
	wrm 	R1, 0x00

	wrx 	UI, 0x80
	rdm 	R2, 0x00

	wrx 	UI, 0x90
	rdm 	R3, 0x00

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt
