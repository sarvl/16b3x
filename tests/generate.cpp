/*
	program used to generate output data from tests/out/ 
	instead of transfering entire files
*/

#include <iostream>
#include <iomanip>
#include <fstream>
#include <sstream>
#include <string>

using namespace std::literals;

std::string slurp(std::ifstream& in) {
    std::ostringstream sstr;
    sstr << in.rdbuf();
    return sstr.str();
}

int main(int argc, char* argv[])
{
	std::string commands[] = {
		"cp ./tests/bin/g00t00.bin ./out.bin",
		"./sim out.bin -l -m",
		"mv ./dump.txt ./tests/out/g00t00.out"
		};

	std::ifstream groups("./tests/groups.txt");
	int group = 0;
	std::string num;
	while(std::getline(groups, num))
	{
		std::getline(groups, num);
		//quick stoi	
		int max;
		if(2 == num.size())
			max = (num[0] - '0') * 10 + num[1] - '0';
		else
			max = num[0] - '0';

		commands[0][19] = '0';
		commands[0][20] = '0';
		commands[2][30] = '0';
		commands[2][31] = '0';
		
		for(int i = 0; i < max; /*see end of loop*/)
		{
			system(commands[0].c_str());
			system(commands[1].c_str());
			system(commands[2].c_str());
			
			i++;
			commands[0][20]++;
			commands[2][31]++;
	
			if(0 == i % 10)
			{
				commands[0][20] = '0';
				commands[0][19]++;
				commands[2][31] = '0';
				commands[2][30]++;
			}
		}

		commands[0][20] = '0';
		commands[0][19] = '0';

		group++;
		commands[0][17]++;
		commands[2][28]++;

		if(0 == group % 10)
		{
			commands[0][17] = '0';
			commands[0][16]++;
			commands[2][28] = '0';
			commands[2][27]++;
		}
	}

}
