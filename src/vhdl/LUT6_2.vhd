-- LUT6_2. O6 is the 6-input LUT. O5 is the lower 32 INIT bits as a
-- 5-input LUT of I4..I0. X follows the same address-agreement rule as LUT6.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity LUT6_2 is
  generic (
    INIT : bit_vector(63 downto 0) := X"0000000000000000"
  );
  port (
    O5 : out std_ulogic;
    O6 : out std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic;
    I2 : in std_ulogic;
    I3 : in std_ulogic;
    I4 : in std_ulogic;
    I5 : in std_ulogic
  );
end entity LUT6_2;

architecture sim of LUT6_2 is
begin
  O5 <= lut_eval(INIT(31 downto 0), (0 => I0, 1 => I1, 2 => I2, 3 => I3, 4 => I4));
  O6 <= lut_eval(INIT, (0 => I0, 1 => I1, 2 => I2, 3 => I3, 4 => I4, 5 => I5));
end architecture sim;
