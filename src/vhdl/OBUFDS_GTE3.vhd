-- OBUFDS_GTE3. Enable is (not REFCLK_EN_TX_PATH) or GTS or CEB.
-- bufif0 on O, notif0 on OB. The default REFCLK generic forces Z.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFDS_GTE3 is
  generic (
    REFCLK_EN_TX_PATH : bit := '0';
    REFCLK_ICNTL_TX : bit_vector(4 downto 0) := "00000"
  );
  port (
    O : out std_ulogic;
    OB : out std_ulogic;
    CEB : in std_ulogic;
    I : in std_ulogic
  );
end entity OBUFDS_GTE3;

architecture sim of OBUFDS_GTE3 is
  signal gts : std_ulogic := '1';
  signal en : std_ulogic;
begin
  toc_p : process
  begin
    toc(gts);
  end process;

  en <= '1' when REFCLK_EN_TX_PATH = '0' else gts or CEB;
  O <= bufif0_val(I, en);
  OB <= notif0_val(I, en);
end architecture sim;
