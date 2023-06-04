/*
	DUs in file in order
		reg_file
		reg
		reg_16bit
		reg_defon
		reg_flags
		stage

	Register File (reg_file) contains 8 registers addressed by ri, r0, r1
		rd    specifiec to which register to write value in i0 
		r0,r1 specify which register to output to o0,o1, respectively

		we,   when '1', enable write
		clk,  synchronization

	reg	
		provides support for storing single bit 
		input on i0, output on o0
		we for enabling write
		clk for synchronization
		defaults to '0'
	
	reg_16bit
		behaves the same as reg except on 16bit vectors
	
	reg_defon
		behaves the same as reg except defaults to '1' 

	reg_flags
		3bit reg specific to ISA
		LSb defaulted to '1' 
		only 3LSb can be written/read
		other bits default to 0 
	
	stage
		used by pipeline implementation 
		regular register convienient for storing stages

*/

--reg_file
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg_file IS 
	PORT(
		i0  : IN  std_ulogic_vector(15 DOWNTO 0);
		
		o0  : OUT std_ulogic_vector(15 DOWNTO 0);
		o1  : OUT std_ulogic_vector(15 DOWNTO 0);

		
		rd  : IN  std_ulogic_vector(2 DOWNTO 0);
		r0  : IN  std_ulogic_vector(2 DOWNTO 0);
		r1  : IN  std_ulogic_vector(2 DOWNTO 0);

		we  : IN  std_ulogic;
		clk : IN  std_ulogic);

END ENTITY reg_file;


ARCHITECTURE behav OF reg_file IS 
	COMPONENT reg_16bit IS 
		PORT(
			i0  : IN  std_ulogic_vector(15 DOWNTO 0);
			o0  : OUT std_ulogic_vector(15 DOWNTO 0);
			
			we  : IN  std_ulogic;
			clk : IN  std_ulogic);
	END COMPONENT reg_16bit;

	SIGNAL d0, d1, d2, d3, d4, d5, d6, d7 : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL w0, w1, w2, w3, w4, w5, w6, w7 : std_ulogic;

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


--reg
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg IS 
	PORT(
		i0  : IN  std_ulogic;
		o0  : OUT std_ulogic := '0';

		we  : IN  std_ulogic;
		clk : IN  std_ulogic);
END ENTITY reg;

ARCHITECTURE behav OF reg IS 
BEGIN 
	o0 <= i0 WHEN rising_edge(clk) AND we = '1'
	 ELSE UNAFFECTED;
END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- reg defon
ENTITY reg_defon IS 
	PORT(
		i0  : IN  std_ulogic;
		o0  : OUT std_ulogic := '1';

		we  : IN  std_ulogic;
		clk : IN  std_ulogic);
END ENTITY reg_defon;

ARCHITECTURE behav OF reg_defon IS 
BEGIN 
	o0 <= i0 WHEN rising_edge(clk) AND we = '1'
	 ELSE UNAFFECTED;
END ARCHITECTURE behav;


--reg 16bit
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg_16bit IS 
	PORT(
		i0  : IN  std_ulogic_vector(15 DOWNTO 0);
		o0  : OUT std_ulogic_vector(15 DOWNTO 0) := x"0000";
		
		we  : IN  std_ulogic;
		clk : IN  std_ulogic);
END ENTITY reg_16bit;

ARCHITECTURE behav OF reg_16bit IS 
	COMPONENT reg IS 
		PORT(
			i0  : IN  std_ulogic;
			o0  : OUT std_ulogic := '0';
	
			we  : IN  std_ulogic;
			clk : IN  std_ulogic);
	END COMPONENT reg;
BEGIN
	
	o0 <= i0 WHEN rising_edge(clk) AND we = '1'
	 ELSE UNAFFECTED;

END ARCHITECTURE behav;


--reg flags
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY reg_flags IS 
	PORT(
		i0  : IN  std_ulogic_vector(15 DOWNTO 0);
		o0  : OUT std_ulogic_vector(15 DOWNTO 0) := x"0001";
		
		we  : IN  std_ulogic;
		clk : IN  std_ulogic);
END ENTITY reg_flags;

ARCHITECTURE behav OF reg_flags IS 
	COMPONENT reg IS 
		PORT(
			i0  : IN  std_ulogic;
			o0  : OUT std_ulogic := '0';
	
			we  : IN  std_ulogic;
			clk : IN  std_ulogic);
	END COMPONENT reg;
	COMPONENT reg_defon IS 
		PORT(
			i0  : IN  std_ulogic;
			o0  : OUT std_ulogic := '1';
	
			we  : IN  std_ulogic;
			clk : IN  std_ulogic);
	END COMPONENT reg_defon;
BEGIN
	
	d0: reg_defon PORT MAP(i0(00), o0(00), we, clk);
	d1: reg       PORT MAP(i0(01), o0(01), we, clk);
	d2: reg       PORT MAP(i0(02), o0(02), we, clk);

END ARCHITECTURE behav;



LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

USE work.p_control.ALL;

PACKAGE p_stage IS
	TYPE t_stage IS RECORD 
		controls      : t_controls;
		r0,  r1       : std_ulogic_vector( 2 DOWNTO 0);
		rdi           : std_ulogic_vector(15 DOWNTO 0);
		op0, op1      : std_ulogic_vector(15 DOWNTO 0);
		alu_op        : std_ulogic_vector( 2 DOWNTO 0);
	END RECORD t_stage;
END PACKAGE p_stage;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

USE work.p_control.ALL;
USE work.p_stage.ALL;

ENTITY stage IS
	PORT(
		i0  : IN  t_stage;
		o0  : OUT t_stage := (controls => (OTHERS => '0'), r0 | r1 | alu_op => (OTHERS => '0'), rdi | op0 | op1 => (OTHERS => '0'));

		clk : IN  std_ulogic);
END ENTITY stage;

ARCHITECTURE behav OF stage IS 
BEGIN
	o0 <= i0 WHEN rising_edge(clk)
	 ELSE UNAFFECTED;
END ARCHITECTURE behav;

