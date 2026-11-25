-- LUT4. I0 is the least-significant address bit.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity LUT4 is
  generic (
    INIT : bit_vector(15 downto 0) := X"0000"
  );
  port (
    O : out std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic;
    I2 : in std_ulogic;
    I3 : in std_ulogic
  );
end entity LUT4;

architecture sim of LUT4 is
begin
  O <= lut_eval(INIT, (0 => I0, 1 => I1, 2 => I2, 3 => I3));
end architecture sim;
