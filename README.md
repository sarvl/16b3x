16 bit cpu made entirely in vhdl 

details on architecture are in instruction_set.txt

the code and this project in general are a bit of a mess
this will change near the end of the month


simple, pipelined and version with cache seem to have no major bugs
they are capable of running all programs in assembly/ 
most notably they can sort numbers and multiply matrixes 

even though pipelined and cache are separated they can be relatively easily merged together
copy `ram.vhdl` and `cache.vhdl` into `pipeline/vhdl/` and it should work 



tu run the programs you can use ghdl and gtkwave
ive included gtkwave settings for each implementation

the assembler will be changed when i get back to compilers, right now dont judge

