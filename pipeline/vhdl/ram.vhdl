LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ram IS
	PORT(
		a0  : IN  std_logic_vector(15 DOWNTO 0);
		i0  : IN  std_logic_vector(15 DOWNTO 0);
		o0  : OUT std_logic_vector(15 DOWNTO 0);

		we  : IN  std_logic := '0';
		clk : IN  std_logic);
END ENTITY ram;

ARCHITECTURE behav OF RAM IS 
	TYPE arr IS ARRAY(32767 DOWNTO 0) OF std_logic_vector(7 DOWNTO 0);
	SIGNAL datam : arr := (
	--fib.asm
	-- 00 => x"28", 01 => x"29", 02 => x"2F", 03 => x"8F", 04 => x"A6", 
	-- 05 => x"02", 06 => x"00", 07 => x"01", 08 => x"CF", 09 => x"A3", 
	-- 10 => x"38", 11 => x"00", 12 => x"0F",
	--fact.asm
	00 => x"A7", 01 => x"89", 02 => x"A5", 03 => x"28", 04 => x"A7", 
	05 => x"02", 06 => x"C9", 07 => x"00", 08 => x"C9", 09 => x"A1", 
	10 => x"B7", 11 => x"07", 12 => x"77", 13 => x"88", 14 => x"A6", 
	15 => x"70", 16 => x"C8", 17 => x"AB", 18 => x"79", 19 => x"AF", 
	20 => x"A7", 21 => x"28", 22 => x"7F", 23 => x"02", 24 => x"B7", 
	25 => x"28", 26 => x"AF", 27 => x"38", 28 => x"0F",
	--sort.asm
	-- x"A7", x"89", x"A5", x"28", x"A7", x"02", x"C9",
	-- x"00", x"C9", x"A1", x"B7", x"8A", x"B6", x"03",
	-- x"03", x"C0", x"C1", x"CA", x"A7", x"06", x"06",
	-- x"89", x"B6", x"02", x"03", x"C3", x"04", x"05",
	-- x"04", x"A6", x"05", x"04", x"C2", x"C3", x"03",
	-- x"A4", x"C9", x"A1", x"B7", x"2E", x"28", x"29",
	-- x"AF", x"F0", x"F8", x"00", x"CE", x"8E", x"A3",
	-- x"28", x"29", x"2A", x"AF", x"28", x"29", x"AF",
	-- x"30", x"31", x"32", x"33", x"34", x"35", x"36",
	-- x"37", x"0F",
	--pipeline_easy.asm
	-- 00 => x"28", 01 => x"29", 02 => x"2A", 03 => x"2B", 04 => x"2C", 
	-- 05 => x"2D", 06 => x"2E", 07 => x"2F", 08 => x"00", 09 => x"01", 
	-- 10 => x"02", 11 => x"03", 12 => x"04", 13 => x"05", 14 => x"06", 
	-- 15 => x"07", 16 => x"F0", 17 => x"F1", 18 => x"F2", 19 => x"F3", 
	-- 20 => x"F4", 21 => x"F5", 22 => x"F6", 23 => x"F7", 24 => x"0F",
	--pipeline_alu_dep.asm
	-- 00 => x"29", 01 => x"28", 02 => x"F0", 03 => x"02", 04 => x"F8",
	-- 05 => x"03", 06 => x"C0", 07 => x"C8", 08 => x"F8", 09 => x"04",
	-- 10 => x"0F",

		OTHERS => x"00"
	);
	SIGNAL datal : arr := (
	--fib.asm
	-- 00 => x"00", 01 => x"01", 02 => x"07", 03 => x"00", 04 => x"0A", 
	-- 05 => x"05", 06 => x"25", 07 => x"58", 08 => x"01", 09 => x"05", 
	-- 10 => x"50", 11 => x"00", 12 => x"00", 
	--fact.asm
	00 => x"19", 01 => x"00", 02 => x"05", 03 => x"00", 04 => x"0A", 
	05 => x"05", 06 => x"01", 07 => x"58", 08 => x"01", 09 => x"07", 
	10 => x"00", 11 => x"4C", 12 => x"00", 13 => x"01", 14 => x"15", 
	15 => x"00", 16 => x"01", 17 => x"0B", 18 => x"00", 19 => x"01", 
	20 => x"16", 21 => x"01", 22 => x"00", 23 => x"ED", 24 => x"00", 
	25 => x"06", 26 => x"0B", 27 => x"50", 28 => x"00",
	--sort.asm
	-- x"27", x"00", x"05", x"00", x"0A", x"05", x"01",
	-- x"58", x"01", x"07", x"00", x"00", x"00", x"06",
	-- x"27", x"02", x"02", x"02", x"0B", x"05", x"38",
	-- x"02", x"00", x"05", x"05", x"02", x"46", x"66",
	-- x"B1", x"20", x"47", x"67", x"02", x"02", x"D1",
	-- x"1A", x"02", x"13", x"00", x"A4", x"01", x"7B",
	-- x"01", x"01", x"01", x"C7", x"02", x"96", x"29",
	-- x"96", x"C8", x"10", x"0B", x"96", x"10", x"13",
	-- x"96", x"98", x"9A", x"9C", x"9E", x"A0", x"A2",
	-- x"A4", x"00",
	--pipeline_easy.asm
	-- 00 => x"00", 01 => x"01", 02 => x"02", 03 => x"03", 04 => x"04", 
	-- 05 => x"05", 06 => x"06", 07 => x"07", 08 => x"38", 09 => x"58", 
	-- 10 => x"78", 11 => x"98", 12 => x"B8", 13 => x"D8", 14 => x"F8", 
	-- 15 => x"18", 16 => x"01", 17 => x"01", 18 => x"01", 19 => x"01", 
	-- 20 => x"01", 21 => x"01", 22 => x"01", 23 => x"01", 24 => x"00",
	--pipeline_alu_dep.asm
	-- 00 => x"00", 01 => x"10", 02 => x"02", 03 => x"05", 04 => x"02",
	-- 05 => x"05", 06 => x"01", 07 => x"02", 08 => x"01", 09 => x"05",
	-- 10 => x"00",
		
		OTHERS => x"00"
	);

	SIGNAL a0m : std_logic_vector(14 DOWNTO 0);
	SIGNAL a0l : std_logic_vector(14 DOWNTO 0);
	
BEGIN
	a0m <= a0(15 DOWNTO 1);
	a0l <= a0(15 DOWNTO 1);

	datam(to_integer(unsigned(a0m))) <= i0(15 DOWNTO 8) WHEN we = '1' AND rising_edge(clk);
	datal(to_integer(unsigned(a0l))) <= i0( 7 DOWNTO 0) WHEN we = '1' AND rising_edge(clk);

	o0 <= datam(to_integer(unsigned(a0m))) 
	    & datal(to_integer(unsigned(a0l)));


END ARCHITECTURE behav;
