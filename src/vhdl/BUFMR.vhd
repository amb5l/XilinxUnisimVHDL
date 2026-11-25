-- BUFMR. Multi-region clock buffer. The functional model is a buf (Z maps to X).

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFMR is
  port (
    O : out std_ulogic;
    I : in std_ulogic
  );
end entity BUFMR;

architecture sim of BUFMR is
begin
  O <= buf1(I);
end architecture sim;
