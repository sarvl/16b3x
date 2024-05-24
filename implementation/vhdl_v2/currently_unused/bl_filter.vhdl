LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.p_decode.ALL;
USE work.p_types.ALL;

ENTITY core IS 
	PORT(
		iodata  : INOUT t_rdword;
		oaddr   : OUT   t_rword;
		ord     : OUT   std_logic;
		owr     : OUT   std_logic;

		ohlt    : OUT   std_logic := '0';
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

	COMPONENT reg_file_oooe IS 
		GENERIC(
			count    : integer;
			count_lg : integer
		);
		PORT(
			i00  : IN  t_uword;
			i10  : IN  t_uword;

			o00  : OUT t_uword;
			o01  : OUT t_uword;
			o10  : OUT t_uword;
			o11  : OUT t_uword;

			r0d  : IN  std_ulogic_vector(count_lg - 1 DOWNTO 0);
			r00  : IN  std_ulogic_vector(count_lg - 1 DOWNTO 0);
			r01  : IN  std_ulogic_vector(count_lg - 1 DOWNTO 0);
			r1d  : IN  std_ulogic_vector(count_lg - 1 DOWNTO 0);
			r10  : IN  std_ulogic_vector(count_lg - 1 DOWNTO 0);
			r11  : IN  std_ulogic_vector(count_lg - 1 DOWNTO 0);

			we0  : IN  std_ulogic;
			we1  : IN  std_ulogic;

			clk  : IN  std_ulogic
		);
	END COMPONENT reg_file_oooe;


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
			--if the implementation can use mem bus in the same cycle as it provides instruction
			can_skip_wait : IN std_ulogic;
	
			controls      : OUT t_signals
		);
	END COMPONENT decoder ;

	FUNCTION to_std_ulogic(x : boolean) RETURN std_ulogic IS 
	BEGIN
		IF x THEN
			RETURN '1';
		ELSE
			RETURN '0';
		END IF;
	END FUNCTION to_std_ulogic;



	CONSTANT par_rob_size_lg : integer := 4;
	CONSTANT par_rob_size    : integer := 2 ** par_rob_size_lg;

	CONSTANT par_prf_size_lg : integer := par_rob_size_lg + 1;
	CONSTANT par_prf_size    : integer := par_rob_size    * 2;

	CONSTANT par_rfl_size_lg : integer := par_prf_size_lg; 
	CONSTANT par_rfl_size    : integer := par_prf_size;



	SUBTYPE t_rob_entry_id IS std_ulogic_vector(par_rob_size_lg - 1 DOWNTO 0);
	SUBTYPE t_prf_entry_id IS std_ulogic_vector(par_prf_size_lg - 1 DOWNTO 0);

	--used to group signals from external_regs
	TYPE t_register IS RECORD
		i0 : t_uword;
		o0 : t_uword;
		we : std_ulogic;
	END RECORD t_register;

	TYPE t_rob_entry IS RECORD 
		present    : std_ulogic;
		instr      : t_uword;
		signals    : t_signals;
		
		prfs0_p    : std_ulogic;
		prfs0_id   : t_prf_entry_id;
		
		prfs1_p    : std_ulogic;
		prfs1_id   : t_prf_entry_id;
		
		prfd0_p    : std_ulogic;
		prfd0_id   : t_prf_entry_id;

		prfprev_id : t_prf_entry_id;

		flags      : std_ulogic_vector(2 DOWNTO 0);
		branch          : std_ulogic;
		branch_dest     : std_ulogic;
		branch_alt_dest : t_uword;
		imm16           : t_uword;
		nxt_ip          : t_uword;
		--for now leave out stuff about branch prediction
	END RECORD t_rob_entry;

	CONSTANT ROB_ENTRY_DEFAULT : t_rob_entry := (
			present | prfs0_p | prfs1_p     => '0',
			prfd0_p | branch  | branch_dest => '0',
			instr   | nxt_ip => x"0000",
			prfs0_id | prfs1_id | prfd0_id | prfprev_id => (OTHERS => '0'),
			flags => "000",
		    branch_alt_dest | imm16 => x"0000",  
			signals => SIGNALS_DEFAULT);

	COMPONENT bc_2bit IS 
		PORT(
			i0 : IN  std_ulogic_vector(1 DOWNTO 0);
			ic : IN  std_ulogic; 

			o0 : OUT std_ulogic_vector(1 DOWNTO 0)
		);
	END COMPONENT bc_2bit;

	SIGNAL 	r_ip : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_sp : t_register := (x"0000", x"0000", '0');
	SIGNAL 	r_lr : t_register := (x"0000", x"0000", '0');
	--UI is constantly we so that it is cleared every cycle
	SIGNAL 	r_ui : t_register := (x"0000", x"0000", '1');
	SIGNAL 	r_fl : t_register := (x"0000", x"0000", '0');

	SIGNAL  r_ip_p1 : t_uword := x"0000";
	SIGNAL  r_ip_p2 : t_uword := x"0000";
	SIGNAL  r_sp_p2 : t_uword := x"0000";
	SIGNAL  r_sp_s2 : t_uword := x"0000";

	SIGNAL  signals0 : t_signals := SIGNALS_DEFAULT;
	SIGNAL  signals1 : t_signals := SIGNALS_DEFAULT;
	SIGNAL  instr0   : t_uword := x"0000";
	SIGNAL  instr1   : t_uword := x"0000";

	SIGNAL  instr_ready : std_ulogic := '0';

	TYPE t_rat_entry IS RECORD
		present : std_ulogic;
		transl  : t_prf_entry_id;
		commit  : t_prf_entry_id;
	END RECORD t_rat_entry;

	TYPE t_rob_arr IS ARRAY(par_rob_size - 1 DOWNTO 0) OF t_rob_entry;
	--arch reg 
	TYPE t_rat_arr IS ARRAY(               7 DOWNTO 0) OF t_rat_entry;
	--technically may need present but in practice this is not needed 
	--because it is impossible to use entire list 
	TYPE t_reg_free_arr IS ARRAY(par_rfl_size - 1 DOWNTO 0) OF t_prf_entry_id;
	TYPE t_regs IS ARRAY(7 DOWNTO 0) OF t_uword; 

	SIGNAL  rob : t_rob_arr := (OTHERS => ROB_ENTRY_DEFAULT);

	FUNCTION to_prf_id(i : integer) RETURN std_ulogic_vector IS
	BEGIN
		RETURN std_ulogic_vector(to_unsigned(i, par_prf_size_lg));
	END;

	SIGNAL  rat : t_rat_arr := (0=>(present=>'1',transl|commit=>to_prf_id(0)),
	                            1=>(present=>'1',transl|commit=>to_prf_id(1)),
	                            2=>(present=>'1',transl|commit=>to_prf_id(2)),
	                            3=>(present=>'1',transl|commit=>to_prf_id(3)),
	                            4=>(present=>'1',transl|commit=>to_prf_id(4)),
	                            5=>(present=>'1',transl|commit=>to_prf_id(5)),
	                            6=>(present=>'1',transl|commit=>to_prf_id(6)),
	                            7=>(present=>'1',transl|commit=>to_prf_id(7)));

	--should be generalized somehow
--rob16
	SIGNAL  rfl : t_reg_free_arr := (
		 0 => '0'&x"0",  1 => '0'&x"1",  2 => '0'&x"2",  3 => '0'&x"3", 
		 4 => '0'&x"4",  5 => '0'&x"5",  6 => '0'&x"6",  7 => '0'&x"7",
		 8 => '0'&x"8",  9 => '0'&x"9", 10 => '0'&x"A", 11 => '0'&x"B", 
		12 => '0'&x"C", 13 => '0'&x"D", 14 => '0'&x"E", 15 => '0'&x"F",
		16 => '1'&x"0", 17 => '1'&x"1", 18 => '1'&x"2", 19 => '1'&x"3", 
		20 => '1'&x"4", 21 => '1'&x"5", 22 => '1'&x"6", 23 => '1'&x"7",
		24 => '1'&x"8", 25 => '1'&x"9", 26 => '1'&x"A", 27 => '1'&x"B", 
		28 => '1'&x"C", 29 => '1'&x"D", 30 => '1'&x"E", 31 => '1'&x"F");
