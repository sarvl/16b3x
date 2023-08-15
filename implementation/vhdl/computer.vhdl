LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.env.finish;

ENTITY computer IS 
END ENTITY computer;

ARCHITECTURE behav OF computer IS 
	COMPONENT CPU IS 
		PORT(	
			halt  : OUT   std_ulogic;
	
			addr  : OUT   std_ulogic_vector(15 DOWNTO 0);
			data  : INOUT std_ulogic_vector(31 DOWNTO 0);
			wren  : OUT   std_ulogic;
			rdy   : IN    std_ulogic;
			clk   : OUT   std_ulogic);
	END COMPONENT CPU;

	COMPONENT ram IS
		PORT(
			a0  : IN  std_ulogic_vector(15 DOWNTO 0) := x"0000";
			i0s : IN  std_ulogic_vector(15 DOWNTO 0);
			o0s : OUT std_ulogic_vector(15 DOWNTO 0);
			o0d : OUT std_ulogic_vector(31 DOWNTO 0) := x"00000000";
	
			we  : IN  std_ulogic := '0';
			rdy : OUT std_ulogic := '0';
			clk : IN  std_ulogic;
			hlt : IN  std_ulogic);
	END COMPONENT ram;

	SIGNAL halt : std_ulogic := '0';
	SIGNAL clk  : std_ulogic := '0';

	SIGNAL ramwr  : std_ulogic := '0';
	SIGNAL ramrdy : std_ulogic := '0';
	SIGNAL baddr  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL bdata  : std_ulogic_vector(31 DOWNTO 0);
	
BEGIN

	

END ARCHITECTURE behav;
