-- LDCE. Transparent latch with gate enable and async clear.
-- The Verilog model is the latchsre_ldce UDP. GSR forces INIT for the
-- default 100 ns ROC by driving the UDP set or reset. GE of Z enables
-- (rv 1). CLR of Z is not a clear (rv 0). Q has no functional delay;
-- the specify path is not applied by this NVC when XIL_TIMING is off.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity LDCE is
  generic (
    INIT : bit := '0';
    IS_CLR_INVERTED : bit := '0';
    IS_G_INVERTED : bit := '0'
  );
  port (
    Q : out std_ulogic;
    CLR : in std_ulogic;
    D : in std_ulogic;
    G : in std_ulogic;
    GE : in std_ulogic
  );
end entity LDCE;

architecture sim of LDCE is
  signal gsr : std_ulogic := '1';
  signal q_out : std_ulogic := 'X';
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  latch : process (gsr, CLR, D, G, GE)
    variable set_i, rst_i : std_ulogic;
  begin
    if gsr = '1' then
      if INIT = '1' then
        set_i := '1';
        rst_i := '0';
      else
        set_i := '0';
        rst_i := '1';
      end if;
    else
      set_i := '0';
      rst_i := gate_in(CLR, IS_CLR_INVERTED);
    end if;
    q_out <= latch_sre(q_out, vxor(G, IS_G_INVERTED), D, set_i, rst_i, rv1(GE));
  end process;

  Q <= q_out;
end architecture sim;
