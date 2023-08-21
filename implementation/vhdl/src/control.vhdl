/*
	DUs in file in order
		p_control
		control 
		
	p_control
		defines type to be used for control signals

	control
		decodes instructions and sends signals 
		couldve been named better
*/

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE p_control IS
	TYPE t_controls IS RECORD 
		hlt : std_ulogic;
	
		srm : std_ulogic;
		sro : std_ulogic;
		sre : std_ulogic;
		srr : std_ulogic;
	
		wrr : std_ulogic;
		wrm : std_ulogic;
		wre : std_ulogic;
		wrf : std_ulogic;
	
		iim : std_ulogic;

		mul : std_ulogic;
	
		psh : std_ulogic;
		pop : std_ulogic;
	
		jmp : std_ulogic;
		cal : std_ulogic;
		ret : std_ulogic;
	
		cycadv : std_ulogic;
	END RECORD t_controls;
END PACKAGE p_control;


LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_control.ALL;



ENTITY control IS 
	PORT(
		instr         : IN  std_ulogic_vector(15 DOWNTO 0);
		--clk used to sync input signals of instructions taking more than one clock cycle
		clk           : IN  std_ulogic := '0';
		--applicable when there is no need to stall for memory
		--currently only OOOE impl. uses this feature
		can_skip_wait : IN  std_ulogic := '0'; 
	
		alu_op        : OUT std_ulogic_vector( 2 DOWNTO 0);
		controls      : OUT t_controls);
END ENTITY control;


ARCHITECTURE behav OF control IS 
	TYPE opsigs IS ARRAY (natural RANGE<>) OF std_logic_vector(15 DOWNTO 0);
	TYPE arr IS ARRAY (natural RANGE<>) OF opsigs; 

	CONSTANT opsig0 : opsigs := (
--                      A M R C J P P S S S S W W W W H
--                      D U E A M O S R R R R R R R R L
--                      V L T L P P H R M E O F E M R T
			16#00# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- nop
			16#01# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1", -- hlt
			16#02# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", --    
			16#03# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", --    
			16#04# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", --    
			16#05# => b"1_0_0_0_0_0_0_0_0_0_1_0_0_0_1_0", -- mov
			16#06# => b"0_0_0_0_0_0_0_0_1_0_0_0_0_0_1_0", -- rdm
			16#07# => b"0_0_0_0_0_0_0_0_0_0_0_0_0_1_0_0", -- wrm
			16#08# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", --    
			16#09# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", --    
			16#0A# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", --    
			16#0B# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", --    
			16#0C# => b"1_0_0_0_0_0_0_0_0_1_0_0_0_0_1_0", -- rdx
			16#0D# => b"1_0_0_0_0_0_0_0_0_0_0_0_1_0_0_0", -- wrx
			16#0E# => b"0_0_0_0_0_0_1_0_0_0_0_0_0_1_0_0", -- psh
			16#0F# => b"0_0_0_0_0_1_0_0_1_0_0_0_0_0_1_0", -- pop
			16#10# => b"1_1_0_0_0_0_0_0_0_0_0_0_0_0_1_0", -- mul   
			16#11# => b"1_0_0_0_0_0_0_0_0_0_0_1_0_0_0_0", -- cmp
			16#12# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", --    
			16#13# => b"1_0_0_0_0_0_0_0_0_0_0_1_0_0_0_0", -- tst
			16#14# => b"1_0_0_0_1_0_0_0_0_0_0_0_0_0_0_0", -- jmp
			16#15# => b"1_0_0_1_0_0_0_0_0_0_0_0_0_0_0_0", -- cal
			16#16# => b"1_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0", -- ret
			16#17# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", --    
			16#18# => b"1_0_0_0_0_0_0_1_0_0_0_1_0_0_1_0", -- add
			16#19# => b"1_0_0_0_0_0_0_1_0_0_0_1_0_0_1_0", -- sub
			16#1A# => b"1_0_0_0_0_0_0_1_0_0_0_1_0_0_1_0", -- not
			16#1B# => b"1_0_0_0_0_0_0_1_0_0_0_1_0_0_1_0", -- and
			16#1C# => b"1_0_0_0_0_0_0_1_0_0_0_1_0_0_1_0", -- orr
			16#1D# => b"1_0_0_0_0_0_0_1_0_0_0_1_0_0_1_0", -- xor
			16#1E# => b"1_0_0_0_0_0_0_1_0_0_0_0_0_0_1_0", -- sll
			16#1F# => b"1_0_0_0_0_0_0_1_0_0_0_0_0_0_1_0"  -- slr
	);
	CONSTANT opsig1 : opsigs := (
--                      A M R C J P P S S S S W W W W H
--                      D U E A M O S R R R R R R R R L
--                      V L T L P P H R M E O F E M R T
			16#00# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#01# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#02# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#03# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#04# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#05# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#06# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- rdm
			16#07# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- wrm
			16#08# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#09# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#0A# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#0B# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#0C# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#0D# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#0E# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- psh
			16#0F# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- pop
			16#10# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#11# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#12# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#13# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#14# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#15# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#16# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#17# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#18# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#19# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#1A# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#1B# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#1C# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#1D# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#1E# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- 
			16#1F# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0"  -- 
		);

	CONSTANT rom : arr := (
			opsig0,
			opsig1
	);


	SIGNAL opcode     : std_ulogic_vector( 4 DOWNTO 0) := "00000";
	SIGNAL curind     : std_ulogic_vector( 0 DOWNTO 0) := "0";
	SIGNAL signals    : std_ulogic_vector(15 DOWNTO 0) := x"0000";

BEGIN

	--these 3 assignments are based on isa
	controls.iim <= '0' WHEN instr(15 DOWNTO 11) = "00000" 
	           ELSE '1';
	opcode <= instr( 4 DOWNTO 0) WHEN instr(15 DOWNTO 11) = "00000" 
	     ELSE instr(15 DOWNTO 11);
	alu_op <= opcode(2 DOWNTO 0);

	--these 2 assignments allow instructions that need it to take 2 cycles 
	signals <= rom(to_integer(unsigned(curind)))(to_integer(unsigned(opcode))) AFTER 1 ps;
	curind  <= "0" WHEN can_skip_wait = '1'
	      ELSE "1" WHEN signals(15) = '0' AND rising_edge(clk)
	      ELSE "0" WHEN rising_edge(clk)
	      ELSE UNAFFECTED;

	--extracting concrete signals
	controls.hlt    <= signals(00);
	controls.wrr    <= signals(01);
	controls.wrm    <= signals(02);
	controls.wre    <= signals(03);
	controls.wrf    <= signals(04);
	controls.sro    <= signals(05);
	controls.sre    <= signals(06);
	controls.srm    <= signals(07);
	controls.srr    <= signals(08);
	controls.psh    <= signals(09);
	controls.pop    <= signals(10);
	controls.jmp    <= signals(11);
	controls.cal    <= signals(12);
	controls.ret    <= signals(13);
	controls.mul    <= signals(14);
	controls.cycadv <= signals(15);
	

END ARCHITECTURE behav;



