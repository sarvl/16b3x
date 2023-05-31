/*
	DUs in file in order:
		ALU
		multiplier
		16bit adder
		full adder
		shifter left
		shifter right

	Arithmetic and Logic Unit

	ALU provides functionality for instructions requiring computation

	table of operations per op:
		000 - o0 <=  i0 + i1
		001 - o0 <=  i0 - i1
		010 - o0 <= ¬i0 
		011 - o0 <=  i0 ∧ i1
		100 - o0 <=  i0 ∨ i1
		101 - o0 <=  i0 ⊕ i1
		110 - o0 <=  i0 << i1
		111 - o0 <=  i0 >> i1
	
	multiplier
		performs unsigned multiplication
	
	shifts operate modulo 2^4 on i1
	all instructions operate modulo 2^16 on result
*/

-- ALU 
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY alu IS
	PORT(
		i0 : IN  std_ulogic_vector(15 DOWNTO 0);
		i1 : IN  std_ulogic_vector(15 DOWNTO 0);

		o0 : OUT std_ulogic_vector(15 DOWNTO 0);
		
		op : IN  std_ulogic_vector( 2 DOWNTO 0)
	);
END ENTITY alu;


ARCHITECTURE behav OF alu IS 
	COMPONENT adder_16bit IS 
		PORT (
			i0: IN  std_ulogic_vector(15 DOWNTO 0);
			i1: IN  std_ulogic_vector(15 DOWNTO 0);
			ic: IN  std_ulogic;
			
			o0: OUT std_ulogic_vector(15 DOWNTO 0);
			oc: OUT std_ulogic);
	END COMPONENT adder_16bit; 

	COMPONENT shifter_left_16bit IS
		PORT(
			i0 : IN  std_ulogic_vector(15 DOWNTO 0);
			o0 : OUT std_ulogic_vector(15 DOWNTO 0);
	
			am : IN  std_ulogic_vector(3 DOWNTO 0));
	END COMPONENT shifter_left_16bit;

	COMPONENT shifter_right_16bit IS
		PORT(
			i0 : IN  std_ulogic_vector(15 DOWNTO 0);
			o0 : OUT std_ulogic_vector(15 DOWNTO 0);
	
			am : IN  std_ulogic_vector(3 DOWNTO 0));
	END COMPONENT shifter_right_16bit;


	SIGNAL add_in1 : std_ulogic_vector(15 DOWNTO 0);

	SIGNAL add_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL and_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL orr_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL xor_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL not_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL sll_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL slr_out : std_logic_vector(15 DOWNTO 0);

