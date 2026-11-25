-- AUTOBUF. Functional model is a buf. BUFFER_TYPE is not used.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity AUTOBUF is
  generic (
    BUFFER_TYPE : string := "AUTO"
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic
  );
end entity AUTOBUF;

architecture sim of AUTOBUF is
begin
  O <= buf1(I);
end architecture sim;
