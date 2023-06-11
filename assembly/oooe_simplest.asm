#this program is designed to test the simplest possible oooe 
#assumes that CPU works in certain way
#fetching two instructions at once
#and every time it SHOULD execute two instructions at once 
#because 2 fetched instructions DO NOT depend on eachother

	mov 	R0, 0
	mov 	R1, 1
	mov 	R2, 2
	mov 	R3, 3

	add 	R0, R1
	add 	R2, R3

	sub 	R1, R0
	sub 	R2, R3

	xor 	R0, R2
	xor 	R1, R3

	add 	R0, R0
	add 	R1, R1


	hlt
