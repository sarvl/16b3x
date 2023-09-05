# 16 bit CPU made entirely in vhdl 

## Description:
for showcase see bottom of this README

This CPU has 3 implementations (4 counting the simulator) of custom ISA defined in instruction_set.txt
1. simple in order, subscalar implementation computer_simple.vhdl
2. relatively simple in order, subscalar but pipelined implementation computer_pipeline.vhdl
3. much more complicated but still not finished out of order, superscalar execution computer_oooe.vhdl

There is also cache (ram_cache.vhdl) which is plug in replacement for regular ram (ram.vhdl)  
Ram also has ram_tests.vhdl which is used to load data from file and outputs memdump when cpu sets halt signal 

Both simple and pipelined implementation work on all current test programs in `tests/code/`

There is not a lot to say about simple implemntation, it is very simple and the code is very short

Pipelined implementation is more interesting but has a major flaw   
The pipeline has 4 stages:
- fetch  
- decode  
- execute/mem/ext_reg_write  
- writeback  

It is similar to classic risc pipeline but the execute/mem stage are merged since there is no instruction that passes through both of them  
Unfortunately a lot of cycles are wasted on each taken branch, because there is no dynamic branch predictor which causes major slowdown in total, see showcase, this is the only reason that pipeline may stall, other hazards are solved by bypassing or do not exist 
	
OOOE implementation has the most features and is the most complicated 
it does not work fully yet but it will work, and the code is very terrible right now, will change that 
- 8 slot ROB that acts as unified RS for 2 arithmetic execution units  
- 2 wide fetch/decode
- 2 wide execution
- 2 wide commit 
- 16 entries 2BC dynamic BP 

Planned to be implemented
- internal cache for instructions
- LSQ 
- more sophisticated external register handling
Right now loads/stores and external registers are major problem for performance as they can only be executed during commit
- RAS  
The RAS is implemented but I dont think it works as good as it could, or even at all  


This week I must work on something different so I cannot improve/fix current implementations 

## Project Structure
For vhdl code see `implementation/vhdl/`  
For simulator see `simulator/`  
For assembler see `assembly/`  
For tests related programs and tests themselves see `tests/`  

Swapping of modules is done by commenting/uncommenting lines in Makefile
Use `make help` to find out more
ram/ram_tests/ram_cache can be used interchangeably 
computer_simple/computer_pipeline can be used interchangeably 

OOOE requiers few files to be significantly modified, they have the oooe suffix and have to be enabled 

## Running tests
First make sure that the CPU was compiled with `make tests`   
If `tests/out/` is empty, compile the simulator, then `generate.cpp` then run `./generate`  
Then run `./autotest` to test CPU or `./autotest s` to test simulator  

note that the OOO implementation does not pass all the tests

## Runing The CPU simulator in vhdl
```
make computer
make run
```
## ISA
Refer to instruction_set.txt

Generally speaking, it is pretty well organized and without major flaws   
However the idea of external registers significantly complicates especially the OOO implementaion  
I am not sure whether thats the best solution to the problem of not having enough registers that should be modifiable like stack pointer 

## Assembler
compilation
```
make link
```
usage
```
./asm assembly_file.asm
```
this will produce `out.bin` 
`out.bin` consists of instructions encoded in hexadecimal, because its easier to paste to vhdl

During rewrite, I have completely forgot to add `debug.txt` as assembler output, I will fix it  
The attributes are parsed but do not work, I will fix it 

The instructions are typed in lowercase letters, ccc in uppercase, registers internal and external in uppercase  
The assembler has also support for macros, I'm yet to make interesting examples with them, short syntax example:
```x86asm
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
	mov 	R3, add_one(0) 
loop:
	add 	R0, 1 
	@bne(R0, R1, loop)

	@halt
```
The `{}` is syntax for expressions that are written in postfix   
`+, -, *, /, % (mod)` and binary operations can be calculated  

The assembler is not fully tested however I have not discovered a single bug in translation of instructions in all the `tests/code/` programs 

## Simulator
Compilation:
```
g++ -std=c++23 -o sim simulator.cpp input_handle.cpp
```
for options and usage use
```
./sim -h
```

as for now, the project structure to measure performance is questionable  
measuring performance of different branch predictors takes significant amount of space in handling of JMP, CAL, RET  
this will change if better solution is discovered to at least hide the repeatable code

The most interesting option is the `-p` which outputs performance info, example output on matrix multiply:
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/ff8d6292-b0f5-4bc8-9d2b-cb142680bac9)
This will be further improved during the following weeks to include much more elaborate perf info as well as info about OOO implementation  
Each implementation will have tweakable parameters to more accurately model perf of different parameters of implementation 

## Some Showcase

### Cache Speedup
this image contains instructions executed with cache and waiting for memory enabled  
by arbitrary decision cache is 10x faster than RAM, which results in 4x speedup with cache   
when clock signal is denser that means that instructions or data are in cache and CPU doesnt have to wait for RAM 
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/ed061dde-7528-46f1-8f3b-18533318eef4)

### Pipeline stalls
The stall signal when occurs, causes two instructions to become `nop` and the bubble propagates further down the pipeline  
Happens right after `jmp` signal  
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/0fa33e15-eb4f-4611-88c0-f109998f428a)


### Branch Predictor 
This image shows that whenever `mispredict` occurs the `flush` happens which causes ROB to be cleared
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/c508cc3b-4059-4ae8-9d92-ac91257a5a78)
This image shows the updating state of 16BC   
Note that they all have mostly `11` that decision was influenced by the `./sim -p` that shows >half branches are taken  
It may not be the most accurate heuristic as the simulator treated `jmp/cal/ret` as one type of branch
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/56354e4c-0f9a-4206-b138-9665b86caa08)

### OOO Execution
As stated previously in Branch Predictor, one can see flushes on each misprediction  
Additionally the state of the ROB is visible, that it includes several instructions  
The two signals that are responsible for dispatching to execution units `exe_entry` 
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/456c8eef-89e1-4a84-be1c-7652c63d6857)




