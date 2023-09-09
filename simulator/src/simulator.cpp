#include <iostream>
#include <fstream>
#include <iomanip>

#include <string>

#include <unordered_map>

#include <cstring> //memset
#include <cstdint>

#define DEBUG_PRINT(x)   if(program_flags & Program_Flags::debug)   std::cout << x
#define DEBUG_WAIT       if(program_flags & Program_Flags::debug)   std::cin.get()
#define DEBUG_READ(x)    if(program_flags & Program_Flags::debug)   std::getline(x)

#define VERBOSE_PRINT(x) if(program_flags & Program_Flags::verbose) std::cout << x 

#define SET_FLAGS(x)                         \
			if((x) > 0)                      \
				flags_register = Flags::G;   \
			else if((x) < 0)                 \
				flags_register = Flags::L;   \
			else                             \
				flags_register = Flags::E;   

#define PAD_ZERO(x, y) std::setfill('0') << std::setw(x) << (y) 



/*
	PERFORMANCE MEASURE PARAMETERSE
*/

// BRANCH PREDICTOR
constexpr int par_bp_bc_count   = 16;
constexpr int par_bp_his_l_size =  4;
constexpr int par_bp_his_g_size =  4;

//DO NOT CHANGE, effect of previous settings
constexpr int par_bp_his_l_and  = par_bp_his_l_size - 1;
constexpr int par_bp_his_g_and  = par_bp_his_g_size - 1;



namespace Program_Flags{
	enum T_Program_Flags : uint32_t{
		none       = 0x0000,
		print_help = 0x0001,
		debug      = 0x0002,
		verbose    = 0x0004,
		long_input = 0x0008,
		dump_mem   = 0x0010,
		dump_reg   = 0x0020,
		symbols    = 0x0040,
		perf       = 0x0080,
		instr      = 0x0100,
		warn       = 0x0200,
	};
};
			

