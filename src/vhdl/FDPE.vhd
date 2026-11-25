-- FDPE. Async preset to 1. GSR forces INIT (default 1). PRE_in === 1
-- forces 1 and PRE_in === X forces X. Q is delayed 100 ps.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity FDPE is
  generic (
    INIT : bit := '1';
    IS_C_INVERTED : bit := '0';
    IS_D_INVERTED : bit := '0';
    IS_PRE_INVERTED : bit := '0'
  );
  port (
    Q : out std_ulogic;
    C : in std_ulogic;
    CE : in std_ulogic;
    D : in std_ulogic;
    PRE : in std_ulogic
  );
end entity FDPE;

architecture sim of FDPE is
  signal gsr : std_ulogic := '1';
  signal q_out : std_ulogic := 'X';
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  ff : process (gsr, C, PRE)
    variable prev : std_ulogic := 'X';
    variable edge : boolean;
    variable pre_l : std_ulogic;
  begin
    pre_l := gate_in(PRE, IS_PRE_INVERTED);
    if gsr = '1' then
      q_out <= to_sul(INIT);
    elsif pre_l = '1' then
      q_out <= '1';
    elsif pre_l = 'X' then
      q_out <= 'X';
    else
      if IS_C_INVERTED = '0' then
        edge := verilog_posedge(prev, C);
      else
        edge := verilog_negedge(prev, C);
      end if;
      if edge then
        q_out <= sync_ff(q_out, D, CE, '0', IS_D_INVERTED, '0', '1');
      end if;
    end if;
    prev := C;
  end process;

  Q <= q_out after 100 ps;
end architecture sim;
