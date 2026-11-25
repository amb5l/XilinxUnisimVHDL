-- IBUFDS_DIFF_OUT_IBUFDISABLE. Receiver yields X on an X input (===).
-- With the disable off, OB is the inversion of the resolved bit.
-- Disable 1 drives the SIM_DEVICE pair (7SERIES 1/1, ULTRASCALE 0/X, else 0/0).

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUFDS_DIFF_OUT_IBUFDISABLE is
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
    OB : out std_ulogic;
    I : in std_ulogic;
    IB : in std_ulogic;
    IBUFDISABLE : in std_ulogic
  );
end entity IBUFDS_DIFF_OUT_IBUFDISABLE;

architecture sim of IBUFDS_DIFF_OUT_IBUFDISABLE is
  signal q : std_ulogic := 'X';
begin
  check : process
  begin
    assert sim_device_ok(SIM_DEVICE)
      report "IBUFDS_DIFF_OUT_IBUFDISABLE SIM_DEVICE is not a legal value" severity failure;
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
  OB <= inv1(q) when not USE_IBUFDISABLE else
        disabled_b_val(SIM_DEVICE) when IBUFDISABLE = '1' else
        inv1(q) when IBUFDISABLE = '0' else
        'X';
end architecture sim;
