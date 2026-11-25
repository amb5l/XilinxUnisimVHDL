-- SRLC32E. 32-bit shift register. Q is data[A] and Q31 is data(31).
-- A is a vector with A(0) as the LSB. CE of 1 or Z shifts. A non-0/1
-- address bit reads X. The INIT force matches SRL16E. Q31 is combinational
-- on the top bit, not a second address.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity SRLC32E is
  generic (
    INIT : bit_vector(31 downto 0) := X"00000000";
    IS_CLK_INVERTED : bit := '0'
  );
  port (
    Q : out std_ulogic;
    Q31 : out std_ulogic;
    A : in std_logic_vector(4 downto 0);
    CE : in std_ulogic;
    CLK : in std_ulogic;
    D : in std_ulogic
  );
end entity SRLC32E;

architecture sim of SRLC32E is
  signal mem : std_logic_vector(31 downto 0) := to_stdlogicvector(INIT);
begin
  Q <= mem_read(mem, A);
  Q31 <= mem(31);
  shifter : process is
  begin
    srl_run(CLK, CE, D, mem, IS_CLK_INVERTED);
  end process;
end architecture sim;
