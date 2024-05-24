@macro bne(x, y, z)
	cmp 	_x, _y
	jmp 	LG, _z
@end


@macro halt
	hlt 	LEG
@end

@def count 10

@macro zero
	0
@end

@macro add_one(x) 
	{_x 1 +}
@end

	mov 	R0, 0
	mov 	R1, 1
	mov 	R2, 1
	mov 	R3, 2
	mov 	R4, 3
	mov 	R5, 5
	mov 	R6, 8
	mov 	R7, 13
	@registers_save(100)

	mov 	R0, @zero
	mov 	R1, count
[ALIGN 2]
	mov 	R3, 1
[ALIGN 2]
loop:
	add 	R0, 1 
	@bne(R0, R1, loop)

	psh 	R1
	@registers_restore(100)
	pop 	R1

	@halt

