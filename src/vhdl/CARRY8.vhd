-- CARRY8. Eight-bit carry. Every data input passes through rv 0
-- (Z becomes 0, X stays X).
--   CO_fb = {CO[6:4], CI_TOP_in, CO[2:0], CI}
--   O     = S xor CO_fb
--   CO    = (S and CO_fb) or (not S and DI)
-- SINGLE_CY8 (the default) feeds CO(3) into the upper nibble, so CI_TOP
-- is unused. DUAL_CY4 starts the upper nibble from CI_TOP instead.
-- Any other CARRY_TYPE makes the Verilog $finish; this model uses the
-- single chain, which is also the Verilog parameter default before that
-- check. The Verilog copies CARRY_TYPE into a reg after 2 ps. Compare
-- after that.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity CARRY8 is
  generic (
    CARRY_TYPE : string := "SINGLE_CY8"
  );
  port (
    CO : out std_logic_vector(7 downto 0);
    O : out std_logic_vector(7 downto 0);
    CI : in std_ulogic;
    CI_TOP : in std_ulogic;
    DI : in std_logic_vector(7 downto 0);
    S : in std_logic_vector(7 downto 0)
  );
end entity CARRY8;

architecture sim of CARRY8 is
begin
  step : process (CI, CI_TOP, DI, S)
    variable fb   : std_ulogic_vector(7 downto 0);
    variable co_v : std_logic_vector(7 downto 0);
    variable o_v  : std_logic_vector(7 downto 0);
    variable sb   : std_ulogic;
    variable db   : std_ulogic;
  begin
    fb(0) := rv0(CI);
    for i in 0 to 7 loop
      if i = 4 then
        if CARRY_TYPE = "DUAL_CY4" then
          fb(4) := rv0(CI_TOP);
        else
          fb(4) := co_v(3);
        end if;
      end if;
      sb := rv0(S(i));
      db := rv0(DI(i));
      o_v(i) := sb xor fb(i);
      co_v(i) := (sb and fb(i)) or ((not sb) and db);
      if i < 7 and i /= 3 then
        fb(i + 1) := co_v(i);
      end if;
    end loop;
    CO <= co_v;
    O <= o_v;
  end process;
end architecture sim;
