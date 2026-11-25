-- EFUSE_USR. The eFUSE value is the generic. There is no timing path.

library ieee;
use ieee.std_logic_1164.all;

entity EFUSE_USR is
  generic (
    SIM_EFUSE_VALUE : bit_vector(31 downto 0) := X"00000000"
  );
  port (
    EFUSEUSR : out std_logic_vector(31 downto 0)
  );
end entity EFUSE_USR;

architecture sim of EFUSE_USR is
begin
  EFUSEUSR <= to_stdlogicvector(SIM_EFUSE_VALUE);
end architecture sim;
