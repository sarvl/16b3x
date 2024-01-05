/*
	file containing all components implementing arithmetic operations
*/

/*
TODO:
	replace shifters with more generic versions
	replace saturating counters with generic version
*/


/*
	ALU used by core, operations are as specified by ISA
	op is 3LSb of instr opcode as thats convienient and works
*/
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.p_types.ALL;

ENTITY alu IS 
	PORT(
		i0 : IN  t_uword;
		i1 : IN  t_uword;
		o0 : OUT t_uword;

		op : IN  std_ulogic_vector( 2 DOWNTO 0)
	);
END ENTITY alu;


ARCHITECTURE behav OF alu IS 
	COMPONENT adder IS
		GENERIC (
			size : positive 
		);
		PORT(
			i0 : IN  std_ulogic_vector(size - 1 DOWNTO 0); 
			i1 : IN  std_ulogic_vector(size - 1 DOWNTO 0); 
			o0 : OUT std_ulogic_vector(size - 1 DOWNTO 0);

			ic : IN  std_ulogic; 
			oc : OUT std_ulogic
		);
	END COMPONENT adder;

	COMPONENT shifter_right_16bit IS
		PORT(
			i0    : IN  t_uword;
			iamnt : IN  std_ulogic_vector( 3 DOWNTO 0);
	
			o0    : OUT t_uword
		);
	END COMPONENT shifter_right_16bit;
	
	COMPONENT shifter_left_16bit IS 
		PORT(
			i0    : IN  t_uword;
			iamnt : IN  std_ulogic_vector( 3 DOWNTO 0);
	
			o0    : OUT t_uword
		);
	END COMPONENT shifter_left_16bit;

	SIGNAL adder_i1  : t_uword := x"0000";
	SIGNAL adder_out : t_uword := x"0000";
	SIGNAL shl_out   : t_uword := x"0000";
	SIGNAL shr_out   : t_uword := x"0000";
