-- FDSE. Sync set to 1. Same GSR, CE, and 100 ps Q delay as FDRE.
-- An X on S forces 1 only when Q is already 1, matching the Verilog.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity FDSE is
  generic (
    INIT : bit := '1';
    IS_C_INVERTED : bit := '0';
    IS_D_INVERTED : bit := '0';
    IS_S_INVERTED : bit := '0'
  );
  port (
    Q : out std_ulogic;
    C : in std_ulogic;
    CE : in std_ulogic;
    D : in std_ulogic;
    S : in std_ulogic
  );
end entity FDSE;

architecture sim of FDSE is
  signal gsr : std_ulogic := '1';
  signal q_out : std_ulogic := 'X';
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  ff : process (gsr, C)
    variable prev : std_ulogic := 'X';
    variable edge : boolean;
  begin
    if gsr = '1' then
      q_out <= to_sul(INIT);
    else
      if IS_C_INVERTED = '0' then
        edge := verilog_posedge(prev, C);
      else
        edge := verilog_negedge(prev, C);
      end if;
      if edge then
        q_out <= sync_ff(q_out, D, CE, S, IS_D_INVERTED, IS_S_INVERTED, '1');
      end if;
    end if;
    prev := C;
  end process;

  Q <= q_out after 100 ps;
end architecture sim;
