-- OBUFT. ts = GTS or T; bufif0(O, I, ts), as NVC simulates bufif0.
-- See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFT is
  generic (
    CAPACITANCE : string := "DONT_CARE";
    DRIVE : integer := 12;
    IOSTANDARD : string := "DEFAULT";
    SLEW : string := "SLOW"
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic;
    T : in std_ulogic
  );
end entity OBUFT;

architecture sim of OBUFT is
  signal gts : std_ulogic := '1';
begin
  check : process
  begin
    assert CAPACITANCE = "LOW" or CAPACITANCE = "NORMAL" or CAPACITANCE = "DONT_CARE"
      report "OBUFT CAPACITANCE must be LOW, NORMAL, or DONT_CARE" severity failure;
    wait;
  end process;

  toc_p : process
  begin
    toc(gts);
  end process;

  O <= bufif0_val(I, gts or T);
end architecture sim;