--rob08
--	SIGNAL  rfl : t_reg_free_arr := (
--		 0 => x"0",  1 => x"1",  2 => x"2",  3 => x"3", 
--		 4 => x"4",  5 => x"5",  6 => x"6",  7 => x"7",
--		 8 => x"8",  9 => x"9", 10 => x"A", 11 => x"B", 
--		12 => x"C", 13 => x"D", 14 => x"E", 15 => x"F");

	SIGNAL  debug_regs : t_regs := (OTHERS => x"0000");

	--rob start entry
	TYPE t_arr_slv_robs IS ARRAY(integer RANGE <>) OF t_rob_entry_id;
	TYPE t_arr_slv_robf IS ARRAY(integer RANGE <>) OF t_rob_entry_id;
	TYPE t_arr_slv_rfl  IS ARRAY(integer RANGE <>) OF std_ulogic_vector(par_rfl_size_lg - 1 DOWNTO 0);
	TYPE t_arr_int_rob IS ARRAY(integer RANGE <>) OF integer RANGE  par_rob_size - 1 DOWNTO 0;
	TYPE t_arr_int_rfl IS ARRAY(integer RANGE <>) OF integer RANGE par_rfl_size - 1 DOWNTO 0;

	SIGNAL rob_SE : t_arr_slv_robs(0 TO par_rob_size - 1) := (OTHERS => (OTHERS => '0'));

	--rob free entry
	SIGNAL rob_FE : t_arr_slv_robf(0 TO 2) := (OTHERS => (OTHERS => '0'));

	--free reg list start entry
	--later dont matter
	SIGNAL rfl_SE : t_arr_slv_rfl(0 TO 2) := (std_ulogic_vector(to_unsigned(8, par_rfl_size_lg)), OTHERS=>(OTHERS=>'0'));
	--free reg list free entry
	SIGNAL rfl_FE : t_arr_slv_rfl(0 TO 2) := (OTHERS=>(OTHERS=>'0'));

	SIGNAL rfl_SE_com : t_arr_slv_rfl(0 TO 2) := (std_ulogic_vector(to_unsigned(8, par_rfl_size_lg)), OTHERS=>(OTHERS=>'0'));

	SIGNAL rob_SE_i : t_arr_int_rob(0 TO par_rob_size-1);
	--rob free entry
	SIGNAL rob_FE_i : t_arr_int_rob(0 TO 1);
	--free reg list start entry
	SIGNAL rfl_SE_i : t_arr_int_rfl(0 TO 2);
	--free reg list free entry
	SIGNAL rfl_FE_i : t_arr_int_rfl(0 TO 2);

	SIGNAL  rat_0_s0_i     : integer RANGE 7 DOWNTO 0 := 0;
	SIGNAL  rat_0_s1_i     : integer RANGE 7 DOWNTO 0 := 1;
	SIGNAL  rat_0_d0_i     : integer RANGE 7 DOWNTO 0 := 0;
	SIGNAL  rat_1_s0_i     : integer RANGE 7 DOWNTO 0 := 0;
	SIGNAL  rat_1_s1_i     : integer RANGE 7 DOWNTO 0 := 1;
	SIGNAL  rat_1_d0_i     : integer RANGE 7 DOWNTO 0 := 0;

	SIGNAL  can_fetch      : std_ulogic := '1';
	SIGNAL  can_cache      : std_ulogic := '0';

	TYPE t_exec_unit IS RECORD 
		rob_entry : t_rob_entry_id;
		present   : std_logic;
		rd   : t_prf_entry_id;
		res  : t_rword;

		r0   : t_prf_entry_id;
		arg0 : t_rword;
		r1   : t_prf_entry_id;
		arg1 : t_rword;

		imm16  : t_uword;

		signals : t_signals;
	END RECORD t_exec_unit;
	CONSTANT EXEC_UNIT_DEFAULT : t_exec_unit := (
		rob_entry                 => (OTHERS => '0'),
		present                   => '0',
		rd | r0 | r1              => (OTHERS => '0'),
		res | arg0 | arg1 | imm16 => x"ZZZZ",  
		signals                   => SIGNALS_DEFAULT);

	SIGNAL eu0 : t_exec_unit := EXEC_UNIT_DEFAULT;
	SIGNAL eu1 : t_exec_unit := EXEC_UNIT_DEFAULT;
	SIGNAL eu1_mem : std_ulogic := '0';

	SIGNAL alu0_out  : t_uword := x"0000";
	SIGNAL alu1_out  : t_uword := x"0000";
	SIGNAL mul0_out  : t_uword := x"0000";
	SIGNAL mul1_out  : t_uword := x"0000";

	SIGNAL ext_out  : t_uword := x"0000";
	SIGNAL mem_out  : t_uword := x"0000";

	SIGNAL r00_data  : t_uword := x"0000";
	SIGNAL r01_data  : t_uword := x"0000";
	SIGNAL r10_data  : t_uword := x"0000";
	SIGNAL r11_data  : t_uword := x"0000";

	SIGNAL same_dest : std_ulogic := '0';

	SIGNAL s0_branch : std_ulogic := '0';
	SIGNAL s1_branch : std_ulogic := '0';
	SIGNAL branch    : std_ulogic := '0';

	SIGNAL retire0   : std_ulogic := '0';
	SIGNAL retire1   : std_ulogic := '0';

	SIGNAL fetch0    : std_ulogic := '0';
	SIGNAL fetch1    : std_ulogic := '0';

	SIGNAL ignore0      : std_ulogic := '0';
	SIGNAL ignore1      : std_ulogic := '0';

	SIGNAL movrr0       : std_ulogic := '0';
	SIGNAL movrr1       : std_ulogic := '0';

	SIGNAL flcmp     : std_ulogic := '0';

	SIGNAL misprediction : std_ulogic := '0';
	SIGNAL branch_dest   : t_uword := x"0000";
	SIGNAL branch_dest_misalign : std_ulogic := '0';
	SIGNAL branch_dest_misalign_delayed : std_ulogic := '0';

	--always taken for now
	SIGNAL branch_predict_taken : std_ulogic := '1';

	SIGNAL internal_oaddr       : t_uword := x"0000";

	--used to keep value before commit
	--when 2 regs are trying to access it, zero it out

	SIGNAL shadow_ui_present : std_ulogic := '0';
	SIGNAL shadow_ui_value   : t_uword := x"0000";

	SIGNAL shadow_lr_value   : t_uword := x"0000";

	SIGNAL s0_imm16 : t_uword := x"0000";
	SIGNAL s1_imm16 : t_uword := x"0000";

	SIGNAL prf_present : std_ulogic_vector(par_prf_size - 1 DOWNTO 0) := (OTHERS=>'1');

	SIGNAL flush : std_ulogic := '0';
	SIGNAL flush_additional_wait : std_ulogic := '0';


	--bloom filter used to detect whether particular memory address has instruction 
	--if so, flush the machine as one of the instructions executed may be wrong
	--occasionally definitely false positive
	SIGNAL b_filter : std_ulogic_vector(255 DOWNTO 0) := (OTHERS => '0');
	SIGNAL write_to_instr : std_ulogic := '0';

	SIGNAL b_mem_filter : std_ulogic_vector(255 DOWNTO 0) := (OTHERS => '0');
	SIGNAL write_read_conflict : std_ulogic := '0';

	SIGNAL cur_ip    : t_uword := x"0000";
	SIGNAL cur_ip_p1 : t_uword := x"0000";

	SIGNAL prev_eu1_mem : std_ulogic := '0';
	SIGNAL prev_branch  : std_ulogic := '0';
	SIGNAL prev_flush   : std_ulogic := '0';
	SIGNAL prev_flush_ui: std_ulogic := '0';
	SIGNAL prev_cache   : std_ulogic := '0';

	SIGNAL cnt_misprediction : integer := 0;
	SIGNAL cnt_fetch         : integer := 0;
	SIGNAL cnt_cache         : integer := 0;
	SIGNAL cnt_retire2       : integer := 0;
	SIGNAL cnt_retire1       : integer := 0;
	SIGNAL cnt_retire0       : integer := 0;
	SIGNAL cnt_exec2         : integer := 0;
	SIGNAL cnt_exec1         : integer := 0;
	SIGNAL cnt_exec0         : integer := 0;
	SIGNAL cnt_movrr         : integer := 0;
	SIGNAL cnt_ignore        : integer := 0;
	SIGNAL cnt_instr         : integer := 0;
	SIGNAL cnt_cyc           : integer := 0;
	SIGNAL cnt_flush         : integer := 0;
	SIGNAL cnt_robful        : integer := 0;
	SIGNAL cnt_w2iflush      : integer := 0;
	SIGNAL cnt_wrcflush      : integer := 0;

	TYPE t_bp_arr IS ARRAY(15 DOWNTO 0) OF std_ulogic_vector(1 DOWNTO 0); 
	--because of heruistics from simulator, it is better to start from T than NT
	SIGNAL bp_arr : t_bp_arr := (OTHERS => "11");

	SIGNAL bp_arr_match        : std_ulogic_vector(1 DOWNTO 0);
	SIGNAL bp_arr_match_to_inc : std_ulogic_vector(1 DOWNTO 0);
	SIGNAL bp_arr_match_new    : std_ulogic_vector(1 DOWNTO 0);

	TYPE t_ras IS ARRAY(3 DOWNTO 0) OF t_uword;
	SIGNAL ras : t_ras := (OTHERS => x"0000");
	SIGNAL ras_top_m1   : std_ulogic_vector(1 DOWNTO 0) := "11";
	SIGNAL ras_top_p0   : std_ulogic_vector(1 DOWNTO 0) := "00";
	SIGNAL ras_top_p1   : std_ulogic_vector(1 DOWNTO 0) := "01";
	SIGNAL ras_top_m1_i : integer := 3; 
	SIGNAL ras_top_p0_i : integer := 0; 
	SIGNAL ras_top_p1_i : integer := 1; 

	SIGNAL prfs0_id   : std_ulogic_vector(par_prf_size_lg-1 DOWNTO 0);
	SIGNAL prfs1_id   : std_ulogic_vector(par_prf_size_lg-1 DOWNTO 0);
	SIGNAL prfd0_id   : std_ulogic_vector(par_prf_size_lg-1 DOWNTO 0);
	SIGNAL prfprev_id : std_ulogic_vector(par_prf_size_lg-1 DOWNTO 0);


	TYPE t_cache_entry IS RECORD 
		present : std_ulogic;
		tag     : std_ulogic_vector( 9 DOWNTO 0);
		data    : std_ulogic_vector(31 DOWNTO 0);
	END RECORD t_cache_entry;
	CONSTANT cache_entry_default : t_cache_entry := (present => '0', tag => (OTHERS => '0'), data => (OTHERS => '0'));

	TYPE t_cache IS ARRAY(15 DOWNTO 0) OF t_cache_entry;

	SIGNAL cache : t_cache := (OTHERS => cache_entry_default);
	SIGNAL cache_addr : integer := 0;
	SIGNAL cache_data : std_ulogic_vector(31 DOWNTO 0);

	SIGNAL cache_hit : std_ulogic := '0';



	SIGNAL feature_cache   : std_ulogic := '1';
	SIGNAL feature_w2iprot : std_ulogic := '1';

