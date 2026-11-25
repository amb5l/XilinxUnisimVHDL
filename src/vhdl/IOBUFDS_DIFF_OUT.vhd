-- IOBUFDS_DIFF_OUT. Separate enables: bufif0(IO, I, GTS or TM) and
-- notif0(IOB, I, GTS or TS). The receiver drives X when no row matches
-- (it does not hold). OB is ~ of the resolved IO bit, which is inv1
-- for 0/1 and X whenever O is X. See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IOBUFDS_DIFF_OUT is
  generic (
    DIFF_TERM : boolean := FALSE;
    DQS_BIAS : boolean := FALSE;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT"
  );
  port (
    O : out std_ulogic;
    OB : out std_ulogic;
    IO : inout std_logic;
    IOB : inout std_logic;
    I : in std_ulogic;
    TM : in std_ulogic;
    TS : in std_ulogic
  );
end entity IOBUFDS_DIFF_OUT;

architecture sim of IOBUFDS_DIFF_OUT is
  signal gts : std_ulogic := '1';
  signal q : std_ulogic := 'X';
begin
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
    O <= n;
    OB <= inv1(n);
  end process;
end architecture sim;
