LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE p_decode IS
	TYPE t_signals IS RECORD
		aluop  : std_ulogic_vector(2 DOWNTO 0);

		r0     : std_ulogic_vector(2 DOWNTO 0);
		r1     : std_ulogic_vector(2 DOWNTO 0);
		imm8   : std_ulogic_vector(7 DOWNTO 0);

		--duplicates of r0
		x0w    : std_ulogic_vector(2 DOWNTO 0);
		fl     : std_ulogic_vector(2 DOWNTO 0);

		
		x0r    : std_ulogic_vector(2 DOWNTO 0);

		src    : std_ulogic_vector(2 DOWNTO 0);

		rwr    : std_ulogic;
		xwr    : std_ulogic;
		mwr    : std_ulogic;

		mrd    : std_ulogic;
		fwr    : std_ulogic;

		iim    : std_ulogic;

		psh    : std_ulogic;
		pop    : std_ulogic;

		jmp    : std_ulogic;
		cal    : std_ulogic;
		ret    : std_ulogic;

		hlt    : std_ulogic;
		cycadv : std_ulogic;
	END RECORD t_signals;
END PACKAGE p_decode;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_decode.ALL;
USE work.p_types.ALL;

ENTITY decoder IS 
	PORT(
		instr : IN t_uword; 

		clk           : IN std_ulogic;
		--if the implementation can use mem bus in the same cycle as it provides instructio
		can_skip_wait : IN std_ulogic;

		controls      : OUT t_signals
	);
END ENTITY decoder ;

ARCHITECTURE behav OF decoder IS 
	TYPE t_arr     IS ARRAY (natural RANGE<>) OF std_ulogic_vector(11 DOWNTO 0);
	TYPE t_opsigs  IS ARRAY (natural RANGE<>) of t_arr;

	CONSTANT opsigs: t_opsigs := (
	(
--                  R X M M F P P J C R H A
--                  W W W R W S O M A E L D
--                  R R R D R H P P L T T V
		16#00# => b"0_0_0_0_0_0_0_0_0_0_0_1", --nop
		16#01# => b"0_0_0_0_0_0_0_0_0_0_1_1", --hlt
		16#02# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#03# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#04# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#05# => b"1_0_0_0_0_0_0_0_0_0_0_1", --mov
		16#06# => b"1_0_0_1_0_0_0_0_0_0_0_0", --rdm
		16#07# => b"0_0_1_0_0_0_0_0_0_0_0_0", --wrm
		16#08# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#09# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#0A# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#0B# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#0C# => b"1_0_0_0_0_0_0_0_0_0_0_1", --rdx
		16#0D# => b"0_1_0_0_0_0_0_0_0_0_0_1", --wrx
		16#0E# => b"0_0_1_0_0_1_0_0_0_0_0_0", --psh
		16#0F# => b"1_0_0_1_0_0_1_0_0_0_0_0", --pop
		16#10# => b"1_0_0_0_1_0_0_0_0_0_0_1", --mul
		16#11# => b"0_0_0_0_1_0_0_0_0_0_0_1", --cmp
		16#12# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#13# => b"0_0_0_0_1_0_0_0_0_0_0_1", --tst
		16#14# => b"0_0_0_0_0_0_0_1_0_0_0_1", --jmp
		16#15# => b"0_0_0_0_0_0_0_0_1_0_0_1", --cal
		16#16# => b"0_0_0_0_0_0_0_0_0_1_0_1", --ret
		16#17# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#18# => b"1_0_0_0_1_0_0_0_0_0_0_1", --add
		16#19# => b"1_0_0_0_1_0_0_0_0_0_0_1", --sub
		16#1A# => b"1_0_0_0_1_0_0_0_0_0_0_1", --not
		16#1B# => b"1_0_0_0_1_0_0_0_0_0_0_1", --and
		16#1C# => b"1_0_0_0_1_0_0_0_0_0_0_1", --orr
		16#1D# => b"1_0_0_0_1_0_0_0_0_0_0_1", --xor
		16#1E# => b"1_0_0_0_1_0_0_0_0_0_0_1", --sll
		16#1F# => b"1_0_0_0_1_0_0_0_0_0_0_1"  --slr
	),
	(
--                  R X M M F P P J C R H A
--                  W W W R W S O M A E L D
--                  R R R D R H P P L T T V
		16#00# => b"0_0_0_0_0_0_0_0_0_0_0_1", --nop
		16#01# => b"0_0_0_0_0_0_0_0_0_0_0_1", --hlt
		16#02# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#03# => b"0_0_0_0_0_0_0_0_0_0_0_1", --lkm
		16#04# => b"0_0_0_0_0_0_0_0_0_0_0_1", --ukm
		16#05# => b"0_0_0_0_0_0_0_0_0_0_0_1", --mov
		16#06# => b"0_0_0_0_0_0_0_0_0_0_0_1", --rdm
		16#07# => b"0_0_0_0_0_0_0_0_0_0_0_1", --wrm
		16#08# => b"0_0_0_0_0_0_0_0_0_0_0_1", --rds
		16#09# => b"0_0_0_0_0_0_0_0_0_0_0_1", --wrs
		16#0A# => b"0_0_0_0_0_0_0_0_0_0_0_1", --rds
		16#0B# => b"0_0_0_0_0_0_0_0_0_0_0_1", --wrs
		16#0C# => b"0_0_0_0_0_0_0_0_0_0_0_1", --rdx
		16#0D# => b"0_0_0_0_0_0_0_0_0_0_0_1", --wrx
		16#0E# => b"0_0_0_0_0_0_0_0_0_0_0_1", --psh
		16#0F# => b"0_0_0_0_0_0_0_0_0_0_0_1", --pop
		16#10# => b"0_0_0_0_0_0_0_0_0_0_0_1", --mul
		16#11# => b"0_0_0_0_0_0_0_0_0_0_0_1", --cmp
		16#12# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#13# => b"0_0_0_0_0_0_0_0_0_0_0_1", --tst
		16#14# => b"0_0_0_0_0_0_0_0_0_0_0_1", --jmp
		16#15# => b"0_0_0_0_0_0_0_0_0_0_0_1", --cal
		16#16# => b"0_0_0_0_0_0_0_0_0_0_0_1", --ret
		16#17# => b"0_0_0_0_0_0_0_0_0_0_0_1", --   
		16#18# => b"0_0_0_0_0_0_0_0_0_0_0_1", --add
		16#19# => b"0_0_0_0_0_0_0_0_0_0_0_1", --sub
		16#1A# => b"0_0_0_0_0_0_0_0_0_0_0_1", --not
		16#1B# => b"0_0_0_0_0_0_0_0_0_0_0_1", --and
		16#1C# => b"0_0_0_0_0_0_0_0_0_0_0_1", --orr
		16#1D# => b"0_0_0_0_0_0_0_0_0_0_0_1", --xor
		16#1E# => b"0_0_0_0_0_0_0_0_0_0_0_1", --sll
		16#1F# => b"0_0_0_0_0_0_0_0_0_0_0_1"  --slr
	));

	SIGNAL opcode : std_ulogic_vector(4 DOWNTO 0);
	SIGNAL aluop  : std_ulogic_vector(2 DOWNTO 0);
	SIGNAL isimm  : std_ulogic;

	SIGNAL sgnls  : std_ulogic_vector(11 DOWNTO 0); 
	SIGNAL rsrc   : std_ulogic_vector( 2 DOWNTO 0); 

	SIGNAL curcyc : integer := 0;

