-- BUFMRCE. Multi-region clock buffer with clock enable.
-- Same two-BUFGCTRL structure as BUFHCE, except IGNORE0 is tied to 0
-- (CE_TYPE is checked in the Verilog and then unused) and the second
-- cell's INIT_OUT generic is 1. The top-level INIT_OUT selects which
-- cell drives O. An illegal INIT_OUT does not $finish; only 1 selects
-- the second cell.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFMRCE is
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
end entity BUFMRCE;

architecture sim of BUFMRCE is
  signal nce, ce_pos, o0, o1 : std_ulogic;
  signal zero : std_ulogic := '0';
  signal one : std_ulogic := '1';
begin
  nce <= not vxor(CE, IS_CE_INVERTED);
  ce_pos <= not nce;

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
      IGNORE0 => zero,
      IGNORE1 => zero,
      S0 => one,
      S1 => one
    );

  u1 : entity unisim.BUFGCTRL
    generic map (
      INIT_OUT => 1,
      PRESELECT_I0 => TRUE,
      PRESELECT_I1 => FALSE
    )
    port map (
      O => o1,
      CE0 => ce_pos,
      CE1 => nce,
      I0 => I,
      I1 => one,
      IGNORE0 => zero,
      IGNORE1 => zero,
      S0 => one,
      S1 => one
    );

  O <= o1 when INIT_OUT = 1 else o0;
end architecture sim;
