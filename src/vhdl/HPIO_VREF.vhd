-- HPIO_VREF. VREF is constant 1. FABRIC_VREF_TUNE and VREF_CNTR are
-- not used by the output. An illegal VREF_CNTR does not $finish.

library ieee;
use ieee.std_logic_1164.all;

entity HPIO_VREF is
  generic (
    VREF_CNTR : string := "OFF"
  );
  port (
    VREF : out std_ulogic;
    FABRIC_VREF_TUNE : in std_logic_vector(6 downto 0)
  );
end entity HPIO_VREF;

architecture sim of HPIO_VREF is
begin
  VREF <= '1';
end architecture sim;
