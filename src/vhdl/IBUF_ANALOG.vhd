-- IBUF_ANALOG. The Verilog functional model is a plain assign, so Z passes.

library ieee;
use ieee.std_logic_1164.all;

entity IBUF_ANALOG is
  port (
    O : out std_ulogic;
    I : in std_ulogic
  );
end entity IBUF_ANALOG;

architecture sim of IBUF_ANALOG is
begin
  O <= I;
end architecture sim;
