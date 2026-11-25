-- OBUFTDS. Enable is GTS or T. bufif0 on O, notif0 on OB.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFTDS is
  generic (
    CAPACITANCE : string := "DONT_CARE";
    IOSTANDARD : string := "DEFAULT";
    SLEW : string := "SLOW"
  );
  port (
    O : out std_ulogic;
    OB : out std_ulogic;
    I : in std_ulogic;
    T : in std_ulogic
  );
end entity OBUFTDS;

architecture sim of OBUFTDS is
  signal gts : std_ulogic := '1';
  signal en : std_ulogic;
begin
  check : process
  begin
    assert CAPACITANCE = "LOW" or CAPACITANCE = "NORMAL" or CAPACITANCE = "DONT_CARE"
      report "OBUFTDS CAPACITANCE must be LOW, NORMAL, or DONT_CARE" severity failure;
    wait;
  end process;

  toc_p : process
  begin
    toc(gts);
  end process;

  en <= gts or T;
  O <= bufif0_val(I, en);
  OB <= notif0_val(I, en);
end architecture sim;
