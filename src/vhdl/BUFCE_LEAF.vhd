-- BUFCE_LEAF. Leaf clock buffer with a clock enable.
-- CE uses rv 1, then the optional invert (Z stays 1). I is xor'd with
-- IS_I_INVERTED (Z becomes X). enable starts at 1 and is forced to 1
-- while GSR is 1. ASYNC copies CE whenever GSR is 0. SYNC (and any other
-- CE_TYPE, which the Verilog encodes as SYNC) copies CE only while I is 0.
-- O is enable and I. An illegal CE_TYPE does not $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFCE_LEAF is
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
end entity BUFCE_LEAF;

architecture sim of BUFCE_LEAF is
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
