#include <iostream>
#include <fstream>
#include <iomanip>

#include <string>

#include <unordered_map>

#include <cstdint>

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
				flags_register = Flags::E;   

#define PAD_ZERO(x, y) std::setfill('0') << std::setw(x) << (y) 
			

void input_handle_args(
	int   argc       ,
	char* argv[]     ,
	bool& print_help ,
	bool& debug      ,
	bool& verbose    ,
	bool& long_input ,
	bool& dump_mem   ,
	bool& dump_reg   ,
	bool& symbols    ,
	bool& perf       ,
	std::string& code,
	std::string& syms 
	);

int input_read_syms(
	std::unordered_map<uint16_t, std::string>& symbols,	
	std::string const&                         file_name
	);
int input_read_instr(
	uint8_t*           mem       ,
	bool*              modified  ,
	bool        const  long_input,
	std::string const& file_name
	);

void output_print_help();


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


	constexpr char to_char(const Flags fl)
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

Instruction decode(uint16_t const val)
{
	Opcode  opc;
	uint8_t op0;
	uint8_t op1;
	bool i_format = true;
	
	op0 = (val & 0x0700) >> 8;
	
	//if first 5 bits are 0
	if(0 == (val & 0xF800))
	{
		i_format = false;

		opc = static_cast<Opcode>(val & 0x001F);
		op1 = (val >> 5) & 0x7;
	}
	else
	{
		opc = static_cast<Opcode>(val >> 11);
		op1 = val & 0x00FF;
	}

	return Instruction(opc, op0, i_format, op1);
}


constexpr const char* ext_reg(const uint8_t id)
{
	switch(id)
	{
	case 0:
		return "IP";
	case 1:
		return "SP";
	case 2:
		return "LR";
	case 3:
		return "INVALID";
	case 4:
		return "UI";
	case 5:
		return "FL";
	case 6:
		return "INVALID";
	case 7:
		return "CF";
	}
	return "INVALID";
}


uint16_t ext[8];
uint16_t reg[8];
uint8_t  mem[0x10000];
bool     modified[0x10000];

