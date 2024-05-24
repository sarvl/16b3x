
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

	mov 	R0, @zero
	mov 	R1, count
loop:
	add 	R0, 0 
	@bne(R0, R1, loop)

	@halt

