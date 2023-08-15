/*
	DUs in file
		computer

	this computer is {pipelined; sub scalar; in order} 
	implementation of isa specified in intruction_set.txt

*/

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_control.ALL;
USE work.p_stage.ALL;
USE std.env.finish;

ENTITY computer IS 
END ENTITY computer;

ARCHITECTURE behav OF computer IS

	TYPE t_register IS RECORD
		i0 : std_ulogic_vector(15 DOWNTO 0);
		o0 : std_ulogic_vector(15 DOWNTO 0);
		we : std_ulogic;
	END RECORD t_register;

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
			i0  : IN  std_ulogic_vector(15 DOWNTO 0);
			
			o0  : OUT std_ulogic_vector(15 DOWNTO 0);
			o1  : OUT std_ulogic_vector(15 DOWNTO 0);
	
			rd  : IN  std_ulogic_vector( 2 DOWNTO 0);	
			r0  : IN  std_ulogic_vector(2 DOWNTO 0);
			r1  : IN  std_ulogic_vector(2 DOWNTO 0);
	
			we  : IN  std_ulogic;
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
			a0  : IN  std_ulogic_vector(15 DOWNTO 0) := x"0000";
			i0s : IN  std_ulogic_vector(15 DOWNTO 0);
			o0s : OUT std_ulogic_vector(15 DOWNTO 0);
			o0d : OUT std_ulogic_vector(31 DOWNTO 0) := x"00000000";
	
			we  : IN  std_ulogic := '0';
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

	COMPONENT stage IS
		PORT(
			i0  : IN  t_stage;
			o0  : OUT t_stage := (controls => (OTHERS => '0'), r0 | r1 | alu_op => (OTHERS => '0'), rdi | op0 | op1 => (OTHERS => '0'));
	
			clk : IN  std_ulogic);
	END COMPONENT stage;

	--to model pipeline speedup, arbitrarly can be set to lower value
	CONSTANT clk_period : time       :=  1 NS;
	SIGNAL   clk        : std_ulogic := '0';


	SIGNAL  instr       : std_ulogic_vector(15 DOWNTO 0) := x"0000";

	SIGNAL  rdi         : std_ulogic_vector(15 DOWNTO 0); 
	SIGNAL 	r0o         : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	r1o         : std_ulogic_vector(15 DOWNTO 0);

	SIGNAL  alu_out     : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  mul_out     : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  ram_adr     : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  ram_in      : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  ram_out     : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL  dat_adr     : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL  mem_rdy     : std_ulogic := '0';


	SIGNAL 	r_ip : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_sp : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_lr : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_ui : t_register := (x"0000", x"0000", '1');
	SIGNAL 	r_fl : t_register := (x"0000", x"0000", '0');


	SIGNAL  delayed_ip : std_ulogic_vector(15 DOWNTO 0) := x"0000";


	SIGNAL 	spp2  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	sps2  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	ipp1  : std_ulogic_vector(15 DOWNTO 0);

	SIGNAL 	flcmp : std_ulogic_vector( 2 DOWNTO 0);
	SIGNAL 	flcmp_delayed : std_ulogic_vector( 2 DOWNTO 0);

	--SIGNAL stage0 : t_stage; -- not needed since there are NO signals then
	SIGNAL 	stage1_id : t_stage;
	SIGNAL 	stage2_ex : t_stage;
	SIGNAL 	stage3_wb : t_stage;

	SIGNAL  stall     : std_ulogic := '0';

