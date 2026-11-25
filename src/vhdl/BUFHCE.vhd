-- BUFHCE. Horizontal clock buffer with clock enable.
-- Built from two BUFGCTRL cells the way the Verilog is: both selects are
-- 1, I0 is I, I1 is 0 on the first cell and 1 on the second, and CE picks
-- which input each cell forwards. INIT_OUT selects which cell drives O.
-- ASYNC drives IGNORE0 so the enable is not sampled on I. An illegal
-- CE_TYPE or INIT_OUT does not $finish; IGNORE0 is then X and any
-- INIT_OUT other than 1 selects the first cell.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFHCE is
  generic (
    CE_TYPE : string := "SYNC";
    INIT_OUT : integer := 0;
    IS_CE_INVERTED : bit := '0'
  );
  port (
    O : out std_ulogic;
    CE : in std_ulogic;
    I : in std_ulogic
  );
end entity BUFHCE;

architecture sim of BUFHCE is
  signal nce, ce_pos, ign, o0, o1 : std_ulogic;
  signal zero : std_ulogic := '0';
  signal one : std_ulogic := '1';
begin
  nce <= not vxor(CE, IS_CE_INVERTED);
  ce_pos <= not nce;
  ign <= '1' when CE_TYPE = "ASYNC" else
         '0' when CE_TYPE = "SYNC" else
         'X';

  u0 : entity unisim.BUFGCTRL
    generic map (
      INIT_OUT => 0,
      PRESELECT_I0 => TRUE,
      PRESELECT_I1 => FALSE
    )
    port map (
      O => o0,
      CE0 => ce_pos,
      CE1 => nce,
      I0 => I,
      I1 => zero,
      IGNORE0 => ign,
      IGNORE1 => zero,
      S0 => one,
      S1 => one
    );

  u1 : entity unisim.BUFGCTRL
    generic map (
      INIT_OUT => 0,
      PRESELECT_I0 => TRUE,
      PRESELECT_I1 => FALSE
    )
    port map (
      O => o1,
      CE0 => ce_pos,
      CE1 => nce,
      I0 => I,
      I1 => one,
      IGNORE0 => ign,
      IGNORE1 => zero,
      S0 => one,
      S1 => one
    );

  O <= o1 when INIT_OUT = 1 else o0;
end architecture sim;
