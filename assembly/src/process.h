#pragma once

#include <vector>
#include <string>

#include "token.h"
#include "error.h"

struct Label;

/*
	extracts constants
	extracts labels 
	evaluates macros
	counts how many instructions were used
	pasts end of input token
	changes what MCA in input_Tok mean
*/
void process_initial(
	std::vector<Token>      & output_tok ,
	std::vector<Label>      & labels     ,
	std::vector<std::string>& names      ,
	int                     & instr_count,
	std::vector<Token>      & input_tok  
	);

void process_expr(
	std::vector<Token>           & output_tok ,
	std::vector<Token>      const& input_tok  
	);
