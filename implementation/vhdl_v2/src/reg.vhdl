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


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_types.ALL;

ENTITY reg_file_oooe IS 
	PORT(
		i00  : IN  t_uword;
		i10  : IN  t_uword;

		o00  : OUT t_uword;
		o01  : OUT t_uword;
		o10  : OUT t_uword;
		o11  : OUT t_uword;

		r0d  : IN  std_ulogic_vector(3 DOWNTO 0);
		r00  : IN  std_ulogic_vector(3 DOWNTO 0);
		r01  : IN  std_ulogic_vector(3 DOWNTO 0);
		r1d  : IN  std_ulogic_vector(3 DOWNTO 0);
		r10  : IN  std_ulogic_vector(3 DOWNTO 0);
		r11  : IN  std_ulogic_vector(3 DOWNTO 0);

		we0  : IN  std_ulogic;
		we1  : IN  std_ulogic;

		clk  : IN  std_ulogic
	);
END ENTITY reg_file_oooe;

ARCHITECTURE behav OF reg_file_oooe IS 

	SIGNAL data : t_reg_arr := (OTHERS => x"0000");
BEGIN

	o00 <= data(to_integer(unsigned(r00)));
	o01 <= data(to_integer(unsigned(r01)));
	o10 <= data(to_integer(unsigned(r10)));
	o11 <= data(to_integer(unsigned(r11)));
	PROCESS (clk) IS 
	BEGIN
		IF rising_edge(clk) THEN
			data(to_integer(unsigned(r0d))) <= i00 WHEN we0;
			data(to_integer(unsigned(r1d))) <= i10 WHEN we1;
		END IF;
	END PROCESS;

END ARCHITECTURE behav;
