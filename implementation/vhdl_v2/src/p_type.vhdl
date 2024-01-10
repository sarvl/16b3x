LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE p_types IS 
	SUBTYPE t_word  IS std_ulogic_vector(15 DOWNTO 0);
	SUBTYPE t_uword IS std_ulogic_vector(15 DOWNTO 0);
	SUBTYPE t_rword IS std_logic_vector (15 DOWNTO 0);

	SUBTYPE t_dword  IS std_ulogic_vector(31 DOWNTO 0);
	SUBTYPE t_udword IS std_ulogic_vector(31 DOWNTO 0);
	SUBTYPE t_rdword IS std_logic_vector (31 DOWNTO 0);

	TYPE t_cache_entry IS RECORD 
		present : std_ulogic;
		dirty   : std_ulogic;
		tag     : std_ulogic_vector(7 DOWNTO 0);
		data    : t_rword;
	END RECORD t_cache_entry;

	TYPE t_mem_arr IS ARRAY(32768 - 1 DOWNTO 0) OF t_uword;
	TYPE t_mem_wide_arr IS ARRAY(16384 - 1 DOWNTO 0) OF t_udword;
	--subarray
	TYPE t_csh_sar IS ARRAY(  2 - 1 DOWNTO 0)   OF t_cache_entry;
	TYPE t_csh_arr IS ARRAY(128 - 1 DOWNTO 0)   OF t_csh_sar;

	TYPE t_reg_arr IS ARRAY(natural RANGE<>)    OF t_uword;
END PACKAGE p_types;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE p_decode IS
	TYPE t_signals IS RECORD
		aluop  : std_ulogic_vector(2 DOWNTO 0);

		r0     : std_ulogic_vector(2 DOWNTO 0);
		r1     : std_ulogic_vector(2 DOWNTO 0);
		imm8   : std_ulogic_vector(7 DOWNTO 0);

		--duplicates of r0
		x0w    : std_ulogic_vector(2 DOWNTO 0);
		fl     : std_ulogic_vector(2 DOWNTO 0);

		
		x0r    : std_ulogic_vector(2 DOWNTO 0);

		src    : std_ulogic_vector(2 DOWNTO 0);

		rwr    : std_ulogic;
		xwr    : std_ulogic;
		mwr    : std_ulogic;

		mrd    : std_ulogic;
		fwr    : std_ulogic;

		iim    : std_ulogic;

		psh    : std_ulogic;
		pop    : std_ulogic;

		jmp    : std_ulogic;
		cal    : std_ulogic;
		ret    : std_ulogic;

		hlt    : std_ulogic;
		cycadv : std_ulogic;
	END RECORD t_signals;


	CONSTANT SIGNALS_DEFAULT : t_signals := 
		(
			aluop | r0 | r1 | x0r | x0w | fl | src  => "000", 
			imm8 => x"00",	
			rwr | xwr | mwr | mrd | fwr | iim | psh => '0',
			jmp | cal | ret | hlt | pop => '0',
			cycadv => '0'
		);
END PACKAGE p_decode;
