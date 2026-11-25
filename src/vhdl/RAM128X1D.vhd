-- RAM128X1D. 128 x 1 dual-port distributed RAM.
-- Write is mem[A] <= #100 D on posedge of (WCLK xor IS_WCLK_INVERTED),
-- and only when rv1(WE) is 1: WE of Z writes, WE of X does not.
-- A non-0/1 address bit reads X and the write is ignored. No GSR.
-- The 100 ps delay is transport.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAM128X1D is
  generic (
    INIT : bit_vector(127 downto 0) := X"00000000000000000000000000000000";
    IS_WCLK_INVERTED : bit := '0'
  );
  port (
    DPO : out std_ulogic;
    SPO : out std_ulogic;
    A : in std_logic_vector(6 downto 0);
    D : in std_ulogic;
    DPRA : in std_logic_vector(6 downto 0);
    WCLK : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAM128X1D;

architecture sim of RAM128X1D is
  signal mem : std_logic_vector(127 downto 0) := to_stdlogicvector(INIT);
begin
  SPO <= mem_read(mem, A);
  DPO <= mem_read(mem, DPRA);
  writer : process is
  begin
    ram_clocked(WCLK, WE, D, A, mem, IS_WCLK_INVERTED, 100 ps);
  end process;
end architecture sim;
