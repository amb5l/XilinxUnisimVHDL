-- IBUFDSE3. Delays are 0. OSC_EN is two bits: 11 selects O_OSC,
-- 01 and 10 drive X, and anything else is the differential receiver.
-- The oscillator updates only when OSC_EN is 11. ULTRASCALE and
-- ULTRASCALE_PLUS use the OSC pins; every other legal SIM_DEVICE
-- forces them to 0. USE_IBUFDISABLE drives O to 0 when IBUFDISABLE
-- is 1, and to X when IBUFDISABLE is not 0 or 1. DIFF_TERM,
-- IBUF_LOW_PWR and IOSTANDARD are unused.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUFDSE3 is
  generic (
    DIFF_TERM : boolean := FALSE;
    DQS_BIAS : boolean := FALSE;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SIM_DEVICE : string := "ULTRASCALE";
    SIM_INPUT_BUFFER_OFFSET : integer := 0;
    USE_IBUFDISABLE : boolean := FALSE
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic;
    IB : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    OSC : in std_logic_vector(3 downto 0);
    OSC_EN : in std_logic_vector(1 downto 0)
  );
end entity IBUFDSE3;

architecture sim of IBUFDSE3 is
  signal o_osc : std_ulogic := 'X';
  signal q : std_ulogic := 'X';
  signal osc_m : std_logic_vector(3 downto 0);
  signal en_m : std_logic_vector(1 downto 0);
begin
  check : process
  begin
    assert e3_sim_ok(SIM_DEVICE)
      report "IBUFDSE3 SIM_DEVICE is not legal" severity failure;
    assert SIM_INPUT_BUFFER_OFFSET >= -50 and SIM_INPUT_BUFFER_OFFSET <= 50
      report "IBUFDSE3 SIM_INPUT_BUFFER_OFFSET must be -50 to 50"
      severity failure;
    wait;
  end process;

  osc_m <= "0000" when not e3_ultra(SIM_DEVICE) else OSC;
  en_m <= "00" when not e3_ultra(SIM_DEVICE) else OSC_EN;

  osc_p : process
    variable level : std_ulogic := 'X';
    variable armed : boolean := false;
  begin
    if not armed then
      level := osc_init(SIM_INPUT_BUFFER_OFFSET);
      armed := true;
    end if;
    if en_m = "11" then
      level := osc_step(level, osc_m, true, SIM_INPUT_BUFFER_OFFSET);
    end if;
    o_osc <= level;
    wait on osc_m, en_m;
  end process;

  recv : process (I, IB, IBUFDISABLE)
    variable n : std_ulogic;
  begin
    if USE_IBUFDISABLE and IBUFDISABLE = '1' then
      q <= '0';
    elsif (USE_IBUFDISABLE and IBUFDISABLE = '0') or not USE_IBUFDISABLE then
      n := diff_next(q, I, IB, DQS_BIAS, true, true, false);
      if n /= q then
        q <= n;
      end if;
    else
      q <= 'X';
    end if;
  end process;

  O <= o_osc when en_m = "11" else
       'X' when en_m = "10" or en_m = "01" else
       q;
end architecture sim;
