-- DSP_PREADD. AD is D_DATA plus or minus PREADD_AB. INMODE2 selects
-- D_DATA; 0 selects zero. The sum is 27 bits and wraps. No $finish.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DSP_PREADD is
  port (
    AD : out std_logic_vector(26 downto 0);
    ADDSUB : in std_ulogic;
    D_DATA : in std_logic_vector(26 downto 0);
    INMODE2 : in std_ulogic;
    PREADD_AB : in std_logic_vector(26 downto 0)
  );
end entity DSP_PREADD;

architecture sim of DSP_PREADD is
  function binary(s : std_logic_vector) return boolean is
  begin
    for i in s'range loop
      if s(i) /= '0' and s(i) /= '1' then
        return false;
      end if;
    end loop;
    return true;
  end function;
begin
  add : process (ADDSUB, D_DATA, INMODE2, PREADD_AB)
    variable d_mux : std_logic_vector(26 downto 0);
    variable r : unsigned(26 downto 0);
  begin
    if INMODE2 = '1' then
      d_mux := D_DATA;
    elsif INMODE2 = '0' then
      d_mux := (others => '0');
    else
      d_mux := (others => 'X');
    end if;
    if not binary(d_mux) or not binary(PREADD_AB) then
      AD <= (others => 'X');
    elsif ADDSUB = '1' then
      r := unsigned(d_mux) - unsigned(PREADD_AB);
      AD <= std_logic_vector(r);
    elsif ADDSUB = '0' then
      r := unsigned(d_mux) + unsigned(PREADD_AB);
      AD <= std_logic_vector(r);
    else
      AD <= (others => 'X');
    end if;
  end process;
end architecture sim;
