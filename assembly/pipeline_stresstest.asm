	mov 	R0, 5
	mov 	R1, R0
	sll 	R0, 2
	wrx 	UI, 1
	mov 	R2, 0
	slr 	R2, 7
loop:
	add 	R0, 1
	mul 	R0, R0
	sub 	R2, 1
	jmp 	EG, loop
	wrx 	UI, 1
	rdx 	R4, UI
	wrx 	LR, end
	ret
end2:
	mov 	R5, 9
	mul 	R5, 4
	wrm 	R5, 100
	rdm 	R6, 100
	xor 	R5, R5
	wrx 	IP, halt
end:
	cal 	LEG, end2
halt:
	hlt
