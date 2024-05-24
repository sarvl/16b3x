/*
	DUs in file
		computer

	this computer is {not pipelined; superscalar; out of order} 
	implementation of isa specified in intruction_set.txt

	note that there are commented out lines related to LSQ
	this is because i need to think through how to exactly implement it 
	currently the bad approach of waiting till the first instruction to mmit is implemented

	RAS probably should be fixed, in that misprediction causes serious desync
	i dont think it works at all tbh
	more checking required
	not now

	the entire forwarding check is just mess
*/

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_control.ALL;
USE std.env.finish;

ENTITY computer IS 
END ENTITY computer;

ARCHITECTURE behav OF computer IS

	TYPE t_register IS RECORD
		i0 : std_ulogic_vector(15 DOWNTO 0);
		o0 : std_ulogic_vector(15 DOWNTO 0);
		we : std_ulogic;
	END RECORD t_register;

	TYPE t_buf_entry IS RECORD
		valid    : std_logic;
		complete : std_logic;

		--to verify correctness, not needed for actual simulation
		instr    : std_logic_vector(15 DOWNTO 0);

		controls : t_controls; 

		value    : std_logic_vector(15 DOWNTO 0);
		
		dest     : std_logic_vector(2 DOWNTO 0);

		src0_p   : std_logic;
		src0     : std_logic_vector(15 DOWNTO 0);

		src1_p   : std_logic;
		src1     : std_logic_vector(15 DOWNTO 0);

		alu_op   : std_logic_vector( 2 DOWNTO 0);

		cf       : std_logic;
		pr_tkn   : std_logic;

		addr     : std_logic_vector(15 DOWNTO 0);
	END RECORD t_buf_entry;

	TYPE t_buf IS ARRAY(7 DOWNTO 0) OF t_buf_entry; 

	CONSTANT t_buf_entry_empty : t_buf_entry := 
	    (valid | complete | src0_p | src1_p | pr_tkn | cf => '0',
	     dest  | alu_op  => "000",
	     controls => (cycadv => '1', OTHERS => '0'),
	     value | src0 | src1 | instr | addr => x"0000");


--	TYPE t_instruction IS RECORD 
--		 ctrl       : t_controls;
--
--		 rdi        : std_ulogic_vector(15 DOWNTO 0);
--		 bfe        : std_ulogic_vector( 2 DOWNTO 0);
--		 op0        : std_ulogic_vector(15 DOWNTO 0);
--		 op1        : std_ulogic_vector(15 DOWNTO 0);
--	END RECORD t_instruction;

	TYPE t_rat_entry IS RECORD
		in_rf       : std_ulogic;
		rob_entry   : std_ulogic_vector(2 DOWNTO 0);
	END RECORD t_rat_entry;

	CONSTANT t_rat_entry_def : t_rat_entry := (in_rf     => '1',
	                                           rob_entry => "000");
	 
	TYPE t_rat IS ARRAY(7 DOWNTO 0) OF t_rat_entry;


	TYPE t_bhb_entry IS RECORD
		bc : std_ulogic_vector(1 DOWNTO 0); 
	END RECORD t_bhb_entry;

	--can start with anything for correctness
	--11 is better since most branches are taken
	CONSTANT t_bhb_entry_empty : t_bhb_entry := (bc => "11");

	TYPE t_bhb IS ARRAY(15 DOWNTO 0) OF t_bhb_entry;

	TYPE t_ras_entry IS RECORD 
		addr : std_ulogic_vector(15 DOWNTO 0);
	END RECORD t_ras_entry;
	TYPE t_ras IS ARRAY( 7 DOWNTO 0) OF t_ras_entry; 
	
	CONSTANT t_ras_entry_empty : t_ras_entry := (addr => x"0000");

--	TYPE t_lsq_entry IS RECORD
--		valid    : std_ulogic;
--		complete : std_ulogic;
--		write    : std_ulogic;
--		addrp    : std_ulogic;
--		addr     : std_ulogic_vector(15 DOWNTO 0);
--		valuep   : std_ulogic;
--		value    : std_ulogic_vector(15 DOWNTO 0);
--		robentry : std_Ulogic_vector( 2 DOWNTO 0);
--	END RECORD t_lsq_entry;
--
--	CONSTANT t_lsq_entry_empty : t_lsq_entry := (
--		valid | complete | write => '0',
--		addrp | valuep => '0',
--		addr  | value  => x"0000",
--		robentry => "000");
--	
--	TYPE t_lsq IS ARRAY(7 DOWNTO 0) OF t_lsq_entry;

	COMPONENT alu IS 
		PORT(
			i0 : IN  std_ulogic_vector(15 DOWNTO 0);
			i1 : IN  std_ulogic_vector(15 DOWNTO 0);

			o0 : OUT std_ulogic_vector(15 DOWNTO 0);

			op : IN  std_ulogic_vector( 2 DOWNTO 0));
	END COMPONENT alu;

	COMPONENT adder_03bit IS 
		PORT (
			i0: IN  std_ulogic_vector( 2 DOWNTO 0);
			i1: IN  std_ulogic_vector( 2 DOWNTO 0);
			ic: IN  std_ulogic;
			
			o0: OUT std_ulogic_vector( 2 DOWNTO 0);
			oc: OUT std_ulogic);
	END COMPONENT adder_03bit; 

	COMPONENT adder_16bit IS 
		PORT (
			i0: IN  std_ulogic_vector(15 DOWNTO 0);
			i1: IN  std_ulogic_vector(15 DOWNTO 0);
			ic: IN  std_ulogic;
			
			o0: OUT std_ulogic_vector(15 DOWNTO 0);
			oc: OUT std_ulogic);
	END COMPONENT adder_16bit; 

	COMPONENT multiplier IS 
		PORT (
			i0: IN  std_ulogic_vector(15 DOWNTO 0);
			i1: IN  std_ulogic_vector(15 DOWNTO 0);
			
			o0: OUT std_ulogic_vector(15 DOWNTO 0));
	END COMPONENT multiplier; 

	COMPONENT reg_file IS 
		PORT(
			i0f : IN  std_ulogic_vector(15 DOWNTO 0);
			i0s : IN  std_ulogic_vector(15 DOWNTO 0);
			
			o0f : OUT std_ulogic_vector(15 DOWNTO 0);
			o1f : OUT std_ulogic_vector(15 DOWNTO 0);
			
			o0s : OUT std_ulogic_vector(15 DOWNTO 0);
			o1s : OUT std_ulogic_vector(15 DOWNTO 0);

			
			rdf : IN  std_ulogic_vector(2 DOWNTO 0);
			r0f : IN  std_ulogic_vector(2 DOWNTO 0);
			r1f : IN  std_ulogic_vector(2 DOWNTO 0);
			
			rds : IN  std_ulogic_vector(2 DOWNTO 0);
			r0s : IN  std_ulogic_vector(2 DOWNTO 0);
			r1s : IN  std_ulogic_vector(2 DOWNTO 0);

			wef : IN  std_ulogic;
			wes : IN  std_ulogic;

			clk : IN  std_ulogic);
	END COMPONENT reg_file;

	COMPONENT reg_16bit IS 
		PORT(
			i0  : IN  std_ulogic_vector(15 DOWNTO 0);
			o0  : OUT std_ulogic_vector(15 DOWNTO 0);
			
			we  : IN  std_ulogic;
			clk : IN  std_ulogic);
	END COMPONENT reg_16bit;

	COMPONENT reg_flags IS 
		PORT(
			i0  : IN  std_ulogic_vector(15 DOWNTO 0);
			o0  : OUT std_ulogic_vector(15 DOWNTO 0) := x"0001";
			
			we  : IN  std_ulogic;
			clk : IN  std_ulogic);
	END COMPONENT reg_flags;
	
	COMPONENT ram IS
		PORT(
			a0  : IN  std_ulogic_vector(15 DOWNTO 0);
			i0s : IN  std_ulogic_vector(15 DOWNTO 0);
			o0s : OUT std_ulogic_vector(15 DOWNTO 0);
			o0d : OUT std_ulogic_vector(31 DOWNTO 0);

			we  : IN  std_ulogic;
			rdy : OUT std_ulogic := '0';
			hlt : IN  std_ulogic := '0';
			clk : IN  std_ulogic);
	END COMPONENT ram;

	COMPONENT control IS 
		PORT(
			instr         : IN  std_ulogic_vector(15 DOWNTO 0);
			clk           : IN  std_ulogic := '0';
			can_skip_wait : IN  std_ulogic := '0'; 
	
			alu_op        : OUT std_ulogic_vector( 2 DOWNTO 0);
			controls      : OUT t_controls);
	END COMPONENT control;


	COMPONENT bc_2bit IS 
		PORT(
			i0 : IN  std_ulogic_vector(1 DOWNTO 0);
			ic : IN  std_ulogic; 
			o0 : OUT std_ulogic_vector(1 DOWNTO 0));
	END COMPONENT bc_2bit;


	CONSTANT clk_period : time       :=  1 NS;
	SIGNAL   clk        : std_ulogic := '0';

	SIGNAL  ram_adr     : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  ram_in      : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  ram_out     : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  dat_adr     : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  mem_rdy     : std_ulogic := '0';
	SIGNAL  ram_we      : std_ulogic := '0';

	SIGNAL  mul0_res     : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  mul1_res     : std_ulogic_vector(15 DOWNTO 0);

	SIGNAL  ramdb_out   : std_ulogic_vector(31 DOWNTO 0) := x"00000000";
	SIGNAL  instr_out   : std_ulogic_vector(31 DOWNTO 0) := x"00000000";

	SIGNAL 	r_ip : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_sp : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_lr : t_register := (x"0000", x"0000", '0');
