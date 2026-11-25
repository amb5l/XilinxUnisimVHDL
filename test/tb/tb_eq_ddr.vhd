-- Equivalence for IDDR, IDDR_2CLK, IDDRE1, ODDR, and ODDRE1 against
-- the Apache-2.0 Verilog analysed into library work. GLBL is elaborated
-- so the Verilog side has a glbl net; on this NVC that net stays 0 when
-- the module is instantiated from VHDL. GSR is therefore checked on the
-- VHDL model only. Comparisons start after GSR has fallen, and after a
-- reset has written the pipeline so the Verilog X left by a missing GSR
-- is gone.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_ddr is
end entity tb_eq_ddr;

architecture sim of tb_eq_ddr is
  signal c, ce, d, r, s : std_ulogic := '0';
  signal q1o_h, q1o_v, q2o_h, q2o_v : std_ulogic;
  signal q1s_h, q1s_v, q2s_h, q2s_v : std_ulogic;
  signal q1p_h, q1p_v, q2p_h, q2p_v : std_ulogic;
  signal q1i_h, q1i_v, q2i_h, q2i_v : std_ulogic;

  signal ca, cea, da, ra, sa : std_ulogic := '0';
  signal q1a_h, q1a_v, q2a_h, q2a_v : std_ulogic;

  signal ci, cei, di, ri, si : std_ulogic := '0';
  signal q1n_h, q1n_v, q2n_h, q2n_v : std_ulogic;

  signal c2, cb2, ce2, d2, r2, s2 : std_ulogic := '0';
  signal q1c_h, q1c_v, q2c_h, q2c_v : std_ulogic;
  signal q1cs_h, q1cs_v, q2cs_h, q2cs_v : std_ulogic;
  signal q1cp_h, q1cp_v, q2cp_h, q2cp_v : std_ulogic;

  signal c2a, cb2a, ce2a, d2a, r2a, s2a : std_ulogic := '0';
  signal q1ca_h, q1ca_v, q2ca_h, q2ca_v : std_ulogic;

  signal c2i, cb2i, ce2i, d2i, r2i, s2i : std_ulogic := '1';
  signal q1ci_h, q1ci_v, q2ci_h, q2ci_v : std_ulogic;

  signal ce1, cb1, de1, re1 : std_ulogic := '0';
  signal e1_h, e1_v, e1s_h, e1s_v, e1p_h, e1p_v : std_ulogic;
  signal e1q2_h, e1q2_v, e1sq2_h, e1sq2_v, e1pq2_h, e1pq2_v : std_ulogic;

  signal co, ceo, d1o, d2o, ro, so : std_ulogic := '0';
  signal qo_h, qo_v, qs_h, qs_v : std_ulogic;
  signal coa, ceoa, d1oa, d2oa, roa, soa : std_ulogic := '0';
  signal qa_h, qa_v : std_ulogic;
  signal coi, ceoi, d1oi, d2oi, roi, soi : std_ulogic := '0';
  signal qi_h, qi_v : std_ulogic;
  signal qinit_h, qinit_v : std_ulogic;

  signal cu, d1u, d2u, sru : std_ulogic := '0';
  signal qu_h, qu_v : std_ulogic;
  signal qu1_h, qu1_v : std_ulogic;
  signal cv, d1v, d2v, srv : std_ulogic := '0';
  signal qv_h, qv_v : std_ulogic;
  signal cn, d1n, d2n, srn : std_ulogic := '1';
  signal qn_h, qn_v : std_ulogic;

  component IDDR is
    generic (
      DDR_CLK_EDGE : string := "OPPOSITE_EDGE";
      INIT_Q1 : bit := '0';
      INIT_Q2 : bit := '0';
      IS_C_INVERTED : bit := '0';
      IS_D_INVERTED : bit := '0';
      SRTYPE : string := "SYNC"
    );
    port (
      Q1, Q2 : out std_ulogic;
      C, CE, D, R, S : in std_ulogic
    );
  end component;

  component IDDR_2CLK is
    generic (
      DDR_CLK_EDGE : string := "OPPOSITE_EDGE";
      INIT_Q1 : bit := '0';
      INIT_Q2 : bit := '0';
      IS_CB_INVERTED : bit := '0';
      IS_C_INVERTED : bit := '0';
      IS_D_INVERTED : bit := '0';
      SRTYPE : string := "SYNC"
    );
    port (
      Q1, Q2 : out std_ulogic;
      C, CB, CE, D, R, S : in std_ulogic
    );
  end component;

  component IDDRE1 is
    generic (
      DDR_CLK_EDGE : string := "OPPOSITE_EDGE";
      IS_CB_INVERTED : bit := '0';
      IS_C_INVERTED : bit := '0'
    );
    port (
      Q1, Q2 : out std_ulogic;
      C, CB, D, R : in std_ulogic
    );
  end component;

  component ODDR is
    generic (
      DDR_CLK_EDGE : string := "OPPOSITE_EDGE";
      INIT : bit := '0';
      IS_C_INVERTED : bit := '0';
      IS_D1_INVERTED : bit := '0';
      IS_D2_INVERTED : bit := '0';
      SRTYPE : string := "SYNC"
    );
    port (
      Q : out std_ulogic;
      C, CE, D1, D2, R, S : in std_ulogic
    );
  end component;

  component ODDRE1 is
    generic (
      IS_C_INVERTED : bit := '0';
      IS_D1_INVERTED : bit := '0';
      IS_D2_INVERTED : bit := '0';
      SIM_DEVICE : string := "ULTRASCALE";
      SRVAL : bit := '0'
    );
    port (
      Q : out std_ulogic;
      C, D1, D2, SR : in std_ulogic
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
  u_o_h : entity unisim.IDDR port map (Q1 => q1o_h, Q2 => q2o_h, C => c, CE => ce, D => d, R => r, S => s);
  u_o_v : IDDR port map (Q1 => q1o_v, Q2 => q2o_v, C => c, CE => ce, D => d, R => r, S => s);
  u_s_h : entity unisim.IDDR generic map (DDR_CLK_EDGE => "SAME_EDGE")
    port map (Q1 => q1s_h, Q2 => q2s_h, C => c, CE => ce, D => d, R => r, S => s);
  u_s_v : IDDR generic map (DDR_CLK_EDGE => "SAME_EDGE")
    port map (Q1 => q1s_v, Q2 => q2s_v, C => c, CE => ce, D => d, R => r, S => s);
  u_p_h : entity unisim.IDDR generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
    port map (Q1 => q1p_h, Q2 => q2p_h, C => c, CE => ce, D => d, R => r, S => s);
  u_p_v : IDDR generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
    port map (Q1 => q1p_v, Q2 => q2p_v, C => c, CE => ce, D => d, R => r, S => s);
  u_i_h : entity unisim.IDDR generic map (INIT_Q1 => '1', INIT_Q2 => '1')
    port map (Q1 => q1i_h, Q2 => q2i_h, C => c, CE => ce, D => d, R => r, S => s);
  u_i_v : IDDR generic map (INIT_Q1 => '1', INIT_Q2 => '1')
    port map (Q1 => q1i_v, Q2 => q2i_v, C => c, CE => ce, D => d, R => r, S => s);

  u_a_h : entity unisim.IDDR generic map (SRTYPE => "ASYNC")
    port map (Q1 => q1a_h, Q2 => q2a_h, C => ca, CE => cea, D => da, R => ra, S => sa);
  u_a_v : IDDR generic map (SRTYPE => "ASYNC")
    port map (Q1 => q1a_v, Q2 => q2a_v, C => ca, CE => cea, D => da, R => ra, S => sa);

  u_n_h : entity unisim.IDDR generic map (IS_C_INVERTED => '1', IS_D_INVERTED => '1')
    port map (Q1 => q1n_h, Q2 => q2n_h, C => ci, CE => cei, D => di, R => ri, S => si);
  u_n_v : IDDR generic map (IS_C_INVERTED => '1', IS_D_INVERTED => '1')
    port map (Q1 => q1n_v, Q2 => q2n_v, C => ci, CE => cei, D => di, R => ri, S => si);

  u_c_h : entity unisim.IDDR_2CLK port map (
    Q1 => q1c_h, Q2 => q2c_h, C => c2, CB => cb2, CE => ce2, D => d2, R => r2, S => s2);
  u_c_v : IDDR_2CLK port map (
    Q1 => q1c_v, Q2 => q2c_v, C => c2, CB => cb2, CE => ce2, D => d2, R => r2, S => s2);
  u_cs_h : entity unisim.IDDR_2CLK generic map (DDR_CLK_EDGE => "SAME_EDGE")
    port map (Q1 => q1cs_h, Q2 => q2cs_h, C => c2, CB => cb2, CE => ce2, D => d2, R => r2, S => s2);
  u_cs_v : IDDR_2CLK generic map (DDR_CLK_EDGE => "SAME_EDGE")
    port map (Q1 => q1cs_v, Q2 => q2cs_v, C => c2, CB => cb2, CE => ce2, D => d2, R => r2, S => s2);
  u_cp_h : entity unisim.IDDR_2CLK generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
    port map (Q1 => q1cp_h, Q2 => q2cp_h, C => c2, CB => cb2, CE => ce2, D => d2, R => r2, S => s2);
  u_cp_v : IDDR_2CLK generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
    port map (Q1 => q1cp_v, Q2 => q2cp_v, C => c2, CB => cb2, CE => ce2, D => d2, R => r2, S => s2);

  u_ca_h : entity unisim.IDDR_2CLK generic map (SRTYPE => "ASYNC")
    port map (Q1 => q1ca_h, Q2 => q2ca_h, C => c2a, CB => cb2a, CE => ce2a, D => d2a, R => r2a, S => s2a);
  u_ca_v : IDDR_2CLK generic map (SRTYPE => "ASYNC")
    port map (Q1 => q1ca_v, Q2 => q2ca_v, C => c2a, CB => cb2a, CE => ce2a, D => d2a, R => r2a, S => s2a);

  u_ci_h : entity unisim.IDDR_2CLK generic map (IS_C_INVERTED => '1', IS_CB_INVERTED => '1', IS_D_INVERTED => '1')
    port map (Q1 => q1ci_h, Q2 => q2ci_h, C => c2i, CB => cb2i, CE => ce2i, D => d2i, R => r2i, S => s2i);
  u_ci_v : IDDR_2CLK generic map (IS_C_INVERTED => '1', IS_CB_INVERTED => '1', IS_D_INVERTED => '1')
    port map (Q1 => q1ci_v, Q2 => q2ci_v, C => c2i, CB => cb2i, CE => ce2i, D => d2i, R => r2i, S => s2i);

  u_e_h : entity unisim.IDDRE1 port map (Q1 => e1_h, Q2 => e1q2_h, C => ce1, CB => cb1, D => de1, R => re1);
  u_e_v : IDDRE1 port map (Q1 => e1_v, Q2 => e1q2_v, C => ce1, CB => cb1, D => de1, R => re1);
  u_es_h : entity unisim.IDDRE1 generic map (DDR_CLK_EDGE => "SAME_EDGE")
    port map (Q1 => e1s_h, Q2 => e1sq2_h, C => ce1, CB => cb1, D => de1, R => re1);
  u_es_v : IDDRE1 generic map (DDR_CLK_EDGE => "SAME_EDGE")
    port map (Q1 => e1s_v, Q2 => e1sq2_v, C => ce1, CB => cb1, D => de1, R => re1);
  u_ep_h : entity unisim.IDDRE1 generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
    port map (Q1 => e1p_h, Q2 => e1pq2_h, C => ce1, CB => cb1, D => de1, R => re1);
  u_ep_v : IDDRE1 generic map (DDR_CLK_EDGE => "SAME_EDGE_PIPELINED")
    port map (Q1 => e1p_v, Q2 => e1pq2_v, C => ce1, CB => cb1, D => de1, R => re1);

  u_od_h : entity unisim.ODDR port map (Q => qo_h, C => co, CE => ceo, D1 => d1o, D2 => d2o, R => ro, S => so);
  u_od_v : ODDR port map (Q => qo_v, C => co, CE => ceo, D1 => d1o, D2 => d2o, R => ro, S => so);
  u_ods_h : entity unisim.ODDR generic map (DDR_CLK_EDGE => "SAME_EDGE")
    port map (Q => qs_h, C => co, CE => ceo, D1 => d1o, D2 => d2o, R => ro, S => so);
  u_ods_v : ODDR generic map (DDR_CLK_EDGE => "SAME_EDGE")
    port map (Q => qs_v, C => co, CE => ceo, D1 => d1o, D2 => d2o, R => ro, S => so);
  u_oda_h : entity unisim.ODDR generic map (SRTYPE => "ASYNC")
    port map (Q => qa_h, C => coa, CE => ceoa, D1 => d1oa, D2 => d2oa, R => roa, S => soa);
  u_oda_v : ODDR generic map (SRTYPE => "ASYNC")
    port map (Q => qa_v, C => coa, CE => ceoa, D1 => d1oa, D2 => d2oa, R => roa, S => soa);
  u_odi_h : entity unisim.ODDR generic map (IS_C_INVERTED => '1', IS_D1_INVERTED => '1', IS_D2_INVERTED => '1')
    port map (Q => qi_h, C => coi, CE => ceoi, D1 => d1oi, D2 => d2oi, R => roi, S => soi);
  u_odi_v : ODDR generic map (IS_C_INVERTED => '1', IS_D1_INVERTED => '1', IS_D2_INVERTED => '1')
    port map (Q => qi_v, C => coi, CE => ceoi, D1 => d1oi, D2 => d2oi, R => roi, S => soi);
  u_odn_h : entity unisim.ODDR generic map (INIT => '1')
    port map (Q => qinit_h, C => co, CE => ceo, D1 => d1o, D2 => d2o, R => ro, S => so);
  u_odn_v : ODDR generic map (INIT => '1')
    port map (Q => qinit_v, C => co, CE => ceo, D1 => d1o, D2 => d2o, R => ro, S => so);

  u_ou_h : entity unisim.ODDRE1 port map (Q => qu_h, C => cu, D1 => d1u, D2 => d2u, SR => sru);
  u_ou_v : ODDRE1 port map (Q => qu_v, C => cu, D1 => d1u, D2 => d2u, SR => sru);
  u_ou1_h : entity unisim.ODDRE1 generic map (SRVAL => '1')
    port map (Q => qu1_h, C => cu, D1 => d1u, D2 => d2u, SR => sru);
  u_ou1_v : ODDRE1 generic map (SRVAL => '1')
    port map (Q => qu1_v, C => cu, D1 => d1u, D2 => d2u, SR => sru);
  u_ov_h : entity unisim.ODDRE1 generic map (SIM_DEVICE => "VERSAL_PRIME")
    port map (Q => qv_h, C => cv, D1 => d1v, D2 => d2v, SR => srv);
  u_ov_v : ODDRE1 generic map (SIM_DEVICE => "VERSAL_PRIME")
    port map (Q => qv_v, C => cv, D1 => d1v, D2 => d2v, SR => srv);
  u_on_h : entity unisim.ODDRE1 generic map (IS_C_INVERTED => '1', IS_D1_INVERTED => '1', IS_D2_INVERTED => '1', SIM_DEVICE => "ULTRASCALE_PLUS")
    port map (Q => qn_h, C => cn, D1 => d1n, D2 => d2n, SR => srn);
  u_on_v : ODDRE1 generic map (IS_C_INVERTED => '1', IS_D1_INVERTED => '1', IS_D2_INVERTED => '1', SIM_DEVICE => "ULTRASCALE_PLUS")
    port map (Q => qn_v, C => cn, D1 => d1n, D2 => d2n, SR => srn);

  stim : process
    variable n : natural := 0;
    -- NVC applies a Verilog NBA, then the continuous assign to the
    -- port, on successive resumes of this process. rise and fall wait
    -- twice so a following comparison sees the port.
    constant step : time := 5 ns;

    procedure eq(name : string; got, exp : std_ulogic) is
    begin
      n := n + 1;
      assert got = from_vlog(exp)
        report name & " VHDL=" & std_ulogic'image(got)
          & " Verilog=" & std_ulogic'image(from_vlog(exp))
        severity failure;
    end procedure;

    procedure expect(name : string; got, exp : std_ulogic) is
    begin
      n := n + 1;
      assert got = exp
        report name & " got " & std_ulogic'image(got)
          & " expected " & std_ulogic'image(exp)
        severity failure;
    end procedure;

    procedure eq_iddr(tag : string) is
    begin
      eq(tag & " opp q1", q1o_h, q1o_v);
      eq(tag & " opp q2", q2o_h, q2o_v);
      eq(tag & " same q1", q1s_h, q1s_v);
      eq(tag & " same q2", q2s_h, q2s_v);
      eq(tag & " pipe q1", q1p_h, q1p_v);
      eq(tag & " pipe q2", q2p_h, q2p_v);
      eq(tag & " init q1", q1i_h, q1i_v);
      eq(tag & " init q2", q2i_h, q2i_v);
    end procedure;

    procedure eq_iddr2(tag : string) is
    begin
      eq(tag & " 2c q1", q1c_h, q1c_v);
      eq(tag & " 2c q2", q2c_h, q2c_v);
      eq(tag & " 2c same q1", q1cs_h, q1cs_v);
      eq(tag & " 2c same q2", q2cs_h, q2cs_v);
      eq(tag & " 2c pipe q1", q1cp_h, q1cp_v);
      eq(tag & " 2c pipe q2", q2cp_h, q2cp_v);
    end procedure;

    procedure eq_iddre1(tag : string) is
    begin
      eq(tag & " e1 q1", e1_h, e1_v);
      eq(tag & " e1 q2", e1q2_h, e1q2_v);
      eq(tag & " e1 same q1", e1s_h, e1s_v);
      eq(tag & " e1 same q2", e1sq2_h, e1sq2_v);
      eq(tag & " e1 pipe q1", e1p_h, e1p_v);
      eq(tag & " e1 pipe q2", e1pq2_h, e1pq2_v);
    end procedure;

    procedure rise(signal ck : inout std_ulogic) is
    begin
      ck <= '1';
      wait for step;
      wait for step;
    end procedure;

    procedure fall(signal ck : inout std_ulogic) is
    begin
      ck <= '0';
      wait for step;
      wait for step;
    end procedure;

  begin
    wait for 50 ns;
    expect("gsr iddr q1", q1o_h, '0');
    expect("gsr iddr q2", q2o_h, '0');
    expect("gsr iddr init q1", q1i_h, '1');
    expect("gsr iddr init q2", q2i_h, '1');
    expect("gsr iddre1 q1", e1_h, '0');
    expect("gsr oddr", qo_h, '0');
    expect("gsr oddr init", qinit_h, '1');
    expect("gsr oddre1", qu_h, '0');
    expect("gsr oddre1 srval", qu1_h, '1');

    wait for 70 ns;
    ce <= '1';
    r <= '1';
    wait for step;
    rise(c);
    fall(c);
    r <= '0';
    wait for step;
    eq_iddr("sync rst");

    d <= '1';
    wait for step;
    rise(c);
    eq_iddr("d1 rise");
    fall(c);
    eq_iddr("d1 fall");
    d <= '0';
    wait for step;
    rise(c);
    eq_iddr("d0 rise");
    fall(c);
    eq_iddr("d0 fall");
    d <= '1';
    wait for step;
    rise(c);
    fall(c);
    eq_iddr("d1 again");

    ce <= '0';
    d <= '0';
    wait for step;
    rise(c);
    fall(c);
    eq_iddr("ce 0");
    ce <= '1';
    wait for step;

    s <= '1';
    wait for step;
    rise(c);
    fall(c);
    eq_iddr("sync set");
    s <= '0';
    wait for step;
    d <= '0';
    wait for step;
    rise(c);
    fall(c);
    eq_iddr("after set");

    d <= 'X';
    wait for step;
    rise(c);
    fall(c);
    eq_iddr("d x");
    d <= 'Z';
    wait for step;
    rise(c);
    fall(c);
    eq_iddr("d z");
    d <= '1';
    r <= 'Z';
    wait for step;
    rise(c);
    fall(c);
    eq_iddr("r z");
    r <= '0';
    ce <= 'Z';
    d <= '0';
    wait for step;
    rise(c);
    fall(c);
    eq_iddr("ce z");
    ce <= '1';

    cea <= '1';
    ra <= '1';
    wait for step;
    wait for step;
    eq("async r q1", q1a_h, q1a_v);
    eq("async r q2", q2a_h, q2a_v);
    expect("async r forces 0", q1a_h, '0');
    ra <= '0';
    sa <= '1';
    wait for step;
    wait for step;
    eq("async s q1", q1a_h, q1a_v);
    eq("async s q2", q2a_h, q2a_v);
    expect("async s forces 1", q1a_h, '1');
    sa <= '0';
    da <= '1';
    wait for step;
    rise(ca);
    fall(ca);
    eq("async data q1", q1a_h, q1a_v);
    eq("async data q2", q2a_h, q2a_v);
    da <= '0';
    wait for step;
    rise(ca);
    fall(ca);
    eq("async d0 q1", q1a_h, q1a_v);
    eq("async d0 q2", q2a_h, q2a_v);

    cei <= '1';
    ri <= '1';
    ci <= '1';
    wait for step;
    fall(ci);
    rise(ci);
    ri <= '0';
    di <= '0';
    wait for step;
    fall(ci);
    eq("inv rise q1", q1n_h, q1n_v);
    eq("inv rise q2", q2n_h, q2n_v);
    rise(ci);
    eq("inv fall q1", q1n_h, q1n_v);
    eq("inv fall q2", q2n_h, q2n_v);
    di <= '1';
    wait for step;
    fall(ci);
    rise(ci);
    eq("inv d1 q1", q1n_h, q1n_v);
    eq("inv d1 q2", q2n_h, q2n_v);

    ce2 <= '1';
    r2 <= '1';
    wait for step;
    rise(c2);
    rise(cb2);
    fall(c2);
    fall(cb2);
    r2 <= '0';
    wait for step;
    eq_iddr2("rst");
    d2 <= '1';
    wait for step;
    rise(c2);
    eq_iddr2("c rise");
    rise(cb2);
    eq_iddr2("cb rise");
    d2 <= '0';
    wait for step;
    fall(c2);
    fall(cb2);
    rise(c2);
    eq_iddr2("c2");
    rise(cb2);
    eq_iddr2("cb2");
    d2 <= '1';
    wait for step;
    fall(c2);
    fall(cb2);
    rise(c2);
    rise(cb2);
    eq_iddr2("c3");
    ce2 <= '0';
    d2 <= '0';
    wait for step;
    fall(c2);
    fall(cb2);
    rise(c2);
    rise(cb2);
    eq_iddr2("ce0");
    ce2 <= '1';
    s2 <= '1';
    wait for step;
    fall(c2);
    fall(cb2);
    rise(c2);
    rise(cb2);
    eq_iddr2("set");
    s2 <= '0';
    r2 <= 'Z';
    d2 <= '0';
    wait for step;
    fall(c2);
    fall(cb2);
    rise(c2);
    rise(cb2);
    eq_iddr2("r z");
    r2 <= '0';

    ce2a <= '1';
    r2a <= '1';
    wait for step;
    wait for step;
    eq("2c async r q1", q1ca_h, q1ca_v);
    eq("2c async r q2", q2ca_h, q2ca_v);
    r2a <= '0';
    s2a <= '1';
    wait for step;
    wait for step;
    eq("2c async s q1", q1ca_h, q1ca_v);
    eq("2c async s q2", q2ca_h, q2ca_v);
    s2a <= '0';
    d2a <= '1';
    wait for step;
    rise(c2a);
    rise(cb2a);
    eq("2c async d q1", q1ca_h, q1ca_v);
    eq("2c async d q2", q2ca_h, q2ca_v);

    ce2i <= '1';
    r2i <= '1';
    wait for step;
    fall(c2i);
    fall(cb2i);
    rise(c2i);
    rise(cb2i);
    r2i <= '0';
    d2i <= '0';
    wait for step;
    fall(c2i);
    eq("2c inv c q1", q1ci_h, q1ci_v);
    eq("2c inv c q2", q2ci_h, q2ci_v);
    fall(cb2i);
    eq("2c inv cb q1", q1ci_h, q1ci_v);
    eq("2c inv cb q2", q2ci_h, q2ci_v);

    re1 <= '1';
    wait for step;
    eq_iddre1("r");
    expect("iddre1 r q1", e1_h, '0');
    re1 <= '0';
    de1 <= '1';
    wait for step;
    rise(ce1);
    eq_iddre1("c");
    rise(cb1);
    eq_iddre1("cb");
    de1 <= '0';
    wait for step;
    fall(ce1);
    fall(cb1);
    rise(ce1);
    rise(cb1);
    eq_iddre1("d0");
    de1 <= 'Z';
    wait for step;
    fall(ce1);
    fall(cb1);
    rise(ce1);
    rise(cb1);
    eq_iddre1("d z");
    de1 <= '1';
    re1 <= 'X';
    wait for step;
    fall(ce1);
    fall(cb1);
    rise(ce1);
    rise(cb1);
    eq_iddre1("r x");

    ceo <= '1';
    ro <= '1';
    wait for step;
    rise(co);
    fall(co);
    ro <= '0';
    wait for step;
    wait for step;
    eq("oddr rst opp", qo_h, qo_v);
    eq("oddr rst same", qs_h, qs_v);
    eq("oddr rst init", qinit_h, qinit_v);
    d1o <= '1';
    d2o <= '0';
    wait for step;
    rise(co);
    eq("oddr d1 opp", qo_h, qo_v);
    eq("oddr d1 same", qs_h, qs_v);
    fall(co);
    eq("oddr d2 opp", qo_h, qo_v);
    eq("oddr d2 same", qs_h, qs_v);
    d1o <= '0';
    d2o <= '1';
    wait for step;
    rise(co);
    fall(co);
    eq("oddr swap opp", qo_h, qo_v);
    eq("oddr swap same", qs_h, qs_v);
    ceo <= '0';
    d1o <= '1';
    d2o <= '0';
    wait for step;
    rise(co);
    fall(co);
    eq("oddr ce0 opp", qo_h, qo_v);
    eq("oddr ce0 same", qs_h, qs_v);
    ceo <= '1';
    so <= '1';
    wait for step;
    rise(co);
    fall(co);
    eq("oddr set opp", qo_h, qo_v);
    eq("oddr set same", qs_h, qs_v);
    so <= '0';
    ro <= 'Z';
    d1o <= '0';
    d2o <= '1';
    wait for step;
    rise(co);
    fall(co);
    eq("oddr rz opp", qo_h, qo_v);
    eq("oddr rz same", qs_h, qs_v);
    ro <= '0';

    ceoa <= '1';
    roa <= '1';
    wait for step;
    wait for step;
    eq("oddr async r", qa_h, qa_v);
    expect("oddr async r 0", qa_h, '0');
    roa <= '0';
    soa <= '1';
    wait for step;
    wait for step;
    eq("oddr async s", qa_h, qa_v);
    expect("oddr async s 1", qa_h, '1');
    soa <= '0';
    d1oa <= '1';
    d2oa <= '0';
    wait for step;
    rise(coa);
    fall(coa);
    eq("oddr async data", qa_h, qa_v);

    ceoi <= '1';
    roi <= '1';
    coi <= '1';
    wait for step;
    fall(coi);
    rise(coi);
    roi <= '0';
    d1oi <= '0';
    d2oi <= '1';
    wait for step;
    fall(coi);
    eq("oddr inv rise", qi_h, qi_v);
    rise(coi);
    eq("oddr inv fall", qi_h, qi_v);

    sru <= '1';
    wait for step;
    wait for step;
    eq("oddre1 sr", qu_h, qu_v);
    eq("oddre1 srval1", qu1_h, qu1_v);
    expect("oddre1 sr 0", qu_h, '0');
    expect("oddre1 sr 1", qu1_h, '1');
    sru <= '0';
    d1u <= '1';
    d2u <= '0';
    wait for step;
    rise(cu);
    eq("oddre1 load", qu_h, qu_v);
    fall(cu);
    eq("oddre1 fall", qu_h, qu_v);
    sru <= '1';
    wait for step;
    rise(cu);
    sru <= '0';
    d1u <= '0';
    d2u <= '1';
    wait for step;
    fall(cu);
    rise(cu);
    fall(cu);
    rise(cu);
    fall(cu);
    rise(cu);
    fall(cu);
    eq("oddre1 hold", qu_h, qu_v);
    rise(cu);
    fall(cu);
    eq("oddre1 release", qu_h, qu_v);

    srv <= '1';
    wait for step;
    wait for step;
    eq("oddre1 versal sr", qv_h, qv_v);
    rise(cv);
    srv <= '0';
    d1v <= '1';
    d2v <= '0';
    wait for step;
    fall(cv);
    rise(cv);
    eq("oddre1 versal release", qv_h, qv_v);
    fall(cv);
    eq("oddre1 versal fall", qv_h, qv_v);

    srn <= '1';
    cn <= '1';
    wait for step;
    fall(cn);
    srn <= '0';
    d1n <= '0';
    d2n <= '1';
    wait for step;
    rise(cn);
    fall(cn);
    rise(cn);
    fall(cn);
    rise(cn);
    fall(cn);
    rise(cn);
    eq("oddre1 inv release", qn_h, qn_v);

    report "tb_eq_ddr PASS checks=" & integer'image(n);
    finish(0);
  end process;
end architecture sim;
