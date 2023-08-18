#include <fstream>

#include <vector>
#include <string> 

#include <cstring> //strcmp

#include "token.h"
#include "parse.h"
#include "instruction.h"


#define CHECK_IF_CC(x) ('L' == (x) || 'E' == (x) || 'G' == (x))
#define CHECK_CHARS3(x, y, z) if(x == line[beg] && y == line[beg + 1] && z == line[beg + 2])  
#define CHECK_CHARS2(x, y) if(x == line[beg] && y == line[beg + 1])  

extern std::vector<std::string> filenames;

void parse_file(
	int                      const  file_num,
	std::vector<Token>            & tokens  ,
	std::vector<std::string>      & names
	)
{
	std::ifstream file(filenames[file_num]);
	std::string line;
	int ln = 0;
	while(std::getline(file, line))
		parse_line(tokens, names, line, ++ln, file_num); 

	file.close();
	return;

}


void parse_line(
	 std::vector<Token>            & tokens  , 
	 std::vector<std::string>      & names   ,
	 std::string              const& line    ,
	 int                      const  line_num,
	 int                      const  file_num
	 )
{
	using enum T_Token;

	int ind = 0;
	while(ind < line.size())
	{
	switch(line[ind])
	{
	case '@':
	{
		unsigned int beg = ind + 1;
		unsigned int end;
		for(end = beg; end < line.size(); end++)
			if(' '  == line[end]
			|| '\t' == line[end]
			|| '('  == line[end])
				break;
		
		if(end - beg == 3
		&& 0 == strncmp(&line[beg], "end", 3))
			tokens.emplace_back(MCE, -1, line_num, file_num);
		else if(end - beg == 3
		&& 0 == strncmp(&line[beg], "def", 3))
		{
			tokens.emplace_back(CNS, names.size(), line_num, file_num);
			
			beg = end + 1;
			for(end = beg; end < line.size(); end++)
				if(' '  == line[end]
				|| '\t' == line[end])
					break;
			names.emplace_back(line.substr(beg, end - beg));

		}
		else if(end - beg == 5
		&& 0 == strncmp(&line[beg], "macro", 5))
		{
			tokens.emplace_back(MCS, -1, line_num, file_num);
			

			beg = end + 1;
			for(end = beg; end < line.size(); end++)
				if(' '  == line[end]
				|| '\t' == line[end]
				|| '(' == line[end])
					break;
			tokens.emplace_back(MCN, names.size(), line_num, file_num);
			names.emplace_back(line.substr(beg, end - beg));

		}
		else
		{
			tokens.emplace_back(MCR, names.size(), line_num, file_num);
			names.emplace_back(line.substr(beg, end - beg));
		}

		ind = end;
		break;
	}
	case '(':
	{
		while(')' != line[ind])
		{
			unsigned beg = ind + 1;
			unsigned end;
			if(' '  == line[beg]
			|| '\t' == line[beg])
			{
				ind++;
				continue;
			}

			for(end = beg; end < line.size(); end++)
				if(')' == line[end]
				|| ',' == line[end])
					break;
			
			tokens.emplace_back(MCP, names.size(), line_num, file_num);
			names.emplace_back(line.substr(beg, end - beg));
			
			ind = end;
		}
		ind++;
		break;
	}
	case '0'...'9':
	{
		int num = 0;

		while('0' <= line[ind] && line[ind] <= '9')
		{
			num = 10 * num + line[ind] - '0';
			ind++;
		}

		tokens.emplace_back(NUM, num, line_num, file_num);
		break;
	}
	case '_':
	{
		unsigned beg = ind + 1;
		unsigned end;

		for(end = beg; end < line.size(); end++)
			if(' '  == line[end]
			|| '\t' == line[end]
			|| ',' == line[end])
				break;
	
		tokens.emplace_back(MCA, names.size(), line_num, file_num);
		names.emplace_back(line.substr(beg, end - beg));
		
		ind = end;
		break;
	}	
	case '{':
		tokens.emplace_back(EXS, -1, line_num, file_num);
		ind++;
		break;
	case '}':
		tokens.emplace_back(EXE, -1, line_num, file_num);
		ind++;
		break;
	case '[':
		tokens.emplace_back(ATS, -1, line_num, file_num);
		ind++;
		break;
	case ']':
		tokens.emplace_back(ATE, -1, line_num, file_num);
		ind++;
		break;
	case '#':
	case ';':
		return;
	case '\t':
	case '\n':
	case ' ':
	case ',':
		ind++;
		continue;
	case '+':
	case '-':
	case '*':
	case '/':
	case '%':
	case '&':
	case '|':
	case '^':
	case '!':
		tokens.emplace_back(EXO, line[ind], line_num, file_num); 
		ind++;
		break;
	default:
	{
		unsigned beg = ind;
		unsigned end;

		for(end = beg; end < line.size(); end++)
			if(' '  == line[end]
			|| '\t' == line[end]
			|| ',' == line[end])
				break;

		if(':' == line[end - 1])
		{
			tokens.emplace_back(LBC, names.size(), line_num, file_num);
			names.emplace_back(line.substr(beg, end - beg - 1));
			ind = end;
			continue;
		}

		if(2 == end - beg)
		{
			if('R' == line[beg]
			&& '0' <= line[beg + 1]
			&& line[beg + 1] <= '7')
			{
				tokens.emplace_back(RIN, line[beg + 1] - '0', line_num, file_num);
				ind = end;
				continue;
			}
			else CHECK_CHARS2('I','P') 
				{tokens.emplace_back(REX, 0, line_num, file_num); ind = end; continue;}
			else CHECK_CHARS2('S','P') 
				{tokens.emplace_back(REX, 1, line_num, file_num); ind = end; continue;}
			else CHECK_CHARS2('L','R') 
				{tokens.emplace_back(REX, 2, line_num, file_num); ind = end; continue;}
//			else CHECK_CHARS2(' ',' ') 
//				{tokens.emplace_back(REX, 3, line_num, file_num); ind = end; continue;}
			else CHECK_CHARS2('U','I') 
				{tokens.emplace_back(REX, 4, line_num, file_num); ind = end; continue;}
			else CHECK_CHARS2('F','L') 
				{tokens.emplace_back(REX, 5, line_num, file_num); ind = end; continue;}
//			else CHECK_CHARS2(' ',' ') 
//				{tokens.emplace_back(REX, 6, line_num, file_num); ind = end; continue;}
			else CHECK_CHARS2('C','F') 
				{tokens.emplace_back(REX, 7, line_num, file_num); ind = end; continue;}

			else goto add_label;

		}
		else if(3 == end - beg)
		{
			int opcode = -1;

			     CHECK_CHARS3('n','o','p') opcode = 0x00;
			else CHECK_CHARS3('h','l','t') opcode = 0x01;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x02;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x03;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x04;
			else CHECK_CHARS3('m','o','v') opcode = 0x05;
			else CHECK_CHARS3('r','d','m') opcode = 0x06;
			else CHECK_CHARS3('w','r','m') opcode = 0x07;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x08;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x09;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x0A;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x0B;
			else CHECK_CHARS3('r','d','x') opcode = 0x0C;
			else CHECK_CHARS3('w','r','x') opcode = 0x0D;
			else CHECK_CHARS3('p','s','h') opcode = 0x0E;
			else CHECK_CHARS3('p','o','p') opcode = 0x0F;
			else CHECK_CHARS3('m','u','l') opcode = 0x10;
			else CHECK_CHARS3('c','m','p') opcode = 0x11;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x12;
			else CHECK_CHARS3('t','s','t') opcode = 0x13;
			else CHECK_CHARS3('j','m','p') opcode = 0x14;
			else CHECK_CHARS3('c','a','l') opcode = 0x15;
			else CHECK_CHARS3('r','e','t') opcode = 0x16;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x17;
			else CHECK_CHARS3('a','d','d') opcode = 0x18;
			else CHECK_CHARS3('s','u','b') opcode = 0x19;
			else CHECK_CHARS3('n','o','t') opcode = 0x1A;
			else CHECK_CHARS3('a','n','d') opcode = 0x1B;
			else CHECK_CHARS3('o','r','r') opcode = 0x1C;
			else CHECK_CHARS3('x','o','r') opcode = 0x1D;
			else CHECK_CHARS3('s','l','l') opcode = 0x1E;
			else CHECK_CHARS3('s','l','r') opcode = 0x1F;

			if(opcode == -1)
				goto add_label;

			tokens.emplace_back(INS, opcode, line_num, file_num);
			ind = end;

		}
		else
		{
add_label:
			int flags = 0x0;
			while(ind < end)
			{
				char const c = line[ind];
				switch(c)
				{
				case 'G':
				case 'g':
					flags |= Flags::G;
					break;
				case 'L':
				case 'l':
					flags |= Flags::L;
					break;
				case 'E':
				case 'e':
				case 'Z':
				case 'z':
					flags |= Flags::E;
					break;
				default:
					goto usual_text;
					continue;
				}
				ind++;
			}

			tokens.emplace_back(ICC, flags, line_num, file_num);
			ind = end;
			continue;
usual_text:
			tokens.emplace_back(LBU, names.size(), line_num, file_num);
			names.emplace_back(line.substr(beg, end - beg));

			ind = end;

			continue;
		}
		break;
	}
	}
	}


	return;
}

