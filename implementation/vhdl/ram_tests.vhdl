/*
	DUs in file in order
		ram
	
	ram 
		a0  is address input
		i0  is data input
		o0  is data output
		we  is write enable
		clk is synchronization
		
		64KiB of data, byte addressable
		access must be 2B aligned 
		unaligned memory access is rounded down to first aligned 
		meaning LSb is discarded when using a0 
		
		so in practice behaves like 32Ki of 16bit words

		default value of data is program
*/


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE std.textio.ALL;
USE ieee.std_logic_textio.ALL;

ENTITY ram IS
	PORT(
		a0  : IN  std_ulogic_vector(15 DOWNTO 0) := x"0000";
		i0s : IN  std_ulogic_vector(15 DOWNTO 0);
		o0s : OUT std_ulogic_vector(15 DOWNTO 0);
		o0d : OUT std_ulogic_vector(31 DOWNTO 0) := x"00000000";

		we  : IN  std_ulogic := '0';
		rdy : OUT std_ulogic := '0';
		hlt : IN  std_ulogic := '0';
		clk : IN  std_ulogic);
END ENTITY ram;

ARCHITECTURE behav OF ram IS 
	TYPE arr IS ARRAY(16383 DOWNTO 0) OF std_logic_vector(31 DOWNTO 0);
	SIGNAL data : arr := (
		--this way, when initializing from two sources, value is correct
		OTHERS => x"ZZZZZZZZ"
	);

	SIGNAL addr     : integer RANGE 16383 DOWNTO 0;
	SIGNAL mem_data : std_ulogic_vector(31 DOWNTO 0) := x"00000000";
	SIGNAL ms_half  : std_ulogic;

	SIGNAL mem_in      : std_ulogic_vector(31 DOWNTO 0);

	-- Convert string to std_logic_vector, assuming characters in '0' to '9',
	-- 'A' to 'F', or 'a' to 'f'.
	function str_to_slv(str : string) return std_logic_vector is
	  alias str_norm : string(1 to str'length) is str;
	  variable char_v : character;
	  variable val_of_char_v : natural;
	  variable res_v : std_logic_vector(4 * str'length - 1 downto 0);
	begin
	  for str_norm_idx in str_norm'range loop
	    char_v := str_norm(str_norm_idx);
	    case char_v is
	      when '0' to '9' => val_of_char_v := character'pos(char_v) - character'pos('0');
	      when 'A' to 'F' => val_of_char_v := character'pos(char_v) - character'pos('A') + 10;
	      when 'a' to 'f' => val_of_char_v := character'pos(char_v) - character'pos('a') + 10;
	      when others => report "str_to_slv: Invalid characters for convert" severity ERROR;
	    end case;
	    res_v(res_v'left - 4 * str_norm_idx + 4 downto res_v'left - 4 * str_norm_idx + 1) :=
	      std_logic_vector(to_unsigned(val_of_char_v, 4));
	  end loop;
	  return res_v;
	end function;

	FUNCTION slv_to_str(slv : std_ulogic_vector(31 DOWNTO 0)) return string IS
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

	SIGNAL can_write : std_ulogic := '0';
	
BEGIN
	memory_init: PROCESS IS  
		FILE code : text; 

		VARIABLE index : natural;
		VARIABLE size  : natural;
		VARIABLE temp_storage : string(8 DOWNTO 1);
	BEGIN
		index := 0;
--
		file_open(code, "input_prog.bin"); 
		WHILE NOT endfile(code) LOOP
			read(code, temp_storage, size);
			data(index) <= str_to_slv(temp_storage) WHEN can_write = '0';
			index := index + 1;
		END LOOP;

		file_close(code);
		can_write <= '1';
		WAIT;

	END PROCESS memory_init;

	memory_fin: PROCESS IS 
		FILE dump : text;

		VARIABLE temp  : string(8 DOWNTO 1);

	BEGIN
		WAIT ON hlt;

		file_open(dump, "dump.txt", WRITE_MODE); 
		FOR ind IN 0 TO (data'length - 1) LOOP 
			temp := slv_to_str(data(ind));
			write(dump, temp & LF);
		END LOOP;

		file_close(dump);
	END PROCESS memory_fin;

		--LSb is ignored
		--next bit is one decides whether data is in first or second half of memory
		addr <= to_integer(unsigned(a0(15 DOWNTO 2)));

		--most significant half 
		--in xAAAABBBB
		--its half denoted by AAAA
		ms_half  <= NOT a0(1);
		mem_data <= data(addr) WHEN NOT hlt;

		mem_in <= mem_data(31 DOWNTO 16) & i0s WHEN ms_half = '0'
		     ELSE i0s & mem_data(15 DOWNTO  0);

		data(addr) <= mem_in WHEN we = '1' AND rising_edge(clk) AND can_write'delayed(1 NS) = '1'
		         ELSE UNAFFECTED;

		o0s <= mem_data(31 DOWNTO 16) WHEN ms_half = '1'
		  ELSE mem_data(15 DOWNTO  0); 
		o0d <= mem_data;

		--models delay
		--rdy <= '1' AFTER 10 NS, '0' AFTER 10.5   NS WHEN rising_edge(clk)
		--  ELSE UNAFFECTED;
		--stub 
		rdy <= '1';


END ARCHITECTURE behav; 

