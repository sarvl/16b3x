CD := '\033[0m'    #color default 
CR := '\033[0;31m' #color red
CY := '\033[0;33m' #color yellow 

ALU  := alu
#REGS := registers
REGS := registers_oooe
RAM  := ram
#RAM  := ram_cache
CTRL := control
#CPU  := computer_simple
#CPU  := computer_pipeline
CPU  := computer_oooe

WARN := -Wlibrary -Wbinding -Wport -Wreserved -Wnested-comment -Wparenthesis -Wspecs -Wport-bounds -Wruntime-error -Wunused -Wnowrite -Wothers -Wuseless
#WARN := 

FILES       := out/${ALU}.o out/${RAM}.o out/${CTRL}.o out/${REGS}.o  out/${CPU}.o 
FILES_TESTS := out/${ALU}.o out/ram_tests.o out/${CTRL}.o out/${REGS}.o  out/${CPU}.o 

UPPER_LIMIT       := 1000ns
UPPER_LIMIT_TESTS := 10000ns

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
	@rm -frv out/*.o *.o computer out/work-obj08.cf wave.ghw

refresh:
	@touch src/*.vhdl

clear:
	@clear

computer: clear analyse elaborate
remake: clean refresh computer
tests: clear analyse_tests elaborate
remake_tests: clean refresh tests 

run: clear
	@echo -e ${CR}running simulation${CD}
	@ghdl -r computer --wave=wave.ghw --stop-time=${UPPER_LIMIT}

test: clear
	@echo -e ${CR}running simulation${CD}
	@ghdl -r computer --stop-time=${UPPER_LIMIT_TESTS}

elaborate: 
	@echo -e ${CR}elaborating${CD}
	@ghdl -e --workdir=out --std=08 ${WARN} computer 

analyse_tests: ${FILES_TESTS}
analyse: ${FILES}

out/alu.o: src/alu.vhdl
	@echo -e ${CY}analysing alu.vhdl${CD}
	@ghdl -a --workdir=out  --std=08 ${WARN} src/alu.vhdl

out/registers.o: src/registers.vhdl
	@echo -e ${CY}analysing registers.vhdl${CD}
	@ghdl -a --workdir=out --std=08 ${WARN} src/registers.vhdl

out/registers_oooe.o: src/registers_oooe.vhdl
	@echo -e ${CY}analysing registers_oooe.vhdl${CD}
	@ghdl -a --workdir=out --std=08 ${WARN} src/registers_oooe.vhdl

out/ram.o: src/ram.vhdl
	@echo -e ${CY}analysing ram.vhdl${CD}
	@ghdl -a --workdir=out --std=08 ${WARN} src/ram.vhdl

out/ram_cache.o: src/ram_cache.vhdl
	@echo -e ${CY}analysing ram_cache.vhdl${CD}
	@ghdl -a --workdir=out --std=08 ${WARN} src/ram_cache.vhdl

out/ram_tests.o: src/ram_tests.vhdl
	@echo -e ${CY}analysing ram_tests.vhdl${CD}
	@ghdl -a --workdir=out --std=08 ${WARN} src/ram_tests.vhdl

out/control.o: src/control.vhdl
	@echo -e ${CY}analysing control.vhdl${CD}
	@ghdl -a --workdir=out --std=08 ${WARN} src/control.vhdl

out/computer_simple.o: out/control.o src/computer_simple.vhdl
	@echo -e ${CY}analysing computer_simple.vhdl${CD}
	@ghdl -a --workdir=out --std=08 ${WARN} src/computer_simple.vhdl

out/computer_pipeline.o: out/control.o src/computer_pipeline.vhdl
	@echo -e ${CY}analysing computer_pipeline.vhdl${CD}
	@ghdl -a --workdir=out --std=08 ${WARN} src/computer_pipeline.vhdl

out/computer_oooe.o: out/control.o src/computer_oooe.vhdl
	@echo -e ${CY}analysing computer_oooe.vhdl${CD}
	@ghdl -a --workdir=out --std=08 ${WARN} src/computer_oooe.vhdl
	
src/alu.vhdl:
	@touch src/alu.vhdl
src/registers.vhdl:
	@touch src/registers.vhdl
src/registers_oooe.vhdl:
	@touch src/registers_oooe.vhdl
src/ram.vhdl:
	@touch src/ram.vhdl
src/ram_cache.vhdl:
	@touch src/ram_cache.vhdl
src/ram_tests.vhdl:
	@touch src/ram_tests.vhdl
src/control.vhdl:
	@touch src/control.vhdl
src/computer_simple.vhdl:
	@touch src/computer_simple.vhdl
src/computer_pipeline.vhdl:
	@touch src/computer_pipeline.vhdl
src/computer_oooe.vhdl:
	@touch src/computer_oooe.vhdl

