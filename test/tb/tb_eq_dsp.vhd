-- DSP_* sub-blocks. DSP_PREADD and DSP_MULTIPLIER are combinational
-- and are compared with the Verilog analysed under XIL_TIMING. The
-- registered cells read delay nets that stay undriven in that netlist,
-- so they are checked against the Verilog equations. GSR is checked
-- on the VHDL models only.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library unisim;

entity tb_eq_dsp is
end entity tb_eq_dsp;

architecture sim of tb_eq_dsp is
  constant step : time := 5 ns;
  constant u_none : std_logic_vector(44 downto 0) := (44 => '1', others => '0');

  signal d_pre, ab_pre : std_logic_vector(26 downto 0) := (others => '0');
  signal in2, addsub : std_ulogic := '0';
  signal ad_h, ad_v : std_logic_vector(26 downto 0);
  signal in2x : std_ulogic := 'X';
  signal adx_h, adx_v : std_logic_vector(26 downto 0);

  signal a27, ad27 : std_logic_vector(26 downto 0) := (others => '0');
  signal b18 : std_logic_vector(17 downto 0) := (others => '0');
  signal u_h, u_v, v_h, v_v : std_logic_vector(44 downto 0);
  signal am_h, am_v, bm_h, bm_v : std_ulogic;
  signal u_n, u_nv, v_n, v_nv : std_logic_vector(44 downto 0);
  signal am_n, bm_n, am_nv, bm_nv : std_ulogic;
  signal a_ad, b_ad : std_logic_vector(26 downto 0) := (others => '0');
  signal b_ad18 : std_logic_vector(17 downto 0) := (others => '0');
  signal u_ad, u_adv, v_ad, v_adv : std_logic_vector(44 downto 0);

  signal c_bus : std_logic_vector(47 downto 0) := (others => '1');
  signal cec, clkc, rstc : std_ulogic := '0';
  signal cd_h : std_logic_vector(47 downto 0);
  signal c0 : std_logic_vector(47 downto 0) := (others => '1');
  signal cd0 : std_logic_vector(47 downto 0);
  signal ci : std_logic_vector(47 downto 0) := (others => '0');
  signal clki, rsti : std_ulogic := '1';
  signal cdi : std_logic_vector(47 downto 0);

  signal u_m, v_m : std_logic_vector(44 downto 0) := (others => '0');
  signal cem, clkm, rstm : std_ulogic := '0';
  signal ud, vd : std_logic_vector(44 downto 0);
  signal ud0, vd0 : std_logic_vector(44 downto 0);

  signal a_bus : std_logic_vector(29 downto 0) := (others => '0');
  signal b_bus : std_logic_vector(17 downto 0) := (others => '0');
  signal acin, bcin : std_logic_vector(29 downto 0) := (others => '0');
  signal bcin18 : std_logic_vector(17 downto 0) := (others => '0');
  signal cea1, cea2, ceb1, ceb2, clka, rsta, rstb : std_ulogic := '0';
  signal a1d, a2d : std_logic_vector(26 downto 0);
  signal acout, aalu : std_logic_vector(29 downto 0);
  signal b1d, b2d, bcout, balu : std_logic_vector(17 downto 0);
  signal az : std_logic_vector(29 downto 0) := (others => '0');
  signal aalu0 : std_logic_vector(29 downto 0);
  signal balu0 : std_logic_vector(17 downto 0);
  signal ac_alu : std_logic_vector(29 downto 0);

  signal a1p, a2p : std_logic_vector(26 downto 0) := (others => '0');
  signal b1p, b2p : std_logic_vector(17 downto 0) := (others => '0');
  signal din_p : std_logic_vector(26 downto 0) := (others => '0');
  signal ad_p : std_logic_vector(26 downto 0) := (others => '0');
  signal inmode : std_logic_vector(4 downto 0) := (others => '0');
  signal clkp, cein, ced, cead, rstd, rstin : std_ulogic := '0';
  signal a2a1, ddata, addata, pre_ab : std_logic_vector(26 downto 0);
  signal b2b1 : std_logic_vector(17 downto 0);
  signal addsub_p, inmode2_p : std_ulogic;
  signal a2a1_b, pre_b : std_logic_vector(26 downto 0);
  signal b2b1_b : std_logic_vector(17 downto 0);
  signal d_off : std_logic_vector(26 downto 0);
  signal in0 : std_logic_vector(4 downto 0) := (others => '0');
  signal a2a1_i : std_logic_vector(26 downto 0);
  signal din_z : std_logic_vector(26 downto 0) := (others => '0');
  signal d_z : std_logic_vector(26 downto 0);
  signal ad_r, din_r : std_logic_vector(26 downto 0) := (others => '0');
  signal clk_r, ce_r, rstd_r : std_ulogic := '0';
  signal ad_out, d_out : std_logic_vector(26 downto 0);

  signal opmode : std_logic_vector(8 downto 0) := "000000101";
  signal alumode : std_logic_vector(3 downto 0) := (others => '0');
  signal csel : std_logic_vector(2 downto 0) := (others => '0');
  signal carryin : std_ulogic := '0';
  signal a_alu_i : std_logic_vector(29 downto 0) := (others => '0');
  signal b_alu_i : std_logic_vector(17 downto 0) := (others => '0');
  signal c_alu : std_logic_vector(47 downto 0) := (others => '0');
  signal alu_out : std_logic_vector(47 downto 0);
  signal cout : std_logic_vector(3 downto 0);
  signal xormx : std_logic_vector(7 downto 0);
  signal alum10, msign : std_ulogic;
  signal op_r : std_logic_vector(8 downto 0) := (others => '0');
  signal clk_alu, cectrl : std_ulogic := '0';
  signal alu_r : std_logic_vector(47 downto 0);
  signal a4 : std_logic_vector(29 downto 0) := (others => '0');
  signal b4 : std_logic_vector(17 downto 0) := (others => '0');
  signal c4 : std_logic_vector(47 downto 0) := (others => '0');
  signal alu4 : std_logic_vector(47 downto 0);
  signal cout4 : std_logic_vector(3 downto 0);
  signal alu_w : std_logic_vector(47 downto 0);
  signal xor_w : std_logic_vector(7 downto 0);

  signal alu_o : std_logic_vector(47 downto 0) := (others => '0');
  signal cout_o : std_logic_vector(3 downto 0) := (others => '0');
  signal xor_o : std_logic_vector(7 downto 0) := (others => '0');
  signal c_o : std_logic_vector(47 downto 0) := (others => '0');
  signal alum_o, msign_o, cep, clko, rstp : std_ulogic := '0';
  signal p_o, pcout, pfdbk : std_logic_vector(47 downto 0);
  signal carryout : std_logic_vector(3 downto 0);
  signal xorout : std_logic_vector(7 downto 0);
  signal ccout, ccasc, ovf, unf, pdet, pdetb, pf47, mso : std_ulogic;
  signal p_p : std_logic_vector(47 downto 0);
  signal pdet_p, pdetb_p, ovf_n : std_ulogic;
  signal alu_m : std_logic_vector(47 downto 0) := (others => '0');
  signal clk_m2, cep_m : std_ulogic := '0';
  signal p_m : std_logic_vector(47 downto 0);
  signal pdet_m : std_ulogic;
  signal p_c, pc_c : std_logic_vector(47 downto 0);
  signal pdet_c : std_ulogic;

  signal chain_ad, chain_d, chain_ab, chain_a : std_logic_vector(26 downto 0);
  signal chain_b : std_logic_vector(17 downto 0);
  signal chain_in2, chain_sub : std_ulogic;
  signal chain_sum : std_logic_vector(26 downto 0);
  signal chain_u, ref_u : std_logic_vector(44 downto 0);

  function slv(n, w : natural) return std_logic_vector is
  begin
    return std_logic_vector(to_unsigned(n, w));
  end function;

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

  component DSP_PREADD is
    port (
      AD : out std_logic_vector(26 downto 0);
      ADDSUB : in std_ulogic;
      D_DATA : in std_logic_vector(26 downto 0);
      INMODE2 : in std_ulogic;
      PREADD_AB : in std_logic_vector(26 downto 0)
    );
  end component;

  component DSP_MULTIPLIER is
    generic (
      AMULTSEL : string := "A";
      BMULTSEL : string := "B";
      USE_MULT : string := "MULTIPLY"
    );
    port (
      AMULT26 : out std_ulogic;
      BMULT17 : out std_ulogic;
      U : out std_logic_vector(44 downto 0);
      V : out std_logic_vector(44 downto 0);
      A2A1 : in std_logic_vector(26 downto 0);
      AD_DATA : in std_logic_vector(26 downto 0);
      B2B1 : in std_logic_vector(17 downto 0)
    );
  end component;

