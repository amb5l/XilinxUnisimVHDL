-- IOBUF_INTERMDISABLE. Same pad driver and O mux as IOBUF_DCIEN.
-- INTERMDISABLE is a port only; the functional assign does not read it.
-- See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IOBUF_INTERMDISABLE is
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
    I : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    INTERMDISABLE : in std_ulogic;
    T : in std_ulogic
  );
end entity IOBUF_INTERMDISABLE;

architecture sim of IOBUF_INTERMDISABLE is
  signal gts : std_ulogic := '1';
begin
  check : process
  begin
    assert sim_device_ok(SIM_DEVICE)
      report "IOBUF_INTERMDISABLE SIM_DEVICE is not legal" severity failure;
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
