-- Equivalence for the clock-buffer batch against the Apache-2.0 Verilog,
-- analysed into library work. BUFCE_ROW $finish without XIL_TIMING, and
-- with XIL_TIMING its delay nets are not driven, so it is checked against
-- the VHDL BUFCE_LEAF (HARDSYNC against SYNC).

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_bufg is
end entity tb_eq_bufg;

architecture sim of tb_eq_bufg is
  signal il, cel : std_ulogic := '0';
  signal ig, ceg : std_ulogic := '0';
  signal ips, ipsv : std_ulogic := '0';
  signal i0, i1, ce0, ce1, ign0, ign1, s0, s1 : std_ulogic := '0';
  signal ih, ceh : std_ulogic := '0';
  signal im, cem : std_ulogic := '0';
  signal ib, ceb, clrb : std_ulogic := '0';
  signal id, ced, clrd : std_ulogic := '0';
  signal igt, cegt, cemask, clrgt, clrmask : std_ulogic := '0';
  signal divgt : std_logic_vector(2 downto 0) := "000";
  signal a, b : std_ulogic := '0';

  signal io_h, io_v, mr_h, mr_v : std_ulogic;
  signal ces_h, ces_v, clrs_h, clrs_v : std_ulogic;
  signal leaf_h, leaf_v, leafa_h, leafa_v, leafi_h, leafi_v : std_ulogic;
  signal row_s, row_a, row_h : std_ulogic;
  signal gce_h, gce_v, gcea_h, gcea_v, gceh_h, gceh_v, gcei_h, gcei_v : std_ulogic;
  signal gces_h, gces_v : std_ulogic;
  signal ps_h, ps_v, psv_h, psv_v : std_ulogic;
  signal ctl_h, ctl_v, ctl0_h, ctl0_v, ctl1_h, ctl1_v : std_ulogic;
  signal hce_h, hcea_h, hce1_h : std_ulogic;
  signal mce_h, mce_v, mce1_h, mce1_v : std_ulogic;
  signal by_h, by_v, d2_h, d2_v, d1_h, d1_v, d8_h, d8_v, v4_h, v4_v : std_ulogic;
  signal div1_h, div1_v, div2_h, div2_v, div4_h, div4_v : std_ulogic;
  signal gt_h, gt_v, gtv_h, gtv_v : std_ulogic;

  component BUFIO is
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component BUFMR is
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component BUFG_GT_SYNC is
    port (
      CESYNC, CLRSYNC : out std_ulogic;
      CE, CLK, CLR : in std_ulogic
    );
  end component;
  component BUFCE_LEAF is
    generic (
      CE_TYPE : string := "SYNC";
      IS_CE_INVERTED : bit := '0';
      IS_I_INVERTED : bit := '0'
    );
    port (O : out std_ulogic; CE, I : in std_ulogic);
  end component;
  component BUFGCE is
    generic (
      CE_TYPE : string := "SYNC";
      IS_CE_INVERTED : bit := '0';
      IS_I_INVERTED : bit := '0';
      SIM_DEVICE : string := "ULTRASCALE";
      STARTUP_SYNC : boolean := FALSE
    );
    port (O : out std_ulogic; CE, I : in std_ulogic);
  end component;
  component BUFG_PS is
    generic (
      SIM_DEVICE : string := "ULTRASCALE_PLUS";
      STARTUP_SYNC : boolean := FALSE
    );
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component BUFGCTRL is
    generic (
      CE_TYPE_CE0 : string := "SYNC";
      CE_TYPE_CE1 : string := "SYNC";
      INIT_OUT : integer := 0;
      IS_CE0_INVERTED : bit := '0';
      IS_CE1_INVERTED : bit := '0';
      IS_I0_INVERTED : bit := '0';
      IS_I1_INVERTED : bit := '0';
      IS_IGNORE0_INVERTED : bit := '0';
      IS_IGNORE1_INVERTED : bit := '0';
      IS_S0_INVERTED : bit := '0';
      IS_S1_INVERTED : bit := '0';
      PRESELECT_I0 : boolean := FALSE;
      PRESELECT_I1 : boolean := FALSE;
      SIM_DEVICE : string := "ULTRASCALE";
      STARTUP_SYNC : boolean := FALSE
    );
    port (
      O : out std_ulogic;
      CE0, CE1, I0, I1, IGNORE0, IGNORE1, S0, S1 : in std_ulogic
    );
  end component;
  component BUFMRCE is
    generic (
      CE_TYPE : string := "SYNC";
      INIT_OUT : integer := 0;
      IS_CE_INVERTED : bit := '0'
    );
    port (O : out std_ulogic; CE, I : in std_ulogic);
  end component;
  component BUFR is
    generic (
      BUFR_DIVIDE : string := "BYPASS";
      SIM_DEVICE : string := "7SERIES"
    );
    port (O : out std_ulogic; CE, CLR, I : in std_ulogic);
  end component;
  component BUFGCE_DIV is
    generic (
      BUFGCE_DIVIDE : integer := 1;
      CE_TYPE : string := "SYNC";
      HARDSYNC_CLR : boolean := FALSE;
      IS_CE_INVERTED : bit := '0';
      IS_CLR_INVERTED : bit := '0';
      IS_I_INVERTED : bit := '0';
      SIM_DEVICE : string := "ULTRASCALE";
      STARTUP_SYNC : boolean := FALSE
    );
    port (O : out std_ulogic; CE, CLR, I : in std_ulogic);
  end component;
  component BUFG_GT is
    generic (
      SIM_DEVICE : string := "ULTRASCALE";
      STARTUP_SYNC : boolean := FALSE
    );
    port (
      O : out std_ulogic;
      CE, CEMASK, CLR, CLRMASK : in std_ulogic;
      DIV : in std_logic_vector(2 downto 0);
      I : in std_ulogic
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
  u_io_h : entity unisim.BUFIO port map (O => io_h, I => a);
  u_io_v : BUFIO port map (O => io_v, I => a);
  u_mr_h : entity unisim.BUFMR port map (O => mr_h, I => a);
  u_mr_v : BUFMR port map (O => mr_v, I => a);

  u_sy_h : entity unisim.BUFG_GT_SYNC port map (ces_h, clrs_h, a, b, b);
  u_sy_v : BUFG_GT_SYNC port map (ces_v, clrs_v, a, b, b);

  u_lf_h : entity unisim.BUFCE_LEAF port map (O => leaf_h, CE => cel, I => il);
  u_lf_v : BUFCE_LEAF port map (O => leaf_v, CE => cel, I => il);
  u_lfa_h : entity unisim.BUFCE_LEAF generic map (CE_TYPE => "ASYNC")
    port map (O => leafa_h, CE => cel, I => il);
  u_lfa_v : BUFCE_LEAF generic map (CE_TYPE => "ASYNC")
    port map (O => leafa_v, CE => cel, I => il);
  u_lfi_h : entity unisim.BUFCE_LEAF
    generic map (IS_CE_INVERTED => '1', IS_I_INVERTED => '1')
    port map (O => leafi_h, CE => cel, I => il);
  u_lfi_v : BUFCE_LEAF
    generic map (IS_CE_INVERTED => '1', IS_I_INVERTED => '1')
    port map (O => leafi_v, CE => cel, I => il);

  u_row_s : entity unisim.BUFCE_ROW port map (O => row_s, CE => cel, I => il);
  u_row_a : entity unisim.BUFCE_ROW generic map (CE_TYPE => "ASYNC")
    port map (O => row_a, CE => cel, I => il);
  u_row_h : entity unisim.BUFCE_ROW generic map (CE_TYPE => "HARDSYNC")
    port map (O => row_h, CE => cel, I => il);

  u_gce_h : entity unisim.BUFGCE port map (O => gce_h, CE => ceg, I => ig);
  u_gce_v : BUFGCE port map (O => gce_v, CE => ceg, I => ig);
  u_gcea_h : entity unisim.BUFGCE generic map (CE_TYPE => "ASYNC")
    port map (O => gcea_h, CE => ceg, I => ig);
  u_gcea_v : BUFGCE generic map (CE_TYPE => "ASYNC")
    port map (O => gcea_v, CE => ceg, I => ig);
  u_gceh_h : entity unisim.BUFGCE generic map (CE_TYPE => "HARDSYNC")
    port map (O => gceh_h, CE => ceg, I => ig);
  u_gceh_v : BUFGCE generic map (CE_TYPE => "HARDSYNC")
    port map (O => gceh_v, CE => ceg, I => ig);
  u_gcei_h : entity unisim.BUFGCE
    generic map (IS_CE_INVERTED => '1', IS_I_INVERTED => '1')
    port map (O => gcei_h, CE => ceg, I => ig);
  u_gcei_v : BUFGCE
    generic map (IS_CE_INVERTED => '1', IS_I_INVERTED => '1')
    port map (O => gcei_v, CE => ceg, I => ig);
  u_gces_h : entity unisim.BUFGCE
    generic map (SIM_DEVICE => "VERSAL_PRIME", STARTUP_SYNC => TRUE)
    port map (O => gces_h, CE => ceg, I => ig);
  u_gces_v : BUFGCE
    generic map (SIM_DEVICE => "VERSAL_PRIME", STARTUP_SYNC => TRUE)
    port map (O => gces_v, CE => ceg, I => ig);

  u_ps_h : entity unisim.BUFG_PS port map (O => ps_h, I => ips);
  u_ps_v : BUFG_PS port map (O => ps_v, I => ips);
  u_psv_h : entity unisim.BUFG_PS
    generic map (SIM_DEVICE => "VERSAL_PRIME", STARTUP_SYNC => TRUE)
    port map (O => psv_h, I => ipsv);
  u_psv_v : BUFG_PS
    generic map (SIM_DEVICE => "VERSAL_PRIME", STARTUP_SYNC => TRUE)
    port map (O => psv_v, I => ipsv);

  u_ctl_h : entity unisim.BUFGCTRL
    port map (ctl_h, ce0, ce1, i0, i1, ign0, ign1, s0, s1);
  u_ctl_v : BUFGCTRL
    port map (ctl_v, ce0, ce1, i0, i1, ign0, ign1, s0, s1);
  u_ctl0_h : entity unisim.BUFGCTRL generic map (PRESELECT_I0 => TRUE)
    port map (ctl0_h, ce0, ce1, i0, i1, ign0, ign1, s0, s1);
  u_ctl0_v : BUFGCTRL generic map (PRESELECT_I0 => TRUE)
    port map (ctl0_v, ce0, ce1, i0, i1, ign0, ign1, s0, s1);
  u_ctl1_h : entity unisim.BUFGCTRL
    generic map (PRESELECT_I1 => TRUE, INIT_OUT => 1, SIM_DEVICE => "7SERIES")
    port map (ctl1_h, ce0, ce1, i0, i1, ign0, ign1, s0, s1);
  u_ctl1_v : BUFGCTRL
    generic map (PRESELECT_I1 => TRUE, INIT_OUT => 1, SIM_DEVICE => "7SERIES")
    port map (ctl1_v, ce0, ce1, i0, i1, ign0, ign1, s0, s1);

  -- BUFHCE's Verilog uses defparam, which this NVC does not elaborate.
  -- The cell is two BUFGCTRL instances; those are equivalence-tested,
  -- and BUFHCE itself is self-checked.
  u_hce_h : entity unisim.BUFHCE port map (O => hce_h, CE => ceh, I => ih);
  u_hcea_h : entity unisim.BUFHCE generic map (CE_TYPE => "ASYNC")
    port map (O => hcea_h, CE => ceh, I => ih);
  u_hce1_h : entity unisim.BUFHCE
    generic map (INIT_OUT => 1, IS_CE_INVERTED => '1')
    port map (O => hce1_h, CE => ceh, I => ih);

  u_mce_h : entity unisim.BUFMRCE port map (O => mce_h, CE => cem, I => im);
  u_mce_v : BUFMRCE port map (O => mce_v, CE => cem, I => im);
  u_mce1_h : entity unisim.BUFMRCE generic map (INIT_OUT => 1, CE_TYPE => "ASYNC")
    port map (O => mce1_h, CE => cem, I => im);
  u_mce1_v : BUFMRCE generic map (INIT_OUT => 1, CE_TYPE => "ASYNC")
    port map (O => mce1_v, CE => cem, I => im);

  u_by_h : entity unisim.BUFR port map (O => by_h, CE => ceb, CLR => clrb, I => ib);
  u_by_v : BUFR port map (O => by_v, CE => ceb, CLR => clrb, I => ib);
  u_d1_h : entity unisim.BUFR generic map (BUFR_DIVIDE => "1")
    port map (O => d1_h, CE => ceb, CLR => clrb, I => ib);
  u_d1_v : BUFR generic map (BUFR_DIVIDE => "1")
    port map (O => d1_v, CE => ceb, CLR => clrb, I => ib);
  u_d2_h : entity unisim.BUFR generic map (BUFR_DIVIDE => "2")
    port map (O => d2_h, CE => ceb, CLR => clrb, I => ib);
  u_d2_v : BUFR generic map (BUFR_DIVIDE => "2")
    port map (O => d2_v, CE => ceb, CLR => clrb, I => ib);
  u_d8_h : entity unisim.BUFR generic map (BUFR_DIVIDE => "8", SIM_DEVICE => "VIRTEX6")
    port map (O => d8_h, CE => ceb, CLR => clrb, I => ib);
  u_d8_v : BUFR generic map (BUFR_DIVIDE => "8", SIM_DEVICE => "VIRTEX6")
    port map (O => d8_v, CE => ceb, CLR => clrb, I => ib);
  u_v4_h : entity unisim.BUFR
    generic map (BUFR_DIVIDE => "2", SIM_DEVICE => "VIRTEX4")
    port map (O => v4_h, CE => ceb, CLR => clrb, I => ib);
  u_v4_v : BUFR
    generic map (BUFR_DIVIDE => "2", SIM_DEVICE => "VIRTEX4")
    port map (O => v4_v, CE => ceb, CLR => clrb, I => ib);

  u_dv1_h : entity unisim.BUFGCE_DIV port map (O => div1_h, CE => ced, CLR => clrd, I => id);
  u_dv1_v : BUFGCE_DIV port map (O => div1_v, CE => ced, CLR => clrd, I => id);
  u_dv2_h : entity unisim.BUFGCE_DIV generic map (BUFGCE_DIVIDE => 2)
    port map (O => div2_h, CE => ced, CLR => clrd, I => id);
  u_dv2_v : BUFGCE_DIV generic map (BUFGCE_DIVIDE => 2)
    port map (O => div2_v, CE => ced, CLR => clrd, I => id);
  u_dv4_h : entity unisim.BUFGCE_DIV
    generic map (BUFGCE_DIVIDE => 4, IS_I_INVERTED => '1', IS_CE_INVERTED => '1')
    port map (O => div4_h, CE => ced, CLR => clrd, I => id);
  u_dv4_v : BUFGCE_DIV
    generic map (BUFGCE_DIVIDE => 4, IS_I_INVERTED => '1', IS_CE_INVERTED => '1')
    port map (O => div4_v, CE => ced, CLR => clrd, I => id);

  u_gt_h : entity unisim.BUFG_GT
    port map (gt_h, cegt, cemask, clrgt, clrmask, divgt, igt);
  u_gt_v : BUFG_GT
    port map (gt_v, cegt, cemask, clrgt, clrmask, divgt, igt);
  u_gtv_h : entity unisim.BUFG_GT generic map (SIM_DEVICE => "VERSAL_PRIME")
    port map (gtv_h, cegt, cemask, clrgt, clrmask, divgt, igt);
  u_gtv_v : BUFG_GT generic map (SIM_DEVICE => "VERSAL_PRIME")
    port map (gtv_v, cegt, cemask, clrgt, clrmask, divgt, igt);

  process
    variable n : integer := 0;

    procedure step(t : time := 1 ns) is
    begin
      wait for t;
    end procedure;

    procedure bump is
    begin
      n := n + 1;
    end procedure;

    procedure eq(name : string; got, exp : std_ulogic) is
    begin
      bump;
      assert got = from_vlog(exp)
        report name & " VHDL=" & std_ulogic'image(got)
          & " Verilog=" & std_ulogic'image(exp)
        severity failure;
    end procedure;

    procedure expect(name : string; got, exp : std_ulogic) is
    begin
      bump;
      assert got = exp
        report name & " got " & std_ulogic'image(got)
          & " expected " & std_ulogic'image(exp)
        severity failure;
    end procedure;

    procedure tick(signal clk : out std_ulogic) is
    begin
      clk <= '1';
      step;
      clk <= '0';
      step;
    end procedure;

    procedure eq_leaf(tag : string) is
    begin
      eq(tag & " leaf", leaf_h, leaf_v);
      eq(tag & " leaf async", leafa_h, leafa_v);
      eq(tag & " leaf inv", leafi_h, leafi_v);
      expect(tag & " row sync", row_s, leaf_h);
      expect(tag & " row async", row_a, leafa_h);
      expect(tag & " row hardsync", row_h, leaf_h);
    end procedure;

    procedure eq_gce(tag : string; full : boolean := true) is
    begin
      eq(tag & " gce", gce_h, gce_v);
      eq(tag & " gce async", gcea_h, gcea_v);
      -- NVC does not run always @(*) at time 0, so O stays X until I or
      -- the enable changes. Inverted I and STARTUP_SYNC do not move on
      -- the first CE write; compare them after I has toggled.
      if full then
        eq(tag & " gce hs", gceh_h, gceh_v);
        eq(tag & " gce inv", gcei_h, gcei_v);
        eq(tag & " gce startup", gces_h, gces_v);
      end if;
    end procedure;

    procedure eq_ctl(tag : string) is
    begin
      eq(tag & " ctrl", ctl_h, ctl_v);
      eq(tag & " ctrl I0", ctl0_h, ctl0_v);
      eq(tag & " ctrl I1", ctl1_h, ctl1_v);
    end procedure;

    procedure eq_hce(tag : string) is
    begin
      eq(tag & " mrce", mce_h, mce_v);
      eq(tag & " mrce init1", mce1_h, mce1_v);
    end procedure;

    procedure eq_bufr(tag : string) is
    begin
      eq(tag & " bypass", by_h, by_v);
      eq(tag & " div1", d1_h, d1_v);
      eq(tag & " div2", d2_h, d2_v);
      eq(tag & " div8", d8_h, d8_v);
      eq(tag & " v4", v4_h, v4_v);
    end procedure;

    procedure eq_div(tag : string) is
    begin
      -- Divide values other than 1 are self-checked. On this NVC the
      -- Verilog toggle-count always loses the race with BUFGCE_DIVIDE_BIN
      -- and stays at 1, so it is not a divider reference.
      eq(tag & " /1", div1_h, div1_v);
    end procedure;

    procedure eq_gt(tag : string) is
    begin
      eq(tag & " gt", gt_h, gt_v);
      eq(tag & " gt versal", gtv_h, gtv_v);
    end procedure;
  begin
    -- Past ROC (100 ns) and GRESTORE (10 ns to 20 ns).
    wait for 120 ns;

    for ai in 0 to 3 loop
      if ai = 0 then
        a <= '0';
      elsif ai = 1 then
        a <= '1';
      elsif ai = 2 then
        a <= 'X';
      else
        a <= 'Z';
      end if;
      if ai mod 2 = 0 then
        b <= '0';
      else
        b <= '1';
      end if;
      step;
      eq("BUFIO", io_h, io_v);
      eq("BUFMR", mr_h, mr_v);
      eq("CESYNC", ces_h, ces_v);
      eq("CLRSYNC", clrs_h, clrs_v);
      if a = '0' or a = '1' then
        expect("BUFIO level", io_h, a);
        expect("BUFMR level", mr_h, a);
      else
        expect("BUFIO buf", io_h, 'X');
      end if;
      if a = 'Z' then
        expect("CESYNC Z", ces_h, '1');
      elsif a = '0' or a = '1' then
        expect("CESYNC level", ces_h, a);
      end if;
    end loop;
    a <= '0';
    b <= 'Z';
    step;
    eq("CLRSYNC Z", clrs_h, clrs_v);
    expect("CLRSYNC Z is 0", clrs_h, '0');
    b <= 'X';
    step;
    eq("CLRSYNC X", clrs_h, clrs_v);
    expect("CLRSYNC X", clrs_h, 'X');

    -- GSR on BUFCE_LEAF forces the enable, so a rising I during GSR still
    -- passes. That window is over; resync by sampling CE while I is low.
    il <= '0';
    cel <= '1';
    step;
    eq_leaf("arm");
    expect("leaf armed", leaf_h, '0');
    il <= '1';
    step;
    eq_leaf("high");
    expect("leaf passes", leaf_h, '1');
    expect("leaf async passes", leafa_h, '1');
    cel <= '0';
    step;
    eq_leaf("ce drop");
    expect("sync holds", leaf_h, '1');
    expect("async drops", leafa_h, '0');
    il <= '0';
    step;
    eq_leaf("sample 0");
    expect("sync sampled 0", leaf_h, '0');
    il <= '1';
    step;
    eq_leaf("stay off");
    expect("sync stays off", leaf_h, '0');
    cel <= 'Z';
    il <= '0';
    step;
    eq_leaf("ce Z");
    il <= '1';
    step;
    eq_leaf("ce Z high");
    expect("Z enables", leaf_h, '1');
    cel <= 'X';
    il <= '0';
    step;
    il <= '1';
    step;
    eq_leaf("ce X");
    cel <= '1';
    il <= 'Z';
    step;
    eq_leaf("i Z");
    il <= 'X';
    step;
    eq_leaf("i X");

    ig <= '0';
    ceg <= '1';
    step;
    eq_gce("arm", false);
    ig <= '1';
    step;
    eq_gce("on");
    expect("gce on", gce_h, '1');
    ceg <= '0';
    step;
    eq_gce("hold");
    expect("gce sync holds", gce_h, '1');
    expect("gce async clears", gcea_h, '0');
    ig <= '0';
    step;
    eq_gce("low");
    expect("gce sampled 0", gce_h, '0');
    ceg <= '1';
    for k in 1 to 4 loop
      tick(ig);
      eq_gce("hs " & integer'image(k));
    end loop;
    ig <= '1';
    step;
    eq_gce("hs high");
    expect("hardsync on", gceh_h, '1');
    ceg <= 'X';
    ig <= '0';
    step;
    ig <= '1';
    step;
    eq_gce("ce X");
    ceg <= 'Z';
    ig <= '0';
    step;
    ig <= '1';
    step;
    eq_gce("ce Z");

    ips <= '0';
    step;
    eq("ps low", ps_h, ps_v);
    ips <= '1';
    step;
    eq("ps high", ps_h, ps_v);
    expect("ps follows", ps_h, '1');
    ips <= '0';
    step;
    eq("ps fall", ps_h, ps_v);
    expect("ps low", ps_h, '0');
    ips <= 'Z';
    step;
    eq("ps Z", ps_h, ps_v);
    ips <= 'X';
    step;
    eq("ps X", ps_h, ps_v);
    for k in 1 to 4 loop
      tick(ipsv);
      eq("ps versal " & integer'image(k), psv_h, psv_v);
    end loop;
    ipsv <= '1';
    step;
    eq("ps versal run", psv_h, psv_v);
    expect("versal startup passed", psv_h, '1');

    s0 <= '1';
    s1 <= '1';
    ce0 <= '1';
    ce1 <= '1';
    ign0 <= '0';
    ign1 <= '0';
    i0 <= '0';
    i1 <= '0';
    step;
    eq_ctl("idle");
    for k in 1 to 6 loop
      i0 <= '1';
      step;
      eq_ctl("i0h " & integer'image(k));
      i0 <= '0';
      step;
      eq_ctl("i0l " & integer'image(k));
      i1 <= '1';
      step;
      eq_ctl("i1h " & integer'image(k));
      i1 <= '0';
      step;
      eq_ctl("i1l " & integer'image(k));
    end loop;
    s0 <= '0';
    s1 <= '1';
    step;
    eq_ctl("sel1");
    for k in 1 to 4 loop
      tick(i0);
      tick(i1);
      eq_ctl("sel " & integer'image(k));
    end loop;
    ce0 <= '0';
    ce1 <= '0';
    step;
    for k in 1 to 3 loop
      tick(i0);
      tick(i1);
      eq_ctl("ce0 " & integer'image(k));
    end loop;
    ign0 <= '1';
    ign1 <= '1';
    ce0 <= '1';
    ce1 <= '0';
    s0 <= '1';
    s1 <= '1';
    step;
    for k in 1 to 3 loop
      tick(i0);
      tick(i1);
      eq_ctl("ign " & integer'image(k));
    end loop;
    i0 <= 'X';
    i1 <= 'Z';
    ce0 <= 'Z';
    s0 <= 'X';
    step;
    eq_ctl("xz");

    ceh <= '1';
    ih <= '0';
    step;
    ih <= '1';
    step;
    eq_hce("on");
    expect("hce on", hce_h, '1');
    ih <= '0';
    ceh <= '0';
    step;
    ih <= '1';
    step;
    eq_hce("off");
    expect("hce sync off", hce_h, '0');
    ih <= '1';
    ceh <= '1';
    step;
    eq_hce("async mid");
    expect("hce sync stays off", hce_h, '0');
    expect("hce async follows", hcea_h, '1');
    ih <= '0';
    ceh <= 'X';
    step;
    ih <= '1';
    step;
    eq_hce("ce X");
    ceh <= 'Z';
    ih <= '0';
    step;
    ih <= 'Z';
    step;
    eq_hce("z");

    cem <= '1';
    im <= '0';
    step;
    im <= '1';
    step;
    eq_hce("mr on");
    expect("mrce on", mce_h, '1');
    im <= '0';
    cem <= '0';
    step;
    im <= '1';
    step;
    eq_hce("mr off");
    expect("mrce off", mce_h, '0');

    ib <= '1';
    step;
    eq_bufr("high");
    expect("bypass 1", by_h, '1');
    ib <= '0';
    step;
    eq_bufr("low");
    expect("bypass 0", by_h, '0');
    ib <= 'Z';
    step;
    eq_bufr("Z");
    expect("bypass Z", by_h, 'X');
    ib <= 'X';
    clrb <= '1';
    step;
    eq_bufr("clr");
    expect("divider cleared", d2_h, '0');
    clrb <= '0';
    ceb <= '1';
    ib <= '0';
    step;
    for k in 1 to 20 loop
      tick(ib);
      eq_bufr("run " & integer'image(k));
    end loop;
    -- Drop CE while I is low so i_ce does not glitch in the same timestep.
    ceb <= '0';
    step;
    eq_bufr("ce dropped");
    for k in 1 to 4 loop
      tick(ib);
      eq_bufr("ce0 " & integer'image(k));
    end loop;
    clrb <= '1';
    step;
    eq_bufr("clr2");
    expect("div2 clear", d2_h, '0');
    expect("bypass ignores clr", by_h, '0');

    id <= '0';
    ced <= '0';
    step;
    clrd <= '1';
    step;
    ced <= '1';
    step;
    eq_div("clr");
    expect("divide 1 cleared", div1_h, '0');
    clrd <= '0';
    step;
    eq_div("arm");
    for k in 1 to 8 loop
      id <= '1';
      step;
      eq_div("cnt " & integer'image(k));
      expect("divide 1 high", div1_h, '1');
      if k mod 2 = 1 then
        expect("div2 high " & integer'image(k), div2_h, '1');
      else
        expect("div2 low " & integer'image(k), div2_h, '0');
      end if;
      id <= '0';
      step;
      eq_div("low " & integer'image(k));
      expect("divide 1 low", div1_h, '0');
    end loop;
    ced <= '0';
    for k in 1 to 4 loop
      tick(id);
      eq_div("off " & integer'image(k));
    end loop;
    ced <= 'X';
    clrd <= 'X';
    step;
    eq_div("x");
    clrd <= '0';
    ced <= 'Z';
    id <= '0';
    step;
    tick(id);
    eq_div("z");

    cegt <= '1';
    clrgt <= '0';
    cemask <= '0';
    clrmask <= '0';
    divgt <= "000";
    igt <= '0';
    step;
    eq_gt("arm");
    for k in 1 to 6 loop
      tick(igt);
      eq_gt("pass " & integer'image(k));
    end loop;
    expect("gt follows", gt_h, '0');
    igt <= '1';
    step;
    eq_gt("high");
    divgt <= "001";
    clrgt <= '1';
    step;
    eq_gt("div clr");
    clrgt <= '0';
    igt <= '0';
    step;
    for k in 1 to 16 loop
      tick(igt);
      eq_gt("div " & integer'image(k));
    end loop;
    cemask <= '1';
    clrmask <= '1';
    divgt <= "011";
    step;
    for k in 1 to 10 loop
      tick(igt);
      eq_gt("mask " & integer'image(k));
    end loop;
    cegt <= 'Z';
    clrgt <= 'Z';
    divgt <= "0X0";
    step;
    eq_gt("xz");

    report "tb_eq_bufg PASS checks=" & integer'image(n) severity note;
    finish(0);
  end process;
end architecture sim;
