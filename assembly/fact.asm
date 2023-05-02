	jmp 	LEG, start

; returns res in R0
; takes arg0 in R0
; takes arg1 in R1
; it is advised to put smaller value into R1 

;x0001
mult:
	cmp 	R1, 0 
	jmp 	LG, mult_count
	
	mov 	R0, 0
	jmp 	LEG, mult_end

mult_count:
	mov 	R2, R0 

	sub 	R1, 1
mult_loop:
	add 	R0, R2

	sub 	R1, 1
	jmp 	G, mult_loop

mult_end:
	ret

; returns factorial in R0
; takes n in R0

;x000B
fact:
	rdx 	R7, LR
	psh 	R7


	cmp 	R0, 1
	jmp 	LE, fact_ret

	psh 	R0
	sub 	R0, 1
	cal 	GE, fact
	
	pop 	R1
	; R0 = fact(n - 1)
	; R1 = n 
	cal 	LEG, mult
	jmp 	LEG, fact_end

fact_ret:
	mov 	R0, 1
fact_end:
; link register
	pop 	R7
	wrx 	LR, R7
	ret

;x0019
start:
	mov 	R0, 6
	cal 	LEG fact


	wrm 	R0, 80
	hlt
	
