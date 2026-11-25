-- RAMD64E. 64 x 1 dual-port distributed RAM.
-- The SIMPRIM $finish under `ifndef XIL_TIMING` is not part of the model.
-- Write matches RAMD32, and also requires each RAM_ADDRESS_MASK bit that
-- is 0 to see the matching RAM_ADDRESS_SPACE bit on WADR7 (bit 1) and
-- WADR6 (bit 0). An X or Z there fails the compare and the write is ignored.
-- The Verilog copies IS_CLK_INVERTED into a reg after 2 ps. Compare after that.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAMD64E is
  generic (
    INIT : bit_vector(63 downto 0) := X"0000000000000000";
    IS_CLK_INVERTED : bit := '0';
    RAM_ADDRESS_MASK : bit_vector(1 downto 0) := "00";
    RAM_ADDRESS_SPACE : bit_vector(1 downto 0) := "00"
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
    WADR5 : in std_ulogic;
    WADR6 : in std_ulogic;
    WADR7 : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAMD64E;

architecture sim of RAMD64E is
  signal mem : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT);

  function space_ok(mask : bit; wadr, space : std_ulogic) return boolean is
  begin
    return mask = '1' or wadr = space;
  end function;
begin
  O <= mem_read(mem, RADR5 & RADR4 & RADR3 & RADR2 & RADR1 & RADR0);

  writer : process is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
    variable sel : std_logic_vector(5 downto 0);
  begin
    loop
      curr := vxor(CLK, IS_CLK_INVERTED);
      sel := WADR5 & WADR4 & WADR3 & WADR2 & WADR1 & WADR0;
      if verilog_posedge(prev, curr) and rv1(WE) = '1'
         and space_ok(RAM_ADDRESS_MASK(1), WADR7, to_sul(RAM_ADDRESS_SPACE(1)))
         and space_ok(RAM_ADDRESS_MASK(0), WADR6, to_sul(RAM_ADDRESS_SPACE(0))) then
        ram_write_at(mem, bit_addr(sel), I, 0 ps);
      end if;
      prev := curr;
      wait on CLK;
    end loop;
  end process;
end architecture sim;
