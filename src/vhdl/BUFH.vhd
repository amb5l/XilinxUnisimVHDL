-- BUFH. Functional model is a buf (Z maps to X).

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFH is
  port (
    O : out std_ulogic;
    I : in std_ulogic
  );
end entity BUFH;

architecture sim of BUFH is
begin
  O <= buf1(I);
end architecture sim;
