LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY alu IS 
	PORT(
		i0 : IN  std_logic_vector(15 DOWNTO 0);
		i1 : IN  std_logic_vector(15 DOWNTO 0);

		o0 : OUT std_logic_vector(15 DOWNTO 0);

		op : IN  std_logic_vector(2 DOWNTO 0));
END ENTITY alu;

ARCHITECTURE behav OF alu IS 
	COMPONENT arith_adder_16bit IS 
		PORT (
			i0: IN  std_logic_vector(15 DOWNTO 0);
			i1: IN  std_logic_vector(15 DOWNTO 0);
			ic: IN  std_logic;
			
			o0: OUT std_logic_vector(15 DOWNTO 0);
			oc: OUT std_logic);
	END COMPONENT arith_adder_16bit; 

	COMPONENT gate_and2_16bit IS 
		PORT(
				i0 : IN  std_logic_vector(15 DOWNTO 0);
				i1 : IN  std_logic_vector(15 DOWNTO 0);
				o0 : OUT std_logic_vector(15 DOWNTO 0));
	END COMPONENT gate_and2_16bit;

	COMPONENT gate_orr2_16bit IS 
		PORT(
				i0 : IN  std_logic_vector(15 DOWNTO 0);
				i1 : IN  std_logic_vector(15 DOWNTO 0);
				o0 : OUT std_logic_vector(15 DOWNTO 0));
	END COMPONENT gate_orr2_16bit;

	COMPONENT gate_xor2_16bit IS 
		PORT(
				i0 : IN  std_logic_vector(15 DOWNTO 0);
				i1 : IN  std_logic_vector(15 DOWNTO 0);
				o0 : OUT std_logic_vector(15 DOWNTO 0));
	END COMPONENT gate_xor2_16bit;


	COMPONENT gate_not_16bit IS 
		PORT(
				i0 : IN  std_logic_vector(15 DOWNTO 0);
				o0 : OUT std_logic_vector(15 DOWNTO 0));
	END COMPONENT gate_not_16bit;

	COMPONENT arith_shifter_left_16bit IS
		PORT(
			i0 : IN  std_logic_vector(15 DOWNTO 0);
			o0 : OUT std_logic_vector(15 DOWNTO 0);
	
			am : IN  std_logic_vector(3 DOWNTO 0));
	END COMPONENT arith_shifter_left_16bit;

	COMPONENT arith_shifter_right_16bit IS
		PORT(
			i0 : IN  std_logic_vector(15 DOWNTO 0);
			o0 : OUT std_logic_vector(15 DOWNTO 0);
	
			am : IN  std_logic_vector(3 DOWNTO 0));
	END COMPONENT arith_shifter_right_16bit;


	--lacking barrel shifter, you know what to do ;]

	SIGNAL add_in1 : std_logic_vector(15 DOWNTO 0);
	SIGNAL add_tmp : std_logic_vector(15 DOWNTO 0);

	SIGNAL add_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL and_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL orr_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL xor_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL not_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL sll_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL slr_out : std_logic_vector(15 DOWNTO 0);

BEGIN
		
	add_tmp <= (OTHERS => op(0));
	subsg: gate_xor2_16bit           PORT MAP(i1, add_tmp, add_in1);
	--if subtraction doesnt happen the problem is here
	adder: arith_adder_16bit         PORT MAP(i0, add_in1, op(0), add_out, OPEN); 
	ander: gate_and2_16bit           PORT MAP(i0, i1,      and_out); 
	orrer: gate_orr2_16bit           PORT MAP(i0, i1,      orr_out); 
	xorer: gate_xor2_16bit           PORT MAP(i0, i1,      xor_out); 
	noter: gate_not_16bit            PORT MAP(i0,          not_out); 
	sller: arith_shifter_left_16bit  PORT MAP(i0, sll_out, i1(3 DOWNTO 0));
	slrer: arith_shifter_right_16bit PORT MAP(i0, slr_out, i1(3 DOWNTO 0));

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




