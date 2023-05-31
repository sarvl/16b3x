//TODO
//fix the sim command 
//add help

#include <iostream>
#include <fstream>

#include <string>
#include <vector>

#include <unordered_map>

#define DEBUG_PRINT(x)   if(debug)   std::cout << x
#define DEBUG_WAIT       if(debug)   std::cin.get()
#define DEBUG_READ(x)    if(debug)   std::getline(x)

#define VERBOSE_PRINT(x) if(verbose) std::cout << x 

#define SET_FLAGS(x)                         \
			if((x) > 0)                      \
				flags_register = Flags::G;   \
			else if((x) < 0)                 \
				flags_register = Flags::L;   \
			else                             \
				flags_register = Flags::E;   \
			;

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

namespace Flags{
	enum Flags : uint8_t{
		 L = 0b100,
		 E = 0b010,
		 G = 0b001
	};


	char to_char(const Flags fl)
	{
		if(fl == Flags::L)
			return 'L';
		if(fl == Flags::E)
			return 'E';
		if(fl == Flags::G)
			return 'G';

		return 'I';
	}
};

namespace Feature_Flags{
	enum FFlags : uint16_t{
		M = 0b0000'0000'0000'0001
	};
};

struct Instruction{
	Opcode  op;
	union{
		uint8_t r0;
		uint8_t ccc;
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

constexpr uint32_t hex_val(const char hex)
{
	if(hex <= '9')
		return hex - '0';
	else
		return hex - 'A' + 10;
}



uint16_t ext[8];
uint16_t reg[8];
uint8_t  mem[0xFFFF + 1];

int main(int argc, char* argv[])
{
	if(2 >  argc)
	{
		std::cout << "not enough arguments\n";
		return 1;
	}

	bool debug   = false;
	bool verbose = false;
	if('n' == argv[1][0])
	{}
	else if('d' == argv[1][0])
	{
		debug   = true;
	}
	else if('v' == argv[1][0])
	{
		verbose = true;
	}
	else if('a' == argv[1][0])
	{
		debug   = true;
		verbose = true;
	}

	std::ifstream file(argv[2]);

	if(false == file.is_open())
	{
		std::cout << "file could not have been open\n";
		return 2;
	}

	std::unordered_map<uint16_t, std::string> debug_info_labels;
	if(debug)
	{
		std::ifstream debug_file;
		
		if(4 <= argc)
		{
			debug_file.open(argv[3]);

			if(false == debug_file.is_open())
			{
				std::cout << "debug file could not have been open\n";
				return 3;
			}

		
			std::string line;
			while(std::getline(debug_file, line))
			{
				int str_end = 0;
				int instr = 0;
				while(' ' != line[str_end])
					str_end++;

				for(unsigned int i = str_end + 1; i < line.size(); i++)
				{
					instr *= 10;
					instr += line[i] - '0';
				}

				debug_info_labels[static_cast<uint16_t>(instr)] = line.substr(0, str_end);
			}

		}
	};

	std::vector<Instruction> instructions;
	std::string line;
	while(std::getline(file, line))
	{
		const uint16_t val = (hex_val(line[0]) << 12)
		                   | (hex_val(line[1]) <<  8)
		                   | (hex_val(line[2]) <<  4)
		                   | (hex_val(line[3]) <<  0);

		Opcode  opc;
		uint8_t op0;
		uint8_t op1;
		bool r_format = false;
		
		op0 = (val & 0x0700) >> 8;
		
		//if first 5 bits are 0
		if(0 == (val & 0xF800))
		{
			r_format = true;

			opc = static_cast<Opcode>(val & 0x001F);
			op1 = (val >> 5) & 0x7;
		}
		else
		{
			opc = static_cast<Opcode>(val >> 11);
			op1 = val & 0x00FF;
		}


		instructions.emplace_back(opc, op0, ! r_format, op1);
	}


	uint16_t& instruction_pointer = ext[0];
	uint16_t& stack_pointer       = ext[1];
	uint16_t& link_register       = ext[2];

	uint16_t& upper_immiediate    = ext[4];
	uint16_t& flags_register      = ext[5];
	
	uint16_t& feature_register    = ext[7];

	feature_register = Feature_Flags::M;

	uint32_t cycle_count = 0;

	flags_register = 0x1;
	stack_pointer = 0x0;

	bool run = false;
	while(true)
	{
		cycle_count++;
		if(debug)
		{
			if(false == run) std::getline(std::cin, line);
			if("exit" == line) goto end;
			if(0 != line.size()) run = true;
		}

		const auto& instr = instructions[instruction_pointer >> 1];

		uint16_t& reg0 = reg[instr.op0.r0];
		
		const uint16_t ccc = instr.op0.ccc;
		
		uint16_t second;
		if(instr.is_imm)
			second = (upper_immiediate << 8) | instr.op1.imm8;	
		else
			second = reg[instr.op1.r1];

		upper_immiediate = 0;
	
		DEBUG_PRINT((instruction_pointer >> 1) << ' ' << reg0 << ' ' << second << ' ');

		instruction_pointer += 2;

		switch(instr.op)
		{
		case Opcode::NOP:
		{
			DEBUG_PRINT("NOP\n");
			break;
		}
		case Opcode::HLT: 
		{
			DEBUG_PRINT("HLT\n");
			if(ccc & flags_register)
			{
				VERBOSE_PRINT("MACHINE HALTED\n");
				goto end;
			}
			VERBOSE_PRINT("HALT DID NOT OCCUR\n");
			break;
		}
		//case Opcode::
		{
		//	break;
		}
		//case Opcode::
		{
		//	break;
		}
		//case Opcode::
		{
		//	break;
		}
		case Opcode::MOV: 
		{
			DEBUG_PRINT("MOV\n");
			reg0 = second; 
			
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << second << "\n");
			break;
		}
		case Opcode::RDM: 
		{
			DEBUG_PRINT("RDM\n");
			const uint16_t MSB = mem[second + 0];
			const uint16_t LSB = mem[second + 1];

			reg0 = MSB << 8
			     | LSB << 0;
			
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << "\n"); 

			break;
		}
		case Opcode::WRM: 
		{
			DEBUG_PRINT("WRM\n");
			
			const uint8_t MSB = static_cast<uint8_t>(reg0 >> 8);
			const uint8_t LSB = static_cast<uint8_t>(reg0 >> 0);

			mem[second + 0] = MSB;
			mem[second + 1] = LSB;
			
			VERBOSE_PRINT("M[" << second + 0 << "] <= " << +MSB << "\n");
			VERBOSE_PRINT("M[" << second + 1 << "] <= " << +LSB << "\n");

			break;
		}
		//case Opcode::
		{
		//	break;
		}
		//case Opcode::
		{
		//	break;
		}
		//case Opcode::
		{
		//	break;
		}
		//case Opcode::
		{
		//	break;
		}
		case Opcode::RDX: 
		{
			DEBUG_PRINT("RDX\n");
			reg0 = ext[instr.op1.r1];
			break;
		}
		case Opcode::WRX: 
		{
			DEBUG_PRINT("WRX\n");
			if(instr.op0.r0 != 7) //dont write to feature flags
				ext[instr.op0.r0] = second;
			break;
		}
		case Opcode::PSH: 
		{
			DEBUG_PRINT("PSH\n");
			stack_pointer -= 2;

			uint8_t f = static_cast<uint8_t>(reg0 >> 8);
			uint8_t s = static_cast<uint8_t>(reg0 >> 0);
			
			mem[stack_pointer + 1] = f;
			mem[stack_pointer + 0] = s;

			VERBOSE_PRINT("PUSH " << reg0 << " FROM R" << +instr.op0.r0 << "\n");

			break;
		}
		case Opcode::POP: 
		{
			DEBUG_PRINT("POP\n");
			
			uint16_t f = mem[stack_pointer + 1];
			uint16_t s = mem[stack_pointer + 0];

			reg0 = f << 8 
			     | s << 0;

			stack_pointer += 2;
			
			VERBOSE_PRINT("POP " << reg0 << " TO R" << +instr.op0.r0 << "\n");
			break;
		}
		case Opcode::MUL:
		{
			DEBUG_PRINT("MUL\n");
			const int16_t temp = reg0 * second;
			
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " * " << second << "  (" << static_cast<uint16_t>(reg0 * second) << ")\n");
			
			SET_FLAGS(temp);
			reg0 = temp;
			

			break;
		}
		case Opcode::CMP: 
		{
			DEBUG_PRINT("CMP\n");
			const int32_t temp = static_cast<uint32_t>(reg0) - second;

			VERBOSE_PRINT("R" << +instr.op0.r0 << " - " << second << "\n");
			
			SET_FLAGS(temp);

			VERBOSE_PRINT("FL <= ");
			VERBOSE_PRINT(Flags::to_char(static_cast<Flags::Flags>(flags_register)) << "\n");

			break;
		}
		//case Opcode::
		{
		//	break;
		}
		case Opcode::TST: 
		{
			DEBUG_PRINT("TST\n");
			const int16_t temp = reg0 & second;
			VERBOSE_PRINT("R" << +instr.op0.r0 << " & " << second << "\n");
			
			SET_FLAGS(temp);

			VERBOSE_PRINT("FL <= ");
			VERBOSE_PRINT(Flags::to_char(static_cast<Flags::Flags>(flags_register)) << "\n");
			break;
		}
		case Opcode::JMP: 
		{
			DEBUG_PRINT("JMP\n");

			if(verbose)
			{
				const auto& fnd = debug_info_labels.find(second);
				if(debug_info_labels.end() != fnd)
				{   VERBOSE_PRINT("JMP TO " << fnd->second);}
				else
				{	VERBOSE_PRINT("JMP TO " << second);     }
			}

			if(flags_register & ccc)
			{
				instruction_pointer = second << 1;
				if(debug)
				{
					const auto& fnd = debug_info_labels.find(second);
					if(debug_info_labels.end() != fnd
					&& fnd->second == line)
						run = false;
				}

				VERBOSE_PRINT("\n");
				continue;
			}
			
			VERBOSE_PRINT(" DID NOT OCCUR\n");	
			break;
		}
		case Opcode::CAL: 
		{
			DEBUG_PRINT("CAL\n");
			
			if(verbose)
			{
				const auto& fnd = debug_info_labels.find(second);
				if(debug_info_labels.end() != fnd)
				{	VERBOSE_PRINT("CAL TO " << fnd->second);}
				else
				{	VERBOSE_PRINT("CAL TO " << second);     }
			}

			if(flags_register & ccc)
			{
				link_register = instruction_pointer;
				instruction_pointer = second << 1;
				
				if(debug)
				{
					const auto& fnd = debug_info_labels.find(second);
					if(debug_info_labels.end() != fnd
					&& fnd->second == line)
						run = false;
				}
				VERBOSE_PRINT("\n");
				continue;
			}

			VERBOSE_PRINT(" DID NOT OCCUR\n");

			break;
		}
		case Opcode::RET: 
		{
			DEBUG_PRINT("RET\n");

			VERBOSE_PRINT("RET TO " << link_register);

			if(flags_register & ccc)
			{
				instruction_pointer = link_register;

				VERBOSE_PRINT("\n");
				if(debug)
					run = false;
				
				continue;
			}

			VERBOSE_PRINT(" DID NOT OCCUR\n");
			break;
		}
		//case Opcode::
		{
		//	break;
		}
		case Opcode::ADD: 
		{
			DEBUG_PRINT("ADD\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " + " << second << "  (" << reg0 + second << ")\n");
			
			const int16_t temp = reg0 + second;
			reg0 += second; 

			SET_FLAGS(temp);


			break;
		}
		case Opcode::SUB: 
		{
			DEBUG_PRINT("SUB\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " - " << second << "  (" << reg0 - second << ")\n");

			const int16_t temp = reg0 - second;
			reg0 -= second; 
			
			SET_FLAGS(temp);
			break;
		}
		case Opcode::NOT: 
		{
			DEBUG_PRINT("NOT\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <=  ~ " << second << "  (" << ~second << ")\n");
			reg0 = ~second; 
			const int16_t temp = reg0;
			SET_FLAGS(temp);
			break;
		}
		case Opcode::AND: 
		{
			DEBUG_PRINT("AND\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " & " << second << "  (" << (reg0 & second) << ")\n");
			reg0 &= second; 
			const int16_t temp = reg0;
			SET_FLAGS(temp);
			break;
		}
		case Opcode::ORR: 
		{
			DEBUG_PRINT("ORR\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " | " << second << "  (" << (reg0 | second) << ")\n");
			reg0 |= second; 
			const int16_t temp = reg0;
			SET_FLAGS(temp);
			break;
		}
		case Opcode::XOR: 
		{
			DEBUG_PRINT("XOR\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " ^ " << second << "  (" << (reg0 ^ second) << ")\n");
			reg0 ^= second; 
			const int16_t temp = reg0;
			SET_FLAGS(temp);
			break;
		}
		case Opcode::SLL: 
		{
			DEBUG_PRINT("SLL\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " << " << second << "  (" << (reg0 << second) << ")\n");
			reg0 <<= second; 
			break;
		}
		case Opcode::SLR: 
		{
			DEBUG_PRINT("SLR\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " >> " << second << "  (" << (reg0 >> second) << ")\n");
			reg0 >>= second; 
			break;
		}
		}
	}
end:
	
	DEBUG_PRINT("\n");


	for(int i = 0; i < 8; i++)
		std::cout << "reg " << i << ' ' << reg[i] << '\n';


	const uint16_t MSB = mem[80 + 0];
	const uint16_t LSB = mem[80 + 1];

	std::cout << "Exit Mem:    " << ((MSB << 8) | LSB) << '\n';
	std::cout << "Cycle count: " << cycle_count << '\n';

	return 0;
}
