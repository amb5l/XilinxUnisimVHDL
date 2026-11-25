-- OBUFDS_GTE4. Z when REFCLK is off, CEB is 1, or GTS is 1.
-- Otherwise O is I (Z passes) and OB is not I. CEB of X does not disable.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFDS_GTE4 is
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
end entity OBUFDS_GTE4;

architecture sim of OBUFDS_GTE4 is
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
