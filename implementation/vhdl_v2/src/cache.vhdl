LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_types.ALL;

--generally speaking, cache is the same as memory in interface except for "present" signal
--however the implementation is slightly different


/*
	15         8 7     1    0
	+-----------+-------+----+
	|    TAG    | INDEX | BO |
	+-----------+-------+----+

*/

ENTITY cache IS 
	GENERIC(
		delay : time := 0 NS
	);
	PORT(
		ia            : IN    t_rword := x"0000";
		iodata        : INOUT t_rword := x"0000";
		opresent      : OUT   std_ulogic := '0';

		oevicteda     : OUT   t_rword := x"0000";
		oevictedd     : OUT   t_rword := x"0000";
		oevictedp     : OUT   std_ulogic := '0';
	
		--determines whether to read/write value
		rd            : IN  std_logic := '0';
		wr            : IN  std_logic := '0';
	
		--if read or write, delay after which memory is usable again
		rdy           : OUT std_logic := '0';
	
		disable_delay : IN std_ulogic := '1';
		clk           : IN std_ulogic := '0'
	);
END ENTITY cache;

ARCHITECTURE behav OF cache IS 
	SIGNAL mem : t_csh_arr := (
		OTHERS => (OTHERS => (present => '0', dirty => '0', tag => x"00", data => x"ZZZZ"))
	);

	--denotes which one is LRU 
	--0 means first, 1 means second
	SIGNAL lru : std_ulogic_vector(128 - 1 DOWNTO 0) := (OTHERS => '0');

	SIGNAL addr : integer RANGE 128 - 1 DOWNTO 0 := 0;
	
	SIGNAL cur_entry_0          : t_cache_entry := (present => '0', dirty => '0', tag => x"00", data => x"0000");
	SIGNAL cur_entry_0_same     : std_ulogic := '0';
	SIGNAL cur_entry_1          : t_cache_entry := (present => '0', dirty => '0', tag => x"00", data => x"0000");
	SIGNAL cur_entry_1_same     : std_ulogic := '0';
	SIGNAL evicted_entry        : t_cache_entry;
	SIGNAL eviction             : std_ulogic := '0';
	SIGNAL none_same            : std_ulogic := '0';

	SIGNAL acs                  : std_ulogic := '0';
BEGIN
	
	--addr is set index part
	addr <= to_integer(unsigned(ia( 7 DOWNTO 1)));
	cur_entry_0 <= mem(addr)(0);
	cur_entry_1 <= mem(addr)(1);

	iodata    <= cur_entry_0.data WHEN rd AND cur_entry_0_same
	        ELSE cur_entry_1.data WHEN rd AND cur_entry_1_same 
	        ELSE x"ZZZZ";

	--2 cannot be same at the same time because tags will differ
	acs <= wr OR rd;
	cur_entry_0_same <= acs WHEN cur_entry_0.present = '1' AND cur_entry_0.tag = ia(15 DOWNTO 8)
	               ELSE '0';
	cur_entry_1_same <= acs WHEN cur_entry_1.present = '1' AND cur_entry_1.tag = ia(15 DOWNTO 8)
	               ELSE '0';

	none_same        <= acs AND NOT (cur_entry_0_same OR cur_entry_1_same); 

	--when evicts, clear current one
	--when hit               : add to the one that hits 
	--when miss and     empty: write to empty 
	--when miss and not empty: evict LRU and let the cpu adjust because writeback 
	mem(addr) <= (cur_entry_1, (present => '1', dirty => (wr OR cur_entry_0.dirty), tag => ia(15 DOWNTO 8), data =>  iodata)) 
	               WHEN (cur_entry_0_same = '1' AND rising_edge(clk))
	        ELSE ((present  => '1', dirty => (wr OR cur_entry_1.dirty), tag => ia(15 DOWNTO 8), data =>  iodata),  cur_entry_0) 
	               WHEN (cur_entry_1_same = '1' AND rising_edge(clk)) 

	        ELSE (cur_entry_1, (present  => '1', dirty =>  wr                      , tag => ia(15 DOWNTO 8), data =>  iodata)) 
	               WHEN (none_same        = '1' AND rising_edge(clk) AND cur_entry_0.present = '0') 
	        ELSE ((present => '1', dirty =>  wr                      , tag => ia(15 DOWNTO 8), data =>  iodata), cur_entry_0) 
	               WHEN (none_same        = '1' AND rising_edge(clk) AND cur_entry_1.present = '0') 

	        ELSE (cur_entry_1, (present  => '0', dirty => '0'                      , tag => x"00"          , data => x"ZZZZ")) 
	               WHEN (none_same        = '1' AND rising_edge(clk) AND lru(addr) = '0') --lru is 0 
	        ELSE ((present => '0', dirty => '0'                      , tag => x"00"          , data => x"ZZZZ"), cur_entry_0) 
	               WHEN (none_same        = '1' AND rising_edge(clk) AND lru(addr) = '1') --lru is 1 
	        ELSE UNAFFECTED;

	--yes, 0 if 1, 1 if 0, it should be like this
	--when evicts, clear current one
	--when hit               : add to the one that hits 
	--when miss and     empty: write to empty 
	--when miss and not empty: evict LRU and let the cpu adjust because writeback 
	lru(addr) <= '1'           WHEN (cur_entry_0_same = '1' AND rising_edge(clk))
	        ELSE '0'           WHEN (cur_entry_1_same = '1' AND rising_edge(clk))
	        ELSE '1'           WHEN (none_same        = '1' AND rising_edge(clk) AND cur_entry_0.present = '0') 
	        ELSE '0'           WHEN (none_same        = '1' AND rising_edge(clk) AND cur_entry_1.present = '0')  
	        ELSE NOT lru(addr) WHEN (none_same        = '1' AND rising_edge(clk))
	        ELSE UNAFFECTED;


	opresent <= cur_entry_0_same OR cur_entry_1_same;
	iodata   <= cur_entry_0.data WHEN cur_entry_0_same AND rd 
	       ELSE cur_entry_1.data WHEN cur_entry_1_same AND rd 
	       ELSE x"ZZZZ";

	eviction      <= none_same AND cur_entry_0.present AND cur_entry_1.present;
	evicted_entry <= cur_entry_0 WHEN eviction ='1' AND lru(addr) = '0' 
	            ELSE cur_entry_1;
	
	oevictedp <= eviction AND evicted_entry.dirty; 
	oevictedd <= evicted_entry.data; 
	--                         tag       set        block offset 
	oevicteda <= evicted_entry.tag & ia(7 DOWNTO 1) & '0'; 


	lbl1: IF delay = 0 FS GENERATE
		rdy <= '1';
	END GENERATE;
	lbl2: IF delay /= 0 FS GENERATE
		rdy <= '1'             WHEN disable_delay = '1'
		  ELSE '0', '1' AFTER delay WHEN rdy = '1' AND (rd OR WR) = '1' AND rising_edge(clk)
		  ELSE UNAFFECTED;
	END GENERATE;

END ARCHITECTURE behav;
