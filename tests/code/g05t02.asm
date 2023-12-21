#3x3 matrix multiplication

	jmp 	LEG, start

; takes addr in R0 
; creates matrix of the form 
; 1 2 3
; 4 5 6
; 7 8 9
createmat3x3:
	mov 	R1, 9
	add 	R0, 16
createmat3x3_loop:
	wrm 	R1, R0
	sub 	R0, 2
	sub	 	R1, 1
	jmp 	G, createmat3x3_loop

	ret 


;takes row adr of A in R0
;takes col adr of B in R1
;takes where to write in R2
;writes dot product to R2
;unrolled to improve performance
matmult3x3_rowcol:
; regular:
;
;	rdm 	R7, R0
;	rdm 	R5, R1
;	mul 	R7, R5
;	add 	R0, 2
;	add 	R1, 6
;	
;	rdm 	R4, R0
;	rdm 	R5, R1
;	mul 	R4, R5
;	add 	R7, R4
;	add 	R0, 2
;	add 	R1, 6
;	
;	rdm 	R4, R0
;	rdm 	R5, R1
;	mul 	R4, R5
;	add 	R7, R4
;
;	wrm 	R7, R2
;
;	ret
;
;reordered
	rdm 	R7, R0

	rdm 	R5, R1
	add 	R0, 2
	mul 	R7, R5
	add 	R1, 6
	
	rdm 	R4, R0
	rdm 	R5, R1
	add 	R0, 2
	mul 	R4, R5

	add 	R1, 6
	add 	R7, R4

	rdm 	R4, R0
	rdm 	R5, R1
	mul 	R4, R5
	add 	R7, R4

	wrm 	R7, R2

	ret


;takes mat0adr in R0
;takes mat1adr in R1
;takes mat2adr in R2

;calculates R0*R1 and puts result in R2 
matmult3x3:
	rdx 	R7, LR
	psh 	R7

;precompute starting addresses
	wrm 	R1, 200
	add 	R1, 2
	wrm 	R1, 202
	add 	R1, 2
	wrm 	R1, 204

	mov 	R6, 3
matmult3x3_loop_outer:
	wrm 	R0, 254

;unrolled loop
	rdm 	R1, 200
	;R0 already what is should be
	cal 	matmult3x3_rowcol
	add 	R2, 2
	
	rdm 	R0, 254
	rdm 	R1, 202
	cal 	matmult3x3_rowcol
	add 	R2, 2
	
	rdm 	R0, 254
	rdm 	R1, 204
	cal 	matmult3x3_rowcol
	add 	R2, 2


	rdm 	R0, 254
	add 	R0, 6
	sub 	R6, 1
	jmp 	G, matmult3x3_loop_outer


	pop 	R7
	wrx 	LR, R7
	ret


start:
	wrx 	UI, 1
	mov 	R0, 0
	cal 	LEG, createmat3x3
	wrx 	UI, 2 
	mov 	R0, 0
	cal 	LEG, createmat3x3

	
	wrx 	UI, 1
	mov 	R0, 0
	wrx 	UI, 2
	mov 	R1, 0
	wrx 	UI, 3
	mov 	R2, 0
	cal 	LEG, matmult3x3

	wrx 	UI, 3
	mov 	R7, 0
	rdm 	R0, R7
	add 	R7, 2
	rdm 	R1, R7
	add 	R7, 2
	rdm 	R2, R7
	add 	R7, 2
	rdm 	R3, R7
	add 	R7, 2
	rdm 	R4, R7
	add 	R7, 2
	rdm 	R5, R7
	add 	R7, 2
	rdm 	R6, R7
	add 	R7, 2
	rdm 	R7, R7


	hlt

