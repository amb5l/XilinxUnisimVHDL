-- IOBUFDS_DIFF_OUT_DCIEN. Same drivers and receiver as
-- IOBUFDS_DIFF_OUT. DCITERMDISABLE is not read by the functional
-- assign. USE_IBUFDISABLE true forces out_val / out_b_val when
-- ~TM || IBUFDISABLE (and ~TS for OB) is 1. 7SERIES is 1/1,
-- ULTRASCALE is 0/X, anything else is 0/0. See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IOBUFDS_DIFF_OUT_DCIEN is
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
    IO : inout std_logic;
    IOB : inout std_logic;
    DCITERMDISABLE : in std_ulogic;
    I : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    TM : in std_ulogic;
    TS : in std_ulogic
  );
end entity IOBUFDS_DIFF_OUT_DCIEN;

architecture sim of IOBUFDS_DIFF_OUT_DCIEN is
  signal gts : std_ulogic := '1';
  signal q : std_ulogic := 'X';
  signal qb : std_ulogic := 'X';
begin
  check : process
  begin
    assert sim_device_ok(SIM_DEVICE)
      report "IOBUFDS_DIFF_OUT_DCIEN SIM_DEVICE is not legal" severity failure;
    wait;
  end process;

  toc_p : process
  begin
    toc(gts);
  end process;

  IO <= bufif0_val(I, gts or TM);
  IOB <= notif0_val(I, gts or TS);

  recv : process (IO, IOB)
    variable n : std_ulogic;
  begin
    n := diff_next(q, IO, IOB, DQS_BIAS, false, false, true);
    q <= n;
    qb <= inv1(n);
  end process;

  O <= q when not USE_IBUFDISABLE else
       mux01(inv1(TM) or IBUFDISABLE, disabled_val(SIM_DEVICE), q);
  OB <= qb when not USE_IBUFDISABLE else
        mux01(inv1(TS) or IBUFDISABLE, disabled_b_val(SIM_DEVICE), qb);
end architecture sim;
