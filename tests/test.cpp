#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <string>

using namespace std::literals;

#define PAD_ZERO(x, y) std::setfill('0') << std::setw(x) << (y) 

std::string slurp(std::ifstream& in) {
    std::ostringstream sstr;
    sstr << in.rdbuf();
    return sstr.str();
}

int main(int argc, char* argv[])
{
	bool test_simulator = false;
	test_simulator = argc > 1 && argv[1][0] == 's';

	std::string commands[] = {
		"cp ./tests/bin/g00t00.bin ./implementation/vhdl/input_prog.bin",
		"cd ./implementation/vhdl/ ; ghdl -r computer --stop-time=4000ns 1>/dev/null",
		"mv ./implementation/vhdl/dump.txt ./",
		"rm -f ./dump.txt",
		"mv ./dump.txt ./failed_g00t00.out"
		};
	
	if(test_simulator)
	{
		commands[0] = "cp ./tests/bin/g00t00.bin ./out.bin";
		commands[1] = "./sim out.bin -l -m";
		commands[2] = "";
		//command[3] unmodified
	}

	std::string correct_file = "./tests/out/g00t00.out";
	std::string group_name;
	std::string num; 

	std::ifstream correct;
	std::ifstream tested;
	std::ifstream groups("./tests/groups.txt");
	int group = 0;
	while(std::getline(groups, group_name))
	{
		std::cout << "\033[1;38;5;55m" << group_name << "\033[0m\n";
		std::getline(groups, num);
		//quick stoi	
		int max;
		if(2 == num.size())
			max = (num[0] - '0') * 10 + num[1] - '0';
		else
			max = num[0] - '0';
		
		for(int i = 0; i < max; /*see end of loop*/)
		{
			system(commands[0].c_str());
			system(commands[1].c_str());
			system(commands[2].c_str());
	
			tested.open("./dump.txt");
			correct.open(correct_file);
			
			if(slurp(tested) != slurp(correct))
			{
				commands[4][24] = correct_file[13];
				commands[4][25] = correct_file[14];
				commands[4][27] = correct_file[16];
				commands[4][28] = correct_file[17];

				std::cout << "\033[1;38;5;1m[X] TEST g" << PAD_ZERO(2, group) << "t" << PAD_ZERO(2, i) << " FAILED\033[0m\n";
				system(commands[4].c_str());
			}
			else
			{
				std::cout << "\033[1;38;5;46m[V] TEST g"<< PAD_ZERO(2, group) << "t" << PAD_ZERO(2, i) << " PASSED\033[0m\n";
				system(commands[3].c_str());
			}
	
			tested.close();
			correct.close();
			
			i++;
			correct_file[17] = i + '0';
			commands[0][20] = i + '0';
	
			if(0 == i % 10)
			{
				correct_file[17] = '0';
				commands[0][20] = '0';
				
				correct_file[16]++;
				commands[0][19]++;
			}
		}

		commands[0][19] = '0';
		commands[0][20] = '0';
		correct_file[16] = '0';
		correct_file[17] = '0';

		group++;
		correct_file[14]++;
		commands[0][17]++;

		if(0 == group % 10)
		{
			correct_file[14] = '0';
			commands[0][17] = '0';
			
			correct_file[13]++;
			commands[0][16]++;

		}
	}

}
