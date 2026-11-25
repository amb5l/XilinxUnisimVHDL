-- XORCY. Derived from the Apache-2.0 Verilog xor (O = CI xor LI).

library ieee;
use ieee.std_logic_1164.all;

entity XORCY is
  port (
    O : out std_ulogic;
    CI : in std_ulogic;
    LI : in std_ulogic
  );
end entity XORCY;

architecture sim of XORCY is
begin
  O <= CI xor LI;
end architecture sim;
