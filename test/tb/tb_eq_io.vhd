-- Equivalence for the second VHDL batch (buffers, differential IO, LUT6_2)
-- against the Apache-2.0 Verilog analysed into library work.
-- A component of the same name binds to that Verilog module.
-- GLBL in work supplies glbl.GTS for the Verilog side. The VHDL side
-- uses the local TOC in unisim_sim. Comparisons start at 1 ns, after
-- TOC and after the 1 ps DQS_BIAS / USE_IBUFDISABLE parameter update.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_io is
end entity tb_eq_io;

architecture sim of tb_eq_io is
  constant vals : std_logic_vector(0 to 3) := "01XZ";
  constant lut_init : bit_vector(63 downto 0) := X"6996966996696996";

  signal i, ib, dis, imd, t, ceb : std_ulogic := '0';
  signal i0, i1, i2, i3, i4, i5 : std_ulogic := '0';

  signal autobuf_h, autobuf_v : std_ulogic;
  signal bufgp_h, bufgp_v : std_ulogic;
  signal bufh_h, bufh_v : std_ulogic;
  signal ana_h, ana_v : std_ulogic;
  signal dis_h, dis_v : std_ulogic;
  signal dis_u_h, dis_u_v : std_ulogic;
  signal dis_off_h, dis_off_v : std_ulogic;
  signal inter_h, inter_v : std_ulogic;
  signal ibufds_h, ibufds_v : std_ulogic;
  signal ibufds_b_h, ibufds_b_v : std_ulogic;
  signal diff_h, diff_v, diffb_h, diffb_v : std_ulogic;
  signal diff_bias_h, diff_bias_v, diffb_bias_h, diffb_bias_v : std_ulogic;
  signal ddis_h, ddis_v : std_ulogic;
  signal ddis_u_h, ddis_u_v : std_ulogic;
  signal ddis_off_h, ddis_off_v : std_ulogic;
  signal dint_h, dint_v : std_ulogic;
  signal dint_off_h, dint_off_v : std_ulogic;
  signal dim_h, dim_v : std_ulogic;
  signal dimi_h, dimi_v : std_ulogic;
  signal dout_h, dout_v, doutb_h, doutb_v : std_ulogic;
  signal dout_u_h, dout_u_v, doutb_u_h, doutb_u_v : std_ulogic;
  signal dout_p_h, dout_p_v, doutb_p_h, doutb_p_v : std_ulogic;
  signal dout_off_h, dout_off_v, doutb_off_h, doutb_off_v : std_ulogic;
  signal doutd_h, doutd_v, doutdb_h, doutdb_v : std_ulogic;
  signal obufds_h, obufds_v, obufdsb_h, obufdsb_v : std_ulogic;
  signal obuftds_h, obuftds_v, obuftdsb_h, obuftdsb_v : std_ulogic;
  signal dcien_h, dcien_v : std_ulogic;
  signal dciends_h, dciends_v, dciendsb_h, dciendsb_v : std_ulogic;
  signal gte3_h, gte3_v, gte3b_h, gte3b_v : std_ulogic;
  signal gte3e_h, gte3e_v, gte3eb_h, gte3eb_v : std_ulogic;
  signal gte4_h, gte4_v, gte4b_h, gte4b_v : std_ulogic;
  signal gte4e_h, gte4e_v, gte4eb_h, gte4eb_v : std_ulogic;
  signal o5_h, o5_v, o6_h, o6_v : std_ulogic;

  component AUTOBUF is
    generic (BUFFER_TYPE : string := "AUTO");
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component BUFGP is
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component BUFH is
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component IBUF_ANALOG is
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component IBUF_IBUFDISABLE is
    generic (
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT";
      SIM_DEVICE : string := "7SERIES";
      USE_IBUFDISABLE : boolean := TRUE
    );
    port (O : out std_ulogic; I, IBUFDISABLE : in std_ulogic);
  end component;
  component IBUF_INTERMDISABLE is
    generic (
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT";
      SIM_DEVICE : string := "7SERIES";
      USE_IBUFDISABLE : boolean := TRUE
    );
    port (O : out std_ulogic; I, IBUFDISABLE, INTERMDISABLE : in std_ulogic);
  end component;
  component IBUFDS is
    generic (
      CAPACITANCE : string := "DONT_CARE";
      DIFF_TERM : boolean := FALSE;
      DQS_BIAS : boolean := FALSE;
      IBUF_DELAY_VALUE : string := "0";
      IBUF_LOW_PWR : boolean := TRUE;
      IFD_DELAY_VALUE : string := "AUTO";
      IOSTANDARD : string := "DEFAULT"
    );
    port (O : out std_ulogic; I, IB : in std_ulogic);
  end component;
  component IBUFDS_DIFF_OUT is
    generic (
      DIFF_TERM : boolean := FALSE;
      DQS_BIAS : boolean := FALSE;
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT"
    );
    port (O, OB : out std_ulogic; I, IB : in std_ulogic);
  end component;
  component IBUFDS_IBUFDISABLE is
    generic (
      DIFF_TERM : boolean := FALSE;
      DQS_BIAS : boolean := FALSE;
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT";
      SIM_DEVICE : string := "7SERIES";
      USE_IBUFDISABLE : boolean := TRUE
    );
    port (O : out std_ulogic; I, IB, IBUFDISABLE : in std_ulogic);
  end component;
  component IBUFDS_IBUFDISABLE_INT is
    generic (
      DIFF_TERM : boolean := FALSE;
      DQS_BIAS : boolean := FALSE;
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT";
      USE_IBUFDISABLE : boolean := TRUE
    );
    port (O : out std_ulogic; I, IB, IBUFDISABLE : in std_ulogic);
  end component;
  component IBUFDS_INTERMDISABLE is
    generic (
      DIFF_TERM : boolean := FALSE;
      DQS_BIAS : boolean := FALSE;
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT";
      SIM_DEVICE : string := "7SERIES";
      USE_IBUFDISABLE : boolean := TRUE
    );
    port (O : out std_ulogic; I, IB, IBUFDISABLE, INTERMDISABLE : in std_ulogic);
  end component;
  component IBUFDS_INTERMDISABLE_INT is
    generic (
      DIFF_TERM : boolean := FALSE;
      DQS_BIAS : boolean := FALSE;
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT";
      USE_IBUFDISABLE : boolean := TRUE
    );
    port (O : out std_ulogic; I, IB, IBUFDISABLE, INTERMDISABLE : in std_ulogic);
  end component;
  component IBUFDS_DIFF_OUT_IBUFDISABLE is
    generic (
      DIFF_TERM : boolean := FALSE;
      DQS_BIAS : boolean := FALSE;
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT";
      SIM_DEVICE : string := "7SERIES";
      USE_IBUFDISABLE : boolean := TRUE
    );
    port (O, OB : out std_ulogic; I, IB, IBUFDISABLE : in std_ulogic);
  end component;
  component IBUFDS_DIFF_OUT_INTERMDISABLE is
    generic (
      DIFF_TERM : boolean := FALSE;
      DQS_BIAS : boolean := FALSE;
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT";
      SIM_DEVICE : string := "7SERIES";
      USE_IBUFDISABLE : boolean := TRUE
    );
    port (O, OB : out std_ulogic; I, IB, IBUFDISABLE, INTERMDISABLE : in std_ulogic);
  end component;
  component OBUFDS is
    generic (
      CAPACITANCE : string := "DONT_CARE";
      IOSTANDARD : string := "DEFAULT";
      SLEW : string := "SLOW"
    );
    port (O, OB : out std_ulogic; I : in std_ulogic);
  end component;
  component OBUFTDS is
    generic (
      CAPACITANCE : string := "DONT_CARE";
      IOSTANDARD : string := "DEFAULT";
      SLEW : string := "SLOW"
    );
    port (O, OB : out std_ulogic; I, T : in std_ulogic);
  end component;
  component OBUFT_DCIEN is
    generic (
      DRIVE : integer := 12;
      IOSTANDARD : string := "DEFAULT";
      SLEW : string := "SLOW"
    );
    port (O : out std_ulogic; DCITERMDISABLE, I, T : in std_ulogic);
  end component;
  component OBUFTDS_DCIEN is
    generic (
      IOSTANDARD : string := "DEFAULT";
      SLEW : string := "SLOW"
    );
    port (O, OB : out std_ulogic; DCITERMDISABLE, I, T : in std_ulogic);
  end component;
  component OBUFDS_GTE3 is
    generic (
      REFCLK_EN_TX_PATH : bit := '0';
      REFCLK_ICNTL_TX : bit_vector(4 downto 0) := "00000"
    );
    port (O, OB : out std_ulogic; CEB, I : in std_ulogic);
  end component;
  component OBUFDS_GTE4 is
    generic (
      REFCLK_EN_TX_PATH : bit := '0';
      REFCLK_ICNTL_TX : bit_vector(4 downto 0) := "00000"
    );
    port (O, OB : out std_ulogic; CEB, I : in std_ulogic);
  end component;
  component LUT6_2 is
    generic (INIT : bit_vector(63 downto 0) := X"0000000000000000");
    port (
      O5, O6 : out std_ulogic;
      I0, I1, I2, I3, I4, I5 : in std_ulogic
    );
  end component;

  function from_vlog(v : std_ulogic) return std_ulogic is
  begin
    if v = 'U' then
      return 'X';
    end if;
    return v;
  end function;

