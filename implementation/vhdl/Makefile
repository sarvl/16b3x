CD := '\033[0m'    #color default 
CR := '\033[0;31m' #color red
CY := '\033[0;33m' #color yellow 

ALU  := alu
REGS := registers
RAM  := ram
#RAM  := ram_cache
CTRL := control
CPU  := computer_simple
#CPU  := computer_pipeline

FILES := ${ALU}.o ${RAM}.o ${CTRL}.o ${REGS}.o  ${CPU}.o 

UPPER_LIMIT := 2000ns

default:
	@echo -e no option specified

help:
	@echo -e "by default makefile is set so that simplest possible implementation runs"
	@echo -e "\tif it is not, then it is a mistake, report it"
	@echo -e "\n"
	@echo -e "each component must provide interface"
	@echo -e "\tso to change what component is used, the file must be changed"
	@echo -e "\tfile names MUST NOT have additional whitespace characters, IT WILL BREAK"
	@echo -e "\tthere are several replacement files implementing features provided here"
	@echo -e "\tto use one, one of the lines at the top of the Makefile should be uncommented (and the currently used one commented)"
	@echo -e "\teg to use ram with cache, \`RAM := ram\` should be uncommented and \`RAM := ram_cache\` should be commented"
	@echo -e "\n"
	@echo -e "remember to use \`clean\` or \`remake\` after"

clean:
	@rm -frv *.o computer work-obj08.cf wave.ghw

refresh:
	@touch *.vhdl

clear:
	@clear

computer: clear analyse elaborate
remake: clean refresh computer

run: clear
	@echo -e ${CR}running simulation${CD}
	@ghdl -r computer --wave=wave.ghw --stop-time=${UPPER_LIMIT}

elaborate:
	@echo -e ${CR}elaborating${CD}
	@ghdl -e --std=08 computer

analyse: ${FILES}

alu.o: alu.vhdl
	@echo -e ${CY}analysing alu.vhdl${CD}
	@ghdl -a --std=08 alu.vhdl

registers.o: registers.vhdl
	@echo -e ${CY}analysing registers.vhdl${CD}
	@ghdl -a --std=08 registers.vhdl

ram.o: ram.vhdl
	@echo -e ${CY}analysing ram.vhdl${CD}
	@ghdl -a --std=08 ram.vhdl

ram_cache.o: ram_cache.vhdl
	@echo -e ${CY}analysing ram_cache.vhdl${CD}
	@ghdl -a --std=08 ram_cache.vhdl

control.o: control.vhdl
	@echo -e ${CY}analysing control.vhdl${CD}
	@ghdl -a --std=08 control.vhdl

computer_simple.o: control.o computer_simple.vhdl
	@echo -e ${CY}analysing computer_simple.vhdl${CD}
	@ghdl -a --std=08 computer_simple.vhdl

computer_pipeline.o: control.o computer_pipeline.vhdl
	@echo -e ${CY}analysing computer_pipeline.vhdl${CD}
	@ghdl -a --std=08 computer_pipeline.vhdl
	
alu.vhdl:
	@touch alu.vhdl
registers.vhdl:
	@touch registers.vhdl
ram_cache.vhdl:
	@touch ram_cache.vhdl
ram.vhdl:
	@touch ram.vhdl
control.vhdl:
	@touch control.vhdl
computer_simple.vhdl:
	@touch computer_simple.vhdl
computer_pipeline.vhdl:
	@touch computer_pipeline.vhdl

