-- DIFFINBUF. The SIMPRIM $finish under `ifndef XIL_TIMING` is not part
-- of the model. The receiver matches IBUFDS: 1/0 yields 1, 0/1 yields 0,
-- a Z/0 with a Z/1 yields 0 when DQS_BIAS is true and X otherwise, and an
-- X yields X. Any other pair holds, starting at X, until an input event.
-- OSC_EN of 11 selects the offset oscillator (O_B is its complement path),
-- 01 or 10 drives X, and every other value selects the receiver.
-- The oscillator uses the same offset rule as INBUF, on both outputs.
-- VREF, DIFF_TERM, IBUF_LOW_PWR, and ISTANDARD are unused. glbl.GSR is unused.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity DIFFINBUF is
  generic (
    DIFF_TERM : boolean := FALSE;
    DQS_BIAS : boolean := FALSE;
    IBUF_LOW_PWR : boolean := TRUE;
    ISTANDARD : string := "UNUSED";
    SIM_INPUT_BUFFER_OFFSET : integer := 0
  );
  port (
    O : out std_ulogic;
    O_B : out std_ulogic;
    DIFF_IN_N : in std_ulogic;
    DIFF_IN_P : in std_ulogic;
    OSC : in std_logic_vector(3 downto 0);
    OSC_EN : in std_logic_vector(1 downto 0);
    VREF : in std_ulogic
  );
end entity DIFFINBUF;

architecture sim of DIFFINBUF is
  signal o_diff, ob_diff : std_ulogic := 'X';
  signal o_osc, ob_osc : std_ulogic := 'X';
begin
  check : process is
  begin
    assert SIM_INPUT_BUFFER_OFFSET >= -50 and SIM_INPUT_BUFFER_OFFSET <= 50
      report "DIFFINBUF SIM_INPUT_BUFFER_OFFSET must be -50 to 50"
      severity failure;
    wait;
  end process;

  diff : process is
  begin
    wait on DIFF_IN_P, DIFF_IN_N;
    if DIFF_IN_P = '1' and DIFF_IN_N = '0' then
      o_diff <= '1';
      ob_diff <= '0';
    elsif DIFF_IN_P = '0' and DIFF_IN_N = '1' then
      o_diff <= '0';
      ob_diff <= '1';
    elsif (DIFF_IN_P = 'Z' or DIFF_IN_P = '0')
          and (DIFF_IN_N = 'Z' or DIFF_IN_N = '1') then
      if DQS_BIAS then
        o_diff <= '0';
        ob_diff <= '1';
      else
        o_diff <= 'X';
        ob_diff <= 'X';
      end if;
    elsif DIFF_IN_P = 'X' or DIFF_IN_N = 'X' then
      o_diff <= 'X';
      ob_diff <= 'X';
    end if;
  end process;

  -- O_B is the complement of O, including X. A difference below 0 drives
  -- 0/1, above 0 drives 1/0, and zero toggles both.
  osc_p : process is
    variable level : std_ulogic := 'X';
    variable armed : boolean := false;
  begin
    if not armed then
      level := osc_init(SIM_INPUT_BUFFER_OFFSET);
      armed := true;
    end if;
    if OSC_EN = "11" then
      level := osc_step(level, OSC, true, SIM_INPUT_BUFFER_OFFSET);
    end if;
    o_osc <= level;
    ob_osc <= inv1(level);
    wait on OSC, OSC_EN;
  end process;

  O <= o_osc when OSC_EN = "11" else
       'X' when OSC_EN = "10" or OSC_EN = "01" else
       o_diff;
  O_B <= ob_osc when OSC_EN = "11" else
         'X' when OSC_EN = "10" or OSC_EN = "01" else
         ob_diff;
end architecture sim;
