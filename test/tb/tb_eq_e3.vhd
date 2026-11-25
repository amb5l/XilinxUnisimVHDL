-- IBUFE3, IBUFDSE3 and OBUFDS_DPHY against the submodule Verilog.
-- XIL_TIMING stays undefined. The offset oscillator does not free-run.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_e3 is
end entity tb_eq_e3;

architecture sim of tb_eq_e3 is
  signal i, dis, en, vref : std_ulogic := '0';
  signal osc : std_logic_vector(3 downto 0) := "0000";
  signal iu, disu, enu : std_ulogic := '0';
  signal oscu : std_logic_vector(3 downto 0) := "0000";
  signal iv, disv, env : std_ulogic := '0';
  signal oscv : std_logic_vector(3 downto 0) := "0000";
  signal di, dib, ddis : std_ulogic := '0';
  signal den : std_logic_vector(1 downto 0) := "00";
  signal dosc : std_logic_vector(3 downto 0) := "0000";
  signal bi, bib, bdis : std_ulogic := '0';
  signal ben : std_logic_vector(1 downto 0) := "00";
  signal bosc : std_logic_vector(3 downto 0) := "0000";
  signal ui, uib, udis : std_ulogic := '0';
  signal uen : std_logic_vector(1 downto 0) := "00";
  signal uosc : std_logic_vector(3 downto 0) := "0000";
  signal hs, hst, lpn, lpp, lpt : std_ulogic := '0';

  signal o_h, o_v : std_ulogic;
  signal ou_h, ou_v : std_ulogic;
  signal ov_h, ov_v : std_ulogic;
  signal d_h, d_v : std_ulogic;
  signal b_h, b_v : std_ulogic;
  signal u_h, u_v : std_ulogic;
  signal po_h, po_v, pb_h, pb_v : std_ulogic;

  component IBUFE3 is
    generic (
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT";
      SIM_DEVICE : string := "ULTRASCALE";
      SIM_INPUT_BUFFER_OFFSET : integer := 0;
      USE_IBUFDISABLE : boolean := FALSE
    );
    port (
      O : out std_ulogic;
      I : in std_ulogic;
      IBUFDISABLE : in std_ulogic;
      OSC : in std_logic_vector(3 downto 0);
      OSC_EN : in std_ulogic;
      VREF : in std_ulogic
    );
  end component;

  component IBUFDSE3 is
    generic (
      DIFF_TERM : boolean := FALSE;
      DQS_BIAS : boolean := FALSE;
      IBUF_LOW_PWR : boolean := TRUE;
      IOSTANDARD : string := "DEFAULT";
      SIM_DEVICE : string := "ULTRASCALE";
      SIM_INPUT_BUFFER_OFFSET : integer := 0;
      USE_IBUFDISABLE : boolean := FALSE
    );
    port (
      O : out std_ulogic;
      I : in std_ulogic;
      IB : in std_ulogic;
      IBUFDISABLE : in std_ulogic;
      OSC : in std_logic_vector(3 downto 0);
      OSC_EN : in std_logic_vector(1 downto 0)
    );
  end component;

  component OBUFDS_DPHY is
    generic (IOSTANDARD : string := "DEFAULT");
    port (
      O : out std_ulogic;
      OB : out std_ulogic;
      HSTX_I : in std_ulogic;
      HSTX_T : in std_ulogic;
      LPTX_I_N : in std_ulogic;
      LPTX_I_P : in std_ulogic;
      LPTX_T : in std_ulogic
    );
  end component;
