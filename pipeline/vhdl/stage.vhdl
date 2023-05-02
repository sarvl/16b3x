LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY stage IS
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
		ihlt : IN  std_logic;
		iiim : IN  std_logic;
		isre : IN  std_logic;
		iext : IN  std_logic_vector(15 DOWNTO 0);

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
		oiim : OUT std_logic;
		osre : OUT std_logic;
		oext : OUT std_logic_vector(15 DOWNTO 0));
END ENTITY stage;


ARCHITECTURE behav OF stage IS 

	COMPONENT reg_16bit IS 
		PORT(
			i0  : IN  std_logic_vector(15 DOWNTO 0);
			o0  : OUT std_logic_vector(15 DOWNTO 0);
			
			we  : IN  std_logic;
			clk : IN  std_logic);
	END COMPONENT reg_16bit;

	COMPONENT reg_defon IS 
		PORT(
			i0  : IN  std_logic;
			o0  : OUT std_logic := '1';
	
			we  : IN  std_logic;
			clk : IN  std_logic);
	END COMPONENT reg_defon;

	SIGNAL bundled_in  : std_logic_vector(31 DOWNTO 0);
	SIGNAL bundled_out : std_logic_vector(31 DOWNTO 0);

BEGIN

	bundled_in( 0) <= ir0(0);
	bundled_in( 1) <= ir0(1);
	bundled_in( 2) <= ir0(2);

	bundled_in( 3) <= ir1(0);
	bundled_in( 4) <= ir1(1);
	bundled_in( 5) <= ir1(2);
	
	bundled_in( 6) <= iflg(0);
	bundled_in( 7) <= iflg(1);
	bundled_in( 8) <= iflg(2);

	bundled_in( 9) <= ialu_op(0);
	bundled_in(10) <= ialu_op(1);
	bundled_in(11) <= ialu_op(2);

	bundled_in(12) <= iwrr;
	bundled_in(13) <= iwrm;
	bundled_in(14) <= iwre;
	bundled_in(15) <= iwrf;
	bundled_in(16) <= isro;
	bundled_in(17) <= isrr;
	bundled_in(18) <= isrm;
	bundled_in(19) <= ipsh;
	bundled_in(20) <= ipop;
	bundled_in(21) <= ijmp;
	bundled_in(22) <= ical;
	bundled_in(23) <= iret;
	bundled_in(24) <= ihlt;
	bundled_in(25) <= iiim;
	bundled_in(26) <= isre;
		
	dc : reg_defon PORT MAP(                 icycadv,                   ocycadv, update_stage, clk);

	d0 : reg_16bit PORT MAP(bundled_in(15 DOWNTO  0), bundled_out(15 DOWNTO  0), update_stage, clk);
	d1 : reg_16bit PORT MAP(bundled_in(31 DOWNTO 16), bundled_out(31 DOWNTO 16), update_stage, clk);
	d2 : reg_16bit PORT MAP(                    ires,                      ores, update_stage, clk);
	d3 : reg_16bit PORT MAP(                    imem,                      omem, update_stage, clk);
	d4 : reg_16bit PORT MAP(                    iop0,                      oop0, update_stage, clk);
	d5 : reg_16bit PORT MAP(                    iop1,                      oop1, update_stage, clk);
	d6 : reg_16bit PORT MAP(                    iext,                      oext, update_stage, clk);


	or0(0)     <= bundled_out( 0);
	or0(1)     <= bundled_out( 1);
	or0(2)     <= bundled_out( 2);
                               
	or1(0)     <= bundled_out( 3);
	or1(1)     <= bundled_out( 4);
	or1(2)     <= bundled_out( 5);
	                           
	oflg(0)    <= bundled_out( 6);
	oflg(1)    <= bundled_out( 7);
	oflg(2)    <= bundled_out( 8);
                               
	oalu_op(0) <= bundled_out( 9);
	oalu_op(1) <= bundled_out(10);
	oalu_op(2) <= bundled_out(11);
                               
	owrr       <= bundled_out(12);
	owrm       <= bundled_out(13);
	owre       <= bundled_out(14);
	owrf       <= bundled_out(15);
	osro       <= bundled_out(16);
	osrr       <= bundled_out(17);
	osrm       <= bundled_out(18);
	opsh       <= bundled_out(19);
	opop       <= bundled_out(20);
	ojmp       <= bundled_out(21);
	ocal       <= bundled_out(22);
	oret       <= bundled_out(23);
	ohlt       <= bundled_out(24);
	oiim       <= bundled_out(25);
	osre       <= bundled_out(26);

END ARCHITECTURE behav;
