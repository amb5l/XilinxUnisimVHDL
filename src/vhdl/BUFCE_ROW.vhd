-- BUFCE_ROW. Row clock buffer. Same enable as BUFCE_LEAF, plus HARDSYNC.
-- HARDSYNC is not ASYNC, so CE is copied only while I is 0, matching SYNC.
-- The Verilog $finish when XIL_TIMING is undefined is not implemented.
-- An illegal CE_TYPE falls back to that SYNC behaviour and does not abort.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFCE_ROW is
  generic (
    CE_TYPE : string := "SYNC";
    IS_CE_INVERTED : bit := '0';
    IS_I_INVERTED : bit := '0'
  );
  port (
    O : out std_ulogic;
    CE : in std_ulogic;
    I : in std_ulogic
  );
end entity BUFCE_ROW;

architecture sim of BUFCE_ROW is
  signal gsr : std_ulogic := '1';
  signal ce_in, i_in : std_ulogic;
  signal enable_clk : std_ulogic := '1';
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  ce_in <= rv1x(CE, IS_CE_INVERTED);
  i_in <= vxor(I, IS_I_INVERTED);

  en : process (i_in, ce_in, gsr)
  begin
    if gsr = '1' then
      enable_clk <= '1';
    elsif CE_TYPE = "ASYNC" or i_in = '0' then
      enable_clk <= ce_in;
    end if;
  end process;

  O <= enable_clk and i_in;
end architecture sim;