begin
  u_pre_h : entity unisim.DSP_PREADD
    port map (AD => ad_h, ADDSUB => addsub, D_DATA => d_pre, INMODE2 => in2, PREADD_AB => ab_pre);
  u_pre_v : DSP_PREADD
    port map (AD => ad_v, ADDSUB => addsub, D_DATA => d_pre, INMODE2 => in2, PREADD_AB => ab_pre);
  u_prex_h : entity unisim.DSP_PREADD
    port map (AD => adx_h, ADDSUB => '0', D_DATA => d_pre, INMODE2 => in2x, PREADD_AB => ab_pre);
  u_prex_v : DSP_PREADD
    port map (AD => adx_v, ADDSUB => '0', D_DATA => d_pre, INMODE2 => in2x, PREADD_AB => ab_pre);

  u_mul_h : entity unisim.DSP_MULTIPLIER
    port map (AMULT26 => am_h, BMULT17 => bm_h, U => u_h, V => v_h,
              A2A1 => a27, AD_DATA => ad27, B2B1 => b18);
  u_mul_v : DSP_MULTIPLIER
    port map (AMULT26 => am_v, BMULT17 => bm_v, U => u_v, V => v_v,
              A2A1 => a27, AD_DATA => ad27, B2B1 => b18);
  u_none_h : entity unisim.DSP_MULTIPLIER generic map (USE_MULT => "NONE")
    port map (AMULT26 => am_n, BMULT17 => bm_n, U => u_n, V => v_n,
              A2A1 => a27, AD_DATA => ad27, B2B1 => b18);
  u_none_v : DSP_MULTIPLIER generic map (USE_MULT => "NONE")
    port map (AMULT26 => am_nv, BMULT17 => bm_nv, U => u_nv, V => v_nv,
              A2A1 => a27, AD_DATA => ad27, B2B1 => b18);
  u_ad_h : entity unisim.DSP_MULTIPLIER generic map (AMULTSEL => "AD")
    port map (AMULT26 => open, BMULT17 => open, U => u_ad, V => v_ad,
              A2A1 => a27, AD_DATA => a_ad, B2B1 => b_ad18);
  u_ad_v : DSP_MULTIPLIER generic map (AMULTSEL => "AD")
    port map (AMULT26 => open, BMULT17 => open, U => u_adv, V => v_adv,
              A2A1 => a27, AD_DATA => a_ad, B2B1 => b_ad18);

  u_c : entity unisim.DSP_C_DATA
    port map (C_DATA => cd_h, C => c_bus, CEC => cec, CLK => clkc, RSTC => rstc);
  u_c0 : entity unisim.DSP_C_DATA generic map (CREG => 0)
    port map (C_DATA => cd0, C => c0, CEC => '0', CLK => '0', RSTC => '0');
  u_ci : entity unisim.DSP_C_DATA
    generic map (IS_CLK_INVERTED => '1', IS_RSTC_INVERTED => '1')
    port map (C_DATA => cdi, C => ci, CEC => '1', CLK => clki, RSTC => rsti);

  u_md : entity unisim.DSP_M_DATA
    port map (U_DATA => ud, V_DATA => vd, CEM => cem, CLK => clkm, RSTM => rstm, U => u_m, V => v_m);
  u_md0 : entity unisim.DSP_M_DATA generic map (MREG => 0)
    port map (U_DATA => ud0, V_DATA => vd0, CEM => '0', CLK => '0', RSTM => '0', U => u_m, V => v_m);

  u_ab2 : entity unisim.DSP_A_B_DATA
    generic map (ACASCREG => 1, AREG => 2, BCASCREG => 1, BREG => 2)
    port map (
      A1_DATA => a1d, A2_DATA => a2d, ACOUT => acout, A_ALU => aalu,
      B1_DATA => b1d, B2_DATA => b2d, BCOUT => bcout, B_ALU => balu,
      A => a_bus, ACIN => (others => '0'), B => b_bus, BCIN => (others => '0'),
      CEA1 => cea1, CEA2 => cea2, CEB1 => ceb1, CEB2 => ceb2,
      CLK => clka, RSTA => rsta, RSTB => rstb);
  u_ab0 : entity unisim.DSP_A_B_DATA
    generic map (ACASCREG => 0, AREG => 0, BCASCREG => 0, BREG => 0)
    port map (
      A1_DATA => open, A2_DATA => open, ACOUT => open, A_ALU => aalu0,
      B1_DATA => open, B2_DATA => open, BCOUT => open, B_ALU => balu0,
      A => az, ACIN => (others => '0'), B => b_bus, BCIN => (others => '0'),
      CEA1 => '0', CEA2 => '0', CEB1 => '0', CEB2 => '0',
      CLK => '0', RSTA => '0', RSTB => '0');
  u_abc : entity unisim.DSP_A_B_DATA
    generic map (AREG => 0, A_INPUT => "CASCADE")
    port map (
      A1_DATA => open, A2_DATA => open, ACOUT => open, A_ALU => ac_alu,
      B1_DATA => open, B2_DATA => open, BCOUT => open, B_ALU => open,
      A => a_bus, ACIN => acin, B => b_bus, BCIN => bcin18,
      CEA1 => '0', CEA2 => '0', CEB1 => '0', CEB2 => '0',
      CLK => '0', RSTA => '0', RSTB => '0');

  u_pd : entity unisim.DSP_PREADD_DATA
    port map (
      A2A1 => a2a1, ADDSUB => addsub_p, AD_DATA => addata, B2B1 => b2b1,
      D_DATA => ddata, INMODE_2 => inmode2_p, PREADD_AB => pre_ab,
      A1_DATA => a1p, A2_DATA => a2p, AD => ad_p, B1_DATA => b1p, B2_DATA => b2p,
      CEAD => cead, CED => ced, CEINMODE => cein, CLK => clkp, DIN => din_p,
      INMODE => inmode, RSTD => rstd, RSTINMODE => rstin);
  u_pdb : entity unisim.DSP_PREADD_DATA
    generic map (INMODEREG => 0, PREADDINSEL => "B")
    port map (
      A2A1 => a2a1_b, ADDSUB => open, AD_DATA => open, B2B1 => b2b1_b,
      D_DATA => open, INMODE_2 => open, PREADD_AB => pre_b,
      A1_DATA => a1p, A2_DATA => a2p, AD => ad_p, B1_DATA => b1p, B2_DATA => b2p,
      CEAD => '0', CED => '0', CEINMODE => '0', CLK => '0', DIN => din_p,
      INMODE => inmode, RSTD => '0', RSTINMODE => '0');
  u_pdn : entity unisim.DSP_PREADD_DATA
    generic map (DREG => 1, USE_MULT => "NONE")
    port map (
      A2A1 => open, ADDSUB => open, AD_DATA => open, B2B1 => open,
      D_DATA => d_off, INMODE_2 => open, PREADD_AB => open,
      A1_DATA => a1p, A2_DATA => a2p, AD => ad_p, B1_DATA => b1p, B2_DATA => b2p,
      CEAD => '0', CED => '1', CEINMODE => '0', CLK => clkp, DIN => din_p,
      INMODE => inmode, RSTD => '0', RSTINMODE => '0');
  u_pdi : entity unisim.DSP_PREADD_DATA
    generic map (INMODEREG => 0, IS_INMODE_INVERTED => "00001")
    port map (
      A2A1 => a2a1_i, ADDSUB => open, AD_DATA => open, B2B1 => open,
      D_DATA => d_z, INMODE_2 => open, PREADD_AB => open,
      A1_DATA => a1p, A2_DATA => a2p, AD => ad_p, B1_DATA => b1p, B2_DATA => b2p,
      CEAD => '0', CED => '0', CEINMODE => '0', CLK => '0', DIN => din_z,
      INMODE => in0, RSTD => '0', RSTINMODE => '0');
  u_pdr : entity unisim.DSP_PREADD_DATA
    generic map (ADREG => 1, AMULTSEL => "AD", BMULTSEL => "AD", DREG => 1, INMODEREG => 0)
    port map (
      A2A1 => open, ADDSUB => open, AD_DATA => ad_out, B2B1 => open,
      D_DATA => d_out, INMODE_2 => open, PREADD_AB => open,
      A1_DATA => a1p, A2_DATA => a2p, AD => ad_r, B1_DATA => b1p, B2_DATA => b2p,
      CEAD => ce_r, CED => ce_r, CEINMODE => '0', CLK => clk_r, DIN => din_r,
      INMODE => in0, RSTD => rstd_r, RSTINMODE => '0');

  u_alu : entity unisim.DSP_ALU
    generic map (
      ALUMODEREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, MREG => 0, OPMODEREG => 0,
      RND => X"000000000005")
    port map (
      ALUMODE10 => alum10, ALU_OUT => alu_out, COUT => cout, MULTSIGN_ALU => msign,
      XOR_MX => xormx, ALUMODE => alumode, AMULT26 => am_h, A_ALU => a_alu_i,
      BMULT17 => bm_h, B_ALU => b_alu_i, CARRYCASCIN => '0', CARRYIN => carryin,
      CARRYINSEL => csel, CCOUT => '0', CEALUMODE => '0', CECARRYIN => '0',
      CECTRL => '0', CEM => '0', CLK => '0', C_DATA => c_alu, MULTSIGNIN => '0',
      OPMODE => opmode, PCIN => (others => '0'), P_FDBK => (others => '0'),
      P_FDBK_47 => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTCTRL => '0',
      U_DATA => u_h, V_DATA => v_h);
  u_alur : entity unisim.DSP_ALU
    generic map (ALUMODEREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, MREG => 0, OPMODEREG => 1)
    port map (
      ALUMODE10 => open, ALU_OUT => alu_r, COUT => open, MULTSIGN_ALU => open,
      XOR_MX => open, ALUMODE => (others => '0'), AMULT26 => '0', A_ALU => a_alu_i,
      BMULT17 => '0', B_ALU => b_alu_i, CARRYCASCIN => '0', CARRYIN => '0',
      CARRYINSEL => "000", CCOUT => '0', CEALUMODE => '0', CECARRYIN => '0',
      CECTRL => cectrl, CEM => '0', CLK => clk_alu, C_DATA => (others => '0'),
      MULTSIGNIN => '0', OPMODE => op_r, PCIN => (others => '0'),
      P_FDBK => (others => '0'), P_FDBK_47 => '0', RSTALLCARRYIN => '0',
      RSTALUMODE => '0', RSTCTRL => '0', U_DATA => (others => '0'), V_DATA => (others => '0'));
  u_alu4 : entity unisim.DSP_ALU
    generic map (
      ALUMODEREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, MREG => 0,
      OPMODEREG => 0, USE_SIMD => "FOUR12")
    port map (
      ALUMODE10 => open, ALU_OUT => alu4, COUT => cout4, MULTSIGN_ALU => open,
      XOR_MX => open, ALUMODE => (others => '0'), AMULT26 => '0', A_ALU => a4,
      BMULT17 => '0', B_ALU => b4, CARRYCASCIN => '0', CARRYIN => '0',
      CARRYINSEL => "000", CCOUT => '0', CEALUMODE => '0', CECARRYIN => '0',
      CECTRL => '0', CEM => '0', CLK => '0', C_DATA => c4, MULTSIGNIN => '0',
      OPMODE => "000110011", PCIN => (others => '0'), P_FDBK => (others => '0'),
      P_FDBK_47 => '0', RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTCTRL => '0',
      U_DATA => (others => '0'), V_DATA => (others => '0'));
  u_aluw : entity unisim.DSP_ALU
    generic map (
      ALUMODEREG => 0, CARRYINREG => 0, CARRYINSELREG => 0, MREG => 0,
      OPMODEREG => 0, RND => X"000000000005", USE_WIDEXOR => TRUE, XORSIMD => "XOR12")
    port map (
      ALUMODE10 => open, ALU_OUT => alu_w, COUT => open, MULTSIGN_ALU => open,
      XOR_MX => xor_w, ALUMODE => (others => '0'), AMULT26 => '0',
      A_ALU => (others => '0'), BMULT17 => '0', B_ALU => slv(1, 18),
      CARRYCASCIN => '0', CARRYIN => '0', CARRYINSEL => "000", CCOUT => '0',
      CEALUMODE => '0', CECARRYIN => '0', CECTRL => '0', CEM => '0', CLK => '0',
      C_DATA => (others => '0'), MULTSIGNIN => '0', OPMODE => "000000011",
      PCIN => (others => '0'), P_FDBK => (others => '0'), P_FDBK_47 => '0',
      RSTALLCARRYIN => '0', RSTALUMODE => '0', RSTCTRL => '0',
      U_DATA => (others => '0'), V_DATA => (others => '0'));

  u_out : entity unisim.DSP_OUTPUT
    generic map (PREG => 0, USE_PATTERN_DETECT => "PATDET", MASK => X"000000000000")
    port map (
      CARRYCASCOUT => ccasc, CARRYOUT => carryout, CCOUT_FB => ccout,
      MULTSIGNOUT => mso, OVERFLOW => ovf, P => p_o, PATTERN_B_DETECT => pdetb,
      PATTERN_DETECT => pdet, PCOUT => pcout, P_FDBK => pfdbk, P_FDBK_47 => pf47,
      UNDERFLOW => unf, XOROUT => xorout, ALUMODE10 => alum_o, ALU_OUT => alu_o,
      CEP => cep, CLK => clko, COUT => cout_o, C_DATA => c_o, MULTSIGN_ALU => msign_o,
      RSTP => rstp, XOR_MX => xor_o);
  u_outn : entity unisim.DSP_OUTPUT generic map (PREG => 0)
    port map (
      CARRYCASCOUT => open, CARRYOUT => open, CCOUT_FB => open, MULTSIGNOUT => open,
      OVERFLOW => ovf_n, P => p_p, PATTERN_B_DETECT => pdetb_p, PATTERN_DETECT => pdet_p,
      PCOUT => open, P_FDBK => open, P_FDBK_47 => open, UNDERFLOW => open, XOROUT => open,
      ALUMODE10 => '0', ALU_OUT => alu_o, CEP => '0', CLK => '0', COUT => "0000",
      C_DATA => (others => '0'), MULTSIGN_ALU => '0', RSTP => '0', XOR_MX => (others => '0'));
  u_outm : entity unisim.DSP_OUTPUT
    generic map (AUTORESET_PATDET => "RESET_MATCH", PREG => 1,
                 USE_PATTERN_DETECT => "PATDET", MASK => X"000000000000")
    port map (
      CARRYCASCOUT => open, CARRYOUT => open, CCOUT_FB => open, MULTSIGNOUT => open,
      OVERFLOW => open, P => p_m, PATTERN_B_DETECT => open, PATTERN_DETECT => pdet_m,
      PCOUT => open, P_FDBK => open, P_FDBK_47 => open, UNDERFLOW => open, XOROUT => open,
      ALUMODE10 => '0', ALU_OUT => alu_m, CEP => cep_m, CLK => clk_m2, COUT => "0000",
      C_DATA => (others => '0'), MULTSIGN_ALU => '0', RSTP => '0', XOR_MX => (others => '0'));
  u_outc : entity unisim.DSP_OUTPUT
    generic map (PREG => 0, SEL_PATTERN => "C", USE_PATTERN_DETECT => "PATDET",
                 MASK => X"000000000000")
    port map (
      CARRYCASCOUT => open, CARRYOUT => open, CCOUT_FB => open, MULTSIGNOUT => open,
      OVERFLOW => open, P => p_c, PATTERN_B_DETECT => open, PATTERN_DETECT => pdet_c,
      PCOUT => pc_c, P_FDBK => open, P_FDBK_47 => open, UNDERFLOW => open, XOROUT => open,
      ALUMODE10 => '0', ALU_OUT => alu_o, CEP => '0', CLK => '0', COUT => "0000",
      C_DATA => c_o, MULTSIGN_ALU => '0', RSTP => '0', XOR_MX => (others => '0'));

  u_ch_pd : entity unisim.DSP_PREADD_DATA generic map (INMODEREG => 0, DREG => 0, ADREG => 0)
    port map (
      A2A1 => chain_a, ADDSUB => chain_sub, AD_DATA => open, B2B1 => chain_b,
      D_DATA => chain_d, INMODE_2 => chain_in2, PREADD_AB => chain_ab,
      A1_DATA => (others => '0'), A2_DATA => slv(5, 27), AD => (others => '0'),
      B1_DATA => (others => '0'), B2_DATA => (others => '0'),
      CEAD => '0', CED => '0', CEINMODE => '0', CLK => '0', DIN => (others => '0'),
      INMODE => "00000", RSTD => '0', RSTINMODE => '0');
  u_ch_add : entity unisim.DSP_PREADD
    port map (AD => chain_sum, ADDSUB => chain_sub, D_DATA => chain_d,
              INMODE2 => chain_in2, PREADD_AB => chain_ab);
  u_ch_mul : entity unisim.DSP_MULTIPLIER generic map (AMULTSEL => "AD")
    port map (AMULT26 => open, BMULT17 => open, U => chain_u, V => open,
              A2A1 => chain_a, AD_DATA => chain_sum, B2B1 => slv(3, 18));
  u_ch_ref : entity unisim.DSP_MULTIPLIER
    port map (AMULT26 => open, BMULT17 => open, U => ref_u, V => open,
              A2A1 => slv(5, 27), AD_DATA => (others => '0'), B2B1 => slv(3, 18));

  stim : process
    variable n : natural := 0;

    procedure settle is
    begin
      wait for step;
      wait for step;
    end procedure;

    procedure rise(signal c : out std_ulogic) is
    begin
      c <= '1';
      settle;
    end procedure;

    procedure fall(signal c : out std_ulogic) is
    begin
      c <= '0';
      settle;
    end procedure;

    procedure eqv(name : string; got, exp : std_logic_vector) is
    begin
      n := n + 1;
      if got /= exp then
        report name & " VHDL=" & to_string(got) & " exp=" & to_string(exp)
          severity failure;
      end if;
    end procedure;

    procedure eqs(name : string; got, exp : std_ulogic) is
    begin
      n := n + 1;
      if got /= exp then
        report name & " VHDL=" & std_ulogic'image(got) & " exp=" & std_ulogic'image(exp)
          severity failure;
      end if;
    end procedure;

    procedure eq_pre(name : string) is
    begin
      eqv(name, ad_h, from_vlog(ad_v));
    end procedure;

    procedure eq_mul(name : string) is
    begin
      eqv(name & " u", u_h, from_vlog(u_v));
      eqv(name & " v", v_h, from_vlog(v_v));
      eqs(name & " am", am_h, from_vlog(am_v));
      eqs(name & " bm", bm_h, from_vlog(bm_v));
    end procedure;
  begin
    cec <= '1';
    cea1 <= '1';
    cea2 <= '1';
    ceb1 <= '1';
    ceb2 <= '1';
    cem <= '1';
    a_bus <= slv(341, 30);
    b_bus <= slv(17, 18);
    az <= (0 => 'Z', others => '0');
    acin <= slv(99, 30);
    wait for 50 ns;
    eqv("gsr c", cd_h, slv(0, 48));
    eqv("gsr creg0", cd0, (47 downto 0 => '1'));
    eqv("gsr p", p_o, slv(0, 48));
    eqv("gsr m", ud, slv(0, 45));
    wait for 70 ns;

    d_pre <= slv(20, 27);
    ab_pre <= slv(3, 27);
    in2 <= '1';
    addsub <= '0';
    settle;
    eq_pre("add");
    eqv("add 23", ad_h, slv(23, 27));
    addsub <= '1';
    settle;
    eq_pre("sub");
    eqv("sub 17", ad_h, slv(17, 27));
    in2 <= '0';
    settle;
    eq_pre("in0 sub");
    eqv("neg3", ad_h, slv(134217725, 27));
    addsub <= '0';
    settle;
    eq_pre("in0 add");
    eqv("plus3", ad_h, slv(3, 27));
    eqv("in x", adx_h, from_vlog(adx_v));
    eqv("in x val", adx_h, (26 downto 0 => 'X'));

    a27 <= slv(7, 27);
    b18 <= slv(9, 18);
    settle;
    eq_mul("7x9");
    eqv("none u", u_n, from_vlog(u_nv));
    eqv("none v", v_n, from_vlog(v_nv));
    eqv("none zero", u_n, u_none);
    eqv("none v", v_n, u_none);
    eqs("none am", am_n, '0');
    a_ad <= slv(7, 27);
    b_ad18 <= slv(9, 18);
    settle;
    eqv("ad u", u_ad, from_vlog(u_adv));
    eqv("ad same", u_ad, u_h);

    eqv("alu 7x9", alu_out, slv(63, 48));
    eqs("alu sign", msign, '0');
    eqs("alu alumode10", alum10, '0');
    eqs("alu cout3", cout(3), '1');
    eqs("alu cout2", cout(2), 'X');
    eqs("alu cout1", cout(1), 'X');
    eqs("alu cout0", cout(0), 'X');
    eqv("alu xor", xormx, slv(0, 8));

    opmode <= "000000011";
    b_alu_i <= slv(7, 18);
    settle;
    eqv("alu ab", alu_out, slv(7, 48));
    opmode <= "000110011";
    c_alu <= slv(10, 48);
    settle;
    eqv("alu ab+c", alu_out, slv(17, 48));
    opmode <= "000000000";
    carryin <= '1';
    settle;
    eqv("alu cin", alu_out, slv(1, 48));

    a4 <= slv(16#40040#, 30);
    b4 <= slv(16#1001#, 18);
    c4 <= x"001001001001";
    settle;
    eqv("four12", alu4, x"002002002002");
    eqs("four12 cout0", cout4(0), '0');

    opmode <= "100000000";
    carryin <= '0';
    c_alu <= (others => '0');
    settle;
    eqv("rnd", alu_out, slv(5, 48));
    eqv("xor12", xor_w, slv(1, 8));
    eqv("xor src", alu_w, slv(1, 48));

    op_r <= "000000011";
    cectrl <= '1';
    a_alu_i <= (others => '0');
    b_alu_i <= slv(9, 18);
    eqv("opmode reg before", alu_r, slv(0, 48));
    rise(clk_alu);
    eqv("opmode reg", alu_r, slv(9, 48));
    fall(clk_alu);

    eqv("creg0", cd0, c0);
    c0(0) <= 'Z';
    settle;
    eqs("c rv1 z", cd0(0), '1');
    rise(clkc);
    eqv("creg", cd_h, c_bus);
    fall(clkc);
    cec <= '0';
    c_bus <= slv(5, 48);
    rise(clkc);
    eqv("ce hold", cd_h, (47 downto 0 => '1'));
    fall(clkc);
    cec <= '1';
    rstc <= '1';
    rise(clkc);
    eqv("rstc", cd_h, slv(0, 48));
    fall(clkc);
    ci <= slv(3, 48);
    rise(clki);
    eqv("inv clk hold", cdi, slv(0, 48));
    fall(clki);
    eqv("inv clk", cdi, slv(3, 48));
    rsti <= '0';
    rise(clki);
    fall(clki);
    eqv("inv rst", cdi, slv(0, 48));

    u_m <= (others => '1');
    v_m <= slv(9, 45);
    eqv("mreg0", ud0, u_m);
    rise(clkm);
    eqv("mreg u", ud, u_m);
    eqv("mreg v", vd, v_m);
    fall(clkm);
    rstm <= '1';
    rise(clkm);
    eqv("rstm", ud, slv(0, 45));
    fall(clkm);

    eqv("areg2 a before", aalu, slv(0, 30));
    rise(clka);
    eqv("areg2 a1", a1d, slv(341, 27));
    eqv("areg2 a2", a2d, slv(0, 27));
    eqv("areg2 alu", aalu, slv(0, 30));
    eqv("areg2 acout", acout, slv(341, 30));
    eqv("breg2 b1", b1d, slv(17, 18));
    eqv("breg2 alu", balu, slv(0, 18));
    eqv("breg2 bcout", bcout, slv(17, 18));
    fall(clka);
    rise(clka);
    eqv("areg2 a2 next", a2d, slv(341, 27));
    eqv("areg2 alu next", aalu, slv(341, 30));
    eqv("breg2 alu next", balu, slv(17, 18));
    fall(clka);
    rsta <= '1';
    rise(clka);
    eqv("rsta", aalu, slv(0, 30));
    eqv("rsta b", balu, slv(17, 18));
    fall(clka);
    eqs("a z", aalu0(0), '1');
    eqv("a direct", aalu0(29 downto 1), slv(0, 29));
    eqv("b direct", balu0, b_bus);
    eqv("cascade", ac_alu, slv(99, 30));

    a1p <= slv(9, 27);
    a2p <= slv(5, 27);
    b1p <= slv(7, 18);
    b2p <= slv(1, 18);
    din_p <= slv(4, 27);
    ad_p <= slv(8, 27);
    cein <= '1';
    settle;
    eqv("pre a", a2a1, slv(5, 27));
    eqv("pre b", b2b1, slv(1, 18));
    eqv("pre ab", pre_ab, slv(5, 27));
    eqs("pre sub", addsub_p, '0');
    eqs("pre in2", inmode2_p, '0');
    eqv("d passthrough", ddata, slv(4, 27));
    eqv("ad passthrough", addata, slv(8, 27));
    inmode <= "11011";
    rise(clkp);
    eqv("inmode a1", a2a1, slv(0, 27));
    eqs("inmode sub", addsub_p, '1');
    eqs("inmode bit2", inmode2_p, '0');
    eqv("inmode b1", b2b1, slv(7, 18));
    fall(clkp);
    inmode <= "00010";
    b2p <= slv(16#20000#, 18);
    settle;
    eqv("bsel b", b2b1_b, slv(0, 18));
    eqv("bsel ab", pre_b, slv(0, 27));
    inmode <= "00000";
    settle;
    eqv("bsext", pre_b(26 downto 17), (9 downto 0 => '1'));
    eqv("bsext lo", pre_b(16 downto 0), (16 downto 0 => '0'));
    eqv("d none", d_off, din_p);
    eqs("inmode inv", a2a1_i(0), a1p(0));
    eqv("inmode inv rest", a2a1_i, a1p);
    din_z(0) <= 'Z';
    settle;
    eqs("din z", d_z(0), '0');

    ad_r <= slv(6, 27);
    din_r <= slv(11, 27);
    ce_r <= '1';
    eqv("ad reg gsr", ad_out, slv(0, 27));
    rise(clk_r);
    eqv("ad reg", ad_out, slv(6, 27));
    eqv("d reg", d_out, slv(11, 27));
    fall(clk_r);
    rstd_r <= '1';
    rise(clk_r);
    eqv("rstd ad", ad_out, slv(0, 27));
    eqv("rstd d", d_out, slv(0, 27));
    fall(clk_r);

    alu_o <= slv(0, 48);
    settle;
    eqs("pat match", pdet, '1');
    eqs("pat b", pdetb, '0');
    eqs("ovf", ovf, '0');
    eqs("unf", unf, '0');
    eqv("p passthrough", p_o, slv(0, 48));
    eqv("pfdbk reg", pfdbk, slv(0, 48));
    alu_o <= slv(1, 48);
    settle;
    eqs("pat miss", pdet, '0');
    eqs("pat b partial", pdetb, '0');
    eqs("ovf partial", ovf, '0');
    eqs("nopat det", pdet_p, '1');
    eqs("nopat b", pdetb_p, '1');
    eqs("nopat ovf", ovf_n, 'X');
    alu_o <= (47 downto 0 => '1');
    settle;
    eqs("pat b miss", pdetb, '1');
    eqs("pat still miss", pdet, '0');
    cout_o <= "1010";
    alum_o <= '1';
    xor_o <= slv(16#A5#, 8);
    settle;
    eqv("carryout", carryout, "1010");
    eqs("casc", ccasc, '0');
    eqs("ccout fb", ccout, '0');
    eqv("xorout", xorout, slv(16#A5#, 8));
    c_o <= (47 downto 0 => '1');
    settle;
    eqs("pattern c", pdet_c, '1');
    eqv("pcout", pc_c, alu_o);

    cep_m <= '1';
    alu_m <= slv(0, 48);
    rise(clk_m2);
    eqs("match load", pdet_m, '1');
    eqv("match p", p_m, slv(0, 48));
    fall(clk_m2);
    rise(clk_m2);
    eqs("auto reset det", pdet_m, '0');
    eqv("auto reset p", p_m, slv(0, 48));

    eqv("chain a", chain_a, slv(5, 27));
    eqv("chain sum", chain_sum, slv(5, 27));
    eqv("chain u", chain_u, ref_u);

    report "tb_eq_dsp PASS checks=" & integer'image(n);
    finish(0);
  end process;
end architecture sim;
