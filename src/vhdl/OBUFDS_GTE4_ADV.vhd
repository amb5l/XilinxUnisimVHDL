-- OBUFDS_GTE4_ADV. Z when the TX path is off, CEB is 1, or GTS is 1.
-- Otherwise O is the selected I bit (Z passes) and OB is its inverse.
-- CEB of X does not disable. REFCLK_ICNTL_TX is unused.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFDS_GTE4_ADV is
  generic (
    REFCLK_EN_TX_PATH : bit := '0';
    REFCLK_ICNTL_TX : bit_vector(4 downto 0) := "00000"
  );
  port (
    O : out std_ulogic;
    OB : out std_ulogic;
    CEB : in std_ulogic;
    I : in std_logic_vector(3 downto 0);
    RXRECCLK_SEL : in std_logic_vector(1 downto 0)
  );
end entity OBUFDS_GTE4_ADV;

architecture sim of OBUFDS_GTE4_ADV is
  signal gts : std_ulogic := '1';
  signal off : boolean;
  signal i_sel : std_ulogic;
begin
  toc_p : process
  begin
    toc(gts);
  end process;

  i_sel <= I(0) when RXRECCLK_SEL = "00" else
           I(1) when RXRECCLK_SEL = "01" else
           I(2) when RXRECCLK_SEL = "10" else
           I(3) when RXRECCLK_SEL = "11" else
           I(0);
  off <= REFCLK_EN_TX_PATH = '0' or CEB = '1' or gts = '1';
  O <= 'Z' when off else i_sel;
  OB <= 'Z' when off else inv1(i_sel);
end architecture sim;
