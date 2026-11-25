-- IOBUFDS_INTERMDISABLE. Same pad drivers, receiver, and O mux as
-- IOBUFDS_DCIEN. INTERMDISABLE is a port only. See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IOBUFDS_INTERMDISABLE is
  generic (
    DIFF_TERM : boolean := FALSE;
    DQS_BIAS : boolean := FALSE;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SIM_DEVICE : string := "7SERIES";
    SLEW : string := "SLOW";
    USE_IBUFDISABLE : boolean := TRUE
  );
  port (
    O : out std_ulogic;
    IO : inout std_logic;
    IOB : inout std_logic;
    I : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    INTERMDISABLE : in std_ulogic;
    T : in std_ulogic
  );
end entity IOBUFDS_INTERMDISABLE;

architecture sim of IOBUFDS_INTERMDISABLE is
  signal gts : std_ulogic := '1';
  signal q : std_ulogic := 'X';
begin
  check : process
  begin
    assert sim_device_ok(SIM_DEVICE)
      report "IOBUFDS_INTERMDISABLE SIM_DEVICE is not legal" severity failure;
    wait;
  end process;

  toc_p : process
  begin
    toc(gts);
  end process;

  IO <= tri_en(I, gts or T);
  IOB <= tri_en(inv1(I), gts or T);

  recv : process (IO, IOB)
    variable n : std_ulogic;
  begin
    n := diff_next(q, IO, IOB, DQS_BIAS, true, true, false);
    if n /= q then
      q <= n;
    end if;
  end process;

  O <= q when not USE_IBUFDISABLE else
       mux01(inv1(T) or IBUFDISABLE, disabled_val(SIM_DEVICE), q);
end architecture sim;
