-- SRL16E. 16-bit shift register addressed as a LUT.
-- Q is data[{A3,A2,A1,A0}]. data(0) is the bit most recently shifted in.
-- A non-0/1 address bit reads X. CE of 1 or Z shifts; CE of 0 or X does not.
-- The Verilog forces INIT until CLK has been seen at its idle level by a
-- 1 ns poll, or until 101 ns. The specify (CLK => Q) = 100 ps is not
-- applied by this NVC, so Q updates on the shift.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity SRL16E is
  generic (
    INIT : bit_vector(15 downto 0) := X"0000";
    IS_CLK_INVERTED : bit := '0'
  );
  port (
    Q : out std_ulogic;
    A0 : in std_ulogic;
    A1 : in std_ulogic;
    A2 : in std_ulogic;
    A3 : in std_ulogic;
    CE : in std_ulogic;
    CLK : in std_ulogic;
    D : in std_ulogic
  );
end entity SRL16E;

architecture sim of SRL16E is
  signal mem : std_logic_vector(15 downto 0) := to_stdlogicvector(INIT);
begin
  Q <= mem_read(mem, A3 & A2 & A1 & A0);
  shifter : process is
  begin
    srl_run(CLK, CE, D, mem, IS_CLK_INVERTED);
  end process;
end architecture sim;
