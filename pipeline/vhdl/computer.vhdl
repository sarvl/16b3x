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
	
			
			rd  : IN  std_logic_vector(2 DOWNTO 0);
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

-- STAGE
	COMPONENT stage IS
		PORT(
			clk          : IN  std_logic := '0';
			update_stage : IN  std_logic;
	
			ir0  : IN  std_logic_vector( 2 DOWNTO 0);
			ir1  : IN  std_logic_vector( 2 DOWNTO 0);
			ires : IN  std_logic_vector(15 DOWNTO 0);
			imem : IN  std_logic_vector(15 DOWNTO 0);
			iop0 : IN  std_logic_vector(15 DOWNTO 0);
			iop1 : IN  std_logic_vector(15 DOWNTO 0);
			iflg : IN  std_logic_vector( 2 DOWNTO 0);
			iwrr : IN  std_logic;
			iwrm : IN  std_logic;
			iwre : IN  std_logic;
			iwrf : IN  std_logic;
			isro : IN  std_logic;
			isrr : IN  std_logic;
			isrm : IN  std_logic;
			ipsh : IN  std_logic;
			ipop : IN  std_logic;
			ijmp : IN  std_logic;
			ical : IN  std_logic;
			iret : IN  std_logic;
			ialu_op : IN  std_logic_vector(2 DOWNTO 0);
			icycadv : IN  std_logic;
			ihlt: IN  std_logic;
			iiim: IN  std_logic;
	
			or0  : OUT std_logic_vector( 2 DOWNTO 0);
			or1  : OUT std_logic_vector( 2 DOWNTO 0);
			ores : OUT std_logic_vector(15 DOWNTO 0);
			omem : OUT std_logic_vector(15 DOWNTO 0);
			oop0 : OUT std_logic_vector(15 DOWNTO 0);
			oop1 : OUT std_logic_vector(15 DOWNTO 0);
			oflg : OUT std_logic_vector( 2 DOWNTO 0);
			owrr : OUT std_logic;
			owrm : OUT std_logic;
			owre : OUT std_logic;
			owrf : OUT std_logic;
			osro : OUT std_logic;
			osrr : OUT std_logic;
			osrm : OUT std_logic;
			opsh : OUT std_logic;
			opop : OUT std_logic;
			ojmp : OUT std_logic;
			ocal : OUT std_logic;
			oret : OUT std_logic;
			oalu_op : OUT std_logic_vector(2 DOWNTO 0);
			ocycadv : OUT std_logic;
			ohlt : OUT std_logic;
			oiim : OUT std_logic);
	END COMPONENT stage;
-- STAGE

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

	SIGNAL sre    : std_logic := '0';
	SIGNAL inv    : std_logic := '0';
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
	SIGNAL   imm8  : std_logic_vector( 7 DOWNTO 0);
	SIGNAL   imm16 : std_logic_vector(15 DOWNTO 0);
-- signals operands

-- signals regfile
	SIGNAL   r0o : std_logic_vector(15 DOWNTO 0);
	SIGNAL   r1o : std_logic_vector(15 DOWNTO 0);
	SIGNAL   r0i : std_logic_vector(15 DOWNTO 0);
-- signals reg file	


	SIGNAL next_stage : std_logic := '1';


	TYPE passed_signals IS RECORD 
		r0  : std_logic_vector( 2 DOWNTO 0);
		r1  : std_logic_vector( 2 DOWNTO 0);
		res : std_logic_vector(15 DOWNTO 0);
		mem : std_logic_vector(15 DOWNTO 0);
		op0 : std_logic_vector(15 DOWNTO 0);
		op1 : std_logic_vector(15 DOWNTO 0);
		flg : std_logic_vector( 2 DOWNTO 0);
		wrr : std_logic;
		wrm : std_logic;
		wre : std_logic;
		wrf : std_logic;
		sro : std_logic;
		srr : std_logic;
		srm : std_logic;
		psh : std_logic;
		pop : std_logic;
		jmp : std_logic;
		cal : std_logic;
		ret : std_logic;
		alu_op : std_logic_vector(2 DOWNTO 0);
		cycadv : std_logic;
		hlt : std_logic;
		iim : std_logic;
	END RECORD passed_signals;


	SIGNAL s0_signals : passed_signals;
	SIGNAL s1_signals : passed_signals;
	SIGNAL s2_signals : passed_signals;


	SIGNAL alu_in0 : std_logic_vector(15 DOWNTO 0);
	SIGNAL alu_in1 : std_logic_vector(15 DOWNTO 0);

	SIGNAL instr_adr : std_logic_vector(15 DOWNTO 0);
BEGIN
	PROCESS IS 
	BEGIN
		clk <= '0';
		WAIT FOR clk_duration / 2;
		clk <= '1' AND (NOT s2_signals.hlt);
		WAIT FOR clk_duration / 2;
	END PROCESS;
	
-- ALU 
	aluo:   alu       PORT MAP(i0  => alu_in0, 
	                           i1  => alu_in1,
	                           o0  => alu_out,
	                           op  => s1_signals.alu_op);
-- ALU 

