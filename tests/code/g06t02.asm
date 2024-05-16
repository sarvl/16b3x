;implementation of quicksort, tests performance on largeish data sets 

@def COUNT 45
@def ARR_H 0x5
@def ARR_L 0x0

	jmp 	start

[ALIGN 2]
;num in R0
xorshift:
	;x ^= x << 7
	mov 	R1, R0 
	sll 	R1, 7
	xor 	R0, R1

	;x ^= x >> 9
	mov 	R1, R0 
	slr 	R1, 9
	xor 	R0, R1

	;x ^= x << 8
	mov 	R1, R0 
	sll 	R1, 8
	xor 	R0, R1

	ret

[ALIGN 2]
@macro PTR_START
	R0
@end
@macro PTR_END
	R1
@end
@macro PIVOT 
	R2
@end
@macro PTR_GREAT 
	R3
@end
;R0 contains starting      addr
;R1 contains end INCLUSIVE addr 
partition:
	rdx 	R7, LR
	psh 	R7

	;pointer for greater element
	mov 	@PTR_GREAT, @PTR_START 
	sub 	@PTR_GREAT, 2

	rdm	 	@PIVOT, @PTR_END

	cmp 	@PTR_START, @PTR_END
	jmp 	GE partition_loop_end

[ALIGN 2]
partition_loop:
	rdm 	R4, @PTR_START 
	cmp 	R4, @PIVOT 
	jmp 	G partition_loop_if_skip

	add 	@PTR_GREAT, 2

	;swap
	rdm 	R5, @PTR_GREAT 
	rdm 	R6, @PTR_START
	wrm 	R5, @PTR_START
	wrm 	R6, @PTR_GREAT

partition_loop_if_skip:

	add 	@PTR_START, 2
	cmp 	@PTR_START, @PTR_END
	jmp 	L partition_loop
	
partition_loop_end:

	;return partition point
	mov 	R0, @PTR_GREAT
	add 	R0, 2

	;swap
	rdm 	R5, R0 
	rdm 	R6, @PTR_END
	wrm 	R5, @PTR_END
	wrm 	R6, R0

	pop 	R7
	wrx 	LR, R7
	ret
	

[ALIGN 2]
@macro QSORT_PTR_START
	R6
@end
@macro QSORT_PTR_END
	R7
@end
@macro QSORT_PTR_PIVOT
	R0
@end
;R0 contains ptr start 
;R1 contains ptr end inclusive
qsort:
	;if elem count <= 1, end
	cmp 	R0, R1
	ret 	GE 
	
	rdx 	R7, LR
	psh 	R7

	mov 	@QSORT_PTR_START, R0
	mov 	@QSORT_PTR_END, R1 

	psh 	@QSORT_PTR_START
	psh 	@QSORT_PTR_END
	cal 	partition
	pop 	@QSORT_PTR_END
	pop 	@QSORT_PTR_START

	psh 	@QSORT_PTR_PIVOT
	psh 	@QSORT_PTR_START
	psh 	@QSORT_PTR_END

	mov 	R1, @QSORT_PTR_PIVOT
	sub 	R1, 2
	mov 	R0, @QSORT_PTR_START
	cal 	qsort

	pop 	@QSORT_PTR_END
	pop 	@QSORT_PTR_START
	pop 	@QSORT_PTR_PIVOT

	mov 	R0, @QSORT_PTR_PIVOT
	add 	R0, 2
	mov 	R1, @QSORT_PTR_END
	cal 	qsort

	pop 	R7
	wrx 	LR, R7
	ret

[ALIGN 2]
start:
	;load arr start to R6
	wrx 	UI, ARR_H 
	mov 	R6, ARR_L 

	;load element count to R7
	mov 	R7, COUNT 
	;get starting xorshift val to R0
	mov 	R0, 42 

populate_arr:
	cal  	xorshift
	;make sure value is unsigned
 	slr 	R0, 1
	wrm 	R0, R6
	add 	R6, 2
	sub 	R7, 1
	jmp 	G, populate_arr

	;load arr start to R0
	wrx 	UI, ARR_H 
	mov 	R0, ARR_L 

	;load end inclusive to R1
	mov 	R1, COUNT 
	sll 	R1, 1
	add 	R1, R0
	sub 	R1, 2

	cal 	qsort

	hlt
	
	
