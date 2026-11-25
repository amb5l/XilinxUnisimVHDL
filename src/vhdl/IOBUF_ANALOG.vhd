-- IOBUF_ANALOG. I and T pass through rv1 (Z becomes 1) before the
-- ternary. IO = ~T_in ? I_in : Z, so T of Z disables and I of Z is
-- driven as 1. O is the resolved pad, and Z passes through.
-- See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IOBUF_ANALOG is
  generic (
    DRIVE : integer := 12;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SLEW : string := "SLOW"
  );
  port (
    O : out std_ulogic;
    IO : inout std_logic;
    I : in std_ulogic;
    T : in std_ulogic
  );
end entity IOBUF_ANALOG;

architecture sim of IOBUF_ANALOG is
begin
  IO <= tri_en(rv1(I), rv1(T));
  O <= IO;
end architecture sim;
