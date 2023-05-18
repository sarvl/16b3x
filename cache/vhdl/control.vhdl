LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;


ENTITY control IS 
		PORT(
			i0  : IN  std_logic_vector(15 DOWNTO 0);
			clk : IN  std_logic;

			--halt
			hlt : OUT std_logic;
			--write register
			wrr : OUT std_logic;
			--write memory 
			wrm : OUT std_logic;
			--write external 
			wre : OUT std_logic;
			--write flags 
			wrf : OUT std_logic;
			--isimm
			iim : OUT std_logic;
			--source operand
			sro : OUT std_logic;
			--source external
			sre : OUT std_logic;
			--source memory
			srm : OUT std_logic;
			--source result
			srr : OUT std_logic;
			--invalid
			inv : OUT std_logic;

			--instructions requiring special care
			psh : OUT std_logic;
			pop : OUT std_logic;
			jmp : OUT std_logic;
			cal : OUT std_logic;
			ret : OUT std_logic;

			alu_op : OUT std_logic_vector(2 DOWNTO 0);

			--next cycle, if off then DO not advance ip 
			cycadv : OUT std_logic);

END ENTITY control;


ARCHITECTURE behav OF control IS 
	CONSTANT op_nop : std_logic_vector(4 DOWNTO 0) := "00000"; 
	CONSTANT op_hlt : std_logic_vector(4 DOWNTO 0) := "00001"; 



	CONSTANT op_mov : std_logic_vector(4 DOWNTO 0) := "00101"; 
	CONSTANT op_rdm : std_logic_vector(4 DOWNTO 0) := "00110"; 
	CONSTANT op_wrm : std_logic_vector(4 DOWNTO 0) := "00111"; 




	CONSTANT op_rdx : std_logic_vector(4 DOWNTO 0) := "01100"; 
	CONSTANT op_wrx : std_logic_vector(4 DOWNTO 0) := "01101"; 
	CONSTANT op_psh : std_logic_vector(4 DOWNTO 0) := "01110"; 
	CONSTANT op_pop : std_logic_vector(4 DOWNTO 0) := "01111"; 

	CONSTANT op_cmp : std_logic_vector(4 DOWNTO 0) := "10001"; 

	CONSTANT op_tst : std_logic_vector(4 DOWNTO 0) := "10011"; 
	CONSTANT op_jmp : std_logic_vector(4 DOWNTO 0) := "10100"; 
	CONSTANT op_cal : std_logic_vector(4 DOWNTO 0) := "10101"; 
	CONSTANT op_ret : std_logic_vector(4 DOWNTO 0) := "10110"; 

	CONSTANT op_add : std_logic_vector(4 DOWNTO 0) := "11000"; 
	CONSTANT op_sub : std_logic_vector(4 DOWNTO 0) := "11001"; 
	CONSTANT op_not : std_logic_vector(4 DOWNTO 0) := "11010"; 
	CONSTANT op_and : std_logic_vector(4 DOWNTO 0) := "11011"; 
	CONSTANT op_orr : std_logic_vector(4 DOWNTO 0) := "11100"; 
	CONSTANT op_xor : std_logic_vector(4 DOWNTO 0) := "11101"; 
	CONSTANT op_sll : std_logic_vector(4 DOWNTO 0) := "11110"; 
	CONSTANT op_slr : std_logic_vector(4 DOWNTO 0) := "11111"; 
                
                

	SIGNAL next_cycle : std_logic := '0';
	SIGNAL opcode : std_logic_vector(4 DOWNTO 0) := "00000";

	SIGNAL curind : std_logic_vector(0 DOWNTO 0) := "0";

	SIGNAL signals : std_logic_vector(15 DOWNTO 0);

	
	TYPE opsigs IS ARRAY (natural RANGE<>) OF std_logic_vector(15 DOWNTO 0);
	TYPE arr IS ARRAY (natural RANGE<>) OF opsigs; 

	CONSTANT opsig0 : opsigs := (
--                      A R C J P P I S S S S W W W W H
--                      D E A M O S N R R R R R R R R L
--                      V T L P P H V R M E O F E M R T
			16#00# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- nop
			16#01# => b"1_0_0_0_0_0_0_0_0_0_0_0_0_0_0_1", -- hlt
			16#02# => b"1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0", --    
			16#03# => b"1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0", --    
			16#04# => b"1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0", --    
			16#05# => b"1_0_0_0_0_0_0_0_0_0_1_0_0_0_1_0", -- mov
			16#06# => b"0_0_0_0_0_0_0_0_1_0_0_0_0_0_1_0", -- rdm
			16#07# => b"0_0_0_0_0_0_0_0_0_0_0_0_0_1_0_0", -- wrm
			16#08# => b"1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0", --    
			16#09# => b"1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0", --    
			16#0A# => b"1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0", --    
			16#0B# => b"1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0", --    
			16#0C# => b"1_0_0_0_0_0_0_0_0_1_0_0_0_0_1_0", -- rdx
			16#0D# => b"1_0_0_0_0_0_0_0_0_0_0_0_1_0_0_0", -- wrx
			16#0E# => b"0_0_0_0_0_1_0_0_0_0_0_0_0_1_0_0", -- psh
			16#0F# => b"0_0_0_0_1_0_0_0_0_0_0_0_0_0_1_0", -- pop
			16#10# => b"1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0", --    
			16#11# => b"1_0_0_0_0_0_0_0_0_0_0_1_0_0_0_0", -- cmp
			16#12# => b"1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0", --    
			16#13# => b"1_0_0_0_0_0_0_0_0_0_0_1_0_0_0_0", -- tst
			16#14# => b"1_0_0_1_0_0_0_0_0_0_0_0_0_0_0_0", -- jmp
			16#15# => b"1_0_1_0_0_0_0_0_0_0_0_0_0_0_0_0", -- cal
			16#16# => b"1_1_0_0_0_0_0_0_0_0_0_0_0_0_0_0", -- ret
			16#17# => b"1_0_0_0_0_0_1_0_0_0_0_0_0_0_0_0", --    
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
--                      A R C J P P I S S S S W W W W H
--                      D E A M O S N R R R R R R R R L
--                      V T L P P H V R M E O F E M R T
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


BEGIN
	
	iim    <= '0' WHEN i0(15 DOWNTO 11) = "00000" ELSE '1';
	opcode <= i0(4 DOWNTO 0) WHEN i0(15 DOWNTO 11) = "00000" ELSE i0(15 DOWNTO 11);
	alu_op <= opcode(2 DOWNTO 0);


	--delay is to prevent oscilation, this is a solution
	--i dont think this is the solution
	signals <= rom(to_integer(unsigned(curind)))(to_integer(unsigned(opcode))) AFTER 1 ps;


	curind <= "1" WHEN signals(15) = '0' AND rising_edge(clk)
	     ELSE "0" WHEN rising_edge(clk); 



	hlt    <= signals(00);
	wrr    <= signals(01);
	wrm    <= signals(02);
	wre    <= signals(03);
	wrf    <= signals(04);
	sro    <= signals(05);
	sre    <= signals(06);
	srm    <= signals(07);
	srr    <= signals(08);
	inv    <= signals(09);
	psh    <= signals(10);
	pop    <= signals(11);
	jmp    <= signals(12);
	cal    <= signals(13);
	ret    <= signals(14);
	cycadv <= signals(15);

END ARCHITECTURE behav;
