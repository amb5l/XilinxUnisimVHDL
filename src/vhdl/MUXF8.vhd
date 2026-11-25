-- MUXF8. Same select rule as MUXF7: only S === 1 selects I1.

library ieee;
use ieee.std_logic_1164.all;

entity MUXF8 is
  port (
    O : out std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic;
    S : in std_ulogic
  );
end entity MUXF8;

architecture sim of MUXF8 is
begin
  O <= I1 when S = '1' else I0;
end architecture sim;
