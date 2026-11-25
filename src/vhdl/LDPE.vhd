-- LDPE. Transparent latch with gate enable and async preset.
-- Same UDP table as LDCE. GSR forces INIT. PRE of Z is not a preset.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity LDPE is
  generic (
    INIT : bit := '1';
    IS_G_INVERTED : bit := '0';
    IS_PRE_INVERTED : bit := '0'
  );
  port (
    Q : out std_ulogic;
    D : in std_ulogic;
    G : in std_ulogic;
    GE : in std_ulogic;
    PRE : in std_ulogic
  );
end entity LDPE;

architecture sim of LDPE is
  signal gsr : std_ulogic := '1';
  signal q_out : std_ulogic := 'X';
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  latch : process (gsr, D, G, GE, PRE)
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
      set_i := gate_in(PRE, IS_PRE_INVERTED);
      rst_i := '0';
    end if;
    q_out <= latch_sre(q_out, vxor(G, IS_G_INVERTED), D, set_i, rst_i, rv1(GE));
  end process;

  Q <= q_out;
end architecture sim;
