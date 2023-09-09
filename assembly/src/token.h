#pragma once

#include <iostream>
#include <string>

enum class T_Token{
	NON =  0, //none, default

	INS = 10, //instruction
	RIN = 11, //reg internal
	REX = 12, //reg external
	ICC = 13, //instruction condition codes

	NUM = 20, //number

	CNS = 30, //name of constant
	LBC = 31, //label created
	LBU = 32, //label used

	MCS = 40, //macro start
	MCE = 41, //macro end
	MCN = 42, //macro name
	MCR = 43, //macro reference
	MCP = 44, //name of parameter in macro or name of what is to be substituted
	MCA = 45, //where argument should be pasted 

	EXS = 50, //expression start
	EXE = 51, //expression end
	EXO = 52, //expression operator

	ATS = 60, //attribute start
	ATE = 61, //attribute end

	DTA = 70, //data allocation

	END = -1  //end of file, token to prevent potential too long reads
};


struct Token{
	T_Token type;
	int val;      //represents a lot of things, depending on T_Token
	              //list at the bottom of the file
	int line;
	int file;

	Token();
	Token(T_Token const n_type, int const n_val, int const n_line, int const n_file);
};

std::ostream& operator<<(std::ostream& os, Token const& token);
std::string to_string(T_Token const token);

/* 
WHAT VAL MEANS FOR EACH TOKEN TYPE

	NON
		no meaning

	INS
		opcode
	RIN
		internal register index
	REX
		external register index
	ICC
		condition code

	NUM
		value of number

	CNS
		index to names
		name of constant
	LBC
		index to names
		name of label
	LBU
		index to names
		name of label

	MCS
		no meaning
	MCE
		no meaning
	MCN
		index to names
		name of macro
	MCR
		intex to names
		name of macro
	MCP
		index to names
		name of parameter
	MCA
		initially:
		index to names, NAME of parameter
		later:
		INDEX of argument 

	EXS
		no meaning
	EXE
		no meaning
	EXO
		ASCII value of operator

	ATS
		no meaning
	ATE
		no meaning

	DTA 
		no meaning

	END
		no meaning

*/