begin
  u_auto_h : entity unisim.AUTOBUF
    generic map (BUFFER_TYPE => "AUTO")
    port map (O => autobuf_h, I => i);
  u_auto_v : AUTOBUF
    generic map (BUFFER_TYPE => "AUTO")
    port map (O => autobuf_v, I => i);
  u_bufgp_h : entity unisim.BUFGP port map (O => bufgp_h, I => i);
  u_bufgp_v : BUFGP port map (O => bufgp_v, I => i);
  u_bufh_h : entity unisim.BUFH port map (O => bufh_h, I => i);
  u_bufh_v : BUFH port map (O => bufh_v, I => i);
  u_ana_h : entity unisim.IBUF_ANALOG port map (O => ana_h, I => i);
  u_ana_v : IBUF_ANALOG port map (O => ana_v, I => i);

  u_dis_h : entity unisim.IBUF_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES", USE_IBUFDISABLE => TRUE)
    port map (O => dis_h, I => i, IBUFDISABLE => dis);
  u_dis_v : IBUF_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES", USE_IBUFDISABLE => TRUE)
    port map (O => dis_v, I => i, IBUFDISABLE => dis);
  u_dis_u_h : entity unisim.IBUF_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE", USE_IBUFDISABLE => TRUE)
    port map (O => dis_u_h, I => i, IBUFDISABLE => dis);
  u_dis_u_v : IBUF_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE", USE_IBUFDISABLE => TRUE)
    port map (O => dis_u_v, I => i, IBUFDISABLE => dis);
  u_dis_off_h : entity unisim.IBUF_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES", USE_IBUFDISABLE => FALSE)
    port map (O => dis_off_h, I => i, IBUFDISABLE => dis);
  u_dis_off_v : IBUF_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES", USE_IBUFDISABLE => FALSE)
    port map (O => dis_off_v, I => i, IBUFDISABLE => dis);

  u_inter_h : entity unisim.IBUF_INTERMDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => inter_h, I => i, IBUFDISABLE => dis, INTERMDISABLE => imd);
  u_inter_v : IBUF_INTERMDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => inter_v, I => i, IBUFDISABLE => dis, INTERMDISABLE => imd);

  u_ibufds_h : entity unisim.IBUFDS
    generic map (
      CAPACITANCE => "DONT_CARE", DQS_BIAS => FALSE,
      IBUF_DELAY_VALUE => "0", IFD_DELAY_VALUE => "AUTO", IOSTANDARD => "DEFAULT"
    )
    port map (O => ibufds_h, I => i, IB => ib);
  u_ibufds_v : IBUFDS
    generic map (
      CAPACITANCE => "DONT_CARE", DQS_BIAS => FALSE,
      IBUF_DELAY_VALUE => "0", IFD_DELAY_VALUE => "AUTO", IOSTANDARD => "DEFAULT"
    )
    port map (O => ibufds_v, I => i, IB => ib);
  u_ibufds_b_h : entity unisim.IBUFDS
    generic map (
      CAPACITANCE => "DONT_CARE", DQS_BIAS => TRUE,
      IBUF_DELAY_VALUE => "0", IFD_DELAY_VALUE => "AUTO", IOSTANDARD => "DEFAULT"
    )
    port map (O => ibufds_b_h, I => i, IB => ib);
  u_ibufds_b_v : IBUFDS
    generic map (
      CAPACITANCE => "DONT_CARE", DQS_BIAS => TRUE,
      IBUF_DELAY_VALUE => "0", IFD_DELAY_VALUE => "AUTO", IOSTANDARD => "DEFAULT"
    )
    port map (O => ibufds_b_v, I => i, IB => ib);

  u_diff_h : entity unisim.IBUFDS_DIFF_OUT
    generic map (DQS_BIAS => FALSE, IOSTANDARD => "DEFAULT")
    port map (O => diff_h, OB => diffb_h, I => i, IB => ib);
  u_diff_v : IBUFDS_DIFF_OUT
    generic map (DQS_BIAS => FALSE, IOSTANDARD => "DEFAULT")
    port map (O => diff_v, OB => diffb_v, I => i, IB => ib);
  u_diff_b_h : entity unisim.IBUFDS_DIFF_OUT
    generic map (DQS_BIAS => TRUE, IOSTANDARD => "DEFAULT")
    port map (O => diff_bias_h, OB => diffb_bias_h, I => i, IB => ib);
  u_diff_b_v : IBUFDS_DIFF_OUT
    generic map (DQS_BIAS => TRUE, IOSTANDARD => "DEFAULT")
    port map (O => diff_bias_v, OB => diffb_bias_v, I => i, IB => ib);

  u_ddis_h : entity unisim.IBUFDS_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => ddis_h, I => i, IB => ib, IBUFDISABLE => dis);
  u_ddis_v : IBUFDS_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => ddis_v, I => i, IB => ib, IBUFDISABLE => dis);
  u_ddis_u_h : entity unisim.IBUFDS_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE")
    port map (O => ddis_u_h, I => i, IB => ib, IBUFDISABLE => dis);
  u_ddis_u_v : IBUFDS_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE")
    port map (O => ddis_u_v, I => i, IB => ib, IBUFDISABLE => dis);
  u_ddis_off_h : entity unisim.IBUFDS_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", USE_IBUFDISABLE => FALSE)
    port map (O => ddis_off_h, I => i, IB => ib, IBUFDISABLE => dis);
  u_ddis_off_v : IBUFDS_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", USE_IBUFDISABLE => FALSE)
    port map (O => ddis_off_v, I => i, IB => ib, IBUFDISABLE => dis);

  u_dint_h : entity unisim.IBUFDS_IBUFDISABLE_INT
    generic map (IOSTANDARD => "DEFAULT")
    port map (O => dint_h, I => i, IB => ib, IBUFDISABLE => dis);
  u_dint_v : IBUFDS_IBUFDISABLE_INT
    generic map (IOSTANDARD => "DEFAULT")
    port map (O => dint_v, I => i, IB => ib, IBUFDISABLE => dis);
  u_dint_off_h : entity unisim.IBUFDS_IBUFDISABLE_INT
    generic map (IOSTANDARD => "DEFAULT", USE_IBUFDISABLE => FALSE)
    port map (O => dint_off_h, I => i, IB => ib, IBUFDISABLE => dis);
  u_dint_off_v : IBUFDS_IBUFDISABLE_INT
    generic map (IOSTANDARD => "DEFAULT", USE_IBUFDISABLE => FALSE)
    port map (O => dint_off_v, I => i, IB => ib, IBUFDISABLE => dis);

  u_dim_h : entity unisim.IBUFDS_INTERMDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => dim_h, I => i, IB => ib, IBUFDISABLE => dis, INTERMDISABLE => imd);
  u_dim_v : IBUFDS_INTERMDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => dim_v, I => i, IB => ib, IBUFDISABLE => dis, INTERMDISABLE => imd);
  u_dimi_h : entity unisim.IBUFDS_INTERMDISABLE_INT
    generic map (IOSTANDARD => "DEFAULT")
    port map (O => dimi_h, I => i, IB => ib, IBUFDISABLE => dis, INTERMDISABLE => imd);
  u_dimi_v : IBUFDS_INTERMDISABLE_INT
    generic map (IOSTANDARD => "DEFAULT")
    port map (O => dimi_v, I => i, IB => ib, IBUFDISABLE => dis, INTERMDISABLE => imd);

  u_dout_h : entity unisim.IBUFDS_DIFF_OUT_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => dout_h, OB => doutb_h, I => i, IB => ib, IBUFDISABLE => dis);
  u_dout_v : IBUFDS_DIFF_OUT_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => dout_v, OB => doutb_v, I => i, IB => ib, IBUFDISABLE => dis);
  u_dout_u_h : entity unisim.IBUFDS_DIFF_OUT_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE")
    port map (O => dout_u_h, OB => doutb_u_h, I => i, IB => ib, IBUFDISABLE => dis);
  u_dout_u_v : IBUFDS_DIFF_OUT_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE")
    port map (O => dout_u_v, OB => doutb_u_v, I => i, IB => ib, IBUFDISABLE => dis);
  u_dout_p_h : entity unisim.IBUFDS_DIFF_OUT_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "VERSAL_PRIME")
    port map (O => dout_p_h, OB => doutb_p_h, I => i, IB => ib, IBUFDISABLE => dis);
  u_dout_p_v : IBUFDS_DIFF_OUT_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "VERSAL_PRIME")
    port map (O => dout_p_v, OB => doutb_p_v, I => i, IB => ib, IBUFDISABLE => dis);
  u_dout_off_h : entity unisim.IBUFDS_DIFF_OUT_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", USE_IBUFDISABLE => FALSE)
    port map (O => dout_off_h, OB => doutb_off_h, I => i, IB => ib, IBUFDISABLE => dis);
  u_dout_off_v : IBUFDS_DIFF_OUT_IBUFDISABLE
    generic map (IOSTANDARD => "DEFAULT", USE_IBUFDISABLE => FALSE)
    port map (O => dout_off_v, OB => doutb_off_v, I => i, IB => ib, IBUFDISABLE => dis);

  u_doutd_h : entity unisim.IBUFDS_DIFF_OUT_INTERMDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => doutd_h, OB => doutdb_h, I => i, IB => ib, IBUFDISABLE => dis, INTERMDISABLE => imd);
  u_doutd_v : IBUFDS_DIFF_OUT_INTERMDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => doutd_v, OB => doutdb_v, I => i, IB => ib, IBUFDISABLE => dis, INTERMDISABLE => imd);

  u_obufds_h : entity unisim.OBUFDS
    generic map (CAPACITANCE => "DONT_CARE", IOSTANDARD => "DEFAULT", SLEW => "SLOW")
    port map (O => obufds_h, OB => obufdsb_h, I => i);
  u_obufds_v : OBUFDS
    generic map (CAPACITANCE => "DONT_CARE", IOSTANDARD => "DEFAULT", SLEW => "SLOW")
    port map (O => obufds_v, OB => obufdsb_v, I => i);
  u_obuftds_h : entity unisim.OBUFTDS
    generic map (CAPACITANCE => "DONT_CARE", IOSTANDARD => "DEFAULT", SLEW => "SLOW")
    port map (O => obuftds_h, OB => obuftdsb_h, I => i, T => t);
  u_obuftds_v : OBUFTDS
    generic map (CAPACITANCE => "DONT_CARE", IOSTANDARD => "DEFAULT", SLEW => "SLOW")
    port map (O => obuftds_v, OB => obuftdsb_v, I => i, T => t);

  u_dcien_h : entity unisim.OBUFT_DCIEN
    generic map (DRIVE => 12, IOSTANDARD => "DEFAULT", SLEW => "SLOW")
    port map (O => dcien_h, DCITERMDISABLE => imd, I => i, T => t);
  u_dcien_v : OBUFT_DCIEN
    generic map (DRIVE => 12, IOSTANDARD => "DEFAULT", SLEW => "SLOW")
    port map (O => dcien_v, DCITERMDISABLE => imd, I => i, T => t);
  u_dciends_h : entity unisim.OBUFTDS_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SLEW => "SLOW")
    port map (O => dciends_h, OB => dciendsb_h, DCITERMDISABLE => imd, I => i, T => t);
  u_dciends_v : OBUFTDS_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SLEW => "SLOW")
    port map (O => dciends_v, OB => dciendsb_v, DCITERMDISABLE => imd, I => i, T => t);

  u_gte3_h : entity unisim.OBUFDS_GTE3
    generic map (REFCLK_EN_TX_PATH => '0', REFCLK_ICNTL_TX => "00000")
    port map (O => gte3_h, OB => gte3b_h, CEB => ceb, I => i);
  u_gte3_v : OBUFDS_GTE3
    generic map (REFCLK_EN_TX_PATH => '0', REFCLK_ICNTL_TX => "00000")
    port map (O => gte3_v, OB => gte3b_v, CEB => ceb, I => i);
  u_gte3e_h : entity unisim.OBUFDS_GTE3
    generic map (REFCLK_EN_TX_PATH => '1', REFCLK_ICNTL_TX => "10101")
    port map (O => gte3e_h, OB => gte3eb_h, CEB => ceb, I => i);
  u_gte3e_v : OBUFDS_GTE3
    generic map (REFCLK_EN_TX_PATH => '1', REFCLK_ICNTL_TX => "10101")
    port map (O => gte3e_v, OB => gte3eb_v, CEB => ceb, I => i);

  u_gte4_h : entity unisim.OBUFDS_GTE4
    generic map (REFCLK_EN_TX_PATH => '0', REFCLK_ICNTL_TX => "00000")
    port map (O => gte4_h, OB => gte4b_h, CEB => ceb, I => i);
  u_gte4_v : OBUFDS_GTE4
    generic map (REFCLK_EN_TX_PATH => '0', REFCLK_ICNTL_TX => "00000")
    port map (O => gte4_v, OB => gte4b_v, CEB => ceb, I => i);
  u_gte4e_h : entity unisim.OBUFDS_GTE4
    generic map (REFCLK_EN_TX_PATH => '1', REFCLK_ICNTL_TX => "10101")
    port map (O => gte4e_h, OB => gte4eb_h, CEB => ceb, I => i);
  u_gte4e_v : OBUFDS_GTE4
    generic map (REFCLK_EN_TX_PATH => '1', REFCLK_ICNTL_TX => "10101")
    port map (O => gte4e_v, OB => gte4eb_v, CEB => ceb, I => i);

  u_lut_h : entity unisim.LUT6_2
    generic map (INIT => lut_init)
    port map (O5 => o5_h, O6 => o6_h, I0 => i0, I1 => i1, I2 => i2, I3 => i3, I4 => i4, I5 => i5);
  u_lut_v : LUT6_2
    generic map (INIT => lut_init)
    port map (O5 => o5_v, O6 => o6_v, I0 => i0, I1 => i1, I2 => i2, I3 => i3, I4 => i4, I5 => i5);

  stim : process
    variable n : natural := 0;

    procedure eq(name : string; got, exp : std_ulogic) is
    begin
      n := n + 1;
      assert got = from_vlog(exp)
        report name & " VHDL=" & std_ulogic'image(got)
          & " Verilog=" & std_ulogic'image(from_vlog(exp))
        severity failure;
    end procedure;

    procedure check_io is
    begin
      eq("AUTOBUF", autobuf_h, autobuf_v);
      eq("BUFGP", bufgp_h, bufgp_v);
      eq("BUFH", bufh_h, bufh_v);
      eq("IBUF_ANALOG", ana_h, ana_v);
      eq("IBUF_IBUFDISABLE", dis_h, dis_v);
      eq("IBUF_IBUFDISABLE ultra", dis_u_h, dis_u_v);
      eq("IBUF_IBUFDISABLE off", dis_off_h, dis_off_v);
      eq("IBUF_INTERMDISABLE", inter_h, inter_v);
      eq("IBUFDS", ibufds_h, ibufds_v);
      eq("IBUFDS bias", ibufds_b_h, ibufds_b_v);
      eq("IBUFDS_DIFF_OUT", diff_h, diff_v);
      eq("IBUFDS_DIFF_OUT OB", diffb_h, diffb_v);
      eq("IBUFDS_DIFF_OUT bias", diff_bias_h, diff_bias_v);
      eq("IBUFDS_DIFF_OUT bias OB", diffb_bias_h, diffb_bias_v);
      eq("IBUFDS_IBUFDISABLE", ddis_h, ddis_v);
      eq("IBUFDS_IBUFDISABLE ultra", ddis_u_h, ddis_u_v);
      eq("IBUFDS_IBUFDISABLE off", ddis_off_h, ddis_off_v);
      eq("IBUFDS_IBUFDISABLE_INT", dint_h, dint_v);
      eq("IBUFDS_IBUFDISABLE_INT off", dint_off_h, dint_off_v);
      eq("IBUFDS_INTERMDISABLE", dim_h, dim_v);
      eq("IBUFDS_INTERMDISABLE_INT", dimi_h, dimi_v);
      eq("DIFF_OUT_IBUFDISABLE", dout_h, dout_v);
      eq("DIFF_OUT_IBUFDISABLE OB", doutb_h, doutb_v);
      eq("DIFF_OUT_IBUFDISABLE ultra", dout_u_h, dout_u_v);
      eq("DIFF_OUT_IBUFDISABLE ultra OB", doutb_u_h, doutb_u_v);
      eq("DIFF_OUT_IBUFDISABLE prime", dout_p_h, dout_p_v);
      eq("DIFF_OUT_IBUFDISABLE prime OB", doutb_p_h, doutb_p_v);
      eq("DIFF_OUT_IBUFDISABLE off", dout_off_h, dout_off_v);
      eq("DIFF_OUT_IBUFDISABLE off OB", doutb_off_h, doutb_off_v);
      eq("DIFF_OUT_INTERMDISABLE", doutd_h, doutd_v);
      eq("DIFF_OUT_INTERMDISABLE OB", doutdb_h, doutdb_v);
      eq("OBUFDS", obufds_h, obufds_v);
      eq("OBUFDS OB", obufdsb_h, obufdsb_v);
      eq("OBUFTDS", obuftds_h, obuftds_v);
      eq("OBUFTDS OB", obuftdsb_h, obuftdsb_v);
      eq("OBUFT_DCIEN", dcien_h, dcien_v);
      eq("OBUFTDS_DCIEN", dciends_h, dciends_v);
      eq("OBUFTDS_DCIEN OB", dciendsb_h, dciendsb_v);
      eq("OBUFDS_GTE3", gte3_h, gte3_v);
      eq("OBUFDS_GTE3 OB", gte3b_h, gte3b_v);
      eq("OBUFDS_GTE3 en", gte3e_h, gte3e_v);
      eq("OBUFDS_GTE3 en OB", gte3eb_h, gte3eb_v);
      eq("OBUFDS_GTE4", gte4_h, gte4_v);
      eq("OBUFDS_GTE4 OB", gte4b_h, gte4b_v);
      eq("OBUFDS_GTE4 en", gte4e_h, gte4e_v);
      eq("OBUFDS_GTE4 en OB", gte4eb_h, gte4eb_v);
    end procedure;
  begin
    -- Past TOC (GTS falls after 0 ns) and the 1 ps parameter updates.
    wait for 1 ns;
    for ai in 0 to 3 loop
      for bi in 0 to 3 loop
        for di in 0 to 3 loop
          i <= vals(ai);
          ib <= vals(bi);
          dis <= vals(di);
          imd <= vals(di);
          t <= vals(ai);
          ceb <= vals(bi);
          wait for 1 ns;
          check_io;
        end loop;
      end loop;
    end loop;

    -- The Verilog LUT UDP stays X until an input changes, so leave the
    -- pins at X before the first all-zero vector.
    i0 <= 'X'; i1 <= 'X'; i2 <= 'X'; i3 <= 'X'; i4 <= 'X'; i5 <= 'X';
    wait for 1 ns;
    for a in 0 to 63 loop
      i0 <= '1' when (a / 1) mod 2 = 1 else '0';
      i1 <= '1' when (a / 2) mod 2 = 1 else '0';
      i2 <= '1' when (a / 4) mod 2 = 1 else '0';
      i3 <= '1' when (a / 8) mod 2 = 1 else '0';
      i4 <= '1' when (a / 16) mod 2 = 1 else '0';
      i5 <= '1' when (a / 32) mod 2 = 1 else '0';
      wait for 1 ns;
      eq("LUT6_2 O5", o5_h, o5_v);
      eq("LUT6_2 O6", o6_h, o6_v);
    end loop;

    i0 <= 'X'; i1 <= '0'; i2 <= '1'; i3 <= '0'; i4 <= '1'; i5 <= '0';
    wait for 1 ns;
    eq("LUT6_2 O5 X", o5_h, o5_v);
    eq("LUT6_2 O6 X", o6_h, o6_v);
    i0 <= 'Z';
    wait for 1 ns;
    eq("LUT6_2 O5 Z", o5_h, o5_v);
    eq("LUT6_2 O6 Z", o6_h, o6_v);

    report "tb_eq_io PASS checks=" & integer'image(n) severity note;
    finish(0);
  end process;
end architecture sim;
