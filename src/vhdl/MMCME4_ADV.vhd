-- MMCME4_ADV. Same integer clock path as MMCME2_ADV. The VCO minimum
-- in the Verilog is 800 MHz; this model does not check that range and
-- does not $finish. CDDCDONE stays 0.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity MMCME4_ADV is
  generic (
    BANDWIDTH : string := "OPTIMIZED";
    CLKFBOUT_MULT_F : real := 5.000;
    CLKFBOUT_PHASE : real := 0.000;
    CLKFBOUT_USE_FINE_PS : boolean := FALSE;
    CLKIN1_PERIOD : real := 0.000;
    CLKIN2_PERIOD : real := 0.000;
    CLKOUT0_DIVIDE_F : real := 1.000;
    CLKOUT0_DUTY_CYCLE : real := 0.500;
    CLKOUT0_PHASE : real := 0.000;
    CLKOUT0_USE_FINE_PS : boolean := FALSE;
    CLKOUT1_DIVIDE : integer := 1;
    CLKOUT1_DUTY_CYCLE : real := 0.500;
    CLKOUT1_PHASE : real := 0.000;
    CLKOUT1_USE_FINE_PS : boolean := FALSE;
    CLKOUT2_DIVIDE : integer := 1;
    CLKOUT2_DUTY_CYCLE : real := 0.500;
    CLKOUT2_PHASE : real := 0.000;
    CLKOUT2_USE_FINE_PS : boolean := FALSE;
    CLKOUT3_DIVIDE : integer := 1;
    CLKOUT3_DUTY_CYCLE : real := 0.500;
    CLKOUT3_PHASE : real := 0.000;
    CLKOUT3_USE_FINE_PS : boolean := FALSE;
    CLKOUT4_CASCADE : boolean := FALSE;
    CLKOUT4_DIVIDE : integer := 1;
    CLKOUT4_DUTY_CYCLE : real := 0.500;
    CLKOUT4_PHASE : real := 0.000;
    CLKOUT4_USE_FINE_PS : boolean := FALSE;
    CLKOUT5_DIVIDE : integer := 1;
    CLKOUT5_DUTY_CYCLE : real := 0.500;
    CLKOUT5_PHASE : real := 0.000;
    CLKOUT5_USE_FINE_PS : boolean := FALSE;
    CLKOUT6_DIVIDE : integer := 1;
    CLKOUT6_DUTY_CYCLE : real := 0.500;
    CLKOUT6_PHASE : real := 0.000;
    CLKOUT6_USE_FINE_PS : boolean := FALSE;
    COMPENSATION : string := "AUTO";
    DIVCLK_DIVIDE : integer := 1;
    IS_CLKFBIN_INVERTED : bit := '0';
    IS_CLKIN1_INVERTED : bit := '0';
    IS_CLKIN2_INVERTED : bit := '0';
    IS_CLKINSEL_INVERTED : bit := '0';
    IS_PSEN_INVERTED : bit := '0';
    IS_PSINCDEC_INVERTED : bit := '0';
    IS_PWRDWN_INVERTED : bit := '0';
    IS_RST_INVERTED : bit := '0';
    REF_JITTER1 : real := 0.010;
    REF_JITTER2 : real := 0.010;
    SS_EN : boolean := FALSE;
    SS_MODE : string := "CENTER_HIGH";
    SS_MOD_PERIOD : integer := 10000;
    STARTUP_WAIT : boolean := FALSE
  );
  port (
    CDDCDONE : out std_ulogic;
    CLKFBOUT : out std_ulogic;
    CLKFBOUTB : out std_ulogic;
    CLKFBSTOPPED : out std_ulogic;
    CLKINSTOPPED : out std_ulogic;
    CLKOUT0 : out std_ulogic;
    CLKOUT0B : out std_ulogic;
    CLKOUT1 : out std_ulogic;
    CLKOUT1B : out std_ulogic;
    CLKOUT2 : out std_ulogic;
    CLKOUT2B : out std_ulogic;
    CLKOUT3 : out std_ulogic;
    CLKOUT3B : out std_ulogic;
    CLKOUT4 : out std_ulogic;
    CLKOUT5 : out std_ulogic;
    CLKOUT6 : out std_ulogic;
    DO : out std_logic_vector(15 downto 0);
    DRDY : out std_ulogic;
    LOCKED : out std_ulogic;
    PSDONE : out std_ulogic;
    CDDCREQ : in std_ulogic;
    CLKFBIN : in std_ulogic;
    CLKIN1 : in std_ulogic;
    CLKIN2 : in std_ulogic;
    CLKINSEL : in std_ulogic;
    DADDR : in std_logic_vector(6 downto 0);
    DCLK : in std_ulogic;
    DEN : in std_ulogic;
    DI : in std_logic_vector(15 downto 0);
    DWE : in std_ulogic;
    PSCLK : in std_ulogic;
    PSEN : in std_ulogic;
    PSINCDEC : in std_ulogic;
    PWRDWN : in std_ulogic;
    RST : in std_ulogic
  );
end entity MMCME4_ADV;

architecture sim of MMCME4_ADV is
  signal fb_i, in1_i, in2_i : std_ulogic;
begin
  CDDCDONE <= '0';
  CLKFBSTOPPED <= '0';
  CLKINSTOPPED <= '0';
  DO <= (others => '0');
  DRDY <= '0';
  PSDONE <= '0';
  fb_i <= xor_inv(CLKFBIN, IS_CLKFBIN_INVERTED);
  in1_i <= xor_inv(CLKIN1, IS_CLKIN1_INVERTED);
  in2_i <= xor_inv(CLKIN2, IS_CLKIN2_INVERTED);

  u : entity unisim.mmcm_core
    generic map (
      CLKFBOUT_MULT_F => CLKFBOUT_MULT_F,
      CLKOUT0_DIVIDE_F => CLKOUT0_DIVIDE_F,
      CLKOUT1_DIVIDE => CLKOUT1_DIVIDE,
      CLKOUT2_DIVIDE => CLKOUT2_DIVIDE,
      CLKOUT3_DIVIDE => CLKOUT3_DIVIDE,
      CLKOUT4_DIVIDE => CLKOUT4_DIVIDE,
      CLKOUT5_DIVIDE => CLKOUT5_DIVIDE,
      CLKOUT6_DIVIDE => CLKOUT6_DIVIDE,
      DIVCLK_DIVIDE => DIVCLK_DIVIDE,
      IS_CLKINSEL_INVERTED => IS_CLKINSEL_INVERTED,
      IS_PWRDWN_INVERTED => IS_PWRDWN_INVERTED,
      IS_RST_INVERTED => IS_RST_INVERTED
    )
    port map (
      CLKFBOUT => CLKFBOUT, CLKFBOUTB => CLKFBOUTB,
      CLKOUT0 => CLKOUT0, CLKOUT0B => CLKOUT0B,
      CLKOUT1 => CLKOUT1, CLKOUT1B => CLKOUT1B,
      CLKOUT2 => CLKOUT2, CLKOUT2B => CLKOUT2B,
      CLKOUT3 => CLKOUT3, CLKOUT3B => CLKOUT3B,
      CLKOUT4 => CLKOUT4, CLKOUT5 => CLKOUT5, CLKOUT6 => CLKOUT6,
      LOCKED => LOCKED,
      CLKFBIN => fb_i, CLKIN1 => in1_i, CLKIN2 => in2_i,
      CLKINSEL => CLKINSEL, PWRDWN => PWRDWN, RST => RST
    );
end architecture sim;
