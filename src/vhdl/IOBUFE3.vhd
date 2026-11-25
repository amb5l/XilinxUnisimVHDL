-- IOBUFE3. bufif0(IO, I, GTS or T). Delays are 0. ULTRASCALE and
-- ULTRASCALE_PLUS use OSC; every other legal SIM_DEVICE forces OSC
-- and OSC_EN to 0 (the Verilog flag named versal_or_later is 0 for
-- UltraScale). OSC[2:0]*5 is negated when OSC[3] is 0 and compared
-- with SIM_INPUT_BUFFER_OFFSET. A zero difference toggles O_OSC once
-- per OSC/OSC_EN change, and does not free-run. USE_IBUFDISABLE false
-- (the default): O = OSC_EN ? O_OSC : IO. USE true drives 0 only when
-- ~T || IBUFDISABLE is 1 and OSC_EN is 0. VREF and DCITERMDISABLE are
-- not in the functional equation. See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IOBUFE3 is
  generic (
    DRIVE : integer := 12;
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SIM_DEVICE : string := "ULTRASCALE";
    SIM_INPUT_BUFFER_OFFSET : integer := 0;
    USE_IBUFDISABLE : boolean := FALSE
  );
  port (
    O : out std_ulogic;
    IO : inout std_logic;
    DCITERMDISABLE : in std_ulogic;
    I : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    OSC : in std_logic_vector(3 downto 0);
    OSC_EN : in std_ulogic;
    T : in std_ulogic;
    VREF : in std_ulogic
  );
end entity IOBUFE3;

architecture sim of IOBUFE3 is
  signal gts : std_ulogic := '1';
  signal o_osc : std_ulogic := 'X';
  signal osc_m : std_logic_vector(3 downto 0);
  signal en_m : std_ulogic;

  function e3_o(
    nt, en, oscv, pad : std_ulogic;
    use_dis : boolean
  ) return std_ulogic is
  begin
    if not use_dis or nt = '0' then
      return tri_mux(en, oscv, pad);
    elsif nt = '1' and en = '0' then
      return '0';
    else
      return 'X';
    end if;
  end function;
begin
  check : process
  begin
    assert e3_sim_ok(SIM_DEVICE)
      report "IOBUFE3 SIM_DEVICE is not legal" severity failure;
    assert DRIVE >= 2 and DRIVE <= 24
      report "IOBUFE3 DRIVE must be 2 to 24" severity failure;
    assert SIM_INPUT_BUFFER_OFFSET >= -50 and SIM_INPUT_BUFFER_OFFSET <= 50
      report "IOBUFE3 SIM_INPUT_BUFFER_OFFSET must be -50 to 50"
      severity failure;
    wait;
  end process;

  toc_p : process
  begin
    toc(gts);
  end process;

  IO <= bufif0_val(I, gts or T);
  osc_m <= "0000" when not e3_ultra(SIM_DEVICE) else OSC;
  en_m <= '0' when not e3_ultra(SIM_DEVICE) else OSC_EN;

  -- OSC_int starts at 0, so the initial compare ignores the OSC pins.
  -- The always block updates O_OSC only while OSC_EN is 1. level is a
  -- variable so a zero difference toggles once per wake-up and does
  -- not free-run.
  osc_p : process
    variable level : std_ulogic := 'X';
    variable armed : boolean := false;
  begin
    if not armed then
      level := osc_init(SIM_INPUT_BUFFER_OFFSET);
      armed := true;
    end if;
    if en_m = '1' then
      level := osc_step(level, osc_m, true, SIM_INPUT_BUFFER_OFFSET);
    end if;
    o_osc <= level;
    wait on osc_m, en_m;
  end process;

  O <= e3_o(inv1(T) or IBUFDISABLE, en_m, o_osc, IO, USE_IBUFDISABLE);
end architecture sim;
