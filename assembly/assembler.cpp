/*
	this assembler will be rewritten once i get back to compilers

*/


#include <iostream>
#include <fstream>

#include <vector>
#include <string>

#include <utility> //move

using namespace std::literals;

struct Label{
	std::string name;
	int position;
	int line;

	Label(const std::string& n_name, const int n_pos)
		: name(n_name), position(n_pos) {}
};

enum class Opcode : uint8_t{
 NOP = 0x00,
 HLT = 0x01,

 MOV = 0x05,
 RDM = 0x06,
 WRM = 0x07,

 RDX = 0x0C,
 WRX = 0x0D,
 PSH = 0x0E,
 POP = 0x0F,
 MUL = 0x10,
 CMP = 0x11,

 TST = 0x13,
 JMP = 0x14,
 CAL = 0x15,
 RET = 0x16,

 ADD = 0x18,
 SUB = 0x19,
 NOT = 0x1A,
 AND = 0x1B,
 ORR = 0x1C,
 XOR = 0x1D,
 SLL = 0x1E,
 SLR = 0x1F
};

constexpr uint8_t opval(const Opcode op)
{
	return static_cast<uint8_t>(op);
}

namespace Flags{
	enum Flags : uint8_t{
		 L = 0b100,
		 E = 0b010,
		 G = 0b001
	};

	constexpr uint8_t all = (Flags::L | Flags::E | Flags::G);
};


struct Instruction{
	Opcode  op;
	union{
		uint8_t r0;
		uint8_t cc;
	} op0; 

	union{
		uint8_t r1;
		uint8_t imm8;
		uint8_t e0;
	} op1;

	bool is_imm;


	Instruction(const Opcode n_op, const uint8_t n_op0, const uint8_t n_is_imm, const uint8_t n_op1)
		: op(n_op), op0(n_op0), op1(n_op1), is_imm(n_is_imm) 
	{}
};

constexpr char val_hex(const uint8_t val)
{
	if(val <= 9)
		return val + '0';
	else
		return val + 'A' - 10;
}

bool error = false;
void print_Error(const std::string& str, const int line_num)
{
	std::cout << "\033[0;31mERROR:\033[0m " << str << "\n";
	std::cout << "\033[0;35m\tline:\033[0m " << line_num << "\n";
	error = true;
}

