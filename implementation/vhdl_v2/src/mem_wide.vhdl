LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_types.ALL;

ENTITY memory IS 
	GENERIC(
		delay : time := 0 NS
	);
	PORT(
		ia            : IN    t_rword  := x"0000";
		iodata        : INOUT t_rdword := (OTHERS => '0');
	
		--determines whether to read/write value
		rd            : IN  std_logic := '0';
		wr            : IN  std_logic := '0';
		--mostly for initialization
		wide_wr       : IN  std_logic := '0';
	
		--if read or write, delay after which memory is usable again
		rdy           : OUT std_logic := '0';
	
		disable_delay : IN std_ulogic := '0';
		clk           : IN std_ulogic := '0'
	);
END ENTITY memory;


ARCHITECTURE behav OF memory IS 
--	TYPE arr IS ARRAY(32768 - 1 DOWNTO 0) OF t_uword;

	SIGNAL mem : t_mem_wide_arr := (
		OTHERS => (OTHERS => 'Z')
	);

	SIGNAL addr : integer RANGE 16384 - 1 DOWNTO 0 := 0;
BEGIN
	
	--2 least significant bits are ignored since addres is assumed to be aligned
	addr <= to_integer(unsigned(ia(15 DOWNTO 2)));
	
	--however for write the second to least significant bit is important
	mem(addr) <= iodata                                        WHEN wide_wr = '1'            AND rising_edge(clk)
	        ELSE iodata(31 DOWNTO 16) & mem(addr)(15 DOWNTO 0) WHEN ia(1) = '0' AND wr = '1' AND rising_edge(clk)
	        ELSE mem(addr)(31 DOWNTO 16) & iodata(15 DOWNTO 0) WHEN ia(1) = '1' AND wr = '1' AND rising_edge(clk)
	        ELSE UNAFFECTED;
	iodata    <= mem(addr) WHEN rd = '1'
	        ELSE (OTHERS => 'Z');
	
	
	lbl1: IF delay = 0 FS GENERATE
		rdy <= '1';
	END GENERATE;
	lbl2: IF delay /= 0 FS GENERATE
		rdy <= '1'             WHEN disable_delay = '1'
		  ELSE '0', '1' AFTER delay WHEN rdy = '1' AND (rd OR WR) = '1' AND rising_edge(clk)
		  ELSE UNAFFECTED;
	END GENERATE;
		  
END ARCHITECTURE behav;
