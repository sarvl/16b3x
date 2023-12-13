LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.p_types.ALL;

ENTITY reg IS 
	GENERIC(
		size    : positive;
		def_val : std_ulogic_vector(size - 1 DOWNTO 0) := (OTHERS => '0')
	);
	PORT(
		i0  : IN  std_ulogic_vector(size - 1 DOWNTO 0);
		o0  : OUT std_ulogic_vector(size - 1 DOWNTO 0) := def_val;
		we  : IN  std_ulogic;

		clk : IN  std_ulogic
	);
END ENTITY reg;

ARCHITECTURE behav OF reg IS 
BEGIN
	o0 <= i0 WHEN rising_edge(clk) AND we = '1'
	 ELSE UNAFFECTED;
END ARCHITECTURE behav;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.p_types.ALL;

ENTITY reg_file IS 
	PORT(
		i0  : IN  t_uword;

		o0  : OUT t_uword;
		o1  : OUT t_uword;

		rd  : IN  std_ulogic_vector(2 DOWNTO 0);
		r0  : IN  std_ulogic_vector(2 DOWNTO 0);
		r1  : IN  std_ulogic_vector(2 DOWNTO 0);

		we  : IN  std_ulogic;
		clk : IN  std_ulogic
	);
END ENTITY reg_file;

ARCHITECTURE behav OF reg_file IS 

	SIGNAL d0, d1, d2, d3, d4, d5, d6, d7 : t_uword := x"0000";
BEGIN

	WITH r0 SELECT o0 <= 
		d0 WHEN "000",
		d1 WHEN "001",
		d2 WHEN "010",
		d3 WHEN "011",
		d4 WHEN "100",
		d5 WHEN "101",
		d6 WHEN "110",
		d7 WHEN OTHERS; 
	WITH r1 SELECT o1 <= 
		d0 WHEN "000",
		d1 WHEN "001",
		d2 WHEN "010",
		d3 WHEN "011",
		d4 WHEN "100",
		d5 WHEN "101",
		d6 WHEN "110",
		d7 WHEN OTHERS; 

	d0 <= i0 WHEN rd = "000" AND we = '1' AND rising_edge(clk) ELSE UNAFFECTED;
	d1 <= i0 WHEN rd = "001" AND we = '1' AND rising_edge(clk) ELSE UNAFFECTED;
	d2 <= i0 WHEN rd = "010" AND we = '1' AND rising_edge(clk) ELSE UNAFFECTED;
	d3 <= i0 WHEN rd = "011" AND we = '1' AND rising_edge(clk) ELSE UNAFFECTED;
	d4 <= i0 WHEN rd = "100" AND we = '1' AND rising_edge(clk) ELSE UNAFFECTED;
	d5 <= i0 WHEN rd = "101" AND we = '1' AND rising_edge(clk) ELSE UNAFFECTED;
	d6 <= i0 WHEN rd = "110" AND we = '1' AND rising_edge(clk) ELSE UNAFFECTED;
	d7 <= i0 WHEN rd = "111" AND we = '1' AND rising_edge(clk) ELSE UNAFFECTED;

END ARCHITECTURE behav;
