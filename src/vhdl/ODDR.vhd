-- ODDR. The rising edge of C drives Q from D1 and remembers D2.
-- OPPOSITE_EDGE drives Q from D2 on the falling edge. SAME_EDGE drives
-- Q from that remembered D2. With CE = 0 the rising edge remembers the
-- current Q instead of D2. GSR forces INIT. ASYNC R = 1 forces 0 and
-- ASYNC S = 1 forces 1. R and S have pulldowns, so Z is 0. An unknown
-- DDR_CLK_EDGE does not update Q on the falling edge.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity ODDR is
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
    C : in std_ulogic;
    CE : in std_ulogic;
    D1 : in std_ulogic;
    D2 : in std_ulogic;
    R : in std_ulogic;
    S : in std_ulogic
  );
end entity ODDR;

architecture sim of ODDR is
  signal gsr : std_ulogic := '1';
  signal c_in : std_ulogic;
  signal r_in : std_ulogic;
  signal s_in : std_ulogic;
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  c_in <= vxor(C, IS_C_INVERTED);
  r_in <= '0' when R = 'Z' else R;
  s_in <= '0' when S = 'Z' else S;

  ddr : process (gsr, c_in, r_in, s_in)
    variable armed : boolean := false;
    variable prev : std_ulogic := 'U';
    variable forced : boolean := true;
    variable q_val : std_ulogic := to_sul(INIT);
    variable qd2 : std_ulogic := to_sul(INIT);
    variable rise, fall : boolean;
  begin
    if gsr = '1' then
      forced := true;
      q_val := to_sul(INIT);
      qd2 := to_sul(INIT);
    elsif gsr = '0' then
      if r_in = '1' and SRTYPE = "ASYNC" then
        forced := true;
        q_val := '0';
        qd2 := '0';
      elsif r_in = '0' and s_in = '1' and SRTYPE = "ASYNC" then
        forced := true;
        q_val := '1';
        qd2 := '1';
      elsif (r_in = '1' or s_in = '1') and SRTYPE = "SYNC" then
        forced := false;
      elsif r_in = '0' and s_in = '0' then
        forced := false;
      end if;
    end if;

    rise := false;
    fall := false;
    if armed then
      rise := verilog_posedge(prev, c_in);
      fall := verilog_negedge(prev, c_in);
    end if;
    armed := true;
    prev := c_in;

    if rise and not forced then
      if r_in = '1' then
        q_val := '0';
        qd2 := '0';
      elsif r_in = '0' and s_in = '1' then
        q_val := '1';
        qd2 := '1';
      elsif CE = '1' and r_in = '0' and s_in = '0' then
        q_val := vxor(D1, IS_D1_INVERTED);
        qd2 := vxor(D2, IS_D2_INVERTED);
      elsif CE = '0' and r_in = '0' and s_in = '0' then
        qd2 := q_val;
      end if;
    end if;

    if fall and not forced then
      if r_in = '1' then
        q_val := '0';
      elsif r_in = '0' and s_in = '1' then
        q_val := '1';
      elsif CE = '1' and r_in = '0' and s_in = '0' then
        if DDR_CLK_EDGE = "SAME_EDGE" then
          q_val := qd2;
        elsif DDR_CLK_EDGE = "OPPOSITE_EDGE" then
          q_val := vxor(D2, IS_D2_INVERTED);
        end if;
      end if;
    end if;

    Q <= q_val;
  end process;
end architecture sim;
