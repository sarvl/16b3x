@macro registers_save(x)
	wrm 	R0, {_x  0 +}
	wrm 	R1, {_x  2 +}
	wrm 	R2, {_x  4 +}
	wrm 	R3, {_x  6 +}
	wrm 	R4, {_x  8 +}
	wrm 	R5, {_x 10 +}
	wrm 	R6, {_x 12 +}
	wrm 	R7, {_x 14 +}
@end

@macro registers_restore(x)
	rdm 	R0, {_x  0 +}
	rdm 	R1, {_x  2 +}
	rdm 	R2, {_x  4 +}
	rdm 	R3, {_x  6 +}
	rdm 	R4, {_x  8 +}
	rdm 	R5, {_x 10 +}
	rdm 	R6, {_x 12 +}
	rdm 	R7, {_x 14 +}
@end

@macro registers_push
	psh 	R0
	psh 	R1
	psh 	R2
	psh 	R3
	psh 	R4
	psh 	R5
	psh 	R6
	psh 	R7
@end

@macro registers_pop
	pop 	R7
	pop 	R6
	pop 	R5
	pop 	R4
	pop 	R3
	pop 	R2
	pop 	R1
	pop 	R0
@end

@macro proc_enter
	rdx 	R7, LR
	psh 	R7
@end

@macro proc_exit
	pop 	R7
	wrx 	LR, R7
@end