int main(int argc, char* argv[])
{
	if(argc == 1)
	{
		std::cout << "Not Enough Arguments\n";
		return 1;
	}

	std::ifstream read(argv[1]);

	if(read.is_open() == false)
	{
		std::cout << "File Does Not Exist\n";
		return 2;
	}
	
	std::vector<Instruction> instructions;
	std::vector<Label> labels;
	std::vector<Label> to_fill;

	std::string line;
	
	std::vector<std::string> contents;
	int line_num = 0;
	while(std::getline(read, line))
	{
		line_num++;

		contents.clear();
		std::string cur;

		for(const char c : line)
		{
			if('#' == c
			|| ';' == c)
				break;

			if(' '  == c
			|| ','  == c 
			|| '\t' == c)
			{
				if(cur.size() != 0)
				{
					contents.push_back(std::move(cur));
					cur.clear();
				}
				continue;
			}

			cur += c;
		}
		if(cur.size() != 0)
		{
			contents.push_back(std::move(cur));
			cur.clear();
		}

		if(contents.size() == 0)
			continue;

		if(contents[0].back() == ':')
		{
			if(1 != contents.size())
			{
				print_Error("label should be the only thing on the line", line_num);
				continue;
			}
			
			contents[0].pop_back();
			
			if(contents[0].size() == 0)
			{
				print_Error("label cannot be empty", line_num);
				continue;
			}

			labels.emplace_back(std::move(contents[0]), instructions.size());

			continue;
		}

		Opcode opcode;
		uint8_t op0 = 0;
		uint8_t op1 = 0;
		bool is_imm = true;
		//could be done with state machine or HT
		//and i should consider making a stress test to test performance
			 if("nop" == contents[0]) opcode = Opcode::NOP;
		else if("hlt" == contents[0]) opcode = Opcode::HLT;

		else if("mov" == contents[0]) opcode = Opcode::MOV;
		else if("rdm" == contents[0]) opcode = Opcode::RDM;
		else if("wrm" == contents[0]) opcode = Opcode::WRM;

		else if("rdx" == contents[0]) opcode = Opcode::RDX;
		else if("wrx" == contents[0]) opcode = Opcode::WRX;
		else if("psh" == contents[0]) opcode = Opcode::PSH;
		else if("pop" == contents[0]) opcode = Opcode::POP;
		else if("mul" == contents[0]) opcode = Opcode::MUL;
		else if("cmp" == contents[0]) opcode = Opcode::CMP;

		else if("tst" == contents[0]) opcode = Opcode::TST;
		else if("jmp" == contents[0]) opcode = Opcode::JMP;
		else if("cal" == contents[0]) opcode = Opcode::CAL;
		else if("ret" == contents[0]) opcode = Opcode::RET;

		else if("add" == contents[0]) opcode = Opcode::ADD;
		else if("sub" == contents[0]) opcode = Opcode::SUB;
		else if("not" == contents[0]) opcode = Opcode::NOT;
		else if("and" == contents[0]) opcode = Opcode::AND;
		else if("orr" == contents[0]) opcode = Opcode::ORR;
		else if("xor" == contents[0]) opcode = Opcode::XOR;
		else if("sll" == contents[0]) opcode = Opcode::SLL;
		else if("slr" == contents[0]) opcode = Opcode::SLR;

		else
		{
			print_Error("invalid instruction", line_num);
			continue;
		}

		
		if(1 == contents.size())
		{
			if(Opcode::NOP == opcode)
			{
				goto place_instr;
			}
			if(Opcode::HLT == opcode
			|| Opcode::RET == opcode)
			{
				op0 = Flags::all; 
				goto place_instr;
			}

			print_Error("Not enough arguments", line_num);
			continue;
		}

		if(2 == contents.size())
		{
			if(! (Opcode::HLT == opcode
			   || Opcode::RET == opcode
			   || Opcode::PSH == opcode
			   || Opcode::POP == opcode))
			{
				print_Error("Not enough arguments", line_num);
				continue;
			}
		}

		if(contents.size() > 3)
		{
			print_Error("Too many arguments", line_num);
			continue;
		}

		//parsing first argument
		if('r' == contents[1][0]
		|| 'R' == contents[1][0])
		{
			if(contents[1].size() != 2
			|| contents[1][1] < '0'
			|| contents[1][1] > '7')
			{
				print_Error("Invalid register specifier", line_num);
				continue;
			}

			op0 = contents[1][1] - '0';
		}
		else
		{
			if("IP"s == contents[1])
			{
				op0 = 0;
				goto parse_2nd;
			}
			if("SP"s == contents[1])
			{
				op0 = 1;
				goto parse_2nd;
			}
			if("LR"s == contents[1])
			{
				op0 = 2;
				goto parse_2nd;
			}
			if("UI"s == contents[1])
			{
				op0 = 4;
				goto parse_2nd;
			}
			if("FL"s == contents[1])
			{
				op0 = 5;
				goto parse_2nd;
			}
			if("CF"s == contents[1])
			{
				op0 = 7;
				goto parse_2nd;
			}

			uint8_t flags = 0x0;
			for(const char c : contents[1])
			{
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
					print_Error("Invalid register or condition code specifier", line_num);
					continue;
				}
			}

			op0 = flags;
		}

parse_2nd:
		if(2 == contents.size())
			goto place_instr;

		
		if('r' == contents[2][0]
		|| 'R' == contents[2][0])
		{

			is_imm = false;
			if(contents[2].size() != 2
			|| contents[2][1] < '0'
			|| contents[2][1] > '7')
			{
				print_Error("Invalid register specifier", line_num);
				continue;
			}

			op1 = contents[2][1] - '0';
		}
		else
		{
			if('0' > contents[2][0]
			|| '9' < contents[2][0])
			{
				if("IP"s == contents[2])
				{
					op1 = 0;
					is_imm = false;
					goto place_instr;
				}
				if("SP"s == contents[2])
				{
					op1 = 1;
					is_imm = false;
					goto place_instr;
				}
				if("LR"s == contents[2])
				{
					op1 = 2;
					is_imm = false;
					goto place_instr;
				}
				if("UI"s == contents[2])
				{
					op1 = 4;
					is_imm = false;
					goto place_instr;
				}
				if("FL"s == contents[2])
				{
					op1 = 5;
					is_imm = false;
					goto place_instr;
				}
				if("CF"s == contents[2])
				{
					op1 = 7;
					is_imm = false;
					goto place_instr;
				}


				to_fill.emplace_back(contents[2], instructions.size());
				to_fill.back().line = line_num;
				goto place_instr;
			}

			uint16_t num = 0;
			for(const char c : contents[2])
			{
				if('0' > c
				|| '9' < c)
				{
					print_Error("Not a valid number", line_num);
					goto next_instr;
				}

				num = num * 10 + c - '0';
			}

			if(num > 0xFF)
			{
				print_Error("Constant too big to fit into 1B", line_num);
				continue;
			}

			op1 = static_cast<uint8_t>(num);
		}


place_instr:
		instructions.emplace_back(opcode, op0, is_imm, op1);
next_instr:
		continue;
	}


	std::ofstream write_debug("debug.txt");
	for(const auto& label : labels)
	{
		write_debug << label.name << ' ' << label.position << '\n';
	}


	//to be changed
	for(const auto& label_tf : to_fill)
	{
		for(const auto& label : labels)
		{
			if(label_tf.name == label.name)
			{
				instructions[label_tf.position].op1.imm8 = label.position;
				goto cont;
			}
		}
		print_Error(label_tf.name + " not defined", label_tf.line);
cont:
		continue;
	}



	if(error)
		return 0;

	std::ofstream write("out.bin");

	std::string out(instructions.size() * 5, '0');

	for(unsigned int i = 0; i < instructions.size(); i++)
	{
		const auto& instr = instructions[i];
		uint16_t val;
		if(instr.is_imm)
			val = static_cast<uint16_t>((opval(instr.op)) << 11)
			    | static_cast<uint16_t>((instr.op0.r0   ) <<  8)
			    | static_cast<uint16_t>((instr.op1.imm8 ) <<  0)
			    ;
		else
			val = static_cast<uint16_t>((instr.op0.r0   ) <<  8)
			    | static_cast<uint16_t>((instr.op1.r1   ) <<  5)
			    | static_cast<uint16_t>((opval(instr.op)) <<  0)
			    ;
		

		out[i * 5 + 0] = val_hex((val >> 12) & 0xF);
		out[i * 5 + 1] = val_hex((val >>  8) & 0xF);
		out[i * 5 + 2] = val_hex((val >>  4) & 0xF);
		out[i * 5 + 3] = val_hex((val >>  0) & 0xF);
		out[i * 5 + 4] = '\n'; 

	}

//	std::cout << out << '\n';
	write << out;


}
