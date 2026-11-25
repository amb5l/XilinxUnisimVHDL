-- LUT6. I0 is the least-significant address bit.
-- Binary inputs index INIT. X inputs follow the Verilog LUT mux.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity LUT6 is
  generic (
    INIT : bit_vector(63 downto 0) := X"0000000000000000"
  );
  port (
    O : out std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic;
    I2 : in std_ulogic;
    I3 : in std_ulogic;
    I4 : in std_ulogic;
    I5 : in std_ulogic
  );
end entity LUT6;

architecture sim of LUT6 is
begin
  O <= lut_eval(INIT, (0 => I0, 1 => I1, 2 => I2, 3 => I3, 4 => I4, 5 => I5));
end architecture sim;
