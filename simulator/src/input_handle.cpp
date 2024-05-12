#include <iostream>
#include <fstream>

#include <cstring> //strcmp
#include <cstdint>

#include <string>
#include <unordered_map>

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
		preciseperf= 0x0400,
		branch     = 0x0800
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


constexpr uint32_t hex_val(const char hex)
{
	if(hex <= '9')
		return hex - '0';
	else
		return hex - 'A' + 10;
}

void input_handle_args(
	int   argc       ,
	char* argv[]     ,
	uint32_t& flags  ,
	std::string& code,
	std::string& syms 
	)
{
	if(argc < 2)
		return;
	if(0 == strcmp(argv[1], "-h"))
	{
		flags |= Program_Flags::print_help;
		return;
	}

	code = argv[1];

	for(int i = 2; i < argc; i++)
	{
		if(argv[i][0] != '-'
		|| strlen(argv[i]) < 2)
			continue;

		switch(argv[i][1])
		{
		case 'h':
			flags |= Program_Flags::print_help;
			return;
		case 'd':
			flags |= Program_Flags::debug;
			continue;
		case 'v':
			flags |= Program_Flags::verbose;
			continue;
		case 'l':
			flags |= Program_Flags::long_input;
			continue;
		case 'm':
			flags |= Program_Flags::dump_mem;
			continue;
		case 'r':
			flags |= Program_Flags::dump_reg;
			continue;
		case 'p':
			flags |= Program_Flags::perf;
			continue;
		case 'i':
			flags |= Program_Flags::instr;
			continue;
		case 'w':
			flags |= Program_Flags::warn;
			continue;
		case 'P':
			flags |= Program_Flags::preciseperf;
			continue;
		case 'b':
			flags |= Program_Flags::branch;
			continue;
		case 's':
			flags |= Program_Flags::symbols;

			if(argc <= i)
				return;

			syms = argv[i + 1];
			return;
		default:
			std::cout << "not recognized option " << argv[i] << "\n";
			continue;
		}
	}

	return;
}


int input_read_syms(
	std::unordered_map<uint16_t, std::string>& symbols,	
	std::string const&                         file_name
	)
{
	std::ifstream debug_file(file_name);
	
	if(false == debug_file.is_open())
		return -1;

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

		symbols[static_cast<uint16_t>(instr)] = line.substr(0, str_end);
	}

	return 0;
}


int input_read_instr(
	uint8_t*           mem       ,
	bool*              modified  ,
	bool        const  long_input,
	std::string const& file_name
	)
{
	std::ifstream file(file_name);

	if(false == file.is_open())
		return -1;
	
	std::string line;
	if(long_input)
	{
		int ind = 0;
		while(std::getline(file, line))
		{
			      uint16_t val = (hex_val(line[0]) << 12)
			                   | (hex_val(line[1]) <<  8)
			                   | (hex_val(line[2]) <<  4)
			                   | (hex_val(line[3]) <<  0);
			mem[ind + 0] = static_cast<uint8_t>(val >> 8);
			mem[ind + 1] = static_cast<uint8_t>(val & 0xFF);
	
			modified[ind + 0] = true;
			modified[ind + 1] = true;
			
			               val = (hex_val(line[4]) << 12)
			                   | (hex_val(line[5]) <<  8)
			                   | (hex_val(line[6]) <<  4)
			                   | (hex_val(line[7]) <<  0);
			mem[ind + 2] = static_cast<uint8_t>(val >> 8);
			mem[ind + 3] = static_cast<uint8_t>(val & 0xFF);
	
			modified[ind + 2] = true;
			modified[ind + 3] = true;
	
			ind += 4;
		}
	}
	else
	{
		int ind = 0;
		while(std::getline(file, line))
		{
			const uint16_t val = (hex_val(line[0]) << 12)
			                   | (hex_val(line[1]) <<  8)
			                   | (hex_val(line[2]) <<  4)
			                   | (hex_val(line[3]) <<  0);
			mem[ind + 0] = static_cast<uint8_t>(val >> 8);
			mem[ind + 1] = static_cast<uint8_t>(val & 0xFF);
	
			modified[ind + 0] = true;
			modified[ind + 1] = true;
	
			ind += 2;
		}
	}

	return 0;
}

void output_print_help()
{
	std::cout << 
		"usage ./sim program_input_file OPTIONS\n"
		"\n"
		"OPTIONS:\n"
		"\t-h         prints this help\n"
		"\t-d         debug, step through program\n"
		"\t-v         verbose output of what each executed isntruction does\n"
		"\t-l         long input\n"
		"\t           input is long when each line has two instructions\n"
		"\t-m         memory dump to dump.txt\n"
		"\t-r         output register dump\n"
		"\t-i         output how many times each instruction executed\n"
		"\t-p         output performance info\n"
		"\t-P         output precise performance info, overrides -p\n"
		"\t-b         output branch predictor info\n"
		"\t-w         output potential warnings\n"
		"\t-s         symbol file, MUST be used as last option and MUST be followed by symbols file\n"
		"using these options improperly may result in weird error\n";

	return;
}