BEGIN
	
	c_decoder0 : decoder  PORT MAP(instr         => instr0,
	                               clk           => clk,
	                               can_skip_wait => '1',
	                               controls      => signals0);
	c_decoder1 : decoder  PORT MAP(instr         => instr1,
	                               clk           => clk,
	                               can_skip_wait => '1',
	                               controls      => signals1);

	c_regfile  : reg_file_oooe GENERIC MAP(count    => par_rob_size * 2, 
	                                       count_lg => par_rob_size_lg + 1)
	                           PORT MAP(r0d => eu0.rd,
	                                    i00 => eu0.res,
	                                    r00 => eu0.r0, 
	                                    o00 => r00_data,
	                                    r01 => eu0.r1,
	                                    o01 => r01_data,
	                                    we0 => eu0.signals.rwr AND eu0.present,
	                                    r1d => eu1.rd,
	                                    i10 => eu1.res,
	                                    r10 => eu1.r0, 
	                                    o10 => r10_data,
	                                    r11 => eu1.r1,
	                                    o11 => r11_data,
	                                    we1 => eu1.signals.rwr AND eu1.present,
	                                    clk => clk); 

	c_alu0     : alu PORT MAP(i0 => eu0.arg0,
	                          i1 => eu0.arg1,
	                          o0 => alu0_out,
	                          op => eu0.signals.aluop); 
	c_alu1     : alu PORT MAP(i0 => eu1.arg0,
	                          i1 => eu1.arg1,
	                          o0 => alu1_out,
	                          op => eu1.signals.aluop); 
	c_mul0     : multiplier GENERIC MAP(size => 16)
	                        PORT MAP(i0 => eu0.arg0,
	                                 i1 => eu0.arg1,
	                                 o0 => mul0_out);
	c_mul1     : multiplier GENERIC MAP(size => 16)
	                        PORT MAP(i0 => eu1.arg0,
	                                 i1 => eu1.arg1,
	                                 o0 => mul1_out);


	c_r_ip : reg GENERIC MAP(size => 16, def_val => x"FFFE")
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
	c_r_ip_p2 : adder GENERIC MAP(size => 16)
	                  PORT    MAP(i0 => r_ip.o0, i1 => x"0002", ic => '0', o0 => r_ip_p2, oc => OPEN);
	c_r_sp_p2 : adder GENERIC MAP(size => 16)
	                  PORT    MAP(i0 => r_sp.o0, i1 => x"0002", ic => '0', o0 => r_sp_p2, oc => OPEN);
	--2s complement
	c_r_sp_s2 : adder GENERIC MAP(size => 16)
	                  PORT    MAP(i0 => r_sp.o0, i1 => x"FFFE", ic => '0', o0 => r_sp_s2, oc => OPEN);

	cur_ip_p1 <= rob(rob_SE_i(0)).nxt_ip;
	--subtracts 1 from rob(0).ip 
	c_cur_ip  : adder GENERIC MAP(size => 16)
	                  PORT    MAP(i0 => cur_ip_p1, i1 => x"FFFF", ic => '0', o0 => cur_ip, oc => OPEN);


	--not needed
--	c_rse_adder_0 : adder GENERIC MAP(size=>par_rob_size_lg) PORT MAP(i0=>rob_SE(0),i1=>"000",o0=>rob_SE(0),ic=>'0',oc=>OPEN);
	u3: FOR i IN 1 TO par_rob_size - 1 GENERATE
		c: adder GENERIC MAP(size=>par_rob_size_lg)
		         PORT    MAP(i0=>rob_SE(0),i1=>std_ulogic_vector(to_unsigned(i, par_rob_size_lg)),o0=>rob_SE(i),ic=>'0',oc=>OPEN);
	END GENERATE u3;

	--not needed
--	c_rfe_adder_0 : adder GENERIC MAP(size=>par_rob_size_lg) PORT MAP(i0=>rob_FE(0),i1=>"000",o0=>rob_FE(0),ic=>'0',oc=>OPEN);
--	c_rfl_adder_0 : adder GENERIC MAP(size=>4) PORT MAP(i0=>rfl_SE(0),i1=>"0000",o0=>rfl_SE(0),ic=>'0',oc=>OPEN);
--	c_rfl_adder_3 : adder GENERIC MAP(size=>4) PORT MAP(i0=>rfl_FE(0),i1=>"0000",o0=>rfl_FE(0),ic=>'0',oc=>OPEN);
--	c_rfl_adder_6 : adder GENERIC MAP(size=>4) PORT MAP(i0=>rfl_SE_com(0),i1=>"0000",o0=>rfl_SE_com(0),ic=>'0',oc=>OPEN);

	u4: FOR i IN 1 TO 2 GENERATE
		c_rfe_adder : adder GENERIC MAP(size=>par_rob_size_lg) 
		                    PORT    MAP(i0=>rob_FE(0),i1=>std_ulogic_vector(to_unsigned(i, par_rob_size_lg)),o0=>rob_FE(i),ic=>'0',oc=>OPEN);
		c_rfl_adder0: adder GENERIC MAP(size=>par_rfl_size_lg)
		                    PORT    MAP(i0=>rfl_SE(0),i1=>std_ulogic_vector(to_unsigned(i, par_rfl_size_lg)),o0=>rfl_SE(i),ic=>'0',oc=>OPEN);
		c_rfl_adder1: adder GENERIC MAP(size=>par_rfl_size_lg) 
		                    PORT    MAP(i0=>rfl_FE(0),i1=>std_ulogic_vector(to_unsigned(i, par_rfl_size_lg)),o0=>rfl_FE(i),ic=>'0',oc=>OPEN);
		c_rfl_adder2: adder GENERIC MAP(size=>par_rfl_size_lg)
		                    PORT    MAP(i0=>rfl_SE_com(0),i1=>std_ulogic_vector(to_unsigned(i, par_rfl_size_lg)),o0=>rfl_SE_com(i),ic=>'0',oc=>OPEN);
	END GENERATE u4;

	--convert all slvs into ints
	u0: FOR i IN 0 TO par_rob_size - 1 GENERATE
		rob_SE_i(i) <= to_integer(unsigned(rob_SE(i)));
	END GENERATE u0;
	u1: FOR i IN 0 TO 1 GENERATE
		rob_FE_i(i) <= to_integer(unsigned(rob_FE(i)));
	END GENERATE u1;
	u2: FOR i IN 0 TO 2 GENERATE
		rfl_SE_i(i) <= to_integer(unsigned(rfl_SE(i)));
		rfl_FE_i(i) <= to_integer(unsigned(rfl_FE(i)));
	END GENERATE u2;

	rat_0_s0_i <= to_integer(unsigned(signals0.r0));
	rat_0_s1_i <= to_integer(unsigned(signals0.r1));
	rat_0_d0_i <= to_integer(unsigned(signals0.r0));

	rat_1_s0_i <= to_integer(unsigned(signals1.r0));
	rat_1_s1_i <= to_integer(unsigned(signals1.r1));
	rat_1_d0_i <= to_integer(unsigned(signals1.r0));

	c_bp : bc_2bit PORT MAP(i0 => bp_arr_match_to_inc, ic => flcmp, o0 => bp_arr_match_new);
	
	--not needed
