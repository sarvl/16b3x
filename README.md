# 16 bit CPU made entirely in vhdl 

## CPU Features
- pipelining
- cache
- superscalar execution
- oooe execution 

## Project Structure
simple, cache and pipelined implementation are working without meaningful bugs, some subtle problems may occur
additionaly due to how project is organized, it is possible to use cache with simple and pipelined implementation 

OOOE and superscalar are tied together and cant be used with pipeline nor cache
additionaly their implementation is not perfect, contains few known bugs that are not severe enough to fix them right now
both of these problems will be fixed near the end of august

## Runing The CPU
refer to Makefile for commands and help

## ISA
refer to instruction_set.txt

## Assembler
the code is not satisfying but it works 
compilation
```
g++ -std=c++23 -o asm assembly.cpp
```
usage
```
./asm assembly_file.asm
```
this will produce `out.bin` and `debug.txt` 
`out.bin` consists of instructions encoded in hexadecimal, because its easier to paste to vhdl
`debug.txt` consists of additional debug info for program, used by simulator

## Simulator
the code is kind of okay but it works 
compilation
```
g++ -std=c++23 -o sim simulator.cpp
```
usage
```
./sim MODE out.bin debug.txt
```
where `out.bin` and `debug.txt` are output of assembler 
where `debug.txt` is optional
MODE is one of these
- `n` no additional output
- `d` debug, single stepping
- `v` verbose output what is going on
- `a` debug and verbose

## Some Showcase

### Cache Speedup
this image contains instructions executed when cache and waiting for memory enabled
by arbitrary decision cache is 10x faster than CPU
when clock signal is denser that means that instructions or data are in cache and CPU doesnt have to wait for RAM 
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/ed061dde-7528-46f1-8f3b-18533318eef4)


### Superscalar Execution
this image shows that more than one instruction is executing at once (two different `instr` signals)
additionaly it features a buffer for waiting instructions and whether each instruction in the buffer depends on another
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/53f97dfb-ae1e-4899-b839-0e625e2093d5)