--	SIGNAL 	r_ui : t_register := (x"0000", x"0000", '1'); forwarding
	SIGNAL 	r_fl : t_register := (x"0000", x"0000", '0');


	SIGNAL 	spp2  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	sps2  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	ipp2  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	ipp1  : std_ulogic_vector(15 DOWNTO 0);

	SIGNAL 	flcmp : std_ulogic_vector( 2 DOWNTO 0);


--	SIGNAL  we_s       : std_ulogic := '0';
--	SIGNAL  we_f       : std_ulogic := '0';

--	SIGNAL  can_skip_wait : std_ulogic := '0';

	--effectively used to handle cycadv from control, because this time control cant help
	SIGNAL  cycadv        : std_ulogic := '1';

	SIGNAL  ROB  : t_buf := (
		OTHERS => t_buf_entry_empty 
	);
	SIGNAL  RAT  : t_rat := (
		OTHERS => t_rat_entry_def
	);
	SIGNAL  BHB  : t_bhb := (
		OTHERS => t_bhb_entry_empty
	);
	SIGNAL  RAS  : t_ras := (
		OTHERS => t_ras_entry_empty
	);
--	SIGNAL  LSQ  : t_lsq := (
--		OTHERS => t_lsq_entry_empty
--	);
--	--que to lsq 
--	SIGNAL  LSQQ : t_lsq := (
--		OTHERS => t_lsq_entry_empty
--	);


	SIGNAL  RSPp0 : std_ulogic_vector(2 DOWNTO 0) := "000"; 
	SIGNAL  RSPp1 : std_ulogic_vector(2 DOWNTO 0) := "000"; 
	SIGNAL  RSPp2 : std_ulogic_vector(2 DOWNTO 0) := "000"; 
	SIGNAL  RSPp3 : std_ulogic_vector(2 DOWNTO 0) := "000"; 
	SIGNAL  RSPp4 : std_ulogic_vector(2 DOWNTO 0) := "000"; 
	SIGNAL  RSPp5 : std_ulogic_vector(2 DOWNTO 0) := "000"; 
	SIGNAL  RSPp6 : std_ulogic_vector(2 DOWNTO 0) := "000"; 
	SIGNAL  RSPp7 : std_ulogic_vector(2 DOWNTO 0) := "000"; 

	SIGNAL  REPp0 : std_ulogic_vector(2 DOWNTO 0) := "000";
	SIGNAL  REPp1 : std_ulogic_vector(2 DOWNTO 0) := "001";
	SIGNAL  REPp2 : std_ulogic_vector(2 DOWNTO 0) := "010";
	SIGNAL  REPp7 : std_ulogic_vector(2 DOWNTO 0) := "111";

	SIGNAL  LQSp0 : std_ulogic_vector(2 DOWNTO 0) := "000";
	SIGNAL  LQSp1 : std_ulogic_vector(2 DOWNTO 0) := "001";
	SIGNAL  LQEp0 : std_ulogic_vector(2 DOWNTO 0) := "000";
	SIGNAL  LQEp1 : std_ulogic_vector(2 DOWNTO 0) := "001";
	SIGNAL  LQQSp0 : std_ulogic_vector(2 DOWNTO 0) := "000";
	SIGNAL  LQQSp1 : std_ulogic_vector(2 DOWNTO 0) := "001";
	SIGNAL  LQQEp0 : std_ulogic_vector(2 DOWNTO 0) := "000";
	SIGNAL  LQQEp1 : std_ulogic_vector(2 DOWNTO 0) := "001";
	SIGNAL  LQQEp2 : std_ulogic_vector(2 DOWNTO 0) := "010";

	SIGNAL  addr0_e : integer RANGE 7 DOWNTO 0 := 0;
	SIGNAL  addr1_e : integer RANGE 7 DOWNTO 0 := 1;  
	SIGNAL  addr0_s : integer RANGE 7 DOWNTO 0 := 0;
	SIGNAL  addr1_s : integer RANGE 7 DOWNTO 0 := 1;  
	
	SIGNAL  rat00_e : integer RANGE 7 DOWNTO 0 := 0;
	SIGNAL  rat01_e : integer RANGE 7 DOWNTO 0 := 1;
	SIGNAL  rat10_e : integer RANGE 7 DOWNTO 0 := 0;  
	SIGNAL  rat11_e : integer RANGE 7 DOWNTO 0 := 1;  

	SIGNAL  RSEp0  : std_ulogic_vector(2 DOWNTO 0) := "000";
	SIGNAL  RSEp1  : std_ulogic_vector(2 DOWNTO 0) := "001";
	SIGNAL  RSEp2  : std_ulogic_vector(2 DOWNTO 0) := "010";
	SIGNAL  RSEp6  : std_ulogic_vector(2 DOWNTO 0) := "110";
	SIGNAL  RSEp7  : std_ulogic_vector(2 DOWNTO 0) := "111";

	SIGNAL  instr0_controls : t_controls;
	SIGNAL  instr0_aluop    : std_ulogic_vector(2 DOWNTO 0);
	SIGNAL  instr0_r0       : std_ulogic_vector(2 DOWNTO 0);
	SIGNAL  instr0_r1       : std_ulogic_vector(2 DOWNTO 0);
	SIGNAL  instr0_imm8     : std_ulogic_vector(7 DOWNTO 0);
	SIGNAL  instr0_r0v      : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  instr0_r1v      : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  instr0_foi      : std_ulogic;
	SIGNAL  instr0_pr_tkn   : std_ulogic;
	SIGNAL  instr0_cf       : std_ulogic;

	SIGNAL  instr1_controls : t_controls;
	SIGNAL  instr1_aluop    : std_ulogic_vector(2 DOWNTO 0);
	SIGNAL  instr1_r0       : std_ulogic_vector(2 DOWNTO 0);
	SIGNAL  instr1_r1       : std_ulogic_vector(2 DOWNTO 0);
	SIGNAL  instr1_imm8     : std_ulogic_vector(7 DOWNTO 0);
	SIGNAL  instr1_r0v      : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  instr1_r1v      : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  instr1_foi      : std_ulogic;
	SIGNAL  instr1_pr_tkn   : std_ulogic;
	SIGNAL  instr1_cf       : std_ulogic;

	SIGNAL  can_assign_rob  : std_ulogic := '1';
	SIGNAL  can_fetch       : std_ulogic := '1';
	SIGNAL  can_retire0     : std_ulogic := '0';
	SIGNAL  can_retire1     : std_ulogic := '0';
	SIGNAL  use_memory      : std_ulogic := '0';

	SIGNAL  i0_val          : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  i0_rd           : std_ulogic_vector( 2 DOWNTO 0) := "000";
	SIGNAL  i0_we           : std_ulogic := '0';
	SIGNAL  i1_val          : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  i1_rd           : std_ulogic_vector( 2 DOWNTO 0) := "000";
	SIGNAL  i1_we           : std_ulogic := '0';


	SIGNAL  alu0_op0        : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  alu0_op1        : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  alu0_res        : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  alu0_opc        : std_ulogic_vector( 2 DOWNTO 0) :=   "000";
	SIGNAL  alu1_op0        : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  alu1_op1        : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  alu1_res        : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  alu1_opc        : std_ulogic_vector( 2 DOWNTO 0) :=   "000";

	SIGNAL  exe_entry0      : std_ulogic_vector( 2 DOWNTO 0) := "000";
	SIGNAL  exe_entry0p     : std_ulogic                     := '0';
	SIGNAL  exe_entry1      : std_ulogic_vector( 2 DOWNTO 0) := "001";
	SIGNAL  exe_entry1p     : std_ulogic                     := '0';

	SIGNAL  flush           : std_ulogic := '0';
	SIGNAL  misprediction   : std_ulogic := '0';
	SIGNAL  correct_addr    : std_ulogic_vector(15 DOWNTO 0) := x"0000";


	SIGNAL  bc_adi          : std_ulogic_vector( 1 DOWNTO 0) := "00";
	SIGNAL  bc_dir          : std_ulogic                     :=  '0';
	SIGNAL  bc_adr          : std_ulogic_vector( 1 DOWNTO 0) := "00";

	SIGNAL  hlt             : std_ulogic;

	SIGNAL  misaligned_br   : std_ulogic := '0';