--	c_ras_adder_0 : adder GENERIC MAP(size => 2) PORT MAP(i0=>ras_top_p0,i1=>"00",o0=>ras_top_p0,ic=>'0',oc=>OPEN); 
	c_ras_adder_1 : adder GENERIC MAP(size => 2) PORT MAP(i0=>ras_top_p0,i1=>"01",o0=>ras_top_p1,ic=>'0',oc=>OPEN); 
	c_ras_adder_2 : adder GENERIC MAP(size => 2) PORT MAP(i0=>ras_top_p0,i1=>"11",o0=>ras_top_m1,ic=>'0',oc=>OPEN); 

	ras_top_p0_i <= to_integer(unsigned(ras_top_p0));
	ras_top_p1_i <= to_integer(unsigned(ras_top_p1));
	ras_top_m1_i <= to_integer(unsigned(ras_top_m1));

	rob_FE(0) <= (OTHERS=>'0') WHEN flush = '1' 
	                            AND rising_edge(clk)
	--rob_FE_i(1) not present implies rob_FE_i(0) not present
	        ELSE rob_FE(2)     WHEN fetch0 AND NOT ignore0
	                            AND fetch1 AND NOT ignore1
	                            AND instr_ready AND to_std_ulogic(rising_edge(clk))
	        ELSE rob_FE(1)     WHEN fetch0 AND NOT ignore0
	                            AND instr_ready AND to_std_ulogic(rising_edge(clk))
			ELSE rob_FE(1)     WHEN fetch0 AND     ignore0
				                AND fetch1 AND NOT ignore1
	                            AND instr_ready AND to_std_ulogic(rising_edge(clk))


	        ELSE rob_FE(0);

	--not necessary but looks better 
	rob_SE(0) <= (OTHERS=>'0') WHEN flush = '1' 
	                            AND rising_edge(clk)
	--retire1 implies retire0
	        ELSE rob_SE(2)     WHEN retire1 = '1' AND rising_edge(clk) 
	        ELSE rob_SE(1)     WHEN retire0 = '1' AND rising_edge(clk) 
	        ELSE rob_SE(0);

	--no instruction that writes to reg can cause flush 
	rfl_SE(0) <= rfl_SE_com(0) WHEN  flush = '1' AND rising_edge(clk)
	--when both instructions write to reg 
	        ELSE rfl_SE(0)     WHEN  s0_branch = '1' AND branch_predict_taken = '1'
	                            AND  instr_ready = '1'
	                            AND  rising_edge(clk) 
	        ELSE rfl_SE(2)     WHEN (signals0.rwr = '1' AND signals1.rwr = '1')
	                            AND  instr_ready = '1'
	                            AND  rising_edge(clk)
	        ELSE rfl_SE(1)     WHEN (signals0.rwr = '1' XOR signals1.rwr = '1')
	                            AND  instr_ready = '1'
	                            AND  rising_edge(clk)
	        ELSE rfl_SE(0);

	--present, finished and writing
	rfl_FE(0) <= rfl_FE(2) WHEN rising_edge(clk)
	                        AND retire0 = '1' AND retire1 = '1'
	                        AND rob(rob_SE_i(0)).signals.rwr = '1'
	                        AND rob(rob_SE_i(1)).signals.rwr = '1'
	        ELSE rfl_FE(1) WHEN rising_edge(clk)
	                        AND retire0 = '1' 
	                        AND rob(rob_SE_i(0)).signals.rwr = '1'
	        ELSE rfl_FE(1) WHEN rising_edge(clk)
	                        AND retire1 = '1'
	                        AND rob(rob_SE_i(1)).signals.rwr = '1'
	        ELSE rfl_FE(0);

	rfl_SE_com(0) <= rfl_SE_com(2) WHEN rising_edge(clk)
	                                AND retire0 = '1' AND rob(rob_SE_i(0)).signals.rwr = '1'
	                                AND retire1 = '1' AND rob(rob_SE_i(1)).signals.rwr = '1'
	            ELSE rfl_SE_com(1) WHEN rising_edge(clk)
	                                AND retire0 = '1' AND rob(rob_SE_i(0)).signals.rwr = '1'
	            ELSE rfl_SE_com(1) WHEN rising_edge(clk)
	                                AND retire1 = '1' AND rob(rob_SE_i(1)).signals.rwr = '1'
	            ELSE rfl_SE_com(0);

	eu0.arg0 <= r00_data; 
	eu0.arg1 <= eu0.imm16 WHEN eu0.signals.iim
	       ELSE r01_data;
	eu1.arg0 <= r10_data; 
	eu1.arg1 <= eu1.imm16 WHEN eu1.signals.iim
	       ELSE r11_data;

	--DEAD indicates that this value must NEVER occur 
	--otherwise there is some kind of mistake 
	WITH eu0.signals.x0r SELECT ext_out <= 
	--uses the fact that this instr is first to retire but should change
		rob(rob_SE_i(0)).nxt_ip WHEN "000", 		
		r_sp.o0                 WHEN "001", 		
		r_lr.o0                 WHEN "010", 		
		r_ui.o0                 WHEN "100", 		
		r_fl.o0                 WHEN "101", 		
		x"0001"                 WHEN "111", --cpu flags	
		x"DEAD"                 WHEN OTHERS;

	WITH eu0.signals.src SELECT eu0.res <= 
		eu0.arg1 WHEN "000", --operand		
		ext_out  WHEN "001", --ext
		alu0_out WHEN "010", --alu
		mul0_out WHEN "011", --mul
		x"DEAD"  WHEN "100", --mem
		x"DEAD"  WHEN OTHERS;
	WITH eu1.signals.src SELECT eu1.res <= 
		eu1.arg1 WHEN "000", --operand		
		x"DEAD"  WHEN "001", --ext
		alu1_out WHEN "010", --alu
		mul1_out WHEN "011", --mul
		mem_out  WHEN "100", --mem
		x"DEAD"  WHEN OTHERS;

	mem_out <= iodata(31 DOWNTO 16) WHEN NOT internal_oaddr(1)
	      ELSE iodata(15 DOWNTO  0);

	same_dest <=  signals0.rwr AND signals1.rwr AND to_std_ulogic(signals0.r0 = signals1.r0);
	s0_branch <= (signals0.jmp OR signals0.cal OR signals0.ret) AND NOT (prev_eu1_mem AND prev_flush);
	s1_branch <= (signals1.jmp OR signals1.cal OR signals1.ret) AND NOT (prev_eu1_mem AND prev_flush);

	bp_arr_match <= bp_arr(to_integer(unsigned(r_ip.o0(3 DOWNTO 0)))) WHEN signals0.jmp 
	           ELSE bp_arr(to_integer(unsigned(r_ip_p1(3 DOWNTO 0)))); 
	--incorrect for signals1.jmp 
	bp_arr_match_to_inc <= bp_arr(to_integer(unsigned(cur_ip(3 DOWNTO 0)))); 
	bp_arr(to_integer(unsigned(cur_ip(3 DOWNTO 0)))) <= bp_arr_match_new WHEN rob(rob_SE_i(0)).signals.jmp = '1' AND rising_edge(clk)
	                                               ELSE UNAFFECTED;

	--may break when 2 branches are fetched at once and predicted to be not taken 
	branch               <= misprediction OR s0_branch OR s1_branch; 

	--                        ret           
	branch_predict_taken <=  (signals0.ret) 
	--                        cal             jmp CCC            jmp LEG 
	                     OR ((signals0.cal OR bp_arr_match(1) OR to_std_ulogic(signals0.fl = "111")) AND signals0.iim) 
	                         WHEN s0_branch 
	                   ELSE  (signals1.ret) 
	                     OR ((signals1.cal OR bp_arr_match(1) OR to_std_ulogic(signals1.fl = "111")) AND signals1.iim) 
	                         WHEN s1_branch 
	                   ELSE '0'; 
	--due to hard to get address, predict indirect ones as not taken, ALWAYS

	flcmp  <= to_std_ulogic((r_fl.o0(2 DOWNTO 0) AND rob(rob_SE_i(0)).signals.fl) /= "000");
	--whenever branch is retired it is definitely in slot 0 
	misprediction <= retire0 AND rob(rob_SE_i(0)).branch
	--flcmp does not agree
	             AND (  to_std_ulogic(flcmp /= rob(rob_SE_i(0)).branch_dest)
	--addr in ret does not agree
	                 OR to_std_ulogic(rob(rob_SE_i(0)).signals.ret      = '1' 
	                              AND rob(rob_SE_i(0)).branch_dest      = '1' 
	                              AND rob(rob_SE_i(0)).branch_alt_dest /= r_lr.o0)
	                 );


	branch_dest <= r_lr.o0                          WHEN misprediction AND     flcmp AND rob(rob_SE_i(0)).signals.ret
	          ELSE cur_ip_p1                        WHEN misprediction AND NOT flcmp AND rob(rob_SE_i(0)).signals.ret
	          ELSE rob(rob_SE_i(0)).branch_alt_dest WHEN misprediction AND     flcmp 
	          ELSE rob(rob_SE_i(0)).nxt_ip          WHEN misprediction AND NOT flcmp 
			  --may break
	          ELSE rob(rob_SE_i(0)).nxt_ip          WHEN flush_additional_wait --for more general flushes
	          ELSE rob(rob_SE_i(0)).nxt_ip          WHEN flush --for more general flushes
	--ret always predict taken
	          ELSE shadow_lr_value                  WHEN s0_branch AND signals0.ret 
	          ELSE s0_imm16                         WHEN s0_branch AND branch_predict_taken
	--only 1 branch is handled in a single cycle, therefore if both are branches and predict not taken, other must wait
	          ELSE r_ip_p1                          WHEN s0_branch AND s1_branch 
	          ELSE r_ip_p2                          WHEN s0_branch              
	          ELSE shadow_lr_value                  WHEN s1_branch AND signals1.ret 
	          ELSE s1_imm16                         WHEN s1_branch AND branch_predict_taken
	          ELSE r_ip_p2;
	 --if LSB ithen it is misaligned
	branch_dest_misalign <= branch_dest(0);
	branch_dest_misalign_delayed <= branch_dest_misalign WHEN rising_edge(clk)
	                           ELSE UNAFFECTED;

	retire0 <=             rob(rob_SE_i(0)).present AND rob(rob_SE_i(0)).prfd0_p;
	retire1 <= retire0 AND rob(rob_SE_i(1)).present AND rob(rob_SE_i(1)).prfd0_p
	--cannot retire 2 branches in the same cycle and branch must be first thing to retire due to how misprediction is determined
	                   AND NOT rob(rob_SE_i(1)).branch
	                   AND NOT misprediction 
	--cannot retire halt with anything in the same cycle
	                   AND NOT rob(rob_SE_i(0)).signals.hlt
	                   AND NOT rob(rob_SE_i(1)).signals.hlt
	                   ;


	--when 3 b_filter entries say that this addr was seen then it probably was seen
	--but more important is that when it was seen then b_filter will say that it was seen
	write_to_instr <= feature_w2iprot
	              AND b_filter(to_integer(unsigned(internal_oaddr( 7 DOWNTO  0))))
	              AND b_filter(to_integer(unsigned(internal_oaddr(15 DOWNTO  8))))
	              AND b_filter(to_integer(unsigned(internal_oaddr(11 DOWNTO  4))))
	             WHEN eu1.signals.mwr
	             ELSE '0'; 
	
	write_read_conflict <= '1'
	                   AND b_mem_filter(to_integer(unsigned(internal_oaddr( 7 DOWNTO  0))))
	                   AND b_mem_filter(to_integer(unsigned(internal_oaddr(15 DOWNTO  8))))
	                   AND b_mem_filter(to_integer(unsigned(internal_oaddr(11 DOWNTO  4))))
	                  WHEN eu1.signals.mwr
	                  ELSE '0'; 


	--both fetched at once so 2 entries must be free 
	--simplifies things
	fetch0 <= NOT rob(rob_FE_i(0)).present AND NOT rob(rob_FE_i(1)).present AND instr_ready;
	--        fetch0      prev is not branch     or if it is then it must be predict not taken and current must not be a branch 
	fetch1 <= fetch0 AND (NOT s0_branch OR (NOT branch_predict_taken AND NOT s1_branch));


	--nop
	ignore0   <= '1' WHEN instr0 = x"0000" AND fetch0 = '1'
	--wrx UI, imm   AND next is fetched AND next is not rdx UI 
	        ELSE '1' WHEN signals0.xwr  = '1' AND signals0.x0w = "100" AND signals0.iim = '1'
	                  AND fetch1        = '1' 
	                  AND signals1.src /= "001" --less logic and it is unlikely to have eg wrx UI,v followed by rdx LR 
	        ELSE '0';
	--nop
	ignore1   <= to_std_ulogic(instr1 = x"0000" AND fetch1 = '1');

	movrr0    <= to_std_ulogic(signals0.rwr = '1' AND signals0.src = "000" AND signals0.iim = '0' AND fetch0 = '1');
	movrr1    <= to_std_ulogic(signals1.rwr = '1' AND signals1.src = "000" AND signals1.iim = '0' AND fetch1 = '1');

	s0_imm16 <= r_ui.o0(7 DOWNTO 0)         & signals0.imm8 WHEN prev_flush_ui AND NOT branch_dest_misalign_delayed
	       ELSE shadow_ui_value(7 DOWNTO 0) & signals0.imm8 WHEN shadow_ui_present
	       ELSE x"00"                       & signals0.imm8;

	s1_imm16 <= r_ui.o0(7 DOWNTO 0)         & signals1.imm8 WHEN prev_flush_ui AND     branch_dest_misalign_delayed
	       ELSE signals0.imm8               & signals1.imm8 WHEN signals0.xwr = '1' AND signals0.x0w = "100" AND signals0.iim = '1' 
	       ELSE x"00"                       & signals1.imm8;

	shadow_ui_present <= '1' WHEN flush = '0' 
	                          AND fetch1 = '1' 
	                          AND signals1.xwr = '1' AND signals1.x0w = "100" AND signals1.iim = '1'
	                          AND (s0_branch    = '0'  OR branch_predict_taken = '0') 
	                          AND  instr_ready  = '1' AND rising_edge(clk) 
	                ELSE '0' WHEN  instr_ready  = '1' AND rising_edge(clk) 
	                ELSE UNAFFECTED;
	shadow_ui_value   <= x"00" & signals1.imm8 WHEN  fetch1 = '1'
	                                            AND signals1.xwr = '1' AND signals1.x0w = "100" 
	                                            AND (s0_branch    = '0'  OR branch_predict_taken = '0') 
	                                            AND  instr_ready  = '1' AND rising_edge(clk) 
	                ELSE x"DEAD"               WHEN  instr_ready  = '1' AND rising_edge(clk) 
	                ELSE UNAFFECTED;


	ras(ras_top_p1_i) <= r_ip_p2 WHEN fetch1 = '1' AND signals1.cal = '1' AND rising_edge(clk)
	                ELSE r_ip_p1 WHEN fetch0 = '1' AND signals0.cal = '1' AND rising_edge(clk)
	                ELSE UNAFFECTED;

	ras_top_p0        <= ras_top_p1 WHEN  fetch1 = '1' AND signals1.cal = '1' AND rising_edge(clk)
	                ELSE ras_top_p1 WHEN  fetch0 = '1' AND signals0.cal = '1' AND rising_edge(clk)
	                ELSE ras_top_m1 WHEN  fetch1 = '1' AND signals1.ret = '1' AND rising_edge(clk)
	                ELSE ras_top_m1 WHEN  fetch0 = '1' AND signals0.ret = '1' AND rising_edge(clk)
	                ELSE UNAFFECTED;

