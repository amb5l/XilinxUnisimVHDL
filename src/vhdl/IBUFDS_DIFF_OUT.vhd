-- IBUFDS_DIFF_OUT. Same receiver as IBUFDS, except an X does not match
-- the Verilog == test, so the output holds. OB is the inversion of the
-- resolved bit (buf then not).

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUFDS_DIFF_OUT is
  generic (
    DIFF_TERM : boolean := FALSE;
    DQS_BIAS : boolean := FALSE;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT"
  );
  port (
    O : out std_ulogic;
    OB : out std_ulogic;
    I : in std_ulogic;
    IB : in std_ulogic
  );
end entity IBUFDS_DIFF_OUT;

architecture sim of IBUFDS_DIFF_OUT is
  signal q : std_ulogic := 'X';
begin
  step : process (I, IB)
  begin
    diff_recv(q, I, IB, DQS_BIAS, false);
  end process;

  O <= q;
  OB <= inv1(q);
end architecture sim;
