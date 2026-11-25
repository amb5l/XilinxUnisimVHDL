-- IBUFCTRL. The SIMPRIM $finish under `ifndef XIL_TIMING` is not part
-- of the model. USE_IBUFDISABLE false passes I through. True drives 0 when
-- (not T or IBUFDISABLE) is 1, passes I when that is 0, and drives X otherwise.
-- INTERMDISABLE and ISTANDARD are unused. glbl.GSR is unused.

library ieee;
use ieee.std_logic_1164.all;

entity IBUFCTRL is
  generic (
    ISTANDARD : string := "UNUSED";
    USE_IBUFDISABLE : boolean := FALSE
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    INTERMDISABLE : in std_ulogic;
    T : in std_ulogic
  );
end entity IBUFCTRL;

architecture sim of IBUFCTRL is
  signal dis : std_ulogic;
begin
  dis <= (not T) or IBUFDISABLE;
  O <= I when not USE_IBUFDISABLE else
       I when dis = '0' else
       '0' when dis = '1' else
       'X';
end architecture sim;
