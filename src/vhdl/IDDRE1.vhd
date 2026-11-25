-- IDDRE1. IDDR without CE or S. R = 1 is always an async clear to 0
-- (there is no SRTYPE and no INIT). Q2 samples D on the rising edge of
-- CB. CB uses rv 1. An unknown DDR_CLK_EDGE holds Q.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IDDRE1 is
  generic (
    DDR_CLK_EDGE : string := "OPPOSITE_EDGE";
    IS_CB_INVERTED : bit := '0';
    IS_C_INVERTED : bit := '0'
  );
  port (
    Q1 : out std_ulogic;
    Q2 : out std_ulogic;
    C : in std_ulogic;
    CB : in std_ulogic;
    D : in std_ulogic;
    R : in std_ulogic
  );
end entity IDDRE1;

architecture sim of IDDRE1 is
  signal gsr : std_ulogic := '1';
  signal c_in : std_ulogic;
  signal cb_in : std_ulogic;
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  c_in <= vxor(C, IS_C_INVERTED);
  cb_in <= rv1x(CB, IS_CB_INVERTED);

  ddr : process (gsr, c_in, cb_in, R)
    variable armed : boolean := false;
    variable prev_c : std_ulogic := 'U';
    variable prev_cb : std_ulogic := 'U';
    variable forced : boolean := true;
    variable q1i, q1p, q2s, q2i : std_ulogic := 'X';
    variable q1o : std_ulogic := 'X';
    variable q2o : std_ulogic := 'X';
    variable rise_c, rise_cb : boolean;
  begin
    if gsr = '1' or R = '1' then
      forced := true;
      q1i := '0';
      q1p := '0';
      q2s := '0';
      q2i := '0';
    elsif gsr = '0' and R = '0' then
      forced := false;
    end if;

    rise_c := false;
    rise_cb := false;
    if armed then
      rise_c := verilog_posedge(prev_c, c_in);
      rise_cb := verilog_posedge(prev_cb, cb_in);
    end if;
    armed := true;
    prev_c := c_in;
    prev_cb := cb_in;

    if rise_c and not forced then
      if R = '1' then
        q1i := '0';
        q1p := '0';
        q2s := '0';
      elsif R = '0' then
        q1p := q1i;
        q2s := q2i;
        q1i := D;
      end if;
    end if;

    if rise_cb and not forced then
      if R = '1' then
        q2i := '0';
      elsif R = '0' then
        q2i := D;
      end if;
    end if;

    if DDR_CLK_EDGE = "OPPOSITE_EDGE" then
      q1o := q1i;
      q2o := q2i;
    elsif DDR_CLK_EDGE = "SAME_EDGE" then
      q1o := q1i;
      q2o := q2s;
    elsif DDR_CLK_EDGE = "SAME_EDGE_PIPELINED" then
      q1o := q1p;
      q2o := q2s;
    end if;
    Q1 <= q1o;
    Q2 <= q2o;
  end process;
end architecture sim;
