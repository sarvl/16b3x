/*
	DUs in file in order
		ram
		cache
	
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

		the RAM actually returns 4B of data, so that cache can get more at the same time
	
	cache
		2 way set associative LRU write through cache 
		each cache entry is 4B 

		(note the small b) 
		8MSb are tag
		next 6b are set
		last 2b are ignored by cache, memory module chooses what it needs

		internally cache uses 1 additional bit (that is, 6set bits + 1 additional)
		to allow for 2 mem location with the same set to be stored

		so there are 2^6 sets and 2^7 cache entries 


		since cache is write through, for correct implementation RAM Should contain additional buffer to send what to write 
		otherwise it may not behave as it should
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
		hlt : IN  std_ulogic := '0'; --NAI
		rdy : OUT std_ulogic := '0';
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
--	/*
		00 => x"28050105", 01 => x"F0026C01", 02 => x"2A00FA07", 03 => x"C0010010", 04 => x"CA01A306",
		05 => x"6C01048C", 06 => x"6A14B700", 07 => x"2D098504", 08 => x"3D643664", 09 => x"05BD6815",
		10 => x"AF0E0F00",
--	*/
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
	OTHERS => x"00000000"
	);

	COMPONENT cache IS 
		PORT(
			a0  : IN  std_ulogic_vector(15 DOWNTO 0);
			i0  : IN  std_ulogic_vector(31 DOWNTO 0);
			o0  : OUT std_ulogic_vector(31 DOWNTO 0);
	
			prs : OUT std_ulogic;
			clk : IN  std_ulogic);
	END COMPONENT cache;

	SIGNAL addr     : integer RANGE 16383 DOWNTO 0;
	SIGNAL mem_data : std_ulogic_vector(31 DOWNTO 0);
	SIGNAL ms_half  : std_ulogic;

	SIGNAL cache_data  : std_ulogic_vector(31 DOWNTO 0);
	SIGNAL cache_in    : std_ulogic_vector(31 DOWNTO 0);
	SIGNAL cache_valid : std_ulogic;

	SIGNAL mem_out     : std_ulogic_vector(31 DOWNTO 0);
	SIGNAL mem_in      : std_ulogic_vector(31 DOWNTO 0);
BEGIN
	c0: cache PORT MAP(a0  => a0,
	                   i0  => cache_in,
	                   o0  => cache_data,
	                   prs => cache_valid,
	                   clk => clk);

	--LSb is ignored
	--next bit is one decides whether data is in first or second half of memory
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

	mem_out <= mem_data  WHEN cache_valid /= '1'
	      ELSE cache_data;

	o0s <= mem_out(31 DOWNTO 16) WHEN ms_half = '1'
	  ELSE mem_out(15 DOWNTO  0); 
	o0d <= mem_out;

	cache_in <= mem_in   WHEN we
	       ELSE mem_data;

	--models delay
	--rdy <= '1' AFTER 10 NS, '0' AFTER 10.5   NS WHEN rising_edge(clk) AND cache_valid /= '1'
	--  ELSE '1'            , '0' AFTER  0.501 NS WHEN rising_edge(clk) AND cache_valid  = '1'
	--  ELSE UNAFFECTED;
	--stub 
	rdy <= '1';

END ARCHITECTURE behav; 



--cache
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY cache IS 
	PORT(
		a0  : IN  std_ulogic_vector(15 DOWNTO 0) := x"0000";
		i0  : IN  std_ulogic_vector(31 DOWNTO 0);
		o0  : OUT std_ulogic_vector(31 DOWNTO 0);

		prs : OUT std_ulogic;
		clk : IN  std_ulogic);
END ENTITY cache;

ARCHITECTURE behav OF cache IS 
	TYPE entry IS RECORD
		valid : std_ulogic;
		tag   : std_ulogic_vector( 7 DOWNTO 0);
		data  : std_ulogic_vector(31 DOWNTO 0);
	END RECORD entry;		

	TYPE arr IS ARRAY(255 DOWNTO 0) OF entry;

	SIGNAL data : arr := (
		OTHERS => ('0', x"00", x"00000000")
	);

	SIGNAL opt0 : entry;
	SIGNAL opt1 : entry;

	SIGNAL matched_opt0 : std_ulogic;
	SIGNAL matched_opt1 : std_ulogic;

	--whether or not first entry is LRU
	SIGNAL first_lru    : std_ulogic_vector(127 DOWNTO 0);
	
	SIGNAL addr         : std_ulogic_vector(6 DOWNTO 0);

	SIGNAL adrset0      : std_ulogic_vector(6 DOWNTO 0) := "0000000";
	SIGNAL adrset1      : std_ulogic_vector(6 DOWNTO 0) := "0000000";

	SIGNAL change_lru   : std_ulogic;

	SIGNAL addr_int     : integer RANGE 127 DOWNTO 0;
BEGIN
	adrset0 <= a0(7 DOWNTO 2) & '0';
	adrset1 <= a0(7 DOWNTO 2) & '1';

	opt0 <= data(to_integer(unsigned(adrset0)));
	opt1 <= data(to_integer(unsigned(adrset1)));

	--find whether matched
	matched_opt0 <= '1' WHEN opt0.tag = a0(15 DOWNTO 8) AND opt0.valid = '1' ELSE '0';
	matched_opt1 <= '1' WHEN opt1.tag = a0(15 DOWNTO 8) AND opt1.valid = '1' ELSE '0';

	--reading logic
	o0 <= opt0.data WHEN matched_opt0
	 ELSE opt1.data WHEN matched_opt1
	 ELSE x"DEADC0DE";

	prs <= '1' WHEN matched_opt0 = '1' OR matched_opt1 = '1'
	  ELSE '0';

	
	addr_int <= to_integer(unsigned(a0(7 DOWNTO 2)));
	--choose where to write
	--if any matched use matched one
	addr <= adrset0 WHEN matched_opt0 = '1' 
	   ELSE adrset1 WHEN matched_opt1 = '1' 
	--else evict one 
	   ELSE adrset0 WHEN first_lru(addr_int)  = '1'
	   ELSE adrset1;

	change_lru <= '0' WHEN matched_opt0 = '1' 
   	         ELSE '1' WHEN matched_opt1 = '1' 
			 --change LRU to NOT evicted one
   	         ELSE '0' WHEN first_lru(addr_int)  = '1'
   	         ELSE '1';
   

	first_lru(addr_int) <= change_lru WHEN rising_edge(clk)
	                  ELSE UNAFFECTED;

	data(to_integer(unsigned(addr))) <= ('1', a0(15 DOWNTO 8), i0) WHEN rising_edge(clk)
	                               ELSE UNAFFECTED;

END ARCHITECTURE behav;