BEGIN 
	PROCESS IS 
	BEGIN
		clk <= '0' ;             WAIT FOR clk_period / 2;
		
		--whenever hlt = 0 there is no need to continue the simulation
		--how to handle when second instruction has hlt??
		IF hlt THEN
			finish;
		END IF;

		clk <= '1'; WAIT FOR clk_period / 2;

		--so that it looks nicer on the gtkwave
		clk <= '0';
		IF mem_rdy /= '1' THEN
			WAIT UNTIL mem_rdy = '1';
		END IF;
	END PROCESS;

	rgf0: reg_file PORT MAP(i0f => i0_val,
	                        i0s => i1_val,
	                        o0f => instr0_r0v,
	                        o1f => instr0_r1v, 
	                        o0s => instr1_r0v,
	                        o1s => instr1_r1v,
	                        rdf => i0_rd,
	                        r0f => instr0_r0,
	                        r1f => instr0_r1,
	                        rds => i1_rd,
	                        r0s => instr1_r0,
	                        r1s => instr1_r1,
	                        wef => i0_we,
	                        wes => i1_we, 
	                        clk => clk);

	alu0: alu PORT MAP(i0 => alu0_op0,
	                   i1 => alu0_op1,
	                   o0 => alu0_res,
	                   op => alu0_opc);
	alu1: alu PORT MAP(i0 => alu1_op0,
	                   i1 => alu1_op1,
	                   o0 => alu1_res,
	                   op => alu1_opc);

	ram0: ram PORT MAP(a0  => ram_adr,
	                   i0s => ram_in,
	                   o0s => ram_out,
	                   o0d => ramdb_out,
	                   we  => ram_we,
					   rdy => mem_rdy,
	                   hlt => hlt, 
	                   clk => clk);


	mul0: multiplier PORT MAP(i0 => alu0_op0,
	                          i1 => alu0_op1,
	                          o0 => mul0_res);
	mul1: multiplier PORT MAP(i0 => alu1_op0,
	                          i1 => alu1_op1,
	                          o0 => mul1_res);

	
	ctr0: control PORT MAP(instr         => instr_out(31 DOWNTO 16),
	                       controls      => instr0_controls,
	                       can_skip_wait => '1', 
	                       alu_op        => instr0_aluop,
	                       clk           => clk);
	ctr1: control PORT MAP(instr         => instr_out(15 DOWNTO  0),
	                       controls      => instr1_controls,
	                       can_skip_wait => '1',
	                       alu_op        => instr1_aluop,
	                       clk           => clk);
						   

	reg_ip: reg_16bit PORT MAP(i0  => r_ip.i0(15 DOWNTO 1) & '0',
	                           o0  => r_ip.o0,
	                           we  => r_ip.we,
	                           clk => clk);
	reg_lr: reg_16bit PORT MAP(i0  => r_lr.i0,
	                           o0  => r_lr.o0,
	                           we  => r_lr.we,
	                           clk => clk);
	reg_sp: reg_16bit PORT MAP(i0  => r_sp.i0,
	                           o0  => r_sp.o0,
	                           we  => r_sp.we,
	                           clk => clk);
--	reg_ui: reg_16bit PORT MAP(i0  => r_ui.i0,
--	                           o0  => r_ui.o0,
--	                           we  => r_ui.we,
--	                           clk => clk);
	reg_fl: reg_flags PORT MAP(i0  => r_fl.i0,
	                           o0  => r_fl.o0,
	                           we  => r_fl.we,
	                           clk => clk);

	spadd: adder_16bit PORT MAP(i0 => r_sp.o0,
	                            i1 => x"0002",
	                            ic => '0',
	                            o0 => spp2,
	                            oc => OPEN);
	spsub: adder_16bit PORT MAP(i0 => r_sp.o0,
	                            i1 => x"FFFE",
	                            ic => '0',
	                            o0 => sps2,
	                            oc => OPEN);
	ipad1: adder_16bit PORT MAP(i0 => r_ip.o0,
	                            i1 => x"0001",
	                            ic => '0',
	                            o0 => ipp1,
	                            oc => OPEN);
	ipad2: adder_16bit PORT MAP(i0 => r_ip.o0,
	                            i1 => x"0002",
	                            ic => '0',
	                            o0 => ipp2,
	                            oc => OPEN);

	bcchg: bc_2bit     PORT MAP(i0 => bc_adi,
	                            ic => bc_dir,
	                            o0 => bc_adr);


	--                           i0     i1     ic   o0     oc 
	rspa1: adder_03bit  PORT MAP(RSPp0, "001", '0', RSPp1, OPEN);
	rspa2: adder_03bit  PORT MAP(RSPp0, "010", '0', RSPp2, OPEN);
	rspa3: adder_03bit  PORT MAP(RSPp0, "011", '0', RSPp3, OPEN);
	rspa4: adder_03bit  PORT MAP(RSPp0, "100", '0', RSPp4, OPEN);
	rspa5: adder_03bit  PORT MAP(RSPp0, "101", '0', RSPp5, OPEN);
	rspa6: adder_03bit  PORT MAP(RSPp0, "110", '0', RSPp6, OPEN);
	rspa7: adder_03bit  PORT MAP(RSPp0, "111", '0', RSPp7, OPEN);

	repa1: adder_03bit  PORT MAP(REPp0, "001", '0', REPp1, OPEN);
	repa2: adder_03bit  PORT MAP(REPp0, "010", '0', REPp2, OPEN);
	repa7: adder_03bit  PORT MAP(REPp0, "111", '0', REPp7, OPEN);

	lqsa1: adder_03bit  PORT MAP(LQSp0, "001", '0', LQSp1, OPEN);
	lqea1: adder_03bit  PORT MAP(LQEp0, "001", '0', LQEp1, OPEN);
	lqqsa1: adder_03bit PORT MAP(LQQSp0,"001", '0', LQQSp1,OPEN);
	lqqea1: adder_03bit PORT MAP(LQQEp0,"001", '0', LQQEp1,OPEN);
	lqqea2: adder_03bit PORT MAP(LQQEp0,"010", '0', LQQEp2,OPEN);

	rsepa1: adder_03bit PORT MAP(RSEp0, "001", '0', RSEp1, OPEN);
	rsepa2: adder_03bit PORT MAP(RSEp0, "010", '0', RSEp2, OPEN);
	rsepa6: adder_03bit PORT MAP(RSEp0, "110", '0', RSEp6, OPEN);
	rsepa7: adder_03bit PORT MAP(RSEp0, "111", '0', RSEp7, OPEN);
	 
	
	
--	we_f <= '0' WHEN (eu_0.ctrl.controls.srm = '1' OR eu_0.ctrl.controls.wrm = '1') AND cycadv = '1' AND b3_src /= df
--	   ELSE eu_0.ctrl.controls.wrr;
--	we_s <= '0' WHEN (eu_0.ctrl.controls.srm = '1' OR eu_0.ctrl.controls.wrm = '1') AND cycadv = '1' AND b3_src /= df
--	   ELSE eu_1.ctrl.controls.wrr;
--	can_skip_wait <= '1';

	--slighdly delayed to use correct values, instead can use the logic that is used to set b3_src
