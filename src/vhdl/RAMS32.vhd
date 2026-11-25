-- RAMS32. 32 x 1 single-port distributed RAM. Same write rule as RAMD32.
-- One address is both the read address and the write address.
-- The SIMPRIM $finish under `ifndef XIL_TIMING` is not part of the model.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAMS32 is
  generic (
    INIT : bit_vector(31 downto 0) := X"00000000";
    IS_CLK_INVERTED : bit := '0'
  );
  port (
    O : out std_ulogic;
    ADR0 : in std_ulogic;
    ADR1 : in std_ulogic;
    ADR2 : in std_ulogic;
    ADR3 : in std_ulogic;
    ADR4 : in std_ulogic;
    CLK : in std_ulogic;
    I : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAMS32;

architecture sim of RAMS32 is
  signal mem : std_logic_vector(31 downto 0) := to_stdlogicvector(INIT);
begin
  O <= mem_read(mem, ADR4 & ADR3 & ADR2 & ADR1 & ADR0);

  writer : process is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
    variable sel : std_logic_vector(4 downto 0);
  begin
    loop
      curr := vxor(CLK, IS_CLK_INVERTED);
      sel := ADR4 & ADR3 & ADR2 & ADR1 & ADR0;
      if verilog_posedge(prev, curr) and rv1(WE) = '1' then
        ram_write_at(mem, bit_addr(sel), I, 0 ps);
      end if;
      prev := curr;
      wait on CLK;
    end loop;
  end process;
end architecture sim;
