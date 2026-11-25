-- BUFG_PS. Pulse-stretcher style global buffer gated by GSR.
-- I is not passed through buf, so Z stays Z. gwe_latch starts at X and
-- copies ~GSR (or gwe_sync(2) when STARTUP_SYNC stays enabled) while I
-- is 0. O is gwe_latch and I. STARTUP_SYNC is forced off unless
-- SIM_DEVICE is VERSAL*, matching the Verilog correction. An illegal
-- SIM_DEVICE does not $finish; it is not versal.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFG_PS is
  generic (
    SIM_DEVICE : string := "ULTRASCALE_PLUS";
    STARTUP_SYNC : boolean := FALSE
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic
  );
end entity BUFG_PS;

architecture sim of BUFG_PS is
  constant startup : boolean := STARTUP_SYNC and sim_versal(SIM_DEVICE);
  signal gsr : std_ulogic := '1';
  signal i_in, gwe_muxed : std_ulogic;
  signal gwe_latch : std_ulogic := 'X';
  signal gwe_sync : std_ulogic_vector(2 downto 0) := "000";
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  i_in <= I;
  gwe_muxed <= gwe_sync(2) when startup else not gsr;

  shift : process (i_in)
    variable prev : std_ulogic := 'U';
  begin
    if verilog_posedge(prev, i_in) and i_in = '1' then
      gwe_sync <= gwe_sync(1 downto 0) & (not gsr);
    end if;
    prev := i_in;
  end process;

  latch : process (i_in, gwe_muxed)
  begin
    if (not i_in) = '1' then
      gwe_latch <= gwe_muxed;
    end if;
  end process;

  O <= gwe_latch and i_in;
end architecture sim;
