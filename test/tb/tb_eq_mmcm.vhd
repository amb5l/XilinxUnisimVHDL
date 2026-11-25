-- MMCME2/E3/E4 ADV and BASE against the submodule Verilog.
-- Integer multiply and divide, 50 percent duty, zero phase, one input.
-- RST is held through the GSR window: a Verilog instance created from
-- VHDL does not see glbl.GSR on the NVC this CI builds. XIL_TIMING is
-- left undefined. Fractional multiply, a duty other than 0.5, a
-- non-zero phase, fine phase shift, spread spectrum, DRP, and the
-- stopped-clock flags are not compared. CLKFBOUT with DIVCLK_DIVIDE
-- greater than 1 is not compared. Each elaboration compares one cell;
-- a second Verilog MMCM in the same simulation does not lock on this
-- NVC. The Verilog may warn that
-- CLKIN1_PERIOD does not match the measured period and that %m is an
-- unknown format; those messages come from the reference.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_mmcm is
  -- One Verilog MMCM in a simulation. A second one, after the first has
  -- run, does not lock on this NVC (possible NVC bug). The makefile
  -- elaborates this bench once per cell.
  generic (cell : integer := 1);
end entity tb_eq_mmcm;

architecture sim of tb_eq_mmcm is
  constant ncell : integer := 7;

  signal clkin : std_ulogic := '0';
  signal pwrdwn : std_ulogic := '0';

  type sulv is array (1 to ncell) of std_ulogic;
  signal fb_h, fb_v, o0_h, o0_v, o1_h, o1_v, lk_h, lk_v, rst : sulv := (others => '1');
  signal o0b_h, o0b_v, fbb_h, fbb_v : std_ulogic;

  component MMCME2_ADV is
    generic (
      CLKFBOUT_MULT_F : real := 5.000;
      CLKIN1_PERIOD : real := 0.000;
      CLKOUT0_DIVIDE_F : real := 1.000;
      CLKOUT1_DIVIDE : integer := 1;
      DIVCLK_DIVIDE : integer := 1
    );
    port (
      CLKFBOUT, CLKFBOUTB, CLKFBSTOPPED, CLKINSTOPPED : out std_ulogic;
      CLKOUT0, CLKOUT0B, CLKOUT1, CLKOUT1B : out std_ulogic;
      CLKOUT2, CLKOUT2B, CLKOUT3, CLKOUT3B : out std_ulogic;
      CLKOUT4, CLKOUT5, CLKOUT6 : out std_ulogic;
      DO : out std_logic_vector(15 downto 0);
      DRDY, LOCKED, PSDONE : out std_ulogic;
      CLKFBIN, CLKIN1, CLKIN2, CLKINSEL : in std_ulogic;
      DADDR : in std_logic_vector(6 downto 0);
      DCLK, DEN : in std_ulogic;
      DI : in std_logic_vector(15 downto 0);
      DWE, PSCLK, PSEN, PSINCDEC, PWRDWN, RST : in std_ulogic
    );
  end component;

  component MMCME2_BASE is
    generic (
      CLKFBOUT_MULT_F : real := 5.000;
      CLKIN1_PERIOD : real := 0.000;
      CLKOUT0_DIVIDE_F : real := 1.000;
      CLKOUT1_DIVIDE : integer := 1;
      DIVCLK_DIVIDE : integer := 1
    );
    port (
      CLKFBOUT, CLKFBOUTB : out std_ulogic;
      CLKOUT0, CLKOUT0B, CLKOUT1, CLKOUT1B : out std_ulogic;
      CLKOUT2, CLKOUT2B, CLKOUT3, CLKOUT3B : out std_ulogic;
      CLKOUT4, CLKOUT5, CLKOUT6, LOCKED : out std_ulogic;
      CLKFBIN, CLKIN1, PWRDWN, RST : in std_ulogic
    );
  end component;

  component MMCME3_ADV is
    generic (
      CLKFBOUT_MULT_F : real := 5.000;
      CLKIN1_PERIOD : real := 0.000;
      CLKOUT0_DIVIDE_F : real := 1.000;
      CLKOUT1_DIVIDE : integer := 1;
      DIVCLK_DIVIDE : integer := 1
    );
    port (
      CDDCDONE, CLKFBOUT, CLKFBOUTB, CLKFBSTOPPED, CLKINSTOPPED : out std_ulogic;
      CLKOUT0, CLKOUT0B, CLKOUT1, CLKOUT1B : out std_ulogic;
      CLKOUT2, CLKOUT2B, CLKOUT3, CLKOUT3B : out std_ulogic;
      CLKOUT4, CLKOUT5, CLKOUT6 : out std_ulogic;
      DO : out std_logic_vector(15 downto 0);
      DRDY, LOCKED, PSDONE : out std_ulogic;
      CDDCREQ, CLKFBIN, CLKIN1, CLKIN2, CLKINSEL : in std_ulogic;
      DADDR : in std_logic_vector(6 downto 0);
      DCLK, DEN : in std_ulogic;
      DI : in std_logic_vector(15 downto 0);
      DWE, PSCLK, PSEN, PSINCDEC, PWRDWN, RST : in std_ulogic
    );
  end component;

  component MMCME3_BASE is
    generic (
      CLKFBOUT_MULT_F : real := 5.000;
      CLKIN1_PERIOD : real := 0.000;
      CLKOUT0_DIVIDE_F : real := 1.000;
      CLKOUT1_DIVIDE : integer := 1;
      DIVCLK_DIVIDE : integer := 1
    );
    port (
      CLKFBOUT, CLKFBOUTB : out std_ulogic;
      CLKOUT0, CLKOUT0B, CLKOUT1, CLKOUT1B : out std_ulogic;
      CLKOUT2, CLKOUT2B, CLKOUT3, CLKOUT3B : out std_ulogic;
      CLKOUT4, CLKOUT5, CLKOUT6, LOCKED : out std_ulogic;
      CLKFBIN, CLKIN1, PWRDWN, RST : in std_ulogic
    );
  end component;

  component MMCME4_ADV is
    generic (
      CLKFBOUT_MULT_F : real := 5.000;
      CLKIN1_PERIOD : real := 0.000;
      CLKOUT0_DIVIDE_F : real := 1.000;
      CLKOUT1_DIVIDE : integer := 1;
      DIVCLK_DIVIDE : integer := 1
    );
    port (
      CDDCDONE, CLKFBOUT, CLKFBOUTB, CLKFBSTOPPED, CLKINSTOPPED : out std_ulogic;
      CLKOUT0, CLKOUT0B, CLKOUT1, CLKOUT1B : out std_ulogic;
      CLKOUT2, CLKOUT2B, CLKOUT3, CLKOUT3B : out std_ulogic;
      CLKOUT4, CLKOUT5, CLKOUT6 : out std_ulogic;
      DO : out std_logic_vector(15 downto 0);
      DRDY, LOCKED, PSDONE : out std_ulogic;
      CDDCREQ, CLKFBIN, CLKIN1, CLKIN2, CLKINSEL : in std_ulogic;
      DADDR : in std_logic_vector(6 downto 0);
      DCLK, DEN : in std_ulogic;
      DI : in std_logic_vector(15 downto 0);
      DWE, PSCLK, PSEN, PSINCDEC, PWRDWN, RST : in std_ulogic
    );
  end component;

  component MMCME4_BASE is
    generic (
      CLKFBOUT_MULT_F : real := 5.000;
      CLKIN1_PERIOD : real := 0.000;
      CLKOUT0_DIVIDE_F : real := 1.000;
      CLKOUT1_DIVIDE : integer := 1;
      DIVCLK_DIVIDE : integer := 1
    );
    port (
      CLKFBOUT, CLKFBOUTB : out std_ulogic;
      CLKOUT0, CLKOUT0B, CLKOUT1, CLKOUT1B : out std_ulogic;
      CLKOUT2, CLKOUT2B, CLKOUT3, CLKOUT3B : out std_ulogic;
      CLKOUT4, CLKOUT5, CLKOUT6, LOCKED : out std_ulogic;
      CLKFBIN, CLKIN1, PWRDWN, RST : in std_ulogic
    );
  end component;
