LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE std.env.finish;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;
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
			iodata  : INOUT t_rword := x"ZZZZ";
			oaddr   : OUT   t_rword := x"ZZZZ";
			ord     : OUT   std_logic := 'Z';
			owr     : OUT   std_logic := 'Z';
			ohlt    : OUT   std_logic := 'Z';
			
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
			ia            : IN    t_rword := x"0000";
			iodata        : INOUT t_rword := x"0000";
	
			--determines whether to read/write value
			rd            : IN  std_logic := '0';
			wr            : IN  std_logic := '0';
	
			--if read or write, delay after which memory is usable again
			rdy           : OUT std_logic := '0';
	
			disable_delay : IN std_ulogic := '0';
			clk           : IN std_ulogic := '0'
		);
	END COMPONENT memory;

--	SIGNAL clk       : std_ulogic := '0';

	--so that each clock can be individually controlled
	SIGNAL clk_core0 : std_ulogic := '0';
	SIGNAL clk_mem0  : std_ulogic := '0';

	CONSTANT halfperiod : time := 1000 PS;

	SIGNAL c0_hlt      : std_ulogic := '0';
	SIGNAL c0_disable  : std_ulogic := '1';
	
	SIGNAL bus_mem : t_rword := x"0000";
	SIGNAL bus_adr : t_rword := x"0000";
	SIGNAL bus_crd : std_logic := '0';
	SIGNAL bus_cwr : std_logic := '0';
	SIGNAL bus_rdy : std_ulogic := '0';

	SIGNAL abort   : boolean := false;

	SIGNAL disable_delay : std_ulogic := '1';	
