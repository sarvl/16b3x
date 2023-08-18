#include "error.h"
#include <iostream>
#include <vector>
#include <string>

bool is_error   = false;
bool is_warning = false;

extern std::vector<std::string> filenames;

void error(
	std::string const& str, 
	int         const  line_num, 
	int         const  file_num)
{
	std::cout << "\033[0;31mERROR:\033[0m " << str << "\n"
	          << "\033[0;36m\tfile:\033[0m  " << filenames[file_num] << "\n"
	          << "\033[0;36m\tline:\033[0m  " << line_num << "\n";
	is_error = true;
	return;
}
void warning(
	std::string const& str, 
	int         const  line_num, 
	int         const  file_num)
{
	std::cout << "\033[0;35mWARNING:\033[0m " << str << "\n"
	          << "\033[0;36m\tfile:\033[0m  " << filenames[file_num] << "\n"
	          << "\033[0;36m\tline:\033[0m  " << line_num << "\n";
	is_warning = true;
	return;
}