begin
  clkin <= not clkin after 5 ns;

  -- 1: E2 ADV, VCO 800 MHz, CLKOUT0 = input, CLKOUT1 = 2x, DIVCLK 1.
  h1 : entity unisim.MMCME2_ADV
    generic map (CLKFBOUT_MULT_F => 8.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 8.0, CLKOUT1_DIVIDE => 4, DIVCLK_DIVIDE => 1)
    port map (
      CLKFBOUT => fb_h(1), CLKFBOUTB => fbb_h, CLKFBSTOPPED => open, CLKINSTOPPED => open,
      CLKOUT0 => o0_h(1), CLKOUT0B => o0b_h, CLKOUT1 => o1_h(1), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      DO => open, DRDY => open, LOCKED => lk_h(1), PSDONE => open,
      CLKFBIN => fb_h(1), CLKIN1 => clkin, CLKIN2 => '0', CLKINSEL => '1',
      DADDR => (others => '0'), DCLK => '0', DEN => '0', DI => (others => '0'),
      DWE => '0', PSCLK => '0', PSEN => '0', PSINCDEC => '0', PWRDWN => pwrdwn, RST => rst(1));
  v1 : MMCME2_ADV
    generic map (CLKFBOUT_MULT_F => 8.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 8.0, CLKOUT1_DIVIDE => 4, DIVCLK_DIVIDE => 1)
    port map (
      CLKFBOUT => fb_v(1), CLKFBOUTB => fbb_v, CLKFBSTOPPED => open, CLKINSTOPPED => open,
      CLKOUT0 => o0_v(1), CLKOUT0B => o0b_v, CLKOUT1 => o1_v(1), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      DO => open, DRDY => open, LOCKED => lk_v(1), PSDONE => open,
      CLKFBIN => fb_v(1), CLKIN1 => clkin, CLKIN2 => '0', CLKINSEL => '1',
      DADDR => (others => '0'), DCLK => '0', DEN => '0', DI => (others => '0'),
      DWE => '0', PSCLK => '0', PSEN => '0', PSINCDEC => '0', PWRDWN => pwrdwn, RST => rst(1));

  -- 2: E2 ADV with DIVCLK_DIVIDE 2. VCO is still 800 MHz (16 / 20 ns).
  h2 : entity unisim.MMCME2_ADV
    generic map (CLKFBOUT_MULT_F => 16.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 8.0, CLKOUT1_DIVIDE => 4, DIVCLK_DIVIDE => 2)
    port map (
      CLKFBOUT => fb_h(2), CLKFBOUTB => open, CLKFBSTOPPED => open, CLKINSTOPPED => open,
      CLKOUT0 => o0_h(2), CLKOUT0B => open, CLKOUT1 => o1_h(2), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      DO => open, DRDY => open, LOCKED => lk_h(2), PSDONE => open,
      CLKFBIN => fb_h(2), CLKIN1 => clkin, CLKIN2 => '0', CLKINSEL => '1',
      DADDR => (others => '0'), DCLK => '0', DEN => '0', DI => (others => '0'),
      DWE => '0', PSCLK => '0', PSEN => '0', PSINCDEC => '0', PWRDWN => pwrdwn, RST => rst(2));
  v2 : MMCME2_ADV
    generic map (CLKFBOUT_MULT_F => 16.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 8.0, CLKOUT1_DIVIDE => 4, DIVCLK_DIVIDE => 2)
    port map (
      CLKFBOUT => fb_v(2), CLKFBOUTB => open, CLKFBSTOPPED => open, CLKINSTOPPED => open,
      CLKOUT0 => o0_v(2), CLKOUT0B => open, CLKOUT1 => o1_v(2), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      DO => open, DRDY => open, LOCKED => lk_v(2), PSDONE => open,
      CLKFBIN => fb_v(2), CLKIN1 => clkin, CLKIN2 => '0', CLKINSEL => '1',
      DADDR => (others => '0'), DCLK => '0', DEN => '0', DI => (others => '0'),
      DWE => '0', PSCLK => '0', PSEN => '0', PSINCDEC => '0', PWRDWN => pwrdwn, RST => rst(2));

  -- 3: E2 BASE wrapper, VCO 1 GHz.
  h3 : entity unisim.MMCME2_BASE
    generic map (CLKFBOUT_MULT_F => 10.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 10.0, CLKOUT1_DIVIDE => 4, DIVCLK_DIVIDE => 1)
    port map (
      CLKFBOUT => fb_h(3), CLKFBOUTB => open,
      CLKOUT0 => o0_h(3), CLKOUT0B => open, CLKOUT1 => o1_h(3), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      LOCKED => lk_h(3),
      CLKFBIN => fb_h(3), CLKIN1 => clkin, PWRDWN => pwrdwn, RST => rst(3));
  v3 : MMCME2_BASE
    generic map (CLKFBOUT_MULT_F => 10.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 10.0, CLKOUT1_DIVIDE => 4, DIVCLK_DIVIDE => 1)
    port map (
      CLKFBOUT => fb_v(3), CLKFBOUTB => open,
      CLKOUT0 => o0_v(3), CLKOUT0B => open, CLKOUT1 => o1_v(3), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      LOCKED => lk_v(3),
      CLKFBIN => fb_v(3), CLKIN1 => clkin, PWRDWN => pwrdwn, RST => rst(3));

  -- 4: E3 ADV. CDDCREQ stays 0; CDDCDONE is not the comparison path.
  h4 : entity unisim.MMCME3_ADV
    generic map (CLKFBOUT_MULT_F => 8.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 8.0, CLKOUT1_DIVIDE => 4, DIVCLK_DIVIDE => 1)
    port map (
      CDDCDONE => open,
      CLKFBOUT => fb_h(4), CLKFBOUTB => open, CLKFBSTOPPED => open, CLKINSTOPPED => open,
      CLKOUT0 => o0_h(4), CLKOUT0B => open, CLKOUT1 => o1_h(4), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      DO => open, DRDY => open, LOCKED => lk_h(4), PSDONE => open,
      CDDCREQ => '0',
      CLKFBIN => fb_h(4), CLKIN1 => clkin, CLKIN2 => '0', CLKINSEL => '1',
      DADDR => (others => '0'), DCLK => '0', DEN => '0', DI => (others => '0'),
      DWE => '0', PSCLK => '0', PSEN => '0', PSINCDEC => '0', PWRDWN => pwrdwn, RST => rst(4));
  v4 : MMCME3_ADV
    generic map (CLKFBOUT_MULT_F => 8.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 8.0, CLKOUT1_DIVIDE => 4, DIVCLK_DIVIDE => 1)
    port map (
      CDDCDONE => open,
      CLKFBOUT => fb_v(4), CLKFBOUTB => open, CLKFBSTOPPED => open, CLKINSTOPPED => open,
      CLKOUT0 => o0_v(4), CLKOUT0B => open, CLKOUT1 => o1_v(4), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      DO => open, DRDY => open, LOCKED => lk_v(4), PSDONE => open,
      CDDCREQ => '0',
      CLKFBIN => fb_v(4), CLKIN1 => clkin, CLKIN2 => '0', CLKINSEL => '1',
      DADDR => (others => '0'), DCLK => '0', DEN => '0', DI => (others => '0'),
      DWE => '0', PSCLK => '0', PSEN => '0', PSINCDEC => '0', PWRDWN => pwrdwn, RST => rst(4));

  -- 5: E4 ADV. VCO 1 GHz, above the 800 MHz minimum in that model.
  h5 : entity unisim.MMCME4_ADV
    generic map (CLKFBOUT_MULT_F => 10.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 10.0, CLKOUT1_DIVIDE => 5, DIVCLK_DIVIDE => 1)
    port map (
      CDDCDONE => open,
      CLKFBOUT => fb_h(5), CLKFBOUTB => open, CLKFBSTOPPED => open, CLKINSTOPPED => open,
      CLKOUT0 => o0_h(5), CLKOUT0B => open, CLKOUT1 => o1_h(5), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      DO => open, DRDY => open, LOCKED => lk_h(5), PSDONE => open,
      CDDCREQ => '0',
      CLKFBIN => fb_h(5), CLKIN1 => clkin, CLKIN2 => '0', CLKINSEL => '1',
      DADDR => (others => '0'), DCLK => '0', DEN => '0', DI => (others => '0'),
      DWE => '0', PSCLK => '0', PSEN => '0', PSINCDEC => '0', PWRDWN => pwrdwn, RST => rst(5));
  v5 : MMCME4_ADV
    generic map (CLKFBOUT_MULT_F => 10.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 10.0, CLKOUT1_DIVIDE => 5, DIVCLK_DIVIDE => 1)
    port map (
      CDDCDONE => open,
      CLKFBOUT => fb_v(5), CLKFBOUTB => open, CLKFBSTOPPED => open, CLKINSTOPPED => open,
      CLKOUT0 => o0_v(5), CLKOUT0B => open, CLKOUT1 => o1_v(5), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      DO => open, DRDY => open, LOCKED => lk_v(5), PSDONE => open,
      CDDCREQ => '0',
      CLKFBIN => fb_v(5), CLKIN1 => clkin, CLKIN2 => '0', CLKINSEL => '1',
      DADDR => (others => '0'), DCLK => '0', DEN => '0', DI => (others => '0'),
      DWE => '0', PSCLK => '0', PSEN => '0', PSINCDEC => '0', PWRDWN => pwrdwn, RST => rst(5));

  -- 6: E3 BASE wrapper, same ratio as the E2 BASE.
  h6 : entity unisim.MMCME3_BASE
    generic map (CLKFBOUT_MULT_F => 10.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 10.0, CLKOUT1_DIVIDE => 4, DIVCLK_DIVIDE => 1)
    port map (
      CLKFBOUT => fb_h(6), CLKFBOUTB => open,
      CLKOUT0 => o0_h(6), CLKOUT0B => open, CLKOUT1 => o1_h(6), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      LOCKED => lk_h(6),
      CLKFBIN => fb_h(6), CLKIN1 => clkin, PWRDWN => pwrdwn, RST => rst(6));
  v6 : MMCME3_BASE
    generic map (CLKFBOUT_MULT_F => 10.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 10.0, CLKOUT1_DIVIDE => 4, DIVCLK_DIVIDE => 1)
    port map (
      CLKFBOUT => fb_v(6), CLKFBOUTB => open,
      CLKOUT0 => o0_v(6), CLKOUT0B => open, CLKOUT1 => o1_v(6), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      LOCKED => lk_v(6),
      CLKFBIN => fb_v(6), CLKIN1 => clkin, PWRDWN => pwrdwn, RST => rst(6));

  -- 7: E4 BASE wrapper, same ratio as the E4 ADV.
  h7 : entity unisim.MMCME4_BASE
    generic map (CLKFBOUT_MULT_F => 10.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 10.0, CLKOUT1_DIVIDE => 5, DIVCLK_DIVIDE => 1)
    port map (
      CLKFBOUT => fb_h(7), CLKFBOUTB => open,
      CLKOUT0 => o0_h(7), CLKOUT0B => open, CLKOUT1 => o1_h(7), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      LOCKED => lk_h(7),
      CLKFBIN => fb_h(7), CLKIN1 => clkin, PWRDWN => pwrdwn, RST => rst(7));
  v7 : MMCME4_BASE
    generic map (CLKFBOUT_MULT_F => 10.0, CLKIN1_PERIOD => 10.0,
                 CLKOUT0_DIVIDE_F => 10.0, CLKOUT1_DIVIDE => 5, DIVCLK_DIVIDE => 1)
    port map (
      CLKFBOUT => fb_v(7), CLKFBOUTB => open,
      CLKOUT0 => o0_v(7), CLKOUT0B => open, CLKOUT1 => o1_v(7), CLKOUT1B => open,
      CLKOUT2 => open, CLKOUT2B => open, CLKOUT3 => open, CLKOUT3B => open,
      CLKOUT4 => open, CLKOUT5 => open, CLKOUT6 => open,
      LOCKED => lk_v(7),
      CLKFBIN => fb_v(7), CLKIN1 => clkin, PWRDWN => pwrdwn, RST => rst(7));

  stim : process
    variable checks : integer := 0;

    procedure check(h, v : std_ulogic; what : string) is
    begin
      checks := checks + 1;
      if h /= v then
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(v)
          & " at " & time'image(now) severity failure;
      end if;
    end procedure;
  begin
    if cell < 1 or cell > ncell then
      report "bad cell" severity failure;
    end if;
    wait for 200 ns;
    rst(cell) <= '0';
    wait until lk_h(cell) = '1' and lk_v(cell) = '1' for 4 us;
    if lk_h(cell) /= '1' or lk_v(cell) /= '1' then
      report "mmcm " & integer'image(cell) & " did not lock" severity failure;
    end if;
    -- Edges sit on the nanosecond. The Verilog port moves a few deltas
    -- later, so the sample is 200 ps after that point.
    for n in 1 to 1000 loop
      wait for 1 ns;
      wait for 200 ps;
      -- DIVCLK_DIVIDE 2 (cell 2): CLKFBOUT is half a period away.
      if cell /= 2 then
        check(fb_h(cell), fb_v(cell), "fb");
      end if;
      check(o0_h(cell), o0_v(cell), "o0");
      check(o1_h(cell), o1_v(cell), "o1");
      check(lk_h(cell), lk_v(cell), "lk");
      if cell = 1 then
        check(o0b_h, o0b_v, "o0b");
        check(fbb_h, fbb_v, "fbb");
      end if;
    end loop;
    rst(cell) <= '1';
    wait for 50 ns;
    check(lk_h(cell), lk_v(cell), "rst");
    if lk_h(cell) /= '0' then
      report "locked stayed 1 in reset" severity failure;
    end if;
    rst(cell) <= '0';
    pwrdwn <= '1';
    wait for 80 ns;
    check(lk_h(cell), lk_v(cell), "pd");
    if lk_h(cell) /= '0' then
      report "locked stayed 1 in power down" severity failure;
    end if;
    report "PASS tb_eq_mmcm cell=" & integer'image(cell)
      & " checks=" & integer'image(checks);
    finish;
  end process;
end architecture sim;
