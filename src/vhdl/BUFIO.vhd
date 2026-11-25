-- BUFIO. Local I/O clock buffer. The functional model is a buf (Z maps to X).

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFIO is
  port (
    O : out std_ulogic;
    I : in std_ulogic
  );
end entity BUFIO;

architecture sim of BUFIO is
begin
  O <= buf1(I);
end architecture sim;
