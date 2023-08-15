#test of LR register
#failure indicates wrong implementation 

	jmp 	LEG start
proc:
	mov 	R0, 100
	mov 	R1, 101
	ret

proct:
	mov 	R4, 104
	wrx 	LR, end
	mov 	R5, 105
	mov 	R6, 106
	mov 	R7, 107
	ret

procx:
	mov 	R6, 1
	mov 	R7, 2
	rdx 	R5, LR
	jmp 	LEG R5

start:
	mov 	R2, 102
	cal 	LEG proc
	mov 	R3, 103
	cal 	LEG proct
	mov 	R0, 0
	mov 	R1, 0
	mov 	R2, 0
	mov 	R3, 0
	mov 	R4, 0
	mov 	R5, 0
	mov 	R6, 0
	mov 	R7, 0
end:
	cal 	LEG procx

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114
	hlt
	
