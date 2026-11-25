-- MUXF9. Same select rule as MUXF7: `if (S) O = I1; else O = I0`.
-- Only S === 1 selects I1. X and Z select I0.

library ieee;
use ieee.std_logic_1164.all;

entity MUXF9 is
  port (
    O : out std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic;
    S : in std_ulogic
  );
end entity MUXF9;

architecture sim of MUXF9 is
begin
  O <= I1 when S = '1' else I0;
end architecture sim;
