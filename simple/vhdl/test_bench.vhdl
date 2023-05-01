LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_arith_adder_16bit IS
END ENTITY;


ARCHITECTURE tb OF tb_arith_adder_16bit IS 

	signal i0, i1, o0 : std_logic_vector(15 DOWNTO 0);
	signal ic, oc     : std_logic;
BEGIN 
	dut: ENTITY work.arith_adder_16bit(behav) PORT MAP(i0, i1, ic, o0, oc);

	PROCESS IS 
		TYPE pattern IS RECORD 
			i0, i1 : std_logic_vector(15 DOWNTO 0);
			ic     : std_logic;
			
			o0     : std_logic_vector(15 DOWNTO 0);
			oc     : std_logic;
		END RECORD pattern ;

		TYPE arr IS ARRAY (NATURAL RANGE<>) OF pattern; 
		CONSTANT input : ARR := 
		(
		 (x"0000", x"0000", '0', x"0000", '0'),
		 (x"0001", x"0000", '0', x"0001", '0'),
		 (x"FFFF", x"0001", '0', x"0000", '1'),
		 (x"FFFF", x"0000", '1', x"0000", '1'),
		 (x"AAAA", x"5555", '0', x"FFFF", '0'),
		 (x"AAAA", x"5555", '1', x"0000", '1'),
		 (x"FF00", x"00FF", '0', x"FFFF", '0'),
		 (x"00FF", x"FF00", '0', x"FFFF", '0'),
		 (x"00FF", x"FF01", '0', x"0000", '1'),
		 (x"FFFF", x"FFFF", '0', x"FFFE", '1'),
		 (x"FFFF", x"F00F", '0', x"F00E", '1'),
		--dummy
		 (x"0000", x"0000", '0', x"0000", '0'));

	BEGIN
		
		FOR i IN input'range LOOP
			i0 <= input(i).i0;
			i1 <= input(i).i1;
			ic <= input(i).ic;


			WAIT FOR 1 ns;

			ASSERT o0 = input(i).o0
				REPORT "bad output sum " & integer'image(i) SEVERITY error;
			ASSERT oc = input(i).oc
				REPORT "bad output carry " & integer'image(i) SEVERITY error;

		END LOOP;

		WAIT;
	END PROCESS;

END ARCHITECTURE tb;



LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_reg_16bit IS
END ENTITY;

ARCHITECTURE tb OF tb_reg_16bit IS
	SIGNAL i0, o0  : std_logic_vector(15 DOWNTO 0);
	SIGNAL we, clk : std_logic;

BEGIN
	dut: ENTITY work.reg_16bit(behav) PORT MAP(i0, o0, we, clk);


	PROCESS IS 
		TYPE pattern IS RECORD 
			i0, o0  : std_logic_vector(15 DOWNTO 0);
			we, clk : std_logic;
		END RECORD pattern;

		TYPE arr IS ARRAY (NATURAL RANGE<>) OF pattern;

		CONSTANT input : arr := 
		(
		 (x"0000", x"0000", '0', '0'),
		 (x"ABCD", x"0000", '0', '1'),
		 (x"ABCD", x"0000", '1', '0'),
		 (x"ABCD", x"ABCD", '1', '1'),
		 (x"DEAD", x"ABCD", '1', '0'),
		 (x"BEEF", x"ABCD", '0', '0'),
		 (x"B0BA", x"B0BA", '1', '1'),
		 (x"C0DE", x"B0BA", '0', '1'),
		 (x"0000", x"B0BA", '0', '0'),
		 (x"0000", x"0000", '1', '1'),
		--dummy
		 (x"0000", x"0000", '0', '0'));

	BEGIN
		
		FOR i IN input'range LOOP
			i0  <= input(i).i0;
			we  <= input(i).we;
			clk <= input(i).clk;
				
			WAIT FOR 1 ns;

			ASSERT o0 = input(i).o0
				REPORT "wrong register behavior " & integer'image(i) SEVERITY error;

		END LOOP;

		WAIT;
	END PROCESS;


