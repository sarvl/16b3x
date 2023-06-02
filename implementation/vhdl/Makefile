CD := '\033[0m'    #color default 
CR := '\033[0;31m' #color red
CY := '\033[0;33m' #color yellow 

default:
	@echo -e no option specified

clean:
	@rm -frv *.o computer work-obj08.cf wave.ghw

refresh:
	@touch *.vhdl

clear:
	@clear

simple: clear analyse_simple elaborate
cache: clear analyse_cache elaborate
remake_simple: clear refresh simple
remake_cache: clear refresh cache 

run: clear
	@echo -e ${CR}running simulation${CD}
	@ghdl -r computer --wave=wave.ghw --stop-time=10000ns

elaborate:
	@echo -e ${CR}elaborating${CD}
	@ghdl -e --std=08 computer


analyse_simple: alu.o registers.o ram.o control.o computer_simple.o 
analyse_cache: alu.o registers.o ram_cache.o control.o computer_simple.o 
	
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

