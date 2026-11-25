-- LUT3. I0 is the least-significant address bit.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity LUT3 is
  generic (
    INIT : bit_vector(7 downto 0) := X"00"
  );
  port (
    O : out std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic;
    I2 : in std_ulogic
  );
end entity LUT3;

architecture sim of LUT3 is
begin
  O <= lut_eval(INIT, (0 => I0, 1 => I1, 2 => I2));
end architecture sim;
