CD := '\033[0m'    #color default 
CR := '\033[0;31m' #color red
CY := '\033[0;33m' #color yellow 

FILES := out/simulator.o out/input_handle.o 
SAN := -g -fsanitize=undefined -fsanitize=address
#SAN := 

default:
	@echo -e no option specified

clean:
	@rm -frv *.o 

refresh:
	@touch src/*.cpp src/*.h

clear:
	@clear

asm: clear sim 
remake: clean refresh sim 

sim: ${FILES}
	@echo -e ${CR}linking${CD}
	@g++ ${SAN} -std=c++20 -o sim ${FILES} -Wall -Wextra -pedantic

out/simulator.o: src/simulator.cpp
	@echo -e ${CY}compiling simulator.cpp${CD}
	@g++ ${SAN} -std=c++20 -o out/simulator.o -Wall -Wextra -pedantic -c src/simulator.cpp -Wall -Wextra -pedantic 
out/input_handle.o: src/input_handle.cpp
	@echo -e ${CY}compiling input_handle.cpp${CD}
	@g++ ${SAN} -std=c++20 -o out/input_handle.o -Wall -Wextra -pedantic -c src/input_handle.cpp -Wall -Wextra -pedantic
	
src/simulator.cpp:
	@touch src/simulator.cpp
src/input_handle.cpp:
	@touch src/input_handle.cpp
