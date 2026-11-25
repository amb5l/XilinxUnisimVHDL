-- GND. The Verilog model drives G with 0.

library ieee;
use ieee.std_logic_1164.all;

entity GND is
  port (
    G : out std_ulogic
  );
end entity GND;

architecture sim of GND is
begin
  G <= '0';
end architecture sim;