--	cycadv <= '1' WHEN falling_edge(clk'delayed(1 PS)) AND cycadv = '0'
--	     ELSE '0' WHEN falling_edge(clk'delayed(1 PS)) AND eu_0.ctrl.controls.cycadv = '0' AND b3_src /= df
--	     ELSE UNAFFECTED;
	cycadv <= '1';

	--memory stuff
	ram_adr <= r_ip.o0(14 DOWNTO 0) & "0" WHEN can_assign_rob 
	      ELSE dat_adr;
	
	ram_in <= ROB(addr0_s).src0;

	dat_adr <= sps2    WHEN ROB(addr0_s).controls.psh = '1'
	      ELSE r_sp.o0 WHEN ROB(addr0_s).controls.pop = '1'
	      ELSE ROB(addr0_s).src1;
--	ram_we  <= '1' WHEN eu_0.ctrl.controls.wrm = '1' AND (cycadv = '0' OR b3_src = df)
--	      ELSE '0';
	ram_we  <= can_retire0 AND ROB(addr0_s).controls.wrm;

	hlt <= '1' WHEN ROB(addr0_s).controls.hlt = '1' AND flcmp /= "000" 
	  ELSE '0';

	instr_out   <= x"0000" & ramdb_out(15 DOWNTO 0) WHEN misaligned_br = '1' 
	          ELSE ramdb_out;

	instr0_r0   <= instr_out(26 DOWNTO 24);
	instr0_r1   <= instr_out(23 DOWNTO 21);
	instr0_imm8 <= instr_out(23 DOWNTO 16);
	instr1_r0   <= instr_out(10 DOWNTO  8);
	instr1_r1   <= instr_out( 7 DOWNTO  5);
	instr1_imm8 <= instr_out( 7 DOWNTO  0);

	--first operand ignored when operand, memory or external
	instr0_foi  <= instr0_controls.sro 
	            OR instr0_controls.srm
	            OR instr0_controls.sre;
	instr1_foi  <= instr1_controls.sro 
	            OR instr1_controls.srm
	            OR instr1_controls.sre;

	--assume not taken for indirect branch, makes hw easier, perf bad
	instr0_pr_tkn <= '0' WHEN NOT instr0_controls.iim
	            ELSE bhb(to_integer(unsigned(ipp1(3 DOWNTO 0)))).bc(1) 
	            WHEN instr0_controls.jmp 
	              OR instr0_controls.cal
	              OR instr0_controls.ret
	            ELSE '0';
	instr0_cf     <= instr0_controls.jmp 
	              OR instr0_controls.cal
	              OR instr0_controls.ret
	              OR instr0_controls.hlt;

	instr1_pr_tkn <= '0' WHEN NOT instr1_controls.iim
	            ELSE bhb(to_integer(unsigned(ipp2(3 DOWNTO 0)))).bc(1) 
	            WHEN instr1_controls.jmp 
	              OR instr1_controls.cal
	              OR instr1_controls.ret
	            ELSE '0';
	instr1_cf     <= instr1_controls.jmp 
	              OR instr1_controls.cal
	              OR instr1_controls.ret
	              OR instr1_controls.hlt;


	--when either retired writes/reads to memory, dont fetch
	use_memory    <= can_retire0 AND (ROB(addr0_s).controls.wrm OR ROB(addr0_s).controls.srm);
	can_assign_rob <= '0' WHEN use_memory 
	             ELSE '1' WHEN REPp2 /= RSPp0 AND REPp2 /= RSPp1 
	             ELSE '0'; 
	can_retire0    <= ROB(addr0_s).valid AND (ROB(addr0_s).complete OR ROB(addr0_s).controls.wre OR ROB(addr0_s).controls.sre OR ROB(addr0_s).controls.srm);
	--to simplify, try not to retire when second instruction is control flow
	--it causes much more care when dealing with flush and it appears to cause no major slowdown
	--however, try to fix it 
	can_retire1    <= ROB(addr1_s).valid 
	              AND ROB(addr1_s).complete 
	              AND can_retire0 
	              AND NOT ROB(addr0_s).cf
	              AND NOT ROB(addr1_s).cf
	              AND NOT (ROB(addr1_s).controls.wrm OR ROB(addr1_s).controls.srm)
	              AND NOT (ROB(addr1_s).controls.wre OR ROB(addr1_s).controls.sre);


	exe_entry0  <= RSPp0 WHEN ROB(to_integer(unsigned(RSPp0))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp0))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp0))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp0))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp0))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp0))).controls.mul = '1')
	          ELSE RSPp1 WHEN ROB(to_integer(unsigned(RSPp1))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp1))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp1))).controls.mul = '1')
	          ELSE RSPp2 WHEN ROB(to_integer(unsigned(RSPp2))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp2))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp2))).controls.mul = '1')
	          ELSE RSPp3 WHEN ROB(to_integer(unsigned(RSPp3))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp3))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp3))).controls.mul = '1')
	          ELSE RSPp4 WHEN ROB(to_integer(unsigned(RSPp4))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp4))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp4))).controls.mul = '1')
	          ELSE RSPp5 WHEN ROB(to_integer(unsigned(RSPp5))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp5))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp5))).controls.mul = '1')
	          ELSE RSPp6 WHEN ROB(to_integer(unsigned(RSPp6))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp6))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp6))).controls.mul = '1')
	          ELSE RSPp7 WHEN ROB(to_integer(unsigned(RSPp7))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp7))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp7))).controls.mul = '1')
	          ELSE UNAFFECTED;
	exe_entry0p <= '1'   WHEN ROB(to_integer(unsigned(RSPp0))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp0))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp0))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp0))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp0))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp0))).controls.mul = '1')
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp1))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp1))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp1))).controls.mul = '1')
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp2))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp2))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp2))).controls.mul = '1')
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp3))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp3))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp3))).controls.mul = '1')
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp4))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp4))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp4))).controls.mul = '1')
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp5))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp5))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp5))).controls.mul = '1')
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp6))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp6))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp6))).controls.mul = '1')
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp7))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp7))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp7))).controls.mul = '1')
	          ELSE '0'; 

	exe_entry1  <= RSPp1 WHEN ROB(to_integer(unsigned(RSPp1))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp1))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp1))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp1                            
	          ELSE RSPp2 WHEN ROB(to_integer(unsigned(RSPp2))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp2))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp2))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp2                            
	          ELSE RSPp3 WHEN ROB(to_integer(unsigned(RSPp3))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp3))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp3))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp3                            
	          ELSE RSPp4 WHEN ROB(to_integer(unsigned(RSPp4))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp4))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp4))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp4                            
	          ELSE RSPp5 WHEN ROB(to_integer(unsigned(RSPp5))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp5))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp5))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp5                            
	          ELSE RSPp6 WHEN ROB(to_integer(unsigned(RSPp6))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp6))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp6))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp6                            
	          ELSE RSPp7 WHEN ROB(to_integer(unsigned(RSPp7))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp7))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp7))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp7                            
	          ELSE UNAFFECTED;
	exe_entry1p <= '1'   WHEN ROB(to_integer(unsigned(RSPp1))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp1))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp1))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp1))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp1                            
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp2))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp2))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp2))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp2))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp2                            
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp3))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp3))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp3))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp3))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp3                            
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp4))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp4))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp4))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp4))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp4                            
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp5))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp5))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp5))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp5))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp5                            
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp6))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp6))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp6))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp6))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp6                            
	          ELSE '1'   WHEN ROB(to_integer(unsigned(RSPp7))).valid        = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).src0_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).src1_p       = '1'
	                      AND ROB(to_integer(unsigned(RSPp7))).complete     = '0'
	                      AND(ROB(to_integer(unsigned(RSPp7))).controls.srr = '1'
	                       OR ROB(to_integer(unsigned(RSPp7))).controls.mul = '1')
	                      AND exe_entry0 /= RSPp7                            
	          ELSE '0'; 

	alu0_op0 <= ROB(to_integer(unsigned(exe_entry0))).src0;
	alu0_op1 <= ROB(to_integer(unsigned(exe_entry0))).src1;
	alu0_opc <= ROB(to_integer(unsigned(exe_entry0))).alu_op;

	alu1_op0 <= ROB(to_integer(unsigned(exe_entry1))).src0;
	alu1_op1 <= ROB(to_integer(unsigned(exe_entry1))).src1;
	alu1_opc <= ROB(to_integer(unsigned(exe_entry1))).alu_op;

	addr0_e <= to_integer(unsigned(REPp0));
	addr1_e <= to_integer(unsigned(REPp1));
	addr0_s <= to_integer(unsigned(RSPp0));
	addr1_s <= to_integer(unsigned(RSPp1));
	
	rat00_e  <= to_integer(unsigned(instr0_r0));
	rat01_e  <= to_integer(unsigned(instr0_r1));
	rat10_e  <= to_integer(unsigned(instr1_r0));
	rat11_e  <= to_integer(unsigned(instr1_r1));


	--for simplicity
	misprediction <= '1' WHEN flcmp /= "000" AND ROB(addr0_s).pr_tkn = '1' AND ROB(addr0_s).controls.ret = '1' --AND r_lr.o0 /= ROB(addr0_s).br_dir AND ROB(addr0_s).pr_tkn = '1' AND ROB(addr0_s).controls.ret = '1' 
	            ELSE '1' WHEN flcmp  = "000" AND ROB(addr0_s).pr_tkn = '1' AND ROB(addr0_s).cf = '1'
	            ELSE '1' WHEN flcmp /= "000" AND ROB(addr0_s).pr_tkn = '0' AND ROB(addr0_s).cf = '1'
	            ELSE '0';
	flush <= '0' WHEN flush = '1' AND rising_edge(clk) 
        ELSE misprediction;
	correct_addr <= r_lr.o0 WHEN flcmp /= "000" AND ROB(addr0_s).pr_tkn = '1' AND ROB(addr0_s).controls.ret = '1'
	           ELSE ROB(addr0_s).addr   WHEN flcmp  = "000" AND ROB(addr0_s).pr_tkn = '1' 
	           ELSE ROB(addr0_s).src1   WHEN flcmp /= "000" AND ROB(addr0_s).pr_tkn = '0'
	           ELSE x"BEEF";

	bc_adi <= BHB(to_integer(unsigned(ROB(addr0_s).addr(3 DOWNTO 0)))).bc WHEN ROB(addr0_s).cf = '1';
	bc_dir <= '1' WHEN flcmp /= "000"
	     ELSE '0';
	BHB(to_integer(unsigned(ROB(addr0_s).addr(3 DOWNTO 0)))).bc <= bc_adr WHEN ROB(addr0_s).cf = '1' AND rising_edge(clk);


	PROCESS (clk) IS 
		VARIABLE rob0_src0_p : std_ulogic;
		VARIABLE rob0_src0   : std_ulogic_vector(15 DOWNTO 0);
		VARIABLE rob0_src1_p : std_ulogic;
		VARIABLE rob0_src1   : std_ulogic_vector(15 DOWNTO 0);
		VARIABLE rob1_src0_p : std_ulogic;
		VARIABLE rob1_src0   : std_ulogic_vector(15 DOWNTO 0);
		VARIABLE rob1_src1_p : std_ulogic;
		VARIABLE rob1_src1   : std_ulogic_vector(15 DOWNTO 0);
	BEGIN
		IF rising_edge(clk) AND flush = '1' THEN
			--reset and do not cache fire
