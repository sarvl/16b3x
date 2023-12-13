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


	SIGNAL writeback : t_uword;
	SIGNAL r0_data : t_uword;
	SIGNAL r1_data : t_uword;

	--always is the same anyway
	ALIAS  op0     : t_uword IS r0_data;
	SIGNAL op1     : t_uword;

	SIGNAL alu_out : t_uword;
	SIGNAL mul_out : t_uword;
	SIGNAL ext_out : t_uword;

	SIGNAL 	r_ip : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_sp : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_lr : t_register := (x"0000", x"0000", '0');
	--UI is constantly we so that it is cleared every cycle
	SIGNAL 	r_ui : t_register := (x"0000", x"0000", '1');
	SIGNAL 	r_fl : t_register := (x"0000", x"0000", '0');

	SIGNAL  r_ip_p1 : t_uword;
	SIGNAL  r_sp_p2 : t_uword;
	SIGNAL  r_sp_s2 : t_uword;

	SIGNAL  flcmp   : std_ulogic;

	SIGNAL  signals : t_signals;
	SIGNAL  instr   : t_uword := x"0000";

BEGIN
	
	--assume control required control signals are present
	c_alu : ALU PORT MAP(i0 => op0,
	                     i1 => op1,
	                     o0 => alu_out,
	                     op => signals.aluop);
	c_mul : multiplier GENERIC MAP(size => 16)
	                   PORT    MAP(i0 => op0,
	                               i1 => op1,
	                               o0 => mul_out);
	
	c_regfile : reg_file PORT MAP(i0  => writeback,
	                              o0  => r0_data,
	                              o1  => r1_data,
	                              rd  => signals.r0,
	                              r0  => signals.r0,
	                              r1  => signals.r1,
	                              we  => signals.rwr,
	                              clk => clk);
	
	c_decoder : decoder  PORT MAP(instr         => instr,
	                              clk           => clk,
	                              can_skip_wait => '0',
	                              controls      => signals);

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

	
	WITH signals.src SELECT writeback <= 
		op1     WHEN "000", --operand		
		ext_out WHEN "001", --ext
		alu_out WHEN "010", --alu
		mul_out WHEN "011", --mul
		iodata  WHEN "100", --mem
		x"DEAD" WHEN OTHERS;

	WITH signals.x0r SELECT ext_out <= 
		r_ip.i0 WHEN "000", 		
		r_sp.o0 WHEN "001", 		
		r_lr.o0 WHEN "010", 		
		r_ui.o0 WHEN "100", 		
		r_fl.o0 WHEN "101", 		
		x"0001" WHEN "111", --cpu flags	
		x"DEAD" WHEN OTHERS;
	
	--extended immiediate
	op1 <= r_ui.o0(7 DOWNTO 0) & signals.imm8 WHEN signals.iim 
	  ELSE r1_data;

	ord <= 'Z' WHEN disable 
	  ELSE NOT signals.mwr; --signals.mrd;
	owr <= 'Z' WHEN disable
	  ELSE signals.mwr;

	ohlt <= signals.hlt WHEN flcmp
	   ELSE '0';

	iodata <= x"ZZZZ" WHEN disable 
	     ELSE op0 WHEN signals.mwr 
	     ELSE x"ZZZZ";

	instr <= iodata WHEN signals.cycadv = '1' AND rising_edge(clk)
	    ELSE UNAFFECTED; 

	oaddr  <= x"ZZZZ" WHEN disable
	     ELSE r_sp_s2 WHEN signals.psh
	     ELSE r_sp.o0 WHEN signals.pop 
	     ELSE op1     WHEN signals.mrd OR signals.mwr 
	     ELSE r_ip.i0(14 DOWNTO 0) & "0"; --shift left


	r_ip.we <= '1' WHEN  signals.cycadv --next instr
	      ELSE '0';
	r_sp.we <= '1' WHEN (signals.psh = '1' OR signals.pop = '1' )
	                 OR (signals.xwr = '1' AND signals.x0w = "001") --wrx
	      ELSE '0';
	r_lr.we <= '1' WHEN (signals.cal = '1' AND flcmp = '1') --cal
	                 OR (signals.xwr = '1' AND signals.x0w = "010") --wrx
	      ELSE '0';
	/*
		UI always has WE='1'
	*/
	r_fl.we <= '1' WHEN  signals.fwr = '1' --wrf
	                 OR (signals.xwr = '1' AND signals.x0w = "101") --wrx
	      ELSE '0';
	/*
		CF always has WE='0'
	*/


	flcmp <= '1' WHEN (r_fl.o0(2 DOWNTO 0) AND signals.fl) /= "000" --condflags
	    ELSE '0';

	--write external
	r_ip.i0 <= writeback WHEN  signals.xwr = '1' AND signals.x0w = "000"
	--jmp / cal
	      ELSE op1       WHEN (signals.jmp OR signals.cal) AND flcmp
	--ret
	      ELSE r_lr.o0   WHEN  signals.ret AND flcmp
	--next instr
	      ELSE r_ip_p1;

	--write external
	r_sp.i0 <= writeback WHEN signals.xwr = '1' AND signals.x0w = "001"
	--add 2 when pop
	      ELSE r_sp_p2 WHEN signals.pop 
	--sub 2 when push 
	      ELSE r_sp_s2;

	--write external
	r_lr.i0 <= writeback WHEN signals.xwr = '1' AND signals.x0w = "010"
	--save ip from cal
	      ELSE r_ip_p1   WHEN signals.cal AND flcmp	 
	      ELSE UNAFFECTED;

	--write external
	r_ui.i0 <= writeback WHEN signals.xwr = '1' AND signals.x0w = "100"
	--zero out
	      ELSE x"0000"; 

	--write external
	r_fl.i0 <= writeback WHEN signals.xwr  = '1' AND signals.x0w = "101"
	--           LEG
	      ELSE x"0004" WHEN writeback(15) = '1'	 
	      ELSE x"0002" WHEN writeback = x"0000"
	      ELSE x"0001";


END ARCHITECTURE behav;
