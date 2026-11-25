-- IBUF_INTERMDISABLE. Same output equation as IBUF_IBUFDISABLE.
-- INTERMDISABLE is present and unused in the functional model.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUF_INTERMDISABLE is
  generic (
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SIM_DEVICE : string := "7SERIES";
    USE_IBUFDISABLE : boolean := TRUE
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    INTERMDISABLE : in std_ulogic
  );
end entity IBUF_INTERMDISABLE;

architecture sim of IBUF_INTERMDISABLE is
begin
  check : process
  begin
    assert sim_device_ok(SIM_DEVICE)
      report "IBUF_INTERMDISABLE SIM_DEVICE is not a legal value" severity failure;
    wait;
  end process;

  O <= I when not USE_IBUFDISABLE else
       I when IBUFDISABLE = '0' else
       disabled_val(SIM_DEVICE) when IBUFDISABLE = '1' else
       'X';
end architecture sim;
