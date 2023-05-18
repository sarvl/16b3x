LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY arith_full_adder IS 
	PORT(
		i0 : IN  std_logic;
		i1 : IN  std_logic;
		ic : IN  std_logic;
		o0 : OUT std_logic;
		oc : OUT std_logic);
END ENTITY;


ARCHITECTURE behav OF arith_full_adder IS 
	COMPONENT gate_and2 IS 
		PORT(
			i0 : IN  std_logic;
			i1 : IN  std_logic;
			o0 : OUT std_logic);
	END COMPONENT;
	COMPONENT gate_orr3 IS 
		PORT(
			i0 : IN  std_logic;
			i1 : IN  std_logic;
			i2 : IN  std_logic;
			o0 : OUT std_logic);
	END COMPONENT;
	COMPONENT gate_xor3 IS 
		PORT(
			i0 : IN  std_logic;
			i1 : IN  std_logic;
			i2 : IN  std_logic;
			o0 : OUT std_logic);
	END COMPONENT;

	SIGNAL c0, c1, c2 : std_logic;

BEGIN

	a0: gate_and2 PORT MAP(i0, i1, c0);
	a1: gate_and2 PORT MAP(i0, ic, c1);
	a2: gate_and2 PORT MAP(i1, ic, c2);
	
	co: gate_orr3 PORT MAP(c0, c1, c2, oc);

	xr: gate_xor3 PORT MAP(i0, i1, ic, o0);
END ARCHITECTURE behav;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY arith_adder_16bit IS 
	PORT (
		i0: IN  std_logic_vector(15 DOWNTO 0);
		i1: IN  std_logic_vector(15 DOWNTO 0);
		ic: IN  std_logic;
		
		o0: OUT std_logic_vector(15 DOWNTO 0);
		oc: OUT std_logic);
END ENTITY arith_adder_16bit; 

ARCHITECTURE behav OF arith_adder_16bit IS
	COMPONENT arith_full_adder IS 
		PORT(
			i0 : IN  std_logic;
			i1 : IN  std_logic;
			ic : IN  std_logic;
			o0 : OUT std_logic;
			oc : OUT std_logic);
	END COMPONENT arith_full_adder;

	--carry to 
	SIGNAL ct : std_logic_vector(16 DOWNTO 0);

BEGIN
	ct(0) <= ic;

	u0: arith_full_adder PORT MAP(i0(00), i1(00), ct(00), o0(00), ct(01));
	u1: arith_full_adder PORT MAP(i0(01), i1(01), ct(01), o0(01), ct(02));
	u2: arith_full_adder PORT MAP(i0(02), i1(02), ct(02), o0(02), ct(03));
	u3: arith_full_adder PORT MAP(i0(03), i1(03), ct(03), o0(03), ct(04));
	u4: arith_full_adder PORT MAP(i0(04), i1(04), ct(04), o0(04), ct(05));
	u5: arith_full_adder PORT MAP(i0(05), i1(05), ct(05), o0(05), ct(06));
	u6: arith_full_adder PORT MAP(i0(06), i1(06), ct(06), o0(06), ct(07));
	u7: arith_full_adder PORT MAP(i0(07), i1(07), ct(07), o0(07), ct(08));
	u8: arith_full_adder PORT MAP(i0(08), i1(08), ct(08), o0(08), ct(09));
	u9: arith_full_adder PORT MAP(i0(09), i1(09), ct(09), o0(09), ct(10));
	uA: arith_full_adder PORT MAP(i0(10), i1(10), ct(10), o0(10), ct(11));
	uB: arith_full_adder PORT MAP(i0(11), i1(11), ct(11), o0(11), ct(12));
	uC: arith_full_adder PORT MAP(i0(12), i1(12), ct(12), o0(12), ct(13));
	uD: arith_full_adder PORT MAP(i0(13), i1(13), ct(13), o0(13), ct(14));
	uE: arith_full_adder PORT MAP(i0(14), i1(14), ct(14), o0(14), ct(15));
	uF: arith_full_adder PORT MAP(i0(15), i1(15), ct(15), o0(15), ct(16));


	oc <= ct(16);

END ARCHITECTURE behav;



LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY arith_shifter_left_16bit IS
	PORT(
		i0 : IN  std_logic_vector(15 DOWNTO 0);
		o0 : OUT std_logic_vector(15 DOWNTO 0);

		am : IN  std_logic_vector(3 DOWNTO 0));
END ENTITY arith_shifter_left_16bit;

ARCHITECTURE behav OF arith_shifter_left_16bit IS
	SIGNAL t0, t1, t2 : std_logic_vector(15 DOWNTO 0);
BEGIN
	t0 <= i0(14 DOWNTO 0) &        "0" WHEN am(0) = '1' ELSE i0;	
	t1 <= t0(13 DOWNTO 0) &       "00" WHEN am(1) = '1' ELSE t0;	
	t2 <= t1(11 DOWNTO 0) &     "0000" WHEN am(2) = '1' ELSE t1;	
	o0 <= t2(07 DOWNTO 0) & "00000000" WHEN am(3) = '1' ELSE t2;
END ARCHITECTURE behav;



LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY arith_shifter_right_16bit IS
	PORT(
		i0 : IN  std_logic_vector(15 DOWNTO 0);
		o0 : OUT std_logic_vector(15 DOWNTO 0);

		am : IN  std_logic_vector(3 DOWNTO 0));
END ENTITY arith_shifter_right_16bit;

ARCHITECTURE behav OF arith_shifter_right_16bit IS
	SIGNAL t0, t1, t2 : std_logic_vector(15 DOWNTO 0);
BEGIN
	t0 <=         "0" & i0(15 DOWNTO 1) WHEN am(0) = '1' ELSE i0;	
	t1 <=        "00" & t0(15 DOWNTO 2) WHEN am(1) = '1' ELSE t0;	
	t2 <=      "0000" & t1(15 DOWNTO 4) WHEN am(2) = '1' ELSE t1;	
	o0 <=  "00000000" & t2(15 DOWNTO 8) WHEN am(3) = '1' ELSE t2;
END ARCHITECTURE behav;



