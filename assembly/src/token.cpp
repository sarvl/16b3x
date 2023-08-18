#include <iostream>

#include "token.h"


Token::Token()
	: type(T_Token::NON) {}
Token::Token(T_Token const n_type, int const n_val, int const n_line, int const n_file)
		: type(n_type), val(n_val), line(n_line), file(n_file){}

std::string to_string(T_Token const token)
{
	using enum T_Token;
	switch(token)
	{
	case NON:
		return "NON";
	case INS:
		return "INS";
	case RIN:
		return "RIN";
	case REX:
		return "REX";
	case ICC:
		return "ICC";
	case NUM:
		return "NUM";
	case CNS:
		return "CNS";
	case LBC:
		return "LBC";
	case LBU:
		return "LBU";
	case MCS:
		return "MCS";
	case MCE:
		return "MCE";
	case MCN:
		return "MCN";
	case MCR:
		return "MCR";
	case MCP:
		return "MCP";
	case MCA:
		return "MCA";
	case EXS:
		return "EXS";
	case EXE:
		return "EXE";
	case EXO:
		return "EXO";
	case ATS:
		return "ATS";
	case ATE:
		return "ATE";
	case END:
		return "END";
	}
	return "INV";
}

std::ostream& operator<<(std::ostream& os, Token const& token)
{
	os << '<';
	os << to_string(token.type);
	os << " : ";
	os << token.val;
	os << " : ";
	os << token.line;
	os << " : ";
	os << token.file;
	os << '>';
	return os;
}

