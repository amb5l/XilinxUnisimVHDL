-- DNA_PORT. 57 bits, MSB out first. READ reloads SIM_DNA_VALUE.
-- SHIFT appends DIN at the LSB. READ wins over SHIFT. GSR has no
-- effect in the Verilog. The 100 ps CLK-to-DOUT specify path is not
-- copied. An unused shift does not $finish.

library ieee;
use ieee.std_logic_1164.all;

entity DNA_PORT is
  generic (
    SIM_DNA_VALUE : bit_vector(56 downto 0) := "000000000000000000000000000000000000000000000000000000000"
  );
  port (
    DOUT : out std_ulogic;
    CLK : in std_ulogic;
    DIN : in std_ulogic;
    READ : in std_ulogic;
    SHIFT : in std_ulogic
  );
end entity DNA_PORT;

architecture sim of DNA_PORT is
  signal dna : std_logic_vector(56 downto 0) := to_stdlogicvector(SIM_DNA_VALUE);
begin
  DOUT <= dna(56);

  sh : process (CLK) is
  begin
    if rising_edge(CLK) then
      if READ = '1' then
        dna <= to_stdlogicvector(SIM_DNA_VALUE);
      elsif SHIFT = '1' then
        dna <= dna(55 downto 0) & DIN;
      end if;
    end if;
  end process;
end architecture sim;
