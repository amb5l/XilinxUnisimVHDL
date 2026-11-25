-- DSP48E1 and DSP48E2 against the submodule Verilog, analysed with
-- XIL_TIMING. Delay nets are zero-delay copies. The Verilog always
-- @(input) copies do not run for a value that never changes, so
-- stimulus changes A, B, and OPMODE before the first compare.
-- %m in the OPMODE warning is not formatted by this NVC; the values
-- still match.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library unisim;

entity tb_eq_dsp48 is
end entity tb_eq_dsp48;

architecture sim of tb_eq_dsp48 is
  constant step : time := 5 ns;
  constant z48 : std_logic_vector(47 downto 0) := (others => '0');
  constant z30 : std_logic_vector(29 downto 0) := (others => '0');
  constant z27 : std_logic_vector(26 downto 0) := (others => '0');
  constant z25 : std_logic_vector(24 downto 0) := (others => '0');
  constant z18 : std_logic_vector(17 downto 0) := (others => '0');
  constant z5 : std_logic_vector(4 downto 0) := (others => '0');
  constant z4 : std_logic_vector(3 downto 0) := (others => '0');
  constant z3 : std_logic_vector(2 downto 0) := (others => '0');

  signal a, acin : std_logic_vector(29 downto 0) := (others => '0');
  signal b, bcin : std_logic_vector(17 downto 0) := (others => '0');
  signal c, pcin : std_logic_vector(47 downto 0) := (others => '0');
  signal d25 : std_logic_vector(24 downto 0) := (others => '0');
  signal d27 : std_logic_vector(26 downto 0) := (others => '0');
  signal op7 : std_logic_vector(6 downto 0) := (others => '0');
  signal op9 : std_logic_vector(8 downto 0) := (others => '0');
  signal inmode : std_logic_vector(4 downto 0) := (others => '0');
  signal in_z : std_logic_vector(4 downto 0) := (others => '0');
  signal alum : std_logic_vector(3 downto 0) := (others => '0');
  signal csel : std_logic_vector(2 downto 0) := (others => '0');
  signal cin : std_ulogic := '0';
  signal clk : std_ulogic := '0';
  signal ph, pv : std_logic_vector(47 downto 0);
  signal coh, cov : std_logic_vector(3 downto 0);
  signal mh, mv, dh, dv, bh, bv, oh, ov : std_ulogic;

  signal a_n : std_logic_vector(29 downto 0) := (others => '0');
  signal b_n : std_logic_vector(17 downto 0) := (others => '0');
  signal op_n : std_logic_vector(6 downto 0) := (others => '0');
  signal pnh, pnv : std_logic_vector(47 downto 0);

  signal a_d : std_logic_vector(29 downto 0) := (others => '0');
  signal b_d : std_logic_vector(17 downto 0) := (others => '0');
  signal d_d : std_logic_vector(24 downto 0) := (others => '0');
  signal in_d : std_logic_vector(4 downto 0) := (others => '0');
  signal op_d : std_logic_vector(6 downto 0) := "0000101";
  signal pdh, pdv : std_logic_vector(47 downto 0);

  signal a_r : std_logic_vector(29 downto 0) := (others => '0');
  signal b_r : std_logic_vector(17 downto 0) := (others => '0');
  signal op_r : std_logic_vector(6 downto 0) := (others => '0');
  signal clk_r : std_ulogic := '0';
  signal prh, prv : std_logic_vector(47 downto 0);

  signal a2, b2 : std_logic_vector(29 downto 0) := (others => '0');
  signal bb2 : std_logic_vector(17 downto 0) := (others => '0');
  signal c2 : std_logic_vector(47 downto 0) := (others => '0');
  signal op2 : std_logic_vector(8 downto 0) := (others => '0');
  signal p2h, p2v : std_logic_vector(47 downto 0);
  signal xh, xv : std_logic_vector(7 downto 0);

  signal a_p : std_logic_vector(29 downto 0) := (others => '0');
  signal b_p : std_logic_vector(17 downto 0) := (others => '0');
  signal op_p : std_logic_vector(8 downto 0) := (others => '0');
  signal clk_p : std_ulogic := '0';
  signal ac_h, ac_v : std_logic_vector(29 downto 0);
  signal pp_h, pp_v : std_logic_vector(47 downto 0);

  component DSP48E1 is
    generic (
      ACASCREG : integer := 1; ADREG : integer := 1; ALUMODEREG : integer := 1;
      AREG : integer := 1; AUTORESET_PATDET : string := "NO_RESET";
      A_INPUT : string := "DIRECT"; BCASCREG : integer := 1; BREG : integer := 1;
      B_INPUT : string := "DIRECT"; CARRYINREG : integer := 1;
      CARRYINSELREG : integer := 1; CREG : integer := 1; DREG : integer := 1;
      INMODEREG : integer := 1; MREG : integer := 1; OPMODEREG : integer := 1;
      PREG : integer := 1; USE_DPORT : boolean := FALSE;
      USE_MULT : string := "MULTIPLY"; USE_PATTERN_DETECT : string := "NO_PATDET";
      USE_SIMD : string := "ONE48";
      MASK : bit_vector(47 downto 0) := X"3FFFFFFFFFFF";
      PATTERN : bit_vector(47 downto 0) := X"000000000000"
    );
    port (
      ACOUT : out std_logic_vector(29 downto 0);
      BCOUT : out std_logic_vector(17 downto 0);
      CARRYCASCOUT : out std_ulogic;
      CARRYOUT : out std_logic_vector(3 downto 0);
      MULTSIGNOUT : out std_ulogic; OVERFLOW : out std_ulogic;
      P : out std_logic_vector(47 downto 0);
      PATTERNBDETECT : out std_ulogic; PATTERNDETECT : out std_ulogic;
      PCOUT : out std_logic_vector(47 downto 0); UNDERFLOW : out std_ulogic;
      A, ACIN : in std_logic_vector(29 downto 0);
      ALUMODE : in std_logic_vector(3 downto 0);
      B, BCIN : in std_logic_vector(17 downto 0);
      C : in std_logic_vector(47 downto 0);
      CARRYCASCIN, CARRYIN : in std_ulogic;
      CARRYINSEL : in std_logic_vector(2 downto 0);
      CEA1, CEA2, CEAD, CEALUMODE, CEB1, CEB2, CEC, CECARRYIN, CECTRL, CED,
      CEINMODE, CEM, CEP, CLK : in std_ulogic;
      D : in std_logic_vector(24 downto 0);
      INMODE : in std_logic_vector(4 downto 0);
      MULTSIGNIN : in std_ulogic;
      OPMODE : in std_logic_vector(6 downto 0);
      PCIN : in std_logic_vector(47 downto 0);
      RSTA, RSTALLCARRYIN, RSTALUMODE, RSTB, RSTC, RSTCTRL, RSTD, RSTINMODE,
      RSTM, RSTP : in std_ulogic
    );
  end component;

  component DSP48E2 is
    generic (
      ACASCREG : integer := 1; ADREG : integer := 1; ALUMODEREG : integer := 1;
      AREG : integer := 1; BCASCREG : integer := 1; BREG : integer := 1;
      CARRYINREG : integer := 1; CARRYINSELREG : integer := 1; CREG : integer := 1;
      DREG : integer := 1; INMODEREG : integer := 1; MREG : integer := 1;
      OPMODEREG : integer := 1; PREG : integer := 1;
      USE_MULT : string := "MULTIPLY"; USE_WIDEXOR : boolean := FALSE
    );
    port (
      ACOUT : out std_logic_vector(29 downto 0);
      BCOUT : out std_logic_vector(17 downto 0);
      CARRYCASCOUT : out std_ulogic;
      CARRYOUT : out std_logic_vector(3 downto 0);
      MULTSIGNOUT : out std_ulogic; OVERFLOW : out std_ulogic;
      P : out std_logic_vector(47 downto 0);
      PATTERNBDETECT : out std_ulogic; PATTERNDETECT : out std_ulogic;
      PCOUT : out std_logic_vector(47 downto 0); UNDERFLOW : out std_ulogic;
      XOROUT : out std_logic_vector(7 downto 0);
      A, ACIN : in std_logic_vector(29 downto 0);
      ALUMODE : in std_logic_vector(3 downto 0);
      B, BCIN : in std_logic_vector(17 downto 0);
      C : in std_logic_vector(47 downto 0);
      CARRYCASCIN, CARRYIN : in std_ulogic;
      CARRYINSEL : in std_logic_vector(2 downto 0);
      CEA1, CEA2, CEAD, CEALUMODE, CEB1, CEB2, CEC, CECARRYIN, CECTRL, CED,
      CEINMODE, CEM, CEP, CLK : in std_ulogic;
      D : in std_logic_vector(26 downto 0);
      INMODE : in std_logic_vector(4 downto 0);
      MULTSIGNIN : in std_ulogic;
      OPMODE : in std_logic_vector(8 downto 0);
      PCIN : in std_logic_vector(47 downto 0);
      RSTA, RSTALLCARRYIN, RSTALUMODE, RSTB, RSTC, RSTCTRL, RSTD, RSTINMODE,
      RSTM, RSTP : in std_ulogic
    );
  end component;

  function from_vlog(v : std_logic_vector) return std_logic_vector is
    variable r : std_logic_vector(v'range);
  begin
    for i in v'range loop
      if v(i) = 'U' then
        r(i) := 'X';
      else
        r(i) := v(i);
      end if;
    end loop;
    return r;
  end function;

  function from_vlog(v : std_ulogic) return std_ulogic is
  begin
    if v = 'U' then
      return 'X';
    end if;
    return v;
  end function;

  function slv(n, w : natural) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(n, w));
  end function;
