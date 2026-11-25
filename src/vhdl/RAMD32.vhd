-- RAMD32. 32 x 1 dual-port distributed RAM.
-- The SIMPRIM $finish under `ifndef XIL_TIMING` is not part of the model.
-- Write is mem[WADR] = I on posedge of (CLK xor IS_CLK_INVERTED), with no
-- delay, and only when rv1(WE) is 1: WE of Z writes, WE of X does not.
-- The address is sampled in that delta. A non-0/1 address reads X and the
-- write is ignored. Read is combinational. glbl.GSR is unused.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAMD32 is
  generic (
    INIT : bit_vector(31 downto 0) := X"00000000";
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
    WADR0 : in std_ulogic;
    WADR1 : in std_ulogic;
    WADR2 : in std_ulogic;
    WADR3 : in std_ulogic;
    WADR4 : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAMD32;

architecture sim of RAMD32 is
  signal mem : std_logic_vector(31 downto 0) := to_stdlogicvector(INIT);
begin
  O <= mem_read(mem, RADR4 & RADR3 & RADR2 & RADR1 & RADR0);

  writer : process is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
    variable sel : std_logic_vector(4 downto 0);
  begin
    loop
      curr := vxor(CLK, IS_CLK_INVERTED);
      sel := WADR4 & WADR3 & WADR2 & WADR1 & WADR0;
      if verilog_posedge(prev, curr) and rv1(WE) = '1' then
        ram_write_at(mem, bit_addr(sel), I, 0 ps);
      end if;
      prev := curr;
      wait on CLK;
    end loop;
  end process;
end architecture sim;