begin
  u_e_h : entity unisim.IBUFE3
    port map (O => o_h, I => i, IBUFDISABLE => dis, OSC => osc, OSC_EN => en, VREF => vref);
  u_e_v : IBUFE3
    port map (O => o_v, I => i, IBUFDISABLE => dis, OSC => osc, OSC_EN => en, VREF => vref);

  u_u_h : entity unisim.IBUFE3
    generic map (USE_IBUFDISABLE => TRUE)
    port map (O => ou_h, I => iu, IBUFDISABLE => disu, OSC => oscu, OSC_EN => enu, VREF => vref);
  u_u_v : IBUFE3
    generic map (USE_IBUFDISABLE => TRUE)
    port map (O => ou_v, I => iu, IBUFDISABLE => disu, OSC => oscu, OSC_EN => enu, VREF => vref);

  u_v_h : entity unisim.IBUFE3
    generic map (SIM_DEVICE => "VERSAL_AI_CORE")
    port map (O => ov_h, I => iv, IBUFDISABLE => disv, OSC => oscv, OSC_EN => env, VREF => vref);
  u_v_v : IBUFE3
    generic map (SIM_DEVICE => "VERSAL_AI_CORE")
    port map (O => ov_v, I => iv, IBUFDISABLE => disv, OSC => oscv, OSC_EN => env, VREF => vref);

  u_d_h : entity unisim.IBUFDSE3
    port map (O => d_h, I => di, IB => dib, IBUFDISABLE => ddis, OSC => dosc, OSC_EN => den);
  u_d_v : IBUFDSE3
    port map (O => d_v, I => di, IB => dib, IBUFDISABLE => ddis, OSC => dosc, OSC_EN => den);

  u_b_h : entity unisim.IBUFDSE3
    generic map (DQS_BIAS => TRUE)
    port map (O => b_h, I => bi, IB => bib, IBUFDISABLE => bdis, OSC => bosc, OSC_EN => ben);
  u_b_v : IBUFDSE3
    generic map (DQS_BIAS => TRUE)
    port map (O => b_v, I => bi, IB => bib, IBUFDISABLE => bdis, OSC => bosc, OSC_EN => ben);

  u_x_h : entity unisim.IBUFDSE3
    generic map (USE_IBUFDISABLE => TRUE)
    port map (O => u_h, I => ui, IB => uib, IBUFDISABLE => udis, OSC => uosc, OSC_EN => uen);
  u_x_v : IBUFDSE3
    generic map (USE_IBUFDISABLE => TRUE)
    port map (O => u_v, I => ui, IB => uib, IBUFDISABLE => udis, OSC => uosc, OSC_EN => uen);

  u_p_h : entity unisim.OBUFDS_DPHY
    port map (
      O => po_h, OB => pb_h,
      HSTX_I => hs, HSTX_T => hst,
      LPTX_I_N => lpn, LPTX_I_P => lpp, LPTX_T => lpt
    );
  u_p_v : OBUFDS_DPHY
    port map (
      O => po_v, OB => pb_v,
      HSTX_I => hs, HSTX_T => hst,
      LPTX_I_N => lpn, LPTX_I_P => lpp, LPTX_T => lpt
    );

  stimulus : process
    variable checks : natural := 0;

    function from_vlog(v : std_ulogic) return std_ulogic is
    begin
      if v = 'U' then
        return 'X';
      end if;
      return v;
    end function;

    procedure check1(h, v : std_ulogic; what : string) is
    begin
      checks := checks + 1;
      if h /= from_vlog(v) then
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(v)
          & " at " & time'image(now) severity failure;
      end if;
    end procedure;

    procedure expect1(got, exp : std_ulogic; what : string) is
    begin
      if got /= exp then
        report what & " expected " & to_string(exp) & " got " & to_string(got)
          & " at " & time'image(now) severity failure;
      end if;
    end procedure;

    procedure settle is
    begin
      wait for 5 ns;
    end procedure;
  begin
    vref <= '1';
    i <= '1';
    dis <= '1';
    settle;
    check1(o_h, o_v, "e3 i");
    expect1(o_h, '1', "e3 follows i");
    i <= 'Z';
    settle;
    check1(o_h, o_v, "e3 z");
    expect1(o_h, 'Z', "e3 z passes");
    i <= '0';
    en <= '1';
    osc <= "0001";
    settle;
    check1(o_h, o_v, "e3 osc low");
    expect1(o_h, '1', "e3 negative code is 1");
    osc <= "1001";
    settle;
    check1(o_h, o_v, "e3 osc high");
    expect1(o_h, '0', "e3 positive code is 0");
    osc <= "0000";
    settle;
    check1(o_h, o_v, "e3 toggle");
    expect1(o_h, '1', "e3 zero difference toggles");
    en <= '0';
    i <= '0';
    settle;
    check1(o_h, o_v, "e3 release");
    expect1(o_h, '0', "e3 back to i");

    iu <= '1';
    disu <= '0';
    enu <= '0';
    settle;
    check1(ou_h, ou_v, "e3 use");
    expect1(ou_h, '1', "e3 use follows");
    disu <= '1';
    settle;
    check1(ou_h, ou_v, "e3 dis");
    expect1(ou_h, '0', "e3 disable");
    enu <= '1';
    oscu <= "0001";
    settle;
    check1(ou_h, ou_v, "e3 dis en");
    expect1(ou_h, 'X', "e3 disable with en is x");
    disu <= '0';
    settle;
    check1(ou_h, ou_v, "e3 en");
    expect1(ou_h, '1', "e3 osc while enabled");
    enu <= 'Z';
    disu <= '1';
    settle;
    check1(ou_h, ou_v, "e3 en z");
    expect1(ou_h, 'X', "e3 en z is x");

    iv <= '0';
    env <= '1';
    oscv <= "0001";
    settle;
    check1(ov_h, ov_v, "e3 versal");
    expect1(ov_h, '0', "e3 versal ignores osc");

    di <= '1';
    dib <= '0';
    den <= "00";
    settle;
    check1(d_h, d_v, "dse 1");
    expect1(d_h, '1', "dse diff 1");
    di <= '0';
    dib <= '1';
    settle;
    check1(d_h, d_v, "dse 0");
    expect1(d_h, '0', "dse diff 0");
    di <= 'Z';
    dib <= 'Z';
    settle;
    check1(d_h, d_v, "dse z");
    expect1(d_h, 'X', "dse z is x");
    bi <= 'Z';
    bib <= 'Z';
    settle;
    check1(b_h, b_v, "dse bias");
    expect1(b_h, '0', "dse bias is 0");
    den <= "01";
    di <= '1';
    dib <= '0';
    settle;
    check1(d_h, d_v, "dse 01");
    expect1(d_h, 'X', "dse 01 is x");
    den <= "11";
    dosc <= "0001";
    settle;
    check1(d_h, d_v, "dse osc");
    expect1(d_h, '1', "dse osc on 11");
    den <= "10";
    settle;
    check1(d_h, d_v, "dse 10");
    expect1(d_h, 'X', "dse 10 is x");
    den <= "00";
    settle;
    check1(d_h, d_v, "dse back");
    expect1(d_h, '1', "dse receiver returns");

    ui <= '1';
    uib <= '0';
    udis <= '1';
    uen <= "00";
    settle;
    check1(u_h, u_v, "dse dis");
    expect1(u_h, '0', "dse disable");
    udis <= 'X';
    settle;
    check1(u_h, u_v, "dse dis x");
    expect1(u_h, 'X', "dse disable x");
    udis <= '0';
    settle;
    check1(u_h, u_v, "dse dis off");
    expect1(u_h, '1', "dse disable released");

    lpt <= '0';
    lpp <= '1';
    lpn <= '0';
    hs <= '0';
    hst <= '0';
    settle;
    check1(po_h, po_v, "dphy lp o");
    check1(pb_h, pb_v, "dphy lp ob");
    expect1(po_h, '1', "dphy lp p");
    expect1(pb_h, '0', "dphy lp n");
    lpp <= 'Z';
    settle;
    check1(po_h, po_v, "dphy lp z");
    expect1(po_h, 'Z', "dphy z passes");
    lpt <= '1';
    hst <= '0';
    hs <= '1';
    settle;
    check1(po_h, po_v, "dphy hs o");
    check1(pb_h, pb_v, "dphy hs ob");
    expect1(po_h, '1', "dphy hs");
    expect1(pb_h, '0', "dphy hs inv");
    hs <= 'Z';
    settle;
    check1(po_h, po_v, "dphy hs z");
    expect1(po_h, 'Z', "dphy hs z passes");
    expect1(pb_h, 'X', "dphy hs inv of z");
    hst <= '1';
    settle;
    check1(po_h, po_v, "dphy off o");
    check1(pb_h, pb_v, "dphy off ob");
    expect1(po_h, 'Z', "dphy both off");
    expect1(pb_h, 'Z', "dphy ob off");
    lpt <= 'X';
    hst <= '0';
    settle;
    check1(po_h, po_v, "dphy x");
    expect1(po_h, 'Z', "dphy x is z");

    report "tb_eq_e3 checks " & integer'image(checks) severity note;
    finish;
  end process;
end architecture sim;
