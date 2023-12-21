#checks whether memory writes are properly NOT executing after the branch
#may be an issue in pipeline implementation
	mov 	R0, 9
	mov 	R1, 8

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	jmp 	end
	wrm 	R1, 114
end:
	hlt 	