begin
  -- Pipeline registers off. 7x9, then the product plus C, then a negative
  -- product. Pattern detect sees a zero mask and a zero pattern.
  u_h : entity unisim.DSP48E1
    generic map (
      ACASCREG => 0, ADREG => 0, ALUMODEREG => 0, AREG => 0, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0,
      MASK => X"000000000000", USE_PATTERN_DETECT => "PATDET")
    port map (
      ACOUT => open, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => coh,
      MULTSIGNOUT => mh, OVERFLOW => oh, P => ph, PATTERNBDETECT => bh,
      PATTERNDETECT => dh, PCOUT => open, UNDERFLOW => open,
      A => a, ACIN => z30, ALUMODE => alum, B => b, BCIN => z18, C => c,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '1', CEA2 => '1', CEAD => '1', CEALUMODE => '1', CEB1 => '1',
      CEB2 => '1', CEC => '1', CECARRYIN => '1', CECTRL => '1', CED => '1',
      CEINMODE => '1', CEM => '1', CEP => '1', CLK => clk, D => d25,
      INMODE => inmode, MULTSIGNIN => '0', OPMODE => op7, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');
  u_v : DSP48E1
    generic map (
      ACASCREG => 0, ADREG => 0, ALUMODEREG => 0, AREG => 0, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0,
      MASK => X"000000000000", USE_PATTERN_DETECT => "PATDET")
    port map (
      ACOUT => open, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => cov,
      MULTSIGNOUT => mv, OVERFLOW => ov, P => pv, PATTERNBDETECT => bv,
      PATTERNDETECT => dv, PCOUT => open, UNDERFLOW => open,
      A => a, ACIN => z30, ALUMODE => alum, B => b, BCIN => z18, C => c,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '1', CEA2 => '1', CEAD => '1', CEALUMODE => '1', CEB1 => '1',
      CEB2 => '1', CEC => '1', CECARRYIN => '1', CECTRL => '1', CED => '1',
      CEINMODE => '1', CEM => '1', CEP => '1', CLK => clk, D => d25,
      INMODE => inmode, MULTSIGNIN => '0', OPMODE => op7, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');

  -- USE_MULT NONE lets OPMODE X=A:B through. All-zero pipeline plus
  -- USE_MULT MULTIPLY would only $display and hold X.
  u_nh : entity unisim.DSP48E1
    generic map (
      ACASCREG => 0, ADREG => 0, ALUMODEREG => 0, AREG => 0, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0, USE_MULT => "NONE")
    port map (
      ACOUT => open, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => open,
      MULTSIGNOUT => open, OVERFLOW => open, P => pnh, PATTERNBDETECT => open,
      PATTERNDETECT => open, PCOUT => open, UNDERFLOW => open,
      A => a_n, ACIN => z30, ALUMODE => alum, B => b_n, BCIN => z18, C => z48,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '0', CEA2 => '0', CEAD => '0', CEALUMODE => '0', CEB1 => '0',
      CEB2 => '0', CEC => '0', CECARRYIN => '0', CECTRL => '0', CED => '0',
      CEINMODE => '0', CEM => '0', CEP => '0', CLK => '0', D => z25,
      INMODE => in_z, MULTSIGNIN => '0', OPMODE => op_n, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');
  u_nv : DSP48E1
    generic map (
      ACASCREG => 0, ADREG => 0, ALUMODEREG => 0, AREG => 0, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0, USE_MULT => "NONE")
    port map (
      ACOUT => open, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => open,
      MULTSIGNOUT => open, OVERFLOW => open, P => pnv, PATTERNBDETECT => open,
      PATTERNDETECT => open, PCOUT => open, UNDERFLOW => open,
      A => a_n, ACIN => z30, ALUMODE => alum, B => b_n, BCIN => z18, C => z48,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '0', CEA2 => '0', CEAD => '0', CEALUMODE => '0', CEB1 => '0',
      CEB2 => '0', CEC => '0', CECARRYIN => '0', CECTRL => '0', CED => '0',
      CEINMODE => '0', CEM => '0', CEP => '0', CLK => '0', D => z25,
      INMODE => in_z, MULTSIGNIN => '0', OPMODE => op_n, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');

  u_dh : entity unisim.DSP48E1
    generic map (
      ACASCREG => 0, ADREG => 0, ALUMODEREG => 0, AREG => 0, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0, USE_DPORT => TRUE)
    port map (
      ACOUT => open, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => open,
      MULTSIGNOUT => open, OVERFLOW => open, P => pdh, PATTERNBDETECT => open,
      PATTERNDETECT => open, PCOUT => open, UNDERFLOW => open,
      A => a_d, ACIN => z30, ALUMODE => alum, B => b_d, BCIN => z18, C => z48,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '0', CEA2 => '0', CEAD => '0', CEALUMODE => '0', CEB1 => '0',
      CEB2 => '0', CEC => '0', CECARRYIN => '0', CECTRL => '0', CED => '0',
      CEINMODE => '0', CEM => '0', CEP => '0', CLK => '0', D => d_d,
      INMODE => in_d, MULTSIGNIN => '0', OPMODE => op_d, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');
  u_dv : DSP48E1
    generic map (
      ACASCREG => 0, ADREG => 0, ALUMODEREG => 0, AREG => 0, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0, USE_DPORT => TRUE)
    port map (
      ACOUT => open, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => open,
      MULTSIGNOUT => open, OVERFLOW => open, P => pdv, PATTERNBDETECT => open,
      PATTERNDETECT => open, PCOUT => open, UNDERFLOW => open,
      A => a_d, ACIN => z30, ALUMODE => alum, B => b_d, BCIN => z18, C => z48,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '0', CEA2 => '0', CEAD => '0', CEALUMODE => '0', CEB1 => '0',
      CEB2 => '0', CEC => '0', CECARRYIN => '0', CECTRL => '0', CED => '0',
      CEINMODE => '0', CEM => '0', CEP => '0', CLK => '0', D => d_d,
      INMODE => in_d, MULTSIGNIN => '0', OPMODE => op_d, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');

  -- AREG 1 loads both stages from the same mux. One clock makes P = A*B.
  u_rh : entity unisim.DSP48E1
    generic map (
      ACASCREG => 1, ADREG => 0, ALUMODEREG => 0, AREG => 1, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0)
    port map (
      ACOUT => open, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => open,
      MULTSIGNOUT => open, OVERFLOW => open, P => prh, PATTERNBDETECT => open,
      PATTERNDETECT => open, PCOUT => open, UNDERFLOW => open,
      A => a_r, ACIN => z30, ALUMODE => alum, B => b_r, BCIN => z18, C => z48,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '1', CEA2 => '1', CEAD => '0', CEALUMODE => '0', CEB1 => '0',
      CEB2 => '0', CEC => '0', CECARRYIN => '0', CECTRL => '0', CED => '0',
      CEINMODE => '0', CEM => '0', CEP => '0', CLK => clk_r, D => z25,
      INMODE => in_z, MULTSIGNIN => '0', OPMODE => op_r, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');
  u_rv : DSP48E1
    generic map (
      ACASCREG => 1, ADREG => 0, ALUMODEREG => 0, AREG => 1, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0)
    port map (
      ACOUT => open, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => open,
      MULTSIGNOUT => open, OVERFLOW => open, P => prv, PATTERNBDETECT => open,
      PATTERNDETECT => open, PCOUT => open, UNDERFLOW => open,
      A => a_r, ACIN => z30, ALUMODE => alum, B => b_r, BCIN => z18, C => z48,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '1', CEA2 => '1', CEAD => '0', CEALUMODE => '0', CEB1 => '0',
      CEB2 => '0', CEC => '0', CECARRYIN => '0', CECTRL => '0', CED => '0',
      CEINMODE => '0', CEM => '0', CEP => '0', CLK => clk_r, D => z25,
      INMODE => in_z, MULTSIGNIN => '0', OPMODE => op_r, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');

  u2_h : entity unisim.DSP48E2
    generic map (
      ACASCREG => 0, ADREG => 0, ALUMODEREG => 0, AREG => 0, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0)
    port map (
      ACOUT => open, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => open,
      MULTSIGNOUT => open, OVERFLOW => open, P => p2h, PATTERNBDETECT => open,
      PATTERNDETECT => open, PCOUT => open, UNDERFLOW => open, XOROUT => xh,
      A => a2, ACIN => z30, ALUMODE => alum, B => bb2, BCIN => z18, C => c2,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '1', CEA2 => '1', CEAD => '1', CEALUMODE => '1', CEB1 => '1',
      CEB2 => '1', CEC => '1', CECARRYIN => '1', CECTRL => '1', CED => '1',
      CEINMODE => '1', CEM => '1', CEP => '1', CLK => clk, D => d27,
      INMODE => in_z, MULTSIGNIN => '0', OPMODE => op2, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');
  u2_v : DSP48E2
    generic map (
      ACASCREG => 0, ADREG => 0, ALUMODEREG => 0, AREG => 0, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0)
    port map (
      ACOUT => open, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => open,
      MULTSIGNOUT => open, OVERFLOW => open, P => p2v, PATTERNBDETECT => open,
      PATTERNDETECT => open, PCOUT => open, UNDERFLOW => open, XOROUT => xv,
      A => a2, ACIN => z30, ALUMODE => alum, B => bb2, BCIN => z18, C => c2,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '1', CEA2 => '1', CEAD => '1', CEALUMODE => '1', CEB1 => '1',
      CEB2 => '1', CEC => '1', CECARRYIN => '1', CECTRL => '1', CED => '1',
      CEINMODE => '1', CEM => '1', CEP => '1', CLK => clk, D => d27,
      INMODE => in_z, MULTSIGNIN => '0', OPMODE => op2, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');

  -- AREG 2, ACASCREG 1. ACOUT is stage 1. P follows stage 2.
  u2p_h : entity unisim.DSP48E2
    generic map (
      ACASCREG => 1, ADREG => 0, ALUMODEREG => 0, AREG => 2, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0)
    port map (
      ACOUT => ac_h, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => open,
      MULTSIGNOUT => open, OVERFLOW => open, P => pp_h, PATTERNBDETECT => open,
      PATTERNDETECT => open, PCOUT => open, UNDERFLOW => open, XOROUT => open,
      A => a_p, ACIN => z30, ALUMODE => alum, B => b_p, BCIN => z18, C => z48,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '1', CEA2 => '1', CEAD => '0', CEALUMODE => '0', CEB1 => '0',
      CEB2 => '0', CEC => '0', CECARRYIN => '0', CECTRL => '0', CED => '0',
      CEINMODE => '0', CEM => '0', CEP => '0', CLK => clk_p, D => z27,
      INMODE => in_z, MULTSIGNIN => '0', OPMODE => op_p, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');
  u2p_v : DSP48E2
    generic map (
      ACASCREG => 1, ADREG => 0, ALUMODEREG => 0, AREG => 2, BCASCREG => 0,
      BREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, CREG => 0, DREG => 0,
      INMODEREG => 0, MREG => 0, OPMODEREG => 0, PREG => 0)
    port map (
      ACOUT => ac_v, BCOUT => open, CARRYCASCOUT => open, CARRYOUT => open,
      MULTSIGNOUT => open, OVERFLOW => open, P => pp_v, PATTERNBDETECT => open,
      PATTERNDETECT => open, PCOUT => open, UNDERFLOW => open, XOROUT => open,
      A => a_p, ACIN => z30, ALUMODE => alum, B => b_p, BCIN => z18, C => z48,
      CARRYCASCIN => '0', CARRYIN => cin, CARRYINSEL => csel,
      CEA1 => '1', CEA2 => '1', CEAD => '0', CEALUMODE => '0', CEB1 => '0',
      CEB2 => '0', CEC => '0', CECARRYIN => '0', CECTRL => '0', CED => '0',
      CEINMODE => '0', CEM => '0', CEP => '0', CLK => clk_p, D => z27,
      INMODE => in_z, MULTSIGNIN => '0', OPMODE => op_p, PCIN => z48,
      RSTA => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTB => '0',
      RSTC => '0', RSTCTRL => '0', RSTD => '0', RSTINMODE => '0', RSTM => '0',
      RSTP => '0');

  stim : process
    variable n : natural := 0;
    variable exp : std_logic_vector(47 downto 0);

    procedure settle is
    begin
      wait for step;
      wait for step;
    end procedure;

    procedure rise(signal c : out std_ulogic) is
    begin
      c <= '0';
      settle;
      c <= '1';
      settle;
    end procedure;

    procedure eqv(name : string; got, expv : std_logic_vector) is
    begin
      n := n + 1;
      if got /= expv then
        report name & " VHDL=" & to_string(got) & " exp=" & to_string(expv) severity failure;
      end if;
    end procedure;

    procedure eqs(name : string; got, expv : std_ulogic) is
    begin
      n := n + 1;
      if got /= expv then
        report name & " VHDL=" & std_ulogic'image(got) & " exp=" & std_ulogic'image(expv)
          severity failure;
      end if;
    end procedure;

    procedure eqp(name : string; got, other : std_logic_vector) is
    begin
      eqv(name, got, from_vlog(other));
    end procedure;
  begin
    wait for 120 ns;

    -- The Verilog copies each input in an always @(input), which does not
    -- run for a value that never changes. Pulse the controls, then return
    -- them to the arithmetic multiply defaults.
    alum <= "0001";
    csel <= "001";
    cin <= '1';
    inmode <= "00001";
    in_z <= "00001";
    in_d <= "00001";
    a <= (others => '1');
    b <= (others => '1');
    a_n <= (others => '1');
    b_n <= (others => '1');
    a_d <= (others => '1');
    b_d <= (others => '1');
    a_r <= (others => '1');
    b_r <= (others => '1');
    a2 <= (others => '1');
    bb2 <= (others => '1');
    a_p <= (others => '1');
    b_p <= (others => '1');
    op7 <= "0000001";
    op_n <= "0000001";
    op_d <= "0000001";
    op_r <= "0000001";
    op2 <= "000000001";
    op_p <= "000000001";
    settle;
    alum <= (others => '0');
    csel <= (others => '0');
    cin <= '0';
    inmode <= (others => '0');
    in_z <= (others => '0');
    in_d <= (others => '0');
    a <= (others => '0');
    b <= (others => '0');
    a_n <= (others => '0');
    b_n <= (others => '0');
    a_d <= (others => '0');
    b_d <= (others => '0');
    a_r <= (others => '0');
    b_r <= (others => '0');
    a2 <= (others => '0');
    bb2 <= (others => '0');
    a_p <= (others => '0');
    b_p <= (others => '0');
    op7 <= (others => '0');
    op_n <= (others => '0');
    op_d <= (others => '0');
    op_r <= (others => '0');
    op2 <= (others => '0');
    op_p <= (others => '0');
    settle;

    a <= slv(7, 30);
    b <= slv(9, 18);
    op7 <= "0000101";
    settle;
    eqp("e1 7x9", ph, pv);
    eqs("e1 sign", mh, from_vlog(mv));
    eqp("e1 carry", coh, cov);
    eqs("e1 pdet", dh, '0');
    eqs("e1 pdetb", bh, '0');

    a <= (others => '0');
    b <= (others => '0');
    op7 <= "0000000";
    settle;
    eqs("e1 zero pdet", dh, '1');
    eqs("e1 zero pdetb", bh, '0');
    eqs("e1 ovf", oh, '0');

    a <= slv(7, 30);
    b <= slv(9, 18);
    c <= slv(10, 48);
    op7 <= "0110101";
    settle;
    eqp("e1 7x9+c", ph, pv);

    a <= (others => '1');
    b <= slv(2, 18);
    c <= (others => '0');
    op7 <= "0000101";
    settle;
    eqp("e1 neg", ph, pv);
    eqs("e1 neg sign", mh, '1');

    a_n <= slv(5, 30);
    b_n <= slv(7, 18);
    op_n <= "0000011";
    settle;
    exp := slv(5, 30) & slv(7, 18);
    eqp("e1 ab", pnh, pnv);
    eqv("e1 ab val", pnh, exp);

    a_d <= slv(3, 30);
    b_d <= slv(2, 18);
    d_d <= slv(20, 25);
    in_d <= "00100";
    op_d <= "0000000";
    settle;
    op_d <= "0000101";
    settle;
    eqp("e1 d add", pdh, pdv);
    eqv("e1 d add val", pdh, slv(46, 48));
    in_d <= "01100";
    settle;
    eqp("e1 d sub", pdh, pdv);
    eqv("e1 d sub val", pdh, slv(34, 48));

    a_r <= slv(7, 30);
    b_r <= slv(9, 18);
    op_r <= "0000101";
    settle;
    rise(clk_r);
    eqp("e1 areg1", prh, prv);
    eqv("e1 areg1 val", prh, slv(63, 48));

    a2 <= slv(7, 30);
    bb2 <= slv(9, 18);
    op2 <= "000000101";
    settle;
    eqp("e2 7x9", p2h, p2v);
    eqv("e2 7x9 val", p2h, slv(63, 48));
    eqp("e2 xor", xh, xv);

    a2 <= (others => '0');
    bb2 <= slv(7, 18);
    c2 <= slv(10, 48);
    op2 <= "000110011";
    settle;
    eqp("e2 ab+c", p2h, p2v);
    eqv("e2 ab+c val", p2h, slv(17, 48));

    a_p <= slv(7, 30);
    b_p <= slv(9, 18);
    op_p <= "000000101";
    settle;
    rise(clk_p);
    eqp("e2 acout1", ac_h, ac_v);
    eqv("e2 acout val", ac_h, slv(7, 30));
    rise(clk_p);
    eqp("e2 areg2", pp_h, pp_v);
    eqv("e2 areg2 val", pp_h, slv(63, 48));

    report "tb_eq_dsp48 PASS checks=" & integer'image(n);
    finish(0);
  end process;
end architecture sim;
