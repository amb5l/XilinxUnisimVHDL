-- IBUF_IBUFDISABLE. USE_IBUFDISABLE FALSE passes I through, including Z.
-- Otherwise IBUFDISABLE 0 passes I, 1 drives 1 on 7SERIES and 0 otherwise,
-- and X or Z drives X. INTERM is not part of this cell.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUF_IBUFDISABLE is
  generic (
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SIM_DEVICE : string := "7SERIES";
    USE_IBUFDISABLE : boolean := TRUE
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic;
    IBUFDISABLE : in std_ulogic
  );
end entity IBUF_IBUFDISABLE;

architecture sim of IBUF_IBUFDISABLE is
begin
  check : process
  begin
    assert sim_device_ok(SIM_DEVICE)
      report "IBUF_IBUFDISABLE SIM_DEVICE is not a legal value" severity failure;
    wait;
  end process;

  O <= I when not USE_IBUFDISABLE else
       I when IBUFDISABLE = '0' else
       disabled_val(SIM_DEVICE) when IBUFDISABLE = '1' else
       'X';
end architecture sim;
