/*
	pipeline stages:
		Instr Fetch
		Instr Decod
		Execute/Memory
		Writeback
*/

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.p_decode.ALL;
USE work.p_types.ALL;

ENTITY core IS 
	PORT(
		iodata  : INOUT t_rword;
		oaddr   : OUT   t_rword;
		ord     : OUT   std_logic;
		owr     : OUT   std_logic;

		ohlt    : OUT   std_logic;
		disable : IN    std_ulogic;
		
		clk : IN  std_ulogic

	);
END ENTITY core;

ARCHITECTURE behav OF core IS 
	COMPONENT alu IS 
		PORT(
			i0 : IN  t_uword;
			i1 : IN  t_uword;
			o0 : OUT t_uword;
	
			op : IN  std_ulogic_vector( 2 DOWNTO 0)
		);
	END COMPONENT alu;

	COMPONENT adder IS
		GENERIC (
			size : positive 
		);
		PORT(
			i0 : IN  std_ulogic_vector(size - 1 DOWNTO 0); 
			i1 : IN  std_ulogic_vector(size - 1 DOWNTO 0); 
			o0 : OUT std_ulogic_vector(size - 1 DOWNTO 0);

			ic : IN  std_ulogic; 
			oc : OUT std_ulogic
		);
	END COMPONENT adder;

	COMPONENT multiplier IS 
		GENERIC (
			size : positive
		);
		PORT (
			i0 : IN  t_uword;
			i1 : IN  t_uword;
			
			o0 : OUT t_uword);
	END COMPONENT multiplier; 

	COMPONENT reg_file IS 
		PORT(
			i0  : IN  t_uword;
	
			o0  : OUT t_uword;
			o1  : OUT t_uword;
	
			rd  : IN  std_ulogic_vector(2 DOWNTO 0);
			r0  : IN  std_ulogic_vector(2 DOWNTO 0);
			r1  : IN  std_ulogic_vector(2 DOWNTO 0);
	
			we  : IN  std_ulogic;
			clk : IN  std_ulogic
		);
	END COMPONENT reg_file;

	COMPONENT reg IS 
		GENERIC(
			size    : positive;
			def_val : std_ulogic_vector(size - 1 DOWNTO 0) := (OTHERS => '0')
		);
		PORT(
			i0  : IN  std_ulogic_vector(size - 1 DOWNTO 0);
			o0  : OUT std_ulogic_vector(size - 1 DOWNTO 0) := def_val;
			we  : IN  std_ulogic;

			clk : IN  std_ulogic
		);
	END COMPONENT reg;

	COMPONENT decoder IS 
		PORT(
			instr : IN t_uword;
	
			clk           : IN std_ulogic;
			--if the implementation can use mem bus in the same cycle as it provides instructio
			can_skip_wait : IN std_ulogic;
	
			controls      : OUT t_signals
		);
	END COMPONENT decoder ;


	--used to group signals from external_regs
	TYPE t_register IS RECORD
		i0 : t_uword;
		o0 : t_uword;
		we : std_ulogic;
	END RECORD t_register;


	SIGNAL 	r_ip : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_sp : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_lr : t_register := (x"0000", x"0000", '0');
	--UI is constantly we so that it is cleared every cycle
	SIGNAL 	r_ui : t_register := (x"0000", x"0000", '1');
	SIGNAL 	r_fl : t_register := (x"0000", x"0000", '0');

	SIGNAL  r_ip_p1 : t_uword;
	SIGNAL  r_sp_p2 : t_uword;
	SIGNAL  r_sp_s2 : t_uword;


	SIGNAL  instr     : t_uword := x"0000";
	SIGNAL  result    : t_uword := x"0000";
	SIGNAL  writeback : t_uword := x"0000";

	SIGNAL alu_out : t_uword;
	SIGNAL mul_out : t_uword;
	SIGNAL ext_out : t_uword;

	TYPE stage IS RECORD
		signals : t_signals;
		data    : t_uword;
		op0     : t_uword;
		op1     : t_uword;
		--matters only for debug, for real design can be safely removed
		instr   : t_uword;
	END RECORD stage;

	SIGNAL  dec_signals : t_signals := SIGNALS_DEFAULT;

	SIGNAL r0_data : t_uword;
	SIGNAL r1_data : t_uword;

	SIGNAL  op0 : t_uword;
	SIGNAL  op1 : t_uword;

	SIGNAL  st1_decd_op0 : t_uword := x"0000";
	SIGNAL  st1_decd_op1 : t_uword := x"0000";

	--not used as would be empty
