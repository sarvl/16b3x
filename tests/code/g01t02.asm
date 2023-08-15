#test whether condition flags are set correctly
#wrong result indicates that some part of flag setting/reading doesnt work

	cmp 	R0, 0
	jmp 	G g
	jmp 	E e
l:
	mov 	R0, 1
	mov 	R1, 2
e:
	mov 	R2, 3
	mov 	R3, 4
g:
	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt 	LEG