BEGIN

	--inverts input signal when it has to be subtraction
	--inputs carry
	--due to how two`s complements work
	add_in1 <= i1 XOR (15 DOWNTO 0 => op(0));
	adder:     adder_16bit PORT MAP(i0 => i0, i1 => add_in1, ic => op(0), o0 => add_out, oc => OPEN);
	
	and_out <= i0 AND i1;
	orr_out <= i0 OR  i1;
	xor_out <= i0 XOR i1;
	not_out <=    NOT i1;
	
	sller:     shifter_left_16bit  PORT MAP(i0 => i0, am => i1(3 DOWNTO 0), o0 => sll_out);
	slrer:     shifter_right_16bit PORT MAP(i0 => i0, am => i1(3 DOWNTO 0), o0 => slr_out);


	WITH op SELECT o0 <= 
		add_out WHEN "000",
		add_out WHEN "001",
		not_out WHEN "010",
		and_out WHEN "011",
		orr_out WHEN "100",
		xor_out WHEN "101",
		sll_out WHEN "110",
		slr_out WHEN OTHERS;


END ARCHITECTURE behav;


--16bit multiplier 
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY multiplier IS 
	PORT (
		i0: IN  std_ulogic_vector(15 DOWNTO 0);
		i1: IN  std_ulogic_vector(15 DOWNTO 0);
		
		o0: OUT std_ulogic_vector(15 DOWNTO 0));
END ENTITY multiplier; 

ARCHITECTURE behav OF multiplier IS
	COMPONENT adder_16bit IS 
		PORT (
			i0: IN  std_ulogic_vector(15 DOWNTO 0);
			i1: IN  std_ulogic_vector(15 DOWNTO 0);
			ic: IN  std_ulogic;
		
			o0: OUT std_ulogic_vector(15 DOWNTO 0);
			oc: OUT std_ulogic);
	END COMPONENT adder_16bit; 

	SIGNAL s0, s1, s2, s3, s4, s5, s6, s7 : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL s8, s9, sA, sB, sC, sD, sE, sF : std_ulogic_vector(15 DOWNTO 0);
	
	SIGNAL v0, v1, v2, v3, v4, v5, v6, v7 : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL v8, v9, vA, vB, vC, vD         : std_ulogic_vector(15 DOWNTO 0);

BEGIN
	--perform shifts and filter them 
	s0 <= (i0(15 DOWNTO  0)                        ) AND (15 DOWNTO 0 => i1( 0));
	s1 <= (i0(14 DOWNTO  0) & ( 0 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1( 1));
	s2 <= (i0(13 DOWNTO  0) & ( 1 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1( 2));
	s3 <= (i0(12 DOWNTO  0) & ( 2 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1( 3));
	s4 <= (i0(11 DOWNTO  0) & ( 3 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1( 4));
	s5 <= (i0(10 DOWNTO  0) & ( 4 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1( 5));
	s6 <= (i0( 9 DOWNTO  0) & ( 5 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1( 6));
	s7 <= (i0( 8 DOWNTO  0) & ( 6 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1( 7));
	s8 <= (i0( 7 DOWNTO  0) & ( 7 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1( 8));
	s9 <= (i0( 6 DOWNTO  0) & ( 8 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1( 9));
	sA <= (i0( 5 DOWNTO  0) & ( 9 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1(10));
	sB <= (i0( 4 DOWNTO  0) & (10 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1(11));
	sC <= (i0( 3 DOWNTO  0) & (11 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1(12));
	sD <= (i0( 2 DOWNTO  0) & (12 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1(13));
	sE <= (i0( 1 DOWNTO  0) & (13 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1(14));
	sF <= (i0( 0 DOWNTO  0) & (14 DOWNTO  0 => '0')) AND (15 DOWNTO 0 => i1(15));

	--combine results
	--                       i0, i1, ic,  o0, oc
	a0: adder_16bit PORT MAP(s0, s1, '0', v0, OPEN);
	a1: adder_16bit PORT MAP(s2, s3, '0', v1, OPEN);
	a2: adder_16bit PORT MAP(s4, s5, '0', v2, OPEN);
	a3: adder_16bit PORT MAP(s6, s7, '0', v3, OPEN);
	a4: adder_16bit PORT MAP(s8, s9, '0', v4, OPEN);
	a5: adder_16bit PORT MAP(sa, sb, '0', v5, OPEN);
	a6: adder_16bit PORT MAP(sc, sd, '0', v6, OPEN);
	a7: adder_16bit PORT MAP(se, sf, '0', v7, OPEN);

	a8: adder_16bit PORT MAP(v0, v1, '0', v8, OPEN);
	a9: adder_16bit PORT MAP(v2, v3, '0', v9, OPEN);
	aa: adder_16bit PORT MAP(v4, v5, '0', va, OPEN);
	ab: adder_16bit PORT MAP(v6, v7, '0', vb, OPEN);

	ac: adder_16bit PORT MAP(v8, v9, '0', vc, OPEN);
	ad: adder_16bit PORT MAP(va, vb, '0', vd, OPEN);

	ae: adder_16bit PORT MAP(vc, vd, '0', o0, OPEN);


END ARCHITECTURE behav;

--16bit adder
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY adder_16bit IS 
	PORT (
		i0: IN  std_ulogic_vector(15 DOWNTO 0);
		i1: IN  std_ulogic_vector(15 DOWNTO 0);
		ic: IN  std_ulogic;
		
		o0: OUT std_ulogic_vector(15 DOWNTO 0);
		oc: OUT std_ulogic);
END ENTITY adder_16bit; 

ARCHITECTURE behav OF adder_16bit IS
	COMPONENT full_adder IS 
		PORT(
			i0 : IN  std_ulogic;
			i1 : IN  std_ulogic;
			ic : IN  std_ulogic;
			o0 : OUT std_ulogic;
			oc : OUT std_ulogic);
	END COMPONENT full_adder;

	--carry to 
	SIGNAL ct : std_ulogic_vector(16 DOWNTO 0);

BEGIN
	ct(0) <= ic;

	u0: full_adder PORT MAP(i0(00), i1(00), ct(00), o0(00), ct(01));
	u1: full_adder PORT MAP(i0(01), i1(01), ct(01), o0(01), ct(02));
	u2: full_adder PORT MAP(i0(02), i1(02), ct(02), o0(02), ct(03));
	u3: full_adder PORT MAP(i0(03), i1(03), ct(03), o0(03), ct(04));
	u4: full_adder PORT MAP(i0(04), i1(04), ct(04), o0(04), ct(05));
	u5: full_adder PORT MAP(i0(05), i1(05), ct(05), o0(05), ct(06));
	u6: full_adder PORT MAP(i0(06), i1(06), ct(06), o0(06), ct(07));
	u7: full_adder PORT MAP(i0(07), i1(07), ct(07), o0(07), ct(08));
	u8: full_adder PORT MAP(i0(08), i1(08), ct(08), o0(08), ct(09));
	u9: full_adder PORT MAP(i0(09), i1(09), ct(09), o0(09), ct(10));
	uA: full_adder PORT MAP(i0(10), i1(10), ct(10), o0(10), ct(11));
	uB: full_adder PORT MAP(i0(11), i1(11), ct(11), o0(11), ct(12));
	uC: full_adder PORT MAP(i0(12), i1(12), ct(12), o0(12), ct(13));
	uD: full_adder PORT MAP(i0(13), i1(13), ct(13), o0(13), ct(14));
	uE: full_adder PORT MAP(i0(14), i1(14), ct(14), o0(14), ct(15));
	uF: full_adder PORT MAP(i0(15), i1(15), ct(15), o0(15), ct(16));


	oc <= ct(16);

END ARCHITECTURE behav;


--full adder
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY full_adder IS 
	PORT(
		i0 : IN  std_ulogic;
		i1 : IN  std_ulogic;
		ic : IN  std_ulogic;
		o0 : OUT std_ulogic;
		oc : OUT std_ulogic);
END ENTITY;


ARCHITECTURE behav OF full_adder IS 
BEGIN
	oc <= (i0 AND i1) OR (i0 AND ic) OR (i1 AND ic);
	o0 <= i0 XOR i1 XOR ic;
END ARCHITECTURE behav;



--shifter left
--implemented as barrel shifter
--operates mod 2^4 on second input
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY shifter_left_16bit IS
	PORT(
		i0 : IN  std_ulogic_vector(15 DOWNTO 0);
		o0 : OUT std_ulogic_vector(15 DOWNTO 0);

		am : IN  std_ulogic_vector(3 DOWNTO 0));
END ENTITY shifter_left_16bit;

ARCHITECTURE behav OF shifter_left_16bit IS
	SIGNAL t0, t1, t2 : std_ulogic_vector(15 DOWNTO 0);
BEGIN
	t0 <= i0(14 DOWNTO 0) &        "0" WHEN am(0) = '1' ELSE i0;	
	t1 <= t0(13 DOWNTO 0) &       "00" WHEN am(1) = '1' ELSE t0;	
	t2 <= t1(11 DOWNTO 0) &     "0000" WHEN am(2) = '1' ELSE t1;	
	o0 <= t2(07 DOWNTO 0) & "00000000" WHEN am(3) = '1' ELSE t2;
END ARCHITECTURE behav;


--shifter right
--implemented as barrel shifter
--operates mod 2^4 on second input
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY shifter_right_16bit IS
	PORT(
		i0 : IN  std_ulogic_vector(15 DOWNTO 0);
		o0 : OUT std_ulogic_vector(15 DOWNTO 0);

		am : IN  std_ulogic_vector(3 DOWNTO 0));
END ENTITY shifter_right_16bit;

ARCHITECTURE behav OF shifter_right_16bit IS
	SIGNAL t0, t1, t2 : std_ulogic_vector(15 DOWNTO 0);
BEGIN
	t0 <=         "0" & i0(15 DOWNTO 1) WHEN am(0) = '1' ELSE i0;	
	t1 <=        "00" & t0(15 DOWNTO 2) WHEN am(1) = '1' ELSE t0;	
	t2 <=      "0000" & t1(15 DOWNTO 4) WHEN am(2) = '1' ELSE t1;	
	o0 <=  "00000000" & t2(15 DOWNTO 8) WHEN am(3) = '1' ELSE t2;
END ARCHITECTURE behav;



