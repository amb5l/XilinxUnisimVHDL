-- MUXCY. The Verilog functional model is `if (S) O = CI; else O = DI`.
-- Only S === 1 selects CI. X and Z select DI; they do not propagate X.
-- When CI and DI are equal the result is that value for every S.

library ieee;
use ieee.std_logic_1164.all;

entity MUXCY is
  port (
    O : out std_ulogic;
    CI : in std_ulogic;
    DI : in std_ulogic;
    S : in std_ulogic
  );
end entity MUXCY;

architecture sim of MUXCY is
begin
  O <= CI when S = '1' else DI;
end architecture sim;
