-- RAMS64E. 64 x 1 single-port distributed RAM.
-- The SIMPRIM $finish under `ifndef XIL_TIMING` is not part of the model.
-- ADR5:0 is the read and write address. WADR7 and WADR6 are the address-space
-- compare, same rule as RAMD64E. The read does not use that compare.
-- The Verilog copies IS_CLK_INVERTED into a reg after 2 ps. Compare after that.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAMS64E is
  generic (
    INIT : bit_vector(63 downto 0) := X"0000000000000000";
    IS_CLK_INVERTED : bit := '0';
    RAM_ADDRESS_MASK : bit_vector(1 downto 0) := "00";
    RAM_ADDRESS_SPACE : bit_vector(1 downto 0) := "00"
  );
  port (
    O : out std_ulogic;
    ADR0 : in std_ulogic;
    ADR1 : in std_ulogic;
    ADR2 : in std_ulogic;
    ADR3 : in std_ulogic;
    ADR4 : in std_ulogic;
    ADR5 : in std_ulogic;
    CLK : in std_ulogic;
    I : in std_ulogic;
    WADR6 : in std_ulogic;
    WADR7 : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAMS64E;

architecture sim of RAMS64E is
  signal mem : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT);

  function space_ok(mask : bit; wadr, space : std_ulogic) return boolean is
  begin
    return mask = '1' or wadr = space;
  end function;
begin
  O <= mem_read(mem, ADR5 & ADR4 & ADR3 & ADR2 & ADR1 & ADR0);

  writer : process is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
    variable sel : std_logic_vector(5 downto 0);
  begin
    loop
      curr := vxor(CLK, IS_CLK_INVERTED);
      sel := ADR5 & ADR4 & ADR3 & ADR2 & ADR1 & ADR0;
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
