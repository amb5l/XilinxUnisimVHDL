-- OBUFDS_GTM_ADV. Same enable as OBUFDS_GTM, driving the I bit
-- selected by the RXRECCLK_SEL generic. Anything other than 00..11
-- selects I(0). REFCLK_ICNTL_TX is unused.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OBUFDS_GTM_ADV is
  generic (
    REFCLK_EN_TX_PATH : bit := '0';
    REFCLK_ICNTL_TX : integer := 0;
    RXRECCLK_SEL : bit_vector(1 downto 0) := "00"
  );
  port (
    O : out std_ulogic;
    OB : out std_ulogic;
    CEB : in std_ulogic;
    I : in std_logic_vector(3 downto 0)
  );
end entity OBUFDS_GTM_ADV;

architecture sim of OBUFDS_GTM_ADV is
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
