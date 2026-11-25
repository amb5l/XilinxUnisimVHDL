-- OBUFDS_GTE3_ADV. Enable is (not REFCLK_EN_TX_PATH) or GTS or CEB.
-- bufif0 on O and notif0 on OB, from the I bit selected by
-- RXRECCLK_SEL. The default REFCLK generic forces Z.
-- REFCLK_ICNTL_TX is unused.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFDS_GTE3_ADV is
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
end entity OBUFDS_GTE3_ADV;

architecture sim of OBUFDS_GTE3_ADV is
  signal gts : std_ulogic := '1';
  signal en : std_ulogic;
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
  en <= '1' when REFCLK_EN_TX_PATH = '0' else gts or CEB;
  O <= bufif0_val(i_sel, en);
  OB <= notif0_val(i_sel, en);
end architecture sim;
