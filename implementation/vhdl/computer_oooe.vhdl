/*
	DUs in file
		computer

	this computer is {not pipelined; sub scalar; in order} 
	implementation of isa specified in intruction_set.txt

*/

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_control.ALL;

ENTITY computer IS 
END ENTITY computer;

ARCHITECTURE behav OF computer IS

	TYPE t_register IS RECORD
		i0 : std_ulogic_vector(15 DOWNTO 0);
		o0 : std_ulogic_vector(15 DOWNTO 0);
		we : std_ulogic;
	END RECORD t_register;

	TYPE t_instruction_control IS RECORD
		 instr      : std_ulogic_vector(15 DOWNTO 0);
		 addr       : std_ulogic_vector(15 DOWNTO 0);
		 r0         : std_ulogic_vector( 2 DOWNTO 0);
		 r1         : std_ulogic_vector( 2 DOWNTO 0);
		 alu_op     : std_ulogic_vector( 2 DOWNTO 0);
		controls    : t_controls;
	END RECORD t_instruction_control;

	TYPE t_instruction IS RECORD 
		 ctrl       : t_instruction_control;

		 rdi        : std_ulogic_vector(15 DOWNTO 0);
		 r0o        : std_ulogic_vector(15 DOWNTO 0);
		 r1o        : std_ulogic_vector(15 DOWNTO 0);
		 op0        : std_ulogic_vector(15 DOWNTO 0);
		 op1        : std_ulogic_vector(15 DOWNTO 0);
	END RECORD t_instruction;

	TYPE t_buf_src IS (nn, m0, m1, /*b0,*/ b1, b2, b3, df);

	COMPONENT alu IS 
		PORT(
			i0 : IN  std_ulogic_vector(15 DOWNTO 0);
			i1 : IN  std_ulogic_vector(15 DOWNTO 0);

			o0 : OUT std_ulogic_vector(15 DOWNTO 0);

			op : IN  std_ulogic_vector( 2 DOWNTO 0));
	END COMPONENT alu;

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


	CONSTANT clk_period : time       :=  1 NS;
	SIGNAL   clk        : std_ulogic := '0';

	--just remove the meta value warnings
	--zero init is not neccessary for real programs
	CONSTANT empty_c    : t_instruction_control := (instr | addr => x"0000", r0 | r1 | alu_op => "000", controls => (cycadv => '1', OTHERS => '0'));
	SIGNAL  mem_instr_0 : t_instruction_control := empty_c; 
	SIGNAL  mem_instr_1 : t_instruction_control := empty_c; 

	SIGNAL  bufi_0      : t_instruction_control := empty_c;
	SIGNAL  bufi_1      : t_instruction_control := empty_c;
	SIGNAL  bufi_2      : t_instruction_control := empty_c;
	SIGNAL  bufi_3      : t_instruction_control := empty_c;

	SIGNAL  temp_0      : t_instruction_control := empty_c;
	SIGNAL  temp_1      : t_instruction_control := empty_c;

	SIGNAL  bufi_0_p    : std_ulogic := '0';
	SIGNAL  bufi_1_p    : std_ulogic := '0';
	SIGNAL  bufi_2_p    : std_ulogic := '0';
	SIGNAL  bufi_3_p    : std_ulogic := '0';

	SIGNAL  mul_out     : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  ram_adr     : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  ram_in      : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  ram_out     : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  alu_out_0   : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  alu_out_1   : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  dat_adr     : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  mem_rdy     : std_ulogic := '0';
	SIGNAL  ram_we      : std_ulogic := '0';

	SIGNAL  instr_out   : std_ulogic_vector(31 DOWNTO 0) := x"00000000";

	SIGNAL 	r_ip : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_sp : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_lr : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_ui : t_register := (x"0000", x"0000", '1');
	SIGNAL 	r_fl : t_register := (x"0000", x"0000", '0');


	SIGNAL 	spp2  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	sps2  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	ipp2  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	ipp1  : std_ulogic_vector(15 DOWNTO 0);

	SIGNAL 	flcmp : std_ulogic_vector( 2 DOWNTO 0);


	SIGNAL  eu_0   : t_instruction := (ctrl => empty_c, rdi | op0 | op1 | r0o | r1o => x"0000");
	SIGNAL  eu_1   : t_instruction := (ctrl => empty_c, rdi | op0 | op1 | r0o | r1o => x"0000");


	SIGNAL  dep_1on0   : std_ulogic := '0';
	SIGNAL  dep_2on0   : std_ulogic := '0';
	SIGNAL  dep_3on0   : std_ulogic := '0';

	SIGNAL  dep_2on1   : std_ulogic := '0';
	SIGNAL  dep_3on1   : std_ulogic := '0';
	
	SIGNAL  dep_3on2   : std_ulogic := '0';


	SIGNAL 	b0_src     : t_buf_src := m0;
	SIGNAL 	b1_src     : t_buf_src := m1;
	SIGNAL 	b2_src     : t_buf_src := nn;
	SIGNAL 	b3_src     : t_buf_src := nn;


	SIGNAL  we_s       : std_ulogic := '0';
	SIGNAL  we_f       : std_ulogic := '0';

	SIGNAL  can_skip_wait : std_ulogic := '0';

	--effectively used to handle cycadv from control, because this time control cant help
	SIGNAL  cycadv        : std_ulogic := '1';

	SIGNAL  branch_taken  : std_ulogic := '0';
	SIGNAL  branch_unalign: std_ulogic := '0';

	SIGNAL  early_branch  : std_ulogic := '0';
	SIGNAL  early_flags   : std_ulogic_vector(2 DOWNTO 0);
	SIGNAL  early_target  : std_ulogic_vector(15 DOWNTO 0);

