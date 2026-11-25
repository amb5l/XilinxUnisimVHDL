-- DSP48E2. The Verilog behavioural model is the eight DSP_* atoms
-- inlined. This architecture instantiates those VHDL models and wires
-- them the same way. ALU_OUT keeps the 1 ps delay inside DSP_ALU.
-- The AREG/ACASCREG legality check and the OPMODE $display warnings
-- are not modelled, so an illegal pair does not $finish.

library ieee;
use ieee.std_logic_1164.all;

entity DSP48E2 is
  generic (
    ACASCREG : integer := 1;
    ADREG : integer := 1;
    ALUMODEREG : integer := 1;
    AMULTSEL : string := "A";
    AREG : integer := 1;
    AUTORESET_PATDET : string := "NO_RESET";
    AUTORESET_PRIORITY : string := "RESET";
    A_INPUT : string := "DIRECT";
    BCASCREG : integer := 1;
    BMULTSEL : string := "B";
    BREG : integer := 1;
    B_INPUT : string := "DIRECT";
    CARRYINREG : integer := 1;
    CARRYINSELREG : integer := 1;
    CREG : integer := 1;
    DREG : integer := 1;
    INMODEREG : integer := 1;
    IS_ALUMODE_INVERTED : bit_vector(3 downto 0) := X"0";
    IS_CARRYIN_INVERTED : bit := '0';
    IS_CLK_INVERTED : bit := '0';
    IS_INMODE_INVERTED : bit_vector(4 downto 0) := "00000";
    IS_OPMODE_INVERTED : bit_vector(8 downto 0) := "000000000";
    IS_RSTALLCARRYIN_INVERTED : bit := '0';
    IS_RSTALUMODE_INVERTED : bit := '0';
    IS_RSTA_INVERTED : bit := '0';
    IS_RSTB_INVERTED : bit := '0';
    IS_RSTCTRL_INVERTED : bit := '0';
    IS_RSTC_INVERTED : bit := '0';
    IS_RSTD_INVERTED : bit := '0';
    IS_RSTINMODE_INVERTED : bit := '0';
    IS_RSTM_INVERTED : bit := '0';
    IS_RSTP_INVERTED : bit := '0';
    MASK : bit_vector(47 downto 0) := X"3FFFFFFFFFFF";
    MREG : integer := 1;
    OPMODEREG : integer := 1;
    PATTERN : bit_vector(47 downto 0) := X"000000000000";
    PREADDINSEL : string := "A";
    PREG : integer := 1;
    RND : bit_vector(47 downto 0) := X"000000000000";
    SEL_MASK : string := "MASK";
    SEL_PATTERN : string := "PATTERN";
    USE_MULT : string := "MULTIPLY";
    USE_PATTERN_DETECT : string := "NO_PATDET";
    USE_SIMD : string := "ONE48";
    USE_WIDEXOR : boolean := FALSE;
    XORSIMD : string := "XOR24_48_96"
  );
  port (
    ACOUT : out std_logic_vector(29 downto 0);
    BCOUT : out std_logic_vector(17 downto 0);
    CARRYCASCOUT : out std_ulogic;
    CARRYOUT : out std_logic_vector(3 downto 0);
    MULTSIGNOUT : out std_ulogic;
    OVERFLOW : out std_ulogic;
    P : out std_logic_vector(47 downto 0);
    PATTERNBDETECT : out std_ulogic;
    PATTERNDETECT : out std_ulogic;
    PCOUT : out std_logic_vector(47 downto 0);
    UNDERFLOW : out std_ulogic;
    XOROUT : out std_logic_vector(7 downto 0);
    A : in std_logic_vector(29 downto 0);
    ACIN : in std_logic_vector(29 downto 0);
    ALUMODE : in std_logic_vector(3 downto 0);
    B : in std_logic_vector(17 downto 0);
    BCIN : in std_logic_vector(17 downto 0);
    C : in std_logic_vector(47 downto 0);
    CARRYCASCIN : in std_ulogic;
    CARRYIN : in std_ulogic;
    CARRYINSEL : in std_logic_vector(2 downto 0);
    CEA1 : in std_ulogic;
    CEA2 : in std_ulogic;
    CEAD : in std_ulogic;
    CEALUMODE : in std_ulogic;
    CEB1 : in std_ulogic;
    CEB2 : in std_ulogic;
    CEC : in std_ulogic;
    CECARRYIN : in std_ulogic;
    CECTRL : in std_ulogic;
    CED : in std_ulogic;
    CEINMODE : in std_ulogic;
    CEM : in std_ulogic;
    CEP : in std_ulogic;
    CLK : in std_ulogic;
    D : in std_logic_vector(26 downto 0);
    INMODE : in std_logic_vector(4 downto 0);
    MULTSIGNIN : in std_ulogic;
    OPMODE : in std_logic_vector(8 downto 0);
    PCIN : in std_logic_vector(47 downto 0);
    RSTA : in std_ulogic;
    RSTALLCARRYIN : in std_ulogic;
    RSTALUMODE : in std_ulogic;
    RSTB : in std_ulogic;
    RSTC : in std_ulogic;
    RSTCTRL : in std_ulogic;
    RSTD : in std_ulogic;
    RSTINMODE : in std_ulogic;
    RSTM : in std_ulogic;
    RSTP : in std_ulogic
  );
