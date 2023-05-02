16 bit cpu made entirely in vhdl 

details on architecture are in instruction_set.txt
note that this document is not entirely correct nor clear 
it will change as soon as I finish the coding part of this project

currently the not pipelined version seems to be finished and without major bugs 
it is capable of running ALL programs from assembly/ and produces the same result as simulator
most notably it is capable of running bubble sort 

the pipelined version mostly works although not fully
it is capable of running ALL programs from assembly/
although it is known that there are several bugs that are not yet fixed
and not every instruction is yet support (to be precise, not every external register can be accessed via rdx/wrx)

the assembler will be changed when i get back to compilers, right now dont judge
