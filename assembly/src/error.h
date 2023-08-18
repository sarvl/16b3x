#pragma once

#include <string>


extern bool is_error  ;
extern bool is_warning;
void error(
	std::string const& str, 
	int         const  line_num, 
	int         const  file_num
	);
void warning(
	std::string const& str, 
	int         const  line_num, 
	int         const  file_num
	);