int main(int argc, char* argv[])
{
	bool print_help = false;
	bool debug      = false;
	bool verbose    = false;
	bool long_input = false;
	bool dump_mem   = false;
	bool dump_reg   = false;
	bool symbols_rd = false;
	bool perf       = false;
	//to be implemented:
	//bool perf_oooe  = false; 

	std::string file_name_code;
	std::string file_name_syms;
	std::unordered_map<uint16_t, std::string> symbols;	
	std::string line;

	//extracted to another file to reduce clutter here
	input_handle_args(argc, argv    ,
	                  print_help    ,
	                  debug         ,
	                  verbose       ,
	                  long_input    ,
	                  dump_mem      ,
	                  dump_reg      ,
	                  symbols_rd    ,
	                  perf          ,
					  file_name_code,
					  file_name_syms);

	if(print_help)
	{
		output_print_help();
		return 0;
	}
	
	if(0 == file_name_code.size())
	{
		std::cout << "ERROR: not enough arguments\n";
		return 1;
	}

	if(0 != input_read_instr(&mem[0], &modified[0], long_input, file_name_code))
	{
		std::cout << "ERROR: could not open file with program\n";
		return 2;
	}
	if(symbols_rd)
		if(0 != input_read_syms(symbols, file_name_syms))
		{
			std::cout << "ERROR: could not open file with debug symbols\n";
		}
	
	uint16_t& instruction_pointer = ext[0];
	uint16_t& stack_pointer       = ext[1];
	uint16_t& link_register       = ext[2];

	uint16_t& upper_immiediate    = ext[4];
	uint16_t& flags_register      = ext[5];
	
	uint16_t& feature_register    = ext[7];

	feature_register = Feature_Flags::M;


	uint32_t instruction_count = 0;
	uint32_t memory_references = 0;
	uint32_t stack_operations  = 0;
	uint32_t branches          = 0;
	uint32_t branches_taken    = 0;
	uint32_t arithmetic        = 0;

	flags_register = 0x1;
	stack_pointer = 0x0;

	bool run = false;
	while(true)
	{
		instruction_count++;
		if(debug)
		{
			if(false  == run) std::getline(std::cin, line);
			if("exit" == line) goto end;
			if("p r"  == line)
			{
				std::cout << "INTERNAL\n";
				for(int i = 0; i <= 7; i++)
					std::cout << "\tR" << i << ": " << reg[i] << '\n';
				std::cout << "EXTERNAL\n";
				for(int i = 0; i <= 7; i++)
					std::cout << "\tE" << i << ": " << ext[i] << '\n';

				line.clear();
			}
			if(0 != line.size()) run = true;
		}


		const uint16_t instr_val = (static_cast<uint16_t>(mem[(2 * instruction_pointer + 0)&0xFFFF]) << 8)
		                         |  static_cast<uint16_t>(mem[(2 * instruction_pointer + 1)&0xFFFF]);
		const auto& instr = decode(instr_val);

		uint16_t& reg0 = reg[instr.op0.r0];
		
		const uint16_t ccc = instr.op0.ccc;
		
		const uint16_t ui_saved = upper_immiediate;
		uint16_t second;
		if(instr.is_imm)
			second = (ui_saved << 8) | instr.op1.imm8;	
		else
			second = reg[instr.op1.r1];

		upper_immiediate = 0;
	
		DEBUG_PRINT((instruction_pointer) << ' ' << reg0 << ' ' << second << ' ');

		instruction_pointer++;

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
			memory_references++;

			DEBUG_PRINT("RDM\n");
			const uint16_t MSB = mem[second + 0];
			const uint16_t LSB = mem[second + 1];

			reg0 = MSB << 8
			     | LSB << 0;
			
			modified[second + 1] = true;
			modified[second + 0] = true;
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << "\n"); 

			break;
		}
		case Opcode::WRM: 
		{
			memory_references++;

			DEBUG_PRINT("WRM\n");
			
			const uint8_t MSB = static_cast<uint8_t>(reg0 >> 8);
			const uint8_t LSB = static_cast<uint8_t>(reg0 >> 0);

			mem[second + 0] = MSB;
			mem[second + 1] = LSB;
			
			modified[second + 1] = true;
			modified[second + 0] = true;
			
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
			if(4 == instr.op1.r1) //UI
			{
				reg0 = ui_saved;
				VERBOSE_PRINT("R" << +instr.op0.r0 << " <= UI (" << reg0 << ")\n");
			}
			else
			{
				reg0 = ext[instr.op1.r1];
				VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << ext_reg(instr.op1.r1) << " (" << reg0 << ")\n");
			}
			break;
		}
		case Opcode::WRX: 
		{
			DEBUG_PRINT("WRX\n");
			if(instr.op0.r0 != 7) //dont write to feature flags
			{
				ext[instr.op0.r0] = second;
				VERBOSE_PRINT(ext_reg(instr.op0.r0) << " <= " << second << "\n");
			}
			break;
		}
		case Opcode::PSH: 
		{
			memory_references++;
			stack_operations++;

			DEBUG_PRINT("PSH\n");
			stack_pointer -= 2;

			uint8_t f = static_cast<uint8_t>(reg0 >> 8);
			uint8_t s = static_cast<uint8_t>(reg0 >> 0);
			
			mem[stack_pointer + 0] = f;
			mem[stack_pointer + 1] = s;
			
			modified[stack_pointer + 1] = true;
			modified[stack_pointer + 0] = true;

			VERBOSE_PRINT("PUSH " << reg0 << " FROM R" << +instr.op0.r0 << "\n");

			break;
		}
		case Opcode::POP: 
		{
			memory_references++;
			stack_operations++;

			DEBUG_PRINT("POP\n");
			
			uint16_t f = mem[stack_pointer + 0];
			uint16_t s = mem[stack_pointer + 1];

			modified[stack_pointer + 1] = true;
			modified[stack_pointer + 0] = true;

			reg0 = f << 8 
			     | s << 0;

			stack_pointer += 2;
			
			VERBOSE_PRINT("POP " << reg0 << " TO R" << +instr.op0.r0 << "\n");
			break;
		}
		case Opcode::MUL:
		{
			arithmetic++;


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
			branches++;

			DEBUG_PRINT("JMP\n");

			if(verbose)
			{
				const auto& fnd = symbols.find(second);
				if(symbols.end() != fnd)
				{   VERBOSE_PRINT("JMP TO " << fnd->second);}
				else
				{	VERBOSE_PRINT("JMP TO " << second);     }
			}

			if(flags_register & ccc)
			{
				branches_taken++;
				instruction_pointer = second;
				if(debug)
				{
					const auto& fnd = symbols.find(second);
					if(symbols.end() != fnd
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
			branches++;
			DEBUG_PRINT("CAL\n");
			
			if(verbose)
			{
				const auto& fnd = symbols.find(second);
				if(symbols.end() != fnd)
				{	VERBOSE_PRINT("CAL TO " << fnd->second);}
				else
				{	VERBOSE_PRINT("CAL TO " << second);     }
			}

			if(flags_register & ccc)
			{
				branches_taken++;
				link_register = instruction_pointer;
				instruction_pointer = second;
				
				if(debug)
				{
					const auto& fnd = symbols.find(second);
					if(symbols.end() != fnd
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
			branches++;
			DEBUG_PRINT("RET\n");

			VERBOSE_PRINT("RET TO " << link_register);

			if(flags_register & ccc)
			{
				branches_taken++;
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
			arithmetic++;

			DEBUG_PRINT("ADD\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " + " << second << "  (" << reg0 + second << ")\n");
			
			const int16_t temp = reg0 + second;
			reg0 += second; 

			SET_FLAGS(temp);


			break;
		}
		case Opcode::SUB: 
		{
			arithmetic++;

			DEBUG_PRINT("SUB\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " - " << second << "  (" << reg0 - second << ")\n");

			const int16_t temp = reg0 - second;
			reg0 -= second; 
			
			SET_FLAGS(temp);
			break;
		}
		case Opcode::NOT: 
		{
			arithmetic++;

			DEBUG_PRINT("NOT\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <=  ~ " << second << "  (" << ~second << ")\n");
			reg0 = ~second; 
			const int16_t temp = reg0;
			SET_FLAGS(temp);
			break;
		}
		case Opcode::AND: 
		{
			arithmetic++;

			DEBUG_PRINT("AND\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " & " << second << "  (" << (reg0 & second) << ")\n");
			reg0 &= second; 
			const int16_t temp = reg0;
			SET_FLAGS(temp);
			break;
		}
		case Opcode::ORR: 
		{
			arithmetic++;

			DEBUG_PRINT("ORR\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " | " << second << "  (" << (reg0 | second) << ")\n");
			reg0 |= second; 
			const int16_t temp = reg0;
			SET_FLAGS(temp);
			break;
		}
		case Opcode::XOR: 
		{
			arithmetic++;

			DEBUG_PRINT("XOR\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " ^ " << second << "  (" << (reg0 ^ second) << ")\n");
			reg0 ^= second; 
			const int16_t temp = reg0;
			SET_FLAGS(temp);
			break;
		}
		case Opcode::SLL: 
		{
			arithmetic++;

			DEBUG_PRINT("SLL\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " << " << second << "  (" << static_cast<uint16_t>(reg0 << second) << ")\n");
			reg0 <<= (second & 0b1111); 
			break;
		}
		case Opcode::SLR: 
		{
			arithmetic++;

			DEBUG_PRINT("SLR\n");
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << " >> " << second << "  (" << (reg0 >> second) << ")\n");
			reg0 >>= (second & 0b1111); 
			break;
		}
		}
	}
end:
	
	DEBUG_PRINT("\n");

	if(dump_reg)
		for(int i = 0; i < 8; i++)
			std::cout << "reg " << i << ' ' << reg[i] << '\n';

	//memdump
	if(dump_mem)
	{
		std::ofstream dump("dump.txt");
		for(int i = 0; i < 0x10000; /*end of loop*/)
		{
			if(modified[i])
				dump << std::hex << std::uppercase << PAD_ZERO(2, +mem[i]); 
			else
				dump << "__";
		
			i++;
			if(0 == i % 4)
				dump << '\n';
		}
		dump.close();
	}
	if(perf)
	{
		std::cout << "Instruction Count: " << instruction_count << '\n';
		std::cout << "Memory References: " << memory_references << '\n';
		std::cout << "Stack Operations : " << stack_operations  << '\n'; 
		std::cout << "Branches         : " << branches          << '\n'; 
		std::cout << "Branches Taken   : " << branches_taken    << '\n'; 
		std::cout << "Arithmetic       : " << arithmetic        << '\n'; 
		std::cout << '\n';
		std::cout << "Approx. time on simple implementation  : " << instruction_count + memory_references                  << " cycles\n";
		std::cout << "Approx. time on pipeline implementation: " << instruction_count + memory_references + 2 * branches_taken << " cycles\n";
	}




	return 0;
}
