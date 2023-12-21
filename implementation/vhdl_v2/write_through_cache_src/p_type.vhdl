LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE p_types IS 
	SUBTYPE t_word IS std_ulogic_vector(15 DOWNTO 0);
	SUBTYPE t_uword IS std_ulogic_vector(15 DOWNTO 0);
	SUBTYPE t_rword IS std_logic_vector(15 DOWNTO 0);

	TYPE t_mem_arr IS ARRAY(32768 - 1 DOWNTO 0) OF t_uword;
END PACKAGE p_types;