--	shadow_lr_value   <= x"0000";
--	shadow_lr_value   <= ras(ras_top_p0_i);
	shadow_lr_value   <= r_ip_p2 WHEN signals1.cal = '1' AND rising_edge(clk)
	                ELSE r_ip_p1 WHEN signals0.cal = '1' AND rising_edge(clk)
	                ELSE UNAFFECTED;
	

	--bad instructions loaded
	flush <= misprediction
	--self modifying code
	      OR write_to_instr
	--write to loc that was read from
	      OR write_read_conflict 
	--potentially bad instructions executing because writing reg to UI means that next values could not be computed 
	      OR to_std_ulogic(eu0.signals.xwr = '1' AND eu0.signals.x0w = "100" AND eu0.signals.iim = '0');

	prev_flush_ui <= to_std_ulogic(eu0.signals.xwr = '1' AND eu0.signals.x0w = "100" AND eu0.signals.iim = '0') WHEN rising_edge(clk)
	            ELSE UNAFFECTED;

	flush_additional_wait <= to_std_ulogic(eu0.signals.xwr = '1' AND eu0.signals.x0w = "100" AND eu0.signals.iim = '0');


	prev_eu1_mem <= eu1_mem   WHEN rising_edge(clk)
	           ELSE UNAFFECTED;
	prev_branch  <= branch    WHEN rising_edge(clk)
	           ELSE UNAFFECTED;
	prev_flush   <= flush     WHEN rising_edge(clk)
	           ELSE UNAFFECTED;

	prev_cache   <= can_cache WHEN rising_edge(clk)
	           ELSE UNAFFECTED;


	--bloom filter
	PROCESS (ALL) IS 
	BEGIN
		IF rising_edge(clk) THEN 
			IF flush THEN
				b_filter     <= (OTHERS => '0');
				b_mem_filter <= (OTHERS => '0');
			ELSE
				--current ip marks isntructions
				b_filter(to_integer(unsigned(r_ip.i0( 7 DOWNTO  0)))) <= '1';
				b_filter(to_integer(unsigned(r_ip.i0(15 DOWNTO  8)))) <= '1';
				b_filter(to_integer(unsigned(r_ip.i0(11 DOWNTO  4)))) <= '1';


				IF eu1.signals.mrd THEN  
					b_mem_filter(to_integer(unsigned(internal_oaddr( 7 DOWNTO  0)))) <= '1';
					b_mem_filter(to_integer(unsigned(internal_oaddr(15 DOWNTO  8)))) <= '1';
					b_mem_filter(to_integer(unsigned(internal_oaddr(11 DOWNTO  4)))) <= '1';
				END IF;
			END IF;
		END IF;
	END PROCESS;



	--these tests should also incorporate additional decisions like checking whether R0 really is register in that instruction
	--eg jmp LEG has R0 = 0b111 but does not care about R0
	--can be done at once with the check whether r0 really needs to be a dependency
	--like in a case of mov r0, r1 ; mov r0, r2
	--if instr0 writes to instr1.r0 forward dep
	prfs0_id   <= rfl(rfl_SE_i(0)) WHEN to_std_ulogic(signals0.r0 = signals1.r0) AND signals0.rwr
			 ELSE rat(rat_1_s0_i).transl; 
	--if instr0 writes to instr1.r1 forward dep
	prfs1_id   <= rfl(rfl_SE_i(0)) WHEN to_std_ulogic(signals0.r0 = signals1.r1) AND signals0.rwr
			 ELSE rat(rat_1_s1_i).transl; 
	--correctly choose free register in case only 1 writes
	prfd0_id   <= rfl(rfl_SE_i(1)) WHEN signals0.rwr
			 ELSE rfl(rfl_SE_i(0)); 
	--correctly choose prev register dep in case both write to the same one
	prfprev_id <= rfl(rfl_SE_i(0)) WHEN same_dest 
			 ELSE rat(rat_1_d0_i).transl;

	--in order:
	--retire finished entries
	--insert entries into rob
	PROCESS (ALL) IS

		VARIABLE branch_alt_dest : t_uword := x"0000";

		VARIABLE rob_fetch_0 : t_rob_entry;
		VARIABLE rob_fetch_1 : t_rob_entry;

	BEGIN
		IF rising_edge(clk) THEN 
			FOR i IN 0 TO 7 LOOP
				FOR j IN i + 1 TO 7 LOOP
					--never the same since that implies total mess and unpredictable behavior
					ASSERT rat(i).transl /= rat(j).transl
						REPORT "FATAL ERROR: RAT ENTRIES " & integer'image(i) & " " & integer'image(j) & " HAVE THE SAME TRANSLATION" & LF
						SEVERITY failure;

				END LOOP;
			END LOOP;
		END IF;


		ASSERT r_ip.o0(0) = '0' 
			REPORT "FATAL ERROR: IP IS NOT EVEN" & LF
			SEVERITY failure;

		IF rising_edge(clk) AND flush = '1' THEN 
			FOR i IN 0 TO par_rob_size - 1 LOOP
				rob(i) <= ROB_ENTRY_DEFAULT;
			END LOOP;

			FOR i IN 0 TO 7 LOOP
				--NOT A MISTAKE
				rat(i) <= ('1', rat(i).commit, rat(i).commit);
			END LOOP;

			--there is no need to fix the RFL as it is not in an invalid state
			--to put reg on an RFL it had to be used as prev_reg AND retired
			--that means something overwrote ArchReg 
			--so only things that are not mapped to arch reg are in RFL

		ELSE 
			--when predict taken, next ip 
			branch_alt_dest := shadow_lr_value WHEN s0_branch AND signals0.ret  
			              ELSE shadow_lr_value WHEN s1_branch AND signals1.ret  
			              ELSE s0_imm16        WHEN s0_branch
			              ELSE s1_imm16        WHEN s1_branch
			              ELSE x"DEAD";

			--finish execution
			IF rising_edge(clk) THEN
				IF eu0.present THEN
					rob(to_integer(unsigned(eu0.rob_entry))).prfd0_p <= '1';
					rob(to_integer(unsigned(eu0.rob_entry))).flags <= "100" WHEN eu0.res(15) = '1'	 
	      			                                             ELSE "010" WHEN eu0.res = x"0000"
	      			                                             ELSE "001";

					rob(to_integer(unsigned(eu0.rob_entry))).branch_alt_dest <= eu0.res;

					--trivial dependency management
					FOR i IN 0 TO par_rob_size - 1 LOOP 
						rob(i).prfs0_p <= '1' WHEN rob(i).present = '1' AND rob(i).prfs0_id = eu0.rd AND eu0.signals.rwr = '1' ELSE UNAFFECTED;
						rob(i).prfs1_p <= '1' WHEN rob(i).present = '1' AND rob(i).prfs1_id = eu0.rd AND eu0.signals.rwr = '1' ELSE UNAFFECTED;
					END LOOP; 
					prf_present(to_integer(unsigned(eu0.rd))) <= '1' WHEN eu0.signals.rwr ELSE UNAFFECTED;
