-- LUT5. I0 is the least-significant address bit.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity LUT5 is
  generic (
    INIT : bit_vector(31 downto 0) := X"00000000"
  );
  port (
    O : out std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic;
    I2 : in std_ulogic;
    I3 : in std_ulogic;
    I4 : in std_ulogic
  );
end entity LUT5;

architecture sim of LUT5 is
begin
  O <= lut_eval(INIT, (0 => I0, 1 => I1, 2 => I2, 3 => I3, 4 => I4));
end architecture sim;
