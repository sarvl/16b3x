#exactly the same as g01t00 except no TST at the beggining
#failure here without failure in g01t00 almost surely indicates wrong initialization of FLAGS register

	jmp 	start
	mov 	R0, 123
mid:
	jmp 	end
	mov 	R1, 45
start:
	jmp 	mid
	mov 	R2, 67
end:
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt 	
