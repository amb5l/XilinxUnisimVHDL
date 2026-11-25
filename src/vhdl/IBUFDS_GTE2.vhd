-- IBUFDS_GTE2. O is I & ~CEB, and it updates only when I changes.
-- ODIV2 is the divider flag sampled on the previous rising edge.
-- Only CEB 0 advances the count; a flag that is already 1 still
-- clears on the next rising edge. CLKCM_CFG, CLKRCV_TRST and
-- CLKSWING_CFG are not used, and an illegal value does not $finish.
-- IB is unused. The 100 ps specify path is under XIL_TIMING.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUFDS_GTE2 is
  generic (
    CLKCM_CFG : boolean := true;
    CLKRCV_TRST : boolean := true;
    CLKSWING_CFG : bit_vector(1 downto 0) := "11"
  );
  port (
    O : out std_ulogic;
    ODIV2 : out std_ulogic := '0';
    CEB : in std_ulogic;
    I : in std_ulogic;
    IB : in std_ulogic
  );
end entity IBUFDS_GTE2;

architecture sim of IBUFDS_GTE2 is
  signal edge_count : integer range 0 to 7 := 0;
  signal all_equal : std_ulogic := '0';
begin
  -- Sensitive to I only, matching always @(I).
  o_p : process (I)
  begin
    O <= I and (not CEB);
  end process;

  count : process (I)
    variable prev : std_ulogic := 'X';
  begin
    if verilog_posedge(prev, I) then
      ODIV2 <= all_equal;
      if all_equal = '1' then
        edge_count <= 0;
      elsif CEB = '0' then
        edge_count <= edge_count + 1;
      end if;
    end if;
    prev := I;
  end process;

  all_equal <= '1' when edge_count = 1 else '0';
end architecture sim;
