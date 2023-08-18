#pragma once

#include <fstream>

#include <vector>
#include <string> 

#include "token.h"

void parse_file(
	int                      const  file_num,
	std::vector<Token>            & tokens  ,
	std::vector<std::string>      & names
	);


void parse_line(
	 std::vector<Token>           & tokens  , 
	 std::vector<std::string>     & names   ,
	 std::string             const& line    ,
	 int                     const  line_num,
	 int                     const  file_num
	 );

//assumes there is only one token in string
void parse_simple_word(
	 Token                         & token   , 
	 std::vector<std::string>      & names   ,
	 std::string              const& line    ,
	 int                      const  line_num,
	 int                      const  file_num
	 );


