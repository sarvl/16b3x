#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <cstring>
#include <cstdint>
#include <utility>

#include "token.h"
#include "instruction.h"
#include "process.h"
#include "error.h"
#include "parse.h"

using namespace std::literals;

constexpr char val_hex(const uint8_t val)
{
	if(val <= 9)
		return val + '0';
	else
		return val + 'A' - 10;
}

struct Label{
	std::string name;
	int instruction;

	Label(); 
	Label(std::string n_name, int const n_instr);
};
Label::Label() {}
Label::Label(std::string n_name, int const n_instr)
	: name(std::move(n_name)), instruction(n_instr) {}
	
std::vector<std::string> filenames; 

int main(int argc, char* argv[])
{
	for(int i = 1; i < argc; i++)
		filenames.emplace_back(argv[i]);


	std::vector<Token> tokens[2];
	std::vector<std::string> names;
	std::vector<Label> labels;

	std::ofstream out("out.bin");
	int instruction_count = 0;

	parse_file(0, tokens[0], names);
	parse_file(1, tokens[0], names);
	
//	for(const Token& token : tokens[0])
//	{
//		if(T_Token::NON == token.type)
//			continue;
//		std::cout << token;
//		if(T_Token::MCR == token.type
//		|| T_Token::MCN == token.type
//		|| T_Token::MCP == token.type
//		|| T_Token::MCA == token.type
//		|| T_Token::CNS == token.type
//		|| T_Token::LBC == token.type
//		|| T_Token::LBU == token.type)
//			std::cout << ' ' << names[token.val];
//		std::cout << '\n';
//	}
//	std::cout << '\n';

	tokens[1].reserve(tokens[0].size());
	process_initial(tokens[1]         /*out*/, 
	                labels            /*out*/, 
	                names             /*out*/, 
	                instruction_count /*out*/, 
	                tokens[0]         /*in, modified*/
	                );
//	for(const Token& token : tokens[1])
//	{
//		if(T_Token::NON == token.type)
//			continue;
//		std::cout << token;
//		if(T_Token::MCR == token.type
//		|| T_Token::MCN == token.type
//		|| T_Token::MCP == token.type
//		|| T_Token::MCA == token.type
//		|| T_Token::CNS == token.type
//		|| T_Token::LBC == token.type
//		|| T_Token::LBU == token.type)
//			std::cout << ' ' << names[token.val];
//		std::cout << '\n';
//	}
//	std::cout << '\n';
	

	//swap IO token vectors
	tokens[0].clear();
	tokens[0].reserve(tokens[1].size());
	process_expr(tokens[0] /*out*/, 
	             tokens[1]);


//	std::cout << "tokens result: \n";
//	for(const Token& token : tokens[0])
//	{
//		if(T_Token::NON == token.type)
//			continue;
//		std::cout << token;
//		if(T_Token::MCR == token.type
//		|| T_Token::MCN == token.type
//		|| T_Token::MCP == token.type
//		|| T_Token::MCA == token.type
//		|| T_Token::CNS == token.type
//		|| T_Token::LBC == token.type
//		|| T_Token::LBU == token.type)
//			std::cout << ' ' << names[token.val];
//		std::cout << '\n';
//	}
//	std::cout << '\n';

	

#define ERROR_NEQ1(tok, t0, s  )                                      \
			if(t0  != tok){                                           \
				error(s  ,                                            \
				       tokens[0][tid].line,                           \
				       tokens[0][tid].file);                          \
				tid++;                                                \
				continue;}                                            
#define ERROR_NEQ2(tok, t0, t1, s  )                                  \
			if(t0  != tok                                             \
			&& t1  != tok){                                           \
				error(s  ,                                            \
				       tokens[0][tid].line,                           \
				       tokens[0][tid].file);                          \
				tid++;                                                \
				continue;}                                            
#define ERROR_NEQ3(tok, t0, t1, t2, s  )                              \
			if(t0  != tok                                             \
			&& t1  != tok                                             \
			&& t2  != tok){                                           \
				error(s  ,                                            \
				       tokens[0][tid].line,                           \
				       tokens[0][tid].file);                          \
				tid++;                                                \
				continue;}                                            

//	std::cout << instruction_count << '\n';
	std::string output(instruction_count * 5, '0');
	//generate output
	int tid = 0; 
	int cur_instr = -1;
	while(T_Token::END != tokens[0][tid].type)
	{
		int opcode = 0;
		int arg0 = 0;
		int arg1 = 0;
		bool iformat = true;


		/*
			it will be implemented
			not today

		*/
	
		//this can be simpler, in earlies prcessing step add inserting noops
//		if(T_Token::ATS == tokens[0][tid].type)
//		{
//			if(T_Token::LBU != tokens[0][tid + 1].type)
//			{
//				error("attribute should have a name", tokens[0][tid].line, tokens[0][tid].file);
//				continue;
//			}
//			if("ALIGN"s != names[tokens[0][tid + 1].val])
//			{
//				error("unrecognized attribute name", tokens[0][tid].line, tokens[0][tid].file);
//				continue;
//			}
//			if(T_Token::NUM != tokens[0][tid + 2].type)
//			{
//				error("ALIGN argument should be number", tokens[0][tid].line, tokens[0][tid].file);
//				continue;
//			}
//			if(T_Token::ATE != tokens[0][tid + 3].type)
//			{
//				error("unterminated attribute", tokens[0][tid].line, tokens[0][tid].file);
//				continue;
//			}
//			
//			int const alignment = tokens[0][tid + 2].val;
//
//			int const to_add = instruction_count % alignment;
//			output.resize(output.size() + 5 * to_add);	
//			for(int i = 0; i < to_add; i++) 
//			{
//				output[(cur_instr + i) * 5 + 0] = '0';
//				output[(cur_instr + i) * 5 + 1] = '0';
//				output[(cur_instr + i) * 5 + 2] = '0';
//				output[(cur_instr + i) * 5 + 3] = '0';
//				output[(cur_instr + i) * 5 + 4] = '\n';
//			}
//			cur_instr += to_add;
//			tid += 4;
//			continue;
//			
//		}
//
		ERROR_NEQ1(tokens[0][tid].type, T_Token::INS,
		           "unexpected token "s + to_string(tokens[0][tid].type));

		cur_instr++;
		using enum Opcode;
		using enum T_Token;
		opcode = tokens[0][tid].val;
		switch(tokens[0][tid].val)
		{
 		case val(NOP):
			tid++;
			goto insert_instruction;
			continue;
		case val(HLT):
			if(ICC == tokens[0][tid + 1].type)
			{
				arg0 = tokens[0][tid + 1].val;
				tid++;
			}
			else
				arg0 = 0b111;
			tid++;
			goto insert_instruction;

 		case val(PSH):
 		case val(POP):
			ERROR_NEQ1(tokens[0][tid + 1].type, RIN,
			           "expected internal register as first argument");
			goto correct_output_1;

 		case val(RET):
			if(ICC == tokens[0][tid + 1].type)
			{
				arg0 = tokens[0][tid + 1].val;
				tid++;
			}
			else
				arg0 = 0b111;
			tid++;
			goto insert_instruction;
			break;

 		case val(JMP):
 		case val(CAL):

			if(ICC == tokens[0][tid + 1].type)
			{
				arg0 = tokens[0][tid + 1].val;
			
				ERROR_NEQ3(tokens[0][tid + 2].type, RIN, LBU, NUM,
			    	       "expected internal register, label or constant as second argument");
			
				if(LBU == tokens[0][tid + 2].type)
				{
					std::string const& searched = names[tokens[0][tid + 2].val];
					bool label_found = false;
					for(Label const& label : labels)
						if(label.name == searched)
						{
							arg1 = label.instruction;
							label_found = true;
							break;
						}
					if(!label_found)
					{
						error(searched + " does not exist",
						      tokens[0][tid + 2].line,
						      tokens[0][tid + 2].file);
					}
				}
				else
				{
					iformat = (NUM == tokens[0][tid + 2].type);
					arg1 = tokens[0][tid + 2].val;
				}

				tid += 3;
				goto insert_instruction;
			}

			arg0 = 0b111;
				
			ERROR_NEQ3(tokens[0][tid + 1].type, RIN, LBU, NUM,
			   	       "expected condition codes, internal register,  label or constant as first argument");
			if(LBU == tokens[0][tid + 1].type)
			{
				std::string const& searched = names[tokens[0][tid + 1].val];
				bool label_found = false;
				for(Label const& label : labels)
					if(label.name == searched)
					{
						arg1 = label.instruction;
						label_found = true;
						break;
					}
				if(!label_found)
				{
					error(searched + " does not exist",
					      tokens[0][tid + 1].line,
					      tokens[0][tid + 1].file);
				}
			}
			else
			{
				iformat = (NUM == tokens[0][tid + 1].type);
				arg1 = tokens[0][tid + 1].val;
			}
			
			
			tid += 2;
			goto insert_instruction;
			break;
 		case val(RDX):

			ERROR_NEQ1(tokens[0][tid + 1].type, RIN,
			           "expected internal register as first argument");
			ERROR_NEQ1(tokens[0][tid + 2].type, REX,
			           "expected external register as second argument");
			goto correct_output_2;
 		case val(WRX):
			ERROR_NEQ1(tokens[0][tid + 1].type, REX,
			           "expected external register as first argument");
			ERROR_NEQ3(tokens[0][tid + 2].type, RIN, LBU, NUM,
			           "expected internal register, label or constant as second argument");
			goto correct_output_2;

 		case val(MUL):
 		case val(MOV):
 		case val(CMP):
 		case val(TST):
 		case val(ADD):
 		case val(SUB):
 		case val(NOT):
 		case val(AND):
 		case val(ORR):
 		case val(XOR):
 		case val(SLL):
 		case val(SLR):
 		case val(RDM):
 		case val(WRM):
			ERROR_NEQ1(tokens[0][tid + 1].type, RIN,
			           "expected internal register as first argument");
			ERROR_NEQ3(tokens[0][tid + 2].type, RIN, LBU, NUM,
			           "expected internal register, label or constant as second argument");
			goto correct_output_2;
			
			break;
		correct_output_1:
			arg0 = tokens[0][tid + 1].val;
			tid += 2;
			goto insert_instruction;
			break;
		correct_output_2:
			arg0 = tokens[0][tid + 1].val;
			if(LBU == tokens[0][tid + 2].type)
			{
				std::string const& searched = names[tokens[0][tid + 2].val];
				bool label_found = false;
				for(Label const& label : labels)
					if(label.name == searched)
					{
						arg1 = label.instruction;
						label_found = true;
						break;
					}
				if(!label_found)
				{
					error(searched + " does not exist",
					      tokens[0][tid + 2].line,
					      tokens[0][tid + 2].file);
				}
			}
			else
			{
				iformat = (NUM == tokens[0][tid + 2].type);
				arg1 = tokens[0][tid + 2].val;
			}
			
			tid += 3;
			goto insert_instruction;
			break;
		}
		
insert_instruction:
		uint16_t val;
		if(iformat)
			val = static_cast<uint16_t>(opcode << 11)
			    | static_cast<uint16_t>(arg0   <<  8)
			    | static_cast<uint16_t>(arg1   <<  0)
			    ;
		else
			val = static_cast<uint16_t>(arg0   <<  8)
			    | static_cast<uint16_t>(arg1   <<  5)
			    | static_cast<uint16_t>(opcode <<  0)
			    ;
		

		output[cur_instr * 5 + 0] = val_hex((val >> 12) & 0xF);
		output[cur_instr * 5 + 1] = val_hex((val >>  8) & 0xF);
		output[cur_instr * 5 + 2] = val_hex((val >>  4) & 0xF);
		output[cur_instr * 5 + 3] = val_hex((val >>  0) & 0xF);
		output[cur_instr * 5 + 4] = '\n'; 
	}

  
out <<output;

}
