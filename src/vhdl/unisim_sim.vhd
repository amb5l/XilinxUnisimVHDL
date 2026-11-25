-- Helpers for the hand-written unisim models.
-- Behaviour is derived from the Apache-2.0 Verilog in XilinxUnisimLibrary.
-- See docs/vhdl-models.md. This file is not a primitive.

library ieee;
use ieee.std_logic_1164.all;

package unisim_sim is
  -- NVC cannot read a Verilog signal through a VHDL external name
  -- (missing class_of for T_VERILOG). Models that use glbl.GSR / glbl.GTS
  -- reproduce the default ROC/TOC on a local signal:
  --   GSR is '1' for 100 ns, then '0'  (glbl ROC_WIDTH = 100000 ps)
  --   GTS is '1', then '0' after 0 ns  (glbl TOC_WIDTH = 0)
  procedure roc(signal gsr : out std_ulogic);
  procedure toc(signal gts : out std_ulogic);

  function to_sul(b : bit) return std_ulogic;
  function buf1(i : std_ulogic) return std_ulogic;
  function inv1(i : std_ulogic) return std_ulogic;
  function xor_inv(d : std_ulogic; inv : bit) return std_ulogic;
  function verilog_posedge(prev, curr : std_ulogic) return boolean;
  function verilog_negedge(prev, curr : std_ulogic) return boolean;
  function rv0(s : std_ulogic) return std_ulogic;
  function bufif0_val(d, en : std_ulogic) return std_ulogic;
  function notif0_val(d, en : std_ulogic) return std_ulogic;
  function sim_device_ok(s : string) return boolean;
  function disabled_val(sim_device : string) return std_ulogic;
  function disabled_b_val(sim_device : string) return std_ulogic;
  -- en = 0 drives data (Z passes). en = 1 drives Z.
  -- en X/Z is the Verilog ternary: both sides Z yields Z, otherwise X.
  function tri_en(data, en : std_ulogic) return std_ulogic;
  -- en ? when1 : when0, including the X/Z merge.
  function tri_mux(en, when1, when0 : std_ulogic) return std_ulogic;
  -- sel == 1 ? when1 : sel == 0 ? when0 : X. Same for === on 0/1/X/Z.
  function mux01(sel, when1, when0 : std_ulogic) return std_ulogic;
  -- Next differential-receiver value. x_i / x_ib select a === X test on
  -- that pin. else_x drives X when no row matches; otherwise the previous
  -- value is held. IOBUFDS tests === only on IO (x_ib false).
  function diff_next(
    prev, i, ib : std_ulogic;
    dqs_bias : boolean;
    x_i, x_ib, else_x : boolean
  ) return std_ulogic;
  procedure diff_recv(
    signal q : inout std_ulogic;
    i, ib : in std_ulogic;
    dqs_bias : in boolean;
    x_exact : in boolean
  );
  function e3_sim_ok(s : string) return boolean;
  -- True for ULTRASCALE and ULTRASCALE_PLUS, where IOBUF*E3 uses OSC.
  function e3_ultra(s : string) return boolean;
  function osc_init(offset : integer) return std_ulogic;
  function osc_step(
    prev : std_ulogic;
    osc : std_logic_vector(3 downto 0);
    update : boolean;
    offset : integer
  ) return std_ulogic;
  function lut_eval(init : bit_vector; sel : std_ulogic_vector) return std_ulogic;
  function gate_in(clr : std_ulogic; inv : bit) return std_ulogic;
  function rv1(s : std_ulogic) return std_ulogic;
  function vxor(d : std_ulogic; inv : bit) return std_ulogic;
  function latch_sre(
    q, clk, d, set, rst, ge : std_ulogic
  ) return std_ulogic;
  function sync_ff(
    q : std_ulogic;
    d, ce, rst : std_ulogic;
    inv_d, inv_rst : bit;
    set_value : std_ulogic
  ) return std_ulogic;
end package unisim_sim;

