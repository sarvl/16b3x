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
			a0  : IN  std_ulogic_vector(15 DOWNTO 0);
			i0  : IN  std_ulogic_vector(15 DOWNTO 0);
			o0  : OUT std_ulogic_vector(15 DOWNTO 0);

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


	SIGNAL   instr      : std_ulogic_vector(15 DOWNTO 0) := x"0000";
	SIGNAL   r0         : std_ulogic_vector( 2 DOWNTO 0);
	SIGNAL   r1         : std_ulogic_vector( 2 DOWNTO 0);
	SIGNAL   rdi        : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL   r0o        : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL   r1o        : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL   op0        : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL   op1        : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL   imm08      : std_ulogic_vector( 7 DOWNTO 0);
	SIGNAL 	 alu_op     : std_ulogic_vector( 2 DOWNTO 0);

	SIGNAL 	controls    : t_controls;


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


	SIGNAL 	spp2  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	sps2  : std_ulogic_vector(15 DOWNTO 0);
	SIGNAL 	ipp1  : std_ulogic_vector(15 DOWNTO 0);

	SIGNAL 	flcmp : std_ulogic_vector( 2 DOWNTO 0);


BEGIN 
	PROCESS IS 
	BEGIN
		clk <= '0' ;             WAIT FOR clk_period / 2;
		
		--whenever hlt = 0 there is no need to continue the simulation
		assert controls.hlt = '0' 
			report "simulation stopped by hlt signal" & CR severity failure;
		clk <= '1'; WAIT FOR clk_period / 2;

		--so that it looks nicer on the gtkwave
		clk <= '0';
		IF mem_rdy /= '1' THEN
			WAIT UNTIL mem_rdy = '1';
		END IF;
	END PROCESS;

	rgf0: reg_file PORT MAP(rd  => r0,
	                        r0  => r0,
	                        r1  => r1,
	                        i0  => rdi,
	                        o0  => r0o,
	                        o1  => r1o,
	                        we  => controls.wrr,
	                        clk => clk);

	alu0: alu PORT MAP(i0 => op0,
	                   i1 => op1,
	                   o0 => alu_out,
	                   op => alu_op);

	
	ram0: ram PORT MAP(a0  => ram_adr,
	                   i0  => ram_in,
	                   o0  => ram_out,
	                   we  => controls.wrm,
					   rdy => mem_rdy,
	                   clk => clk);
	mul0: multiplier PORT MAP(i0 => op0,
	                          i1 => op1,
	                          o0 => mul_out);

	
	cntrl: control PORT MAP(instr    => instr,
	                        controls => controls,
	                        alu_op   => alu_op, 
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
	

	--retrievieng instruction, only when new instruction should be taken
	instr <= ram_out WHEN controls.cycadv = '1'
	    ELSE UNAFFECTED;
	
	--retrieviegn control stuff from instruction that does not require control
	imm08 <= instr( 7 DOWNTO 0);
	r0    <= instr(10 DOWNTO 8);
	r1    <= instr( 7 DOWNTO 5);
	
	--retrievieng data from reg file
	op0 <= r0o;
	op1 <= r1o WHEN controls.iim /= '1'
	  ELSE r_ui.o0(7 DOWNTO 0) & imm08;

	--memory stuff
	ram_adr <= r_ip.o0(14 DOWNTO 0) & "0" WHEN controls.cycadv = '1'
	      ELSE dat_adr;
	
	ram_in  <= op0 WHEN controls.wrm = '1'
	      ELSE UNAFFECTED;
	
	dat_adr <= sps2    WHEN controls.psh = '1'
	      ELSE r_sp.o0 WHEN controls.pop = '1'
	      ELSE op1     WHEN controls.wrm = '1' OR controls.srm = '1'
	      ELSE x"0000";

	--input to reg file
	rdi   <= op1     WHEN controls.sro = '1'
	    ELSE alu_out WHEN controls.srr = '1'
	    ELSE ram_out WHEN controls.srm = '1' 
		ELSE mul_out WHEN controls.mul = '1'
	    ELSE r_ip.o0 WHEN controls.sre = '1' AND r1 = "000"
	    ELSE r_sp.o0 WHEN controls.sre = '1' AND r1 = "001" 
	    ELSE r_lr.o0 WHEN controls.sre = '1' AND r1 = "010" 
	    ELSE r_ui.o0 WHEN controls.sre = '1' AND r1 = "100" 
	    ELSE r_fl.o0 WHEN controls.sre = '1' AND r1 = "101" 
	    ELSE x"0001" WHEN controls.sre = '1' AND r1 = "111" 
	    ELSE UNAFFECTED;

	--input to external register

	r_sp.i0 <= spp2 WHEN controls.pop = '1'
	      ELSE sps2 WHEN controls.psh = '1'
	      ELSE op1  WHEN controls.wre = '1' AND r0 = "001"
	      ELSE UNAFFECTED;
	r_sp.we <= '1' WHEN  controls.pop = '1' 
	                 OR  controls.psh = '1'
	                 OR (controls.wre = '1' AND r0 = "001")
		  ELSE '0';
	
	r_ui.i0 <= op1 WHEN controls.wre = '1' AND r0 = "100"
	      ELSE x"0000";
	
	r_ip.i0 <= op1     WHEN controls.jmp = '1' AND flcmp /= "000" 
	      ELSE op1     WHEN controls.cal = '1' AND flcmp /= "000" 
	      ELSE r_lr.o0 WHEN controls.ret = '1' AND flcmp /= "000" 
	      ELSE op1     WHEN controls.wre = '1' AND r0     = "000" 
	      ELSE ipp1;
	r_ip.we <= controls.cycadv;

	r_fl.i0 <= op1     WHEN controls.wre = '1' AND r0 = "101" 
	      ELSE x"0004" WHEN alu_out(15)  = '1'
	      ELSE x"0002" WHEN alu_out      = x"0000"     
	      ELSE x"0001";
	r_fl.we <= controls.wrf;

	r_lr.i0 <= ipp1 WHEN  controls.cal = '1' AND flcmp /= "000" 
	      ELSE op1  WHEN  controls.wre = '1' AND r0     = "010"
		  ELSE UNAFFECTED;
	r_lr.we <= '1'  WHEN (controls.cal = '1' AND flcmp /= "000")
	                  OR (controls.wre = '1' AND r0     = "010")
		  ELSE '0';

	--flag comparison
	flcmp <= r0 AND r_fl.o0(2 DOWNTO 0);

END ARCHITECTURE behav;
