-- MUXF7. The Verilog functional model is `if (S) O = I1; else O = I0`.
-- Only S === 1 selects I1. X and Z select I0; they do not propagate X.

library ieee;
use ieee.std_logic_1164.all;

entity MUXF7 is
  port (
    O : out std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic;
    S : in std_ulogic
  );
end entity MUXF7;

architecture sim of MUXF7 is
begin
  O <= I1 when S = '1' else I0;
end architecture sim;
