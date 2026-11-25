-- LUT2. I0 is the least-significant address bit.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity LUT2 is
  generic (
    INIT : bit_vector(3 downto 0) := X"0"
  );
  port (
    O : out std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic
  );
end entity LUT2;

architecture sim of LUT2 is
begin
  O <= lut_eval(INIT, (0 => I0, 1 => I1));
end architecture sim;
