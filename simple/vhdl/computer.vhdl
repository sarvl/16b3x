LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;


ENTITY computer IS 
END ENTITY computer;


ARCHITECTURE behav OF computer IS 

-- GATES
	COMPONENT gate_and2_3bit IS 
		PORT(
				i0 : IN  std_logic_vector(2 DOWNTO 0);
				i1 : IN  std_logic_vector(2 DOWNTO 0);
				o0 : OUT std_logic_vector(2 DOWNTO 0));
	END COMPONENT gate_and2_3bit;
-- GATES 

-- ARITHMETIC COMPONENTS
	COMPONENT alu IS 
		PORT(
			i0 : IN  std_logic_vector(15 DOWNTO 0);
			i1 : IN  std_logic_vector(15 DOWNTO 0);
	
			o0 : OUT std_logic_vector(15 DOWNTO 0);
	
			op : IN  std_logic_vector(2 DOWNTO 0));
	END COMPONENT alu;
	
	COMPONENT arith_adder_16bit IS 
		PORT (
			i0: IN  std_logic_vector(15 DOWNTO 0);
			i1: IN  std_logic_vector(15 DOWNTO 0);
			ic: IN  std_logic;
			
			o0: OUT std_logic_vector(15 DOWNTO 0);
			oc: OUT std_logic);
	END COMPONENT arith_adder_16bit; 

	COMPONENT arith_shifter_left_16bit IS
		PORT(
			i0 : IN  std_logic_vector(15 DOWNTO 0);
			o0 : OUT std_logic_vector(15 DOWNTO 0);
	
			am : IN  std_logic_vector(3 DOWNTO 0));
	END COMPONENT arith_shifter_left_16bit;
-- ARITHMETIC COMPONENTS

-- REGISTERS 
	COMPONENT reg_file IS 
		PORT(
			i0  : IN  std_logic_vector(15 DOWNTO 0);
			
			o0  : OUT std_logic_vector(15 DOWNTO 0);
			o1  : OUT std_logic_vector(15 DOWNTO 0);
	
			
			r0  : IN  std_logic_vector(2 DOWNTO 0);
			r1  : IN  std_logic_vector(2 DOWNTO 0);
	
			we  : IN  std_logic;
			clk : IN  std_logic);
	END COMPONENT reg_file;

	COMPONENT reg_16bit IS 
		PORT(
			i0  : IN  std_logic_vector(15 DOWNTO 0);
			o0  : OUT std_logic_vector(15 DOWNTO 0);
			
			we  : IN  std_logic;
			clk : IN  std_logic);
	END COMPONENT reg_16bit;

	COMPONENT reg_flags IS 
		PORT(
			i0  : IN  std_logic_vector(15 DOWNTO 0);
			o0  : OUT std_logic_vector(15 DOWNTO 0) := x"0001";
			
			we  : IN  std_logic;
			clk : IN  std_logic);
	END COMPONENT reg_flags;
-- REGISTERS

-- RAM
	COMPONENT ram IS
		PORT(
			a0  : IN  std_logic_vector(15 DOWNTO 0);
			i0  : IN  std_logic_vector(15 DOWNTO 0);
			o0  : OUT std_logic_vector(15 DOWNTO 0);

			we  : IN  std_logic;
			clk : IN  std_logic);
	END COMPONENT ram;
-- RAM

-- CONTROL
	COMPONENT control IS 
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
			--used for instructins that require more than one cycle, see control for which one do have it on 
			cycadv : OUT std_logic);
	END COMPONENT control;
-- CONTROL

-- constants
	CONSTANT const_16bit_1  : std_logic_vector(15 DOWNTO 0) := x"0001";
	CONSTANT const_16bit_2  : std_logic_vector(15 DOWNTO 0) := x"0002";
	CONSTANT const_16bit_m2 : std_logic_vector(15 DOWNTO 0) := x"FFFE";
	CONSTANT const_0        : std_logic := '0';
-- constants

-- signals clock 
	CONSTANT clk_duration : time := 1 ns;
	SIGNAL   clk          : std_logic := '0';
-- signals clock 

-- signals control 
	SIGNAL instr : std_logic_vector(15 DOWNTO 0);

	SIGNAL hlt    : std_logic := '0';
	SIGNAL wrr    : std_logic := '0';
	SIGNAL wrm    : std_logic := '0';
	SIGNAL wre    : std_logic := '0';
	SIGNAL wrf    : std_logic := '0';
	SIGNAL iim    : std_logic := '0';
	SIGNAL sro    : std_logic := '0';
	SIGNAL sre    : std_logic := '0';
	SIGNAL srm    : std_logic := '0';
	SIGNAL srr    : std_logic := '0';
	SIGNAL inv    : std_logic := '0';
	SIGNAL psh    : std_logic := '0';
	SIGNAL pop    : std_logic := '0';
	SIGNAL jmp    : std_logic := '0';
	SIGNAL cal    : std_logic := '0';
	SIGNAL ret    : std_logic := '0';
	SIGNAL alu_op : std_logic_vector(2 DOWNTO 0);
	SIGNAL cycadv : std_logic := '1';
