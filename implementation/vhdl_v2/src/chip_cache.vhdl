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

	COMPONENT cache IS 
		GENERIC(
			delay : time := 0 NS
		);
		PORT(
			ia            : IN    t_rword := x"0000";
			iodata        : INOUT t_rword := x"0000";
			opresent      : OUT   std_ulogic := '0';

			oevicteda     : OUT   t_rword := x"0000";
			oevictedd     : OUT   t_rword := x"0000";
			oevictedp     : OUT   std_ulogic := '0';
		
			--determines whether to read/write value
			rd            : IN  std_logic := '0';
			wr            : IN  std_logic := '0';
		
			--if read or write, delay after which memory is usable again
			rdy           : OUT std_logic := '0';
		
			disable_delay : IN std_ulogic := '0';
			clk           : IN std_ulogic := '0'
		);
	END COMPONENT cache;

--	SIGNAL clk       : std_ulogic := '0';

	--so that each clock can be individually controlled
	SIGNAL clk_core0 : std_ulogic := '0';
	SIGNAL clk_mem0  : std_ulogic := '0';
	SIGNAL clk_csh0  : std_ulogic := '0';

	CONSTANT halfperiod : time := 500 PS;

	SIGNAL c0_hlt      : std_ulogic;
	SIGNAL c0_disable  : std_ulogic := '1';
	SIGNAL chip_init     : std_ulogic := '1';
	--used when loading program and to init memory
	SIGNAL mem_disable_delay : std_ulogic := '1'; 	
	
	SIGNAL bus_mem : t_rword :=  x"0000";
	SIGNAL bus_adr : t_rword;
	SIGNAL bus_crd : std_logic := '0';
	SIGNAL bus_cwr : std_logic := '0';

	SIGNAL m0_rd   : std_logic := '0';
	SIGNAL m0_wr   : std_logic := '0';
	SIGNAL m0_rdy  : std_logic;
	SIGNAL m0_bus  : t_rword;
	SIGNAL m0_adr  : t_rword;

	SIGNAL csh_evc_adr : t_rword;
	SIGNAL csh_evc_dat : t_rword;
	SIGNAL csh_evc_prs : std_ulogic;

	SIGNAL csh_rdy : std_logic;
	SIGNAL csh_prs : std_logic;
	SIGNAL csh_bus : t_rword;
	SIGNAL csh_rd  : std_logic := '0';
	SIGNAL csh_wr  : std_logic := '0';

	SIGNAL abort   : boolean := false;
	
	SIGNAL evict_read_conflict     : std_ulogic := '0';
	SIGNAL evict_read_conflict_fix : std_ulogic := '0';
	
