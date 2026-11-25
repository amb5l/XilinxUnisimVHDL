-- CARRY4. CI and CYINIT treat Z as 0 (the Verilog "rv 0" reduction).
-- glbl.GSR is declared in the Verilog functional model and is not used.
-- CO_fb = {CO[2:0], CI_in or CYINIT_in}; O = S xor CO_fb;
-- CO = (S and CO_fb) or (not S and DI).

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity CARRY4 is
  port (
    CO : out std_logic_vector(3 downto 0);
    O : out std_logic_vector(3 downto 0);
    CI : in std_ulogic;
    CYINIT : in std_ulogic;
    DI : in std_logic_vector(3 downto 0);
    S : in std_logic_vector(3 downto 0)
  );
end entity CARRY4;

architecture sim of CARRY4 is
begin
  step : process (CI, CYINIT, DI, S)
    variable ci_in : std_ulogic;
    variable cy_in : std_ulogic;
    variable fb    : std_ulogic_vector(3 downto 0);
    variable co_v  : std_logic_vector(3 downto 0);
    variable o_v   : std_logic_vector(3 downto 0);
  begin
    ci_in := rv0(CI);
    cy_in := rv0(CYINIT);
    fb(0) := ci_in or cy_in;
    for i in 0 to 3 loop
      o_v(i) := S(i) xor fb(i);
      co_v(i) := (S(i) and fb(i)) or ((not S(i)) and DI(i));
      if i < 3 then
        fb(i + 1) := co_v(i);
      end if;
    end loop;
    CO <= co_v;
    O <= o_v;
  end process;
end architecture sim;
