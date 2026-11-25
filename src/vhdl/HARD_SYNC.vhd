-- HARD_SYNC. Two or three registers. GSR loads INIT for the default
-- 100 ns ROC. A LATENCY other than 2 or 3 behaves as 2. The 100 ps
-- specify path is not copied. An illegal LATENCY does not $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity HARD_SYNC is
  generic (
    INIT : bit := '0';
    IS_CLK_INVERTED : bit := '0';
    LATENCY : integer := 2
  );
  port (
    DOUT : out std_ulogic;
    CLK : in std_ulogic;
    DIN : in std_ulogic
  );
end entity HARD_SYNC;

architecture sim of HARD_SYNC is
  signal gsr : std_ulogic := '1';
  signal din_reg : std_ulogic_vector(2 downto 0) := "XXX";
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  ff : process (gsr, CLK)
    variable prev : std_ulogic := 'X';
    variable clk_i : std_ulogic;
  begin
    if gsr = '1' then
      din_reg <= (others => to_sul(INIT));
    else
      clk_i := xor_inv(CLK, IS_CLK_INVERTED);
      if verilog_posedge(prev, clk_i) then
        din_reg <= din_reg(1 downto 0) & DIN;
      end if;
    end if;
    prev := xor_inv(CLK, IS_CLK_INVERTED);
  end process;

  -- (latency == 3) && bit2 || (latency == 2) && bit1. && turns Z into X.
  DOUT <= (din_reg(2) and '1') when LATENCY = 3 else (din_reg(1) and '1');
end architecture sim;
