-- IBUFE3. Delays are 0. ULTRASCALE and ULTRASCALE_PLUS use OSC;
-- every other legal SIM_DEVICE forces OSC and OSC_EN to 0.
-- USE_IBUFDISABLE false (the default): O is O_OSC when OSC_EN is 1,
-- otherwise I. USE true drives 0 when IBUFDISABLE is 1 and OSC_EN is
-- 0. OSC_EN of 1, X or Z with IBUFDISABLE 1 drives X. A zero
-- offset difference toggles once per change and does not free-run. VREF is unused. An illegal
-- SIM_DEVICE or offset fails; the Verilog would $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUFE3 is
  generic (
    IBUF_LOW_PWR : boolean := TRUE;
    IOSTANDARD : string := "DEFAULT";
    SIM_DEVICE : string := "ULTRASCALE";
    SIM_INPUT_BUFFER_OFFSET : integer := 0;
    USE_IBUFDISABLE : boolean := FALSE
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic;
    IBUFDISABLE : in std_ulogic;
    OSC : in std_logic_vector(3 downto 0);
    OSC_EN : in std_ulogic;
    VREF : in std_ulogic
  );
end entity IBUFE3;

architecture sim of IBUFE3 is
  signal o_osc : std_ulogic := 'X';
  signal osc_m : std_logic_vector(3 downto 0);
  signal en_m : std_ulogic;

  function ibufe3_o(
    dis, en, oscv, i : std_ulogic;
    use_dis : boolean
  ) return std_ulogic is
  begin
    if not use_dis or dis = '0' then
      return tri_mux(en, oscv, i);
    elsif dis = '1' and en = '0' then
      return '0';
    else
      return 'X';
    end if;
  end function;
begin
  check : process
  begin
    assert e3_sim_ok(SIM_DEVICE)
      report "IBUFE3 SIM_DEVICE is not legal" severity failure;
    assert SIM_INPUT_BUFFER_OFFSET >= -50 and SIM_INPUT_BUFFER_OFFSET <= 50
      report "IBUFE3 SIM_INPUT_BUFFER_OFFSET must be -50 to 50"
      severity failure;
    wait;
  end process;

  osc_m <= "0000" when not e3_ultra(SIM_DEVICE) else OSC;
  en_m <= '0' when not e3_ultra(SIM_DEVICE) else OSC_EN;

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

  O <= ibufe3_o(IBUFDISABLE, en_m, o_osc, I, USE_IBUFDISABLE);
end architecture sim;