--	SIGNAL  st0_ftch : stage;
	--not used as not enough signals
--	SIGNAL  st1_decd : stage;
	SIGNAL  st2_exec : stage := (signals => SIGNALS_DEFAULT, data | op0 | op1 | instr => x"0000");
	SIGNAL  st3_wrbk : stage := (signals => SIGNALS_DEFAULT, data | op0 | op1 | instr => x"0000");

	SIGNAL  pipeline_advance     : std_ulogic := '1';
	SIGNAL  pipeline_advance_dl1 : std_ulogic := '1';
	SIGNAL  pipeline_advance_dl2 : std_ulogic := '1';
	SIGNAL  st2_branch           : std_ulogic := '0';
	SIGNAL  flcmp                : std_ulogic;

BEGIN
	c_alu : ALU PORT MAP(i0 => op0,
	                     i1 => op1,
	                     o0 => alu_out,
	                     op => st2_exec.signals.aluop);
	c_mul : multiplier GENERIC MAP(size => 16)
	                   PORT    MAP(i0 => op0,
	                               i1 => op1,
	                               o0 => mul_out);

	c_regfile : reg_file PORT MAP(i0  => st3_wrbk.data,
	                              o0  => r0_data,
	                              o1  => r1_data,
	                              rd  => st3_wrbk.signals.r0,
	                              r0  => dec_signals.r0,
	                              r1  => dec_signals.r1,
	                              we  => st3_wrbk.signals.rwr,
	                              clk => clk);

	c_decoder : decoder  PORT MAP(instr         => instr,
	                              clk           => clk,
	                              can_skip_wait => '1',
	                              controls      => dec_signals);


	c_r_ip : reg GENERIC MAP(size => 16, def_val => x"FFFF")
	             PORT    MAP(i0 => r_ip.i0, o0 => r_ip.o0, we => r_ip.we, clk => clk);
	c_r_sp : reg GENERIC MAP(size => 16, def_val => x"0000")
	             PORT    MAP(i0 => r_sp.i0, o0 => r_sp.o0, we => r_sp.we, clk => clk);
	c_r_lr : reg GENERIC MAP(size => 16, def_val => x"0000")
	             PORT    MAP(i0 => r_lr.i0, o0 => r_lr.o0, we => r_lr.we, clk => clk);
	c_r_ui : reg GENERIC MAP(size => 16, def_val => x"0000")
	             PORT    MAP(i0 => r_ui.i0, o0 => r_ui.o0, we => r_ui.we, clk => clk);
	--flags must have some initial value
	c_r_fl : reg GENERIC MAP(size => 16, def_val => x"0001") 
	             PORT    MAP(i0 => r_fl.i0, o0 => r_fl.o0, we => r_fl.we, clk => clk);


	c_r_ip_p1 : adder GENERIC MAP(size => 16)
	                  PORT    MAP(i0 => r_ip.o0, i1 => x"0001", ic => '0', o0 => r_ip_p1, oc => OPEN);
	c_r_sp_p2 : adder GENERIC MAP(size => 16)
	                  PORT    MAP(i0 => r_sp.o0, i1 => x"0002", ic => '0', o0 => r_sp_p2, oc => OPEN);
	--2s complement
	c_r_sp_s2 : adder GENERIC MAP(size => 16)
	                  PORT    MAP(i0 => r_sp.o0, i1 => x"FFFE", ic => '0', o0 => r_sp_s2, oc => OPEN);


	--clocks the instruction fetch stage 
	instr <= x"0000" WHEN disable
	    ELSE x"0000" WHEN pipeline_advance = '0' AND rising_edge(clk)
	    ELSE iodata  WHEN rising_edge(clk) 
	    ELSE UNAFFECTED;

	st2_exec <= (signals => SIGNALS_DEFAULT,
	             data    => x"ZZZZ",
	             op0     => x"0000",
	             op1     => x"0000",
	             instr   => x"0000"
	            ) 
	            WHEN st2_branch = '1' AND rising_edge(clk) 
	       ELSE (signals => dec_signals, 
	             data    => x"ZZZZ",
	             op0     => st1_decd_op0,
	             op1     => st1_decd_op1,
	             instr   => instr
	            )
	            WHEN rising_edge(clk)
	       ELSE UNAFFECTED;
	st3_wrbk <= (signals => st2_exec.signals, 
	             data    => result, 
	             --not needed anymore
	             op0     => x"ZZZZ",
	             op1     => x"ZZZZ", 
	             instr   => st2_exec.instr
				)
	            WHEN rising_edge(clk)
	       ELSE UNAFFECTED;
	
	writeback <= st3_wrbk.data;

	WITH st2_exec.signals.src SELECT result <= 
		st2_exec.op1 WHEN "000", --operand		
		ext_out      WHEN "001", --ext
		alu_out      WHEN "010", --alu
		mul_out      WHEN "011", --mul
		iodata       WHEN "100", --mem
		x"DEAD"      WHEN OTHERS;

	WITH st2_exec.signals.x0r SELECT ext_out <= 
	--read from previous as input one is too far 
		r_ip.o0 WHEN "000", 		
		r_sp.o0 WHEN "001", 		
		r_lr.o0 WHEN "010", 		
		r_ui.o0 WHEN "100", 		
		r_fl.o0 WHEN "101", 		
		x"0001" WHEN "111", --cpu flags	
		x"DEAD" WHEN OTHERS;


	st1_decd_op0 <= result    WHEN st2_exec.signals.rwr = '1'
	                           AND dec_signals.src /= "001" --read external
	                           AND st2_exec.signals.r0 = dec_signals.r0
	           ELSE writeback WHEN st3_wrbk.signals.rwr = '1'
	                           AND dec_signals.src /= "001" --read external
	                           AND st3_wrbk.signals.r0 = dec_signals.r0
	           ELSE r0_data;
	--extended immiediate, done during decode
	--when delayed 2 is 0 then 2 cycles earlier there was write which means that everything is shifted
	--in particular that immiediate is now not in input but output of ui
	st1_decd_op1 <= r_ui.i0(7 DOWNTO 0) & dec_signals.imm8 WHEN dec_signals.iim AND pipeline_advance_dl2
	           ELSE r_ui.o0(7 DOWNTO 0) & dec_signals.imm8 WHEN dec_signals.iim 
	           ELSE result    WHEN st2_exec.signals.rwr = '1'
	                           AND st2_exec.signals.r0 = dec_signals.r1
	           ELSE writeback WHEN st3_wrbk.signals.rwr = '1'
	                           AND st3_wrbk.signals.r0 = dec_signals.r1
	           ELSE r1_data;


	op0 <= st2_exec.op0; 
	op1 <= st2_exec.op1;

	--regular branch
	st2_branch <= '1' WHEN st2_exec.signals.jmp AND flcmp
	         ELSE '1' WHEN st2_exec.signals.ret AND flcmp
	         ELSE '1' WHEN st2_exec.signals.cal AND flcmp
	--modification of IP
	         ELSE '1' WHEN st2_exec.signals.xwr = '1' AND st2_exec.signals.x0w = "000"
	         ELSE '0';

	oaddr <= x"ZZZZ" WHEN disable
	    ELSE r_sp_s2 WHEN (st2_exec.signals.psh)
		              AND  NOT pipeline_advance
	    ELSE r_sp.o0 WHEN (st2_exec.signals.pop)
		              AND  NOT pipeline_advance
	    ELSE op1     WHEN (st2_exec.signals.mwr OR st2_exec.signals.mrd)
		              AND  NOT pipeline_advance
	    ELSE r_ip.i0(14 DOWNTO 0) & "0";
	owr   <= 'Z' WHEN disable
	    ELSE st2_exec.signals.mwr AND NOT pipeline_advance;
	ord   <= 'Z' WHEN disable 
	--NOT of owr
	    ELSE NOT st2_exec.signals.mwr OR pipeline_advance;
	iodata <= op0 WHEN st2_exec.signals.mwr AND NOT pipeline_advance
	     ELSE x"ZZZZ";

	--if st2 modifies flags  then the old value is still at output
	ohlt  <= st3_wrbk.signals.hlt WHEN (r_fl.o0(2 DOWNTO 0) AND st3_wrbk.signals.fl) /= "000"
	    ELSE '0';

	--on rising edge they are transfered to next cycle
	pipeline_advance <= '1' WHEN st2_branch = '1'
	               ELSE NOT (dec_signals.mwr OR dec_signals.mrd) WHEN rising_edge(clk)
	               ELSE '1' WHEN pipeline_advance = '0' AND rising_edge(clk) 
	               ELSE UNAFFECTED;
	pipeline_advance_dl1 <= pipeline_advance     WHEN rising_edge(clk);
	pipeline_advance_dl2 <= pipeline_advance_dl1 WHEN rising_edge(clk);


	--check of cal is required to see whether to advance ip and forward stuff
	r_ip.we <= pipeline_advance OR dec_signals.cal; 
	r_sp.we <= '1' WHEN (st2_exec.signals.psh = '1' OR  st2_exec.signals.pop = '1' )
	                 OR (st2_exec.signals.xwr = '1' AND st2_exec.signals.x0w = "001") --wrx
	      ELSE '0';
	r_lr.we <= '1' WHEN (st2_exec.signals.cal = '1' AND flcmp = '1') --cal
	                 OR (st2_exec.signals.xwr = '1' AND st2_exec.signals.x0w = "010") --wrx
	      ELSE '0';
	r_ui.we <= '1';
	r_fl.we <= '1' WHEN  st2_exec.signals.fwr = '1' --wrf
	                 OR (st2_exec.signals.xwr = '1' AND st2_exec.signals.x0w = "101") --wrx
	      ELSE '0';
	--cf is always we = '0'

	flcmp <= '1' WHEN (r_fl.o0(2 DOWNTO 0) AND st2_exec.signals.fl) /= "000" --condflags
	    ELSE '0';

	--write external
	r_ip.i0 <= op1     WHEN  st2_exec.signals.xwr = '1' AND st2_exec.signals.x0w = "000"
	--jmp / cal
	      ELSE op1     WHEN (st2_exec.signals.jmp OR st2_exec.signals.cal) and flcmp
	--ret
	      ELSE r_lr.o0 WHEN  st2_exec.signals.ret AND flcmp
	--next instr
	      ELSE r_ip_p1;

	--write external
	r_sp.i0 <= op1     WHEN st2_exec.signals.xwr = '1' AND st2_exec.signals.x0w = "001"
	--add 2 when pop
	      ELSE r_sp_p2 WHEN st2_exec.signals.pop 
	--sub 2 when push 
	      ELSE r_sp_s2;

	--write external
	r_lr.i0 <= op1       WHEN st2_exec.signals.xwr = '1' AND st2_exec.signals.x0w = "010"
	--save ip from cal
--	      ELSE r_ip_p1   WHEN st2_exec.signals.cal AND flcmp AND (dec_signals.mrd OR dec_signals.mwr) 
	--rare case where due to offset the ip has to use o0
	      ELSE r_ip.o0   WHEN st2_exec.signals.cal AND flcmp	 
	      ELSE UNAFFECTED;
	--write external
	r_ui.i0 <= r_ui.o0   WHEN pipeline_advance_dl2 = '0'
	      ELSE op1       WHEN st2_exec.signals.xwr = '1' AND st2_exec.signals.x0w = "100"
	--zero out
	      ELSE x"0000"; 

	--write external
	r_fl.i0 <= op1     WHEN st2_exec.signals.xwr  = '1' AND st2_exec.signals.x0w = "101"
	--           LEG
	      ELSE x"0004" WHEN result(15) = '1'	 
	      ELSE x"0002" WHEN result = x"0000"
	      ELSE x"0001";


END ARCHITECTURE behav;
