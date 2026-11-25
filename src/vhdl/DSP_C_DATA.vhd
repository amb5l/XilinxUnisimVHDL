-- DSP_C_DATA. One register on C. CREG 1 selects the register; any
-- other value passes C through and the clock clears the register.
-- C is rv 1. CEC and RSTC are rv 0. GSR clears the register. No $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity DSP_C_DATA is
  generic (
    CREG : integer := 1;
    IS_CLK_INVERTED : bit := '0';
    IS_RSTC_INVERTED : bit := '0'
  );
  port (
    C_DATA : out std_logic_vector(47 downto 0);
    C : in std_logic_vector(47 downto 0);
    CEC : in std_ulogic;
    CLK : in std_ulogic;
    RSTC : in std_ulogic
  );
end entity DSP_C_DATA;

architecture sim of DSP_C_DATA is
  signal gsr : std_ulogic := '1';
  signal clk_in : std_ulogic;
  signal c_reg : std_logic_vector(47 downto 0) := (others => '0');
  signal c_in : std_logic_vector(47 downto 0);
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  clk_in <= gate_in(CLK, IS_CLK_INVERTED);
  c_in <= rv1v(C);

  reg : process (gsr, clk_in)
    variable prev : std_ulogic := 'U';
    variable armed : boolean := false;
  begin
    if gsr = '1' then
      c_reg <= (others => '0');
    elsif armed and verilog_posedge(prev, clk_in) then
      if gate_in(RSTC, IS_RSTC_INVERTED) = '1' or CREG /= 1 then
        c_reg <= (others => '0');
      elsif rv0(CEC) = '1' then
        c_reg <= c_in;
      end if;
    end if;
    armed := true;
    prev := clk_in;
  end process;

  C_DATA <= c_reg when CREG = 1 else c_in;
end architecture sim;