END ARCHITECTURE tb;



LIBRARY ieee;
USE ieee.std_logic_1164.ALL;


ENTITY tb_reg_file IS 

	FUNCTION to_string ( a: std_logic_vector) RETURN string IS
		VARIABLE b : string (1 TO a'length) := (OTHERS => NUL);
		VARIABLE stri : integer := 1; 
		
	BEGIN
		FOR i IN a'range LOOP
			b(stri) := std_logic'image(a((i)))(2);
			stri := stri+1;
    	END LOOP;
	

		RETURN b;
	
	END FUNCTION;
END ENTITY tb_reg_file;

ARCHITECTURE tb OF tb_reg_file IS 
	SIGNAL i0, o0, o1 : std_logic_vector(15 DOWNTO 0);
	SIGNAL r0, r1     : std_logic_vector( 2 DOWNTO 0);
	SIGNAL we, clk    : std_logic;

BEGIN

	dut: ENTITY work.reg_file(behav) PORT MAP(i0, o0, o1, r0, r1, we, clk);

	PROCESS IS
		TYPE pattern IS RECORD 
			i0, o0, o1 : std_logic_vector(15 DOWNTO 0);
			r0, r1     : std_logic_vector(2 DOWNTO 0);	
			we, clk    : std_logic;
		END RECORD pattern;
		
		TYPE arr IS ARRAY (natural RANGE<>) OF pattern;

		CONSTANT inputs : arr := (
		 (x"0000", x"0000", x"0000", "000", "000", '1', '1'), --  0
		 (x"FFFF", x"0000", x"0000", "000", "000", '0', '0'), --  1
		 (x"FFFF", x"0000", x"0000", "000", "000", '1', '0'), --  2
		 (x"FFFF", x"0000", x"0000", "000", "000", '0', '1'), --  3
		 (x"FFFF", x"0000", x"0000", "000", "000", '0', '0'), --  4
		 (x"FFFF", x"FFFF", x"FFFF", "000", "000", '1', '1'), --  5
		 (x"DEAD", x"FFFF", x"FFFF", "000", "000", '0', '0'), --  6
		 (x"C0DE", x"0000", x"FFFF", "001", "000", '0', '0'), --  7
		 (x"C0DE", x"0000", x"FFFF", "001", "000", '1', '0'), --  8
		 (x"C0DE", x"C0DE", x"FFFF", "001", "000", '1', '1'), --  9
		 (x"BEEF", x"FFFF", x"C0DE", "000", "001", '0', '0'), -- 10
		 (x"BEEF", x"0000", x"C0DE", "111", "001", '0', '0'), -- 11
		 (x"BEEF", x"BEEF", x"C0DE", "111", "001", '1', '1'), -- 12
		 (x"8483", x"FFFF", x"BEEF", "000", "111", '0', '0'), -- 13
		 (x"8483", x"8483", x"BEEF", "000", "111", '1', '1'), -- 14
		 (x"8483", x"8483", x"BEEF", "000", "111", '1', '0'), -- 15
		 (x"DEAD", x"DEAD", x"BEEF", "000", "111", '1', '1'), -- 16
		 (x"0000", x"DEAD", x"BEEF", "000", "111", '0', '0'), -- 17
		--dummy
		 (x"0000", x"0000", x"0000", "000", "000", '1', '1'));


	BEGIN
		clk <= '0';
		FOR i IN inputs'range LOOP

			i0  <= inputs(i).i0;
			r0  <= inputs(i).r0;
			r1  <= inputs(i).r1;
			we  <= inputs(i).we;

			WAIT FOR 1 ns;

			clk <= inputs(i).clk;
			
			WAIT FOR 1 ns;

			ASSERT o0 = inputs(i).o0 
				REPORT "output of r0 doesnt match in " & integer'image(i) 
				     & LF & "   expected " & to_string(inputs(i).o0)
				     & LF & "   found    " & to_string(o0)
				SEVERITY error;
			ASSERT o1 = inputs(i).o1 
				REPORT "output of r1 doesnt match in " & integer'image(i) 
				     & LF & "   expected " & to_string(inputs(i).o0)
				     & LF & "   found    " & to_string(o0)
				SEVERITY error;

		END LOOP;
		WAIT;
	END PROCESS;
END ARCHITECTURE tb;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_alu IS 
END ENTITY tb_alu;

ARCHITECTURE tb OF tb_alu IS 

	FUNCTION to_string ( a: std_logic_vector) RETURN string IS
		VARIABLE b : string (1 TO a'length) := (OTHERS => NUL);
		VARIABLE stri : integer := 1; 
		
	BEGIN
		FOR i IN a'range LOOP
			b(stri) := std_logic'image(a((i)))(2);
			stri := stri+1;
    	END LOOP;
	

		RETURN b;
	
	END FUNCTION;


	SIGNAL i0, i1, o0 : std_logic_vector(15 DOWNTO 0);
	SIGNAL op         : std_logic_vector( 2 DOWNTO 0);

BEGIN
	dut: ENTITY work.alu(behav) PORT MAP(i0, i1, o0, op);


	PROCESS IS 
		TYPE pattern IS RECORD 
			i0, i1, o0 : std_logic_vector(15 DOWNTO 0);
			op         : std_logic_vector( 2 DOWNTO 0);
		END RECORD pattern;

		TYPE arr IS ARRAY(natural RANGE<>) OF pattern;

		CONSTANT input : arr := (
		--ADD 00
		  (x"0000", x"0000", x"0000", "000"),
		  (x"0001", x"0000", x"0001", "000"),
		  (x"FFFF", x"0001", x"0000", "000"),
		  (x"FFFF", x"0000", x"FFFF", "000"),
		  (x"AAAA", x"5555", x"FFFF", "000"),
		  (x"FF00", x"00FF", x"FFFF", "000"),
		  (x"00FF", x"FF00", x"FFFF", "000"),
		  (x"00FF", x"FF01", x"0000", "000"),
		  (x"FFFF", x"FFFF", x"FFFE", "000"),
		  (x"FFFF", x"F00F", x"F00E", "000"),
		--SUB 10
		  (x"0000", x"0000", x"0000", "001"),
		  (x"0001", x"0000", x"0001", "001"),
		  (x"FFFF", x"0001", x"FFFE", "001"),
		  (x"FFFF", x"0000", x"FFFF", "001"),
		  (x"AAAA", x"5555", x"5555", "001"),
		  (x"FF00", x"00FF", x"FE01", "001"),
		  (x"00FF", x"FF00", x"01FF", "001"),
		  (x"00FF", x"FF01", x"01FE", "001"),
		  (x"FFFF", x"FFFF", x"0000", "001"),
		  (x"FFFF", x"F00F", x"0FF0", "001"),
		--NOT 20
		  (x"0000", x"0000", x"FFFF", "010"),
		  (x"0001", x"0000", x"FFFE", "010"),
		  (x"FFFF", x"0001", x"0000", "010"),
		  (x"FFFF", x"0000", x"0000", "010"),
		  (x"AAAA", x"5555", x"5555", "010"),
		  (x"FF00", x"00FF", x"00FF", "010"),
		  (x"00FF", x"FF00", x"FF00", "010"),
		  (x"00FF", x"FF01", x"FF00", "010"),
		  (x"FFFF", x"FFFF", x"0000", "010"),
		  (x"FFFF", x"F00F", x"0000", "010"),
		--AND 30 
		  (x"0000", x"0000", x"0000", "011"),
		  (x"0001", x"0000", x"0000", "011"),
		  (x"FFFF", x"0001", x"0001", "011"),
		  (x"FFFF", x"0000", x"0000", "011"),
		  (x"AAAA", x"5555", x"0000", "011"),
		  (x"FF00", x"00FF", x"0000", "011"),
		  (x"00FF", x"FF00", x"0000", "011"),
		  (x"00FF", x"FF01", x"0001", "011"),
		  (x"FFFF", x"FFFF", x"FFFF", "011"),
		  (x"FFFF", x"F00F", x"F00F", "011"),
		--ORR 40 
		  (x"0000", x"0000", x"0000", "100"),
		  (x"0001", x"0000", x"0001", "100"),
		  (x"FFFF", x"0001", x"FFFF", "100"),
		  (x"FFFF", x"0000", x"FFFF", "100"),
		  (x"AAAA", x"5555", x"FFFF", "100"),
		  (x"FF00", x"00FF", x"FFFF", "100"),
		  (x"00FF", x"FF00", x"FFFF", "100"),
		  (x"00FF", x"FF01", x"FFFF", "100"),
		  (x"FFFF", x"FFFF", x"FFFF", "100"),
		  (x"FFFF", x"F00F", x"FFFF", "100"),
		--XOR 50 
		  (x"0000", x"0000", x"0000", "101"),
		  (x"0001", x"0000", x"0001", "101"),
		  (x"FFFF", x"0001", x"FFFE", "101"),
		  (x"FFFF", x"0000", x"FFFF", "101"),
		  (x"AAAA", x"5555", x"FFFF", "101"),
		  (x"FF00", x"00FF", x"FFFF", "101"),
		  (x"00FF", x"FF00", x"FFFF", "101"),
		  (x"00FF", x"FF01", x"FFFE", "101"),
		  (x"FFFF", x"FFFF", x"0000", "101"),
		  (x"FFFF", x"F00F", x"0FF0", "101"),
		--SLL 60 
		  (x"0000", x"0000", x"0000", "110"),
		  (x"0001", x"0000", x"0001", "110"),
		  (x"FFFF", x"0001", x"FFFE", "110"),
		  (x"FFFF", x"0000", x"FFFF", "110"),
		  (x"AAAA", x"5555", x"5540", "110"),
		  (x"FF00", x"00FF", x"0000", "110"),
		  (x"00FF", x"FF00", x"00FF", "110"),
		  (x"00FF", x"FF01", x"01FE", "110"),
		  (x"FFFF", x"FFFF", x"8000", "110"),
		  (x"FFFF", x"F00F", x"8000", "110"),
		--SLR 70 
		  (x"0000", x"0000", x"0000", "111"),
		  (x"0001", x"0000", x"0001", "111"),
		  (x"FFFF", x"0001", x"7FFF", "111"),
		  (x"FFFF", x"0000", x"FFFF", "111"),
		  (x"AAAA", x"5555", x"0555", "111"),
		  (x"FF00", x"00FF", x"0001", "111"),
		  (x"00FF", x"FF00", x"00FF", "111"),
		  (x"00FF", x"FF01", x"007F", "111"),
		  (x"FFFF", x"FFFF", x"0001", "111"),
		  (x"FFFF", x"F00F", x"0001", "111"),
	
		  --dummy
		  (x"0000", x"0000", x"0000", "000")
		);
	BEGIN
		FOR i IN input'range LOOP
			i0 <= input(i).i0;
			i1 <= input(i).i1;
			op <= input(i).op;

			WAIT FOR 1 ns;

			ASSERT o0 = input(i).o0 
				REPORT "OUTPUT DOES NOT MATCH IN " & integer'image(i)
				& LF & "EXPECTED " & to_string(input(i).o0) 
				& LF & "FOUND    " & to_string(o0) 
				SEVERITY error;

		END LOOP;
		WAIT;

	END PROCESS;

END ARCHITECTURE tb;