--					rat(to_integer(unsigned(eu0.signals.r0))).present <= '1';
				END IF;
				IF eu1.present THEN
					rob(to_integer(unsigned(eu1.rob_entry))).prfd0_p <= '1';
					rob(to_integer(unsigned(eu1.rob_entry))).flags <= "100" WHEN eu1.res(15) = '1'	 
	      			                                             ELSE "010" WHEN eu1.res = x"0000"
	      			                                             ELSE "001";

					rob(to_integer(unsigned(eu1.rob_entry))).branch_alt_dest <= eu1.res;

					--trivial dependency management
					FOR i IN 0 TO par_rob_size - 1 LOOP 
						rob(i).prfs0_p <= '1' WHEN rob(i).present = '1' AND rob(i).prfs0_id = eu1.rd  AND eu1.signals.rwr = '1' ELSE UNAFFECTED;
						rob(i).prfs1_p <= '1' WHEN rob(i).present = '1' AND rob(i).prfs1_id = eu1.rd  AND eu1.signals.rwr = '1' ELSE UNAFFECTED;
					END LOOP; 
					prf_present(to_integer(unsigned(eu1.rd))) <= '1' WHEN eu1.signals.rwr ELSE UNAFFECTED;
--					rat(to_integer(unsigned(eu1.signals.r0))).present <= '1';
				END IF;
			END IF;


			--retire finished instructions
			IF rising_edge(clk) THEN

				IF retire0 THEN
					IF rob(rob_SE_i(0)).signals.rwr THEN
						rfl(rfl_FE_i(0)) <= rob(rob_SE_i(0)).prfprev_id;

						--if next instr does not retire 
						IF  retire1 = '0'
						--or if does not write
						OR  rob(rob_SE_i(1)).signals.rwr = '0'
						--or does not write to the same reg 
						OR  rob(rob_SE_i(1)).signals.r0 /= rob(rob_SE_i(0)).signals.r0
						--then change rat to commited
						THEN
							rat(to_integer(unsigned(rob(rob_SE_i(0)).signals.r0))).commit <= rob(rob_SE_i(0)).prfd0_id;
						END IF;

						
					END IF;

					IF rob(rob_SE_i(0)).signals.mwr THEN
						--handled near memory related stuff at the bottom
					END IF;
					rob(rob_SE_i(0)) <= ROB_ENTRY_DEFAULT;
				END IF;

				IF retire1 THEN
					IF    rob(rob_SE_i(0)).signals.rwr 
					  AND rob(rob_SE_i(1)).signals.rwr 
					THEN
						rfl(rfl_FE_i(1)) <= rob(rob_SE_i(1)).prfprev_id;
						rat(to_integer(unsigned(rob(rob_SE_i(1)).signals.r0))).commit <= rob(rob_SE_i(1)).prfd0_id;
					ELSIF rob(rob_SE_i(1)).signals.rwr
					THEN
						rat(to_integer(unsigned(rob(rob_SE_i(1)).signals.r0))).commit <= rob(rob_SE_i(1)).prfd0_id;
						rfl(rfl_FE_i(0)) <= rob(rob_SE_i(1)).prfprev_id;
					END IF;


					rob(rob_SE_i(1)) <= ROB_ENTRY_DEFAULT;
				END IF;
			END IF;

			--insert new instructions
			IF rising_edge(clk) AND instr_ready = '1' THEN 
				
				--case when two destinations are the same and both are writing is different
				rob_fetch_0 := (present         => '1' , 
							    instr           => instr0,
							    signals         => signals0,
							    -- is where it should OR something writes to it right now  
							    prfs0_p         => prf_present(to_integer(unsigned(rat(rat_0_s0_i).transl)))
							       			    OR (to_std_ulogic(eu0.rd = rat(rat_0_s0_i).transl) AND eu0.signals.rwr AND eu0.present) 
							       			    OR (to_std_ulogic(eu1.rd = rat(rat_0_s0_i).transl) AND eu1.signals.rwr AND eu1.present), 
							    prfs0_id        => rat(rat_0_s0_i).transl, 
							    -- same as prfs0_p 
							    prfs1_p         => prf_present(to_integer(unsigned(rat(rat_0_s1_i).transl))) OR signals0.iim
							       			    OR (to_std_ulogic(eu0.rd = rat(rat_0_s1_i).transl) AND eu0.signals.rwr AND eu0.present) 
							       			    OR (to_std_ulogic(eu1.rd = rat(rat_0_s1_i).transl) AND eu1.signals.rwr AND eu1.present), 
							    prfs1_id        => rat(rat_0_s1_i).transl, 
							    -- indirect jumps must not have the result present 
							    prfd0_p         => NOT signals0.rwr 
							                   AND NOT signals0.mwr 
							                   AND NOT signals0.fwr 
							                   AND NOT signals0.xwr 
							    -- execute will always put data to branch_alt_dest 
							                   AND NOT (s0_branch AND NOT signals0.iim), 
							    prfd0_id        => rfl(rfl_SE_i(0)), 
							    prfprev_id      => rat(rat_0_d0_i).transl,
							    imm16           => s0_imm16, 
							    nxt_ip          => r_ip_p1,  
							    flags           => "000",
							    branch          => s0_branch,
							    branch_dest     => branch_predict_taken,
							    branch_alt_dest => branch_alt_dest); 

				rob_fetch_1 := (present         => '1' , 
						        instr           => instr1,
						        signals         => signals1,
						        prfs0_p         => (prf_present(to_integer(unsigned(rat(rat_1_s0_i).transl))) AND (to_std_ulogic(signals0.r0 /= signals1.r0) OR NOT signals0.rwr)) 
						           			    OR (to_std_ulogic(eu0.rd = prfs0_id) AND eu0.signals.rwr AND eu0.present) 
						           			    OR (to_std_ulogic(eu1.rd = prfs0_id) AND eu1.signals.rwr AND eu1.present), 
						        prfs0_id        => prfs0_id, 
						        prfs1_p         => signals1.iim 
						           			    OR (prf_present(to_integer(unsigned(rat(rat_1_s1_i).transl))) AND (to_std_ulogic(signals0.r0 /= signals1.r1) OR NOT signals0.rwr))
						           			    OR (to_std_ulogic(eu0.rd = prfs1_id) AND eu0.signals.rwr AND eu0.present) 
						           			    OR (to_std_ulogic(eu1.rd = prfs1_id) AND eu1.signals.rwr AND eu1.present), 
						        --points to previous instruction if it writes to r1 
						        prfs1_id        => prfs1_id,
						        prfd0_p         => NOT signals1.rwr 
						                       AND NOT signals1.mwr 
						                       AND NOT signals1.fwr 
						                       AND NOT signals1.xwr 
						        -- execute will always put data to branch_alt_dest 
						                       AND NOT (s1_branch AND NOT signals1.iim), 
						        prfd0_id        => prfd0_id, 
						        prfprev_id      => prfprev_id, 
						        imm16           => s1_imm16, 
						        nxt_ip          => r_ip_p2,  
						        flags           => "000",
						        branch          => s1_branch,
						        branch_dest     => branch_predict_taken,
						        branch_alt_dest => branch_alt_dest);


				rob(rob_FE_i(0)) <= rob_fetch_0 WHEN fetch0 AND NOT ignore0
				               ELSE rob_fetch_1 WHEN fetch0 AND     ignore0
				                                 AND fetch1 AND NOT ignore1
				               ELSE UNAFFECTED;
				rob(rob_FE_i(1)) <= rob_fetch_1 WHEN fetch0 AND NOT ignore0
				                                 AND fetch1 AND NOT ignore1 
				               ELSE UNAFFECTED;


				--now change the mapping
				--highly likely that it fails because the conditions are different 
				--FOR FUCKS SAKE

				IF fetch0 AND fetch1 AND signals0.rwr AND signals1.rwr AND NOT (s0_branch AND branch_predict_taken) AND NOT ignore0 AND NOT ignore1 THEN
					prf_present(to_integer(unsigned(rfl(rfl_SE_i(0))))) <= '0';
--					rat(rat_0_d0_i).present <= '0';
					rat(rat_0_d0_i).transl  <= rfl(rfl_SE_i(0));
					prf_present(to_integer(unsigned(prfd0_id))) <= '0';