BEGIN 
	PROCESS IS 
	BEGIN
		clk <= '0' ;             WAIT FOR clk_period / 2;
		
		--whenever hlt = 0 there is no need to continue the simulation
		IF stage3_wb.controls.hlt = '1' AND flcmp_delayed /= "000" THEN
			finish;
		END IF;

		clk <= '1'; WAIT FOR clk_period / 2;

		--so that it looks nicer on the gtkwave
		clk <= '0';
		IF mem_rdy /= '1' THEN
			WAIT UNTIL mem_rdy = '1';
		END IF;
	END PROCESS;

	rgf0: reg_file PORT MAP(rd  => stage3_wb.r0,
	                        r0  => stage1_id.r0,
	                        r1  => stage1_id.r1,
	                        i0  => stage3_wb.rdi,
	                        o0  => r0o,
	                        o1  => r1o,
	                        we  => stage3_wb.controls.wrr,
	                        clk => clk);

	alu0: alu PORT MAP(i0 => stage2_ex.op0,
	                   i1 => stage2_ex.op1,
	                   o0 => alu_out,
	                   op => stage2_ex.alu_op);

	ram0: ram PORT MAP(a0  => ram_adr,
	                   i0s => ram_in,
	                   o0s => ram_out,
	                   o0d => OPEN,
	                   we  => stage2_ex.controls.wrm,
					   rdy => mem_rdy,
	                   hlt => stage3_wb.controls.hlt,
	                   clk => clk);

	mul0: multiplier PORT MAP(i0 => stage2_ex.op0,
	                          i1 => stage2_ex.op1,
	                          o0 => mul_out);

	
	cntrl: control PORT MAP(instr    => instr,
	                        controls => stage1_id.controls,
	                        alu_op   => stage1_id.alu_op,  
	                        can_skip_wait => '0',
	                        clk      => clk);

	reg_ip: reg_16bit PORT MAP(i0  => r_ip.i0,
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
	ipadd: adder_16bit PORT MAP(i0 => r_ip.o0,
	                            i1 => x"0001",
	                            ic => '0',
	                            o0 => ipp1,
	                            oc => OPEN);
	
	
	s2_d: stage PORT MAP(i0  => stage1_id,
	                     o0  => stage2_ex,
	                     clk => clk);
	s3_d: stage PORT MAP(i0  => (controls => stage2_ex.controls, alu_op => stage2_ex.alu_op,
	                             r0       => stage2_ex.r0,       r1     => stage2_ex.r1,
	                             op0      => stage2_ex.op0,      op1    => stage2_ex.op1, 
	                             rdi      => rdi),
	                     o0  => stage3_wb,
	                     clk => clk);

	stall <= '1' WHEN stage2_ex.controls.jmp = '1' AND flcmp /= "000"
	    ELSE '1' WHEN stage2_ex.controls.cal = '1' AND flcmp /= "000"
	    ELSE '1' WHEN stage2_ex.controls.ret = '1' AND flcmp /= "000"
	    ELSE '1' WHEN stage2_ex.controls.wre = '1' AND stage2_ex.r0 = "000"
	    ELSE '0';
	--retrievieng instruction, only when new instruction should be taken
	instr <= x"0000" WHEN stall = '1' 
	    ELSE ram_out WHEN stage2_ex.controls.cycadv = '1' AND rising_edge(clk)
	    ELSE UNAFFECTED;
	
	--retrieving control stuff from instruction that does not require control
	stage1_id.r0 <= instr(10 DOWNTO 8);
	stage1_id.r1 <= instr( 7 DOWNTO 5);
	
	--retrievieng data from reg file
	stage1_id.op0 <=           rdi WHEN stage2_ex.r0 = stage1_id.r0 AND stage2_ex.controls.wrr = '1'
	            ELSE stage3_wb.rdi WHEN stage3_wb.r0 = stage1_id.r0 AND stage3_wb.controls.wrr = '1'
	            ELSE r0o;
	stage1_id.op1 <= r_ui.i0(7 DOWNTO 0) & instr( 7 DOWNTO 0) WHEN stage1_id.controls.iim = '1'
	            ELSE           rdi WHEN stage2_ex.r0 = stage1_id.r1 AND stage2_ex.controls.wrr = '1'
	            ELSE stage3_wb.rdi WHEN stage3_wb.r0 = stage1_id.r1 AND stage3_wb.controls.wrr = '1'
	            ELSE r1o; 

	--memory stuff
	ram_adr <= r_ip.o0(14 DOWNTO 0) & "0" WHEN stage2_ex.controls.cycadv = '1'
	      ELSE dat_adr;
	
	ram_in  <= stage2_ex.op0 WHEN stage2_ex.controls.wrm = '1'
	      ELSE UNAFFECTED;
	
	dat_adr <= sps2          WHEN stage2_ex.controls.psh = '1'
	      ELSE r_sp.o0       WHEN stage2_ex.controls.pop = '1'
	      ELSE stage2_ex.op1 WHEN stage2_ex.controls.wrm = '1' OR stage2_ex.controls.srm = '1'
	      ELSE x"0000";

	--input to reg file
	rdi <= stage2_ex.op1 WHEN stage2_ex.controls.sro = '1'
	  ELSE alu_out       WHEN stage2_ex.controls.srr = '1'
	  ELSE ram_out       WHEN stage2_ex.controls.srm = '1' 
	  ELSE mul_out       WHEN stage2_ex.controls.mul = '1'
	  ELSE delayed_ip    WHEN stage2_ex.controls.sre = '1' AND stage2_ex.r1 = "000"
	  ELSE r_sp.o0       WHEN stage2_ex.controls.sre = '1' AND stage2_ex.r1 = "001" 
	  ELSE r_lr.o0       WHEN stage2_ex.controls.sre = '1' AND stage2_ex.r1 = "010" 
	  ELSE r_ui.o0       WHEN stage2_ex.controls.sre = '1' AND stage2_ex.r1 = "100" 
	  ELSE r_fl.o0       WHEN stage2_ex.controls.sre = '1' AND stage2_ex.r1 = "101" 
	  ELSE x"0001"       WHEN stage2_ex.controls.sre = '1' AND stage2_ex.r1 = "111" 
	  ELSE UNAFFECTED;


	--input to external register

	r_sp.i0 <= spp2           WHEN stage2_ex.controls.pop = '1'
	      ELSE sps2           WHEN stage2_ex.controls.psh = '1'
	      ELSE stage2_ex.op1  WHEN stage2_ex.controls.wre = '1' AND stage2_ex.r0 = "001"
	      ELSE UNAFFECTED;
	r_sp.we <= '1' WHEN  stage2_ex.controls.pop = '1' 
	                 OR  stage2_ex.controls.psh = '1'
	                 OR (stage2_ex.controls.wre = '1' AND stage2_ex.r0 = "001")
		  ELSE '0';
	
	r_ui.i0 <= stage2_ex.op1 WHEN stage2_ex.controls.wre = '1' AND stage2_ex.r0 = "100"
	      ELSE x"0000";
	
	r_ip.i0 <= stage2_ex.op1 WHEN stage2_ex.controls.jmp = '1' AND flcmp        /= "000" 
	      ELSE stage2_ex.op1 WHEN stage2_ex.controls.cal = '1' AND flcmp        /= "000" 
	      ELSE r_lr.o0       WHEN stage2_ex.controls.ret = '1' AND flcmp        /= "000" 
	      ELSE stage2_ex.op1 WHEN stage2_ex.controls.wre = '1' AND stage2_ex.r0  = "000" 
	      ELSE ipp1;
	r_ip.we <= stage2_ex.controls.cycadv;

	delayed_ip <= r_ip.o0    WHEN rising_edge(clk)
	      ELSE UNAFFECTED;

	r_fl.i0 <= stage2_ex.op1 WHEN stage2_ex.controls.wre = '1' AND stage2_ex.r0 = "101" 
	      ELSE x"0004"       WHEN alu_out(15)  = '1'
	      ELSE x"0002"       WHEN alu_out      = x"0000"     
	      ELSE x"0001";
	r_fl.we <= '1' WHEN  stage2_ex.controls.wrf = '1' 
	                 OR (stage2_ex.controls.wre = '1' AND stage2_ex.r0 = "101")
	      ELSE '0';

	r_lr.i0 <= delayed_ip    WHEN stage2_ex.controls.cal = '1' AND flcmp        /= "000" 
	      ELSE stage2_ex.op1 WHEN stage2_ex.controls.wre = '1' AND stage2_ex.r0  = "010"
		  ELSE UNAFFECTED;
	r_lr.we <= '1'  WHEN (stage2_ex.controls.cal = '1' AND flcmp        /= "000")
	                  OR (stage2_ex.controls.wre = '1' AND stage2_ex.r0  = "010")
		  ELSE '0';

	--flag comparison
	flcmp <= stage1_id.r0 AND r_fl.i0(2 DOWNTO 0) WHEN stage2_ex.controls.wrf = '1'
	                                                OR (stage2_ex.controls.wre = '1' AND stage2_ex.r0 = "101")
	    ELSE stage2_ex.r0 AND r_fl.o0(2 DOWNTO 0);

	flcmp_delayed <= flcmp WHEN rising_edge(clk)
	            ELSE UNAFFECTED;

END ARCHITECTURE behav;
