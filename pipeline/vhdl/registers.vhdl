LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg IS 
	PORT(
		i0  : IN  std_logic;
		o0  : OUT std_logic := '0';

		we  : IN  std_logic;
		clk : IN  std_logic);
END ENTITY reg;

ARCHITECTURE behav OF reg IS 
BEGIN 
	o0 <= i0 WHEN rising_edge(clk) AND we = '1';
END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg_defon IS 
	PORT(
		i0  : IN  std_logic;
		o0  : OUT std_logic := '1';

		we  : IN  std_logic;
		clk : IN  std_logic);
END ENTITY reg_defon;

ARCHITECTURE behav OF reg_defon IS 
BEGIN 
	o0 <= i0 WHEN rising_edge(clk) AND we = '1';
END ARCHITECTURE behav;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg_16bit IS 
	PORT(
		i0  : IN  std_logic_vector(15 DOWNTO 0);
		o0  : OUT std_logic_vector(15 DOWNTO 0);
		
		we  : IN  std_logic;
		clk : IN  std_logic);
END ENTITY reg_16bit;

ARCHITECTURE behav OF reg_16bit IS 
	COMPONENT reg IS 
		PORT(
			i0  : IN  std_logic;
			o0  : OUT std_logic := '0';
	
			we  : IN  std_logic;
			clk : IN  std_logic);
	END COMPONENT reg;
BEGIN
	
	d0: reg PORT MAP(i0(00), o0(00), we, clk);
	d1: reg PORT MAP(i0(01), o0(01), we, clk);
	d2: reg PORT MAP(i0(02), o0(02), we, clk);
	d3: reg PORT MAP(i0(03), o0(03), we, clk);
	d4: reg PORT MAP(i0(04), o0(04), we, clk);
	d5: reg PORT MAP(i0(05), o0(05), we, clk);
	d6: reg PORT MAP(i0(06), o0(06), we, clk);
	d7: reg PORT MAP(i0(07), o0(07), we, clk);
	d8: reg PORT MAP(i0(08), o0(08), we, clk);
	d9: reg PORT MAP(i0(09), o0(09), we, clk);
	dA: reg PORT MAP(i0(10), o0(10), we, clk);
	dB: reg PORT MAP(i0(11), o0(11), we, clk);
	dC: reg PORT MAP(i0(12), o0(12), we, clk);
	dD: reg PORT MAP(i0(13), o0(13), we, clk);
	dE: reg PORT MAP(i0(14), o0(14), we, clk);
	dF: reg PORT MAP(i0(15), o0(15), we, clk);


END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg_flags IS 
	PORT(
		i0  : IN  std_logic_vector(15 DOWNTO 0);
		o0  : OUT std_logic_vector(15 DOWNTO 0) := x"0001";
		
		we  : IN  std_logic;
		clk : IN  std_logic);
END ENTITY reg_flags;

ARCHITECTURE behav OF reg_flags IS 
	COMPONENT reg IS 
		PORT(
			i0  : IN  std_logic;
			o0  : OUT std_logic := '0';
	
			we  : IN  std_logic;
			clk : IN  std_logic);
	END COMPONENT reg;
	COMPONENT reg_defon IS 
		PORT(
			i0  : IN  std_logic;
			o0  : OUT std_logic := '1';
	
			we  : IN  std_logic;
			clk : IN  std_logic);
	END COMPONENT reg_defon;
BEGIN
	
	d0: reg_defon PORT MAP(i0(00), o0(00), we, clk);
	d1: reg       PORT MAP(i0(01), o0(01), we, clk);
	d2: reg       PORT MAP(i0(02), o0(02), we, clk);

END ARCHITECTURE behav;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg_file IS 
	PORT(
		i0  : IN  std_logic_vector(15 DOWNTO 0);
		
		o0  : OUT std_logic_vector(15 DOWNTO 0);
		o1  : OUT std_logic_vector(15 DOWNTO 0);

		
		rd  : IN  std_logic_vector(2 DOWNTO 0);
		r0  : IN  std_logic_vector(2 DOWNTO 0);
		r1  : IN  std_logic_vector(2 DOWNTO 0);

		we  : IN  std_logic;
		clk : IN  std_logic);

END ENTITY reg_file;


ARCHITECTURE behav OF reg_file IS 
	COMPONENT reg_16bit IS 
		PORT(
			i0  : IN  std_logic_vector(15 DOWNTO 0);
			o0  : OUT std_logic_vector(15 DOWNTO 0);
			
			we  : IN  std_logic;
			clk : IN  std_logic);
	END COMPONENT reg_16bit;

	SIGNAL d0, d1, d2, d3, d4, d5, d6, d7 : std_logic_vector(15 DOWNTO 0);
	SIGNAL w0, w1, w2, w3, w4, w5, w6, w7 : std_logic;

BEGIN

	--                      in  out  we  clk
	ur0: reg_16bit PORT MAP(i0, d0,  w0, clk);
	ur1: reg_16bit PORT MAP(i0, d1,  w1, clk);
	ur2: reg_16bit PORT MAP(i0, d2,  w2, clk);
	ur3: reg_16bit PORT MAP(i0, d3,  w3, clk);
	ur4: reg_16bit PORT MAP(i0, d4,  w4, clk);
	ur5: reg_16bit PORT MAP(i0, d5,  w5, clk);
	ur6: reg_16bit PORT MAP(i0, d6,  w6, clk);
	ur7: reg_16bit PORT MAP(i0, d7,  w7, clk);

	
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

	w0 <= '1' WHEN rd = "000" AND we = '1' ELSE '0';
	w1 <= '1' WHEN rd = "001" AND we = '1' ELSE '0';
	w2 <= '1' WHEN rd = "010" AND we = '1' ELSE '0';
	w3 <= '1' WHEN rd = "011" AND we = '1' ELSE '0';
	w4 <= '1' WHEN rd = "100" AND we = '1' ELSE '0';
	w5 <= '1' WHEN rd = "101" AND we = '1' ELSE '0';
	w6 <= '1' WHEN rd = "110" AND we = '1' ELSE '0';
	w7 <= '1' WHEN rd = "111" AND we = '1' ELSE '0';

END ARCHITECTURE behav;