--					rat(rat_1_d0_i).present <= '0';
					rat(rat_1_d0_i).transl  <= prfd0_id; 

				--only one catches 
				ELSIF fetch0 AND signals0.rwr THEN 
					prf_present(to_integer(unsigned(rfl(rfl_SE_i(0))))) <= '0';
					rat(rat_0_d0_i).transl  <= rfl(rfl_SE_i(0));

				ELSIF fetch0 AND ignore0 AND fetch1 AND signals1.rwr THEN 
					prf_present(to_integer(unsigned(prfd0_id))) <= '0';
					rat(rat_1_d0_i).transl  <= prfd0_id;

				ELSIF fetch1 AND signals1.rwr AND  NOT (s0_branch AND branch_predict_taken) THEN 
					prf_present(to_integer(unsigned(prfd0_id))) <= '0';
					rat(rat_1_d0_i).transl  <= prfd0_id;

				END IF;
			END IF; --rob




		END IF; --flush
	END PROCESS;
	
	PROCESS(ALL) IS 
		VARIABLE found0 : boolean := false;
		VARIABLE found1 : boolean := false;
	BEGIN
		IF rising_edge(clk) AND flush = '1' THEN 
			eu0 <= EXEC_UNIT_DEFAULT;
			eu1 <= EXEC_UNIT_DEFAULT;
		ELSE

			found0 := false;
			found1 := false;
			--there is no need to check whether eu is free to execute
			--if it is not then it just got thing to do and is currently executing something
			
			--first one may not use the first one in case it does not have to execute at all
			--and it was just added so there is no need to execute it 
			--ie NOP or mov
			--choose first in program order that can be used
			FOR i IN 0 TO par_rob_size - 1 LOOP
				IF        rob(rob_SE_i(i)).present     AND     rob(rob_SE_i(i)).prfs0_p
				  AND     rob(rob_SE_i(i)).prfs1_p     AND NOT rob(rob_SE_i(i)).prfd0_p 
				  AND NOT rob(rob_SE_i(i)).signals.mwr AND NOT rob(rob_SE_i(i)).signals.mrd
				  --only 1st can read or write external
				  AND    (to_std_ulogic(i = 0) OR NOT (rob(rob_SE_i(i)).signals.xwr OR to_std_ulogic(rob(rob_SE_i(i)).signals.src = "001"))) --xrd
				THEN 
					eu0 <= (rob_entry=>rob_SE(i),present=> '1',rd=>rob(rob_SE_i(i)).prfd0_id,
							r0=>rob(rob_SE_i(i)).prfs0_id,r1=>rob(rob_SE_i(i)).prfs1_id,
							signals=>rob(rob_SE_i(i)).signals,arg0|arg1|res => x"ZZZZ",
							imm16 => rob(rob_SE_i(i)).imm16);

					found0 := true;
					EXIT;
				END IF;
			END LOOP;

			IF NOT found0 THEN
				eu0 <= (rob_entry=>(OTHERS=>'0'),rd|r0|r1=>(OTHERS=>'0'),present=> '0',
						signals=>SIGNALS_DEFAULT,arg0|arg1|res|imm16 => x"ZZZZ");
			END IF;

			--first try to do mem operations as they are usually quite high and are a bottleneck
			--when i can go higher than 1, memory ordering fuckups are expected
			FOR i IN 0 TO 0 LOOP
				IF    rob(rob_SE_i(i)).present     AND     rob(rob_SE_i(i)).prfs0_p
				  AND rob(rob_SE_i(i)).prfs1_p     AND NOT rob(rob_SE_i(i)).prfd0_p 
				  AND (rob(rob_SE_i(i)).signals.mrd OR     rob(rob_SE_i(i)).signals.mwr)
				THEN
					eu1_mem <= '1';
					eu1 <= (rob_entry=>rob_SE(i),present=> '1',rd=>rob(rob_SE_i(i)).prfd0_id,
							r0=>rob(rob_SE_i(i)).prfs0_id,r1=>rob(rob_SE_i(i)).prfs1_id,
							signals=>rob(rob_SE_i(i)).signals,arg0|arg1|res => x"ZZZZ",
							imm16 => rob(rob_SE_i(i)).imm16);

					found1 := true;
					EXIT;
				END IF;
			END LOOP;
			--execute out of order, when problem detected fix later
			IF NOT found1 THEN
				FOR i IN 1 TO par_rob_size - 1 LOOP
					IF    rob(rob_SE_i(i)).present     AND     rob(rob_SE_i(i)).prfs0_p
					  AND rob(rob_SE_i(i)).prfs1_p     AND NOT rob(rob_SE_i(i)).prfd0_p 
				  	  AND rob(rob_SE_i(i)).signals.mrd
				  	  AND NOT rob(rob_SE_i(i)).signals.pop
				  	  AND NOT misprediction 
					THEN
						eu1_mem <= '1';
						eu1 <= (rob_entry=>rob_SE(i),present=> '1',rd=>rob(rob_SE_i(i)).prfd0_id,
								r0=>rob(rob_SE_i(i)).prfs0_id,r1=>rob(rob_SE_i(i)).prfs1_id,
								signals=>rob(rob_SE_i(i)).signals,arg0|arg1|res => x"ZZZZ",
								imm16 => rob(rob_SE_i(i)).imm16);

						found1 := true;
						EXIT;
					END IF;
				END LOOP;
			END IF;

			--second one must watch out for the conflict with the first one
			--however second one can never use first rob entry as if it was free the first eu would use it 
			--one less check then
			--choose first in program order that is not used by eu0 (aka second in program order)
			IF NOT found1 THEN
				FOR i IN 1 TO par_rob_size - 1 LOOP 
					IF        rob(rob_SE_i(i)).present     AND     rob(rob_SE_i(i)).prfs0_p
					  AND     rob(rob_SE_i(i)).prfs1_p     AND NOT rob(rob_SE_i(i)).prfd0_p 
					  AND NOT rob(rob_SE_i(i)).signals.mrd AND NOT rob(rob_SE_i(i)).signals.mwr
					  AND NOT rob(rob_SE_i(i)).signals.xwr AND NOT to_std_ulogic(rob(rob_SE_i(i)).signals.src = "001") --xrd
					  AND to_std_ulogic(eu0.rob_entry /= rob_SE(i))
					THEN 
						eu1_mem <= '0';
						eu1 <= (rob_entry=>rob_SE(i),present=> '1',rd=>rob(rob_SE_i(i)).prfd0_id,
								r0=>rob(rob_SE_i(i)).prfs0_id,r1=>rob(rob_SE_i(i)).prfs1_id,
								signals=>rob(rob_SE_i(i)).signals,arg0|arg1|res => x"ZZZZ",
								imm16 => rob(rob_SE_i(i)).imm16);

						found1 := true;
						EXIT;
					END IF;
				END LOOP;
			END IF;

			IF NOT found1 THEN 
				eu1_mem <= '0';
				eu1 <= (rob_entry=>(OTHERS=>'0'),rd|r0|r1=>(OTHERS=>'0'),present=> '0',
						signals=>SIGNALS_DEFAULT,arg0|arg1|res|imm16 => x"ZZZZ");
			END IF;
		END IF; --flush
	END PROCESS;

	--cache
	cache_addr        <= to_integer(unsigned(r_ip.i0(4 DOWNTO 1)));

	--otherwise, oscilation happens on clock edge which cannot possibly happen because of cache delay
	cache_data        <= cache(cache_addr).data;
	cache_hit         <= cache(cache_addr).present AND to_std_ulogic(cache(cache_addr).tag = r_ip.i0(14 DOWNTO 5));

	PROCESS(clk) IS 
	BEGIN 
		IF rising_edge(clk) THEN
			IF write_to_instr OR write_read_conflict THEN
				FOR i IN 0 TO cache'length - 1 LOOP
					cache(i) <= cache_entry_default;
				END LOOP;
			ELSIF can_fetch AND NOT cache_hit THEN
				cache(cache_addr) <= (present => '1', tag => r_ip.i0(14 DOWNTO 5), data => iodata);
			END IF;
		END IF;
	END PROCESS;
	
	ord <= 'Z' WHEN disable 
	  ELSE eu1.signals.mrd WHEN eu1_mem
	  ELSE can_fetch AND NOT can_cache; 
	owr <= 'Z' WHEN disable
	  ELSE eu1.signals.mwr WHEN eu1_mem
	  ELSE '0';

	iodata <= (OTHERS => 'Z')    WHEN disable 
	--      next 2 depend on alignment 
	     ELSE x"ZZZZ" & eu1.arg0 WHEN eu1_mem AND eu1.signals.mwr AND     internal_oaddr(1) 
	     ELSE eu1.arg0 & x"ZZZZ" WHEN eu1_mem AND eu1.signals.mwr AND NOT internal_oaddr(1) 
	     ELSE (OTHERS => 'Z');

	--aligned
	instr0 <= x"0000"                  WHEN flush = '1'     AND branch_dest_misalign = '1'                        AND rising_edge(clk)
	     ELSE x"0000"                  WHEN branch = '1'    AND branch_dest_misalign = '1' AND instr_ready  = '1' AND rising_edge(clk)
	     ELSE cache_data(31 DOWNTO 16) WHEN can_cache = '1'                                AND rising_edge(clk)
	     ELSE iodata(31 DOWNTO 16)     WHEN can_fetch = '1'                                AND rising_edge(clk)
	     ELSE UNAFFECTED;

	--not aligned 
	instr1 <= cache_data(15 DOWNTO  0) WHEN can_cache = '1' AND rising_edge(clk)
	     ELSE iodata(15 DOWNTO  0)     WHEN can_fetch = '1' AND rising_edge(clk)
	     ELSE UNAFFECTED;

	instr_ready <= '0' WHEN prev_eu1_mem AND prev_flush
	          ELSE can_fetch OR can_cache; 

	internal_oaddr <= x"ZZZZ"  WHEN disable
	             ELSE r_sp_s2  WHEN eu1.signals.psh
	             ELSE r_sp.o0  WHEN eu1.signals.pop
	             ELSE eu1.arg1 WHEN eu1_mem
	             ELSE r_ip.i0(14 DOWNTO 0) & "0"; --shift left
	oaddr <= internal_oaddr;

	can_fetch <= (NOT eu1_mem AND NOT rob(rob_FE_i(1)).present)
	          OR (flush AND NOT (write_to_instr OR write_read_conflict));
	can_cache <= feature_cache
	         AND cache_hit AND NOT rob(rob_FE_i(1)).present
	         AND NOT flush AND NOT write_to_instr AND NOT write_read_conflict;


	--fetch only when place for 1 
	r_ip.we <= can_fetch OR flush OR can_cache; 
	--only rob0 matters because cal is branch
	r_lr.we <= (rob(rob_SE_i(0)).signals.cal AND (retire0 AND flcmp)) 
	        OR to_std_ulogic(eu0.signals.xwr = '1' AND eu0.signals.x0w = "010");
	r_fl.we <= '1' WHEN eu0.signals.xwr = '1' AND eu0.signals.x0w = "101"
	      ELSE (retire0 AND rob(rob_SE_i(0)).signals.fwr)
	        OR (retire1 AND rob(rob_SE_i(1)).signals.fwr);

	--serialized anyway due to memory op
	r_sp.we <= '1' WHEN retire0 AND (rob(rob_SE_i(0)).signals.pop OR rob(rob_SE_i(0)).signals.psh)
	      ELSE '1' WHEN eu0.signals.xwr = '1' AND eu0.signals.x0w = "001"
	      ELSE '0';


	r_sp.i0 <= eu0.arg1 WHEN eu0.signals.xwr = '1' AND eu0.signals.x0w = "001"
	      ELSE r_sp_p2  WHEN rob(rob_SE_i(0)).signals.pop AND retire0
	      ELSE r_sp_s2  WHEN rob(rob_SE_i(0)).signals.psh AND retire0
	      ELSE r_sp.o0; --whatever really

	--guarantee ip is even
	r_ip.i0 <= branch_dest(15 DOWNTO 1) & '0' WHEN flush OR branch
	      ELSE r_ip_p2                        WHEN prev_eu1_mem AND prev_branch AND prev_cache
	      ELSE r_ip.o0                        WHEN prev_eu1_mem AND prev_branch
	      ELSE r_ip.o0                        WHEN prev_eu1_mem AND prev_flush
