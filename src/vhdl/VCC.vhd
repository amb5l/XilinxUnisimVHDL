-- VCC. The Verilog model drives P with 1.

library ieee;
use ieee.std_logic_1164.all;

entity VCC is
  port (
    P : out std_ulogic
  );
end entity VCC;

architecture sim of VCC is
begin
  P <= '1';
end architecture sim;
