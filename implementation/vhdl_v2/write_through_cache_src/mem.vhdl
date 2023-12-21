LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_types.ALL;

ENTITY memory IS 
	GENERIC(
		delay : time := 0 NS
	);
	PORT(
		ia            : IN    t_rword := x"0000";
		iodata        : INOUT t_rword := x"0000";
	
		--determines whether to read/write value
		rd            : IN  std_logic := '0';
		wr            : IN  std_logic := '0';
	
		--if read or write, delay after which memory is usable again
		rdy           : OUT std_logic := '0';
	
		disable_delay : IN std_ulogic := '0';
		clk           : IN std_ulogic := '0'
	);
END ENTITY memory;


ARCHITECTURE behav OF memory IS 
--	TYPE arr IS ARRAY(32768 - 1 DOWNTO 0) OF t_uword;

	SIGNAL mem : t_mem_arr := (
		OTHERS => (OTHERS => 'Z')
	);

	SIGNAL addr : integer RANGE 32768 - 1 DOWNTO 0 := 0;
BEGIN
	
	--last bit is ignored since addres is assumed to be aligned
	addr <= to_integer(unsigned(ia(15 DOWNTO 1)));
	
	mem(addr) <= iodata    WHEN wr = '1' AND rising_edge(clk)
	         ELSE UNAFFECTED;
	iodata    <= mem(addr) WHEN rd = '1'
	        ELSE x"ZZZZ";

	--really verify that
	rdy <= '1'             WHEN disable_delay = '1'
	-- + 1 PS for delay = 0
	  ELSE '0', '1' AFTER delay + 1 PS WHEN rdy = '1' AND (rd OR WR) = '1' AND rising_edge(clk)
	  ELSE UNAFFECTED;
	  
END ARCHITECTURE behav;