BEGIN 
	PROCESS IS 
	BEGIN
		clk <= '0' ;             WAIT FOR clk_period / 2;
		
		--whenever hlt = 0 there is no need to continue the simulation
		--how to handle when second instruction has hlt??
		assert eu_0.ctrl.controls.hlt /= '1' 
			report "simulation stopped by hlt signal" & CR severity failure;
		clk <= '1'; WAIT FOR clk_period / 2;

		--so that it looks nicer on the gtkwave
		clk <= '0';
		IF mem_rdy /= '1' THEN
			WAIT UNTIL mem_rdy = '1';
		END IF;
	END PROCESS;

	rgf0: reg_file PORT MAP(i0f => eu_0.rdi,
	                        i0s => eu_1.rdi,
	                        o0f => eu_0.r0o,
	                        o1f => eu_0.r1o,
	                        o0s => eu_1.r0o,
	                        o1s => eu_1.r1o,
	                        rdf => eu_0.ctrl.r0,
	                        r0f => eu_0.ctrl.r0,
	                        r1f => eu_0.ctrl.r1,
	                        rds => eu_1.ctrl.r0,
	                        r0s => eu_1.ctrl.r0,
	                        r1s => eu_1.ctrl.r1,
	                        wef => we_f,
	                        wes => we_s, 
	                        clk => clk);

	alu0: alu PORT MAP(i0 => eu_0.op0,
	                   i1 => eu_0.op1,
	                   o0 => alu_out_0,
	                   op => eu_0.ctrl.alu_op);
	alu1: alu PORT MAP(i0 => eu_1.op0,
	                   i1 => eu_1.op1,
	                   o0 => alu_out_1,
	                   op => eu_1.ctrl.alu_op);

	ram0: ram PORT MAP(a0  => ram_adr,
	                   i0s => ram_in,
	                   o0s => ram_out,
	                   o0d => instr_out,
	                   we  => ram_we,
					   rdy => mem_rdy,
	                   clk => clk);

	mul0: multiplier PORT MAP(i0 => eu_0.op0,
	                          i1 => eu_0.op1,
	                          o0 => mul_out);

	
	cntrl0: control PORT MAP(instr         => mem_instr_0.instr,
	                         controls      => mem_instr_0.controls,
							 can_skip_wait => can_skip_wait,
	                         alu_op        => mem_instr_0.alu_op,  
	                         clk           => clk);
	
	cntrl1: control PORT MAP(instr         => mem_instr_1.instr,
	                         controls      => mem_instr_1.controls,
							 can_skip_wait => can_skip_wait,
	                         alu_op        => mem_instr_1.alu_op,  
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
	reg_ui: reg_16bit PORT MAP(i0  => r_ui.i0,
	                           o0  => r_ui.o0,
	                           we  => r_ui.we,
	                           clk => clk);
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
	ipad2: adder_16bit PORT MAP(i0 => r_ip.o0,
	                            i1 => x"0002",
	                            ic => '0',
	                            o0 => ipp2,
	                            oc => OPEN);
	ipad1: adder_16bit PORT MAP(i0 => eu_0.ctrl.addr,
	                            i1 => x"0001",
	                            ic => '0',
	                            o0 => ipp1,
	                            oc => OPEN);
	
	
	we_f <= '0' WHEN (eu_0.ctrl.controls.srm = '1' OR eu_0.ctrl.controls.wrm = '1') AND cycadv = '1' AND b3_src /= df
	   ELSE eu_0.ctrl.controls.wrr;
	we_s <= '0' WHEN (eu_0.ctrl.controls.srm = '1' OR eu_0.ctrl.controls.wrm = '1') AND cycadv = '1' AND b3_src /= df
	   ELSE eu_1.ctrl.controls.wrr;
	can_skip_wait <= '1';

	--slighdly delayed to use correct values, instead can use the logic that is used to set b3_src
	cycadv <= '1' WHEN falling_edge(clk'delayed(1 PS)) AND cycadv = '0'
	     ELSE '0' WHEN falling_edge(clk'delayed(1 PS)) AND eu_0.ctrl.controls.cycadv = '0' AND b3_src /= df
	     ELSE UNAFFECTED;

	mem_instr_0.instr <= instr_out(31 DOWNTO 16);
	mem_instr_1.instr <= instr_out(15 DOWNTO  0);
	mem_instr_0.addr  <= r_ip.o0(15 DOWNTO 1) & '0'; 
	mem_instr_1.addr  <= r_ip.o0(15 DOWNTO 1) & '1'; 

	--retrieviegn control stuff from instruction that does not require control
	mem_instr_0.r0  <= mem_instr_0.instr(10 DOWNTO 8);
	mem_instr_0.r1  <= mem_instr_0.instr( 7 DOWNTO 5);
	mem_instr_1.r0  <= mem_instr_1.instr(10 DOWNTO 8);
	mem_instr_1.r1  <= mem_instr_1.instr( 7 DOWNTO 5);

	
	temp_0 <= bufi_0  WHEN bufi_0_p = '1' AND rising_edge(clk) AND cycadv  =  '1';
	temp_1 <= bufi_1  WHEN bufi_1_p = '1' AND rising_edge(clk) AND cycadv  =  '1' AND dep_1on0 = '0'
	     ELSE bufi_2  WHEN bufi_2_p = '1' AND rising_edge(clk) AND cycadv  =  '1' AND dep_2on0 = '0' AND dep_2on1 = '0'
	     ELSE bufi_3  WHEN bufi_3_p = '1' AND rising_edge(clk) AND cycadv  =  '1' AND dep_3on0 = '0' AND dep_3on1 = '0' AND dep_3on2 = '0'
	     ELSE empty_c WHEN                    rising_edge(clk) AND cycadv  =  '1'                    
	     ELSE UNAFFECTED; 
	
	eu_0.ctrl <= temp_1 WHEN temp_1.controls.wrm = '1' OR temp_1.controls.srm = '1'
	                      OR temp_1.controls.mul = '1'
	        ELSE temp_0;
	eu_1.ctrl <= temp_0 WHEN temp_1.controls.wrm = '1' OR temp_1.controls.srm = '1'
	                      OR temp_1.controls.mul = '1'
	        ELSE temp_1;

	--retrievieng data from reg file
	eu_0.op0 <= eu_0.r0o;
	eu_0.op1 <= eu_0.r1o WHEN eu_0.ctrl.controls.iim /= '1'
	       ELSE r_ui.o0(7 DOWNTO 0) & eu_0.ctrl.instr( 7 DOWNTO 0); --imm08
	
	eu_1.op0 <= eu_1.r0o;
	eu_1.op1 <= eu_1.r1o WHEN eu_1.ctrl.controls.iim /= '1'
	       ELSE r_ui.o0(7 DOWNTO 0) & eu_1.ctrl.instr( 7 DOWNTO 0); --imm08

	b0_src <= UNAFFECTED WHEN cycadv = '0'
	     ELSE b1 WHEN falling_edge(clk) AND dep_1on0 = '1'
	     ELSE b2 WHEN falling_edge(clk) AND bufi_2_p = '1'
	     ELSE m0 WHEN falling_edge(clk)
	     ELSE UNAFFECTED;
	b1_src <= UNAFFECTED WHEN cycadv = '0'
	     ELSE b2 WHEN falling_edge(clk) AND dep_1on0 = '1' AND (dep_2on0 = '1' OR dep_2on1 = '1')
	     ELSE b3 WHEN falling_edge(clk) AND dep_1on0 = '1' AND bufi_3_p = '1'         
	     ELSE m0 WHEN falling_edge(clk) AND dep_1on0 = '1'                            
	     ELSE b3 WHEN falling_edge(clk) AND bufi_3_p = '1'
	     ELSE m0 WHEN falling_edge(clk) AND bufi_2_p = '1'                            
	     ELSE m1 WHEN falling_edge(clk)
	     ELSE UNAFFECTED;
	b2_src <= UNAFFECTED WHEN cycadv = '0'
	     ELSE b3 WHEN falling_edge(clk) AND dep_1on0 = '1' AND (dep_2on0 = '1' OR dep_2on1 = '1') AND (dep_3on0 = '1' OR dep_3on1 = '1' OR dep_3on2 = '1')
	     ELSE m0 WHEN falling_edge(clk) AND dep_1on0 = '1' AND (dep_2on0 = '1' OR dep_2on1 = '1')
	     ELSE m0 WHEN falling_edge(clk) AND dep_1on0 = '1' AND bufi_3_p = '1'
	     ELSE m1 WHEN falling_edge(clk) AND dep_1on0 = '1' 
	     ELSE m0 WHEN falling_edge(clk) AND bufi_3_p = '1' 
	     ELSE m1 WHEN falling_edge(clk) AND bufi_2_p = '1' 
	     ELSE nn WHEN falling_edge(clk) 
	     ELSE UNAFFECTED;
	b3_src <= UNAFFECTED WHEN cycadv = '0'
	     ELSE df WHEN falling_edge(clk) AND dep_1on0 = '1' AND (dep_2on0 = '1' OR dep_2on1 = '1') AND (dep_3on0 = '1' OR dep_3on1 = '1' OR dep_3on2 = '1')
	     ELSE m1 WHEN falling_edge(clk) AND dep_1on0 = '1' AND (dep_2on0 = '1' OR dep_2on1 = '1')
	     ELSE m1 WHEN falling_edge(clk) AND dep_1on0 = '1' AND bufi_3_p = '1'
	     ELSE m1 WHEN falling_edge(clk) AND bufi_3_p = '1' 
	     ELSE nn WHEN falling_edge(clk) 
	     ELSE UNAFFECTED; 

	bufi_0 <= UNAFFECTED WHEN cycadv = '0'
	     ELSE empty_c     WHEN rising_edge(branch_taken)   OR branch_taken   = '1'  
	     ELSE empty_c     WHEN rising_edge(branch_unalign) OR branch_unalign = '1'  
	     ELSE mem_instr_0 WHEN rising_edge(clk) AND b0_src = m0 
	     ELSE bufi_1      WHEN rising_edge(clk) AND b0_src = b1
	     ELSE bufi_2      WHEN rising_edge(clk) AND b0_src = b2
	     ELSE UNAFFECTED;
	bufi_1 <= UNAFFECTED WHEN cycadv = '0'
	     ELSE empty_c     WHEN rising_edge(branch_taken) OR branch_taken = '1' 
	     ELSE mem_instr_0 WHEN rising_edge(clk) AND b1_src = m0 
	     ELSE mem_instr_1 WHEN rising_edge(clk) AND b1_src = m1 
	     ELSE bufi_2      WHEN rising_edge(clk) AND b1_src = b2 
	     ELSE bufi_3      WHEN rising_edge(clk) AND b1_src = b3 
	     ELSE UNAFFECTED;
	bufi_2 <= UNAFFECTED WHEN cycadv = '0'
	     ELSE empty_c     WHEN rising_edge(branch_taken) OR branch_taken = '1' 
	     ELSE mem_instr_0 WHEN rising_edge(clk) AND b2_src = m0 
	     ELSE mem_instr_1 WHEN rising_edge(clk) AND b2_src = m1 
	     ELSE bufi_3      WHEN rising_edge(clk) AND b2_src = b3 
	     ELSE UNAFFECTED;
	bufi_3 <= UNAFFECTED WHEN cycadv = '0'
	     ELSE empty_c     WHEN rising_edge(branch_taken) OR branch_taken = '1' 
	     ELSE mem_instr_1 WHEN rising_edge(clk) AND b3_src = m1 
	     ELSE UNAFFECTED; 
	
	bufi_0_p <= '1';
	bufi_1_p <= '1'; 
	bufi_2_p <= '0' WHEN branch_taken = '1'
	       ELSE '1' WHEN rising_edge(clk) AND b2_src /= nn
	       ELSE '0' WHEN rising_edge(clk)
	       ELSE UNAFFECTED;
	bufi_3_p <= '0' WHEN branch_taken = '1'
	       ELSE '1' WHEN rising_edge(clk) AND b3_src /= nn AND b3_src /= df
	       ELSE '0' WHEN rising_edge(clk)
	       ELSE UNAFFECTED;

	/*
		each depedenccy dep_XoY in order:
			1. Y writes to register used by X  
			2. X is HLT or Y is HLT 
			3. X is WRM and Y is WRM/RDM
			4. Y = 0 and Y is RDM/WRM and X is RDM
				two WRM/RDM instructions cant execute at once 
				case when X is WRM is covered by 3 and 4 
			5. Y = 0 and Y is MUL and x is MUL 
				two MUL cant execute at once
			6. X/Y is jmp/cal/ret/wrx/rdx
				this is more restrictive than neccessary
				however this simplifies circuit significantly 
				and the rdx/wrx are not frequent enough 
				 for this restriction to have significant (if any) impact on performance
			7. X modifies RZ and Y is WRM and writes RZ
			

			should add proper handling for rdx wrx 
	*/
	dep_1on0 <= '1' WHEN bufi_0.controls.wrr = '1' 
	                 AND (  bufi_0.r0 = bufi_1.r0
	                     OR (bufi_0.r0 = bufi_1.r1 AND bufi_1.controls.iim = '0'))
	       ELSE '1' WHEN bufi_1.controls.hlt = '1' OR bufi_0.controls.hlt = '1'
	       ELSE '1' WHEN (bufi_1.controls.wrm = '1' OR bufi_1.controls.srm = '1')
		             AND (bufi_0.controls.wrm = '1' OR bufi_0.controls.srm = '1')
	       ELSE '1' WHEN bufi_1.controls.jmp = '1' OR bufi_1.controls.cal = '1' OR bufi_1.controls.ret = '1' OR bufi_1.controls.wre = '1' OR bufi_1.controls.sre = '1'
	                  OR bufi_0.controls.jmp = '1' OR bufi_0.controls.cal = '1' OR bufi_0.controls.ret = '1' OR bufi_0.controls.wre = '1' OR bufi_0.controls.sre = '1'
	       ELSE '1' WHEN bufi_0.controls.wrm = '1' AND bufi_1.controls.wrr = '1' AND bufi_0.r0 = bufi_1.r0
	       ELSE '0';
	dep_2on0 <= '0' WHEN bufi_2_p = '0'
	       ELSE '1' WHEN bufi_0.controls.wrr = '1' 
	                 AND (  bufi_0.r0 = bufi_2.r0
	                     OR (bufi_0.r0 = bufi_2.r1 AND bufi_2.controls.iim = '0'))
	       ELSE '1' WHEN bufi_2.controls.hlt = '1' OR bufi_0.controls.hlt = '1'
	       ELSE '1' WHEN (bufi_2.controls.wrm = '1' OR bufi_2.controls.srm = '1')
		             AND (bufi_0.controls.wrm = '1' OR bufi_0.controls.srm = '1')
	       ELSE '1' WHEN bufi_2.controls.jmp = '1' OR bufi_2.controls.cal = '1' OR bufi_2.controls.ret = '1' OR bufi_2.controls.wre = '1' OR bufi_2.controls.sre = '1'
	                  OR bufi_0.controls.jmp = '1' OR bufi_0.controls.cal = '1' OR bufi_0.controls.ret = '1' OR bufi_0.controls.wre = '1' OR bufi_0.controls.sre = '1'
	       ELSE '1' WHEN bufi_0.controls.wrm = '1' AND bufi_2.controls.wrr = '1' AND bufi_0.r0 = bufi_2.r0
	       ELSE '0';
	dep_3on0 <= '0' WHEN bufi_3_p = '0'
	       ELSE '1' WHEN bufi_0.controls.wrr = '1' 
	                 AND (  bufi_0.r0 = bufi_3.r0
	                     OR (bufi_0.r0 = bufi_3.r1 AND bufi_3.controls.iim = '0'))
	       ELSE '1' WHEN bufi_3.controls.hlt = '1' OR bufi_0.controls.hlt = '1'
	       ELSE '1' WHEN (bufi_3.controls.wrm = '1' OR bufi_3.controls.srm = '1')
		             AND (bufi_0.controls.wrm = '1' OR bufi_0.controls.srm = '1')
	       ELSE '1' WHEN bufi_3.controls.jmp = '1' OR bufi_3.controls.cal = '1' OR bufi_3.controls.ret = '1' OR bufi_3.controls.wre = '1' OR bufi_3.controls.sre = '1'
	                  OR bufi_0.controls.jmp = '1' OR bufi_0.controls.cal = '1' OR bufi_0.controls.ret = '1' OR bufi_0.controls.wre = '1' OR bufi_0.controls.sre = '1'
	       ELSE '1' WHEN bufi_0.controls.wrm = '1' AND bufi_3.controls.wrr = '1' AND bufi_0.r0 = bufi_3.r0
	       ELSE '0';
	dep_2on1 <= '0' WHEN bufi_2_p = '0'
	       ELSE '1' WHEN bufi_1.controls.wrr = '1' 
	                 AND (  bufi_1.r0 = bufi_2.r0
	                     OR (bufi_1.r0 = bufi_2.r1 AND bufi_2.controls.iim = '0'))
	       ELSE '1' WHEN bufi_2.controls.hlt = '1' OR bufi_1.controls.hlt = '1'
	       ELSE '1' WHEN  bufi_2.controls.wrm = '1'
		             AND (bufi_1.controls.wrm = '1' OR bufi_1.controls.srm = '1')
	       ELSE '1' WHEN bufi_2.controls.jmp = '1' OR bufi_2.controls.cal = '1' OR bufi_2.controls.ret = '1' OR bufi_2.controls.wre = '1' OR bufi_2.controls.sre = '1'
	                  OR bufi_1.controls.jmp = '1' OR bufi_1.controls.cal = '1' OR bufi_1.controls.ret = '1' OR bufi_1.controls.wre = '1' OR bufi_1.controls.sre = '1'
	       ELSE '1' WHEN bufi_1.controls.wrm = '1' AND bufi_2.controls.wrr = '1' AND bufi_1.r0 = bufi_2.r0
	       ELSE '0';
	dep_3on1 <= '0' WHEN bufi_3_p = '0'
	       ELSE '1' WHEN bufi_1.controls.wrr = '1' 
	                 AND (  bufi_1.r0 = bufi_3.r0
	                     OR (bufi_1.r0 = bufi_3.r1 AND bufi_3.controls.iim = '0'))
	       ELSE '1' WHEN bufi_3.controls.hlt = '1' OR bufi_1.controls.hlt = '1'
	       ELSE '1' WHEN  bufi_3.controls.wrm = '1'
		             AND (bufi_1.controls.wrm = '1' OR bufi_1.controls.srm = '1')
	       ELSE '1' WHEN bufi_3.controls.jmp = '1' OR bufi_3.controls.cal = '1' OR bufi_3.controls.ret = '1' OR bufi_3.controls.wre = '1' OR bufi_3.controls.sre = '1'
	                  OR bufi_1.controls.jmp = '1' OR bufi_1.controls.cal = '1' OR bufi_1.controls.ret = '1' OR bufi_1.controls.wre = '1' OR bufi_1.controls.sre = '1'
	       ELSE '1' WHEN bufi_1.controls.wrm = '1' AND bufi_3.controls.wrr = '1' AND bufi_1.r0 = bufi_3.r0
	       ELSE '0';
	dep_3on2 <= '0' WHEN bufi_3_p = '0'
	       ELSE '1' WHEN bufi_2.controls.wrr = '1' 
	                 AND (  bufi_2.r0 = bufi_3.r0
	                     OR (bufi_2.r0 = bufi_3.r1 AND bufi_3.controls.iim = '0'))
	       ELSE '1' WHEN bufi_3.controls.hlt = '1' OR bufi_2.controls.hlt = '1'
	       ELSE '1' WHEN  bufi_3.controls.wrm = '1'
		             AND (bufi_2.controls.wrm = '1' OR bufi_2.controls.srm = '1')
	       ELSE '1' WHEN bufi_3.controls.jmp = '1' OR bufi_3.controls.cal = '1' OR bufi_3.controls.ret = '1' OR bufi_3.controls.wre = '1' OR bufi_3.controls.sre = '1'
	                  OR bufi_2.controls.jmp = '1' OR bufi_2.controls.cal = '1' OR bufi_2.controls.ret = '1' OR bufi_2.controls.wre = '1' OR bufi_2.controls.sre = '1'
	       ELSE '1' WHEN bufi_2.controls.wrm = '1' AND bufi_3.controls.wrr = '1' AND bufi_2.r0 = bufi_3.r0
	       ELSE '0';

	--memory stuff
	ram_adr <= r_ip.o0(14 DOWNTO 0) & "0" WHEN cycadv = '1' AND b3_src /= df
	      ELSE dat_adr;
	
	ram_in <= eu_0.op0;

	dat_adr <= sps2    WHEN eu_0.ctrl.controls.psh = '1'
	      ELSE r_sp.o0 WHEN eu_0.ctrl.controls.pop = '1'
	      ELSE eu_0.op1 WHEN (eu_0.ctrl.controls.wrm = '1' OR  eu_0.ctrl.controls.srm = '1') 
		  ELSE UNAFFECTED;
	ram_we  <= '1' WHEN eu_0.ctrl.controls.wrm = '1' AND (cycadv = '0' OR b3_src = df)
	      ELSE '0';
	


	--input to reg file
	eu_0.rdi <= eu_0.op1         WHEN eu_0.ctrl.controls.sro = '1'
	       ELSE alu_out_0        WHEN eu_0.ctrl.controls.srr = '1' 
	       ELSE ram_out          WHEN eu_0.ctrl.controls.srm = '1' 
		   ELSE mul_out          WHEN eu_0.ctrl.controls.mul = '1'
	       ELSE r_ip.o0          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "000"
	       ELSE r_sp.o0          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "001" 
	       ELSE r_lr.o0          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "010" 
	       ELSE r_ui.o0          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "100" 
	       ELSE r_fl.o0          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "101" 
	       ELSE x"0001"          WHEN eu_0.ctrl.controls.sre = '1' AND eu_0.ctrl.r1 = "111" 
	       ELSE UNAFFECTED;
	
	eu_1.rdi <= eu_1.op1         WHEN eu_1.ctrl.controls.sro = '1'
	       ELSE alu_out_1        WHEN eu_1.ctrl.controls.srr = '1' 
	       ELSE ram_out          WHEN eu_1.ctrl.controls.srm = '1' 
		   ELSE mul_out          WHEN eu_1.ctrl.controls.mul = '1'
	       ELSE r_ip.o0          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "000"
	       ELSE r_sp.o0          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "001" 
	       ELSE r_lr.o0          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "010" 
	       ELSE r_ui.o0          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "100" 
	       ELSE r_fl.o0          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "101" 
	       ELSE x"0001"          WHEN eu_1.ctrl.controls.sre = '1' AND eu_1.ctrl.r1 = "111" 
	       ELSE UNAFFECTED;

	--input to external register

	r_sp.i0 <= spp2 WHEN eu_0.ctrl.controls.pop = '1'
	      ELSE sps2 WHEN eu_0.ctrl.controls.psh = '1'
	      ELSE eu_0.op1  WHEN eu_0.ctrl.controls.wre = '1' AND eu_0.ctrl.r0 = "001"
	      ELSE UNAFFECTED;
	r_sp.we <= '0' WHEN (eu_0.ctrl.controls.srm = '1' OR eu_0.ctrl.controls.wrm = '1') AND cycadv = '1' AND b3_src /= df
	      ELSE '1' WHEN  eu_0.ctrl.controls.pop = '1' 
	                 OR  eu_0.ctrl.controls.psh = '1'
	                 OR (eu_0.ctrl.controls.wre = '1' AND eu_0.ctrl.r0 = "001")
		  ELSE '0';
	
	r_ui.i0 <= eu_0.op1 WHEN eu_0.ctrl.controls.wre = '1' AND eu_0.ctrl.r0 = "100"
	      ELSE x"0000";
	
	early_branch <= '1' WHEN falling_edge(clk) AND bufi_0.controls.jmp = '1' AND bufi_0.controls.iim = '1' AND early_flags /= "000"
	           ELSE '0' WHEN falling_edge(clk)
	           ELSE UNAFFECTED;
	early_flags  <= bufi_0.r0 AND r_fl.i0(2 DOWNTO 0) WHEN rising_edge(clk'delayed(10 PS)) AND (eu_0.ctrl.controls.wrf = '1' OR eu_1.ctrl.controls.wrf = '1')
	           ELSE bufi_0.r0 AND r_fl.o0(2 DOWNTO 0) WHEN rising_edge(clk'delayed(10 PS))
	           ELSE UNAFFECTED;
	early_target <= x"00" & bufi_0.instr(7 DOWNTO 0) WHEN falling_edge(clk);

	-- try to predict sooner
	--this will fail when previous instruction sets the upper immiediate
	r_ip.i0 <= early_target WHEN early_branch = '1'
	      ELSE eu_0.op1 WHEN eu_0.ctrl.controls.jmp = '1' AND flcmp     /= "000" 
	      ELSE eu_0.op1 WHEN eu_0.ctrl.controls.cal = '1' AND flcmp     /= "000" 
	      ELSE r_lr.o0  WHEN eu_0.ctrl.controls.ret = '1' AND flcmp     /= "000" 
	      ELSE eu_0.op1 WHEN eu_0.ctrl.controls.wre = '1' AND eu_0.ctrl.r0  = "000" 
	      ELSE ipp2;
	--when two instructions in buffers, DO NOT load new ones
	r_ip.we <= '1' WHEN  early_branch = '1'
	                 OR (cycadv = '1' AND b3_src /= df) 
	                 OR (eu_0.ctrl.controls.jmp = '1' OR eu_0.ctrl.controls.cal = '1' OR eu_0.ctrl.controls.ret = '1')
	      ELSE '0';

	r_fl.i0 <= eu_0.op1 WHEN eu_0.ctrl.controls.wre = '1' AND eu_0.ctrl.r0 = "101" 
	      ELSE x"0004"    WHEN eu_1.ctrl.controls.wrf = '1' AND alu_out_1(15)  = '1'     
	      ELSE x"0002"    WHEN eu_1.ctrl.controls.wrf = '1' AND alu_out_1      = x"0000"     
	      ELSE x"0001"    WHEN eu_1.ctrl.controls.wrf = '1'
	      ELSE x"0004"    WHEN alu_out_0(15)  = '1'     
	      ELSE x"0002"    WHEN alu_out_0      = x"0000"     
	      ELSE x"0001";
	r_fl.we <= eu_0.ctrl.controls.wrf OR eu_1.ctrl.controls.wrf;

	r_lr.i0 <= ipp1     WHEN eu_0.ctrl.controls.cal = '1' AND flcmp     /= "000" 
	      ELSE eu_0.op1 WHEN eu_0.ctrl.controls.wre = '1' AND eu_0.ctrl.r0  = "010"
		  ELSE UNAFFECTED;
	r_lr.we <= '1'  WHEN (eu_0.ctrl.controls.cal = '1' AND flcmp     /= "000")
	                  OR (eu_0.ctrl.controls.wre = '1' AND eu_0.ctrl.r0  = "010")
		  ELSE '0';

	--flag comparison
	flcmp <= eu_0.ctrl.r0 AND r_fl.o0(2 DOWNTO 0) WHEN (eu_0.ctrl.controls.jmp = '1' OR eu_0.ctrl.controls.cal = '1' OR eu_0.ctrl.controls.ret = '1')
	    ELSE eu_1.ctrl.r0 AND r_fl.o0(2 DOWNTO 0);
	
	branch_taken <= '0' WHEN falling_edge(clk) AND branch_taken = '1'
	           ELSE '1' WHEN early_branch = '1'
	           ELSE '1' WHEN falling_edge(clk) AND flcmp /= "000" 
					     AND (  eu_0.ctrl.controls.jmp = '1' OR eu_0.ctrl.controls.cal = '1' OR eu_0.ctrl.controls.ret = '1'
					         OR eu_1.ctrl.controls.jmp = '1' OR eu_1.ctrl.controls.cal = '1' OR eu_1.ctrl.controls.ret = '1')
	           ELSE UNAFFECTED;
	
	--can just use soome additional registers 
	--but thats faster to type
	branch_unalign <= branch_taken'delayed(clk_period) AND r_ip.i0(0)'delayed(clk_period) WHEN falling_edge(clk)
	             ELSE UNAFFECTED;

END ARCHITECTURE behav;
