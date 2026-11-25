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
  function lut_eval(init : bit_vector; sel : std_ulogic_vector) return std_ulogic;
  function gate_in(clr : std_ulogic; inv : bit) return std_ulogic;
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
