-- DSP_MULTIPLIER. Signed 27 x 18 product, split into the U and V
-- partial-product vectors the ALU adds back together. AMULTSEL "AD"
-- and BMULTSEL "AD" select AD_DATA; every other name selects A2A1 or
-- B2B1. USE_MULT "NONE" forces the product to 0. U(44) is 1 and
-- V(44) is the inverted product sign. Even product bits go to U and
-- odd bits go to V.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DSP_MULTIPLIER is
  generic (
    AMULTSEL : string := "A";
    BMULTSEL : string := "B";
    USE_MULT : string := "MULTIPLY"
  );
  port (
    AMULT26 : out std_ulogic;
    BMULT17 : out std_ulogic;
    U : out std_logic_vector(44 downto 0);
    V : out std_logic_vector(44 downto 0);
    A2A1 : in std_logic_vector(26 downto 0);
    AD_DATA : in std_logic_vector(26 downto 0);
    B2B1 : in std_logic_vector(17 downto 0)
  );
end entity DSP_MULTIPLIER;

architecture sim of DSP_MULTIPLIER is
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
  mult : process (A2A1, AD_DATA, B2B1)
    variable a_mux : std_logic_vector(26 downto 0);
    variable b_mux : std_logic_vector(17 downto 0);
    variable prod : signed(89 downto 0);
    variable low : std_logic_vector(44 downto 0);
    variable ub, vb : std_logic_vector(43 downto 0);
  begin
    if AMULTSEL = "AD" then
      a_mux := AD_DATA;
    else
      a_mux := A2A1;
    end if;
    if BMULTSEL = "AD" then
      b_mux := AD_DATA(17 downto 0);
    else
      b_mux := B2B1;
    end if;
    AMULT26 <= a_mux(26);
    BMULT17 <= b_mux(17);
    if USE_MULT = "NONE" then
      low := (others => '0');
    elsif not binary(a_mux) or not binary(b_mux) then
      low := (others => 'X');
    else
      prod := resize(signed(a_mux), 45) * resize(signed(b_mux), 45);
      low := std_logic_vector(prod(44 downto 0));
    end if;
    for i in 0 to 43 loop
      if i mod 2 = 0 then
        ub(i) := low(i);
        vb(i) := '0';
      else
        ub(i) := '0';
        vb(i) := low(i);
      end if;
    end loop;
    U <= '1' & ub;
    V <= (not low(44)) & vb;
  end process;
end architecture sim;