end entity DSP48E2;

architecture sim of DSP48E2 is
  component DSP_A_B_DATA is
    generic (
      ACASCREG : integer := 1; AREG : integer := 1; A_INPUT : string := "DIRECT";
      BCASCREG : integer := 1; BREG : integer := 1; B_INPUT : string := "DIRECT";
      IS_CLK_INVERTED : bit := '0'; IS_RSTA_INVERTED : bit := '0';
      IS_RSTB_INVERTED : bit := '0');
    port (
      A1_DATA : out std_logic_vector(26 downto 0);
      A2_DATA : out std_logic_vector(26 downto 0);
      ACOUT : out std_logic_vector(29 downto 0);
      A_ALU : out std_logic_vector(29 downto 0);
      B1_DATA : out std_logic_vector(17 downto 0);
      B2_DATA : out std_logic_vector(17 downto 0);
      BCOUT : out std_logic_vector(17 downto 0);
      B_ALU : out std_logic_vector(17 downto 0);
      A : in std_logic_vector(29 downto 0); ACIN : in std_logic_vector(29 downto 0);
      B : in std_logic_vector(17 downto 0); BCIN : in std_logic_vector(17 downto 0);
      CEA1, CEA2, CEB1, CEB2, CLK, RSTA, RSTB : in std_ulogic);
  end component;
  component DSP_C_DATA is
    generic (CREG : integer := 1; IS_CLK_INVERTED : bit := '0'; IS_RSTC_INVERTED : bit := '0');
    port (
      C_DATA : out std_logic_vector(47 downto 0);
      C : in std_logic_vector(47 downto 0);
      CEC, CLK, RSTC : in std_ulogic);
  end component;
  component DSP_PREADD_DATA is
    generic (
      ADREG : integer := 1; AMULTSEL : string := "A"; BMULTSEL : string := "B";
      DREG : integer := 1; INMODEREG : integer := 1; IS_CLK_INVERTED : bit := '0';
      IS_INMODE_INVERTED : bit_vector(4 downto 0) := "00000";
      IS_RSTD_INVERTED : bit := '0'; IS_RSTINMODE_INVERTED : bit := '0';
      PREADDINSEL : string := "A"; USE_MULT : string := "MULTIPLY");
    port (
      A2A1 : out std_logic_vector(26 downto 0); ADDSUB : out std_ulogic;
      AD_DATA : out std_logic_vector(26 downto 0);
      B2B1 : out std_logic_vector(17 downto 0);
      D_DATA : out std_logic_vector(26 downto 0); INMODE_2 : out std_ulogic;
      PREADD_AB : out std_logic_vector(26 downto 0);
      A1_DATA, A2_DATA, AD, DIN : in std_logic_vector(26 downto 0);
      B1_DATA, B2_DATA : in std_logic_vector(17 downto 0);
      CEAD, CED, CEINMODE, CLK, RSTD, RSTINMODE : in std_ulogic;
      INMODE : in std_logic_vector(4 downto 0));
  end component;
  component DSP_PREADD is
    port (
      AD : out std_logic_vector(26 downto 0);
      ADDSUB, INMODE2 : in std_ulogic;
      D_DATA, PREADD_AB : in std_logic_vector(26 downto 0));
  end component;
  component DSP_MULTIPLIER is
    generic (AMULTSEL : string := "A"; BMULTSEL : string := "B"; USE_MULT : string := "MULTIPLY");
    port (
      AMULT26, BMULT17 : out std_ulogic;
      U, V : out std_logic_vector(44 downto 0);
      A2A1, AD_DATA : in std_logic_vector(26 downto 0);
      B2B1 : in std_logic_vector(17 downto 0));
  end component;
  component DSP_M_DATA is
    generic (IS_CLK_INVERTED : bit := '0'; IS_RSTM_INVERTED : bit := '0'; MREG : integer := 1);
    port (
      U_DATA, V_DATA : out std_logic_vector(44 downto 0);
      CEM, CLK, RSTM : in std_ulogic;
      U, V : in std_logic_vector(44 downto 0));
  end component;
  component DSP_ALU is
    generic (
      ALUMODEREG : integer := 1; CARRYINREG : integer := 1; CARRYINSELREG : integer := 1;
      IS_ALUMODE_INVERTED : bit_vector(3 downto 0) := X"0";
      IS_CARRYIN_INVERTED : bit := '0'; IS_CLK_INVERTED : bit := '0';
      IS_OPMODE_INVERTED : bit_vector(8 downto 0) := "000000000";
      IS_RSTALLCARRYIN_INVERTED : bit := '0'; IS_RSTALUMODE_INVERTED : bit := '0';
      IS_RSTCTRL_INVERTED : bit := '0'; MREG : integer := 1; OPMODEREG : integer := 1;
      RND : bit_vector(47 downto 0) := X"000000000000"; USE_SIMD : string := "ONE48";
      USE_WIDEXOR : boolean := FALSE; XORSIMD : string := "XOR24_48_96");
    port (
      ALUMODE10 : out std_ulogic; ALU_OUT : out std_logic_vector(47 downto 0);
      COUT : out std_logic_vector(3 downto 0); MULTSIGN_ALU : out std_ulogic;
      XOR_MX : out std_logic_vector(7 downto 0);
      ALUMODE : in std_logic_vector(3 downto 0); AMULT26 : in std_ulogic;
      A_ALU : in std_logic_vector(29 downto 0); BMULT17 : in std_ulogic;
      B_ALU : in std_logic_vector(17 downto 0); CARRYCASCIN, CARRYIN : in std_ulogic;
      CARRYINSEL : in std_logic_vector(2 downto 0); CCOUT : in std_ulogic;
      CEALUMODE, CECARRYIN, CECTRL, CEM, CLK : in std_ulogic;
      C_DATA : in std_logic_vector(47 downto 0); MULTSIGNIN : in std_ulogic;
      OPMODE : in std_logic_vector(8 downto 0); PCIN, P_FDBK : in std_logic_vector(47 downto 0);
      P_FDBK_47 : in std_ulogic; RSTALLCARRYIN, RSTALUMODE, RSTCTRL : in std_ulogic;
      U_DATA, V_DATA : in std_logic_vector(44 downto 0));
  end component;
  component DSP_OUTPUT is
    generic (
      AUTORESET_PATDET : string := "NO_RESET"; AUTORESET_PRIORITY : string := "RESET";
      IS_CLK_INVERTED : bit := '0'; IS_RSTP_INVERTED : bit := '0';
      MASK : bit_vector(47 downto 0) := X"3FFFFFFFFFFF";
      PATTERN : bit_vector(47 downto 0) := X"000000000000"; PREG : integer := 1;
      SEL_MASK : string := "MASK"; SEL_PATTERN : string := "PATTERN";
      USE_PATTERN_DETECT : string := "NO_PATDET");
    port (
      CARRYCASCOUT : out std_ulogic; CARRYOUT : out std_logic_vector(3 downto 0);
      CCOUT_FB, MULTSIGNOUT, OVERFLOW : out std_ulogic;
      P : out std_logic_vector(47 downto 0);
      PATTERN_B_DETECT, PATTERN_DETECT : out std_ulogic;
      PCOUT, P_FDBK : out std_logic_vector(47 downto 0); P_FDBK_47, UNDERFLOW : out std_ulogic;
      XOROUT : out std_logic_vector(7 downto 0);
      ALUMODE10 : in std_ulogic; ALU_OUT : in std_logic_vector(47 downto 0);
      CEP, CLK : in std_ulogic; COUT : in std_logic_vector(3 downto 0);
      C_DATA : in std_logic_vector(47 downto 0); MULTSIGN_ALU, RSTP : in std_ulogic;
      XOR_MX : in std_logic_vector(7 downto 0));
  end component;

  signal a1_data, a2_data : std_logic_vector(26 downto 0);
  signal a_alu : std_logic_vector(29 downto 0);
  signal b1_data, b2_data, b_alu : std_logic_vector(17 downto 0);
  signal a2a1, d_data, ad_data, ad_sum, pre_ab : std_logic_vector(26 downto 0);
  signal b2b1 : std_logic_vector(17 downto 0);
  signal addsub, inmode2 : std_ulogic;
  signal u_raw, v_raw, u_data, v_data : std_logic_vector(44 downto 0);
  signal amult, bmult : std_ulogic;
  signal c_data, alu_out, p_fdbk : std_logic_vector(47 downto 0);
  signal cout : std_logic_vector(3 downto 0);
  signal xor_mx : std_logic_vector(7 downto 0);
  signal alumode10, msign, ccout_fb, p_fdbk_47 : std_ulogic;