void parse_simple_word(
	 Token                         & token   , 
	 std::vector<std::string>      & names   ,
	 std::string              const& line    ,
	 int                      const  line_num,
	 int                      const  file_num
	 )
{
	using enum T_Token;

	int ind = 0;
	while(ind < line.size())
	{
	switch(line[ind])
	{
	case '0'...'9':
	{
		int num = 0;

		while('0' <= line[ind] && line[ind] <= '9')
		{
			num = 10 * num + line[ind] - '0';
			ind++;
		}

		token = Token(NUM, num, line_num, file_num);
		break;
	}
	case '\t':
	case '\n':
	case ' ':
	case ',':
		ind++;
		continue;
	default:
	{
		unsigned beg = ind;
		unsigned end;

		for(end = beg; end < line.size(); end++)
			if(' '  == line[end]
			|| '\t' == line[end]
			|| ',' == line[end])
				break;

		if(':' == line[end - 1])
		{
			token = Token(LBC, names.size(), line_num, file_num);
			names.emplace_back(line.substr(beg, end - beg - 1));
			ind = end;
			continue;
		}

		if(2 == end - beg)
		{
			if('R' == line[beg]
			&& '0' <= line[beg + 1]
			&& line[beg + 1] <= '7')
			{
				token = Token(RIN, line[beg + 1] - '0', line_num, file_num);
				ind = end;
				continue;
			}
			else CHECK_CHARS2('I','P') 
				{token = Token(REX, 0, line_num, file_num); ind = end; continue;}
			else CHECK_CHARS2('S','P') 
				{token = Token(REX, 1, line_num, file_num); ind = end; continue;}
			else CHECK_CHARS2('L','R') 
				{token = Token(REX, 2, line_num, file_num); ind = end; continue;}
//			else CHECK_CHARS2(' ',' ') 
//				{token = Token(REX, 3, line_num, file_num); ind = end; continue;}
			else CHECK_CHARS2('U','I') 
				{token = Token(REX, 4, line_num, file_num); ind = end; continue;}
			else CHECK_CHARS2('F','L') 
				{token = Token(REX, 5, line_num, file_num); ind = end; continue;}
//			else CHECK_CHARS2(' ',' ') 
//				{token = Token(REX, 6, line_num, file_num); ind = end; continue;}
			else CHECK_CHARS2('C','F') 
				{token = Token(REX, 7, line_num, file_num); ind = end; continue;}

			else goto add_label;

		}
		else if(3 == end - beg)
		{
			int opcode = -1;

			     CHECK_CHARS3('n','o','p') opcode = 0x00;
			else CHECK_CHARS3('h','l','t') opcode = 0x01;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x02;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x03;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x04;
			else CHECK_CHARS3('m','o','v') opcode = 0x05;
			else CHECK_CHARS3('r','d','m') opcode = 0x06;
			else CHECK_CHARS3('w','r','m') opcode = 0x07;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x08;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x09;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x0A;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x0B;
			else CHECK_CHARS3('r','d','x') opcode = 0x0C;
			else CHECK_CHARS3('w','r','x') opcode = 0x0D;
			else CHECK_CHARS3('p','s','h') opcode = 0x0E;
			else CHECK_CHARS3('p','o','p') opcode = 0x0F;
			else CHECK_CHARS3('m','u','l') opcode = 0x10;
			else CHECK_CHARS3('c','m','p') opcode = 0x11;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x12;
			else CHECK_CHARS3('t','s','t') opcode = 0x13;
			else CHECK_CHARS3('j','m','p') opcode = 0x14;
			else CHECK_CHARS3('c','a','l') opcode = 0x15;
			else CHECK_CHARS3('r','e','t') opcode = 0x16;
//			else CHECK_CHARS3(' ',' ',' ') opcode = 0x17;
			else CHECK_CHARS3('a','d','d') opcode = 0x18;
			else CHECK_CHARS3('s','u','b') opcode = 0x19;
			else CHECK_CHARS3('n','o','t') opcode = 0x1A;
			else CHECK_CHARS3('a','n','d') opcode = 0x1B;
			else CHECK_CHARS3('o','r','r') opcode = 0x1C;
			else CHECK_CHARS3('x','o','r') opcode = 0x1D;
			else CHECK_CHARS3('s','l','l') opcode = 0x1E;
			else CHECK_CHARS3('s','l','r') opcode = 0x1F;

			if(opcode == -1)
				goto add_label;

			token = Token(INS, opcode, line_num, file_num);
			ind = end;

		}
		else
		{
add_label:
			int flags = 0x0;
			while(ind < end)
			{
				char const c = line[ind];
				switch(c)
				{
				case 'G':
				case 'g':
					flags |= Flags::G;
					break;
				case 'L':
				case 'l':
					flags |= Flags::L;
					break;
				case 'E':
				case 'e':
				case 'Z':
				case 'z':
					flags |= Flags::E;
					break;
				default:
					goto usual_text;
					continue;
				}
				ind++;
			}

			token = Token(ICC, flags, line_num, file_num);
			ind = end;
			continue;
usual_text:
			token = Token(LBU, names.size(), line_num, file_num);
			names.emplace_back(line.substr(beg, end - beg));

			ind = end;

			continue;
		}
		break;
	}
	}
	}


	return;
}

