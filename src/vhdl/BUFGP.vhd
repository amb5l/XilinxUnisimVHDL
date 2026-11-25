-- BUFGP. Functional model is a buf (Z maps to X).

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFGP is
  port (
    O : out std_ulogic;
    I : in std_ulogic
  );
end entity BUFGP;

architecture sim of BUFGP is
begin
  O <= buf1(I);
end architecture sim;
