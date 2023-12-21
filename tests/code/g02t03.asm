#program designed to test cache correctness by writing to addr with same index but different tag 
#in total 12 cache misses should be generated in writeback cache
#         11                                  in writethrough cache

# out of this file make several test groups to test cache behavior 
# following problems may occur:
#	does not properly differentiate tag
#	data gets overwritten while in cache (wrong eviction, only in writeback)
#   data does not get properly arbitrated when writeback writes evicted AND wants to store read
#
# these ones may occur but they usually have to be detected manually 
#  or maybe with added perf counters but are highly dependent on initial configuration of cache
# cache misses are not properly aligned to instr that caused them 
# 

	mov 	R0, 1
	mov 	R1, 2
	mov 	R2, 3
	mov 	R3, 4

	wrx 	UI, 0x5
#cache miss because of evicting last value 
	wrm 	R0, 0

	wrx 	UI, 0x5
#cache hit but write different value so if cache does not properly update memory, it may break 
#however in writeback cache this should not generate a miss
	wrm 	R1, 0

	wrx 	UI, 0x6
#cache miss
#in writeback it should write data
	wrm 	R1, 0
	wrx 	UI, 0x7
#cache miss
#in writeback it should write data
	wrm 	R2, 0
	wrx 	UI, 0x8
#cache miss
#in writeback it should write data
	wrm 	R3, 0

	wrx 	UI, 0x5
#cache miss
#in writeback this should generate double miss
#one for write old and one for read R4
	rdm 	R4, 0
	wrx 	UI, 0x6
#cache miss
#single, only read
	rdm 	R5, 0
	wrx 	UI, 0x7
#cache miss
#single, only read
	rdm 	R6, 0
	wrx 	UI, 0x8
#cache miss
#single, only read
	rdm 	R7, 0

#now evict next instruction, marked with label
#single, only read
	wrx 	UI, 0x5
#cache miss
#evict instruction 
#(that actually depends on how the stuff is inited)
	wrm 	R4, {evict 2 *}

evict:
#cache miss
#double in writeback
#write prev and read instr
	mov 	R0, 0x96

	wrm 	R0, 100
	wrm 	R1, 102
	wrm 	R2, 104
	wrm 	R3, 106
	wrm 	R4, 108
	wrm 	R5, 110
	wrm 	R6, 112
	wrm 	R7, 114

	hlt 	

