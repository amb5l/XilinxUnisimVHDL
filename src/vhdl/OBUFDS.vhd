-- OBUFDS. bufif0(O, I, GTS) and notif0(OB, I, GTS), as NVC simulates them.
-- After the default TOC, GTS is 0.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFDS is
  generic (
    CAPACITANCE : string := "DONT_CARE";
    IOSTANDARD : string := "DEFAULT";
    SLEW : string := "SLOW"
  );
  port (
    O : out std_ulogic;
    OB : out std_ulogic;
    I : in std_ulogic
  );
end entity OBUFDS;

architecture sim of OBUFDS is
  signal gts : std_ulogic := '1';
begin
  check : process
  begin
    assert CAPACITANCE = "LOW" or CAPACITANCE = "NORMAL" or CAPACITANCE = "DONT_CARE"
      report "OBUFDS CAPACITANCE must be LOW, NORMAL, or DONT_CARE" severity failure;
    wait;
  end process;

  toc_p : process
  begin
    toc(gts);
  end process;

  O <= bufif0_val(I, gts);
  OB <= notif0_val(I, gts);
end architecture sim;
