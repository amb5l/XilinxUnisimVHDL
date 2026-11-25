-- DSP_A_B_DATA. Two-deep A and B input registers. AREG/BREG of 0
-- passes the port (or the cascade) through. 2 clocks stage 1 into
-- stage 2. 1 clocks the port into stage 2 only. ACASCREG equal to
-- AREG selects A_ALU for ACOUT, otherwise stage 1. A and B are rv 1.
-- Cascade inputs pass through. An unknown A_INPUT or B_INPUT is DIRECT.
-- The AREG/ACASCREG legality check does not $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity DSP_A_B_DATA is
  generic (
    ACASCREG : integer := 1;
    AREG : integer := 1;
    A_INPUT : string := "DIRECT";
    BCASCREG : integer := 1;
    BREG : integer := 1;
    B_INPUT : string := "DIRECT";
    IS_CLK_INVERTED : bit := '0';
    IS_RSTA_INVERTED : bit := '0';
    IS_RSTB_INVERTED : bit := '0'
  );
  port (
    A1_DATA : out std_logic_vector(26 downto 0);
    A2_DATA : out std_logic_vector(26 downto 0);
    ACOUT : out std_logic_vector(29 downto 0);
    A_ALU : out std_logic_vector(29 downto 0);
    B1_DATA : out std_logic_vector(17 downto 0);
    B2_DATA : out std_logic_vector(17 downto 0);
    BCOUT : out std_logic_vector(17 downto 0);
    B_ALU : out std_logic_vector(17 downto 0);
    A : in std_logic_vector(29 downto 0);
    ACIN : in std_logic_vector(29 downto 0);
    B : in std_logic_vector(17 downto 0);
    BCIN : in std_logic_vector(17 downto 0);
    CEA1 : in std_ulogic;
    CEA2 : in std_ulogic;
    CEB1 : in std_ulogic;
    CEB2 : in std_ulogic;
    CLK : in std_ulogic;
    RSTA : in std_ulogic;
    RSTB : in std_ulogic
  );
end entity DSP_A_B_DATA;

architecture sim of DSP_A_B_DATA is
  signal gsr : std_ulogic := '1';
  signal clk_in : std_ulogic;
  signal a1_reg, a2_reg : std_logic_vector(29 downto 0) := (others => '0');
  signal b1_reg, b2_reg : std_logic_vector(17 downto 0) := (others => '0');
  signal a_in : std_logic_vector(29 downto 0);
  signal b_in : std_logic_vector(17 downto 0);
  signal a_alu_s : std_logic_vector(29 downto 0);
  signal b2_data_s : std_logic_vector(17 downto 0);
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  clk_in <= gate_in(CLK, IS_CLK_INVERTED);
  a_in <= rv1v(A);
  b_in <= rv1v(B);

  reg : process (gsr, clk_in)
    variable prev : std_ulogic := 'U';
    variable armed : boolean := false;
    variable rsta_l, rstb_l : std_ulogic;
  begin
    rsta_l := gate_in(RSTA, IS_RSTA_INVERTED);
    rstb_l := gate_in(RSTB, IS_RSTB_INVERTED);
    if gsr = '1' then
      a1_reg <= (others => '0');
      a2_reg <= (others => '0');
      b1_reg <= (others => '0');
      b2_reg <= (others => '0');
    elsif armed and verilog_posedge(prev, clk_in) then
      if rsta_l = '1' or AREG = 0 then
        a2_reg <= (others => '0');
      elsif rv0(CEA2) = '1' then
        if AREG = 2 then
          a2_reg <= a1_reg;
        elsif A_INPUT = "CASCADE" then
          a2_reg <= ACIN;
        else
          a2_reg <= a_in;
        end if;
      end if;
      if rsta_l = '1' or AREG = 0 then
        a1_reg <= (others => '0');
      elsif rv0(CEA1) = '1' then
        if A_INPUT = "CASCADE" then
          a1_reg <= ACIN;
        else
          a1_reg <= a_in;
        end if;
      end if;
      if rstb_l = '1' then
        b2_reg <= (others => '0');
      elsif rv0(CEB2) = '1' then
        if BREG = 2 then
          b2_reg <= b1_reg;
        elsif B_INPUT = "CASCADE" then
          b2_reg <= BCIN;
        else
          b2_reg <= b_in;
        end if;
      end if;
      if rstb_l = '1' or BREG = 0 then
        b1_reg <= (others => '0');
      elsif rv0(CEB1) = '1' then
        if B_INPUT = "CASCADE" then
          b1_reg <= BCIN;
        else
          b1_reg <= b_in;
        end if;
      end if;
    end if;
    armed := true;
    prev := clk_in;
  end process;

  a_alu_s <= a2_reg when AREG /= 0 else
             ACIN when A_INPUT = "CASCADE" else
             a_in;
  b2_data_s <= b2_reg when BREG /= 0 else
               BCIN when B_INPUT = "CASCADE" else
               b_in;

  A_ALU <= a_alu_s;
  A2_DATA <= a_alu_s(26 downto 0);
  A1_DATA <= a1_reg(26 downto 0);
  ACOUT <= a_alu_s when ACASCREG = AREG else a1_reg;
  B1_DATA <= b1_reg;
  B2_DATA <= b2_data_s;
  B_ALU <= b2_data_s;
  BCOUT <= b2_data_s when BCASCREG = BREG else b1_reg;
end architecture sim;