/* these are enough for correctness but i want to visually see ENTIRE thing be cleared
			ROB(0).valid <= '0';
			ROB(1).valid <= '0';
			ROB(2).valid <= '0';
			ROB(3).valid <= '0';
			ROB(4).valid <= '0';
			ROB(5).valid <= '0';
			ROB(6).valid <= '0';
			ROB(7).valid <= '0';

			RAT(0).in_rf <= '1';	
			RAT(1).in_rf <= '1';	
			RAT(2).in_rf <= '1';	
			RAT(3).in_rf <= '1';	
			RAT(4).in_rf <= '1';	
			RAT(5).in_rf <= '1';	
			RAT(6).in_rf <= '1';	
			RAT(7).in_rf <= '1';	

--			LSQ(0).valid <= '0';
--			LSQ(1).valid <= '0';
--			LSQ(2).valid <= '0';
--			LSQ(3).valid <= '0';
--			LSQ(4).valid <= '0';
--			LSQ(5).valid <= '0';
--			LSQ(6).valid <= '0';
--			LSQ(7).valid <= '0';
--			
--			LSQQ(0).valid <= '0';
--			LSQQ(1).valid <= '0';
--			LSQQ(2).valid <= '0';
--			LSQQ(3).valid <= '0';
--			LSQQ(4).valid <= '0';
--			LSQQ(5).valid <= '0';
--			LSQQ(6).valid <= '0';
--			LSQQ(7).valid <= '0';
*/
			ROB(0) <= t_buf_entry_empty;
			ROB(1) <= t_buf_entry_empty;
			ROB(2) <= t_buf_entry_empty;
			ROB(3) <= t_buf_entry_empty;
			ROB(4) <= t_buf_entry_empty;
			ROB(5) <= t_buf_entry_empty;
			ROB(6) <= t_buf_entry_empty;
			ROB(7) <= t_buf_entry_empty;

			RAT(0) <= t_rat_entry_def;	
			RAT(1) <= t_rat_entry_def;	
			RAT(2) <= t_rat_entry_def;	
			RAT(3) <= t_rat_entry_def;	
			RAT(4) <= t_rat_entry_def;	
			RAT(5) <= t_rat_entry_def;	
			RAT(6) <= t_rat_entry_def;	
			RAT(7) <= t_rat_entry_def;	

--			LSQ(0) <= t_lsq_entry_empty;
--			LSQ(1) <= t_lsq_entry_empty;
--			LSQ(2) <= t_lsq_entry_empty;
--			LSQ(3) <= t_lsq_entry_empty;
--			LSQ(4) <= t_lsq_entry_empty;
--			LSQ(5) <= t_lsq_entry_empty;
--			LSQ(6) <= t_lsq_entry_empty;
--			LSQ(7) <= t_lsq_entry_empty;
--			
--			LSQQ(0) <= t_lsq_entry_empty;
--			LSQQ(1) <= t_lsq_entry_empty;
--			LSQQ(2) <= t_lsq_entry_empty;
--			LSQQ(3) <= t_lsq_entry_empty;
--			LSQQ(4) <= t_lsq_entry_empty;
--			LSQQ(5) <= t_lsq_entry_empty;
--			LSQQ(6) <= t_lsq_entry_empty;
--			LSQQ(7) <= t_lsq_entry_empty;

			i0_we <= '0';
			i1_we <= '0';
		END IF;

		IF rising_edge(clk) AND flush = '0' THEN
			IF exe_entry0p THEN 
				
				ROB(to_integer(unsigned(exe_entry0))).complete <= '1';
				ROB(to_integer(unsigned(exe_entry0))).value    <= mul0_res WHEN ROB(to_integer(unsigned(exe_entry0))).controls.mul
				                                             ELSE alu0_res;

				FOR i IN 0 TO 7 LOOP 
					IF ROB(i).valid = '1' AND ROB(i).src0_p = '0' AND ROB(i).src0(2 DOWNTO 0) = exe_entry0 THEN
						ROB(i).src0_p <= '1';
						ROB(i).src0   <= mul0_res WHEN ROB(to_integer(unsigned(exe_entry0))).controls.mul 
						            ELSE alu0_res;
					END IF;
					IF ROB(i).valid = '1' AND ROB(i).src1_p = '0' AND ROB(i).src1(2 DOWNTO 0) = exe_entry0 THEN
						ROB(i).src1_p <= '1';
						ROB(i).src1   <= mul0_res WHEN ROB(to_integer(unsigned(exe_entry0))).controls.mul
						            ELSE alu0_res;
					END IF;
				END LOOP;
			END IF;
			IF exe_entry1p THEN 
				ROB(to_integer(unsigned(exe_entry1))).complete <= '1';
				ROB(to_integer(unsigned(exe_entry1))).value    <= mul1_res WHEN ROB(to_integer(unsigned(exe_entry1))).controls.mul
				                                             ELSE alu1_res;

				FOR i IN 0 TO 7 LOOP 
					IF ROB(i).valid = '1' AND ROB(i).src0_p = '0' AND ROB(i).src0(2 DOWNTO 0) = exe_entry1 THEN
						ROB(i).src0_p <= '1';
						ROB(i).src0   <= mul1_res WHEN ROB(to_integer(unsigned(exe_entry1))).controls.mul 
						            ELSE alu1_res;
					END IF;
					IF ROB(i).valid = '1' AND ROB(i).src1_p = '0' AND ROB(i).src1(2 DOWNTO 0) = exe_entry1 THEN
						ROB(i).src1_p <= '1';
						ROB(i).src1   <= mul1_res WHEN ROB(to_integer(unsigned(exe_entry1))).controls.mul
						            ELSE alu1_res;
					END IF;
				END LOOP;
			END IF;
		END IF;


		IF rising_edge(clk) AND flush = '0' THEN 
			IF can_retire0 THEN 
--				IF ROB(addr0_s).controls.hlt THEN 
--					finish;
--				END IF;
				ROB(addr0_s).valid <= '0';

				IF ROB(addr0_s).controls.wrr THEN 
					--prevent write of two different vals to the same reg
					i0_we  <= '0' WHEN can_retire1 = '1'
					               AND ROB(addr0_s).dest = ROB(addr1_s).dest
					               AND ROB(addr1_s).controls.wrr = '1'
					     ELSE '1';
					i0_rd  <= ROB(addr0_s).dest;
					i0_val <= ram_out WHEN ROB(addr0_s).controls.srm = '1' 
					     ELSE ROB(addr0_s).src1 WHEN ROB(addr0_s).controls.sro
					     ELSE r_lr.o0 WHEN ROB(addr0_s).controls.sre = '1'
					     ELSE ROB(addr0_s).value;

					--when RAT entry points to this ROB entry
					RAT(to_integer(unsigned(ROB(addr0_s).dest))).in_rf <= '1'
					    WHEN RAT(to_integer(unsigned(ROB(addr0_s).dest))).rob_entry = RSPp0 
					    ELSE '0';

					--find whether there is a place where to put data
					--test for validitiy not *really* needed
					FOR i IN 0 TO 7 LOOP 
						IF ROB(i).valid = '1' AND ROB(i).src0_p = '0' AND ROB(i).src0(2 DOWNTO 0) = RSPp0 THEN
							ROB(i).src0_p <= '1';
							ROB(i).src0   <= ram_out WHEN ROB(addr0_s).controls.srm = '1' 
					                    ELSE ROB(addr0_s).src1 WHEN ROB(addr0_s).controls.sro
					    	            ELSE r_lr.o0 WHEN ROB(addr0_s).controls.sre = '1'
					                    ELSE ROB(addr0_s).value;

						END IF;
						IF ROB(i).valid = '1' AND ROB(i).src1_p = '0' AND ROB(i).src1(2 DOWNTO 0) = RSPp0 THEN
							ROB(i).src1_p <= '1';
							ROB(i).src1   <= ram_out WHEN ROB(addr0_s).controls.srm = '1' 
					                    ELSE ROB(addr0_s).src1 WHEN ROB(addr0_s).controls.sro
					    	            ELSE r_lr.o0 WHEN ROB(addr0_s).controls.sre = '1'
					                    ELSE ROB(addr0_s).value;
						END IF;
					END LOOP;
				ELSE
					i0_we <= '0';
				END IF;

			ELSE
				i0_we <= '0';
			END IF;

			IF can_retire1 AND NOT flush THEN 
