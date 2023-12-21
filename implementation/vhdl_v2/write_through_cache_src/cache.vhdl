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
	TYPE t_cache_entry IS RECORD 
		present : std_ulogic;
		tag     : std_ulogic_vector(7 DOWNTO 0);
		data    : t_rword;
	END RECORD t_cache_entry;

	TYPE t_arr IS ARRAY(128 - 1 DOWNTO 0) OF t_cache_entry;

	SIGNAL mem : t_arr := (
		OTHERS => (present => '0', tag => x"00", data => x"BEEF")
	);

	SIGNAL addr : integer RANGE 128 - 1 DOWNTO 0 := 0;
	

	SIGNAL cur_entry : t_cache_entry := (present => '0', tag => x"00", data => x"0000");
BEGIN
	
	--addr is index part
	addr <= to_integer(unsigned(ia( 7 DOWNTO 1)));
	cur_entry <= mem(addr);

	iodata    <= cur_entry.data WHEN rd = '1' AND cur_entry.present = '1' AND cur_entry.tag = ia(15 DOWNTO 8)
	        ELSE x"ZZZZ";

	opresent <= '1' WHEN cur_entry.present = '1' AND cur_entry.tag = ia(15 DOWNTO 8)
	       ELSE '0';
	--always write to cache
	mem(addr) <= (present => '1', tag => ia(15 DOWNTO 8), data => iodata) WHEN (rd = '1' OR wr = '1') AND rising_edge(clk)
	        ELSE UNAFFECTED;

	rdy <= '1'            WHEN disable_delay = '1'
	  ELSE '0', '1' AFTER delay + 1 PS WHEN rdy = '1' AND (rd OR WR) = '1' AND rising_edge(clk)
	  ELSE UNAFFECTED;

END ARCHITECTURE behav;
