-- BUFGCE. Global buffer with clock enable.
-- CE uses rv 1, then the optional invert (Z stays 1). I is xor'd with
-- IS_I_INVERTED. enable starts at 0. It copies CE while GSR is low and,
-- unless CE_TYPE is ASYNC, only while I is 0. HARDSYNC copies ce_sync(2)
-- instead of CE; that shifter advances on a rising I that lands on 1.
-- STARTUP_SYNC gates the enable with gwe_sync(2) instead of ~GSR, on every
-- SIM_DEVICE (this cell does not force it off). SIM_DEVICE is otherwise
-- unused. An illegal attribute does not $finish; a CE_TYPE other than
-- ASYNC or HARDSYNC behaves as SYNC.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFGCE is
  generic (
    CE_TYPE : string := "SYNC";
    IS_CE_INVERTED : bit := '0';
    IS_I_INVERTED : bit := '0';
    SIM_DEVICE : string := "ULTRASCALE";
    STARTUP_SYNC : boolean := FALSE
  );
  port (
    O : out std_ulogic;
    CE : in std_ulogic;
    I : in std_ulogic
  );
end entity BUFGCE;

architecture sim of BUFGCE is
  signal gsr : std_ulogic := '1';
  signal ce_in, i_in : std_ulogic;
  signal enable_clk : std_ulogic := '0';
  signal gwe_sync, ce_sync : std_ulogic_vector(2 downto 0) := "000";
  signal gwe_muxed, ce_muxed, term, cb : std_ulogic;
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  ce_in <= rv1x(CE, IS_CE_INVERTED);
  i_in <= vxor(I, IS_I_INVERTED);

  gwe_muxed <= gwe_sync(2) when STARTUP_SYNC else not gsr;
  ce_muxed <= ce_sync(2) when CE_TYPE = "HARDSYNC" else ce_in;
  term <= '0' when CE_TYPE = "ASYNC" else i_in;
  cb <= not ((not gwe_muxed) or term);

  shift : process (i_in)
    variable prev : std_ulogic := 'U';
  begin
    if verilog_posedge(prev, i_in) and i_in = '1' then
      gwe_sync <= gwe_sync(1 downto 0) & (not gsr);
      ce_sync <= ce_sync(1 downto 0) & ce_in;
    end if;
    prev := i_in;
  end process;

  en : process (cb, ce_muxed)
  begin
    if cb = '1' then
      enable_clk <= ce_muxed;
    end if;
  end process;

  O <= enable_clk and i_in;
end architecture sim;