void input_handle_args(
	int   argc       ,
	char* argv[]     ,
	uint32_t& flags  ,
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
	uint32_t program_flags = 0;
	//to be implemented:
	//bool program_flags & Program_Flags::perf_oooe  = false; 

	std::string file_name_code;
	std::string file_name_syms;
	std::unordered_map<uint16_t, std::string> symbols;	
	std::string line;

	//extracted to another file to reduce clutter here
	input_handle_args(argc, argv    ,
	                  program_flags ,
					  file_name_code,
					  file_name_syms);

	if(program_flags & Program_Flags::print_help)
	{
		output_print_help();
		return 0;
	}
	
	if(0 == file_name_code.size())
	{
		std::cout << "ERROR: not enough arguments\n";
		return 1;
	}

	if(0 != input_read_instr(&mem[0], &modified[0], program_flags & Program_Flags::long_input, file_name_code))
	{
		std::cout << "ERROR: could not open file with program\n";
		return 2;
	}
	if(program_flags & Program_Flags::symbols)
		if(0 != input_read_syms(symbols, file_name_syms))
		{
			std::cout << "ERROR: could not open file with debug symbols\n";
		}


	//verify parameters


	
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

	uint32_t instr_ex_count[32];
	std::memset(instr_ex_count, 0, sizeof(uint32_t) * 32); 
	uint8_t bp_1bc_st[par_bp_bc_count];
	uint8_t bp_1bc_sn[par_bp_bc_count];
	uint8_t bp_2bc_st[par_bp_bc_count];
	uint8_t bp_2bc_sn[par_bp_bc_count];
	uint8_t bp_his_1bc_st[par_bp_bc_count][par_bp_his_l_size];
	uint8_t bp_his_1bc_sn[par_bp_bc_count][par_bp_his_l_size];
	uint8_t bp_his_2bc_st[par_bp_bc_count][par_bp_his_l_size];
	uint8_t bp_his_2bc_sn[par_bp_bc_count][par_bp_his_l_size];
	uint8_t bp_g_his_1bc_st[par_bp_his_g_size];
	uint8_t bp_g_his_1bc_sn[par_bp_his_g_size];
	uint8_t bp_g_his_2bc_st[par_bp_his_g_size];
	uint8_t bp_g_his_2bc_sn[par_bp_his_g_size];
	int bp_his = 0;
	int next_bp_his = 0;
	int bp_his_l = 0;
	int bp_his_g = 0;

	uint32_t bp_1bc_st_cor[par_bp_bc_count];
	uint32_t bp_1bc_sn_cor[par_bp_bc_count];
	uint32_t bp_2bc_st_cor[par_bp_bc_count];
	uint32_t bp_2bc_sn_cor[par_bp_bc_count];
	uint32_t bp_his_1bc_st_cor[par_bp_bc_count][par_bp_his_l_size];
	uint32_t bp_his_1bc_sn_cor[par_bp_bc_count][par_bp_his_l_size];
	uint32_t bp_his_2bc_st_cor[par_bp_bc_count][par_bp_his_l_size];
	uint32_t bp_his_2bc_sn_cor[par_bp_bc_count][par_bp_his_l_size];
	uint32_t bp_g_his_1bc_st_cor[par_bp_his_g_size];
	uint32_t bp_g_his_1bc_sn_cor[par_bp_his_g_size];
	uint32_t bp_g_his_2bc_st_cor[par_bp_his_g_size];
	uint32_t bp_g_his_2bc_sn_cor[par_bp_his_g_size];

	uint32_t bp_tr_l_cor = 0;

	std::memset(bp_1bc_st, 0b01, sizeof(uint8_t) * par_bp_bc_count); 
	std::memset(bp_1bc_sn, 0b00, sizeof(uint8_t) * par_bp_bc_count); 
	std::memset(bp_2bc_st, 0b11, sizeof(uint8_t) * par_bp_bc_count); 
	std::memset(bp_2bc_sn, 0b00, sizeof(uint8_t) * par_bp_bc_count); 
	std::memset(bp_his_1bc_st, 0b01, sizeof(uint8_t) * par_bp_bc_count * par_bp_his_l_size); 
	std::memset(bp_his_1bc_sn, 0b00, sizeof(uint8_t) * par_bp_bc_count * par_bp_his_l_size); 
	std::memset(bp_his_2bc_st, 0b11, sizeof(uint8_t) * par_bp_bc_count * par_bp_his_l_size); 
	std::memset(bp_his_2bc_sn, 0b00, sizeof(uint8_t) * par_bp_bc_count * par_bp_his_l_size); 
	std::memset(bp_g_his_1bc_st, 0b01, sizeof(uint8_t) * par_bp_his_g_size); 
	std::memset(bp_g_his_1bc_sn, 0b00, sizeof(uint8_t) * par_bp_his_g_size); 
	std::memset(bp_g_his_2bc_st, 0b11, sizeof(uint8_t) * par_bp_his_g_size); 
	std::memset(bp_g_his_2bc_sn, 0b00, sizeof(uint8_t) * par_bp_his_g_size); 

	std::memset(bp_1bc_st_cor, 0, sizeof(uint32_t) * par_bp_bc_count); 
	std::memset(bp_1bc_sn_cor, 0, sizeof(uint32_t) * par_bp_bc_count); 
	std::memset(bp_2bc_st_cor, 0, sizeof(uint32_t) * par_bp_bc_count); 
	std::memset(bp_2bc_sn_cor, 0, sizeof(uint32_t) * par_bp_bc_count); 
	std::memset(bp_his_1bc_st_cor, 0, sizeof(uint32_t) * par_bp_bc_count * par_bp_his_l_size); 
	std::memset(bp_his_1bc_sn_cor, 0, sizeof(uint32_t) * par_bp_bc_count * par_bp_his_l_size); 
	std::memset(bp_his_2bc_st_cor, 0, sizeof(uint32_t) * par_bp_bc_count * par_bp_his_l_size); 
	std::memset(bp_his_2bc_sn_cor, 0, sizeof(uint32_t) * par_bp_bc_count * par_bp_his_l_size); 
	std::memset(bp_g_his_1bc_st_cor, 0, sizeof(uint32_t) * par_bp_his_g_size); 
	std::memset(bp_g_his_1bc_sn_cor, 0, sizeof(uint32_t) * par_bp_his_g_size); 
	std::memset(bp_g_his_2bc_st_cor, 0, sizeof(uint32_t) * par_bp_his_g_size); 
	std::memset(bp_g_his_2bc_sn_cor, 0, sizeof(uint32_t) * par_bp_his_g_size); 
	

	flags_register = 0x1;

	bool run = false;
	while(true)
	{
		instruction_count++;
		if(program_flags & Program_Flags::debug)
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

		const int bp_index = instruction_pointer & 0xF;
		instr_ex_count[static_cast<int>(instr.op)]++;
		bp_his = next_bp_his;

		bp_his_l = bp_his & par_bp_his_l_and;
		bp_his_g = bp_his & par_bp_his_g_and;
		
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
			const uint16_t MSB = mem[(second + 0) & 0xFFFF];
			const uint16_t LSB = mem[(second + 1) & 0xFFFF];

			reg0 = MSB << 8
			     | LSB << 0;
			
			modified[(second + 1) & 0xFFFF] = true;
			modified[(second + 0) & 0xFFFF] = true;
			VERBOSE_PRINT("R" << +instr.op0.r0 << " <= " << reg0 << "\n"); 

			break;
		}
		case Opcode::WRM: 
		{
			memory_references++;

			DEBUG_PRINT("WRM\n");
			
			const uint8_t MSB = static_cast<uint8_t>(reg0 >> 8);
			const uint8_t LSB = static_cast<uint8_t>(reg0 >> 0);

			mem[(second + 0) & 0xFFFF] = MSB;
			mem[(second + 1) & 0xFFFF] = LSB;
			
			modified[(second + 0) & 0xFFFF] = true;
			modified[(second + 1) & 0xFFFF] = true;
			
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
			bool bp_1bc_st_gt = (bp_1bc_st[bp_index] &  0b1) != 0; 
			bool bp_1bc_sn_gt = (bp_1bc_sn[bp_index] &  0b1) != 0; 
			bool bp_2bc_st_gt = (bp_2bc_st[bp_index] & 0b10) != 0; 
			bool bp_2bc_sn_gt = (bp_2bc_sn[bp_index] & 0b10) != 0; 
			bool bp_his_1bc_st_gt = (bp_his_1bc_st[bp_index][bp_his_l] &  0b1) != 0; 
			bool bp_his_1bc_sn_gt = (bp_his_1bc_sn[bp_index][bp_his_l] &  0b1) != 0; 
			bool bp_his_2bc_st_gt = (bp_his_2bc_st[bp_index][bp_his_l] & 0b10) != 0; 
			bool bp_his_2bc_sn_gt = (bp_his_2bc_sn[bp_index][bp_his_l] & 0b10) != 0; 
			bool bp_g_his_1bc_st_gt = (bp_g_his_1bc_st[bp_his_g] &  0b1) != 0; 
			bool bp_g_his_1bc_sn_gt = (bp_g_his_1bc_sn[bp_his_g] &  0b1) != 0; 
			bool bp_g_his_2bc_st_gt = (bp_g_his_2bc_st[bp_his_g] & 0b10) != 0; 
			bool bp_g_his_2bc_sn_gt = (bp_g_his_2bc_sn[bp_his_g] & 0b10) != 0; 

			bool best_gt = bp_1bc_st_gt;
			uint32_t best_score = bp_1bc_st_cor[bp_index];
			//somehow i should add loop here, somehow
			if(bp_1bc_sn_cor[bp_index] > best_score)
			{ best_gt = bp_1bc_sn_gt; best_score = bp_1bc_sn_cor[bp_index]; }
			if(bp_2bc_st_cor[bp_index] > best_score)
			{ best_gt = bp_2bc_st_gt; best_score = bp_2bc_st_cor[bp_index]; }
			if(bp_2bc_sn_cor[bp_index] > best_score)
			{ best_gt = bp_2bc_sn_gt; best_score = bp_2bc_sn_cor[bp_index]; }


			if(bp_his_1bc_st_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_1bc_st_gt; best_score = bp_his_1bc_st_cor[bp_index][bp_his_l]; }
			if(bp_his_1bc_sn_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_1bc_sn_gt; best_score = bp_his_1bc_sn_cor[bp_index][bp_his_l]; }
			if(bp_his_2bc_st_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_2bc_st_gt; best_score = bp_his_2bc_st_cor[bp_index][bp_his_l]; }
			if(bp_his_2bc_sn_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_2bc_sn_gt; best_score = bp_his_2bc_sn_cor[bp_index][bp_his_l]; }

			if(bp_g_his_1bc_st_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_1bc_st_gt; best_score = bp_g_his_1bc_st_cor[bp_his_g]; }
			if(bp_g_his_1bc_sn_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_1bc_sn_gt; best_score = bp_g_his_1bc_sn_cor[bp_his_g]; }
			if(bp_g_his_2bc_st_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_2bc_st_gt; best_score = bp_g_his_2bc_st_cor[bp_his_g]; }
			if(bp_g_his_2bc_sn_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_2bc_sn_gt; best_score = bp_g_his_2bc_sn_cor[bp_his_g]; }


			branches++;

			DEBUG_PRINT("JMP\n");

			if(program_flags & Program_Flags::verbose)
			{
				const auto& fnd = symbols.find(second);
				if(symbols.end() != fnd)
				{   VERBOSE_PRINT("JMP TO " << fnd->second);}
				else
				{	VERBOSE_PRINT("JMP TO " << second);     }
			}

			next_bp_his <<= 1;
			if(flags_register & ccc)
			{
				next_bp_his |= 0b1;
				if(true == bp_1bc_st_gt)
					bp_1bc_st_cor[bp_index]++;
				if(true == bp_1bc_sn_gt)
					bp_1bc_sn_cor[bp_index]++;
				if(true == bp_2bc_st_gt)
					bp_2bc_st_cor[bp_index]++;
				if(true == bp_2bc_sn_gt)
					bp_2bc_sn_cor[bp_index]++;

				if(true == bp_his_1bc_st_gt)
					bp_his_1bc_st_cor[bp_index][bp_his_l]++;
				if(true == bp_his_1bc_sn_gt)
					bp_his_1bc_sn_cor[bp_index][bp_his_l]++;
				if(true == bp_his_2bc_st_gt)
					bp_his_2bc_st_cor[bp_index][bp_his_l]++;
				if(true == bp_his_2bc_sn_gt)
					bp_his_2bc_sn_cor[bp_index][bp_his_l]++;

				if(true == bp_g_his_1bc_st_gt)
					bp_g_his_1bc_st_cor[bp_his_g]++;
				if(true == bp_g_his_1bc_sn_gt)
					bp_g_his_1bc_sn_cor[bp_his_g]++;
				if(true == bp_g_his_2bc_st_gt)
					bp_g_his_2bc_st_cor[bp_his_g]++;
				if(true == bp_g_his_2bc_sn_gt)
					bp_g_his_2bc_sn_cor[bp_his_g]++;

				if(true == best_gt)
					bp_tr_l_cor++;


				bp_1bc_st[bp_index] = 0b1;
				bp_1bc_sn[bp_index] = 0b1;
				bp_2bc_st[bp_index]++;
				bp_2bc_sn[bp_index]++;

				if(bp_2bc_st[bp_index] > 0b11)
					bp_2bc_st[bp_index] = 0b11;
				if(bp_2bc_sn[bp_index] > 0b11)
					bp_2bc_sn[bp_index] = 0b11;

				bp_his_1bc_st[bp_index][bp_his_l] = 0b1;
				bp_his_1bc_sn[bp_index][bp_his_l] = 0b1;
				bp_his_2bc_st[bp_index][bp_his_l]++;
				bp_his_2bc_sn[bp_index][bp_his_l]++;

				if(bp_his_2bc_st[bp_index][bp_his_l] > 0b11)
					bp_his_2bc_st[bp_index][bp_his_l] = 0b11;
				if(bp_his_2bc_sn[bp_index][bp_his_l] > 0b11)
					bp_his_2bc_sn[bp_index][bp_his_l] = 0b11;
				
				bp_g_his_1bc_st[bp_his_g] = 0b1;
				bp_g_his_1bc_sn[bp_his_g] = 0b1;
				bp_g_his_2bc_st[bp_his_g]++;
				bp_g_his_2bc_sn[bp_his_g]++;

				if(bp_g_his_2bc_st[bp_his_g] > 0b11)
					bp_g_his_2bc_st[bp_his_g] = 0b11;
				if(bp_g_his_2bc_sn[bp_his_g] > 0b11)
					bp_g_his_2bc_sn[bp_his_g] = 0b11;

				branches_taken++;
				instruction_pointer = second;
				if(program_flags & Program_Flags::debug)
				{
					const auto& fnd = symbols.find(second);
					if(symbols.end() != fnd
					&& fnd->second == line)
						run = false;
				}

				VERBOSE_PRINT("\n");
				continue;
			}

			if(false == bp_1bc_st_gt)
				bp_1bc_st_cor[bp_index]++;
			if(false == bp_1bc_sn_gt)
				bp_1bc_sn_cor[bp_index]++;
			if(false == bp_2bc_st_gt)
				bp_2bc_st_cor[bp_index]++;
			if(false == bp_2bc_sn_gt)
				bp_2bc_sn_cor[bp_index]++;

			if(false == bp_his_1bc_st_gt)
				bp_his_1bc_st_cor[bp_index][bp_his_l]++;
			if(false == bp_his_1bc_sn_gt)
				bp_his_1bc_sn_cor[bp_index][bp_his_l]++;
			if(false == bp_his_2bc_st_gt)
				bp_his_2bc_st_cor[bp_index][bp_his_l]++;
			if(false == bp_his_2bc_sn_gt)
				bp_his_2bc_sn_cor[bp_index][bp_his_l]++;

			if(false == bp_g_his_1bc_st_gt)
				bp_g_his_1bc_st_cor[bp_his_g]++;
			if(false == bp_g_his_1bc_sn_gt)
				bp_g_his_1bc_sn_cor[bp_his_g]++;
			if(false == bp_g_his_2bc_st_gt)
				bp_g_his_2bc_st_cor[bp_his_g]++;
			if(false == bp_g_his_2bc_sn_gt)
				bp_g_his_2bc_sn_cor[bp_his_g]++;

			if(false == best_gt)
				bp_tr_l_cor++;

			bp_1bc_st[bp_index] = 0b0;
			bp_1bc_sn[bp_index] = 0b0;
			bp_2bc_st[bp_index]--;
			bp_2bc_sn[bp_index]--;

			//detects overflow
			if(bp_2bc_st[bp_index] > 0b11)
				bp_2bc_st[bp_index] = 0b00;
			if(bp_2bc_sn[bp_index] > 0b11)
				bp_2bc_sn[bp_index] = 0b00;


			bp_his_1bc_st[bp_index][bp_his_l] = 0b0;
			bp_his_1bc_sn[bp_index][bp_his_l] = 0b0;
			bp_his_2bc_st[bp_index][bp_his_l]--;
			bp_his_2bc_sn[bp_index][bp_his_l]--;

			if(bp_his_2bc_st[bp_index][bp_his_l] > 0b11)
				bp_his_2bc_st[bp_index][bp_his_l] = 0b00;
			if(bp_his_2bc_sn[bp_index][bp_his_l] > 0b11)
				bp_his_2bc_sn[bp_index][bp_his_l] = 0b00;

			bp_g_his_1bc_st[bp_his_g] = 0b0;
			bp_g_his_1bc_sn[bp_his_g] = 0b0;
			bp_g_his_2bc_st[bp_his_g]--;
			bp_g_his_2bc_sn[bp_his_g]--;

			if(bp_g_his_2bc_st[bp_his_g] > 0b11)
				bp_g_his_2bc_st[bp_his_g] = 0b00;
			if(bp_g_his_2bc_sn[bp_his_g] > 0b11)
				bp_g_his_2bc_sn[bp_his_g] = 0b00;

			VERBOSE_PRINT(" DID NOT OCCUR\n");	
			break;
		}
		case Opcode::CAL: 
		{
			bool bp_1bc_st_gt = (bp_1bc_st[bp_index] &  0b1) != 0; 
			bool bp_1bc_sn_gt = (bp_1bc_sn[bp_index] &  0b1) != 0; 
			bool bp_2bc_st_gt = (bp_2bc_st[bp_index] & 0b10) != 0; 
			bool bp_2bc_sn_gt = (bp_2bc_sn[bp_index] & 0b10) != 0; 
			bool bp_his_1bc_st_gt = (bp_his_1bc_st[bp_index][bp_his_l] &  0b1) != 0; 
			bool bp_his_1bc_sn_gt = (bp_his_1bc_sn[bp_index][bp_his_l] &  0b1) != 0; 
			bool bp_his_2bc_st_gt = (bp_his_2bc_st[bp_index][bp_his_l] & 0b10) != 0; 
			bool bp_his_2bc_sn_gt = (bp_his_2bc_sn[bp_index][bp_his_l] & 0b10) != 0; 
			bool bp_g_his_1bc_st_gt = (bp_g_his_1bc_st[bp_his_g] &  0b1) != 0; 
			bool bp_g_his_1bc_sn_gt = (bp_g_his_1bc_sn[bp_his_g] &  0b1) != 0; 
			bool bp_g_his_2bc_st_gt = (bp_g_his_2bc_st[bp_his_g] & 0b10) != 0; 
			bool bp_g_his_2bc_sn_gt = (bp_g_his_2bc_sn[bp_his_g] & 0b10) != 0; 

			bool best_gt = bp_1bc_st_gt;
			uint32_t best_score = bp_1bc_st_cor[bp_index];
			//somehow i should add loop here, somehow
			if(bp_1bc_sn_cor[bp_index] > best_score)
			{ best_gt = bp_1bc_sn_gt; best_score = bp_1bc_sn_cor[bp_index]; }
			if(bp_2bc_st_cor[bp_index] > best_score)
			{ best_gt = bp_2bc_st_gt; best_score = bp_2bc_st_cor[bp_index]; }
			if(bp_2bc_sn_cor[bp_index] > best_score)
			{ best_gt = bp_2bc_sn_gt; best_score = bp_2bc_sn_cor[bp_index]; }


			if(bp_his_1bc_st_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_1bc_st_gt; best_score = bp_his_1bc_st_cor[bp_index][bp_his_l]; }
			if(bp_his_1bc_sn_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_1bc_sn_gt; best_score = bp_his_1bc_sn_cor[bp_index][bp_his_l]; }
			if(bp_his_2bc_st_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_2bc_st_gt; best_score = bp_his_2bc_st_cor[bp_index][bp_his_l]; }
			if(bp_his_2bc_sn_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_2bc_sn_gt; best_score = bp_his_2bc_sn_cor[bp_index][bp_his_l]; }

			if(bp_g_his_1bc_st_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_1bc_st_gt; best_score = bp_g_his_1bc_st_cor[bp_his_g]; }
			if(bp_g_his_1bc_sn_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_1bc_sn_gt; best_score = bp_g_his_1bc_sn_cor[bp_his_g]; }
			if(bp_g_his_2bc_st_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_2bc_st_gt; best_score = bp_g_his_2bc_st_cor[bp_his_g]; }
			if(bp_g_his_2bc_sn_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_2bc_sn_gt; best_score = bp_g_his_2bc_sn_cor[bp_his_g]; }

			branches++;
			DEBUG_PRINT("CAL\n");
			
			if(program_flags & Program_Flags::verbose)
			{
				const auto& fnd = symbols.find(second);
				if(symbols.end() != fnd)
				{	VERBOSE_PRINT("CAL TO " << fnd->second);}
				else
				{	VERBOSE_PRINT("CAL TO " << second);     }
			}

			next_bp_his <<= 1;
			if(flags_register & ccc)
			{
				next_bp_his |= 0b1;
				if(true == bp_1bc_st_gt)
					bp_1bc_st_cor[bp_index]++;
				if(true == bp_1bc_sn_gt)
					bp_1bc_sn_cor[bp_index]++;
				if(true == bp_2bc_st_gt)
					bp_2bc_st_cor[bp_index]++;
				if(true == bp_2bc_sn_gt)
					bp_2bc_sn_cor[bp_index]++;

				if(true == bp_his_1bc_st_gt)
					bp_his_1bc_st_cor[bp_index][bp_his_l]++;
				if(true == bp_his_1bc_sn_gt)
					bp_his_1bc_sn_cor[bp_index][bp_his_l]++;
				if(true == bp_his_2bc_st_gt)
					bp_his_2bc_st_cor[bp_index][bp_his_l]++;
				if(true == bp_his_2bc_sn_gt)
					bp_his_2bc_sn_cor[bp_index][bp_his_l]++;

				if(true == bp_g_his_1bc_st_gt)
					bp_g_his_1bc_st_cor[bp_his_g]++;
				if(true == bp_g_his_1bc_sn_gt)
					bp_g_his_1bc_sn_cor[bp_his_g]++;
				if(true == bp_g_his_2bc_st_gt)
					bp_g_his_2bc_st_cor[bp_his_g]++;
				if(true == bp_g_his_2bc_sn_gt)
					bp_g_his_2bc_sn_cor[bp_his_g]++;
					
				if(true == best_gt)
					bp_tr_l_cor++;

				bp_1bc_st[bp_index] = 0b1;
				bp_1bc_sn[bp_index] = 0b1;
				bp_2bc_st[bp_index]++;
				bp_2bc_sn[bp_index]++;

				if(bp_2bc_st[bp_index] > 0b11)
					bp_2bc_st[bp_index] = 0b11;
				if(bp_2bc_sn[bp_index] > 0b11)
					bp_2bc_sn[bp_index] = 0b11;

				bp_his_1bc_st[bp_index][bp_his_l] = 0b1;
				bp_his_1bc_sn[bp_index][bp_his_l] = 0b1;
				bp_his_2bc_st[bp_index][bp_his_l]++;
				bp_his_2bc_sn[bp_index][bp_his_l]++;

				if(bp_his_2bc_st[bp_index][bp_his_l] > 0b11)
					bp_his_2bc_st[bp_index][bp_his_l] = 0b11;
				if(bp_his_2bc_sn[bp_index][bp_his_l] > 0b11)
					bp_his_2bc_sn[bp_index][bp_his_l] = 0b11;

				bp_g_his_1bc_st[bp_his_g] = 0b1;
				bp_g_his_1bc_sn[bp_his_g] = 0b1;
				bp_g_his_2bc_st[bp_his_g]++;
				bp_g_his_2bc_sn[bp_his_g]++;

				if(bp_g_his_2bc_st[bp_his_g] > 0b11)
					bp_g_his_2bc_st[bp_his_g] = 0b11;
				if(bp_g_his_2bc_sn[bp_his_g] > 0b11)
					bp_g_his_2bc_sn[bp_his_g] = 0b11;

				branches_taken++;
				link_register = instruction_pointer;
				instruction_pointer = second;
				
				if(program_flags & Program_Flags::debug)
				{
					const auto& fnd = symbols.find(second);
					if(symbols.end() != fnd
					&& fnd->second == line)
						run = false;
				}
				VERBOSE_PRINT("\n");
				continue;
			}

			if(false == bp_1bc_st_gt)
				bp_1bc_st_cor[bp_index]++;
			if(false == bp_1bc_sn_gt)
				bp_1bc_sn_cor[bp_index]++;
			if(false == bp_2bc_st_gt)
				bp_2bc_st_cor[bp_index]++;
			if(false == bp_2bc_sn_gt)
				bp_2bc_sn_cor[bp_index]++;

			if(false == bp_his_1bc_st_gt)
				bp_his_1bc_st_cor[bp_index][bp_his_l]++;
			if(false == bp_his_1bc_sn_gt)
				bp_his_1bc_sn_cor[bp_index][bp_his_l]++;
			if(false == bp_his_2bc_st_gt)
				bp_his_2bc_st_cor[bp_index][bp_his_l]++;
			if(false == bp_his_2bc_sn_gt)
				bp_his_2bc_sn_cor[bp_index][bp_his_l]++;

			if(false == bp_g_his_1bc_st_gt)
				bp_g_his_1bc_st_cor[bp_his_g]++;
			if(false == bp_g_his_1bc_sn_gt)
				bp_g_his_1bc_sn_cor[bp_his_g]++;
			if(false == bp_g_his_2bc_st_gt)
				bp_g_his_2bc_st_cor[bp_his_g]++;
			if(false == bp_g_his_2bc_sn_gt)
				bp_g_his_2bc_sn_cor[bp_his_g]++;

			if(false == best_gt)
				bp_tr_l_cor++;

			bp_1bc_st[bp_index] = 0b0;
			bp_1bc_sn[bp_index] = 0b0;
			bp_2bc_st[bp_index]--;
			bp_2bc_sn[bp_index]--;

			//detects overflow
			if(bp_2bc_st[bp_index] > 0b11)
				bp_2bc_st[bp_index] = 0b00;
			if(bp_2bc_sn[bp_index] > 0b11)
				bp_2bc_sn[bp_index] = 0b00;


			bp_his_1bc_st[bp_index][bp_his_l] = 0b0;
			bp_his_1bc_sn[bp_index][bp_his_l] = 0b0;
			bp_his_2bc_st[bp_index][bp_his_l]--;
			bp_his_2bc_sn[bp_index][bp_his_l]--;

			if(bp_his_2bc_st[bp_index][bp_his_l] > 0b11)
				bp_his_2bc_st[bp_index][bp_his_l] = 0b00;
			if(bp_his_2bc_sn[bp_index][bp_his_l] > 0b11)
				bp_his_2bc_sn[bp_index][bp_his_l] = 0b00;

			bp_g_his_1bc_st[bp_his_g] = 0b0;
			bp_g_his_1bc_sn[bp_his_g] = 0b0;
			bp_g_his_2bc_st[bp_his_g]--;
			bp_g_his_2bc_sn[bp_his_g]--;

			if(bp_g_his_2bc_st[bp_his_g] > 0b11)
				bp_g_his_2bc_st[bp_his_g] = 0b00;
			if(bp_g_his_2bc_sn[bp_his_g] > 0b11)
				bp_g_his_2bc_sn[bp_his_g] = 0b00;

			VERBOSE_PRINT(" DID NOT OCCUR\n");

			break;
		}
		case Opcode::RET: 
		{
			bool bp_1bc_st_gt = (bp_1bc_st[bp_index] &  0b1) != 0; 
			bool bp_1bc_sn_gt = (bp_1bc_sn[bp_index] &  0b1) != 0; 
			bool bp_2bc_st_gt = (bp_2bc_st[bp_index] & 0b10) != 0; 
			bool bp_2bc_sn_gt = (bp_2bc_sn[bp_index] & 0b10) != 0; 
			bool bp_his_1bc_st_gt = (bp_his_1bc_st[bp_index][bp_his_l] &  0b1) != 0; 
			bool bp_his_1bc_sn_gt = (bp_his_1bc_sn[bp_index][bp_his_l] &  0b1) != 0; 
			bool bp_his_2bc_st_gt = (bp_his_2bc_st[bp_index][bp_his_l] & 0b10) != 0; 
			bool bp_his_2bc_sn_gt = (bp_his_2bc_sn[bp_index][bp_his_l] & 0b10) != 0; 
			bool bp_g_his_1bc_st_gt = (bp_g_his_1bc_st[bp_his_g] &  0b1) != 0; 
			bool bp_g_his_1bc_sn_gt = (bp_g_his_1bc_sn[bp_his_g] &  0b1) != 0; 
			bool bp_g_his_2bc_st_gt = (bp_g_his_2bc_st[bp_his_g] & 0b10) != 0; 
			bool bp_g_his_2bc_sn_gt = (bp_g_his_2bc_sn[bp_his_g] & 0b10) != 0; 

			bool best_gt = bp_1bc_st_gt;
			uint32_t best_score = bp_1bc_st_cor[bp_index];
			//somehow i should add loop here, somehow
			if(bp_1bc_sn_cor[bp_index] > best_score)
			{ best_gt = bp_1bc_sn_gt; best_score = bp_1bc_sn_cor[bp_index]; }
			if(bp_2bc_st_cor[bp_index] > best_score)
			{ best_gt = bp_2bc_st_gt; best_score = bp_2bc_st_cor[bp_index]; }
			if(bp_2bc_sn_cor[bp_index] > best_score)
			{ best_gt = bp_2bc_sn_gt; best_score = bp_2bc_sn_cor[bp_index]; }


			if(bp_his_1bc_st_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_1bc_st_gt; best_score = bp_his_1bc_st_cor[bp_index][bp_his_l]; }
			if(bp_his_1bc_sn_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_1bc_sn_gt; best_score = bp_his_1bc_sn_cor[bp_index][bp_his_l]; }
			if(bp_his_2bc_st_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_2bc_st_gt; best_score = bp_his_2bc_st_cor[bp_index][bp_his_l]; }
			if(bp_his_2bc_sn_cor[bp_index][bp_his_l] > best_score)
			{ best_gt = bp_his_2bc_sn_gt; best_score = bp_his_2bc_sn_cor[bp_index][bp_his_l]; }

			if(bp_g_his_1bc_st_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_1bc_st_gt; best_score = bp_g_his_1bc_st_cor[bp_his_g]; }
			if(bp_g_his_1bc_sn_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_1bc_sn_gt; best_score = bp_g_his_1bc_sn_cor[bp_his_g]; }
			if(bp_g_his_2bc_st_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_2bc_st_gt; best_score = bp_g_his_2bc_st_cor[bp_his_g]; }
			if(bp_g_his_2bc_sn_cor[bp_his_l] > best_score)
			{ best_gt = bp_g_his_2bc_sn_gt; best_score = bp_g_his_2bc_sn_cor[bp_his_g]; }

			branches++;
			DEBUG_PRINT("RET\n");

			VERBOSE_PRINT("RET TO " << link_register);

			next_bp_his <<= 1;
			if(flags_register & ccc)
			{
				next_bp_his |= 0b1;
				if(true == bp_1bc_st_gt)
					bp_1bc_st_cor[bp_index]++;
				if(true == bp_1bc_sn_gt)
					bp_1bc_sn_cor[bp_index]++;
				if(true == bp_2bc_st_gt)
					bp_2bc_st_cor[bp_index]++;
				if(true == bp_2bc_sn_gt)
					bp_2bc_sn_cor[bp_index]++;

				if(true == bp_his_1bc_st_gt)
					bp_his_1bc_st_cor[bp_index][bp_his_l]++;
				if(true == bp_his_1bc_sn_gt)
					bp_his_1bc_sn_cor[bp_index][bp_his_l]++;
				if(true == bp_his_2bc_st_gt)
					bp_his_2bc_st_cor[bp_index][bp_his_l]++;
				if(true == bp_his_2bc_sn_gt)
					bp_his_2bc_sn_cor[bp_index][bp_his_l]++;

				if(true == bp_g_his_1bc_st_gt)
					bp_g_his_1bc_st_cor[bp_his_g]++;
				if(true == bp_g_his_1bc_sn_gt)
					bp_g_his_1bc_sn_cor[bp_his_g]++;
				if(true == bp_g_his_2bc_st_gt)
					bp_g_his_2bc_st_cor[bp_his_g]++;
				if(true == bp_g_his_2bc_sn_gt)
					bp_g_his_2bc_sn_cor[bp_his_g]++;


				if(true == best_gt)
					bp_tr_l_cor++;

				bp_1bc_st[bp_index] = 0b1;
				bp_1bc_sn[bp_index] = 0b1;
				bp_2bc_st[bp_index]++;
				bp_2bc_sn[bp_index]++;

				if(bp_2bc_st[bp_index] > 0b11)
					bp_2bc_st[bp_index] = 0b11;
				if(bp_2bc_sn[bp_index] > 0b11)
					bp_2bc_sn[bp_index] = 0b11;

				bp_his_1bc_st[bp_index][bp_his_l] = 0b1;
				bp_his_1bc_sn[bp_index][bp_his_l] = 0b1;
				bp_his_2bc_st[bp_index][bp_his_l]++;
				bp_his_2bc_sn[bp_index][bp_his_l]++;

				if(bp_his_2bc_st[bp_index][bp_his_l] > 0b11)
					bp_his_2bc_st[bp_index][bp_his_l] = 0b11;
				if(bp_his_2bc_sn[bp_index][bp_his_l] > 0b11)
					bp_his_2bc_sn[bp_index][bp_his_l] = 0b11;

				bp_g_his_1bc_st[bp_his_g] = 0b1;
				bp_g_his_1bc_sn[bp_his_g] = 0b1;
				bp_g_his_2bc_st[bp_his_g]++;
				bp_g_his_2bc_sn[bp_his_g]++;

				if(bp_g_his_2bc_st[bp_his_g] > 0b11)
					bp_g_his_2bc_st[bp_his_g] = 0b11;
				if(bp_g_his_2bc_sn[bp_his_g] > 0b11)
					bp_g_his_2bc_sn[bp_his_g] = 0b11;

				branches_taken++;
				instruction_pointer = link_register;

				VERBOSE_PRINT("\n");
				if(program_flags & Program_Flags::debug)
					run = false;
				
				continue;
			}

			if(false == bp_1bc_st_gt)
				bp_1bc_st_cor[bp_index]++;
			if(false == bp_1bc_sn_gt)
				bp_1bc_sn_cor[bp_index]++;
			if(false == bp_2bc_st_gt)
				bp_2bc_st_cor[bp_index]++;
			if(false == bp_2bc_sn_gt)
				bp_2bc_sn_cor[bp_index]++;

			if(false == bp_his_1bc_st_gt)
				bp_his_1bc_st_cor[bp_index][bp_his_l]++;
			if(false == bp_his_1bc_sn_gt)
				bp_his_1bc_sn_cor[bp_index][bp_his_l]++;
			if(false == bp_his_2bc_st_gt)
				bp_his_2bc_st_cor[bp_index][bp_his_l]++;
			if(false == bp_his_2bc_sn_gt)
				bp_his_2bc_sn_cor[bp_index][bp_his_l]++;

			if(false == bp_g_his_1bc_st_gt)
				bp_g_his_1bc_st_cor[bp_his_g]++;
			if(false == bp_g_his_1bc_sn_gt)
				bp_g_his_1bc_sn_cor[bp_his_g]++;
			if(false == bp_g_his_2bc_st_gt)
				bp_g_his_2bc_st_cor[bp_his_g]++;
			if(false == bp_g_his_2bc_sn_gt)
				bp_g_his_2bc_sn_cor[bp_his_g]++;

			if(false == best_gt)
				bp_tr_l_cor++;

			bp_1bc_st[bp_index] = 0b0;
			bp_1bc_sn[bp_index] = 0b0;
			bp_2bc_st[bp_index]--;
			bp_2bc_sn[bp_index]--;

			//detects overflow
			if(bp_2bc_st[bp_index] > 0b11)
				bp_2bc_st[bp_index] = 0b00;
			if(bp_2bc_sn[bp_index] > 0b11)
				bp_2bc_sn[bp_index] = 0b00;

			bp_his_1bc_st[bp_index][bp_his_l] = 0b0;
			bp_his_1bc_sn[bp_index][bp_his_l] = 0b0;
			bp_his_2bc_st[bp_index][bp_his_l]--;
			bp_his_2bc_sn[bp_index][bp_his_l]--;

			if(bp_his_2bc_st[bp_index][bp_his_l] > 0b11)
				bp_his_2bc_st[bp_index][bp_his_l] = 0b00;
			if(bp_his_2bc_sn[bp_index][bp_his_l] > 0b11)
				bp_his_2bc_sn[bp_index][bp_his_l] = 0b00;


			bp_g_his_1bc_st[bp_his_g] = 0b0;
			bp_g_his_1bc_sn[bp_his_g] = 0b0;
			bp_g_his_2bc_st[bp_his_g]--;
			bp_g_his_2bc_sn[bp_his_g]--;

			if(bp_g_his_2bc_st[bp_his_g] > 0b11)
				bp_g_his_2bc_st[bp_his_g] = 0b00;
			if(bp_g_his_2bc_sn[bp_his_g] > 0b11)
				bp_g_his_2bc_sn[bp_his_g] = 0b00;

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

	//memdump
	if(program_flags & Program_Flags::dump_mem)
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

	if(program_flags & Program_Flags::dump_reg)
	{
		for(int i = 0; i < 8; i++)
			std::cout << "reg " << i << ' ' << reg[i] << '\n';
		for(int i = 0; i < 8; i++)
			std::cout << "ext " << i << ' ' << ext[i] << '\n';
		std::cout << '\n';
	}


	if(program_flags & Program_Flags::instr)
	{
		 std::cout << "NOP: " << instr_ex_count[ 0] << '\n'
		           << "HLT: " << instr_ex_count[ 1] << '\n'
		
		           << "MOV: " << instr_ex_count[ 5] << '\n'
		           << "RDM: " << instr_ex_count[ 6] << '\n'
		           << "WRM: " << instr_ex_count[ 7] << '\n'
		
		           << "RDX: " << instr_ex_count[12] << '\n'
		           << "WRX: " << instr_ex_count[13] << '\n'
		           << "PSH: " << instr_ex_count[14] << '\n'
		           << "POP: " << instr_ex_count[15] << '\n'
		           << "MUL: " << instr_ex_count[16] << '\n'
		           << "CMP: " << instr_ex_count[17] << '\n'
		 
		           << "TST: " << instr_ex_count[19] << '\n'
		           << "JMP: " << instr_ex_count[20] << '\n'
		           << "CAL: " << instr_ex_count[21] << '\n'
		           << "RET: " << instr_ex_count[22] << '\n'
		
		           << "ADD: " << instr_ex_count[24] << '\n'
		           << "SUB: " << instr_ex_count[25] << '\n'
		           << "NOT: " << instr_ex_count[26] << '\n'
		           << "AND: " << instr_ex_count[27] << '\n'
		           << "ORR: " << instr_ex_count[28] << '\n'
		           << "XOR: " << instr_ex_count[29] << '\n'
		           << "SLL: " << instr_ex_count[30] << '\n'
		           << "SLR: " << instr_ex_count[31] << '\n';

		std::cout << '\n';
	}


	if(program_flags & Program_Flags::perf)
	{


		uint32_t t_bp_1bc_st_cor = 0;
		uint32_t t_bp_1bc_sn_cor = 0;
		uint32_t t_bp_2bc_st_cor = 0;
		uint32_t t_bp_2bc_sn_cor = 0;
		uint32_t t_bp_his_1bc_st_cor = 0;
		uint32_t t_bp_his_1bc_sn_cor = 0;
		uint32_t t_bp_his_2bc_st_cor = 0;
		uint32_t t_bp_his_2bc_sn_cor = 0;
		uint32_t t_bp_g_his_1bc_st_cor = 0;
		uint32_t t_bp_g_his_1bc_sn_cor = 0;
		uint32_t t_bp_g_his_2bc_st_cor = 0;
		uint32_t t_bp_g_his_2bc_sn_cor = 0;

		for(int i = 0; i < par_bp_bc_count; i++)
			t_bp_1bc_st_cor += bp_1bc_st_cor[i];
		for(int i = 0; i < par_bp_bc_count; i++)
			t_bp_1bc_sn_cor += bp_1bc_sn_cor[i];
		for(int i = 0; i < par_bp_bc_count; i++)
			t_bp_2bc_st_cor += bp_2bc_st_cor[i];
		for(int i = 0; i < par_bp_bc_count; i++)
			t_bp_2bc_sn_cor += bp_2bc_sn_cor[i];

		for(int i = 0; i < par_bp_bc_count; i++)
			for(int j = 0; j < par_bp_his_l_size; j++)
				t_bp_his_1bc_st_cor += bp_his_1bc_st_cor[i][j];
		for(int i = 0; i < par_bp_bc_count; i++)
			for(int j = 0; j < par_bp_his_l_size; j++)
				t_bp_his_1bc_sn_cor += bp_his_1bc_sn_cor[i][j];
		for(int i = 0; i < par_bp_bc_count; i++)
			for(int j = 0; j < par_bp_his_l_size; j++)
				t_bp_his_2bc_st_cor += bp_his_2bc_st_cor[i][j];
		for(int i = 0; i < par_bp_bc_count; i++)
			for(int j = 0; j < par_bp_his_l_size; j++)
				t_bp_his_2bc_sn_cor += bp_his_2bc_sn_cor[i][j];

		for(int i = 0; i < par_bp_his_g_size; i++)
			t_bp_g_his_1bc_st_cor += bp_g_his_1bc_st_cor[i];
		for(int i = 0; i < par_bp_his_g_size; i++)
			t_bp_g_his_1bc_sn_cor += bp_g_his_1bc_sn_cor[i];
		for(int i = 0; i < par_bp_his_g_size; i++)
			t_bp_g_his_2bc_st_cor += bp_g_his_2bc_st_cor[i];
		for(int i = 0; i < par_bp_his_g_size; i++)
			t_bp_g_his_2bc_sn_cor += bp_g_his_2bc_sn_cor[i];

		std::cout << "____GENERAL INFO____\n";
		std::cout << "Instruction Count: " << instruction_count << '\n';
		std::cout << "Memory References: " << memory_references << '\n';
		std::cout << "Stack Operations : " << stack_operations  << '\n'; 
		std::cout << "Branches         : " << branches          << '\n'; 
		std::cout << "Branches Taken   : " << branches_taken    << '\n'; 
		std::cout << "Arithmetic       : " << arithmetic        << '\n'; 
		std::cout << '\n';

		std::cout << "__BRANCH PREDICTOR__\n";
		std::cout << "1bc T            : " << t_bp_1bc_st_cor << '\n';
		std::cout << "1bc N            : " << t_bp_1bc_sn_cor << '\n';
		std::cout << "2bc T            : " << t_bp_2bc_st_cor << '\n';
		std::cout << "2bc N            : " << t_bp_2bc_sn_cor << '\n';

		std::cout << "his 1bc T        : " << t_bp_his_1bc_st_cor << '\n';
		std::cout << "his 1bc N        : " << t_bp_his_1bc_sn_cor << '\n';
		std::cout << "his 2bc T        : " << t_bp_his_2bc_st_cor << '\n';
		std::cout << "his 2bc N        : " << t_bp_his_2bc_sn_cor << '\n';

		std::cout << "global his 1bc T : " << t_bp_g_his_1bc_st_cor << '\n';
		std::cout << "global his 1bc N : " << t_bp_g_his_1bc_sn_cor << '\n';
		std::cout << "global his 2bc T : " << t_bp_g_his_2bc_st_cor << '\n';
		std::cout << "global his 2bc N : " << t_bp_g_his_2bc_sn_cor << '\n';

		std::cout << "Tournament local : " << bp_tr_l_cor << '\n';

//		std::cout << "Tournament global: " << bp_tr_g_cor << '\n';

		std::cout << '\n';

		std::cout << "__APPROXIMATE TIME__\n";
		std::cout << "Approx. time on simple implementation  : " << instruction_count + memory_references                  << " cycles\n";
		std::cout << "Approx. time on pipeline implementation: " << instruction_count + memory_references + 2 * branches_taken << " cycles\n";
		std::cout << '\n';
	}

	if(program_flags & Program_Flags::warn)
	{
		if(stack_pointer != 0)
			std::cout << "WARNING: stack pointer IS NOT back at 0\n"; 

		std::cout << '\n';
	}	
	return 0;
}