begin
  u_ab : DSP_A_B_DATA
    generic map (
      ACASCREG => ACASCREG, AREG => AREG, A_INPUT => A_INPUT,
      BCASCREG => BCASCREG, BREG => BREG, B_INPUT => B_INPUT,
      IS_CLK_INVERTED => IS_CLK_INVERTED,
      IS_RSTA_INVERTED => IS_RSTA_INVERTED,
      IS_RSTB_INVERTED => IS_RSTB_INVERTED)
    port map (
      A1_DATA => a1_data, A2_DATA => a2_data, ACOUT => ACOUT, A_ALU => a_alu,
      B1_DATA => b1_data, B2_DATA => b2_data, BCOUT => BCOUT, B_ALU => b_alu,
      A => A, ACIN => ACIN, B => B, BCIN => BCIN,
      CEA1 => CEA1, CEA2 => CEA2, CEB1 => CEB1, CEB2 => CEB2,
      CLK => CLK, RSTA => RSTA, RSTB => RSTB);

  u_c : DSP_C_DATA
    generic map (
      CREG => CREG, IS_CLK_INVERTED => IS_CLK_INVERTED,
      IS_RSTC_INVERTED => IS_RSTC_INVERTED)
    port map (C_DATA => c_data, C => C, CEC => CEC, CLK => CLK, RSTC => RSTC);

  u_pd : DSP_PREADD_DATA
    generic map (
      ADREG => ADREG, AMULTSEL => AMULTSEL, BMULTSEL => BMULTSEL,
      DREG => DREG, INMODEREG => INMODEREG,
      IS_CLK_INVERTED => IS_CLK_INVERTED,
      IS_INMODE_INVERTED => IS_INMODE_INVERTED,
      IS_RSTD_INVERTED => IS_RSTD_INVERTED,
      IS_RSTINMODE_INVERTED => IS_RSTINMODE_INVERTED,
      PREADDINSEL => PREADDINSEL, USE_MULT => USE_MULT)
    port map (
      A2A1 => a2a1, ADDSUB => addsub, AD_DATA => ad_data, B2B1 => b2b1,
      D_DATA => d_data, INMODE_2 => inmode2, PREADD_AB => pre_ab,
      A1_DATA => a1_data, A2_DATA => a2_data, AD => ad_sum,
      B1_DATA => b1_data, B2_DATA => b2_data,
      CEAD => CEAD, CED => CED, CEINMODE => CEINMODE, CLK => CLK,
      DIN => D, INMODE => INMODE, RSTD => RSTD, RSTINMODE => RSTINMODE);

  u_pre : DSP_PREADD
    port map (
      AD => ad_sum, ADDSUB => addsub, D_DATA => d_data,
      INMODE2 => inmode2, PREADD_AB => pre_ab);

  u_mul : DSP_MULTIPLIER
    generic map (AMULTSEL => AMULTSEL, BMULTSEL => BMULTSEL, USE_MULT => USE_MULT)
    port map (
      AMULT26 => amult, BMULT17 => bmult, U => u_raw, V => v_raw,
      A2A1 => a2a1, AD_DATA => ad_data, B2B1 => b2b1);

  u_m : DSP_M_DATA
    generic map (
      IS_CLK_INVERTED => IS_CLK_INVERTED,
      IS_RSTM_INVERTED => IS_RSTM_INVERTED, MREG => MREG)
    port map (
      U_DATA => u_data, V_DATA => v_data, CEM => CEM, CLK => CLK,
      RSTM => RSTM, U => u_raw, V => v_raw);

  u_alu : DSP_ALU
    generic map (
      ALUMODEREG => ALUMODEREG, CARRYINREG => CARRYINREG,
      CARRYINSELREG => CARRYINSELREG,
      IS_ALUMODE_INVERTED => IS_ALUMODE_INVERTED,
      IS_CARRYIN_INVERTED => IS_CARRYIN_INVERTED,
      IS_CLK_INVERTED => IS_CLK_INVERTED,
      IS_OPMODE_INVERTED => IS_OPMODE_INVERTED,
      IS_RSTALLCARRYIN_INVERTED => IS_RSTALLCARRYIN_INVERTED,
      IS_RSTALUMODE_INVERTED => IS_RSTALUMODE_INVERTED,
      IS_RSTCTRL_INVERTED => IS_RSTCTRL_INVERTED,
      MREG => MREG, OPMODEREG => OPMODEREG, RND => RND,
      USE_SIMD => USE_SIMD, USE_WIDEXOR => USE_WIDEXOR, XORSIMD => XORSIMD)
    port map (
      ALUMODE10 => alumode10, ALU_OUT => alu_out, COUT => cout,
      MULTSIGN_ALU => msign, XOR_MX => xor_mx,
      ALUMODE => ALUMODE, AMULT26 => amult, A_ALU => a_alu,
      BMULT17 => bmult, B_ALU => b_alu, CARRYCASCIN => CARRYCASCIN,
      CARRYIN => CARRYIN, CARRYINSEL => CARRYINSEL, CCOUT => ccout_fb,
      CEALUMODE => CEALUMODE, CECARRYIN => CECARRYIN, CECTRL => CECTRL,
      CEM => CEM, CLK => CLK, C_DATA => c_data, MULTSIGNIN => MULTSIGNIN,
      OPMODE => OPMODE, PCIN => PCIN, P_FDBK => p_fdbk, P_FDBK_47 => p_fdbk_47,
      RSTALLCARRYIN => RSTALLCARRYIN, RSTALUMODE => RSTALUMODE,
      RSTCTRL => RSTCTRL, U_DATA => u_data, V_DATA => v_data);

  u_p : DSP_OUTPUT
    generic map (
      AUTORESET_PATDET => AUTORESET_PATDET,
      AUTORESET_PRIORITY => AUTORESET_PRIORITY,
      IS_CLK_INVERTED => IS_CLK_INVERTED,
      IS_RSTP_INVERTED => IS_RSTP_INVERTED,
      MASK => MASK, PATTERN => PATTERN, PREG => PREG,
      SEL_MASK => SEL_MASK, SEL_PATTERN => SEL_PATTERN,
      USE_PATTERN_DETECT => USE_PATTERN_DETECT)
    port map (
      CARRYCASCOUT => CARRYCASCOUT, CARRYOUT => CARRYOUT, CCOUT_FB => ccout_fb,
      MULTSIGNOUT => MULTSIGNOUT, OVERFLOW => OVERFLOW, P => P,
      PATTERN_B_DETECT => PATTERNBDETECT, PATTERN_DETECT => PATTERNDETECT,
      PCOUT => PCOUT, P_FDBK => p_fdbk, P_FDBK_47 => p_fdbk_47,
      UNDERFLOW => UNDERFLOW, XOROUT => XOROUT,
      ALUMODE10 => alumode10, ALU_OUT => alu_out, CEP => CEP, CLK => CLK,
      COUT => cout, C_DATA => c_data, MULTSIGN_ALU => msign, RSTP => RSTP,
      XOR_MX => xor_mx);
end architecture sim;
