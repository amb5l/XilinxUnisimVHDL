-- RAM128X1S. 128 x 1 single-port distributed RAM.
-- Write is mem[A] <= #100 D on posedge of (WCLK xor IS_WCLK_INVERTED),
-- and only when rv1(WE) is 1: WE of Z writes, WE of X does not.
-- The address is sampled from the pins in that delta, matching a write
-- that changes A and WCLK together. A non-0/1 address bit reads X and
-- the write is ignored. No GSR. The 100 ps delay is transport.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAM128X1S is
  generic (
    INIT : bit_vector(127 downto 0) := X"00000000000000000000000000000000";
    IS_WCLK_INVERTED : bit := '0'
  );
  port (
    O : out std_ulogic;
    A0 : in std_ulogic;
    A1 : in std_ulogic;
    A2 : in std_ulogic;
    A3 : in std_ulogic;
    A4 : in std_ulogic;
    A5 : in std_ulogic;
    A6 : in std_ulogic;
    D : in std_ulogic;
    WCLK : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAM128X1S;

architecture sim of RAM128X1S is
  signal mem : std_logic_vector(127 downto 0) := to_stdlogicvector(INIT);
begin
  O <= mem_read(mem, A6 & A5 & A4 & A3 & A2 & A1 & A0);
  writer : process is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
    variable sel : std_logic_vector(6 downto 0);
  begin
    loop
      curr := WCLK xor to_sul(IS_WCLK_INVERTED);
      sel(0) := A0;
      sel(1) := A1;
      sel(2) := A2;
      sel(3) := A3;
      sel(4) := A4;
      sel(5) := A5;
      sel(6) := A6;
      if verilog_posedge(prev, curr) and rv1(WE) = '1' then
        ram_write_at(mem, bit_addr(sel), D, 100 ps);
      end if;
      prev := curr;
      wait on WCLK;
    end loop;
  end process;
end architecture sim;
