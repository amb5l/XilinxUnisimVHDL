-- INV. Derived from the Apache-2.0 Verilog not (Z maps to X).

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity INV is
  port (
    O : out std_ulogic;
    I : in std_ulogic
  );
end entity INV;

architecture sim of INV is
begin
  O <= inv1(I);
end architecture sim;
