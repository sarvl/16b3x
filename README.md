# 16 bit CPU made entirely in vhdl 

## CPU Features
- pipelining
- cache
- superscalar execution
- oooe execution 

## Project Structure
simple, cache and pipelined implementation are working without meaningful bugs, some subtle problems may occur
additionaly due to how project is organized, simple, cache and pipeline can all be used selectively, that is, it is possible to have simple with cache, or pipeline with cache

OOOE and superscalar unfortunately are tied together and cant be used with pipeline nor cache, this will change in the future but not near future
also i am absolutely not sure about quality of implementation, it can multiply matrixes but at least one bug does exist 

## Runing The CPU
refer to Makefile for commands

## ISA
refer to instruction_set.txt

## Assembler
the code is not satisfying but it works 
simply compile with `g++` (may require newer standard of c++)
then use `./asm assembly_file.asm` 
this will produce `out.bin` and `debug.txt` 
`out.bin` consists of instructions encoded in hexadecimal, because its easier to paste to vhdl
`debug.txt` consists of additional debug info for program, used by simulator

## Simulator
the code is kind of okay but it works 
simply compile with `g++` (may require newer standard of c++)
then use `out.bin` from assembler
command format is 
```
./sim MODE out.bin debug.txt
```
where `debug.txt` is optional
MODE is one of these
- `n` no additional output
- `d` debug, single stepping
- `v` verbose output what is going on
- `a` debug and verbose

## Some Showcase

### Cache Speedup
this image contains instructions executed with cache and waiting for memory enabled
by arbitrary decision cache is 10x faster than CPU
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/ed061dde-7528-46f1-8f3b-18533318eef4)


### Superscalar Execution
this image shows that more than one instruction are executing at once
additionaly it features a buffer that changes with time and whether each instruction in the buffer depends on another
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/53f97dfb-ae1e-4899-b839-0e625e2093d5)


