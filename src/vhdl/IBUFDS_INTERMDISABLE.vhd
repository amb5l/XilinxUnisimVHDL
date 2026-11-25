-- IBUFDS_INTERMDISABLE. Same equation as IBUFDS_IBUFDISABLE.
-- INTERMDISABLE is unused in the functional model.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUFDS_INTERMDISABLE is
  generic (
    DIFF_TERM : boolean := FALSE;
    DQS_BIAS : boolean := FALSE;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SIM_DEVICE : string := "7SERIES";
    USE_IBUFDISABLE : boolean := TRUE
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic;
    IB : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    INTERMDISABLE : in std_ulogic
  );
end entity IBUFDS_INTERMDISABLE;

architecture sim of IBUFDS_INTERMDISABLE is
  signal q : std_ulogic := 'X';
begin
  check : process
  begin
    assert sim_device_ok(SIM_DEVICE)
      report "IBUFDS_INTERMDISABLE SIM_DEVICE is not a legal value" severity failure;
    wait;
  end process;

  step : process (I, IB)
  begin
    diff_recv(q, I, IB, DQS_BIAS, true);
  end process;

  O <= q when not USE_IBUFDISABLE else
       disabled_val(SIM_DEVICE) when IBUFDISABLE = '1' else
       q when IBUFDISABLE = '0' else
       'X';
end architecture sim;