-- REGISTERS 
	rgf:    reg_file  PORT MAP(rd  => s2_signals.r0,
	                           r0  => s0_signals.r0,
	                           r1  => s0_signals.r1,
	                           i0  => r0i,
	                           o0  => r0o,
	                           o1  => r1o,
	                           we  => s2_signals.wrr,
	                           clk => clk);


	reg_ip: reg_16bit PORT MAP(i0  => r_ip_in,
	                           o0  => r_ip_out,
	                           we  => next_stage,
	                           clk => clk);
	ipadd: arith_adder_16bit PORT MAP(i0 => instr_adr,
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
	                           we  => wrui,
	                           clk => clk);
	reg_fl: reg_flags PORT MAP(i0  => r_fl_in,
	                           o0  => r_fl_out,
	                           we  => s1_signals.wrf,
	                           clk => clk);
	cmpfl: gate_and2_3bit PORT MAP(s1_signals.r0, 
	                               r_fl_out(2 DOWNTO 0),
	                               flcmp);

	--s0_ftchandec ; outputs data to s0_signals
	s1_execution: stage PORT MAP(clk, next_stage,
		s0_signals.r0,     s0_signals.r1,        s0_signals.res, s0_signals.mem, s0_signals.op0, 
		s0_signals.op1,    s0_signals.flg,       s0_signals.wrr, s0_signals.wrm, s0_signals.wre,    
		s0_signals.wrf,    s0_signals.sro,       s0_signals.srr, s0_signals.srm, s0_signals.psh,
		s0_signals.pop,    s0_signals.jmp,       s0_signals.cal, s0_signals.ret, s0_signals.alu_op, 
		s0_signals.cycadv, s0_signals.hlt,       s0_signals.iim,
		s1_signals.r0,     s1_signals.r1,        s1_signals.res, s1_signals.mem, s1_signals.op0, 
		s1_signals.op1,    s1_signals.flg,       s1_signals.wrr, s1_signals.wrm, s1_signals.wre,    
		s1_signals.wrf,    s1_signals.sro,       s1_signals.srr, s1_signals.srm, s1_signals.psh,
		s1_signals.pop,    s1_signals.jmp,       s1_signals.cal, s1_signals.ret, s1_signals.alu_op, 
		s1_signals.cycadv, s1_signals.hlt,       s1_signals.iim);
	s1_writeback: stage PORT MAP(clk, next_stage,
		s1_signals.r0,     r_fl_out(2 DOWNTO 0), alu_out,        ram_out,        s1_signals.op0, 
		s1_signals.op1,    s1_signals.flg,       s1_signals.wrr, s1_signals.wrm, s1_signals.wre,    
		s1_signals.wrf,    s1_signals.sro,       s1_signals.srr, s1_signals.srm, s1_signals.psh,
		s1_signals.pop,    s1_signals.jmp,       s1_signals.cal, s1_signals.ret, s1_signals.alu_op, 
		s1_signals.cycadv, s1_signals.hlt,       s1_signals.iim,
		s2_signals.r0,     s2_signals.r1,        s2_signals.res, s2_signals.mem, s2_signals.op0, 
		s2_signals.op1,    s2_signals.flg,       s2_signals.wrr, s2_signals.wrm, s2_signals.wre,    
		s2_signals.wrf,    s2_signals.sro,       s2_signals.srr, s2_signals.srm, s2_signals.psh,
		s2_signals.pop,    s2_signals.jmp,       s2_signals.cal, s2_signals.ret, s2_signals.alu_op, 
		s2_signals.cycadv, s2_signals.hlt,       s2_signals.iim);

-- REGISTERS

-- RAM
	ramo:   ram       PORT MAP(a0  => ram_adr,
	                           i0  => ram_in,
	                           o0  => ram_out,
	                           we  => s2_signals.wrm,
	                           clk => clk);
-- RAM

-- CONTROL
	cntrl: control PORT MAP(
			instr,
			clk,
			s0_signals.hlt,
			s0_signals.wrr,
			s0_signals.wrm,
			s0_signals.wre,
			s0_signals.wrf,
			s0_signals.iim,
			s0_signals.sro,
			sre,
			s0_signals.srm,
			s0_signals.srr,
			inv,
			s0_signals.psh,
			s0_signals.pop,
			s0_signals.jmp,
			s0_signals.cal,
			s0_signals.ret,
			s0_signals.alu_op,
			s0_signals.cycadv);