-- signals control 

-- signals registers
	SIGNAL   r_ip_in  : std_logic_vector(15 DOWNTO 0);
	SIGNAL   r_ip_out : std_logic_vector(15 DOWNTO 0);
	--write to sp controled by cycadv
	SIGNAL   ipinc    : std_logic_vector(15 DOWNTO 0);
	SIGNAL   ipsll    : std_logic_vector(15 DOWNTO 0);

	SIGNAL   r_sp_in  : std_logic_vector(15 DOWNTO 0);
	SIGNAL   r_sp_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL   wrsp     : std_logic := '0';
	SIGNAL   spp2     : std_logic_vector(15 DOWNTO 0);
	SIGNAL   sps2     : std_logic_vector(15 DOWNTO 0);

	SIGNAL   r_lr_in  : std_logic_vector(15 DOWNTO 0);
	SIGNAL   r_lr_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL   wrlr     : std_logic := '0';

	SIGNAL   r_ui_in  : std_logic_vector(15 DOWNTO 0);
	SIGNAL   r_ui_out : std_logic_vector(15 DOWNTO 0);
	SIGNAL   wrui     : std_logic := '0';

	SIGNAL   r_fl_in  : std_logic_vector(15 DOWNTO 0);
	SIGNAL   r_fl_out : std_logic_vector(15 DOWNTO 0);
	--write to flags controled by wrf
	SIGNAL   flcmp    : std_logic_vector( 2 DOWNTO 0);
-- signals registers

-- signals ram
	SIGNAL   ram_adr : std_logic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL   dataadr : std_logic_vector(15 DOWNTO 0);
	SIGNAL   ram_in  : std_logic_vector(15 DOWNTO 0);
	SIGNAL   ram_out : std_logic_vector(15 DOWNTO 0);
-- signals ram

-- signals alu
	SIGNAL   alu_out : std_logic_vector(15 DOWNTO 0);
	--alu in inside signals control
-- signals alu

-- signals operands
	SIGNAL   op0 : std_logic_vector(15 DOWNTO 0);
	SIGNAL   op1 : std_logic_vector(15 DOWNTO 0);
	SIGNAL   imm8  : std_logic_vector( 7 DOWNTO 0);
	SIGNAL   imm16 : std_logic_vector(15 DOWNTO 0);
-- signals operands

-- signals regfile
	SIGNAL   r0  : std_logic_vector( 2 DOWNTO 0);
	SIGNAL   r1  : std_logic_vector( 2 DOWNTO 0);
	SIGNAL   r0o : std_logic_vector(15 DOWNTO 0);
	SIGNAL   r1o : std_logic_vector(15 DOWNTO 0);
	SIGNAL   r0i : std_logic_vector(15 DOWNTO 0);
-- signals reg file	

BEGIN
	PROCESS IS 
	BEGIN
		clk <= '0';
		WAIT FOR clk_duration / 2;
		clk <= '1' AND (NOT hlt);
		WAIT FOR clk_duration / 2;
	END PROCESS;
	
-- ALU 
	aluo:   alu       PORT MAP(i0  => op0,
	                           i1  => op1,
	                           o0  => alu_out,
	                           op  => alu_op);
-- ALU 

-- REGISTERS 
	rgf:    reg_file  PORT MAP(r0  => r0,
	                           r1  => r1,
	                           i0  => r0i,
	                           o0  => r0o,
	                           o1  => r1o,
	                           we  => wrr,
	                           clk => clk);


	reg_ip: reg_16bit PORT MAP(i0  => r_ip_in,
	                           o0  => r_ip_out,
	                           we  => cycadv,
	                           clk => clk);
	ipadd: arith_adder_16bit PORT MAP(i0 => r_ip_out,
	                                  i1 => const_16bit_1,
	                                  ic => const_0,
	                                  o0 => ipinc,
	                                  oc => OPEN);


	reg_sp: reg_16bit PORT MAP(i0  => r_sp_in,
	                           o0  => r_sp_out,
	                           we  => '1',
	                           clk => clk);
	spadd: arith_adder_16bit PORT MAP(i0 => r_sp_out,
	                                  i1 => const_16bit_2,
	                                  ic => const_0,
	                                  o0 => spp2,
	                                  oc => OPEN);
	spsub: arith_adder_16bit PORT MAP(i0 => r_sp_out,
	                                  i1 => const_16bit_m2,
	                                  ic => const_0,
	                                  o0 => sps2,
	                                  oc => OPEN);

	reg_lr: reg_16bit PORT MAP(i0  => r_lr_in,
	                           o0  => r_lr_out,
	                           we  => wrlr,
	                           clk => clk);
	reg_ui: reg_16bit PORT MAP(i0  => r_ui_in,
	                           o0  => r_ui_out,
	                           we  => '1',
	                           clk => clk);
	reg_fl: reg_flags PORT MAP(i0  => r_fl_in,
	                           o0  => r_fl_out,
	                           we  => wrf,
	                           clk => clk);
	cmpfl: gate_and2_3bit PORT MAP(r0, 
	                               r_fl_out(2 DOWNTO 0),
	                               flcmp);

