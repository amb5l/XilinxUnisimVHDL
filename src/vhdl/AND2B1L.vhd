-- AND2B1L. O = not GSR and DI and not (SRI xor IS_SRI_INVERTED).
-- GSR forces O to 0. This pin has no AND2; AND2B1L is the AND cell.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity AND2B1L is
  generic (
    IS_SRI_INVERTED : bit := '0'
  );
  port (
    O : out std_ulogic;
    DI : in std_ulogic;
    SRI : in std_ulogic
  );
end entity AND2B1L;

architecture sim of AND2B1L is
  signal gsr : std_ulogic := '1';
  signal sri_in : std_ulogic;
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  sri_in <= xor_inv(SRI, IS_SRI_INVERTED);
  O <= '0' when gsr = '1' else DI and inv1(sri_in);
end architecture sim;
