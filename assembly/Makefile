CD := '\033[0m'    #color default 
CR := '\033[0;31m' #color red
CY := '\033[0;33m' #color yellow 

FILES := out/main.o out/parse.o out/token.o out/process.o out/error.o
#SAN := -g -fsanitize=undefined -fsanitize=address 
SAN := 

default:
	@echo -e no option specified

clean:
	@rm -frv *.o 

refresh:
	@touch src/*.cpp src/*.h

clear:
	@clear

asm: clear link
remake: clean refresh asm

link: ${FILES}
	@echo -e ${CR}linking${CD}
	@g++ ${SAN} -std=c++20 -o asm ${FILES} -Wall -Wextra -pedantic

out/main.o: src/main.cpp
	@echo -e ${CY}compiling main.cpp${CD}
	@g++  ${SAN} -std=c++20 -o out/main.o -Wall -Wextra -pedantic -c src/main.cpp 
out/parse.o: src/parse.cpp
	@echo -e ${CY}compiling parse.cpp${CD}
	@g++  ${SAN} -std=c++20 -o out/parse.o -Wall -Wextra -pedantic -c src/parse.cpp
out/token.o: src/token.cpp
	@echo -e ${CY}compiling token.cpp${CD}
	@g++  ${SAN} -std=c++20 -o out/token.o -Wall -Wextra -pedantic -c src/token.cpp
out/process.o: src/process.cpp
	@echo -e ${CY}compiling process.cpp${CD}
	@g++  ${SAN} -std=c++20 -o out/process.o -Wall -Wextra -pedantic -c src/process.cpp
out/error.o: src/error.cpp
	@echo -e ${CY}compiling error.cpp${CD}
	@g++  ${SAN} -std=c++20 -o out/error.o -Wall -Wextra -pedantic -c src/error.cpp
	
src/main.cpp:
	@touch src/main.cpp
src/parse.cpp:
	@touch src/parse.cpp
src/token.cpp:
	@touch src/token.cpp
src/process.cpp:
	@touch src/process.cpp
src/error.cpp:
	@touch src/error.cpp
