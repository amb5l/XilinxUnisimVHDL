-- OR2L. O = not GSR and (DI or (SRI xor IS_SRI_INVERTED)).
-- GSR forces O to 0. This pin has no OR2; OR2L is the OR cell.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OR2L is
  generic (
    IS_SRI_INVERTED : bit := '0'
  );
  port (
    O : out std_ulogic;
    DI : in std_ulogic;
    SRI : in std_ulogic
  );
end entity OR2L;

architecture sim of OR2L is
  signal gsr : std_ulogic := '1';
  signal sri_in : std_ulogic;
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  sri_in <= xor_inv(SRI, IS_SRI_INVERTED);
  O <= '0' when gsr = '1' else DI or sri_in;
end architecture sim;