BEGIN
	
	isimm <= '1' WHEN instr(15 DOWNTO 11) /= "00000"
	    ELSE '0';
	
	opcode <= instr(15 DOWNTO 11) WHEN isimm
	     ELSE instr( 4 DOWNTO  0);

	aluop <= opcode(2 DOWNTO 0);

	sgnls <=  opsigs(curcyc)(to_integer(unsigned(opcode)));

	rsrc  <= "000" WHEN opcode = "00101" -- 05 mov 
	    ELSE "000" WHEN opcode = "01101" -- 05 wrx 
	    ELSE "001" WHEN opcode = "01100" -- 0C rdx
	    ELSE "011" WHEN opcode = "10000" -- 10 mul
	    ELSE "100" WHEN opcode = "00110" -- 06 rdm
	    ELSE "100" WHEN opcode = "01111" -- 06 pop
	    ELSE "010"; --alu 

	--introduces slight delay to avoid wrong feedback loops
	curcyc <= 0 AFTER 1 PS WHEN can_skip_wait
	     ELSE 1 AFTER 1 PS WHEN sgnls(0) = '0' AND rising_edge(clk)
	     ELSE 0 AFTER 1 PS WHEN rising_edge(clk)
	     ELSE UNAFFECTED;



	controls.aluop  <= aluop;

	controls.r0     <= instr(10 DOWNTO 8);
	controls.fl     <= instr(10 DOWNTO 8);
	controls.x0w    <= instr(10 DOWNTO 8);

	controls.r1     <= instr( 7 DOWNTO 5);
	controls.x0r    <= instr( 7 DOWNTO 5);

	controls.imm8   <= instr( 7 DOWNTO 0);

	controls.src    <= rsrc;

	controls.iim    <= isimm;

	controls.rwr    <= sgnls(11);
	controls.xwr    <= sgnls(10);
	controls.mwr    <= sgnls( 9);

	controls.mrd    <= sgnls( 8);
	controls.fwr    <= sgnls( 7);

	controls.psh    <= sgnls( 6);
	controls.pop    <= sgnls( 5);

	controls.jmp    <= sgnls( 4);
	controls.cal    <= sgnls( 3);
	controls.ret    <= sgnls( 2);

	controls.hlt    <= sgnls( 1);
	controls.cycadv <= sgnls( 0);

END ARCHITECTURE behav;
