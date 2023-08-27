#basic test of alu and jumps
#failure indicates either not working

	mov 	R0, 123
	mov 	R1, 72
	mov 	R3, 10
	nop
start:
	add 	R0, 41
	xor 	R0, R1
	sll 	R0, 5
	xor 	R1, R0
	sub 	R3, 1

	jmp 	G, start
	hlt
