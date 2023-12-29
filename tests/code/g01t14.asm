#check whether conditional indirect cal works 

	jmp 	start

proc:
	#if R1 is 123 then weve been here
	cmp 	R1, 0xBE
	jmp 	E, bad_end1
	mov 	R1, 0xBE

	cmp 	R1, 0
#not only should not jump but also should not overwrite LR 
	cal 	E, R0

#detect case when LR was overwritten and we are here again
	cmp 	R3, 0xEF
	jmp 	E, bad_end2
	mov 	R3, 0xEF

	ret 

start:
	mov 	R0, proc

	cal 	proc


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


bad_end1:
	mov 	R0, 0xDE
	jmp 	end
bad_end2:
	mov 	R0, 0xAD
	jmp 	end
