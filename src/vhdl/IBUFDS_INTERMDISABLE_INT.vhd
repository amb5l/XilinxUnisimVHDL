-- IBUFDS_INTERMDISABLE_INT. Disable of 1 drives 1.
-- INTERMDISABLE is unused in the functional model.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUFDS_INTERMDISABLE_INT is
  generic (
    DIFF_TERM : boolean := FALSE;
    DQS_BIAS : boolean := FALSE;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    USE_IBUFDISABLE : boolean := TRUE
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic;
    IB : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    INTERMDISABLE : in std_ulogic
  );
end entity IBUFDS_INTERMDISABLE_INT;

architecture sim of IBUFDS_INTERMDISABLE_INT is
  signal q : std_ulogic := 'X';
begin
  step : process (I, IB)
  begin
    diff_recv(q, I, IB, DQS_BIAS, true);
  end process;

  O <= q when not USE_IBUFDISABLE else
       '1' when IBUFDISABLE = '1' else
       q when IBUFDISABLE = '0' else
       'X';
end architecture sim;
