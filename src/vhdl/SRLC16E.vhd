-- SRLC16E. SRL16E with Q15 = data(15), the bit that shifts out next.
-- CE of 1 or Z shifts. The INIT force and the idle-clock poll match SRL16E.
-- The specify paths are not applied by this NVC.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity SRLC16E is
  generic (
    INIT : bit_vector(15 downto 0) := X"0000";
    IS_CLK_INVERTED : bit := '0'
  );
  port (
    Q : out std_ulogic;
    Q15 : out std_ulogic;
    A0 : in std_ulogic;
    A1 : in std_ulogic;
    A2 : in std_ulogic;
    A3 : in std_ulogic;
    CE : in std_ulogic;
    CLK : in std_ulogic;
    D : in std_ulogic
  );
end entity SRLC16E;

architecture sim of SRLC16E is
  signal mem : std_logic_vector(15 downto 0) := to_stdlogicvector(INIT);
begin
  Q <= mem_read(mem, A3 & A2 & A1 & A0);
  Q15 <= mem(15);
  shifter : process is
  begin
    srl_run(CLK, CE, D, mem, IS_CLK_INVERTED);
  end process;
end architecture sim;
