#test of ip register
#failrue indicates wrong implementation

	wrx 	IP, start


	mov 	R0, 123
start:
	rdx 	R7, IP
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt
