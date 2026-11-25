-- ISERDES against the submodule Verilog. XIL_TIMING is left undefined.
-- The Verilog flop delays are 300 ps; the bench waits 5 ns after the
-- edge. glbl.GSR is not visible to a Verilog module instantiated from
-- VHDL, so SR is pulsed before the comparisons.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_serdes is
end entity tb_eq_serdes;

architecture sim of tb_eq_serdes is
  constant step : time := 5 ns;

  signal clk, clkb, clkdiv, d, oclk, sr, slip : std_ulogic := '0';
  signal q1_h, q2_h, q3_h, q4_h, q5_h, q6_h : std_ulogic;
  signal q1_v, q2_v, q3_v, q4_v, q5_v, q6_v : std_ulogic;
  signal qm1_h, qm2_h, qm3_h, qm4_h : std_ulogic;
  signal qm1_v, qm2_v, qm3_v, qm4_v : std_ulogic;
  signal nq1_h, nq2_h, nq3_h, nq4_h, nq5_h, nq6_h : std_ulogic;
  signal nq1_v, nq2_v, nq3_v, nq4_v, nq5_v, nq6_v : std_ulogic;
  signal nm1_h, nm2_h, nm3_h, nm4_h : std_ulogic;
  signal nm1_v, nm2_v, nm3_v, nm4_v : std_ulogic;
  signal oser_done : boolean := false;

  signal oclk_s, odiv, oce : std_ulogic := '0';
  signal od1, od2, od3, od4, od5, od6 : std_ulogic := '0';
  signal osr : std_ulogic := '0';
  signal ot1 : std_ulogic := '0';
  signal oq_h, oq_v, tq_h, tq_v : std_ulogic;
  signal tclk, tdiv, tce : std_ulogic := '0';
  signal td1, td2, td3, td4 : std_ulogic := '0';
  signal tt1, tt2, tt3, tt4, tsr : std_ulogic := '0';
  signal tq4_h, tq4_v, oq4_h, oq4_v : std_ulogic;

  component ISERDES is
    generic (
      BITSLIP_ENABLE : boolean := FALSE;
      DATA_RATE : string := "DDR";
      DATA_WIDTH : integer := 4;
      INTERFACE_TYPE : string := "MEMORY";
      NUM_CE : integer := 2
    );
    port (
      O : out std_ulogic;
      Q1, Q2, Q3, Q4, Q5, Q6 : out std_ulogic;
      SHIFTOUT1, SHIFTOUT2 : out std_ulogic;
      BITSLIP, CE1, CE2, CLK, CLKDIV, D : in std_ulogic;
      DLYCE, DLYINC, DLYRST, OCLK, REV : in std_ulogic;
      SHIFTIN1, SHIFTIN2, SR : in std_ulogic
    );
  end component;

  component ISERDES_NODELAY is
    generic (
      BITSLIP_ENABLE : boolean := FALSE;
      DATA_RATE : string := "DDR";
      DATA_WIDTH : integer := 4;
      INTERFACE_TYPE : string := "MEMORY";
      NUM_CE : integer := 2
    );
    port (
      Q1, Q2, Q3, Q4, Q5, Q6 : out std_ulogic;
      SHIFTOUT1, SHIFTOUT2 : out std_ulogic;
      BITSLIP, CE1, CE2, CLK, CLKB, CLKDIV, D, OCLK, RST : in std_ulogic;
      SHIFTIN1, SHIFTIN2 : in std_ulogic
    );
  end component;

  component OSERDES is
    generic (
      DATA_RATE_OQ : string := "DDR";
      DATA_RATE_TQ : string := "DDR";
      DATA_WIDTH : integer := 4;
      TRISTATE_WIDTH : integer := 4
    );
    port (
      OQ, SHIFTOUT1, SHIFTOUT2, TQ : out std_ulogic;
      CLK, CLKDIV, D1, D2, D3, D4, D5, D6, OCE, REV : in std_ulogic;
      SHIFTIN1, SHIFTIN2, SR, T1, T2, T3, T4, TCE : in std_ulogic
    );
  end component;
