-- Equivalence for LDCE, LDPE, and CFGLUT5 against the Apache-2.0
-- Verilog analysed into library work. GLBL is elaborated so the
-- Verilog side has a glbl net; on this NVC that net stays 0 when the
-- module is instantiated from VHDL. GSR is therefore checked on the
-- VHDL model only. Comparisons start after GSR has fallen.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_ff is
end entity tb_eq_ff;

architecture sim of tb_eq_ff is
  constant vals : std_logic_vector(0 to 3) := "01XZ";
  constant mem_a : bit_vector(31 downto 0) := X"96696996";
  constant mem_b : bit_vector(31 downto 0) := X"80000000";
  constant mem_c : bit_vector(31 downto 0) := X"80000001";

  signal d, g, ge, clr : std_ulogic := '0';
  signal lc_h, lc_v : std_ulogic;
  signal lc1_h, lc1_v : std_ulogic;
  signal lcg_h, lcg_v : std_ulogic;
  signal lcc_h, lcc_v : std_ulogic;
  signal lp_h, lp_v : std_ulogic;
  signal lp0_h, lp0_v : std_ulogic;
  signal lpg_h, lpg_v : std_ulogic;
  signal lpp_h, lpp_v : std_ulogic;

  signal clk : std_ulogic := '0';
  signal lclk : std_ulogic := '1';
  signal nclk : std_ulogic := '1';
  signal cdi, ce : std_ulogic := '0';
  signal i0, i1, i2, i3, i4 : std_ulogic := '0';
  signal cdo_h, cdo_v, o5_h, o5_v, o6_h, o6_v : std_ulogic;
  signal lcdo_h, lcdo_v, lo6_h, lo6_v : std_ulogic;
  signal ncdo_h, ncdo_v, no6_h, no6_v : std_ulogic;

  component LDCE is
    generic (
      INIT : bit := '0';
      IS_CLR_INVERTED : bit := '0';
      IS_G_INVERTED : bit := '0'
    );
    port (Q : out std_ulogic; CLR, D, G, GE : in std_ulogic);
  end component;
  component LDPE is
    generic (
      INIT : bit := '1';
      IS_G_INVERTED : bit := '0';
      IS_PRE_INVERTED : bit := '0'
    );
    port (Q : out std_ulogic; D, G, GE, PRE : in std_ulogic);
  end component;
  component CFGLUT5 is
    generic (
      INIT : bit_vector(31 downto 0) := X"00000000";
      IS_CLK_INVERTED : bit := '0'
    );
    port (
      CDO, O5, O6 : out std_ulogic;
      CDI, CE, CLK, I0, I1, I2, I3, I4 : in std_ulogic
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
  u_lc_h : entity unisim.LDCE port map (Q => lc_h, CLR => clr, D => d, G => g, GE => ge);
  u_lc_v : LDCE port map (Q => lc_v, CLR => clr, D => d, G => g, GE => ge);
  u_lc1_h : entity unisim.LDCE generic map (INIT => '1')
    port map (Q => lc1_h, CLR => clr, D => d, G => g, GE => ge);
  u_lc1_v : LDCE generic map (INIT => '1')
    port map (Q => lc1_v, CLR => clr, D => d, G => g, GE => ge);
  u_lcg_h : entity unisim.LDCE generic map (IS_G_INVERTED => '1')
    port map (Q => lcg_h, CLR => clr, D => d, G => g, GE => ge);
  u_lcg_v : LDCE generic map (IS_G_INVERTED => '1')
    port map (Q => lcg_v, CLR => clr, D => d, G => g, GE => ge);
  u_lcc_h : entity unisim.LDCE generic map (IS_CLR_INVERTED => '1')
    port map (Q => lcc_h, CLR => clr, D => d, G => g, GE => ge);
  u_lcc_v : LDCE generic map (IS_CLR_INVERTED => '1')
    port map (Q => lcc_v, CLR => clr, D => d, G => g, GE => ge);

  u_lp_h : entity unisim.LDPE port map (Q => lp_h, D => d, G => g, GE => ge, PRE => clr);
  u_lp_v : LDPE port map (Q => lp_v, D => d, G => g, GE => ge, PRE => clr);
  u_lp0_h : entity unisim.LDPE generic map (INIT => '0')
    port map (Q => lp0_h, D => d, G => g, GE => ge, PRE => clr);
  u_lp0_v : LDPE generic map (INIT => '0')
    port map (Q => lp0_v, D => d, G => g, GE => ge, PRE => clr);
  u_lpg_h : entity unisim.LDPE generic map (IS_G_INVERTED => '1')
    port map (Q => lpg_h, D => d, G => g, GE => ge, PRE => clr);
  u_lpg_v : LDPE generic map (IS_G_INVERTED => '1')
    port map (Q => lpg_v, D => d, G => g, GE => ge, PRE => clr);
  u_lpp_h : entity unisim.LDPE generic map (IS_PRE_INVERTED => '1')
    port map (Q => lpp_h, D => d, G => g, GE => ge, PRE => clr);
  u_lpp_v : LDPE generic map (IS_PRE_INVERTED => '1')
    port map (Q => lpp_v, D => d, G => g, GE => ge, PRE => clr);

  u_cfg_h : entity unisim.CFGLUT5 generic map (INIT => mem_a)
    port map (CDO => cdo_h, O5 => o5_h, O6 => o6_h, CDI => cdi, CE => ce, CLK => clk,
              I0 => i0, I1 => i1, I2 => i2, I3 => i3, I4 => i4);
  u_cfg_v : CFGLUT5 generic map (INIT => mem_a)
    port map (CDO => cdo_v, O5 => o5_v, O6 => o6_v, CDI => cdi, CE => ce, CLK => clk,
              I0 => i0, I1 => i1, I2 => i2, I3 => i3, I4 => i4);
  u_lock_h : entity unisim.CFGLUT5 generic map (INIT => mem_b)
    port map (CDO => lcdo_h, O5 => open, O6 => lo6_h, CDI => cdi, CE => ce, CLK => lclk,
              I0 => i0, I1 => i1, I2 => i2, I3 => i3, I4 => i4);
  u_lock_v : CFGLUT5 generic map (INIT => mem_b)
    port map (CDO => lcdo_v, O5 => open, O6 => lo6_v, CDI => cdi, CE => ce, CLK => lclk,
              I0 => i0, I1 => i1, I2 => i2, I3 => i3, I4 => i4);
  u_neg_h : entity unisim.CFGLUT5 generic map (INIT => mem_c, IS_CLK_INVERTED => '1')
    port map (CDO => ncdo_h, O5 => open, O6 => no6_h, CDI => cdi, CE => ce, CLK => nclk,
              I0 => i0, I1 => i1, I2 => i2, I3 => i3, I4 => i4);
  u_neg_v : CFGLUT5 generic map (INIT => mem_c, IS_CLK_INVERTED => '1')
    port map (CDO => ncdo_v, O5 => open, O6 => no6_v, CDI => cdi, CE => ce, CLK => nclk,
              I0 => i0, I1 => i1, I2 => i2, I3 => i3, I4 => i4);

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

    procedure check_latches is
    begin
      eq("LDCE", lc_h, lc_v);
      eq("LDCE INIT1", lc1_h, lc1_v);
      eq("LDCE Ginv", lcg_h, lcg_v);
      eq("LDCE CLRinv", lcc_h, lcc_v);
      eq("LDPE", lp_h, lp_v);
      eq("LDPE INIT0", lp0_h, lp0_v);
      eq("LDPE Ginv", lpg_h, lpg_v);
      eq("LDPE PREinv", lpp_h, lpp_v);
    end procedure;

    procedure rise(signal c : out std_ulogic) is
    begin
      c <= '0';
      wait for 1 ns;
      c <= '1';
      wait for 1 ns;
    end procedure;

    procedure fall(signal c : out std_ulogic) is
    begin
      c <= '1';
      wait for 1 ns;
      c <= '0';
      wait for 1 ns;
    end procedure;
  begin
    -- A 100 ps low pulse is shorter than the 1 ns INIT poll, so a shift
    -- while CLK is held high is discarded. This has to run before the
    -- 101 ns timeout releases the force.
    ce <= '1';
    cdi <= '0';
    -- Between the 1 ns polls, so the sample does not see the low pulse.
    wait for 1500 ps;
    assert lcdo_h = '1' and from_vlog(lcdo_v) = '1'
      report "CFGLUT5 lock lost INIT" severity failure;
    lclk <= '0';
    wait for 100 ps;
    lclk <= '1';
    wait for 1 ns;
    eq("CFGLUT5 locked CDO", lcdo_h, lcdo_v);
    assert lcdo_h = '1' report "CFGLUT5 shifted while INIT was forced" severity failure;

    -- GSR is still 1. An open gate must not capture on the VHDL model.
    d <= '1';
    g <= '1';
    ge <= '1';
    clr <= '0';
    wait for 20 ns;
    assert lc_h = '0' and lp0_h = '0'
      report "GSR did not hold INIT 0" severity failure;
    assert lc1_h = '1' and lp_h = '1'
      report "GSR did not hold INIT 1" severity failure;
    g <= '0';
    wait for 1 ns;

    wait for 150 ns;
    -- Resync both polarities of the gate onto D=0, then compare.
    d <= '0';
    ge <= '1';
    clr <= '0';
    g <= '0';
    wait for 1 ns;
    g <= '1';
    wait for 1 ns;
    check_latches;

    for di in 0 to 3 loop
      for gi in 0 to 3 loop
        for ei in 0 to 3 loop
          for ri in 0 to 3 loop
            d <= vals(di);
            g <= vals(gi);
            ge <= vals(ei);
            clr <= vals(ri);
            wait for 1 ns;
            check_latches;
          end loop;
        end loop;
      end loop;
    end loop;

    -- CFGLUT5 address walk. CLK starts at 0, so the 1 ns poll releases
    -- the INIT force before this wait ends. CE stays 0.
    ce <= '0';
    cdi <= '1';
    wait for 2 ns;
    assert o6_h = '0' and from_vlog(o6_v) = '0'
      report "CFGLUT5 address 0 is not INIT bit 0" severity failure;
    for a in 0 to 31 loop
      i0 <= '1' when (a / 1) mod 2 = 1 else '0';
      i1 <= '1' when (a / 2) mod 2 = 1 else '0';
      i2 <= '1' when (a / 4) mod 2 = 1 else '0';
      i3 <= '1' when (a / 8) mod 2 = 1 else '0';
      i4 <= '1' when (a / 16) mod 2 = 1 else '0';
      wait for 1 ns;
      eq("CFGLUT5 CDO", cdo_h, cdo_v);
      eq("CFGLUT5 O5", o5_h, o5_v);
      eq("CFGLUT5 O6", o6_h, o6_v);
    end loop;
    i0 <= 'X'; i1 <= '0'; i2 <= '1'; i3 <= '0'; i4 <= '1';
    wait for 1 ns;
    eq("CFGLUT5 O6 X", o6_h, o6_v);
    eq("CFGLUT5 O5 X", o5_h, o5_v);
    i0 <= '0'; i4 <= 'Z';
    wait for 1 ns;
    eq("CFGLUT5 O6 Z", o6_h, o6_v);
    eq("CFGLUT5 O5 Z", o5_h, o5_v);
    i4 <= '0';
    i0 <= '0';

    -- CE other than 1 does not shift. CE 1 does.
    ce <= '0';
    cdi <= '1';
    rise(clk);
    eq("CFGLUT5 CE0 CDO", cdo_h, cdo_v);
    eq("CFGLUT5 CE0 O6", o6_h, o6_v);
    ce <= 'X';
    rise(clk);
    eq("CFGLUT5 CEX CDO", cdo_h, cdo_v);
    ce <= 'Z';
    rise(clk);
    eq("CFGLUT5 CEZ CDO", cdo_h, cdo_v);
    ce <= '1';
    i0 <= '0'; i1 <= '0'; i2 <= '0'; i3 <= '0'; i4 <= '0';
    rise(clk);
    eq("CFGLUT5 shift CDO", cdo_h, cdo_v);
    eq("CFGLUT5 shift O6", o6_h, o6_v);
    assert o6_h = '1' report "CFGLUT5 did not shift CDI into bit 0" severity failure;

    -- The 101 ns timeout has released the INIT force. A rising edge
    -- now shifts CDI into the register.
    ce <= '1';
    cdi <= '0';
    i0 <= '0'; i1 <= '0'; i2 <= '0'; i3 <= '0'; i4 <= '0';
    rise(lclk);
    eq("CFGLUT5 released CDO", lcdo_h, lcdo_v);
    eq("CFGLUT5 released O6", lo6_h, lo6_v);
    assert lcdo_h = '0' report "CFGLUT5 did not shift after release" severity failure;

    -- Inverted clock idles high, then shifts on the falling edge.
    ce <= '1';
    cdi <= '0';
    wait for 2 ns;
    fall(nclk);
    eq("CFGLUT5 neg CDO", ncdo_h, ncdo_v);
    eq("CFGLUT5 neg O6", no6_h, no6_v);
    assert ncdo_h = '0' report "CFGLUT5 inverted clock did not shift" severity failure;

    report "tb_eq_ff PASS checks=" & integer'image(n) severity note;
    finish(0);
  end process;
end architecture sim;
