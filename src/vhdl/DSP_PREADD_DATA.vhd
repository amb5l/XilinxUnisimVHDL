-- DSP_PREADD_DATA. INMODE picks A1/A2 and B1/B2, and optionally
-- zeros the preadder input. D and AD registers are forced off when
-- both multiplier selects are the direct ports or USE_MULT is NONE.
-- DIN is rv 0. An unknown select falls back to A, B, or MULTIPLY.
-- No $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity DSP_PREADD_DATA is
  generic (
    ADREG : integer := 1;
    AMULTSEL : string := "A";
    BMULTSEL : string := "B";
    DREG : integer := 1;
    INMODEREG : integer := 1;
    IS_CLK_INVERTED : bit := '0';
    IS_INMODE_INVERTED : bit_vector(4 downto 0) := "00000";
    IS_RSTD_INVERTED : bit := '0';
    IS_RSTINMODE_INVERTED : bit := '0';
    PREADDINSEL : string := "A";
    USE_MULT : string := "MULTIPLY"
  );
  port (
    A2A1 : out std_logic_vector(26 downto 0);
    ADDSUB : out std_ulogic;
    AD_DATA : out std_logic_vector(26 downto 0);
    B2B1 : out std_logic_vector(17 downto 0);
    D_DATA : out std_logic_vector(26 downto 0);
    INMODE_2 : out std_ulogic;
    PREADD_AB : out std_logic_vector(26 downto 0);
    A1_DATA : in std_logic_vector(26 downto 0);
    A2_DATA : in std_logic_vector(26 downto 0);
    AD : in std_logic_vector(26 downto 0);
    B1_DATA : in std_logic_vector(17 downto 0);
    B2_DATA : in std_logic_vector(17 downto 0);
    CEAD : in std_ulogic;
    CED : in std_ulogic;
    CEINMODE : in std_ulogic;
    CLK : in std_ulogic;
    DIN : in std_logic_vector(26 downto 0);
    INMODE : in std_logic_vector(4 downto 0);
    RSTD : in std_ulogic;
    RSTINMODE : in std_ulogic
  );
end entity DSP_PREADD_DATA;

architecture sim of DSP_PREADD_DATA is
  signal gsr : std_ulogic := '1';
  signal clk_in : std_ulogic;
  signal inmode_reg : std_logic_vector(4 downto 0) := (others => '0');
  signal d_reg, ad_reg : std_logic_vector(26 downto 0) := (others => '0');
  signal inmode_in : std_logic_vector(4 downto 0);
  signal din_in : std_logic_vector(26 downto 0);
  signal inmode_mux : std_logic_vector(4 downto 0);
  signal a2a1_s : std_logic_vector(26 downto 0);
  signal b2b1_s : std_logic_vector(17 downto 0);
  signal regs_off : boolean;
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  clk_in <= gate_in(CLK, IS_CLK_INVERTED);
  inmode_in <= gate_inv(INMODE, IS_INMODE_INVERTED);
  din_in <= rv0v(DIN);
  regs_off <= (AMULTSEL = "A" and BMULTSEL = "B") or USE_MULT = "NONE";

  reg : process (gsr, clk_in)
    variable prev : std_ulogic := 'U';
    variable armed : boolean := false;
    variable rstd_l, rstin_l : std_ulogic;
  begin
    rstd_l := gate_in(RSTD, IS_RSTD_INVERTED);
    rstin_l := gate_in(RSTINMODE, IS_RSTINMODE_INVERTED);
    if gsr = '1' then
      inmode_reg <= (others => '0');
      d_reg <= (others => '0');
      ad_reg <= (others => '0');
    elsif armed and verilog_posedge(prev, clk_in) then
      if rstin_l = '1' or INMODEREG /= 1 then
        inmode_reg <= (others => '0');
      elsif rv0(CEINMODE) = '1' then
        inmode_reg <= inmode_in;
      end if;
      if rstd_l = '1' or regs_off or DREG /= 1 then
        d_reg <= (others => '0');
      elsif rv0(CED) = '1' then
        d_reg <= din_in;
      end if;
      if rstd_l = '1' then
        ad_reg <= (others => '0');
      elsif rv0(CEAD) = '1' then
        ad_reg <= AD;
      end if;
    end if;
    armed := true;
    prev := clk_in;
  end process;

  inmode_mux <= inmode_reg when INMODEREG = 1 else inmode_in;

  a2a1_s <= (others => '0') when PREADDINSEL /= "B" and inmode_mux(1) = '1' else
            (others => 'X') when PREADDINSEL /= "B" and inmode_mux(1) /= '0' else
            A1_DATA when inmode_mux(0) = '1' else
            A2_DATA when inmode_mux(0) = '0' else
            (others => 'X');
  b2b1_s <= (others => '0') when PREADDINSEL = "B" and inmode_mux(1) = '1' else
            (others => 'X') when PREADDINSEL = "B" and inmode_mux(1) /= '0' else
            B1_DATA when inmode_mux(4) = '1' else
            B2_DATA when inmode_mux(4) = '0' else
            (others => 'X');

  A2A1 <= a2a1_s;
  B2B1 <= b2b1_s;
  ADDSUB <= inmode_mux(3);
  INMODE_2 <= inmode_mux(2);
  pre_ab : process (a2a1_s, b2b1_s)
  begin
    if PREADDINSEL = "B" then
      PREADD_AB(17 downto 0) <= b2b1_s;
      PREADD_AB(26 downto 18) <= (others => b2b1_s(17));
    else
      PREADD_AB <= a2a1_s;
    end if;
  end process;
  D_DATA <= d_reg when (not regs_off and DREG = 1) else din_in;
  AD_DATA <= ad_reg when (not regs_off and ADREG = 1) else AD;
end architecture sim;
