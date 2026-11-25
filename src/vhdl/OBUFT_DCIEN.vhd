-- OBUFT_DCIEN. Same driver as OBUFT. DCITERMDISABLE is unused.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFT_DCIEN is
  generic (
    DRIVE : integer := 12;
    IOSTANDARD : string := "DEFAULT";
    SLEW : string := "SLOW"
  );
  port (
    O : out std_ulogic;
    DCITERMDISABLE : in std_ulogic;
    I : in std_ulogic;
    T : in std_ulogic
  );
end entity OBUFT_DCIEN;

architecture sim of OBUFT_DCIEN is
  signal gts : std_ulogic := '1';
begin
  toc_p : process
  begin
    toc(gts);
  end process;

  O <= bufif0_val(I, gts or T);
end architecture sim;
