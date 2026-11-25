-- IBUFDS. Complementary inputs resolve to 0 or 1. A Z/0 with Z/1
-- pair follows DQS_BIAS (0, or X when bias is off). An X yields X.
-- Anything else holds the previous value. The receiver starts at X.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUFDS is
  generic (
    CAPACITANCE : string := "DONT_CARE";
    DIFF_TERM : boolean := FALSE;
    DQS_BIAS : boolean := FALSE;
    IBUF_DELAY_VALUE : string := "0";
    IBUF_LOW_PWR : boolean := TRUE;
    IFD_DELAY_VALUE : string := "AUTO";
    IOSTANDARD : string := "DEFAULT"
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic;
    IB : in std_ulogic
  );
end entity IBUFDS;

architecture sim of IBUFDS is
  signal q : std_ulogic := 'X';
begin
  check : process
  begin
    assert CAPACITANCE = "LOW" or CAPACITANCE = "NORMAL" or CAPACITANCE = "DONT_CARE"
      report "IBUFDS CAPACITANCE must be LOW, NORMAL, or DONT_CARE" severity failure;
    wait;
  end process;

  step : process (I, IB)
  begin
    diff_recv(q, I, IB, DQS_BIAS, true);
  end process;

  O <= q;
end architecture sim;