package body unisim_sim is
  procedure roc(signal gsr : out std_ulogic) is
  begin
    gsr <= '1';
    wait for 100 ns;
    gsr <= '0';
    wait;
  end procedure;

  procedure toc(signal gts : out std_ulogic) is
  begin
    gts <= '1';
    gts <= '0' after 0 ns;
    wait;
  end procedure;

  function to_sul(b : bit) return std_ulogic is
  begin
    if b = '1' then
      return '1';
    end if;
    return '0';
  end function;

  function buf1(i : std_ulogic) return std_ulogic is
  begin
    if i = '0' or i = '1' then
      return i;
    else
      return 'X';
    end if;
  end function;

  function inv1(i : std_ulogic) return std_ulogic is
  begin
    if i = '0' then
      return '1';
    elsif i = '1' then
      return '0';
    else
      return 'X';
    end if;
  end function;

  function xor_inv(d : std_ulogic; inv : bit) return std_ulogic is
  begin
    if inv = '0' then
      return d;
    end if;
    return inv1(d);
  end function;

  function verilog_posedge(prev, curr : std_ulogic) return boolean is
  begin
    return (prev = '0' and (curr = '1' or curr = 'X' or curr = 'Z'))
        or ((prev = 'X' or prev = 'Z') and curr = '1');
  end function;

  function verilog_negedge(prev, curr : std_ulogic) return boolean is
  begin
    return (prev = '1' and (curr = '0' or curr = 'X' or curr = 'Z'))
        or ((prev = 'X' or prev = 'Z') and curr = '0');
  end function;

  -- (s !== 'Z') && s, the "rv 0" reduction in CARRY4.
  function rv0(s : std_ulogic) return std_ulogic is
  begin
    if s = 'Z' or s = '0' then
      return '0';
    elsif s = '1' then
      return '1';
    else
      return 'X';
    end if;
  end function;

  -- bufif0 as NVC simulates it. Enable 0 drives 0, 1, or Z, and X data
  -- becomes X. Any other enable (1, X, Z) drives Z. IEEE 1364 instead
  -- maps enabled Z data to X and an X enable to a strength (L/H).
  -- See docs/vhdl-models.md.
  function bufif0_val(d, en : std_ulogic) return std_ulogic is
  begin
    if en = '0' then
      if d = '0' or d = '1' or d = 'Z' then
        return d;
      end if;
      return 'X';
    end if;
    return 'Z';
  end function;

  -- notif0 as NVC simulates it. Enable 0 inverts (Z and X become X).
  -- Any other enable drives Z.
  function notif0_val(d, en : std_ulogic) return std_ulogic is
  begin
    if en = '0' then
      return inv1(d);
    end if;
    return 'Z';
  end function;

  function sim_device_ok(s : string) return boolean is
  begin
    return s = "7SERIES" or s = "ULTRASCALE"
      or s = "VERSAL_AI_CORE" or s = "VERSAL_AI_CORE_ES1" or s = "VERSAL_AI_CORE_ES2"
      or s = "VERSAL_AI_EDGE" or s = "VERSAL_AI_EDGE_ES1" or s = "VERSAL_AI_EDGE_ES2"
      or s = "VERSAL_AI_RF" or s = "VERSAL_AI_RF_ES1" or s = "VERSAL_AI_RF_ES2"
      or s = "VERSAL_HBM" or s = "VERSAL_HBM_ES1" or s = "VERSAL_HBM_ES2"
      or s = "VERSAL_PREMIUM" or s = "VERSAL_PREMIUM_ES1" or s = "VERSAL_PREMIUM_ES2"
      or s = "VERSAL_PRIME" or s = "VERSAL_PRIME_ES1" or s = "VERSAL_PRIME_ES2";
  end function;

  -- Value forced onto O when IBUFDISABLE is 1. 7SERIES is 1, anything else is 0.
  function disabled_val(sim_device : string) return std_ulogic is
  begin
    if sim_device = "7SERIES" then
      return '1';
    end if;
    return '0';
  end function;

  -- Companion value forced onto OB. 7SERIES is 1, ULTRASCALE is X, else 0.
  function disabled_b_val(sim_device : string) return std_ulogic is
  begin
    if sim_device = "7SERIES" then
      return '1';
    elsif sim_device = "ULTRASCALE" then
      return 'X';
    end if;
    return '0';
  end function;

  function tri_en(data, en : std_ulogic) return std_ulogic is
  begin
    if en = '0' then
      return data;
    elsif en = '1' then
      return 'Z';
    elsif data = 'Z' then
      return 'Z';
    else
      return 'X';
    end if;
  end function;

  function tri_mux(en, when1, when0 : std_ulogic) return std_ulogic is
  begin
    if en = '1' then
      return when1;
    elsif en = '0' then
      return when0;
    elsif when1 = when0 then
      return when1;
    else
      return 'X';
    end if;
  end function;

  function mux01(sel, when1, when0 : std_ulogic) return std_ulogic is
  begin
    if sel = '1' then
      return when1;
    elsif sel = '0' then
      return when0;
    else
      return 'X';
    end if;
  end function;

  function diff_next(
    prev, i, ib : std_ulogic;
    dqs_bias : boolean;
    x_i, x_ib, else_x : boolean
  ) return std_ulogic is
  begin
    if i = '1' and ib = '0' then
      return '1';
    elsif i = '0' and ib = '1' then
      return '0';
    elsif (i = 'Z' or i = '0') and (ib = 'Z' or ib = '1') then
      if dqs_bias then
        return '0';
      else
        return 'X';
      end if;
    elsif (x_i and i = 'X') or (x_ib and ib = 'X') then
      return 'X';
    elsif else_x then
      return 'X';
    else
      return prev;
    end if;
  end function;

  -- IBUFDS differential receiver. Complementary 0/1 resolves to that value.
  -- (I is Z or 0) and (IB is Z or 1) yields 0 when DQS_BIAS is set, else X.
  -- An X on either pin yields X when x_exact is true (the === test in
  -- IBUFDS). IBUFDS_DIFF_OUT uses ==, which does not match X, so the
  -- output holds. Any other combination holds the previous value.
  procedure diff_recv(
    signal q : inout std_ulogic;
    i, ib : in std_ulogic;
    dqs_bias : in boolean;
    x_exact : in boolean
  ) is
    variable n : std_ulogic;
  begin
    n := diff_next(q, i, ib, dqs_bias, x_exact, x_exact, false);
    if n /= q then
      q <= n;
    end if;
  end procedure;

  function e3_sim_ok(s : string) return boolean is
  begin
    return s = "ULTRASCALE" or s = "ULTRASCALE_PLUS"
      or (sim_device_ok(s) and s /= "7SERIES");
  end function;

  function e3_ultra(s : string) return boolean is
  begin
    return s = "ULTRASCALE" or s = "ULTRASCALE_PLUS";
  end function;

  function osc_init(offset : integer) return std_ulogic is
  begin
    if offset < 0 then
      return '0';
    elsif offset > 0 then
      return '1';
    else
      return 'X';
    end if;
  end function;

  -- OSC[2:0] * 5, negated when OSC[3] is 0. A non-binary magnitude holds
  -- (return -1000). OSC[3] of X or Z does not negate: Verilog == 0 is not true.
  function osc_code(osc : std_logic_vector(3 downto 0)) return integer is
    variable mag : integer := 0;
  begin
    if (osc(0) /= '0' and osc(0) /= '1')
      or (osc(1) /= '0' and osc(1) /= '1')
      or (osc(2) /= '0' and osc(2) /= '1') then
      return -1000;
    end if;
    if osc(0) = '1' then
      mag := mag + 5;
    end if;
    if osc(1) = '1' then
      mag := mag + 10;
    end if;
    if osc(2) = '1' then
      mag := mag + 20;
    end if;
    if osc(3) = '0' then
      return -mag;
    end if;
    return mag;
  end function;

  function osc_step(
    prev : std_ulogic;
    osc : std_logic_vector(3 downto 0);
    update : boolean;
    offset : integer
  ) return std_ulogic is
    variable code, diff : integer;
  begin
    if not update then
      return prev;
    end if;
    code := osc_code(osc);
    if code = -1000 then
      return prev;
    end if;
    diff := offset - code;
    if diff < 0 then
      return '0';
    elsif diff > 0 then
      return '1';
    else
      return inv1(prev);
    end if;
  end function;

  -- LUT UDP over a bit INIT. I0 is sel'low. A 'Z' (or other non 0/1/X)
  -- input yields 'X', because the Verilog UDP rows match 'x' and not 'z'.
  -- An 'X' input yields 0 or 1 only when every INIT bit it can address
  -- agrees; otherwise 'X'.
  function lut_eval(init : bit_vector; sel : std_ulogic_vector) return std_ulogic is
    constant n    : natural := sel'length;
    variable acc  : std_ulogic := 'U';
    variable bitv : std_ulogic;
    variable addr_bit : std_ulogic;
    variable match : boolean;
    variable span : natural;
  begin
    span := 2 ** n;
    if init'length /= span then
      return 'X';
    end if;
    for a in 0 to span - 1 loop
      match := true;
      for b in 0 to n - 1 loop
        addr_bit := sel(sel'low + b);
        if addr_bit /= '0' and addr_bit /= '1' and addr_bit /= 'X' then
          return 'X';
        end if;
        if addr_bit = '0' and (a / (2 ** b)) mod 2 /= 0 then
          match := false;
        elsif addr_bit = '1' and (a / (2 ** b)) mod 2 /= 1 then
          match := false;
        end if;
      end loop;
      if match then
        bitv := to_sul(init(init'low + a));
        if acc = 'U' then
          acc := bitv;
        elsif acc /= bitv then
          return 'X';
        end if;
      end if;
    end loop;
    if acc = 'U' then
      return 'X';
    end if;
    return acc;
  end function;

  -- (pin xor inv) && (pin !== 'Z'), used by the async clear/preset.
  function gate_in(clr : std_ulogic; inv : bit) return std_ulogic is
    variable x : std_ulogic;
  begin
    if clr = 'Z' then
      return '0';
    end if;
    x := xor_inv(clr, inv);
    if x = '0' or x = '1' then
      return x;
    end if;
    return 'X';
  end function;

  -- (s === 'Z') || s, the "rv 1" reduction. Z and 1 enable a latch.
  function rv1(s : std_ulogic) return std_ulogic is
  begin
    if s = 'Z' or s = '1' then
      return '1';
    elsif s = '0' then
      return '0';
    else
      return 'X';
    end if;
  end function;

  -- Verilog bitwise xor with a 1-bit parameter. X and Z become X.
  function vxor(d : std_ulogic; inv : bit) return std_ulogic is
  begin
    if d /= '0' and d /= '1' then
      return 'X';
    elsif inv = '1' then
      return inv1(d);
    else
      return d;
    end if;
  end function;

  -- latchsre_ldce / latchsre_ldpe UDP. A matching row that names an
  -- output drives that value. A '-' row holds. If nothing matches, the
  -- UDP output is X. The notifier pin is a constant X when XIL_TIMING
  -- is off, so its edge row never fires.
  function latch_sre(
    q, clk, d, set, rst, ge : std_ulogic
  ) return std_ulogic is
    variable val : std_ulogic := 'U';
    variable hold : boolean := false;
  begin
    if clk = '1' and d = '0' and set = '0' and rst = '0' and ge = '1' then
      val := '0';
    end if;
    if clk = '1' and d = '1' and set = '0' and rst = '0' and ge = '1' then
      val := '1';
    end if;
    if set = '1' and rst = '0' then
      val := '1';
    end if;
    if rst = '1' then
      val := '0';
    end if;
    if clk = '0' and set = '0' and rst = 'X' and q = '0' then
      val := '0';
    end if;
    if set = '0' and rst = 'X' and ge = '0' and q = '0' then
      val := '0';
    end if;
    if clk = '1' and d = '0' and set = '0' and rst = 'X' and ge = '1' then
      val := '0';
    end if;
    if clk = '0' and set = 'X' and rst = '0' and q = '1' then
      val := '1';
    end if;
    if set = 'X' and rst = '0' and ge = '0' and q = '1' then
      val := '1';
    end if;
    if clk = '1' and d = '1' and set = 'X' and rst = '0' and ge = '1' then
      val := '1';
    end if;

    if clk = '0' and set = '0' and rst = '0' then
      hold := true;
    end if;
    if set = '0' and rst = '0' and ge = '0' then
      hold := true;
    end if;
    if d = '0' and set = '0' and q = '0' then
      hold := true;
    end if;
    if d = '1' and rst = '0' and q = '1' then
      hold := true;
    end if;

    if val /= 'U' then
      return val;
    elsif hold then
      return q;
    else
      return 'X';
    end if;
  end function;

  -- FDRE/FDSE clocked update. set_value is '0' for a reset and '1' for a set.
  -- CE === 'Z' enables. CE === 'X' updates only when Q is already the new D.
  -- A 'Z' reset is not a reset. An 'X' reset forces set_value only when Q is
  -- already set_value.
  function sync_ff(
    q : std_ulogic;
    d, ce, rst : std_ulogic;
    inv_d, inv_rst : bit;
    set_value : std_ulogic
  ) return std_ulogic is
    variable d_next : std_ulogic;
    variable r_eff  : std_ulogic;
  begin
    d_next := xor_inv(d, inv_d);
    r_eff := xor_inv(rst, inv_rst);
    if (r_eff = '1' and rst /= 'Z') or (rst = 'X' and q = set_value) then
      return set_value;
    elsif ce = '1' or ce = 'Z' or (ce = 'X' and q = d_next) then
      return d_next;
    else
      return q;
    end if;
  end function;
end package body unisim_sim;