begin
  net_h : entity unisim.ISERDES
    generic map (
      BITSLIP_ENABLE => TRUE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "NETWORKING", NUM_CE => 2
    )
    port map (
      O => open, Q1 => q1_h, Q2 => q2_h, Q3 => q3_h, Q4 => q4_h,
      Q5 => q5_h, Q6 => q6_h, SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => slip, CE1 => '1', CE2 => '1', CLK => clk, CLKDIV => clkdiv,
      D => d, DLYCE => '0', DLYINC => '0', DLYRST => '0', OCLK => '0',
      REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0', SR => sr
    );
  net_v : ISERDES
    generic map (
      BITSLIP_ENABLE => TRUE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "NETWORKING", NUM_CE => 2
    )
    port map (
      O => open, Q1 => q1_v, Q2 => q2_v, Q3 => q3_v, Q4 => q4_v,
      Q5 => q5_v, Q6 => q6_v, SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => slip, CE1 => '1', CE2 => '1', CLK => clk, CLKDIV => clkdiv,
      D => d, DLYCE => '0', DLYINC => '0', DLYRST => '0', OCLK => '0',
      REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0', SR => sr
    );

  mem_h : entity unisim.ISERDES
    generic map (
      BITSLIP_ENABLE => FALSE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "MEMORY", NUM_CE => 1
    )
    port map (
      O => open, Q1 => qm1_h, Q2 => qm2_h, Q3 => qm3_h, Q4 => qm4_h,
      Q5 => open, Q6 => open, SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => '0', CE1 => '1', CE2 => '1', CLK => clk, CLKDIV => clkdiv,
      D => d, DLYCE => '0', DLYINC => '0', DLYRST => '0', OCLK => oclk,
      REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0', SR => sr
    );
  mem_v : ISERDES
    generic map (
      BITSLIP_ENABLE => FALSE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "MEMORY", NUM_CE => 1
    )
    port map (
      O => open, Q1 => qm1_v, Q2 => qm2_v, Q3 => qm3_v, Q4 => qm4_v,
      Q5 => open, Q6 => open, SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => '0', CE1 => '1', CE2 => '1', CLK => clk, CLKDIV => clkdiv,
      D => d, DLYCE => '0', DLYINC => '0', DLYRST => '0', OCLK => oclk,
      REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0', SR => sr
    );

  nd_net_h : entity unisim.ISERDES_NODELAY
    generic map (
      BITSLIP_ENABLE => TRUE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "NETWORKING", NUM_CE => 2
    )
    port map (
      Q1 => nq1_h, Q2 => nq2_h, Q3 => nq3_h, Q4 => nq4_h, Q5 => nq5_h, Q6 => nq6_h,
      SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => slip, CE1 => '1', CE2 => '1', CLK => clk, CLKB => clkb, CLKDIV => clkdiv,
      D => d, OCLK => '0', RST => sr, SHIFTIN1 => '0', SHIFTIN2 => '0'
    );
  nd_net_v : ISERDES_NODELAY
    generic map (
      BITSLIP_ENABLE => TRUE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "NETWORKING", NUM_CE => 2
    )
    port map (
      Q1 => nq1_v, Q2 => nq2_v, Q3 => nq3_v, Q4 => nq4_v, Q5 => nq5_v, Q6 => nq6_v,
      SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => slip, CE1 => '1', CE2 => '1', CLK => clk, CLKB => clkb, CLKDIV => clkdiv,
      D => d, OCLK => '0', RST => sr, SHIFTIN1 => '0', SHIFTIN2 => '0'
    );
  nd_mem_h : entity unisim.ISERDES_NODELAY
    generic map (
      BITSLIP_ENABLE => FALSE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "MEMORY", NUM_CE => 1
    )
    port map (
      Q1 => nm1_h, Q2 => nm2_h, Q3 => nm3_h, Q4 => nm4_h, Q5 => open, Q6 => open,
      SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => '0', CE1 => '1', CE2 => '1', CLK => clk, CLKB => clkb, CLKDIV => clkdiv,
      D => d, OCLK => oclk, RST => sr, SHIFTIN1 => '0', SHIFTIN2 => '0'
    );
  nd_mem_v : ISERDES_NODELAY
    generic map (
      BITSLIP_ENABLE => FALSE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "MEMORY", NUM_CE => 1
    )
    port map (
      Q1 => nm1_v, Q2 => nm2_v, Q3 => nm3_v, Q4 => nm4_v, Q5 => open, Q6 => open,
      SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => '0', CE1 => '1', CE2 => '1', CLK => clk, CLKB => clkb, CLKDIV => clkdiv,
      D => d, OCLK => oclk, RST => sr, SHIFTIN1 => '0', SHIFTIN2 => '0'
    );

  oser_h : entity unisim.OSERDES
    generic map (DATA_RATE_OQ => "DDR", DATA_RATE_TQ => "BUF", DATA_WIDTH => 4, TRISTATE_WIDTH => 1)
    port map (
      OQ => oq_h, SHIFTOUT1 => open, SHIFTOUT2 => open, TQ => tq_h,
      CLK => oclk_s, CLKDIV => odiv, D1 => od1, D2 => od2, D3 => od3, D4 => od4,
      D5 => od5, D6 => od6, OCE => oce, REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0',
      SR => osr, T1 => ot1, T2 => '0', T3 => '0', T4 => '0', TCE => '0'
    );
  oser_v : OSERDES
    generic map (DATA_RATE_OQ => "DDR", DATA_RATE_TQ => "BUF", DATA_WIDTH => 4, TRISTATE_WIDTH => 1)
    port map (
      OQ => oq_v, SHIFTOUT1 => open, SHIFTOUT2 => open, TQ => tq_v,
      CLK => oclk_s, CLKDIV => odiv, D1 => od1, D2 => od2, D3 => od3, D4 => od4,
      D5 => od5, D6 => od6, OCE => oce, REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0',
      SR => osr, T1 => ot1, T2 => '0', T3 => '0', T4 => '0', TCE => '0'
    );

  oser4_h : entity unisim.OSERDES
    generic map (DATA_RATE_OQ => "DDR", DATA_RATE_TQ => "DDR", DATA_WIDTH => 4, TRISTATE_WIDTH => 4)
    port map (
      OQ => oq4_h, SHIFTOUT1 => open, SHIFTOUT2 => open, TQ => tq4_h,
      CLK => tclk, CLKDIV => tdiv, D1 => td1, D2 => td2, D3 => td3, D4 => td4,
      D5 => '0', D6 => '0', OCE => '1', REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0',
      SR => tsr, T1 => tt1, T2 => tt2, T3 => tt3, T4 => tt4, TCE => tce
    );
  oser4_v : OSERDES
    generic map (DATA_RATE_OQ => "DDR", DATA_RATE_TQ => "DDR", DATA_WIDTH => 4, TRISTATE_WIDTH => 4)
    port map (
      OQ => oq4_v, SHIFTOUT1 => open, SHIFTOUT2 => open, TQ => tq4_v,
      CLK => tclk, CLKDIV => tdiv, D1 => td1, D2 => td2, D3 => td3, D4 => td4,
      D5 => '0', D6 => '0', OCE => '1', REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0',
      SR => tsr, T1 => tt1, T2 => tt2, T3 => tt3, T4 => tt4, TCE => tce
    );

  stim : process
    variable checks : integer := 0;
    variable pat : std_logic_vector(31 downto 0) := x"A5C33C96";

    procedure check(h, v : std_ulogic; what : string) is
    begin
      checks := checks + 1;
      assert h = v
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(v)
        severity failure;
    end procedure;

    -- D changes, then the clock. The Verilog sampler reads o_delay,
    -- which is a nonblocking copy of D, so D has to be stable before
    -- the edge or the copy loses the race.
    procedure edge(bit : std_ulogic; rise : boolean; div_rise : boolean) is
    begin
      d <= bit;
      wait for 1 ns;
      if rise then
        clk <= '1';
        clkb <= '0';
        oclk <= '1';
        if div_rise then
          clkdiv <= '1';
        end if;
      else
        clk <= '0';
        clkb <= '1';
        oclk <= '0';
      end if;
      wait for step;
    end procedure;
  begin
    wait for 120 ns;
    sr <= '1';
    clk <= '1';
    clkb <= '0';
    oclk <= '1';
    clkdiv <= '1';
    wait for step;
    clk <= '0';
    clkb <= '1';
    oclk <= '0';
    wait for step;
    clkdiv <= '0';
    sr <= '0';
    wait for step;
    for e in 0 to 31 loop
      edge(pat(e), e mod 2 = 0, e mod 4 = 0);
      if e mod 4 = 3 then
        wait for step;
        check(q1_h, q1_v, "net q1");
        check(q2_h, q2_v, "net q2");
        check(q3_h, q3_v, "net q3");
        check(q4_h, q4_v, "net q4");
        check(q5_h, q5_v, "net q5");
        check(q6_h, q6_v, "net q6");
        check(qm1_h, qm1_v, "mem q1");
        check(qm2_h, qm2_v, "mem q2");
        check(qm3_h, qm3_v, "mem q3");
        check(qm4_h, qm4_v, "mem q4");
        check(nq1_h, nq1_v, "nd q1");
        check(nq2_h, nq2_v, "nd q2");
        check(nq3_h, nq3_v, "nd q3");
        check(nq4_h, nq4_v, "nd q4");
        check(nq5_h, nq5_v, "nd q5");
        check(nq6_h, nq6_v, "nd q6");
        check(nm1_h, nm1_v, "nd mem q1");
        check(nm2_h, nm2_v, "nd mem q2");
        check(nm3_h, nm3_v, "nd mem q3");
        check(nm4_h, nm4_v, "nd mem q4");
        clkdiv <= '0';
        wait for step;
      end if;
    end loop;
    if not oser_done then
      wait until oser_done;
    end if;
    report "PASS tb_eq_serdes checks=" & integer'image(checks);
    finish;
  end process;

  -- OSERDES uses its own clocks. BUF tristate is T1, and DDR width 4
  -- shifts T1..T4 the same way the data word shifts.
  ostim : process
    variable checks : integer := 0;
    variable pat : std_logic_vector(31 downto 0) := x"A5C33C96";

    procedure check(h, v : std_ulogic; what : string) is
    begin
      checks := checks + 1;
      assert h = v
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(v)
        severity failure;
    end procedure;

    procedure word(b1, b2, b3, b4 : std_ulogic) is
    begin
      od1 <= b1;
      od2 <= b2;
      od3 <= b3;
      od4 <= b4;
      td1 <= b1;
      td2 <= b2;
      td3 <= b3;
      td4 <= b4;
      tt1 <= b4;
      tt2 <= b3;
      tt3 <= b2;
      tt4 <= b1;
      odiv <= '1';
      tdiv <= '1';
      oclk_s <= '1';
      tclk <= '1';
      wait for step;
      check(oq_h, oq_v, "oq rise");
      check(tq_h, tq_v, "tq buf");
      check(oq4_h, oq4_v, "oq4 rise");
      check(tq4_h, tq4_v, "tq4 rise");
      oclk_s <= '0';
      tclk <= '0';
      wait for step;
      check(oq_h, oq_v, "oq fall");
      check(tq4_h, tq4_v, "tq4 fall");
      oclk_s <= '1';
      tclk <= '1';
      wait for step;
      check(oq_h, oq_v, "oq rise2");
      check(oq4_h, oq4_v, "oq4 rise2");
      oclk_s <= '0';
      tclk <= '0';
      odiv <= '0';
      tdiv <= '0';
      wait for step;
      check(oq_h, oq_v, "oq fall2");
      check(tq4_h, tq4_v, "tq4 fall2");
    end procedure;
  begin
    oce <= '1';
    tce <= '1';
    wait for 120 ns;
    osr <= '1';
    tsr <= '1';
    oclk_s <= '1';
    tclk <= '1';
    odiv <= '1';
    tdiv <= '1';
    wait for step;
    oclk_s <= '0';
    tclk <= '0';
    wait for step;
    osr <= '0';
    tsr <= '0';
    odiv <= '0';
    tdiv <= '0';
    wait for step;
    for e in 0 to 7 loop
      ot1 <= pat(e);
      word(pat(e), pat(e + 8), pat(e + 16), pat(e + 24));
    end loop;
    report "PASS tb_eq_serdes oserdes checks=" & integer'image(checks);
    oser_done <= true;
    wait;
  end process;
end architecture sim;