--				IF ROB(addr1_s).controls.hlt THEN 
--					finish;
--				END IF;

				ROB(addr1_s).valid <= '0';
				IF ROB(addr1_s).controls.wrr THEN
					i1_we  <= '1';
					i1_rd  <= ROB(addr1_s).dest;
					i1_val <= ROB(addr1_s).src1 WHEN ROB(addr1_s).controls.sro
					     ELSE ROB(addr1_s).value;

					--when RAT entry points to this ROB entry
					RAT(to_integer(unsigned(ROB(addr1_s).dest))).in_rf <= '1'
					    WHEN RAT(to_integer(unsigned(ROB(addr1_s).dest))).rob_entry = RSPp1 
					    ELSE '0';
					
					FOR i IN 0 TO 7 LOOP 
						IF ROB(i).valid = '1' AND ROB(i).src0_p = '0' AND ROB(i).src0(2 DOWNTO 0) = RSPp1 THEN
							ROB(i).src0_p <= '1';
							ROB(i).src0   <= ROB(addr1_s).src1 WHEN ROB(addr1_s).controls.sro
					                    ELSE ROB(addr1_s).value;

						END IF;
						IF ROB(i).valid = '1' AND ROB(i).src1_p = '0' AND ROB(i).src1(2 DOWNTO 0) = RSPp1 THEN
							ROB(i).src1_p <= '1';
							ROB(i).src1   <= ROB(addr1_s).src1 WHEN ROB(addr1_s).controls.sro
					                    ELSE ROB(addr1_s).value;

						END IF;
					END LOOP;
				ELSE
					i1_we <= '0';
				END IF;
			ELSE
				i1_we <= '0';
			END IF;
		END IF;

		IF rising_edge(clk) AND can_assign_rob = '1' AND flush = '0' THEN

			ROB(addr0_e).valid  <= '1';
			ROB(addr0_e).instr  <= instr_out(31 DOWNTO 16); 
			ROB(addr0_e).dest   <= instr0_r0;
			--if first operand ignore 
			--or first operand in register
			--or first operand in buffer entry pointed to by the register
			rob0_src0_p := '1' WHEN instr0_foi = '1' OR instr0_cf = '1' 
			            OR RAT(rat00_e).in_rf = '1' 
			            OR (ROB(to_integer(unsigned(RAT(rat00_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat00_e).rob_entry))).controls.sro = '0') 
			            OR (ROB(to_integer(unsigned(RAT(rat00_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat00_e).rob_entry))).controls.sro = '1' AND ROB(to_integer(unsigned(RAT(rat00_e).rob_entry))).src1_p = '1')
			            OR (exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr0_r0 AND RAT(to_integer(unsigned(instr0_r0))).rob_entry = exe_entry0)
			            OR (exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr0_r0 AND RAT(to_integer(unsigned(instr0_r0))).rob_entry = exe_entry1)
			          ELSE '0';
			rob0_src0   := (2 DOWNTO 0 => instr0_r0, OTHERS => '0')WHEN instr0_cf = '1'
			          ELSE i0_val                                     WHEN RAT(rat00_e).in_rf = '1' AND i0_rd = instr0_r0 AND i0_we = '1'
			          ELSE i1_val                                     WHEN RAT(rat00_e).in_rf = '1' AND i1_rd = instr0_r0 AND i1_we = '1'
			          ELSE instr0_r0v                                 WHEN RAT(rat00_e).in_rf
			          ELSE ROB(to_integer(unsigned(RAT(rat00_e).rob_entry))).src1  WHEN ROB(to_integer(unsigned(RAT(rat00_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat00_e).rob_entry))).controls.sro = '1'
			          ELSE ROB(to_integer(unsigned(RAT(rat00_e).rob_entry))).value WHEN ROB(to_integer(unsigned(RAT(rat00_e).rob_entry))).complete = '1'
					  --please forgive me for this monster line, very bad
			          ELSE mul0_res WHEN exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr0_r0 AND RAT(to_integer(unsigned(instr0_r0))).rob_entry = exe_entry0 AND ROB(to_integer(unsigned(exe_entry0))).controls.mul = '1'
			          ELSE mul1_res WHEN exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr0_r0 AND RAT(to_integer(unsigned(instr0_r0))).rob_entry = exe_entry1 AND ROB(to_integer(unsigned(exe_entry1))).controls.mul = '1'
			          ELSE alu0_res WHEN exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr0_r0 AND RAT(to_integer(unsigned(instr0_r0))).rob_entry = exe_entry0
			          ELSE alu1_res WHEN exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr0_r0 AND RAT(to_integer(unsigned(instr0_r0))).rob_entry = exe_entry1
			          ELSE (2 DOWNTO 0 => RAT(rat00_e).rob_entry, OTHERS => '0');
			rob0_src1_p := '1' WHEN instr0_controls.iim = '1' 
			            OR RAT(rat01_e).in_rf = '1'
			            OR (ROB(to_integer(unsigned(RAT(rat01_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat01_e).rob_entry))).controls.sro = '0') 
			            OR (ROB(to_integer(unsigned(RAT(rat01_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat01_e).rob_entry))).controls.sro = '1' AND ROB(to_integer(unsigned(RAT(rat01_e).rob_entry))).src1_p = '1')
			            OR (exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr0_r1 AND RAT(to_integer(unsigned(instr0_r1))).rob_entry = exe_entry0)
			            OR (exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr0_r1 AND RAT(to_integer(unsigned(instr0_r1))).rob_entry = exe_entry1)
			          ELSE '0';
			rob0_src1   := (7 DOWNTO 0 => instr0_imm8, 15 DOWNTO 8 => ROB(to_integer(unsigned(REPp7))).value(7 DOWNTO 0)) WHEN instr0_controls.iim = '1' AND ROB(to_integer(unsigned(REPp7))).controls.wre = '1' AND ROB(to_integer(unsigned(REPp7))).dest = "100"
			          ELSE (7 DOWNTO 0 => instr0_imm8, OTHERS => '0') WHEN instr0_controls.iim = '1' 
			          ELSE i0_val                                     WHEN RAT(rat01_e).in_rf = '1' AND i0_rd = instr0_r1 AND i0_we = '1'
			          ELSE i1_val                                     WHEN RAT(rat01_e).in_rf = '1' AND i1_rd = instr0_r1 AND i1_we = '1'
			          ELSE instr0_r1v                                 WHEN RAT(rat01_e).in_rf
			          ELSE ROB(to_integer(unsigned(RAT(rat01_e).rob_entry))).src1  WHEN ROB(to_integer(unsigned(RAT(rat01_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat01_e).rob_entry))).controls.sro = '1'
			          ELSE ROB(to_integer(unsigned(RAT(rat01_e).rob_entry))).value WHEN ROB(to_integer(unsigned(RAT(rat01_e).rob_entry))).complete = '1'
			          ELSE mul0_res WHEN exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr0_r1 AND RAT(to_integer(unsigned(instr0_r1))).rob_entry = exe_entry0 AND ROB(to_integer(unsigned(exe_entry0))).controls.mul = '1'
			          ELSE mul1_res WHEN exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr0_r1 AND RAT(to_integer(unsigned(instr0_r1))).rob_entry = exe_entry1 AND ROB(to_integer(unsigned(exe_entry1))).controls.mul = '1'
			          ELSE alu0_res WHEN exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr0_r1 AND RAT(to_integer(unsigned(instr0_r1))).rob_entry = exe_entry0
			          ELSE alu1_res WHEN exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr0_r1 AND RAT(to_integer(unsigned(instr0_r1))).rob_entry = exe_entry1
			          ELSE (2 DOWNTO 0 => RAT(rat01_e).rob_entry, OTHERS => '0');

			ROB(addr0_e).src0_p <= rob0_src0_p;
			ROB(addr0_e).src0   <= rob0_src0;
			ROB(addr0_e).src1_p <= rob0_src1_p;
			ROB(addr0_e).src1   <= rob0_src1;
			
			--mov R R/imm can be exe here
			--while not always the instruction is complete when source is operand 
			--it will be complete when possibility of retirement, so it works 
			--TEST THAT
			--not sure what happens when 
			--mov R0, R1
			--mov R3, R0
			--may break
			ROB(addr0_e).complete <= instr0_controls.sro
			                      OR instr0_cf
			                      OR instr0_controls.wrm
			                      OR instr0_controls.wre
			--nop
			                      OR NOT (instr0_controls.wrr OR instr0_controls.wrf);
			ROB(addr0_e).value    <= rob0_src1 WHEN instr0_controls.iim 
			                    ELSE instr0_r1v;
			ROB(addr0_e).alu_op   <= instr0_aluop;
			ROB(addr0_e).controls <= instr0_controls;

			ROB(addr0_e).cf       <= instr0_cf;
			ROB(addr0_e).pr_tkn   <= instr0_pr_tkn;
			ROB(addr0_e).addr     <= ipp1;

			IF instr0_controls.wrr = '1' THEN 
				RAT(rat00_e).in_rf     <= '0';
				RAT(rat00_e).rob_entry <= REPp0;
			END IF;
			
