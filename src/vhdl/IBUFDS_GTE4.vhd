-- IBUFDS_GTE4. O is I when the TX path is off and CEB is not 1.
-- Z and X on I become X. ODIV2 follows O, toggles every rising edge
-- of I, or stays 0, from REFCLK_HROW_CK_SEL. CEB of 0 or Z lets the
-- divider count. IB and REFCLK_ICNTL_RX are unused. The 100 ps
-- specify path is not copied.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUFDS_GTE4 is
  generic (
    REFCLK_EN_TX_PATH : bit := '0';
    REFCLK_HROW_CK_SEL : bit_vector(1 downto 0) := "00";
    REFCLK_ICNTL_RX : bit_vector(1 downto 0) := "00"
  );
  port (
    O : out std_ulogic;
    ODIV2 : out std_ulogic;
    CEB : in std_ulogic;
    I : in std_ulogic;
    IB : in std_ulogic
  );
end entity IBUFDS_GTE4;

architecture sim of IBUFDS_GTE4 is
  signal edge_count : integer range 0 to 7 := 0;
  signal all_equal : std_ulogic := '0';
  signal o_bit : std_ulogic;
begin
  o_bit <= '0' when REFCLK_EN_TX_PATH = '1' or CEB = '1' else (I and '1');
  O <= o_bit;

  count : process (I)
    variable prev : std_ulogic := 'X';
  begin
    if verilog_posedge(prev, I) then
      if all_equal = '1' then
        edge_count <= 0;
      elsif CEB = '0' or CEB = 'Z' then
        edge_count <= edge_count + 1;
      end if;
    end if;
    prev := I;
  end process;

  all_equal <= '1' when edge_count = 1 else '0';

  ODIV2 <= o_bit when REFCLK_HROW_CK_SEL = "00" else
           all_equal when REFCLK_HROW_CK_SEL = "01" else
           '0';
end architecture sim;
