#include "process.h"
#include "parse.h"

#include <vector>
#include <string>

using namespace std::literals;

extern std::vector<std::string> filenames;

struct Macro{
	std::string name;
	std::vector<Token> output_tok;
	int file;
	int arg_count;

	Macro() {}
	Macro(std::string n_name, std::vector<Token> const& to_copy_from, int beg, int const end, int const n_fn, int const n_ac)
		: name(std::move(n_name)), file(n_fn), arg_count(n_ac)
	{
		output_tok.resize(end - beg + 1);
		
		for(int i = 0; beg <= end; beg++, i++)
			output_tok[i] = to_copy_from[beg];
	}
};


struct Label{
	std::string name;
	int instruction;

	Label(); 
	Label(std::string n_name, int const n_instr);
};


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
	)
{
	//its probably suboptimal to use hash tabe for names for any real macro aomunt
	std::vector<Macro> macros;

	int tid = 0;
	while(static_cast<unsigned>(tid) < input_tok.size())
	{
		Token const& token = input_tok[tid];
		using enum T_Token;
		switch(token.type)
		{
		case CNS:
			labels.emplace_back(names[token.val], input_tok[tid + 1].val);
			tid += 2;
			break;
		case LBC:
			labels.emplace_back(names[token.val], instr_count);
			tid++;
			break;
		case MCS:
		{
			int       beg = tid;
			int       end;
			int       end_of_args = beg + 1;
			int const file = input_tok[beg].file;
			int const line = input_tok[beg].line;
			std::vector<std::string> args;
			for(end = beg + 1; 
				static_cast<unsigned>(end) < input_tok.size();
				end++)
			{
				if(MCE == input_tok[end].type)
					break;
				if(MCP == input_tok[end].type)
				{
					args.emplace_back(names[input_tok[end].val]);
					end_of_args = end;
				}

				if(MCA == input_tok[end].type)
				{
					bool found_name = false;
					for(unsigned i = 0; i < args.size(); i++)
					{
						if(args[i] == names[input_tok[end].val])
						{
							input_tok[end].val = i;
							found_name = true;
							break;
						}
					}
					if(!found_name)
						error("did not found "s + names[input_tok[end].val] +
						      " as parameter of macro", input_tok[end].line, input_tok[end].file);

				}
			}

			std::string const& name = names[input_tok[beg + 1].val];
			for(Macro const& other_macro : macros)
			{
				if(other_macro.name == name)
				{
					error("macro "s + name + " already defined in file " + filenames[other_macro.file], line, file); 
					break;
				}
			}

			macros.emplace_back(name, 
			                    input_tok, end_of_args + 1, end - 1,
			                    file, end_of_args - beg - 1);

			tid = end + 1;
				
		}
			break;
		case MCR:
		{
			std::vector<Token> args;
			int beg = tid;
			int end;

			int const file = input_tok[beg].file;
			int const line = input_tok[beg].file;

			for(end = beg + 1; 
				static_cast<unsigned>(end) < input_tok.size();
				end++)
			{
				if(MCP != input_tok[end].type)
					break;

				//NOT reference due to the fact that it may break on resize
				std::string const name = names[input_tok[end].val];
				Token ntoken;
				parse_simple_word(ntoken, names, name, line, file); 
				args.emplace_back(ntoken); 
			}

			std::string const& name = names[input_tok[tid].val];
			for(Macro const& macro : macros)
			{
				if(name == macro.name)
				{
					if(static_cast<unsigned>(macro.arg_count) != args.size())
					{
						error("incorrect amount of arguments given for macro "s + name + 
						      "\n\texpected: "s + std::to_string(macro.arg_count) + 
						      " but got " + std::to_string(args.size()),
						      file, line);
						break;
					}
					for(Token const& token : macro.output_tok)
					{
						if(INS == token.type
						|| DTA == token.type)
							instr_count++;

						if(MCA == token.type)
						{
							output_tok.emplace_back(args[token.val]);
							if(INS == args[token.val].type)
								instr_count++;
						}
						else
							output_tok.emplace_back(token);
						output_tok.back().line = line;
						output_tok.back().file = file;

						
					}
					break;
				}
			}
			tid = end;
		}
			break;
		case ATS:
			if( LBU     != input_tok[tid + 1].type
			|| "ALIGN"s != names[input_tok[tid + 1].val])
			{
				error("Unknown attribute", input_tok[tid].line, input_tok[tid].file);
				tid++;
				break;
			}
			if(NUM != input_tok[tid + 2].type)
			{
				error("ALIGN expects number as argument", input_tok[tid].line, input_tok[tid].file);
				tid += 2;
				break;
			}
			if(ATE != input_tok[tid + 3].type)
			{
				error("Attribute not terminated", input_tok[tid].line, input_tok[tid].file);
				tid += 3;
				break;
			}
			{
			int nops_to_add = input_tok[tid + 2].val - (instr_count % input_tok[tid + 2].val);
			instr_count += nops_to_add;
			while(nops_to_add --> 0)
				output_tok.emplace_back(INS, 0, input_tok[tid].line, input_tok[tid].file); 
			
			tid += 4;
			}
			break;
		case DTA:
		case INS:
			instr_count++;
			goto add_token;

		add_token:
		default:
			output_tok.emplace_back(token);
			tid++;
			break;

		}

	}
	output_tok.emplace_back(T_Token::END, -1, -1, -1);

	return;
}

void process_expr(
	std::vector<Token>           & output_tok ,
	std::vector<Token>      const& input_tok  
	)
{
	bool in_expr = false;
	std::vector<int> stack;
	int line;
	int file;
	for(Token const& token : input_tok)
	{
		using enum T_Token;
		if(EXS == token.type)
		{
			in_expr = true;

			line = token.line;
			file = token.file;
			continue;
		}
		if(EXE == token.type)
		{
			in_expr = false;
			output_tok.emplace_back(NUM, stack[0], -3, -3);
			if(stack.size() > 1)
				error("too many arguments in expression", line, file);

			stack.clear();

			continue;
		}
		if(false == in_expr)
		{
			output_tok.emplace_back(token);
			continue;
		}

		if(NUM == token.type)
		{
			stack.push_back(token.val);
			continue;
		}

#define CASE(c, op)                                           \
	case(c):                                                  \
	{                                                         \
	    if(stack.size() < 2)                                  \
	    {                                                     \
	       error("not enough arguments in expression for "#c, \
		          line, file);                                \
		   stack.back() = 0;                                  \
		   break;                                             \
	    }                                                     \
		int x = stack.back();                                 \
		stack.pop_back();                                     \
		stack.back() op x;                                    \
		break;                                                \
	}
	
		switch(token.val)
		{
		CASE('+', +=)
		CASE('-', -=)
		CASE('*', *=)
		CASE('/', /=)
		CASE('%', %=)
		CASE('&', &=)
		CASE('|', |=)
		CASE('^', ^=)
		case '!':
			stack.back() = !stack.back();
			break;
#undef CASE

		}
	}

	return;
}
