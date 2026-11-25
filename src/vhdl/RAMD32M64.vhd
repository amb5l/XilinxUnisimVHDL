-- RAMD32M64. The Verilog behavioral model is empty: O has no driver,
-- so it stays Z. INIT, the address, and the write pins are unused.
-- The SIMPRIM $finish under `ifndef XIL_TIMING` is not part of the model.

library ieee;
use ieee.std_logic_1164.all;

entity RAMD32M64 is
  generic (
    INIT : bit_vector(63 downto 0) := X"0000000000000000";
    IS_CLK_INVERTED : bit := '0'
  );
  port (
    O : out std_ulogic;
    CLK : in std_ulogic;
    I : in std_ulogic;
    RADR0 : in std_ulogic;
    RADR1 : in std_ulogic;
    RADR2 : in std_ulogic;
    RADR3 : in std_ulogic;
    RADR4 : in std_ulogic;
    RADR5 : in std_ulogic;
    WADR0 : in std_ulogic;
    WADR1 : in std_ulogic;
    WADR2 : in std_ulogic;
    WADR3 : in std_ulogic;
    WADR4 : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAMD32M64;

architecture sim of RAMD32M64 is
begin
  O <= 'Z';
end architecture sim;