-- CONTROL

	--shifting ip by 1 to comply with the way it is encoded 
	ipsll   <= instr_adr(14 DOWNTO 0) & "0";
	--as below 
	instr   <= ram_out WHEN next_stage = '1';
	--if advance instruction then it is certain instr does not use memory, except for fetching 
	ram_adr <= ipsll   WHEN next_stage = '1' 
	      ELSE dataadr;
	--only when instruction uses memory ram_in matters
	ram_in  <= s2_signals.op0 WHEN s2_signals.psh = '1' OR s2_signals.wrm = '1';
	dataadr <= sps2           WHEN s2_signals.psh = '1' 
	      ELSE r_sp_out       WHEN s2_signals.pop = '1'
	      ELSE s2_signals.op1 WHEN s2_signals.wrm = '1' OR s2_signals.srm = '1';

	--as isa specifies
	imm8          <= instr( 7 DOWNTO 0);
	s0_signals.r0 <= instr(10 DOWNTO 8);
	s0_signals.r1 <= instr( 7 DOWNTO 5);
	--extending immiediate
	imm16 <= r_ui_out(7 DOWNTO 0) 
	       & imm8;

	--taking operands 
	s0_signals.op0 <= alu_out        WHEN s1_signals.srr = '1' AND s1_signals.r0 = s0_signals.r0
	             ELSE s1_signals.op1 WHEN s1_signals.sro = '1' AND s1_signals.r0 = s0_signals.r0

	             ELSE s2_signals.res WHEN s2_signals.srr = '1' AND s2_signals.r0 = s0_signals.r0
	             ELSE s2_signals.op1 WHEN s2_signals.sro = '1' AND s2_signals.r0 = s0_signals.r0

	             ELSE r0o;
	s0_signals.op1 <= imm16          WHEN s0_signals.iim = '1' 

	             ELSE alu_out        WHEN s1_signals.srr = '1' AND s1_signals.r0 = s0_signals.r1
	             ELSE s1_signals.op1 WHEN s1_signals.sro = '1' AND s1_signals.r0 = s0_signals.r1
	             
				 ELSE s2_signals.res WHEN s2_signals.srr = '1' AND s2_signals.r0 = s0_signals.r1
	             ELSE s2_signals.op1 WHEN s2_signals.sro = '1' AND s2_signals.r0 = s0_signals.r1

	             ELSE r1o;

	--see control for explanation of `srX` signals
	r0i <= s2_signals.op1 WHEN s2_signals.sro = '1'                 
	  ELSE s2_signals.res WHEN s2_signals.srr = '1'                 
--	  ELSE s2_signals.mem WHEN s2_signals.pop = '1' OR  s2_signals.srm = '1'   
--	  ELSE r_ip_out       WHEN s2_signals.sre = '1' AND  r1 = "000" 
--	  ELSE r_sp_out       WHEN s2_signals.sre = '1' AND  r1 = "001" 
--	  ELSE r_lr_out       WHEN s2_signals.sre = '1' AND  r1 = "010" 
--	  ELSE r_ui_out       WHEN s2_signals.sre = '1' AND  r1 = "100" 
--	  ELSE r_fl_out       WHEN s2_signals.sre = '1' AND  r1 = "101" 
	  ELSE x"0000";

--	r_sp_in <= spp2      WHEN pop = '1'                 
--	      ELSE sps2      WHEN psh = '1'                 
--	      ELSE op1       WHEN wre = '1' AND  r0 = "001" 
--	      ELSE r_sp_out;
--	wrsp    <= '1' WHEN psh = '1' OR pop = '1' 
--	      ELSE '0';


--	r_ui_in <= op1 WHEN wre = '1' AND r0 = "100";
--	wrui    <= '1' WHEN wre = '1' AND r0 = "100" 
--     ELSE '0';


--	r_lr_in <= ipinc    WHEN cal = '1' AND flcmp /= "000" 
--	      ELSE op1      WHEN wre = '1' AND   r0   = "010";
--	wrlr    <= '1' WHEN cal = '1'               
--	      ELSE '1' WHEN wre = '1' AND r0 = "010"
--		  ELSE '0';

	r_ip_in   <= ipinc; 
--	      ELSE op1      WHEN wre = '1' AND r0     = "000" 
	instr_adr <= r_ip_out       WHEN next_stage = '0' 
	        ELSE s1_signals.op1 WHEN s1_signals.jmp = '1' AND flcmp /= "000"
	        ELSE s1_signals.op1 WHEN s1_signals.cal = '1' AND flcmp /= "000" 
	        ELSE r_lr_out       WHEN s1_signals.ret = '1' AND flcmp /= "000" 
	        ELSE r_ip_out;

	r_fl_in <= x"0004" WHEN alu_out(15) = '1'         
	      ELSE x"0002" WHEN alu_out     = x"0000"     
--	      ELSE op1     WHEN wre = '1' AND  r0 = "101" 
	      ELSE x"0001";

	alu_in0 <= s2_signals.res WHEN s2_signals.r0 = s1_signals.r0 AND s2_signals.srr = '1'
	      ELSE s2_signals.op1 WHEN s2_signals.r0 = s1_signals.r0 AND s2_signals.sro = '1'
	      
		  ELSE s1_signals.op0;
	alu_in1 <= s1_signals.op1 WHEN s1_signals.iim = '1'

	      ELSE s2_signals.res WHEN s2_signals.r0 = s1_signals.r1 AND s2_signals.srr = '1'
	      ELSE s2_signals.op1 WHEN s2_signals.r0 = s1_signals.r1 AND s2_signals.sro = '1'
		  
	      ELSE s1_signals.op1;

	next_stage <= '0' WHEN s1_signals.cycadv = '0' 
	         ELSE '1';

END ARCHITECTURE behav;
