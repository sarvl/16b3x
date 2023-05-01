LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_and2 IS 
	PORT(
			i0 : IN  std_logic;
			i1 : IN  std_logic;
			o0 : OUT std_logic);
END ENTITY gate_and2;

ARCHITECTURE behav OF gate_and2 IS 
BEGIN
	o0 <= i0 AND i1;
END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_and3 IS 
	PORT(
			i0 : IN  std_logic;
			i1 : IN  std_logic;
			i2 : IN  std_logic;
			o0 : OUT std_logic);
END ENTITY gate_and3;

ARCHITECTURE behav OF gate_and3 IS 
BEGIN
	o0 <= i0 AND i1 AND i2;
END ARCHITECTURE behav;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_and2_16bit IS 
	PORT(
			i0 : IN  std_logic_vector(15 DOWNTO 0);
			i1 : IN  std_logic_vector(15 DOWNTO 0);
			o0 : OUT std_logic_vector(15 DOWNTO 0));
END ENTITY gate_and2_16bit;

ARCHITECTURE behav OF gate_and2_16bit IS 
	COMPONENT gate_and2 IS 
		PORT(
				i0 : IN  std_logic;
				i1 : IN  std_logic;
				o0 : OUT std_logic);
	END COMPONENT gate_and2;
BEGIN
	u0: gate_and2 PORT MAP(i0(00), i1(00), o0(00));
	u1: gate_and2 PORT MAP(i0(01), i1(01), o0(01));
	u2: gate_and2 PORT MAP(i0(02), i1(02), o0(02));
	u3: gate_and2 PORT MAP(i0(03), i1(03), o0(03));
	u4: gate_and2 PORT MAP(i0(04), i1(04), o0(04));
	u5: gate_and2 PORT MAP(i0(05), i1(05), o0(05));
	u6: gate_and2 PORT MAP(i0(06), i1(06), o0(06));
	u7: gate_and2 PORT MAP(i0(07), i1(07), o0(07));
	u8: gate_and2 PORT MAP(i0(08), i1(08), o0(08));
	u9: gate_and2 PORT MAP(i0(09), i1(09), o0(09));
	uA: gate_and2 PORT MAP(i0(10), i1(10), o0(10));
	uB: gate_and2 PORT MAP(i0(11), i1(11), o0(11));
	uC: gate_and2 PORT MAP(i0(12), i1(12), o0(12));
	uD: gate_and2 PORT MAP(i0(13), i1(13), o0(13));
	uE: gate_and2 PORT MAP(i0(14), i1(14), o0(14));
	uF: gate_and2 PORT MAP(i0(15), i1(15), o0(15));
END ARCHITECTURE behav;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_and2_3bit IS 
	PORT(
			i0 : IN  std_logic_vector(2 DOWNTO 0);
			i1 : IN  std_logic_vector(2 DOWNTO 0);
			o0 : OUT std_logic_vector(2 DOWNTO 0));
END ENTITY gate_and2_3bit;

ARCHITECTURE behav OF gate_and2_3bit IS 
	COMPONENT gate_and2 IS 
		PORT(
				i0 : IN  std_logic;
				i1 : IN  std_logic;
				o0 : OUT std_logic);
	END COMPONENT gate_and2;
BEGIN
	u0: gate_and2 PORT MAP(i0(00), i1(00), o0(00));
	u1: gate_and2 PORT MAP(i0(01), i1(01), o0(01));
	u2: gate_and2 PORT MAP(i0(02), i1(02), o0(02));
END ARCHITECTURE behav;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_orr2 IS 
	PORT(
			i0 : IN  std_logic;
			i1 : IN  std_logic;
			o0 : OUT std_logic);
END ENTITY gate_orr2;

ARCHITECTURE behav OF gate_orr2 IS 
BEGIN
	o0 <= i0 OR  i1;
END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_orr3 IS 
	PORT(
			i0 : IN  std_logic;
			i1 : IN  std_logic;
			i2 : IN  std_logic;
			o0 : OUT std_logic);
END ENTITY gate_orr3;

ARCHITECTURE behav OF gate_orr3 IS 
BEGIN
	o0 <= i0 OR i1 OR i2;
END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_orr2_16bit IS 
	PORT(
			i0 : IN  std_logic_vector(15 DOWNTO 0);
			i1 : IN  std_logic_vector(15 DOWNTO 0);
			o0 : OUT std_logic_vector(15 DOWNTO 0));
END ENTITY gate_orr2_16bit;

ARCHITECTURE behav OF gate_orr2_16bit IS 
	COMPONENT gate_orr2 IS 
		PORT(
				i0 : IN  std_logic;
				i1 : IN  std_logic;
				o0 : OUT std_logic);
	END COMPONENT gate_orr2;
