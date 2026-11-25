-- DSP_M_DATA. One register on the multiplier vectors U and V.
-- MREG 1 selects the registers. GSR or RSTM or MREG 0 clears them.
-- U and V pass through. CEM and RSTM are rv 0. No $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity DSP_M_DATA is
  generic (
    IS_CLK_INVERTED : bit := '0';
    IS_RSTM_INVERTED : bit := '0';
    MREG : integer := 1
  );
  port (
    U_DATA : out std_logic_vector(44 downto 0);
    V_DATA : out std_logic_vector(44 downto 0);
    CEM : in std_ulogic;
    CLK : in std_ulogic;
    RSTM : in std_ulogic;
    U : in std_logic_vector(44 downto 0);
    V : in std_logic_vector(44 downto 0)
  );
end entity DSP_M_DATA;

architecture sim of DSP_M_DATA is
  signal gsr : std_ulogic := '1';
  signal clk_in : std_ulogic;
  signal u_reg, v_reg : std_logic_vector(44 downto 0) := (others => '0');
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  clk_in <= gate_in(CLK, IS_CLK_INVERTED);

  reg : process (gsr, clk_in)
    variable prev : std_ulogic := 'U';
    variable armed : boolean := false;
  begin
    if gsr = '1' then
      u_reg <= (others => '0');
      v_reg <= (others => '0');
    elsif armed and verilog_posedge(prev, clk_in) then
      if gate_in(RSTM, IS_RSTM_INVERTED) = '1' or MREG /= 1 then
        u_reg <= (others => '0');
        v_reg <= (others => '0');
      elsif rv0(CEM) = '1' then
        u_reg <= U;
        v_reg <= V;
      end if;
    end if;
    armed := true;
    prev := clk_in;
  end process;

  U_DATA <= u_reg when MREG = 1 else U;
  V_DATA <= v_reg when MREG = 1 else V;
end architecture sim;
