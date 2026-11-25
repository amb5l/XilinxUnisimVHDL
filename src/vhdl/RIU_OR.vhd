-- RIU_OR. Read data is the bitwise or of the two halves. Read valid
-- is the and of the two valids. SIM_DEVICE and SIM_VERSION are checked
-- by the Verilog and are not used. An illegal value does not $finish.

library ieee;
use ieee.std_logic_1164.all;

entity RIU_OR is
  generic (
    SIM_DEVICE : string := "ULTRASCALE";
    SIM_VERSION : real := 2.0
  );
  port (
    RIU_RD_DATA : out std_logic_vector(15 downto 0);
    RIU_RD_VALID : out std_ulogic;
    RIU_RD_DATA_LOW : in std_logic_vector(15 downto 0);
    RIU_RD_DATA_UPP : in std_logic_vector(15 downto 0);
    RIU_RD_VALID_LOW : in std_ulogic;
    RIU_RD_VALID_UPP : in std_ulogic
  );
end entity RIU_OR;

architecture sim of RIU_OR is
begin
  RIU_RD_DATA <= RIU_RD_DATA_UPP or RIU_RD_DATA_LOW;
  RIU_RD_VALID <= RIU_RD_VALID_UPP and RIU_RD_VALID_LOW;
end architecture sim;