BEGIN
	u0: gate_orr2 PORT MAP(i0(00), i1(00), o0(00));
	u1: gate_orr2 PORT MAP(i0(01), i1(01), o0(01));
	u2: gate_orr2 PORT MAP(i0(02), i1(02), o0(02));
	u3: gate_orr2 PORT MAP(i0(03), i1(03), o0(03));
	u4: gate_orr2 PORT MAP(i0(04), i1(04), o0(04));
	u5: gate_orr2 PORT MAP(i0(05), i1(05), o0(05));
	u6: gate_orr2 PORT MAP(i0(06), i1(06), o0(06));
	u7: gate_orr2 PORT MAP(i0(07), i1(07), o0(07));
	u8: gate_orr2 PORT MAP(i0(08), i1(08), o0(08));
	u9: gate_orr2 PORT MAP(i0(09), i1(09), o0(09));
	uA: gate_orr2 PORT MAP(i0(10), i1(10), o0(10));
	uB: gate_orr2 PORT MAP(i0(11), i1(11), o0(11));
	uC: gate_orr2 PORT MAP(i0(12), i1(12), o0(12));
	uD: gate_orr2 PORT MAP(i0(13), i1(13), o0(13));
	uE: gate_orr2 PORT MAP(i0(14), i1(14), o0(14));
	uF: gate_orr2 PORT MAP(i0(15), i1(15), o0(15));
END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_xor2 IS 
	PORT(
			i0 : IN  std_logic;
			i1 : IN  std_logic;
			o0 : OUT std_logic);
END ENTITY gate_xor2;

ARCHITECTURE behav OF gate_xor2 IS 
BEGIN
	o0 <= i0 XOR i1;
END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_xor3 IS 
	PORT(
			i0 : IN  std_logic;
			i1 : IN  std_logic;
			i2 : IN  std_logic;
			o0 : OUT std_logic);
END ENTITY gate_xor3;

ARCHITECTURE behav OF gate_xor3 IS 
BEGIN
	o0 <= i0 XOR i1 XOR i2;
END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_xor2_16bit IS 
	PORT(
			i0 : IN  std_logic_vector(15 DOWNTO 0);
			i1 : IN  std_logic_vector(15 DOWNTO 0);
			o0 : OUT std_logic_vector(15 DOWNTO 0));
END ENTITY gate_xor2_16bit;

ARCHITECTURE behav OF gate_xor2_16bit IS 
	COMPONENT gate_xor2 IS 
		PORT(
				i0 : IN  std_logic;
				i1 : IN  std_logic;
				o0 : OUT std_logic);
	END COMPONENT gate_xor2;
BEGIN
	u0: gate_xor2 PORT MAP(i0(00), i1(00), o0(00));
	u1: gate_xor2 PORT MAP(i0(01), i1(01), o0(01));
	u2: gate_xor2 PORT MAP(i0(02), i1(02), o0(02));
	u3: gate_xor2 PORT MAP(i0(03), i1(03), o0(03));
	u4: gate_xor2 PORT MAP(i0(04), i1(04), o0(04));
	u5: gate_xor2 PORT MAP(i0(05), i1(05), o0(05));
	u6: gate_xor2 PORT MAP(i0(06), i1(06), o0(06));
	u7: gate_xor2 PORT MAP(i0(07), i1(07), o0(07));
	u8: gate_xor2 PORT MAP(i0(08), i1(08), o0(08));
	u9: gate_xor2 PORT MAP(i0(09), i1(09), o0(09));
	uA: gate_xor2 PORT MAP(i0(10), i1(10), o0(10));
	uB: gate_xor2 PORT MAP(i0(11), i1(11), o0(11));
	uC: gate_xor2 PORT MAP(i0(12), i1(12), o0(12));
	uD: gate_xor2 PORT MAP(i0(13), i1(13), o0(13));
	uE: gate_xor2 PORT MAP(i0(14), i1(14), o0(14));
	uF: gate_xor2 PORT MAP(i0(15), i1(15), o0(15));
END ARCHITECTURE behav;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_not IS 
	PORT(
			i0 : IN  std_logic;
			o0 : OUT std_logic);
END ENTITY gate_not;

ARCHITECTURE behav OF gate_not IS 
BEGIN
	o0 <= NOT i0;
END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY gate_not_16bit IS 
	PORT(
			i0 : IN  std_logic_vector(15 DOWNTO 0);
			o0 : OUT std_logic_vector(15 DOWNTO 0));
END ENTITY gate_not_16bit;

ARCHITECTURE behav OF gate_not_16bit IS 
	COMPONENT gate_not IS 
		PORT(
				i0 : IN  std_logic;
				o0 : OUT std_logic);
	END COMPONENT gate_not;
BEGIN
	u0: gate_not PORT MAP(i0(00), o0(00));
	u1: gate_not PORT MAP(i0(01), o0(01));
	u2: gate_not PORT MAP(i0(02), o0(02));
	u3: gate_not PORT MAP(i0(03), o0(03));
	u4: gate_not PORT MAP(i0(04), o0(04));
	u5: gate_not PORT MAP(i0(05), o0(05));
	u6: gate_not PORT MAP(i0(06), o0(06));
	u7: gate_not PORT MAP(i0(07), o0(07));
	u8: gate_not PORT MAP(i0(08), o0(08));
	u9: gate_not PORT MAP(i0(09), o0(09));
	uA: gate_not PORT MAP(i0(10), o0(10));
	uB: gate_not PORT MAP(i0(11), o0(11));
	uC: gate_not PORT MAP(i0(12), o0(12));
	uD: gate_not PORT MAP(i0(13), o0(13));
	uE: gate_not PORT MAP(i0(14), o0(14));
	uF: gate_not PORT MAP(i0(15), o0(15));
END ARCHITECTURE behav;
