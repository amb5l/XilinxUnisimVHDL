-- IBUF. Functional model is a buf (Z maps to X). The string generics are
-- checked the way the Verilog initial block checks them. IBUF_LOW_PWR is
-- boolean, so it has no illegal value. This pin has no IBUFG.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity IBUF is
  generic (
    CAPACITANCE : string := "DONT_CARE";
    IBUF_DELAY_VALUE : string := "0";
    IBUF_LOW_PWR : boolean := TRUE;
    IFD_DELAY_VALUE : string := "AUTO";
    IOSTANDARD : string := "DEFAULT"
  );
  port (
    O : out std_ulogic;
    I : in std_ulogic
  );
end entity IBUF;

architecture sim of IBUF is
begin
  check : process
    function delay_ok(s : string; hi : natural) return boolean is
    begin
      for n in 0 to hi loop
        if s = integer'image(n) then
          return true;
        end if;
      end loop;
      return false;
    end function;
  begin
    assert CAPACITANCE = "LOW" or CAPACITANCE = "NORMAL" or CAPACITANCE = "DONT_CARE"
      report "IBUF CAPACITANCE must be LOW, NORMAL, or DONT_CARE" severity failure;
    assert delay_ok(IBUF_DELAY_VALUE, 16)
      report "IBUF IBUF_DELAY_VALUE must be 0..16" severity failure;
    assert IFD_DELAY_VALUE = "AUTO" or delay_ok(IFD_DELAY_VALUE, 8)
      report "IBUF IFD_DELAY_VALUE must be AUTO or 0..8" severity failure;
    wait;
  end process;

  O <= buf1(I);
end architecture sim;