--			IF instr0_controls.wrm = '1' THEN 
--				LSQQ(to_integer(unsigned(LQQEp0))).valid    <= '1';
--				LSQQ(to_integer(unsigned(LQQEp0))).complete <= rob0_src1_p AND rob0_src0_p;
--				LSQQ(to_integer(unsigned(LQQEp0))).write    <= '1';
--				LSQQ(to_integer(unsigned(LQQEp0))).addrp    <= rob0_src1_p;
--				LSQQ(to_integer(unsigned(LQQEp0))).addr     <= rob0_src1;
--				LSQQ(to_integer(unsigned(LQQEp0))).valuep   <= rob0_src0_p;
--				LSQQ(to_integer(unsigned(LQQEp0))).value    <= rob0_src0;
--				LSQQ(to_integer(unsigned(LQQEp0))).robentry <= RSPp0;
--			END IF;
--			IF instr0_controls.srm = '1' THEN 
--				LSQQ(to_integer(unsigned(LQQEp0))).valid    <= '1';
--				LSQQ(to_integer(unsigned(LQQEp0))).complete <= '0';
--				LSQQ(to_integer(unsigned(LQQEp0))).write    <= '0';
--				LSQQ(to_integer(unsigned(LQQEp0))).addrp    <= rob0_src1_p;
--				LSQQ(to_integer(unsigned(LQQEp0))).addr     <= rob0_src1;
--				LSQQ(to_integer(unsigned(LQQEp0))).valuep   <= '0';
--				LSQQ(to_integer(unsigned(LQQEp0))).value    <= x"0000";
--				LSQQ(to_integer(unsigned(LQQEp0))).robentry <= RSPp0;
--			END IF;

			RAS(to_integer(unsigned(RSEp0))).addr <= ipp1 WHEN instr0_pr_tkn AND instr0_controls.cal;
		END IF;


		IF rising_edge(clk) AND can_assign_rob = '1' AND instr0_pr_tkn = '0' AND flush = '0' THEN 
			ROB(addr1_e).valid  <= '1';
			ROB(addr1_e).instr  <= instr_out(15 DOWNTO  0);
			ROB(addr1_e).dest   <= instr1_r0;
			--detect write of instr0 to r0 
			rob1_src0_p := '1' WHEN instr1_foi = '1' OR instr1_cf = '1' 
			          ELSE '0' WHEN instr0_r0 = instr1_r0  AND instr0_controls.wrr = '1' 
			          ELSE '1' WHEN RAT(rat10_e).in_rf = '1' 
			            OR (ROB(to_integer(unsigned(RAT(rat10_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat10_e).rob_entry))).controls.sro = '0') 
			            OR (ROB(to_integer(unsigned(RAT(rat10_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat10_e).rob_entry))).controls.sro = '1' AND ROB(to_integer(unsigned(RAT(rat10_e).rob_entry))).src1_p = '1')
			            OR (exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr1_r0 AND RAT(to_integer(unsigned(instr1_r0))).rob_entry = exe_entry0)
			            OR (exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr1_r0 AND RAT(to_integer(unsigned(instr1_r0))).rob_entry = exe_entry1)
			          ELSE '0';
			rob1_src0   := (2 DOWNTO 0 => instr1_r0, OTHERS => '0') WHEN instr1_cf = '1'
			          ELSE (2 DOWNTO 0 => REPp0, OTHERS => '0') WHEN instr0_r0 = instr1_r0 AND instr0_controls.wrr = '1' 
			          ELSE i0_val                                     WHEN RAT(rat10_e).in_rf = '1' AND i0_rd = instr1_r0 AND i0_we = '1'
			          ELSE i1_val                                     WHEN RAT(rat10_e).in_rf = '1' AND i1_rd = instr1_r0 AND i1_we = '1'
			          ELSE instr1_r0v                                 WHEN RAT(rat10_e).in_rf
			          ELSE ROB(to_integer(unsigned(RAT(rat10_e).rob_entry))).src1  WHEN ROB(to_integer(unsigned(RAT(rat10_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat10_e).rob_entry))).controls.sro = '1'
			          ELSE ROB(to_integer(unsigned(RAT(rat10_e).rob_entry))).value WHEN ROB(to_integer(unsigned(RAT(rat10_e).rob_entry))).complete = '1'
			          ELSE mul0_res WHEN exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr1_r0 AND RAT(to_integer(unsigned(instr1_r0))).rob_entry = exe_entry0 AND ROB(to_integer(unsigned(exe_entry0))).controls.mul = '1'
			          ELSE mul1_res WHEN exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr1_r0 AND RAT(to_integer(unsigned(instr1_r0))).rob_entry = exe_entry1 AND ROB(to_integer(unsigned(exe_entry1))).controls.mul = '1'
			          ELSE alu0_res WHEN exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr1_r0 AND RAT(to_integer(unsigned(instr1_r0))).rob_entry = exe_entry0
			          ELSE alu1_res WHEN exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr1_r0 AND RAT(to_integer(unsigned(instr1_r0))).rob_entry = exe_entry1
			          ELSE (2 DOWNTO 0 => RAT(rat10_e).rob_entry, OTHERS => '0');
			rob1_src1_p := '1' WHEN instr1_controls.iim 
			          ELSE '0' WHEN instr0_r0 = instr1_r1 AND instr0_controls.wrr = '1'
			          ELSE '1' WHEN RAT(rat11_e).in_rf = '1' 
			            OR (ROB(to_integer(unsigned(RAT(rat11_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat11_e).rob_entry))).controls.sro = '0') 
			            OR (ROB(to_integer(unsigned(RAT(rat11_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat11_e).rob_entry))).controls.sro = '1' AND ROB(to_integer(unsigned(RAT(rat11_e).rob_entry))).src1_p = '1')
			            OR (exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr1_r1 AND RAT(to_integer(unsigned(instr1_r1))).rob_entry = exe_entry0)
			            OR (exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr1_r1 AND RAT(to_integer(unsigned(instr1_r1))).rob_entry = exe_entry1)
			          ELSE '0';
			rob1_src1   := (7 DOWNTO 0 => instr1_imm8, 15 DOWNTO 8 => instr0_imm8) WHEN instr1_controls.iim = '1' AND instr0_controls.wre = '1' AND instr0_r0 = "100"
			          ELSE (7 DOWNTO 0 => instr1_imm8, OTHERS => '0') WHEN instr1_controls.iim = '1'
			          ELSE (2 DOWNTO 0 => REPp0, OTHERS => '0') WHEN instr0_r0 = instr1_r1 AND instr0_controls.wrr = '1'
			          ELSE i0_val                                     WHEN RAT(rat11_e).in_rf = '1' AND i0_rd = instr1_r1 AND i0_we = '1'
			          ELSE i1_val                                     WHEN RAT(rat11_e).in_rf = '1' AND i1_rd = instr1_r1 AND i1_we = '1'
			          ELSE instr1_r1v                                 WHEN RAT(rat11_e).in_rf
			          ELSE ROB(to_integer(unsigned(RAT(rat11_e).rob_entry))).src1  WHEN ROB(to_integer(unsigned(RAT(rat11_e).rob_entry))).complete = '1' AND ROB(to_integer(unsigned(RAT(rat11_e).rob_entry))).controls.sro = '1'
			          ELSE ROB(to_integer(unsigned(RAT(rat11_e).rob_entry))).value WHEN ROB(to_integer(unsigned(RAT(rat11_e).rob_entry))).complete = '1'
			          ELSE mul0_res WHEN exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr1_r1 AND RAT(to_integer(unsigned(instr1_r1))).rob_entry = exe_entry0 AND ROB(to_integer(unsigned(exe_entry0))).controls.mul = '1'
			          ELSE mul1_res WHEN exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr1_r1 AND RAT(to_integer(unsigned(instr1_r1))).rob_entry = exe_entry1 AND ROB(to_integer(unsigned(exe_entry1))).controls.mul = '1'
			          ELSE alu0_res WHEN exe_entry0p = '1' AND ROB(to_integer(unsigned(exe_entry0))).dest = instr1_r1 AND RAT(to_integer(unsigned(instr1_r1))).rob_entry = exe_entry0
			          ELSE alu1_res WHEN exe_entry1p = '1' AND ROB(to_integer(unsigned(exe_entry1))).dest = instr1_r1 AND RAT(to_integer(unsigned(instr1_r1))).rob_entry = exe_entry1
			          ELSE (2 DOWNTO 0 => RAT(rat11_e).rob_entry, OTHERS => '0');

			ROB(addr1_e).src0_p <= rob1_src0_p;
			ROB(addr1_e).src0   <= rob1_src0;
			ROB(addr1_e).src1_p <= rob1_src1_p;
			ROB(addr1_e).src1   <= rob1_src1;

			--mov R imm can be exe here
			ROB(addr1_e).complete <= instr1_controls.sro
			                      OR instr1_cf 
			                      OR instr1_controls.wrm
			                      OR instr1_controls.wre
			--nop
			                      OR NOT (instr1_controls.wrr OR instr1_controls.wrf);
			ROB(addr1_e).value    <= rob1_src1 WHEN instr1_controls.iim 
			                    ELSE instr1_r1v;
			ROB(addr1_e).alu_op   <= instr1_aluop;
			ROB(addr1_e).controls <= instr1_controls;

			ROB(addr1_e).cf       <= instr1_cf;
			ROB(addr1_e).pr_tkn   <= instr1_pr_tkn; 
			ROB(addr1_e).addr     <= ipp2;

			RAT(rat10_e).in_rf     <= '0'   WHEN instr1_controls.wrr = '1'
			                    ELSE UNAFFECTED;
			RAT(rat10_e).rob_entry <= REPp1 WHEN instr1_controls.wrr = '1'
			                    ELSE UNAFFECTED;
			