--	      ELSE r_ip.o0                        WHEN s0_branch AND s1_branch  AND NOT branch_predict_taken
	      ELSE branch_dest(15 DOWNTO 1) & '0' WHEN (s0_branch OR s1_branch) AND branch_predict_taken

	      ELSE r_ip_p2;

	r_ui.we <= to_std_ulogic(   (eu0.signals.xwr = '1' AND eu0.signals.x0w = "100")
	                         OR (retire0 = '1' AND NOT (rob(rob_SE_i(0)).signals.xwr = '1' AND rob(rob_SE_i(0)).signals.x0w = "100"))); 
	r_ui.i0 <= eu0.arg1 WHEN eu0.signals.xwr = '1' AND eu0.signals.x0w = "100"
	      ELSE x"0000"; 

	r_lr.i0 <= eu0.arg1 WHEN eu0.signals.xwr = '1' AND eu0.signals.x0w = "010"
	      ELSE cur_ip_p1; 

	--second has priority because it is later in program order
	--r_fl_we handles correct signals condition
	r_fl.i0 <= eu0.arg1 WHEN eu0.signals.xwr = '1' AND eu0.signals.x0w = "101"
	      ELSE x"000" & "0" & rob(rob_SE_i(1)).flags WHEN retire1 AND rob(rob_SE_i(1)).signals.fwr 
	      ELSE x"000" & "0" & rob(rob_SE_i(0)).flags; 


	--hlt must be the only instr retired 
	PROCESS (clk) IS 
		VARIABLE ipc : real;
	BEGIN
		IF rising_edge(clk) THEN
			cnt_misprediction <= cnt_misprediction + 1 WHEN misprediction
			                ELSE UNAFFECTED;
			cnt_fetch         <= cnt_fetch         + 1 WHEN can_fetch AND NOT can_cache 
			                ELSE UNAFFECTED;
			cnt_cache         <= cnt_cache         + 1 WHEN can_cache
			                ELSE UNAFFECTED;
			cnt_retire2       <= cnt_retire2       + 1 WHEN retire0 AND retire1 
			                ELSE UNAFFECTED;
			cnt_retire1       <= cnt_retire1       + 1 WHEN retire0 AND NOT retire1
			                ELSE UNAFFECTED;
			cnt_retire0       <= cnt_retire0       + 1 WHEN NOT retire0
			                ELSE UNAFFECTED;
			cnt_exec2         <= cnt_exec2         + 1 WHEN eu0.present AND eu1.present 
			                ELSE UNAFFECTED;
			cnt_exec1         <= cnt_exec1         + 1 WHEN eu0.present XOR eu1.present
			                ELSE UNAFFECTED;
			cnt_exec0         <= cnt_exec0         + 1 WHEN eu0.present NOR eu1.present 
			                ELSE UNAFFECTED;
			cnt_movrr         <= cnt_movrr         + 2 WHEN movrr0 AND movrr1 
			                ELSE cnt_movrr         + 1 WHEN movrr0 XOR movrr1 
			                ELSE UNAFFECTED;
			cnt_ignore        <= cnt_ignore        + 2 WHEN ignore0 AND ignore1
			                ELSE cnt_ignore        + 1 WHEN ignore0 XOR ignore1
			                ELSE UNAFFECTED; 

			cnt_instr         <= cnt_instr         + 2 WHEN retire0 AND retire1
			                ELSE cnt_instr         + 1 WHEN retire0 AND NOT retire1
			                ELSE UNAFFECTED;
			cnt_flush         <= cnt_flush         + 1 WHEN flush
			                ELSE UNAFFECTED;
			cnt_w2iflush      <= cnt_w2iflush      + 1 WHEN write_to_instr
			                ELSE UNAFFECTED;
			cnt_wrcflush      <= cnt_wrcflush      + 1 WHEN write_read_conflict
			                ELSE UNAFFECTED;
			cnt_robful        <= cnt_robful        + 1 WHEN rob(rob_FE_i(1)).present
			                ELSE UNAFFECTED;

			cnt_cyc           <= cnt_cyc           + 1;


			IF  rob(rob_SE_i(0)).present     
			AND rob(rob_SE_i(0)).signals.hlt 
			AND flcmp
			THEN 
				ohlt <= '1';

				ipc := real(cnt_instr) / real(cnt_cyc);

				REPORT LF  
					& LF & "count miss   : " & integer'image(cnt_misprediction)
					& LF & "count fetch  : " & integer'image(cnt_fetch        )
					& LF & "count cache  : " & integer'image(cnt_cache        )
					& LF & "count retire0: " & integer'image(cnt_retire0      )
					& LF & "count retire1: " & integer'image(cnt_retire1      )
					& LF & "count retire2: " & integer'image(cnt_retire2      )
					& LF & "count exec0  : " & integer'image(cnt_exec0        )
					& LF & "count exec1  : " & integer'image(cnt_exec1        )
					& LF & "count exec2  : " & integer'image(cnt_exec2        )
					& LF & "count movrr  : " & integer'image(cnt_movrr        )
					& LF & "count ignore : " & integer'image(cnt_ignore       )
					& LF & "count flush  : " & integer'image(cnt_flush        )
					& LF & "count w2i    : " & integer'image(cnt_w2iflush     )
					& LF & "count wrc    : " & integer'image(cnt_wrcflush     )
					& LF & "count robfull: " & integer'image(cnt_robful       )
					& LF & "count instr  : " & integer'image(cnt_instr        )
					& LF 
					--trim string
--					& LF & "IPC          : " & (real'image(ipc)(1 TO 4))
					& LF;
				REPORT LF
					& LF & "R0: " & integer'image(to_integer(unsigned(debug_regs(0))))
					& LF & "R1: " & integer'image(to_integer(unsigned(debug_regs(1))))
					& LF & "R2: " & integer'image(to_integer(unsigned(debug_regs(2))))
					& LF & "R3: " & integer'image(to_integer(unsigned(debug_regs(3))))
					& LF & "R4: " & integer'image(to_integer(unsigned(debug_regs(4))))
					& LF & "R5: " & integer'image(to_integer(unsigned(debug_regs(5))))
					& LF & "R6: " & integer'image(to_integer(unsigned(debug_regs(6))))
					& LF & "R7: " & integer'image(to_integer(unsigned(debug_regs(7))))
				    & LF;
			ELSE
				ohlt <= '0';
			END IF;
		END IF;
	END PROCESS;

	PROCESS IS 
		ALIAS reg_data IS <<SIGNAL c_regfile.data : t_reg_arr>>;
	BEGIN
		WAIT ON clk;
		FOR i IN 0 TO 7 LOOP
			debug_regs(i) <= reg_data(to_integer(unsigned(rat(i).commit)));
		END LOOP;
	END PROCESS;

END ARCHITECTURE behav;
