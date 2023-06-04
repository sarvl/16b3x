LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

USE work.p_control.ALL;

PACKAGE p_stage IS
	TYPE t_stage IS RECORD 
		controls      : t_controls;
		rd,  r0,  r1  : std_ulogic_vector( 2 DOWNTO 0);
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
		o0  : OUT t_stage : (controls => (OTHERS => '0'), rd | r0 | r1 | alu_op => (OTHERS => '0'), rdi | op0 | op1 => (OTHERS => '0'));

		clk : IN  std_ulogic;
		);
END ENTITY stage;

ARCHITECTURE behav OF stage IS 
BEGIN
	o0 <= i0 WHEN rising_edge(clk)
	 ELSE UNAFFECTED;
END ARCHITECTURE behav;

