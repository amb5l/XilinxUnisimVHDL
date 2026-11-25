-- BUFG. Derived from the Apache-2.0 Verilog buf (Z maps to X).

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFG is
  port (
    O : out std_ulogic;
    I : in std_ulogic
  );
end entity BUFG;

architecture sim of BUFG is
begin
  O <= buf1(I);
end architecture sim;
