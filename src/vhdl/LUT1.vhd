-- LUT1. INIT is addressed by I0. X/Z follows the Verilog LUT UDP.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity LUT1 is
  generic (
    INIT : bit_vector(1 downto 0) := "00"
  );
  port (
    O : out std_ulogic;
    I0 : in std_ulogic
  );
end entity LUT1;

architecture sim of LUT1 is
begin
  O <= lut_eval(INIT, (0 => I0));
end architecture sim;
