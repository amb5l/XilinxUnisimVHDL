-- FDCE. Async clear. GSR forces INIT; else CLR_in === 1 forces 0 and
-- CLR_in === X forces X (procedural continuous assign). The clocked
-- path runs only when the clear is not forcing. Q is delayed 100 ps.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity FDCE is
  generic (
    INIT : bit := '0';
    IS_CLR_INVERTED : bit := '0';
    IS_C_INVERTED : bit := '0';
    IS_D_INVERTED : bit := '0'
  );
  port (
    Q : out std_ulogic;
    C : in std_ulogic;
    CE : in std_ulogic;
    CLR : in std_ulogic;
    D : in std_ulogic
  );
end entity FDCE;

architecture sim of FDCE is
  signal gsr : std_ulogic := '1';
  signal q_out : std_ulogic := 'X';
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  ff : process (gsr, C, CLR)
    variable prev : std_ulogic := 'X';
    variable edge : boolean;
    variable clr_l : std_ulogic;
  begin
    clr_l := gate_in(CLR, IS_CLR_INVERTED);
    if gsr = '1' then
      q_out <= to_sul(INIT);
    elsif clr_l = '1' then
      q_out <= '0';
    elsif clr_l = 'X' then
      q_out <= 'X';
    else
      if IS_C_INVERTED = '0' then
        edge := verilog_posedge(prev, C);
      else
        edge := verilog_negedge(prev, C);
      end if;
      if edge then
        q_out <= sync_ff(q_out, D, CE, '0', IS_D_INVERTED, '0', '0');
      end if;
    end if;
    prev := C;
  end process;

  Q <= q_out after 100 ps;
end architecture sim;
