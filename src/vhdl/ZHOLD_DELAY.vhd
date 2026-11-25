-- ZHOLD_DELAY. Each tap is 200 ps. The delayed nonblocking assign is
-- transport: a pulse shorter than the delay still emerges. DEFAULT and
-- "0" are no delay. An unrecognised tap string is 0 taps and does not
-- $finish. The XIL_TIMING path (1 ps, no tap delay) is not used.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity ZHOLD_DELAY is
  generic (
    IS_DLYIN_INVERTED : bit := '0';
    ZHOLD_FABRIC : string := "DEFAULT";
    ZHOLD_IFF : string := "DEFAULT"
  );
  port (
    DLYFABRIC : out std_ulogic;
    DLYIFF : out std_ulogic;
    DLYIN : in std_ulogic
  );
end entity ZHOLD_DELAY;

architecture sim of ZHOLD_DELAY is
  function taps(s : string) return natural is
    variable n : integer := 0;
    variable digit : integer;
  begin
    if s = "DEFAULT" then
      return 0;
    end if;
    if s'length = 1 or s'length = 2 then
      for i in s'range loop
        digit := character'pos(s(i)) - character'pos('0');
        if digit < 0 or digit > 9 then
          return 0;
        end if;
        n := n * 10 + digit;
      end loop;
      if n <= 31 then
        return n;
      end if;
    end if;
    return 0;
  end function;

  constant fabric_n : natural := taps(ZHOLD_FABRIC);
  constant iff_n : natural := taps(ZHOLD_IFF);
  signal din_i : std_ulogic := '0';
  signal fabric : std_ulogic := '0';
  signal iff : std_ulogic := '0';
begin
  din_i <= vxor(DLYIN, IS_DLYIN_INVERTED);
  fabric <= transport din_i after (200 ps * fabric_n);
  iff <= transport din_i after (200 ps * iff_n);
  DLYFABRIC <= fabric;
  DLYIFF <= iff;
end architecture sim;
