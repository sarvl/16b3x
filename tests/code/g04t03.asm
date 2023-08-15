#test of FL register
#failure inticates wrong implementation

t0:
	wrx 	FL, 1 
	jmp 	L lo
	jmp 	G go
	mov 	R0, 3
t1:
	wrx 	FL, 2 
	jmp 	L lt
	jmp 	G gt
	mov 	R1, 3
t2:
	wrx 	FL, 4 
	jmp 	L lf
	jmp 	G lf
	mov 	R2, 3
t3:

	rdx 	R5, FL

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt


lo:
	mov 	R0, 1
	jmp 	LEG, t1
go:
	mov 	R0, 2
	jmp 	LEG, t1
lt:
	mov 	R1, 1
	jmp 	LEG, t2
gt:
	mov 	R1, 2
	jmp 	LEG, t2
lf:
	mov 	R2, 1
	jmp 	LEG, t3
gf:
	mov 	R2, 2
	jmp 	LEG, t3
