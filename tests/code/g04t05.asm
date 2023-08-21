#this code tests whether IP is really read and writtern properly
#failure indicates invalid read after write 

	wrx 	IP, start
	hlt 
start:
	rdx 	R0, IP


	wrx 	IP, test
test:
	rdx 	R1, IP

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt
