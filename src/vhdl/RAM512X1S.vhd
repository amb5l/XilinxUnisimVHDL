-- RAM512X1S. 512 x 1 single-port distributed RAM.
-- Write is mem[A] <= #100 D on posedge of (WCLK xor IS_WCLK_INVERTED),
-- and only when rv1(WE) is 1: WE of Z writes, WE of X does not.
-- A non-0/1 address bit reads X and the write is ignored. No GSR.
-- The 100 ps delay is transport.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAM512X1S is
  generic (
    INIT : bit_vector(511 downto 0) := X"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    IS_WCLK_INVERTED : bit := '0'
  );
  port (
    O : out std_ulogic;
    A : in std_logic_vector(8 downto 0);
    D : in std_ulogic;
    WCLK : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAM512X1S;

architecture sim of RAM512X1S is
  signal mem : std_logic_vector(511 downto 0) := to_stdlogicvector(INIT);
begin
  O <= mem_read(mem, A);
  writer : process is
  begin
    ram_clocked(WCLK, WE, D, A, mem, IS_WCLK_INVERTED, 100 ps);
  end process;
end architecture sim;
