-- INBUF. The SIMPRIM $finish under `ifndef XIL_TIMING` is not part of
-- the model. O follows PAD unless OSC_EN is 1, which selects the offset
-- oscillator. OSC_int starts at 0, so the initial compare ignores OSC.
-- A later wake-up with OSC_EN === 1 applies OSC[2:0] * 5, negated when
-- OSC[3] is 0. A difference of 0 toggles. X or Z on OSC[2:0] holds.
-- VREF, IBUF_LOW_PWR, and ISTANDARD are unused. glbl.GSR is unused.
-- An out-of-range SIM_INPUT_BUFFER_OFFSET makes the Verilog $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity INBUF is
  generic (
    IBUF_LOW_PWR : boolean := TRUE;
    ISTANDARD : string := "UNUSED";
    SIM_INPUT_BUFFER_OFFSET : integer := 0
  );
  port (
    O : out std_ulogic;
    OSC : in std_logic_vector(3 downto 0);
    OSC_EN : in std_ulogic;
    PAD : in std_ulogic;
    VREF : in std_ulogic
  );
end entity INBUF;

architecture sim of INBUF is
  signal o_osc : std_ulogic := 'X';
begin
  check : process is
  begin
    assert SIM_INPUT_BUFFER_OFFSET >= -50 and SIM_INPUT_BUFFER_OFFSET <= 50
      report "INBUF SIM_INPUT_BUFFER_OFFSET must be -50 to 50"
      severity failure;
    wait;
  end process;

  -- OSC_int starts at 0. The always block updates only while OSC_EN is 1.
  -- level is a variable so a zero difference toggles once per wake-up.
  osc_p : process is
    variable level : std_ulogic := 'X';
    variable armed : boolean := false;
  begin
    if not armed then
      level := osc_init(SIM_INPUT_BUFFER_OFFSET);
      armed := true;
    end if;
    if OSC_EN = '1' then
      level := osc_step(level, OSC, true, SIM_INPUT_BUFFER_OFFSET);
    end if;
    o_osc <= level;
    wait on OSC, OSC_EN;
  end process;

  O <= o_osc when OSC_EN = '1' else PAD;
end architecture sim;
