-- IOBUF. or(ts, GTS, T); bufif0(IO, I, ts); buf(O, IO).
-- After TOC, GTS is 0. O is buf of the resolved pad, so an external Z
-- becomes X. Enable 1, X, or Z drives Z. See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IOBUF is
  generic (
    DRIVE : integer := 12;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SLEW : string := "SLOW"
  );
  port (
    O : out std_ulogic;
    IO : inout std_logic;
    I : in std_ulogic;
    T : in std_ulogic
  );
end entity IOBUF;

architecture sim of IOBUF is
  signal gts : std_ulogic := '1';
begin
  toc_p : process
  begin
    toc(gts);
  end process;

  IO <= bufif0_val(I, gts or T);
  O <= buf1(IO);
end architecture sim;
