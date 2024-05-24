# 16 bit RTL implementation of CPU in vhdl 
this document is shortened and adapted version of https://sarvel.xyz/Projects/p16b3x 

## Overview:
current CPU is very aggressive in extracting performance from every program by implementing:
- Out Of Order Execution
- Superscalar Execution
- Branch Prediction
- Instruction Elimination
- Register Renaming
- Physical Register Sharing
- Load Store Queue
- Internal Caches

speedup of around 1.4 is easily achievable for most programs without particular optimizations
with optimizations 1.85 speedup has been achieved, making me think that with extreme care, 2x might be possible or is just slightly out of reach

entire project implements also:
assembler with support for macros that greatly simplify any bigger project
simulator in c++ that checks logic of programs and generates some useful performance info
test framework to make sure everything really works

unfortunately the project does not concern itself with memory too much and the main CPU does not interface out of the box with any of the caches

while there still are interesting things that could be done it is much more interesting to work on something that can be executed on real HW  
so this is this project won't receive any further updates

only newer implementation (`vhdl_v2`) is described, old (`vhdl`) is in older revisions of readme  
(older OOE one still does not work though, and never will, some stuff may be broken due to me pushing old changes)   


## Performance

[quicksort](https://github.com/sarvl/16bit_cpu/blob/main/tests/code/g05t07.asm):  
  instructions: 1437        
  simple      : 1809 cycles  
  OOE         : 1272 cycles 

  IPC         :  1.13       
  simple/OOE  :  0.70       

[matrix multiply](https://github.com/sarvl/16bit_cpu/blob/main/tests/code/g05t02.asm):  
  instructions:  322        
  simple      :  437 cycles  
  OOE         :  250 cycles 

  IPC         :  1.13       
  simple/OOE  :  0.57       

[simulator](https://github.com/sarvl/16bit_cpu/blob/main/tests/code/g05t05.asm):  
  instructions: 2332        
  simple      : 2662 cycles  
  OOE         : 1570 cycles 

  IPC         :  1.49       
  simple/OOE  :  0.59       

after slight source code modifications, simulator can be run at 1441 cycles making at run at ~0.54 time of simple one with IPC ~ 1.62

## Project Structure
the main CPU  is located in `implementation/vhdl_v2/`  
assembler is  in `assembly/`  
simulator is  in `simulator/` 
tests     are in `tests/`  
  
I am not providing instructions for setting up this project because I don't see a reason to do it   
if for some reason reader wants to set it up, let me know and I can provide some instructions  

## Instructions 
```
     nop                    # ---                                                    
     hlt ccc                # IF(FL & ccc) { halt }                              
                            #                                                        
                            #                                                        
                            #                                                        
     mov     Rd, Rs/imm8    # Rd          <-- Rs/imm16                            
     rdm     Rd, Rs/imm8    # Rd          <-- M[Rs/imm16]                         
     wrm     Rd, Rs/imm8    # M[Rs/imm16] <-- Rd                                  
                            #                                                        
                            #                                                        
                            #                                                        
                            #                                                        
     rdx     Rd, Es         # Rd          <-- Es                                  
     wrx     Ed, Rs/imm8    # Ed          <-- Rs/imm16                            
     psh     Rd             # SP          <-- SP - 2 ; M[SP] <-- Rd            
     pop     Rd             # Rd          <-- M[SP]  ; SP    <-- SP + 2;       
     mul     Rd, Rs/imm8    # Rd          <-- Rd *  Rs/imm16                      
     cmp     Rd, Rs/imm8    #                 Rd -  Rs/imm16                         
                            #                                                        
     tst     Rd, Rs/imm8    #                 Rd &  Rs/imm16                     
     jmp ccc     Rs/imm8    # IF(FL & ccc) {  IP <-- Rd/imm16 }               
     cal ccc     Rs/imm8    # IF(FL & ccc) {  LR <-- IP; IP <-- Rd/imm16 } 
     ret ccc                # IF(FL & ccc) {  IP <-- LR }                     
                            #                                                        
     add     Rd, Rs/imm8    # Rd          <-- Rd +  Rs/imm16                      
     sub     Rd, Rs/imm8    # Rd          <-- Rd -  Rs/imm16                      
     not     Rd, Rs/imm8    # Rd          <--    ~  Rs/imm16                      
     and     Rd, Rs/imm8    # Rd          <-- Rd &  Rs/imm16                  
     orr     Rd, Rs/imm8    # Rd          <-- Rd |  Rs/imm16                      
     xor     Rd, Rs/imm8    # Rd          <-- Rd ^  Rs/imm16                      
     sll     Rd, Rs/imm4    # Rd          <-- Rd << Rs/imm4                 
     slr     Rd, Rs/imm4    # Rd          <-- Rd >> Rs/imm4                 
```
more details available in `instructions_set.txt` 

## Assembler
compilation
```
make link
```
usage
```
./asm assembly_file.asm
```
this produces `out.bin` and `symbols.txt`
`out.bin` consists of instructions encoded in hexadecimal, because it's easier to paste to vhdl
`symbols.txt` associates branch with address, useful for debugging

additionally assembler has support for macros which allow to significantly simpilify writing bigger programs  

The instructions are typed in lowercase letters, ccc in uppercase, registers internal and external in uppercase  
examples are available at https://sarvel.xyz/Projects/p16b3x.html#isa and https://sarvel.xyz/Projects/p16b3x.html#assembly  

## Simulator
Compilation:
```
make link
```
for options and usage use
```
./sim -h
```

as for now, the project structure to measure performance is questionable  
measuring performance of different branch predictors takes significant amount of space in handling of JMP, CAL, RET  

The most interesting option is the `-P` which outputs performance info, example output on matrix multiply (with `-b`):  
![image](https://github.com/sarvl/16bit_cpu/assets/95301979/59cb71d1-5dd0-4929-903a-89e44b0feca1)

## Tests
first, simulator must work  
then run  
```
./tests/gen
```
to test RTL simulation:  
```
./autotest
```
to test RTL simulation on groups numbered from X to Y inclusive:   
```
./autotest X Y
```
to test simulator:  
```
./autotest s
```
