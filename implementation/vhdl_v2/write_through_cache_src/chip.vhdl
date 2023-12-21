LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE std.env.finish;
USE ieee.numeric_std.ALL;
USE work.p_types.ALL;

ENTITY chip IS
END ENTITY chip;

ARCHITECTURE behav of chip IS 
	/*
		should contain:
			CPU
			memory
			optional cache
			peripheral support
				memory mapped?
				special instr?

		manage communication between them
	*/

	COMPONENT core IS 
		PORT(
			--they have to be resolved
			iodata  : INOUT t_rword;
			oaddr   : OUT   t_rword;
			ord     : OUT   std_logic;
			owr     : OUT   std_logic;
			ohlt    : OUT   std_logic;
			
			--disables bus interface, MAY NOT STOP CLOCK
			disable : IN std_ulogic;
			clk : IN  std_ulogic
		);
	END COMPONENT core;


	COMPONENT memory IS 
		GENERIC(
			delay : time := 0 NS
		);
		PORT(
			ia     : IN    t_rword := x"0000";
			iodata : INOUT t_rword := x"0000";
	
			--determines whether to read/write value
			rd   : IN  std_logic := '0';
			wr   : IN  std_logic := '0';
	
			--if read or write, delay after which memory is usable again
			rdy  : OUT std_logic := '0';
	
			clk  : IN  std_ulogic := '0'
		);
	END COMPONENT memory;


--	SIGNAL clk       : std_ulogic := '0';

	--so that each clock can be individually controlled
	SIGNAL clk_core0 : std_ulogic := '0';
	SIGNAL clk_mem0  : std_ulogic := '0';

	CONSTANT halfperiod : time := 1 NS;

	SIGNAL c0_hlt      : std_ulogic;
	SIGNAL c0_disable  : std_ulogic := '1';
	
	SIGNAL bus_mem : t_rword;
	SIGNAL bus_adr : t_rword;
	SIGNAL bus_crd : std_logic;
	SIGNAL bus_cwr : std_logic;
	SIGNAL bus_rdy : std_ulogic;

	SIGNAL abort   : boolean := false;

BEGIN
	--connects everything that has to be connected
	c_core0 : core PORT MAP(iodata  => bus_mem,
	                        oaddr   => bus_adr,
	                        ord     => bus_crd,
	                        owr     => bus_cwr,
	                        ohlt    => c0_hlt, 
	                        disable => c0_disable, 
	                        clk     => clk_core0);

	c_mem0  : memory GENERIC MAP(delay  => 0 NS)
	                 PORT    MAP(ia     => bus_adr,
	                             iodata => bus_mem,
	                             rd     => bus_crd,
	                             wr     => bus_cwr,
	                             rdy    => bus_rdy,
	                             clk    => clk_mem0);
	
--	PROCESS IS
--	BEGIN
--		WAIT FOR 20000 NS;
--		abort <= true;
--	END PROCESS;
	
	--dictates clock
	--maybe can be implemented better?
	--for now as there are only 2 signals its enough
	--in case much more must by synchronised then think of smarter way

	PROCESS IS
	BEGIN
		c0_disable <= '0';
		main: LOOP

			clk_core0 <= '0';
			clk_mem0  <= '0';
	
			WAIT FOR halfperiod; 
			IF c0_hlt = '1' OR abort THEN 
				EXIT; --break;
			END IF;
			
			IF bus_rdy = '1' THEN
				clk_core0 <= '1';
			ELSE
				clk_core0 <= UNAFFECTED;
			END IF;
	
			clk_mem0 <= '1';
	
			WAIT FOR halfperiod; 

		END LOOP main;
		c0_disable <= '1';

		finish;
	END PROCESS;
END ARCHITECTURE behav;
