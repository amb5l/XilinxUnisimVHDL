-- OBUFDS_DPHY. LP mode (LPTX_T 0) copies LPTX_I_P to O and LPTX_I_N
-- to OB, including Z. HS mode (LPTX_T 1 and HSTX_T 0) copies HSTX_I
-- to O and its inverse to OB. Anything else drives Z. IOSTANDARD
-- is unused.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFDS_DPHY is
  generic (
    IOSTANDARD : string := "DEFAULT"
  );
  port (
    O : out std_ulogic;
    OB : out std_ulogic;
    HSTX_I : in std_ulogic;
    HSTX_T : in std_ulogic;
    LPTX_I_N : in std_ulogic;
    LPTX_I_P : in std_ulogic;
    LPTX_T : in std_ulogic
  );
end entity OBUFDS_DPHY;

architecture sim of OBUFDS_DPHY is
begin
  step : process (LPTX_T, HSTX_T, LPTX_I_P, LPTX_I_N, HSTX_I)
  begin
    if LPTX_T = '0' then
      O <= LPTX_I_P;
      OB <= LPTX_I_N;
    elsif LPTX_T = '1' and HSTX_T = '0' then
      O <= HSTX_I;
      OB <= inv1(HSTX_I);
    else
      O <= 'Z';
      OB <= 'Z';
    end if;
  end process;
end architecture sim;
