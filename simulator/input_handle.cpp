#include <iostream>
#include <fstream>

#include <cstring> //strcmp
#include <cstdint>

#include <string>
#include <unordered_map>

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
	)
{
	if(argc < 2)
		return;
	if(0 == strcmp(argv[1], "-h"))
	{
		print_help = true;
		return;
	}

	code = argv[1];

	for(int i = 2; i < argc; i++)
	{
		if(0 == strcmp(argv[i], "-h"))
		{
			print_help = true;
			return;
		}

		if(0 == strcmp(argv[i], "-d"))
		{
			debug = true;
			continue;
		}
		if(0 == strcmp(argv[i], "-v"))
		{
			verbose = true;
			continue;
		}
		if(0 == strcmp(argv[i], "-l"))
		{
			long_input = true;
			continue;
		}
		if(0 == strcmp(argv[i], "-m"))
		{
			dump_mem = true;
			continue;
		}
		if(0 == strcmp(argv[i], "-r"))
		{
			dump_reg = true;
			continue;
		}
		if(0 == strcmp(argv[i], "-p"))
		{
			perf = true;
			continue;
		}
		if(0 == strcmp(argv[i], "-s"))
		{
			symbols = true;
			if(argc <= i)
				return;
			syms = argv[i + 1];
			return;
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
		"\t-d         debug\n"
		"\t-v         verbose output\n"
		"\t-l         long input\n"
		"\t           input is long when each line has two instructions\n"
		"\t-m         memory dump\n"
		"\t-r         register dump\n"
		"\t-p         output performance info\n"
		"\t-s         symbol file, MUST be used as last option and MUST be followed by symbols file\n"
		"using these options improperly may result in weird error\n";

	return;
}

