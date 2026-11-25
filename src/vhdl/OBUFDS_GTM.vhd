-- OBUFDS_GTM. Z when the TX path is off, CEB is 1, or GTS is 1.
-- Otherwise O is I (Z passes) and OB is its inverse. CEB of X does
-- not disable. REFCLK_ICNTL_TX is unused and an illegal value does
-- not $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFDS_GTM is
  generic (
    REFCLK_EN_TX_PATH : bit := '0';
    REFCLK_ICNTL_TX : integer := 0
  );
  port (
    O : out std_ulogic;
    OB : out std_ulogic;
    CEB : in std_ulogic;
    I : in std_ulogic
  );
end entity OBUFDS_GTM;

architecture sim of OBUFDS_GTM is
  signal gts : std_ulogic := '1';
  signal off : boolean;
begin
  toc_p : process
  begin
    toc(gts);
  end process;

  off <= REFCLK_EN_TX_PATH = '0' or CEB = '1' or gts = '1';
  O <= 'Z' when off else I;
  OB <= 'Z' when off else inv1(I);
end architecture sim;