-- REGISTERS

-- RAM
	ramo:   ram       PORT MAP(a0  => ram_adr,
	                           i0  => ram_in,
	                           o0  => ram_out,
	                           we  => wrm,
	                           clk => clk);
-- RAM

-- CONTROL
	cntrl: control PORT MAP(
			instr,
			clk,
			hlt,
			wrr,
			wrm,
			wre,
			wrf,
			iim,
			sro,
			sre,
			srm,
			srr,
			inv,
			psh,
			pop,
			jmp,
			cal,
			ret,
			alu_op,
			cycadv);
-- CONTROL

	--shifting ip by 1 to comply with the way it is encoded 
	ipsll   <= r_ip_out(14 DOWNTO 0) & "0";
	--as below 
	instr   <= ram_out WHEN cycadv = '1';
	--if advance instruction then it is certain instr does not use memory, except for fetching 
	ram_adr <= ipsll   WHEN cycadv = '1' 
	      ELSE dataadr;
	--only when instruction uses memory ram_in matters
	ram_in  <= op0 WHEN psh = '1' OR wrm = '1';
	dataadr <= sps2     WHEN psh = '1' 
	      ELSE r_sp_out WHEN pop = '1'
	      ELSE op1      WHEN wrm = '1' OR srm = '1';

	--as isa specifies
	imm8    <= instr( 7 DOWNTO 0);
	r0      <= instr(10 DOWNTO 8);
	r1      <= instr( 7 DOWNTO 5);
	--extending immiediate
	imm16 <= r_ui_out(7 DOWNTO 0) 
	       & imm8;

	--taking operands 
	op0 <= r0o;
	op1 <= imm16 WHEN iim  = '1' ELSE r1o;

	--see control for explanation of `srX` signals
	r0i <= op1      WHEN sro = '1'                 
	  ELSE alu_out  WHEN srr = '1'                 
	  ELSE ram_out  WHEN pop = '1' OR  srm = '1'   
	  ELSE r_ip_out WHEN sre = '1' AND  r1 = "000" 
	  ELSE r_sp_out WHEN sre = '1' AND  r1 = "001" 
	  ELSE r_lr_out WHEN sre = '1' AND  r1 = "010" 
	  ELSE r_ui_out WHEN sre = '1' AND  r1 = "100" 
	  ELSE r_fl_out WHEN sre = '1' AND  r1 = "101" 
	  ELSE x"0000";

	r_sp_in <= spp2      WHEN pop = '1'                 
	      ELSE sps2      WHEN psh = '1'                 
	      ELSE op1       WHEN wre = '1' AND  r0 = "001" 
	      ELSE r_sp_out;
	wrsp    <= '1' WHEN psh = '1' OR pop = '1' 
	      ELSE '0';


	r_ui_in <= op1 WHEN wre = '1' AND r0 = "100"
	      ELSE x"0000";


	r_lr_in <= ipinc    WHEN cal = '1' AND flcmp /= "000" 
	      ELSE op1      WHEN wre = '1' AND   r0   = "010";
	wrlr    <= '1' WHEN cal = '1'               
	      ELSE '1' WHEN wre = '1' AND r0 = "010"
		  ELSE '0';

	r_ip_in <= op1      WHEN jmp = '1' AND flcmp /= "000" 
	      ELSE op1      WHEN cal = '1' AND flcmp /= "000" 
	      ELSE r_lr_out WHEN ret = '1' AND flcmp /= "000" 
	      ELSE op1      WHEN wre = '1' AND r0     = "000" 
	      ELSE ipinc;

	r_fl_in <= x"0004" WHEN alu_out(15) = '1'         
	      ELSE x"0002" WHEN alu_out     = x"0000"     
	      ELSE op1     WHEN wre = '1' AND  r0 = "101" 
	      ELSE x"0001";





END ARCHITECTURE behav;
