-- IBUFDS_IBUFDISABLE_INT. Same receiver as IBUFDS_IBUFDISABLE.
-- A disable of 1 always drives 1. There is no SIM_DEVICE generic.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUFDS_IBUFDISABLE_INT is
  generic (
    DIFF_TERM : boolean := FALSE;
    DQS_BIAS : boolean := FALSE;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    USE_IBUFDISABLE : boolean := TRUE
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic;
    IB : in std_ulogic;
    IBUFDISABLE : in std_ulogic
  );
end entity IBUFDS_IBUFDISABLE_INT;

architecture sim of IBUFDS_IBUFDISABLE_INT is
  signal q : std_ulogic := 'X';
begin
  step : process (I, IB)
  begin
    diff_recv(q, I, IB, DQS_BIAS, true);
  end process;

  O <= q when not USE_IBUFDISABLE else
       '1' when IBUFDISABLE = '1' else
       q when IBUFDISABLE = '0' else
       'X';
end architecture sim;
