-- OBUFTDS_DCIEN. Same drivers as OBUFTDS. DCITERMDISABLE is unused.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFTDS_DCIEN is
  generic (
    IOSTANDARD : string := "DEFAULT";
    SLEW : string := "SLOW"
  );
  port (
    O : out std_ulogic;
    OB : out std_ulogic;
    DCITERMDISABLE : in std_ulogic;
    I : in std_ulogic;
    T : in std_ulogic
  );
end entity OBUFTDS_DCIEN;

architecture sim of OBUFTDS_DCIEN is
  signal gts : std_ulogic := '1';
  signal en : std_ulogic;
begin
  toc_p : process
  begin
    toc(gts);
  end process;

  en <= gts or T;
  O <= bufif0_val(I, en);
  OB <= notif0_val(I, en);
end architecture sim;
