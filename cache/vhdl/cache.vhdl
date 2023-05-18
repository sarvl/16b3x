LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY cache IS 
	PORT(
		a0  : IN  std_logic_vector(15 DOWNTO 0);
		i0  : IN  std_logic_vector(15 DOWNTO 0);
		o0  : OUT std_logic_vector(15 DOWNTO 0);

		we  : IN  std_logic := '0';
		prs : OUT std_logic;
		clk : IN  std_logic);

END ENTITY cache;

ARCHITECTURE behav OF cache IS
	TYPE entry IS RECORD 
		valid : std_logic;
		tag   : std_logic_vector( 7 DOWNTO 0);
		data  : std_logic_vector(15 DOWNTO 0);
	END RECORD entry;

	TYPE arr IS ARRAY(255 DOWNTO 0) OF entry;

	SIGNAL datam : arr := (
		OTHERS => ('0', x"00", x"0000")
	);

	SIGNAL opt0 : entry; 
	SIGNAL opt1 : entry; 

	SIGNAL matched_opt0 : std_logic;
	SIGNAL matched_opt1 : std_logic;

	--represents whether first tag is LRU
	SIGNAL first_lru : std_logic_vector(127 DOWNTO 0);

	SIGNAL addr : std_logic_vector(7 DOWNTO 0);

	SIGNAL adrset0 : std_logic_vector(7 DOWNTO 0);
	SIGNAL adrset1 : std_logic_vector(7 DOWNTO 0);

	SIGNAL change_lru : std_logic;

BEGIN
	adrset0 <= a0(7 DOWNTO 1) & '0';
	adrset1 <= a0(7 DOWNTO 1) & '1';

	opt0 <= datam(to_integer(unsigned(adrset0)));
	opt1 <= datam(to_integer(unsigned(adrset1)));

	matched_opt0 <= '1' WHEN opt0.tag = a0(15 DOWNTO 8) AND opt0.valid = '1' ELSE '0';
	matched_opt1 <= '1' WHEN opt1.tag = a0(15 DOWNTO 8) AND opt1.valid = '1' ELSE '0';

	o0 <= opt0.data WHEN matched_opt0 
	 ELSE opt1.data WHEN matched_opt1
	 ELSE x"DEAD";

	prs <= '1' WHEN matched_opt0 = '1' OR matched_opt1 = '1' 
	  ELSE '0';

	addr <= adrset0 WHEN first_lru(to_integer(unsigned(a0(7 DOWNTO 1))))  = '1' OR matched_opt0 = '1'
	   ELSE adrset1 WHEN first_lru(to_integer(unsigned(a0(7 DOWNTO 1)))) /= '1' OR matched_opt1 = '1';
	
	change_lru <= '0' WHEN first_lru(to_integer(unsigned(a0(7 DOWNTO 1))))  = '1' OR matched_opt0 = '1'
	         ELSE '1' WHEN first_lru(to_integer(unsigned(a0(7 DOWNTO 1)))) /= '1' OR matched_opt1 = '1';

	first_lru(to_integer(unsigned(a0(7 DOWNTO 1)))) <= change_lru WHEN rising_edge(clk) AND we = '1';

	datam(to_integer(unsigned(addr))) <= 
	       ('1', a0(15 DOWNTO 8), i0)
  	  WHEN rising_edge(clk)   AND we = '1';

	


END ARCHITECTURE behav;