--			IF instr1_controls.wrm = '1' AND (instr0_controls.wrm = '1' OR instr0_controls.srm = '1') THEN 
--				LSQQ(to_integer(unsigned(LQQEp1))).valid    <= '1';
--				LSQQ(to_integer(unsigned(LQQEp1))).complete <= rob1_src1_p AND rob1_src0_p;
--				LSQQ(to_integer(unsigned(LQQEp1))).write    <= '1';
--				LSQQ(to_integer(unsigned(LQQEp1))).addrp    <= rob1_src1_p;
--				LSQQ(to_integer(unsigned(LQQEp1))).addr     <= rob1_src1;
--				LSQQ(to_integer(unsigned(LQQEp1))).valuep   <= rob1_src0_p;
--				LSQQ(to_integer(unsigned(LQQEp1))).value    <= rob1_src0;
--				LSQQ(to_integer(unsigned(LQQEp1))).robentry <= RSPp1;
--			ELSIF instr1_controls.wrm = '1' THEN
--				LSQQ(to_integer(unsigned(LQQEp0))).valid    <= '1';
--				LSQQ(to_integer(unsigned(LQQEp0))).complete <= rob1_src1_p AND rob1_src0_p;
--				LSQQ(to_integer(unsigned(LQQEp0))).write    <= '1';
--				LSQQ(to_integer(unsigned(LQQEp0))).addrp    <= rob1_src1_p;
--				LSQQ(to_integer(unsigned(LQQEp0))).addr     <= rob1_src1;
--				LSQQ(to_integer(unsigned(LQQEp0))).valuep   <= rob1_src0_p;
--				LSQQ(to_integer(unsigned(LQQEp0))).value    <= rob1_src0;
--				LSQQ(to_integer(unsigned(LQQEp0))).robentry <= RSPp1;
--			END IF;
--			IF instr1_controls.srm = '1' AND (instr0_controls.wrm = '1' OR instr0_controls.srm = '1') THEN 
--				LSQQ(to_integer(unsigned(LQQEp1))).valid    <= '1';
--				LSQQ(to_integer(unsigned(LQQEp1))).complete <= '0';
--				LSQQ(to_integer(unsigned(LQQEp1))).write    <= '0';
--				LSQQ(to_integer(unsigned(LQQEp1))).addrp    <= rob1_src1_p;
--				LSQQ(to_integer(unsigned(LQQEp1))).addr     <= rob1_src1;
--				LSQQ(to_integer(unsigned(LQQEp1))).valuep   <= '0';
--				LSQQ(to_integer(unsigned(LQQEp1))).value    <= x"0000";
--				LSQQ(to_integer(unsigned(LQQEp1))).robentry <= RSPp1;
--			ELSIF instr1_controls.srm = '1' THEN
--				LSQQ(to_integer(unsigned(LQQEp0))).valid    <= '1';
--				LSQQ(to_integer(unsigned(LQQEp0))).complete <= '0';
--				LSQQ(to_integer(unsigned(LQQEp0))).write    <= '0';
--				LSQQ(to_integer(unsigned(LQQEp0))).addrp    <= rob1_src1_p;
--				LSQQ(to_integer(unsigned(LQQEp0))).addr     <= rob1_src1;
--				LSQQ(to_integer(unsigned(LQQEp0))).valuep   <= '0';
--				LSQQ(to_integer(unsigned(LQQEp0))).value    <= x"0000";
--				LSQQ(to_integer(unsigned(LQQEp0))).robentry <= RSPp1;
--			END IF;


			RAS(to_integer(unsigned(RSEp0))).addr <= ipp2 WHEN NOT (instr0_pr_tkn AND instr0_controls.cal)
			                                               AND instr1_pr_tkn AND instr0_controls.cal;
			RAS(to_integer(unsigned(RSEp1))).addr <= ipp2 WHEN instr0_pr_tkn AND instr0_controls.cal
			                                               AND instr1_pr_tkn AND instr0_controls.cal;
			
		END IF;
	END PROCESS;
	REPp0 <= "000" WHEN rising_edge(clk) AND flush = '1'
	    ELSE REPp1 WHEN rising_edge(clk) AND can_assign_rob = '1' AND instr0_pr_tkn = '1'
	    ELSE REPp2 WHEN rising_edge(clk) AND can_assign_rob = '1' 
	    ELSE UNAFFECTED;
	RSPp0 <= "000" WHEN rising_edge(clk) AND flush = '1'
	    ELSE RSPp2 WHEN rising_edge(clk) AND can_retire1 = '1'
	    ELSE RSPp1 WHEN rising_edge(clk) AND can_retire0 = '1'
	    ELSE UNAFFECTED;
--	LQQEp0 <= "000"  WHEN  rising_edge(clk) AND flush = '1'
--	     ELSE LQQEp2 WHEN  rising_edge(clk)
--	                  AND (instr0_controls.wrm = '1' OR instr0_controls.srm = '1')
--	                  AND (instr1_controls.wrm = '1' OR instr1_controls.srm = '1')
--	     ELSE LQQEp1 WHEN  rising_edge(clk)
--	                  AND (instr0_controls.wrm = '1' OR instr0_controls.srm = '1')
--	     ELSE LQQEp1 WHEN  rising_edge(clk)
--	                  AND (instr1_controls.wrm = '1' OR instr1_controls.srm = '1')
--	     ELSE UNAFFECTED;
	-- dont care about fixing it! just for prediction, not correctness
	RSEp0 <= RSEp2 WHEN rising_edge(clk) AND (instr0_controls.cal = '1' AND instr1_controls.cal = '1')
	    ELSE RSEp0 WHEN rising_edge(clk) AND (instr0_controls.cal = '1' AND instr1_controls.ret = '1')
	    ELSE RSEp0 WHEN rising_edge(clk) AND (instr0_controls.ret = '1' AND instr1_controls.cal = '1')
		ELSE RSEp1 WHEN rising_edge(clk) AND (instr0_controls.cal = '1' XOR instr1_controls.cal = '1')
		ELSE RSEp7 WHEN rising_edge(clk) AND (instr0_controls.ret = '1' XOR instr1_controls.ret = '1')
		ELSE RSEp6 WHEN rising_edge(clk) AND (instr0_controls.ret = '1' AND instr1_controls.ret = '1')
	    ELSE UNAFFECTED;

	can_fetch <= can_assign_rob;


	--input to reg file
--	eu_0.rdi <= eu_0.op1         WHEN eu_0.ctrl.controls.sro = '1'
--	       ELSE alu_out_0        WHEN eu_0.ctrl.controls.srr = '1' 
--	       ELSE ram_out          WHEN eu_0.ctrl.controls.srm = '1' 
--		   ELSE mul_out          WHEN eu_0.ctrl.controls.mul = '1'
--	       ELSE r_ip.o0          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "000"
--	       ELSE r_sp.o0          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "001" 
--	       ELSE r_lr.o0          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "010" 
--	       ELSE r_ui.o0          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "100" 
--	       ELSE r_fl.o0          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "101" 
--	       ELSE x"0001"          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "111" 
--	       ELSE UNAFFECTED;
--	
--	eu_1.rdi <= eu_1.op1         WHEN eu_1.ctrl.controls.sro = '1'
--	       ELSE alu_out_1        WHEN eu_1.ctrl.controls.srr = '1' 
--	       ELSE ram_out          WHEN eu_1.ctrl.controls.srm = '1' 
--		   ELSE mul_out          WHEN eu_1.ctrl.controls.mul = '1'
--	       ELSE r_ip.o0          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "000"
--	       ELSE r_sp.o0          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "001" 
--	       ELSE r_lr.o0          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "010" 
--	       ELSE r_ui.o0          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "100" 
--	       ELSE r_fl.o0          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "101" 
--	       ELSE x"0001"          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "111" 
--	       ELSE UNAFFECTED;

	--input to external register

	r_sp.i0 <= sps2 WHEN ROB(addr0_s).controls.psh
	      ELSE spp2 WHEN ROB(addr0_s).controls.pop
	      ELSE UNAFFECTED;
	r_sp.we <= '1' WHEN (ROB(addr0_s).controls.psh OR ROB(addr0_s).controls.pop) AND can_retire0
	      ELSE '0'; 
--	r_ui.i0 <= x"0000"; 
	--when last bit is 1 then branch is misaligned
	misaligned_br <= correct_addr(0) WHEN rising_edge(clk) AND flush = '1'
	            ELSE instr0_imm8(0)  WHEN rising_edge(clk) AND instr0_pr_tkn = '1' AND can_assign_rob = '1'
	            ELSE instr1_imm8(0)  WHEN rising_edge(clk) AND instr1_pr_tkn = '1' AND can_assign_rob = '1'
	            ELSE misaligned_br   WHEN rising_edge(clk) AND can_assign_rob = '0' --when needs to wait, forward 
	            ELSE '0'             WHEN rising_edge(clk) 
	            ELSE UNAFFECTED;
	r_ip.i0 <= correct_addr WHEN flush
	      ELSE (7 DOWNTO 0 => instr0_imm8, OTHERS => '0')  WHEN instr0_pr_tkn
	      ELSE (7 DOWNTO 0 => instr1_imm8, OTHERS => '0')  WHEN instr1_pr_tkn
	      ELSE ipp2; 
	r_ip.we <= can_fetch; 
	r_fl.we <= (ROB(addr0_s).controls.wrf AND can_retire0)
	        OR (ROB(addr1_s).controls.wrf AND can_retire1); 
	r_fl.i0 <= x"0004" WHEN ROB(addr1_s).value(15) = '1' AND ROB(addr1_s).controls.wrf = '1' AND can_retire1 = '1' 
	      ELSE x"0002" WHEN ROB(addr1_s).value = x"0000" AND ROB(addr1_s).controls.wrf = '1' AND can_retire1 = '1' 
	      ELSE x"0001" WHEN                                  ROB(addr1_s).controls.wrf = '1' AND can_retire1 = '1' 
	      ELSE x"0004" WHEN ROB(addr0_s).value(15) = '1' AND ROB(addr0_s).controls.wrf = '1' AND can_retire0 = '1' 
	      ELSE x"0002" WHEN ROB(addr0_s).value = x"0000" AND ROB(addr0_s).controls.wrf = '1' AND can_retire0 = '1' 
	      ELSE x"0001" WHEN                                  ROB(addr0_s).controls.wrf = '1' AND can_retire0 = '1' 
	      ELSE UNAFFECTED;
	r_lr.i0 <= ROB(addr0_s).addr WHEN ROB(addr0_s).controls.cal = '1'
	      ELSE ROB(addr0_s).src1; 
	r_lr.we <= '1' WHEN  ROB(addr0_s).controls.cal = '1' 
	                 OR (ROB(addr0_s).controls.wre = '1' AND ROB(addr0_s).dest = "010") 
	      ELSE '0';

	--flag comparison
	flcmp <= r_fl.o0(2 DOWNTO 0) AND ROB(addr0_s).src0(2 DOWNTO 0);

END ARCHITECTURE behav;
