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
		OTHERS => (present => '0', dirty => '0', tag => x"00", data => x"ZZZZ")
	);

	SIGNAL addr : integer RANGE 128 - 1 DOWNTO 0 := 0;
	

	SIGNAL cur_entry : t_cache_entry := (present => '0', dirty => '0', tag => x"00", data => x"0000");
	SIGNAL cur_entry_same     : std_ulogic := '0';
	SIGNAL cur_entry_conflict : std_ulogic := '0';
BEGIN
	
	--addr is index part
	addr <= to_integer(unsigned(ia( 7 DOWNTO 1)));
	cur_entry <= mem(addr);

	iodata    <= cur_entry.data WHEN rd = '1' AND cur_entry.present = '1' AND cur_entry.tag = ia(15 DOWNTO 8)
	        ELSE x"ZZZZ";

	cur_entry_same <= '1' WHEN cur_entry.present = '1' AND cur_entry.tag = ia(15 DOWNTO 8)
	             ELSE '0';
	cur_entry_conflict <= '1' WHEN cur_entry.present = '1' AND cur_entry.tag /= ia(15 DOWNTO 8) AND cur_entry.dirty = '1'
	                 ELSE '0';
	opresent <= cur_entry_same; 

	--when evicts, clear current one
	mem(addr) <= (present => '0', dirty => '0', tag => x"00", data => x"ZZZZ") WHEN cur_entry_conflict = '1' AND rising_edge(clk) 
	        ELSE (present => '1', 
	--dirty when write or there was write to that exact location
	              dirty   => (wr OR (cur_entry.dirty AND cur_entry_same)),
	              tag     => ia(15 DOWNTO 8), 
	              data    => iodata) 
	                WHEN (rd = '1' OR wr = '1') AND rising_edge(clk)
	        ELSE UNAFFECTED;
	
	oevictedp <= cur_entry_conflict; 
	oevictedd <= cur_entry.data;
	--                    tag       set         block offset 
	oevicteda <= cur_entry.tag & ia(7 DOWNTO 1) & '0';


	lbl1: IF delay = 0 FS GENERATE
		rdy <= '1';
	END GENERATE;
	lbl2: IF delay /= 0 FS GENERATE
		rdy <= '1'             WHEN disable_delay = '1'
		  ELSE '0', '1' AFTER delay WHEN rdy = '1' AND (rd OR WR) = '1' AND rising_edge(clk)
		  ELSE UNAFFECTED;
	END GENERATE;

END ARCHITECTURE behav;
