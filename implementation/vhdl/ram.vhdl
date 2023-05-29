/*
	DUs in file in order
		ram
	
	ram 
		a0  is address input
		i0  is data input
		o0  is data output
		we  is write enable
		clk is synchronization
		
		64KiB of data, byte addressable
		access must be 2B aligned 
		unaligned memory access is rounded down to first aligned 
		meaning LSb is discarded when using a0 
		
		so in practice behaves like 32Ki of 16bit words

		default value of data is program
*/


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ram IS
	PORT(
		a0  : IN  std_ulogic_vector(15 DOWNTO 0) := x"0000";
		i0  : IN  std_ulogic_vector(15 DOWNTO 0);
		o0  : OUT std_ulogic_vector(15 DOWNTO 0);

		we  : IN  std_ulogic := '0';
		clk : IN  std_ulogic);
END ENTITY ram;

ARCHITECTURE behav OF ram IS 
	TYPE arr IS ARRAY(32767 DOWNTO 0) OF std_ulogic_vector(15 DOWNTO 0);
	SIGNAL data : arr := (
	--fib.asm
	/*
		00 => x"2800", 01 => x"2901", 02 => x"2F07", 03 => x"8F00", 04 => x"A60A", 
		05 => x"0205", 06 => x"0025", 07 => x"0158", 08 => x"CF01", 09 => x"A305", 
		10 => x"3850", 11 => x"0000", 12 => x"0F00",
	*/
	--fact.asm
	/*
		00 => x"A719", 01 => x"8900", 02 => x"A505", 03 => x"2800", 04 => x"A70A",
		05 => x"0205", 06 => x"C901", 07 => x"0058", 08 => x"C901", 09 => x"A107",
		10 => x"B700", 11 => x"074C", 12 => x"7700", 13 => x"8801", 14 => x"A615",
		15 => x"7000", 16 => x"C801", 17 => x"AB0B", 18 => x"7900", 19 => x"AF01",
		20 => x"A716", 21 => x"2801", 22 => x"7F00", 23 => x"02ED", 24 => x"B700",
		25 => x"2806", 26 => x"AF0B", 27 => x"3850", 28 => x"0F00", 		
	*/
	--sort.asm		
	/*
		00 => x"A727", 01 => x"8900", 02 => x"A505", 03 => x"2800", 04 => x"A70A",
		05 => x"0205", 06 => x"C901", 07 => x"0058", 08 => x"C901", 09 => x"A107",
		10 => x"B700", 11 => x"8A00", 12 => x"B600", 13 => x"0306", 14 => x"0327",
		15 => x"C002", 16 => x"C102", 17 => x"CA02", 18 => x"A70B", 19 => x"0605",
		20 => x"0638", 21 => x"8902", 22 => x"B600", 23 => x"0205", 24 => x"0305",
		25 => x"C302", 26 => x"0446", 27 => x"0566", 28 => x"04B1", 29 => x"A620",
		30 => x"0547", 31 => x"0467", 32 => x"C202", 33 => x"C302", 34 => x"03D1",
		35 => x"A41A", 36 => x"C902", 37 => x"A113", 38 => x"B700", 39 => x"2EA4",
		40 => x"2801", 41 => x"297B", 42 => x"AF01", 43 => x"F001", 44 => x"F801",
		45 => x"00C7", 46 => x"CE02", 47 => x"8E96", 48 => x"A329", 49 => x"2896",
		50 => x"29C8", 51 => x"2A10", 52 => x"AF0B", 53 => x"2896", 54 => x"2910",
		55 => x"AF13", 56 => x"3096", 57 => x"3198", 58 => x"329A", 59 => x"339C",
		60 => x"349E", 61 => x"35A0", 62 => x"36A2", 63 => x"37A4", 64 => x"0F00",
	*/
	--pipeline_easy.asm
	/*
		00 => x"2800", 01 => x"2901", 02 => x"2A02", 03 => x"2B03", 04 => x"2C04",
		05 => x"2D05", 06 => x"2E06", 07 => x"2F07", 08 => x"0038", 09 => x"0158",
		10 => x"0278", 11 => x"0398", 12 => x"04B8", 13 => x"05D8", 14 => x"06F8",
		15 => x"0718", 16 => x"F001", 17 => x"F101", 18 => x"F201", 19 => x"F301",
		20 => x"F401", 21 => x"F501", 22 => x"F601", 23 => x"F701", 24 => x"0F00",
	*/
	--pipeline_alu_dep.asm
	/*
		00 => x"2900", 01 => x"2810", 02 => x"F002", 03 => x"0205", 04 => x"F802",
		05 => x"0305", 06 => x"C001", 07 => x"C802", 08 => x"F801", 09 => x"0405",
		10 => x"0F00",
	*/
	--matmult.asm
		00 => x"A742", 01 => x"2A00", 02 => x"8900", 03 => x"A207", 04 => x"0218",
		05 => x"C901", 06 => x"A104", 07 => x"0045", 08 => x"B700", 09 => x"2909",
		10 => x"C010", 11 => x"0107", 12 => x"C802", 13 => x"C901", 14 => x"A10B",
		15 => x"B700", 16 => x"074C", 17 => x"7700", 18 => x"2B03", 19 => x"2F00",
		20 => x"7000", 21 => x"7100", 22 => x"0006", 23 => x"0126", 24 => x"AF01",
		25 => x"0718", 26 => x"7900", 27 => x"7800", 28 => x"C002", 29 => x"C106",
		30 => x"CB01", 31 => x"A114", 32 => x"00E5", 33 => x"7F00", 34 => x"02ED",
		35 => x"B700", 36 => x"074C", 37 => x"7700", 38 => x"2C03", 39 => x"7400",
		40 => x"7000", 41 => x"7100", 42 => x"2B03", 43 => x"7300", 44 => x"7000",
		45 => x"7100", 46 => x"7200", 47 => x"AF10", 48 => x"7A00", 49 => x"0047",
		50 => x"C202", 51 => x"7900", 52 => x"C102", 53 => x"7800", 54 => x"7B00",
		55 => x"CB01", 56 => x"A12B", 57 => x"7900", 58 => x"7800", 59 => x"C006",
		60 => x"7C00", 61 => x"CC01", 62 => x"A127", 63 => x"7F00", 64 => x"02ED",
		65 => x"B700", 66 => x"6C01", 67 => x"2800", 68 => x"AF09", 69 => x"6C02",
		70 => x"2800", 71 => x"AF09", 72 => x"6C01", 73 => x"2800", 74 => x"6C02",
		75 => x"2900", 76 => x"6C03", 77 => x"2A00", 78 => x"AF24", 79 => x"6C03",
		80 => x"2F00", 81 => x"00E6", 82 => x"C702", 83 => x"01E6", 84 => x"C702",
		85 => x"02E6", 86 => x"C702", 87 => x"03E6", 88 => x"C702", 89 => x"04E6",
		90 => x"C702", 91 => x"05E6", 92 => x"C702", 93 => x"06E6", 94 => x"C702",
		95 => x"07E6", 96 => x"0F00",

		OTHERS => x"0000"
	);

	SIGNAL addr : integer RANGE 32767 DOWNTO 0;
BEGIN
	addr <= to_integer(unsigned(a0(15 DOWNTO 1)));

	data(addr) <= i0 WHEN we = '1' AND rising_edge(clk)
	         ELSE UNAFFECTED;
	o0 <= data(addr); 


END ARCHITECTURE behav;
