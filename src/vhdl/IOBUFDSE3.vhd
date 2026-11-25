-- IOBUFDSE3. bufif0(IO, I, GTS or T) and notif0(IOB, I, same ts).
-- Delays are 0. OSC_EN is two bits: 11 selects O_OSC, 01 and 10
-- drive X, and anything else (including 00 and X) selects the
-- receiver. The oscillator updates only when OSC_EN == 1, which is
-- the vector 01. USE_IBUFDISABLE true and ~T || IBUFDISABLE == 1
-- forces the receiver to 0; an X flag forces X. === matches X on
-- both pins. DCITERMDISABLE is not in the functional always.
-- See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IOBUFDSE3 is
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
    IO : inout std_logic;
    IOB : inout std_logic;
    DCITERMDISABLE : in std_ulogic;
    I : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    OSC : in std_logic_vector(3 downto 0);
    OSC_EN : in std_logic_vector(1 downto 0);
    T : in std_ulogic
  );
end entity IOBUFDSE3;

architecture sim of IOBUFDSE3 is
  signal gts : std_ulogic := '1';
  signal q : std_ulogic := 'X';
  signal o_osc : std_ulogic := 'X';
  signal osc_m : std_logic_vector(3 downto 0);
  signal en_m : std_logic_vector(1 downto 0);
begin
  check : process
  begin
    assert e3_sim_ok(SIM_DEVICE)
      report "IOBUFDSE3 SIM_DEVICE is not legal" severity failure;
    assert SIM_INPUT_BUFFER_OFFSET >= -50 and SIM_INPUT_BUFFER_OFFSET <= 50
      report "IOBUFDSE3 SIM_INPUT_BUFFER_OFFSET must be -50 to 50"
      severity failure;
    wait;
  end process;

  toc_p : process
  begin
    toc(gts);
  end process;

  IO <= bufif0_val(I, gts or T);
  IOB <= notif0_val(I, gts or T);
  osc_m <= "0000" when not e3_ultra(SIM_DEVICE) else OSC;
  en_m <= "00" when not e3_ultra(SIM_DEVICE) else OSC_EN;

  -- Same oscillator as IOBUFE3, except it updates only when the
  -- two-bit OSC_EN equals 01 (Verilog `== 1`).
  osc_p : process
    variable level : std_ulogic := 'X';
    variable armed : boolean := false;
  begin
    if not armed then
      level := osc_init(SIM_INPUT_BUFFER_OFFSET);
      armed := true;
    end if;
    if en_m = "01" then
      level := osc_step(level, osc_m, true, SIM_INPUT_BUFFER_OFFSET);
    end if;
    o_osc <= level;
    wait on osc_m, en_m;
  end process;

  recv : process (IO, IOB, T, IBUFDISABLE)
    variable nt : std_ulogic;
    variable n : std_ulogic;
  begin
    nt := inv1(T) or IBUFDISABLE;
    if USE_IBUFDISABLE and nt = '1' then
      q <= '0';
    elsif (USE_IBUFDISABLE and nt = '0') or not USE_IBUFDISABLE then
      n := diff_next(q, IO, IOB, DQS_BIAS, true, true, false);
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