BEGIN
	--connects everything that has to be connected
	c_core0 : core PORT MAP(iodata  => bus_mem,
	                        oaddr   => bus_adr,
	                        ord     => bus_crd,
	                        owr     => bus_cwr,
	                        ohlt    => c0_hlt, 
	                        disable => c0_disable, 
	                        clk     => clk_core0);

	c_mem0  : memory GENERIC MAP(delay         => 10 NS)
	                 PORT    MAP(ia            => bus_adr,
	                             iodata        => bus_mem,
	                             rd            => bus_crd,
	                             wr            => bus_cwr,
	                             rdy           => bus_rdy,
	                             disable_delay => disable_delay, 
	                             clk           => clk_mem0);
	
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
		-- Convert string to std_logic_vector, assuming characters in '0' to '9',
		-- 'A' to 'F', or 'a' to 'f'.
		FUNCTION str_to_slv(str : string) RETURN std_logic_vector IS
		  ALIAS str_norm : string(1 TO str'length) IS str;
		  VARIABLE char_v : character := ' ';
		  VARIABLE val_of_char_v : natural := 0;
		  VARIABLE res_v : std_logic_vector(4 * str'length - 1 DOWNTO 0) := (OTHERS => '0');
		BEGIN
		  FOR str_norm_idx IN str_norm'range LOOP
		    char_v := str_norm(str_norm_idx);
		    CASE char_v IS
		      WHEN '0' TO '9' => val_of_char_v := character'pos(char_v) - character'pos('0');
		      WHEN 'A' TO 'F' => val_of_char_v := character'pos(char_v) - character'pos('A') + 10;
		      WHEN 'a' TO 'f' => val_of_char_v := character'pos(char_v) - character'pos('a') + 10;
		      WHEN OTHERS => REPORT "str_to_slv: Invalid characters for convert" SEVERITY ERROR;
		    END CASE;
		    res_v(res_v'left - 4 * str_norm_idx + 4 DOWNTO res_v'left - 4 * str_norm_idx + 1) :=
		      std_logic_vector(to_unsigned(val_of_char_v, 4));
		  END LOOP;
		  RETURN res_v;
		END FUNCTION;
	
		FUNCTION slv_to_str(slv : std_ulogic_vector(31 DOWNTO 0)) RETURN string IS
			VARIABLE index : natural;
			VARIABLE str   : string(8 DOWNTO 1);
			VARIABLE sub   : std_ulogic_vector(3 DOWNTO 0);
		BEGIN
			index := 0;
	
			WHILE index < 8 LOOP
				sub(3) := slv(4 * index + 3);
				sub(2) := slv(4 * index + 2);
				sub(1) := slv(4 * index + 1);
				sub(0) := slv(4 * index + 0);
	
				CASE sub IS 
					WHEN x"0"   => str(index + 1) := '0';
					WHEN x"1"   => str(index + 1) := '1';
					WHEN x"2"   => str(index + 1) := '2';
					WHEN x"3"   => str(index + 1) := '3';
					WHEN x"4"   => str(index + 1) := '4';
					WHEN x"5"   => str(index + 1) := '5';
					WHEN x"6"   => str(index + 1) := '6';
					WHEN x"7"   => str(index + 1) := '7';
					WHEN x"8"   => str(index + 1) := '8';
					WHEN x"9"   => str(index + 1) := '9';
					WHEN x"A"   => str(index + 1) := 'A';
					WHEN x"B"   => str(index + 1) := 'B';
					WHEN x"C"   => str(index + 1) := 'C';
					WHEN x"D"   => str(index + 1) := 'D';
					WHEN x"E"   => str(index + 1) := 'E';
					WHEN x"F"   => str(index + 1) := 'F';
					WHEN x"Z"   => str(index + 1) := '_';
					WHEN OTHERS => str(index + 1) := 'X';
				END CASE;
	
				index := index + 1;
			END LOOP;
			
			RETURN str;
	
		END FUNCTION slv_to_str;

		FILE data : text; 

		VARIABLE index : unsigned(15 DOWNTO 0) := x"0000";
		VARIABLE size  : natural;
		VARIABLE temp_storage : string(8 DOWNTO 1);

		VARIABLE temp_slv  : std_logic_vector(31 DOWNTO 0);

		ALIAS mem_data IS <<SIGNAL c_mem0.mem : t_mem_arr>>;
		--to work around cache
		VARIABLE mem_data_copy : t_mem_arr;
		VARIABLE cycles : integer := 0;

	BEGIN
		--initialize program

		--quickly run clock and store data to mem module
		--how should it work when delay is added? idk, maybe some bypassing
		file_open(data, "input_prog.bin");
		bus_cwr <= '1';
		bus_crd <= '0';
		WHILE NOT endfile(data) LOOP
			read(data, temp_storage, size);
			
			temp_slv := str_to_slv(temp_storage);

			bus_mem <= temp_slv(31 DOWNTO 16);
			bus_adr <= std_logic_vector(index);

			index := index + 2;	

			clk_mem0 <= '0';
			WAIT FOR 1 PS; --some slight delay
			clk_mem0 <= '1';
			WAIT FOR 1 PS; --some slight delay

			bus_mem <= temp_slv(15 DOWNTO  0);
			bus_adr <= std_logic_vector(index);

			index := index + 2;	

			clk_mem0 <= '0';
			WAIT FOR 1 PS; --some slight delay
			clk_mem0 <= '1';
			WAIT FOR 1 PS; --some slight delay
		END LOOP;
		file_close(data);

		--dont drive them anymore
		--can be 'Z' but nicely prevents warnings
		disable_delay <= '0';
		bus_cwr <= 'Z';
		bus_crd <= 'Z';
		bus_mem <= x"ZZZZ";
		bus_adr <= x"ZZZZ";
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
			cycles := cycles + 1;
	
			WAIT FOR halfperiod; 

		END LOOP main;
		c0_disable <= '1';

		--memory dump a program

		--this time, NOT using signals as causes significant overhead 
		--rather use alias to external signal

		
		index := x"0000";
		FOR ind IN 0 TO (32768)/2 - 1 LOOP 
			mem_data_copy(to_integer(index + 0)) := mem_data(to_integer(index + 0));
			mem_data_copy(to_integer(index + 1)) := mem_data(to_integer(index + 1));
			index := index + 2;	
		END LOOP;

		file_open(data, "dump.txt", WRITE_MODE);
		index := x"0000";
		FOR ind IN 0 TO (32768)/2 - 1 LOOP 

			temp_slv(31 DOWNTO 16) := mem_data_copy(to_integer(index + 0));
			temp_slv(15 DOWNTO  0) := mem_data_copy(to_integer(index + 1));
			index := index + 2;	

			temp_storage := slv_to_str(temp_slv);
			write(data, temp_storage & LF);
		END LOOP;
		file_close(data);

		REPORT LF & LF & "cycles: " & integer'image(cycles);

		finish;
	END PROCESS;
END ARCHITECTURE behav;
