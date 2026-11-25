-- IDDR_2CLK. Same pipeline as IDDR, but Q2 samples D on the rising
-- edge of CB instead of the falling edge of C. CB uses rv 1, so Z is a
-- 1 and the invert does not apply to Z. CE, R, and S pass through buf,
-- so Z is X. An unknown DDR_CLK_EDGE holds Q. No pulldown on R or S.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IDDR_2CLK is
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
    Q1 : out std_ulogic;
    Q2 : out std_ulogic;
    C : in std_ulogic;
    CB : in std_ulogic;
    CE : in std_ulogic;
    D : in std_ulogic;
    R : in std_ulogic;
    S : in std_ulogic
  );
end entity IDDR_2CLK;

architecture sim of IDDR_2CLK is
  signal gsr : std_ulogic := '1';
  signal c_in : std_ulogic;
  signal cb_in : std_ulogic;
  signal ce_in : std_ulogic;
  signal r_in : std_ulogic;
  signal s_in : std_ulogic;
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  c_in <= vxor(C, IS_C_INVERTED);
  cb_in <= rv1x(CB, IS_CB_INVERTED);
  ce_in <= buf1(CE);
  r_in <= buf1(R);
  s_in <= buf1(S);

  ddr : process (gsr, c_in, cb_in, r_in, s_in)
    variable armed : boolean := false;
    variable prev_c : std_ulogic := 'U';
    variable prev_cb : std_ulogic := 'U';
    variable forced : boolean := true;
    variable q1i, q1p, q2s, q2i : std_ulogic := 'X';
    variable q1o : std_ulogic := to_sul(INIT_Q1);
    variable q2o : std_ulogic := to_sul(INIT_Q2);
    variable rise_c, rise_cb : boolean;
  begin
    if gsr = '1' then
      forced := true;
      q1i := to_sul(INIT_Q1);
      q1p := to_sul(INIT_Q1);
      q2s := to_sul(INIT_Q2);
      q2i := to_sul(INIT_Q2);
    elsif gsr = '0' then
      if r_in = '1' and SRTYPE = "ASYNC" then
        forced := true;
        q1i := '0';
        q1p := '0';
        q2s := '0';
        q2i := '0';
      elsif r_in = '0' and s_in = '1' and SRTYPE = "ASYNC" then
        forced := true;
        q1i := '1';
        q1p := '1';
        q2s := '1';
        q2i := '1';
      elsif (r_in = '1' or s_in = '1') and SRTYPE = "SYNC" then
        forced := false;
      elsif r_in = '0' and s_in = '0' then
        forced := false;
      end if;
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
      if r_in = '1' then
        q1i := '0';
        q1p := '0';
        q2s := '0';
      elsif r_in = '0' and s_in = '1' then
        q1i := '1';
        q1p := '1';
        q2s := '1';
      elsif ce_in = '1' and r_in = '0' and s_in = '0' then
        q1p := q1i;
        q2s := q2i;
        q1i := vxor(D, IS_D_INVERTED);
      end if;
    end if;

    if rise_cb and not forced then
      if r_in = '1' then
        q2i := '0';
      elsif r_in = '0' and s_in = '1' then
        q2i := '1';
      elsif ce_in = '1' and r_in = '0' and s_in = '0' then
        q2i := vxor(D, IS_D_INVERTED);
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