BEGIN

	--handles both addition and subtraction due to how 2s complement work
	c_adder: adder GENERIC MAP(size => t_word'length)
	               PORT    MAP(i0 => i0,
	                           i1 => adder_i1,
	                           ic => op(0), --LSB
	                           o0 => adder_out,
	                           oc => OPEN);

	c_shl: shifter_left_16bit  PORT MAP(i0    => i0,
	                                    iamnt => i1(3 DOWNTO 0),
	                                    o0    => shl_out); 

	c_shr: shifter_right_16bit PORT MAP(i0    => i0,
	                                    iamnt => i1(3 DOWNTO 0),
	                                    o0    => shr_out); 
	
	--negation in 2s complement (1 is added via ic in adder)
	adder_i1 <= i1 XOR (15 DOWNTO 0 => op(0));

	WITH op SELECT o0 <=
		adder_out WHEN "000", --add
		adder_out WHEN "001", --sub
		   NOT i1 WHEN "010", --not
		i0 AND i1 WHEN "011", --and
		i0 OR  i1 WHEN "100", --orr
		i0 XOR i1 WHEN "101", --xor
		shl_out   WHEN "110", --sll
		shr_out   WHEN "111", --slr
		x"UUUU"   WHEN OTHERS;

END ARCHITECTURE behav;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_types.ALL;

ENTITY adder IS
	GENERIC (
		size : positive 
	);
	PORT(
		i0 : IN  std_ulogic_vector(size - 1 DOWNTO 0); 
		i1 : IN  std_ulogic_vector(size - 1 DOWNTO 0); 
		o0 : OUT std_ulogic_vector(size - 1 DOWNTO 0);

		ic : IN  std_ulogic; 
		oc : OUT std_ulogic
	);
END ENTITY adder;

ARCHITECTURE behav OF adder IS
	--purposefuly "size" not "size - 1", to extract carry
	SIGNAL internal : std_ulogic_vector(size DOWNTO 0) := (OTHERS => '0');

BEGIN
	internal <= std_ulogic_vector(
	             unsigned('0' & i0)
	           + unsigned('0' & i1)
	           + unsigned'(0 => ic));

	o0 <= internal(size - 1 DOWNTO 0);
	oc <= internal(size);

END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_types.ALL;

ENTITY multiplier IS 
	GENERIC (
		size : positive
	);
	PORT (
		i0 : IN  std_ulogic_vector(size - 1 DOWNTO 0); 
		i1 : IN  std_ulogic_vector(size - 1 DOWNTO 0); 
		o0 : OUT std_ulogic_vector(size - 1 DOWNTO 0)
	);
END ENTITY multiplier;

ARCHITECTURE behav OF multiplier IS 
	SIGNAL tmp : std_ulogic_vector(2 * size - 1 DOWNTO 0) := (OTHERS => '0');
BEGIN
	tmp <= std_ulogic_vector(unsigned(i0) * unsigned(i1));
	o0  <= tmp(size - 1 DOWNTO 0);
END ARCHITECTURE behav;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.p_types.ALL;

ENTITY shifter_right_16bit IS
	PORT(
		i0    : IN  t_uword;
		iamnt : IN  std_ulogic_vector( 3 DOWNTO 0);

		o0    : OUT t_uword
	);
END ENTITY shifter_right_16bit;

ARCHITECTURE behav OF shifter_right_16bit IS
	SIGNAL t0, t1, t2 : t_uword := x"0000";
BEGIN
--implemented as barrel shifter
	t0 <=         "0" & i0(15 DOWNTO 1) WHEN iamnt(0) = '1' ELSE i0;	
	t1 <=        "00" & t0(15 DOWNTO 2) WHEN iamnt(1) = '1' ELSE t0;	
	t2 <=      "0000" & t1(15 DOWNTO 4) WHEN iamnt(2) = '1' ELSE t1;	
	o0 <=  "00000000" & t2(15 DOWNTO 8) WHEN iamnt(3) = '1' ELSE t2;
END ARCHITECTURE behav;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.p_types.ALL;

ENTITY shifter_left_16bit IS 
	PORT(
		i0    : IN  t_uword;
		iamnt : IN  std_ulogic_vector( 3 DOWNTO 0);

		o0    : OUT t_uword
	);
END ENTITY shifter_left_16bit;

ARCHITECTURE behav OF shifter_left_16bit IS 
	SIGNAL t0, t1, t2 : t_uword := x"0000";
BEGIN
--implemented as barrel shifter
	t0 <= i0(14 DOWNTO 0) &        "0" WHEN iamnt(0) = '1' ELSE i0;	
	t1 <= t0(13 DOWNTO 0) &       "00" WHEN iamnt(1) = '1' ELSE t0;	
	t2 <= t1(11 DOWNTO 0) &     "0000" WHEN iamnt(2) = '1' ELSE t1;	
	o0 <= t2( 7 DOWNTO 0) & "00000000" WHEN iamnt(3) = '1' ELSE t2;
END ARCHITECTURE behav;


/*
	2 bit counter saturating in both directions

a b c   x y  
0 0 0   0 0
0 0 1   0 1
0 1 0   0 0
0 1 1   1 0
1 0 0   0 1
1 0 1   1 1
1 1 0   1 0
1 1 1   1 1

  B ∧ C  ∨ (A ∧ ( B ∨ C))
(¬B ∧ C) ∨ (A ∧ (¬B ∨ C))
*/
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.p_types.ALL;

ENTITY bc_2bit IS 
	PORT(
		i0 : IN  std_ulogic_vector(1 DOWNTO 0);
		ic : IN  std_ulogic; 

		o0 : OUT std_ulogic_vector(1 DOWNTO 0)
	);
END ENTITY bc_2bit;

ARCHITECTURE behav OF bc_2bit IS 
	ALIAS A : std_ulogic IS i0(1);
	ALIAS B : std_ulogic IS i0(0);
	ALIAS C : std_ulogic IS ic;
BEGIN
	o0(1) <= (    B AND C) OR (A AND (    B OR C));
	o0(0) <= (NOT B AND C) OR (A AND (NOT B OR C));
END ARCHITECTURE behav;

