-- DCIRESET. LOCKED falls in the same delta as RST rising, and rises
-- 100 ns after RST falls. That 100 ns is the functional delay in the
-- Verilog continuous assign, not a specify path. The pulse-width
-- $display is not copied, and a short pulse does not $finish.

library ieee;
use ieee.std_logic_1164.all;

entity DCIRESET is
  port (
    LOCKED : out std_ulogic;
    RST : in std_ulogic
  );
end entity DCIRESET;

architecture sim of DCIRESET is
begin
  lock_p : process (RST) is
  begin
    if RST = '1' then
      LOCKED <= '0';
    else
      LOCKED <= '1' after 100 ns;
    end if;
  end process;
end architecture sim;
