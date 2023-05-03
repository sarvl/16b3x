	jmp 	LEG, start

; returns res in R0
; takes arg0 in R0
; takes arg1 in R1
; it is advised to put smaller value into R1 
mult:
	mov 	R2, 0 
	cmp 	R1, 0 
	jmp 	E, mult_end 
	
mult_loop:
	add 	R2, R0
	sub 	R1, 1
	jmp 	G, mult_loop

mult_end:
	mov 	R0, R2
	ret

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
;returns their dot product
matmult3x3_rowcol:
	rdx 	R7, LR
	psh 	R7

	mov 	R3, 3
	mov 	R7, 0
matmult3x3_rowcol_loop:
	psh 	R0
	psh 	R1
	rdm 	R0, R0
	rdm 	R1, R1
	cal 	LEG, mult
	add 	R7, R0
	pop 	R1
	pop 	R0

	add 	R0, 2
	add 	R1, 6
	sub 	R3, 1
	jmp 	G, matmult3x3_rowcol_loop

	mov 	R0, R7

	pop 	R7
	wrx 	LR, R7
	ret


;takes mat0adr in R0
;takes mat1adr in R1
;takes mat2adr in R2

;calculates R0*R1 and puts result in R2 
matmult3x3:
	rdx 	R7, LR
	psh 	R7

	mov 	R4, 3
matmult3x3_loop_outer:
	psh 	R4
	psh 	R0
	psh 	R1

	mov 	R3, 3
matmult3x3_loop:
	psh 	R3
	psh 	R0
	psh 	R1
	psh 	R2
	cal 	LEG, matmult3x3_rowcol
	pop 	R2
	wrm 	R0, R2
	add 	R2, 2
	pop 	R1
	add 	R1, 2 
	pop 	R0

	pop 	R3
	sub 	R3, 1
	jmp 	G, matmult3x3_loop

	pop 	R1
	pop 	R0
	add 	R0, 6
	pop 	R4
	sub 	R4, 1
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

