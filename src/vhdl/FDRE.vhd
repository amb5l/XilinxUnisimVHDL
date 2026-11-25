-- FDRE. Sync reset to 0, clock enable, INIT, IS_*_INVERTED.
-- Q follows Q_out after 100 ps, matching `assign #100 Q = Q_out`
-- (timescale 1 ps). GSR forces INIT for the default 100 ns ROC.
-- XIL_TIMING is off, so there is no specify delay beyond that #100.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity FDRE is
  generic (
    INIT : bit := '0';
    IS_C_INVERTED : bit := '0';
    IS_D_INVERTED : bit := '0';
    IS_R_INVERTED : bit := '0'
  );
  port (
    Q : out std_ulogic;
    C : in std_ulogic;
    CE : in std_ulogic;
    D : in std_ulogic;
    R : in std_ulogic
  );
end entity FDRE;

architecture sim of FDRE is
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
        q_out <= sync_ff(q_out, D, CE, R, IS_D_INVERTED, IS_R_INVERTED, '0');
      end if;
    end if;
    prev := C;
  end process;

  Q <= q_out after 100 ps;
end architecture sim;
