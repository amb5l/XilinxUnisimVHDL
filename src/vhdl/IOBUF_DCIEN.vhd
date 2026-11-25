-- IOBUF_DCIEN. Same pad driver as IOBUF. DCITERMDISABLE is not read
-- by the functional assign. USE_IBUFDISABLE true:
--   O = (~T || IBUFDISABLE) == 1 ? out_val : == 0 ? IO : X
-- out_val is 1 for 7SERIES and 0 otherwise. USE false: O is the
-- resolved pad, and Z passes. See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IOBUF_DCIEN is
  generic (
    DRIVE : integer := 12;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SIM_DEVICE : string := "7SERIES";
    SLEW : string := "SLOW";
    USE_IBUFDISABLE : boolean := TRUE
  );
  port (
    O : out std_ulogic;
    IO : inout std_logic;
    DCITERMDISABLE : in std_ulogic;
    I : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    T : in std_ulogic
  );
end entity IOBUF_DCIEN;

architecture sim of IOBUF_DCIEN is
  signal gts : std_ulogic := '1';
begin
  check : process
  begin
    assert sim_device_ok(SIM_DEVICE)
      report "IOBUF_DCIEN SIM_DEVICE is not legal" severity failure;
    wait;
  end process;

  toc_p : process
  begin
    toc(gts);
  end process;

  IO <= bufif0_val(I, gts or T);
  O <= IO when not USE_IBUFDISABLE else
       mux01(inv1(T) or IBUFDISABLE, disabled_val(SIM_DEVICE), IO);
end architecture sim;
