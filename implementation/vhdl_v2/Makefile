CD := '\033[0m'    #color default 
CR := '\033[0;31m' #color red
CY := '\033[0;33m' #color yellow 

TYPES     := p_type
ARITH     := arith
REG       := reg
#MEM       := mem
MEM       := mem_wide
CACHE     := cache
DECODE    := decode
#CORE      := core
CORE      := core_wide_oooe
CHIP      := chip_wide_test
#CHIP      := chip_test
CHIP_TEST := ${CHIP}


WARN := -Wlibrary -Wbinding -Wport -Wreserved -Wnested-comment -Wparenthesis -Wspecs -Wport-bounds -Wruntime-error -Wunused -Wnowrite -Wothers -Wuseless
#WARN := 

FILES       := out/${TYPES}.o out/${ARITH}.o out/${REG}.o out/${MEM}.o out/${DECODE}.o out/${CORE}.o out/${CHIP}.o
FILES_TESTS := out/${TYPES}.o out/${ARITH}.o out/${REG}.o out/${MEM}.o out/${DECODE}.o out/${CORE}.o out/${CHIP_TEST}.o

UPPER_LIMIT       :=   4000ns
UPPER_LIMIT_TESTS :=  40000ns

default:
	@echo -e no option specified

help:
	@echo -e "not implemented yet"

clean:
	@rm -frv out/*.o *.o out/work-obj08.cf wave.ghw

refresh:
	@touch src/*.vhdl

clear:
	@clear

chip: clear analyse elaborate
remake: clean refresh chip 
tests: clear analyse_tests elaborate
remake_tests: clean refresh tests 

run: clear
	@echo -e ${CR}running simulation${CD}
	@ghdl -r --workdir=out --std=08 chip --wave=wave.ghw --stop-time=${UPPER_LIMIT}

test: clear
	@echo -e ${CR}running simulation${CD}
	@ghdl -r --workdir=out --std=08 chip --stop-time=${UPPER_LIMIT_TESTS}

elaborate: 
	@echo -e ${CR}elaborating${CD}
	@ghdl -e --workdir=out --std=08 ${WARN} chip 

analyse_tests: ${FILES_TESTS}
analyse: ${FILES}

out/${TYPES}.o: src/${TYPES}.vhdl
	@echo -e ${CY}analysing ${TYPES}.vhdl${CD}
	@ghdl -a --workdir=out  --std=08 ${WARN} src/${TYPES}.vhdl
src/${TYPES}.vhdl:
	@touch src/${TYPES}.vhdl

out/${ARITH}.o: src/${ARITH}.vhdl
	@echo -e ${CY}analysing ${ARITH}.vhdl${CD}
	@ghdl -a --workdir=out  --std=08 ${WARN} src/${ARITH}.vhdl
src/${ARITH}.vhdl:
	@touch src/${ARITH}.vhdl


out/${REG}.o: src/${REG}.vhdl
	@echo -e ${CY}analysing ${REG}.vhdl${CD}
	@ghdl -a --workdir=out  --std=08 ${WARN} src/${REG}.vhdl
src/${REG}.vhdl:
	@touch src/${REG}.vhdl


out/${MEM}.o: src/${MEM}.vhdl
	@echo -e ${CY}analysing ${MEM}.vhdl${CD}
	@ghdl -a --workdir=out  --std=08 ${WARN} src/${MEM}.vhdl
src/${MEM}.vhdl:
	@touch src/${MEM}.vhdl


out/${DECODE}.o: src/${DECODE}.vhdl
	@echo -e ${CY}analysing ${DECODE}.vhdl${CD}
	@ghdl -a --workdir=out  --std=08 ${WARN} src/${DECODE}.vhdl
src/${DECODE}.vhdl:
	@touch src/${DECODE}.vhdl


out/${CORE}.o: src/${CORE}.vhdl
	@echo -e ${CY}analysing ${CORE}.vhdl${CD}
	@ghdl -a --workdir=out  --std=08 ${WARN} src/${CORE}.vhdl
src/${CORE}.vhdl:
	@touch src/${CORE}.vhdl


out/${CHIP}.o: src/${CHIP}.vhdl
	@echo -e ${CY}analysing ${CHIP}.vhdl${CD}
	@ghdl -a --workdir=out  --std=08 ${WARN} src/${CHIP}.vhdl
src/${CHIP}.vhdl:
	@touch src/${CHIP}.vhdl


out/${CHIP_TESTS}.o: src/${CHIP_TESTS}.vhdl
	@echo -e ${CY}analysing ${CHIP_TESTS}.vhdl${CD}
	@ghdl -a --workdir=out  --std=08 ${WARN} src/${CHIP_TESTS}.vhdl
src/${CHIP_TESTS}.vhdl:
	@touch src/${CHIP_TESTS}.vhdl



out/${CACHE}.o: src/${CACHE}.vhdl
	@echo -e ${CY}analysing ${CACHE}.vhdl${CD}
	@ghdl -a --workdir=out  --std=08 ${WARN} src/${CACHE}.vhdl
src/${CACHE}.vhdl:
	@touch src/${CACHE}.vhdl
