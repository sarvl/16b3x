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
		
		so in practice behaves like 32Ki of 16bit 

		however internal implementation is 16Ki of 32bit 
		because that is the most convenient for superscalar implementation
		and poses no additional cost for other impl. 

		default value of data is program
*/


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ram IS
	PORT(
		a0  : IN  std_ulogic_vector(15 DOWNTO 0) := x"0000";
		i0s : IN  std_ulogic_vector(15 DOWNTO 0);
		o0s : OUT std_ulogic_vector(15 DOWNTO 0);
		o0d : OUT std_ulogic_vector(31 DOWNTO 0) := x"00000000";

		we  : IN  std_ulogic := '0';
		rdy : OUT std_ulogic := '0';
		hlt : IN  std_ulogic := '0'; --NAI
		clk : IN  std_ulogic);
END ENTITY ram;

ARCHITECTURE behav OF ram IS 
	TYPE arr IS ARRAY(16383 DOWNTO 0) OF std_ulogic_vector(31 DOWNTO 0);
	SIGNAL data : arr := (
	--fib.asm
	/*
		00 => x"28002901", 01 => x"2F078F00", 02 => x"A60A0205", 03 => x"00250158", 04 => x"CF01A305",
		05 => x"38500000", 06 => x"0F000000",
	*/
	--fact.asm
	/*
		00 => x"A7198900", 01 => x"A5052800", 02 => x"A70A0205", 03 => x"C9010058", 04 => x"C901A107",
		05 => x"B700074C", 06 => x"77008801", 07 => x"A6157000", 08 => x"C801AB0B", 09 => x"7900AF01",
		10 => x"A7162801", 11 => x"7F0002ED", 12 => x"B7002806", 13 => x"AF0B3850", 14 => x"0F000000",
	*/
	--sort.asm		
	/*
		00 => x"A7278900", 01 => x"A5052800", 02 => x"A70A0205", 03 => x"C9010058", 04 => x"C901A107",
		05 => x"B7008A00", 06 => x"B6000306", 07 => x"0327C002", 08 => x"C102CA02", 09 => x"A70B0605",
		10 => x"06388902", 11 => x"B6000205", 12 => x"0305C302", 13 => x"04460566", 14 => x"04B1A620",
		15 => x"05470467", 16 => x"C202C302", 17 => x"03D1A41A", 18 => x"C902A113", 19 => x"B7002EA4",
		20 => x"2801297B", 21 => x"AF01F001", 22 => x"F80100C7", 23 => x"CE028E96", 24 => x"A3292896",
		25 => x"29C82A10", 26 => x"AF0B2896", 27 => x"2910AF13", 28 => x"30963198", 29 => x"329A339C",
		30 => x"349E35A0", 31 => x"36A237A4", 32 => x"0F000000",
	*/
	--pipeline_easy.asm
	/*
		00 => x"28002901", 01 => x"2A022B03", 02 => x"2C042D05", 03 => x"2E062F07", 04 => x"00380158",
		05 => x"02780398", 06 => x"04B805D8", 07 => x"06F80718", 08 => x"F001F101", 09 => x"F201F301",
		10 => x"F401F501", 11 => x"F601F701", 12 => x"0F000000",
	*/
	--pipeline_alu_dep.asm
	/*
		00 => x"29002810", 01 => x"F0020205", 02 => x"F8020305", 03 => x"C001C802", 04 => x"F8010405",
		05 => x"0F000000",
	*/
	--pipeline_stresstest.asm
	/*
		00 => x"28050105", 01 => x"F0026C01", 02 => x"2A00FA07", 03 => x"C0010010", 04 => x"CA01A306",
		05 => x"6C01048C", 06 => x"6A14B700", 07 => x"2D098504", 08 => x"3D643664", 09 => x"05BD6815",
		10 => x"AF0E0F00",
	*/
	--matmult.asm
	/*
		00 => x"A7422A00", 01 => x"8900A207", 02 => x"0218C901", 03 => x"A1040045", 04 => x"B7002909",
		05 => x"C0100107", 06 => x"C802C901", 07 => x"A10BB700", 08 => x"074C7700", 09 => x"2B032F00",
		10 => x"70007100", 11 => x"00060126", 12 => x"AF010718", 13 => x"79007800", 14 => x"C002C106",
		15 => x"CB01A114", 16 => x"00E57F00", 17 => x"02EDB700", 18 => x"074C7700", 19 => x"2C037400",
		20 => x"70007100", 21 => x"2B037300", 22 => x"70007100", 23 => x"7200AF10", 24 => x"7A000047",
		25 => x"C2027900", 26 => x"C1027800", 27 => x"7B00CB01", 28 => x"A12B7900", 29 => x"7800C006",
		30 => x"7C00CC01", 31 => x"A1277F00", 32 => x"02EDB700", 33 => x"6C012800", 34 => x"AF096C02",
		35 => x"2800AF09", 36 => x"6C012800", 37 => x"6C022900", 38 => x"6C032A00", 39 => x"AF246C03",
		40 => x"2F0000E6", 41 => x"C70201E6", 42 => x"C70202E6", 43 => x"C70203E6", 44 => x"C70204E6",
		45 => x"C70205E6", 46 => x"C70206E6", 47 => x"C70207E6", 48 => x"0F000000",
	*/
	--sort_instr.asm
	/*
		00 => x"A71D8A00", 01 => x"B6000306", 02 => x"0327C002", 03 => x"C102CA02", 04 => x"A7010605",
		05 => x"06388902", 06 => x"B6000205", 07 => x"0305C302", 08 => x"04460566", 09 => x"04B1A616",
		10 => x"05470467", 11 => x"C202C302", 12 => x"03D1A410", 13 => x"C902A109", 14 => x"B7002EA4",
		15 => x"2801807B", 16 => x"F001F801", 17 => x"00C7CE02", 18 => x"8E96A31F", 19 => x"289629C8",
		20 => x"2A10AF01", 21 => x"28962910", 22 => x"AF093096", 23 => x"3198329A", 24 => x"339C349E",
		25 => x"35A036A2", 26 => x"37A40F00",
	*/
	--matmult_instr.asm
	/*
		00 => x"A7342909", 01 => x"C0100107", 02 => x"C802C901", 03 => x"A103B700", 04 => x"07060526",
		05 => x"07B0C002", 06 => x"C1060406", 07 => x"052604B0", 08 => x"0798C002", 09 => x"C1060406",
		10 => x"052604B0", 11 => x"07980747", 12 => x"B700074C", 13 => x"770039C8", 14 => x"C10239CA",
		15 => x"C10239CC", 16 => x"2E0338FE", 17 => x"31C8AF08", 18 => x"C20230FE", 19 => x"31CAAF08",
		20 => x"C20230FE", 21 => x"31CCAF08", 22 => x"C20230FE", 23 => x"C006CE01", 24 => x"A1217F00",
		25 => x"02EDB700", 26 => x"6C012800", 27 => x"AF016C02", 28 => x"2800AF01", 29 => x"6C012800",
		30 => x"6C022900", 31 => x"6C032A00", 32 => x"AF196C03", 33 => x"2F0000E6", 34 => x"C70201E6",
		35 => x"C70202E6", 36 => x"C70203E6", 37 => x"C70204E6", 38 => x"C70205E6", 39 => x"C70206E6",
		40 => x"C70207E6", 41 => x"0F000000",
	*/
	--oooe_simplest.asm
	/*
		00 => x"28002901", 01 => x"2A022B03", 02 => x"00380278", 03 => x"01190279", 04 => x"005D017D",
		05 => x"00180138", 06 => x"0F000000",
	*/
	--oooe_alu_conflict_0.asm
	/*
		00 => x"28012902", 01 => x"2A042B08", 02 => x"00580318", 03 => x"02380218", 04 => x"0F000000",
	*/
	--oooe_alu_conflict_1.asm
	/*
		00 => x"28012902", 01 => x"2A042B08", 02 => x"00580318", 03 => x"02380278", 04 => x"0F000000",
	*/
	--oooe_alu_conflict_2.asm
	/*
		00 => x"28012902", 01 => x"2A042B08", 02 => x"00580318", 03 => x"02780465", 04 => x"0F000000",
	*/
	--oooe_alu_conflict_3.asm
	/*
		00 => x"28012902", 01 => x"2A042B08", 02 => x"C0010118", 03 => x"02380358", 04 => x"2C102D20",
		05 => x"00000000", 06 => x"0F000000",
	*/
	--oooe_memory_0.asm
	/*
		00 => x"28642968", 01 => x"38643968", 02 => x"35643668", 03 => x"0F000000",
	*/
	--oooe_branch_aligned.asm
	/*
		00 => x"28012902", 01 => x"2A042B08", 02 => x"0351A10A", 03 => x"2C642D68", 04 => x"0F000000",
		05 => x"2C102D20", 06 => x"0F000000",
	*/
	--oooe_branch_misaligned.asm
	/*
		00 => x"28012902", 01 => x"2A042B08", 02 => x"0351A109", 03 => x"2C642D68", 04 => x"0F002C10",
		05 => x"2D200F00",
	*/
	--oooe_fib.asm
	/*
		00 => x"28002F07", 01 => x"29018F00", 02 => x"A60C0000", 03 => x"02050025", 04 => x"0158CF01",
		05 => x"A3060000", 06 => x"38500F00",
	*/
	--simulator.asm
	 00 => x"A71D2800", 01 => x"29012F07", 02 => x"8F00A60A", 03 => x"02050025", 04 => x"0158CF01",
	 05 => x"A3053850", 06 => x"38643966", 07 => x"3A683B6A", 08 => x"3C6C3D6E", 09 => x"3E703F72",
	 10 => x"0F000000", 11 => x"00000000", 12 => x"00000000", 13 => x"00000000", 14 => x"00002F01",
	 15 => x"CF0102E5", 16 => x"C201F201", 17 => x"0646C701", 18 => x"00C5F808", 19 => x"D80701C5",
	 20 => x"D9FF6CF8", 21 => x"9E00A230", 22 => x"F308017C", 23 => x"FE0BA736", 24 => x"F905DE1F",
	 25 => x"0225C115", 26 => x"F1010126", 27 => x"6C023B48", 28 => x"2B006C01", 29 => x"C603F601",
	 30 => x"06C607D4", 31 => x"A71F0513", 32 => x"A21F6C00", 33 => x"A7F2C015", 34 => x"F0010107",
	 35 => x"A71F6C02", 36 => x"C14A0226", 37 => x"C015F001", 38 => x"0207A71F", 39 => x"C015F001",
	 40 => x"00066C02", 41 => x"C14A0027", 42 => x"A71FC015", 43 => x"F0018A00", 44 => x"A2648A01",
	 45 => x"A2668A02", 46 => x"A2698A04", 47 => x"A26B8A05", 48 => x"A26F8A07", 49 => x"A271A71F",
	 50 => x"0707A71F", 51 => x"022C0207", 52 => x"A71F0407", 53 => x"A71F6C01", 54 => x"32230207",
	 55 => x"A71F0507", 56 => x"A71F2A01", 57 => x"0207A71F", 58 => x"8800A27F", 59 => x"8801A281",
	 60 => x"8802A283", 61 => x"8804A285", 62 => x"8805A287", 63 => x"A71F0725", 64 => x"A71F012D",
	 65 => x"A71F0425", 66 => x"A71F0325", 67 => x"A71F0525", 68 => x"A71FC015", 69 => x"F0010006",
	 70 => x"7000A71F", 71 => x"7A00C015", 72 => x"F0010207", 73 => x"A71FC015", 74 => x"F0010205",
	 75 => x"00460030", 76 => x"004705AC", 77 => x"A71FC015", 78 => x"F0010006", 79 => x"003105AC",
	 80 => x"A71FC015", 81 => x"F0010006", 82 => x"003305AC", 83 => x"A71F0513", 84 => x"A21F0725",
	 85 => x"A71F0513", 86 => x"A21F04E5", 87 => x"0725A71F", 88 => x"0513A21F", 89 => x"0785A71F",
	 90 => x"C015F001", 91 => x"02050046", 92 => x"00380047", 93 => x"05ACA71F", 94 => x"C015F001",
	 95 => x"02050046", 96 => x"00390047", 97 => x"05ACA71F", 98 => x"C015F001", 99 => x"02050046",
	100 => x"003A0047",101 => x"05ACA71F",102 => x"C015F001",103 => x"02050046",104 => x"003B0047",
	105 => x"05ACA71F",106 => x"C015F001",107 => x"02050046",108 => x"003C0047",109 => x"05ACA71F",
	110 => x"C015F001",111 => x"02050046",112 => x"003D0047",113 => x"05ACA71F",114 => x"C015F001",
	115 => x"02050046",116 => x"003E0047",117 => x"A71FC015",118 => x"F0010205",119 => x"0046003F",
	120 => x"0047A71F",121 => x"6C00302A",122 => x"6C00312C",123 => x"6C00322E",124 => x"6C003330",
	125 => x"6C003432",126 => x"6C003534",127 => x"6C003636",128 => x"6C003738",129 => x"0F00003E",
	130 => x"003F0000",131 => x"00000000",132 => x"00430047",133 => x"004E0000",134 => x"00000000",
	135 => x"00000055",136 => x"00740089",137 => x"008E0093",138 => x"009B0000",139 => x"00A100A7",
	140 => x"00AB00B0",141 => x"000000B4",142 => x"00BC00C4",143 => x"00CC00D4",144 => x"00DC00E4",
	145 => x"00EB0000",146 => x"00000000",

	OTHERS => x"00000000"
	);

	SIGNAL addr     : integer RANGE 16383 DOWNTO 0;
	SIGNAL mem_data : std_ulogic_vector(31 DOWNTO 0) := x"00000000";
	SIGNAL ms_half  : std_ulogic;

	SIGNAL mem_out     : std_ulogic_vector(31 DOWNTO 0) := x"00000000";
	SIGNAL mem_in      : std_ulogic_vector(31 DOWNTO 0);
BEGIN
	--LSb is ignored
	--next bit decides whether data is in first or second half of 32bit word 
	addr <= to_integer(unsigned(a0(15 DOWNTO 2)));

	--most significant half 
	--in xAAAABBBB
	--its half denoted by AAAA
	ms_half  <= NOT a0(1);
	mem_data <= data(addr);

	--since input is 16b it needs to be merged with part of what is already stored 
	mem_in <= mem_data(31 DOWNTO 16) & i0s WHEN ms_half = '0'
	     ELSE i0s & mem_data(15 DOWNTO  0);

	data(addr) <= mem_in WHEN we = '1' AND rising_edge(clk)
	         ELSE UNAFFECTED;

	mem_out <= mem_data; 

	o0s <= mem_out(31 DOWNTO 16) WHEN ms_half = '1'
	  ELSE mem_out(15 DOWNTO  0); 
	o0d <= mem_out;

	--models delay
	--rdy <= '1' AFTER 10 NS, '0' AFTER 10.5   NS WHEN rising_edge(clk)
	--  ELSE UNAFFECTED;
	--models lack of delay
	rdy <= '1';

END ARCHITECTURE behav; 

