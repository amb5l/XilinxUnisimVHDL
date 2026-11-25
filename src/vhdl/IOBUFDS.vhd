-- IOBUFDS. t_or_gts = GTS || T. IO = t_or_gts ? Z : I and
-- IOB = t_or_gts ? Z : ~I (ternary, not bufif0: an X enable merges).
-- O is the differential receiver. The X arm is === on IO and == on
-- IOB, and == never matches X, so X on IOB alone holds. See
-- docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IOBUFDS is
  generic (
    DIFF_TERM : boolean := FALSE;
    DQS_BIAS : boolean := FALSE;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SLEW : string := "SLOW"
  );
  port (
    O : out std_ulogic;
    IO : inout std_logic;
    IOB : inout std_logic;
    I : in std_ulogic;
    T : in std_ulogic
  );
end entity IOBUFDS;

architecture sim of IOBUFDS is
  signal gts : std_ulogic := '1';
  signal q : std_ulogic := 'X';
begin
  toc_p : process
  begin
    toc(gts);
  end process;

  IO <= tri_en(I, gts or T);
  IOB <= tri_en(inv1(I), gts or T);

  recv : process (IO, IOB)
    variable n : std_ulogic;
  begin
    n := diff_next(q, IO, IOB, DQS_BIAS, true, false, false);
    if n /= q then
      q <= n;
    end if;
  end process;

  O <= q;
end architecture sim;