BEGIN
	--connects everything that has to be connected
	c_core0 : core PORT MAP(iodata  => bus_mem,
	                        oaddr   => bus_adr,
	                        ord     => bus_crd,
	                        owr     => bus_cwr,
	                        ohlt    => c0_hlt, 
	                        disable => c0_disable, 
	                        clk     => clk_core0);

	c_mem0  : memory GENERIC MAP(delay         => 5 NS)
	                 PORT    MAP(ia            => m0_adr,
	                             iodata        => m0_bus,
	                             rd            => m0_rd,
	                             wr            => m0_wr, 
	                             rdy           => m0_rdy, 
	                             disable_delay => mem_disable_delay,
	                             clk           => clk_mem0);

	c_csh0  : cache GENERIC MAP(delay         => 0 NS)
	                PORT    MAP(ia            => bus_adr,
	                            iodata        => csh_bus,
	                            opresent      => csh_prs,
	                            oevictedp     => csh_evc_prs,
	                            oevicteda     => csh_evc_adr,
	                            oevictedd     => csh_evc_dat,
	                            rd            => csh_rd, 
	                            wr            => csh_wr, 
	                            rdy           => csh_rdy,
	                            disable_delay => mem_disable_delay,
	                            clk           => clk_csh0);
	
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
		  VARIABLE char_v : character;
		  VARIABLE val_of_char_v : natural;
		  VARIABLE res_v : std_logic_vector(4 * str'length - 1 DOWNTO 0);
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
		ALIAS csh_data IS <<SIGNAL c_csh0.mem : t_csh_arr>>;
		--to work around cache
		VARIABLE mem_data_copy : t_mem_arr;

	BEGIN
		--initialize program

		--quickly run clock and store data to mem module
		--how should it work when delay is added? idk, maybe some bypassing
		file_open(data, "input_prog.bin");
		bus_cwr <= '1';
		WHILE NOT endfile(data) LOOP
			read(data, temp_storage, size);
			
			temp_slv := str_to_slv(temp_storage);

			m0_bus  <= temp_slv(31 DOWNTO 16);
			csh_bus <= temp_slv(31 DOWNTO 16);
			bus_adr <= std_logic_vector(index);

			index := index + 2;	

			clk_mem0 <= '0';
			clk_csh0 <= '0';
			WAIT FOR 1 PS; --some slight delay
			clk_mem0 <= '1';
			clk_csh0 <= '1';
			WAIT FOR 1 PS; --some slight delay

			m0_bus  <= temp_slv(15 DOWNTO  0);
			csh_bus <= temp_slv(15 DOWNTO  0);
			bus_adr <= std_logic_vector(index);

			index := index + 2;	

			clk_mem0 <= '0';
			clk_csh0 <= '0';
			WAIT FOR 1 PS; --some slight delay
			clk_mem0 <= '1';
			clk_csh0 <= '1';
			WAIT FOR 1 PS; --some slight delay
		END LOOP;
		file_close(data);


		--dont drive them anymore
		bus_cwr <= 'Z';
		bus_crd <= 'Z';
		bus_mem <= x"ZZZZ";
		bus_adr <= x"ZZZZ";
		m0_bus  <= x"ZZZZ";
		csh_bus <= x"ZZZZ";
		c0_disable <= '0';
		chip_init  <= '0';
		mem_disable_delay <= '0';
		main: LOOP

			clk_core0 <= '0';
			clk_csh0  <= '0';
			clk_mem0  <= '0';
	
			WAIT FOR halfperiod; 
			IF c0_hlt = '1' OR abort THEN 
				EXIT; --break;
			END IF;
			--clock high right now

			IF m0_rdy = '1' THEN
				--this will probably break with no delay 
				evict_read_conflict <= '0' WHEN rising_edge(m0_rdy)
				                            AND evict_read_conflict_fix = '1'
				                  ELSE bus_crd AND csh_evc_prs;
				evict_read_conflict_fix <= '1' WHEN rising_edge(m0_rdy)
				                                AND evict_read_conflict = '1'
				                      ELSE '0';


				IF     csh_prs = '1' 
				   AND evict_read_conflict     = '0' 
				   AND evict_read_conflict_fix = '0' THEN 
					clk_core0 <= '1';
				ELSE
					clk_core0 <= UNAFFECTED;
				END IF;
			
				IF evict_read_conflict = '0' OR evict_read_conflict_fix = '1' THEN
					clk_csh0  <= '1';
				ELSE
					clk_csh0  <= UNAFFECTED;
				END IF;
			ELSE
				clk_core0 <= UNAFFECTED;
				clk_csh0  <= UNAFFECTED;
			END IF;
	
			clk_mem0 <= '1';
	
			WAIT FOR halfperiod; 

		END LOOP main;

		c0_disable <= '1';

		--memory dump a program

		--quickly run clock and read data from mem module
		--how should it work when delay is added? idk, maybe some bypassing

		--this time, NOT using signals as causes significant overhead 
		--rather use alias to external signal

		
		index := x"0000";
		FOR ind IN 0 TO (32768)/2 - 1 LOOP 
			mem_data_copy(to_integer(index + 0)) := mem_data(to_integer(index + 0));
			mem_data_copy(to_integer(index + 1)) := mem_data(to_integer(index + 1));
			index := index + 2;	
		END LOOP;

		index := x"0000";
		FOR i0  IN 0 TO t_csh_arr'length - 1 LOOP 
			FOR i1 IN 0 TO t_csh_sar'length - 1 LOOP 
				temp_slv(15 DOWNTO 0) := std_logic_vector(index);
				IF   csh_data(to_integer(index + 0))(i1).present
				 AND csh_data(to_integer(index + 0))(i1).dirty THEN
					mem_data_copy(to_integer(unsigned(
						  csh_data(to_integer(index + 0))(i1).tag
						& temp_slv(6 DOWNTO 1)
						& temp_slv(0) --vhdl gods demand it to be done like that
						)))
					  := csh_data(to_integer(index + 0))(i1).data;
				END IF;

			END LOOP;

			index := index + 1;	
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

		finish;
	END PROCESS;


	m0_rd <= '1'     WHEN     evict_read_conflict_fix
	    ELSE bus_crd WHEN NOT csh_prs
	    ELSE '0';
	--dont write in writeback
	m0_wr <= csh_evc_prs OR chip_init;

	bus_mem <= x"ZZZZ" WHEN chip_init 
	      ELSE m0_bus  WHEN evict_read_conflict_fix
	      ELSE csh_bus WHEN bus_crd AND     csh_prs 
	      ELSE m0_bus  WHEN bus_crd AND NOT csh_prs 
	      ELSE x"ZZZZ";
	m0_adr  <= bus_adr     WHEN evict_read_conflict_fix
	      ELSE csh_evc_adr WHEN csh_evc_prs 
	      ELSE bus_adr;
	m0_bus  <= x"ZZZZ" WHEN chip_init
	      ELSE csh_evc_dat WHEN csh_evc_prs  
	      ELSE x"ZZZZ";
	csh_bus <= x"ZZZZ" WHEN chip_init
	      ELSE m0_bus  WHEN (bus_crd AND NOT csh_prs)
	                     OR (evict_read_conflict_fix)
	      ELSE bus_mem WHEN bus_cwr 
	      ELSE x"ZZZZ"; 
	
	csh_rd  <= '1' WHEN evict_read_conflict_fix
	      ELSE bus_crd;
	csh_wr  <= '0' WHEN evict_read_conflict_fix
	      ELSE bus_cwr;


END ARCHITECTURE behav;
