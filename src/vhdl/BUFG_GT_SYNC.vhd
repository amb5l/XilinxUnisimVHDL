-- BUFG_GT_SYNC. Pass-through synchroniser pins.
-- CESYNC is rv 1 of CE (Z becomes 1). CLRSYNC is rv 0 of CLR (Z becomes 0).
-- CLK is unused.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFG_GT_SYNC is
  port (
    CESYNC : out std_ulogic;
    CLRSYNC : out std_ulogic;
    CE : in std_ulogic;
    CLK : in std_ulogic;
    CLR : in std_ulogic
  );
end entity BUFG_GT_SYNC;

architecture sim of BUFG_GT_SYNC is
begin
  CESYNC <= rv1(CE);
  CLRSYNC <= rv0(CLR);
end architecture sim;
