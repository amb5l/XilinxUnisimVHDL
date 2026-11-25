-- DNA_PORTE2. 96 bits, LSB out first. READ reloads SIM_DNA_VALUE.
-- SHIFT inserts DIN at the MSB. READ wins over SHIFT. The 100 ps
-- CLK-to-DOUT specify path is not copied. A SIM_DNA_VALUE outside
-- the Verilog range does not $finish.

library ieee;
use ieee.std_logic_1164.all;

entity DNA_PORTE2 is
  generic (
    SIM_DNA_VALUE : bit_vector(95 downto 0) := X"000000000000000000000000"
  );
  port (
    DOUT : out std_ulogic;
    CLK : in std_ulogic;
    DIN : in std_ulogic;
    READ : in std_ulogic;
    SHIFT : in std_ulogic
  );
end entity DNA_PORTE2;

architecture sim of DNA_PORTE2 is
  signal dna : std_logic_vector(95 downto 0) := to_stdlogicvector(SIM_DNA_VALUE);
begin
  DOUT <= dna(0);

  sh : process (CLK) is
  begin
    if rising_edge(CLK) then
      if READ = '1' then
        dna <= to_stdlogicvector(SIM_DNA_VALUE);
      elsif SHIFT = '1' then
        dna <= DIN & dna(95 downto 1);
      end if;
    end if;
  end process;
end architecture sim;
