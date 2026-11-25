-- DSP48E1 multiplies with the pipeline registers held at 0:
--   7 x 9, 25 x 25, 1023 x 17, and 0 x 99.
-- OPMODE 0000101 selects the 25x18 product (X = M, Y = 0, Z = 0).

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.env.all;

library unisim;
use unisim.vcomponents.all;

entity tb_dsp48e1 is
end entity tb_dsp48e1;

architecture sim of tb_dsp48e1 is
  signal clk     : std_ulogic := '0';
  signal a       : std_logic_vector(29 downto 0) := (others => '0');
  signal b       : std_logic_vector(17 downto 0) := (others => '0');
  signal p       : std_logic_vector(47 downto 0);
  signal zero48     : std_logic_vector(47 downto 0) := (others => '0');
  signal zero30     : std_logic_vector(29 downto 0) := (others => '0');
  signal zero25     : std_logic_vector(24 downto 0) := (others => '0');
  signal zero18     : std_logic_vector(17 downto 0) := (others => '0');
  signal alumode    : std_logic_vector(3 downto 0) := (others => '0');
  signal carryinsel : std_logic_vector(2 downto 0) := (others => '0');
  signal carryin    : std_ulogic := '0';
  signal inmode     : std_logic_vector(4 downto 0) := (others => '0');
  signal opmode     : std_logic_vector(6 downto 0) := (others => '0');
begin
  dut : DSP48E1
    generic map (
      ACASCREG           => 0,
      ADREG              => 0,
      ALUMODEREG         => 0,
      AREG               => 0,
      AUTORESET_PATDET   => "NO_RESET",
      A_INPUT            => "DIRECT",
      BCASCREG           => 0,
      BREG               => 0,
      B_INPUT            => "DIRECT",
      CARRYINREG         => 0,
      CARRYINSELREG      => 0,
      CREG               => 0,
      DREG               => 0,
      INMODEREG          => 0,
      IS_ALUMODE_INVERTED => X"0",
      IS_CARRYIN_INVERTED => '0',
      IS_CLK_INVERTED     => '0',
      IS_INMODE_INVERTED  => "00000",
      IS_OPMODE_INVERTED  => "0000000",
      MASK                => X"3FFFFFFFFFFF",
      MREG               => 0,
      OPMODEREG          => 0,
      PATTERN            => X"000000000000",
      PREG               => 0,
      SEL_MASK           => "MASK",
      SEL_PATTERN        => "PATTERN",
      USE_DPORT          => FALSE,
      USE_MULT           => "MULTIPLY",
      USE_PATTERN_DETECT => "NO_PATDET",
      USE_SIMD           => "ONE48"
    )
    port map (
      ACOUT          => open,
      BCOUT          => open,
      CARRYCASCOUT   => open,
      CARRYOUT       => open,
      MULTSIGNOUT    => open,
      OVERFLOW       => open,
      P              => p,
      PATTERNBDETECT => open,
      PATTERNDETECT  => open,
      PCOUT          => open,
      UNDERFLOW      => open,
      A              => a,
      ACIN           => zero30,
      ALUMODE        => alumode,
      B              => b,
      BCIN           => zero18,
      C              => zero48,
      CARRYCASCIN    => '0',
      CARRYIN        => carryin,
      CARRYINSEL     => carryinsel,
      CEA1           => '1',
      CEA2           => '1',
      CEAD           => '1',
      CEALUMODE      => '1',
      CEB1           => '1',
      CEB2           => '1',
      CEC            => '1',
      CECARRYIN      => '1',
      CECTRL         => '1',
      CED            => '1',
      CEINMODE       => '1',
      CEM            => '1',
      CEP            => '1',
      CLK            => clk,
      D              => zero25,
      INMODE         => inmode,
      MULTSIGNIN     => '0',
      OPMODE         => opmode,
      PCIN           => zero48,
      RSTA           => '0',
      RSTALLCARRYIN  => '0',
      RSTALUMODE     => '0',
      RSTB           => '0',
      RSTC           => '0',
      RSTCTRL        => '0',
      RSTD           => '0',
      RSTINMODE      => '0',
      RSTM           => '0',
      RSTP           => '0'
    );

  process
    procedure check(constant av, bv, expect : in natural; constant what : in string) is
    begin
      a <= std_logic_vector(to_unsigned(av, a'length));
      b <= std_logic_vector(to_unsigned(bv, b'length));
      wait for 10 ns;
      assert unsigned(p) = to_unsigned(expect, p'length)
        report what & " got 0x" & to_hstring(p) severity failure;
    end procedure;
  begin
    wait for 200 ns;
    -- With the pipeline registers at 0 the model copies each input in an
    -- always @(input) block, which does not run for a value that never
    -- changes. Pulse every input the multiply path samples, staying in
    -- arithmetic OPMODE, then select X=M, Y=0, Z=0.
    a          <= (others => '1');
    b          <= (others => '1');
    inmode     <= "00001";
    alumode    <= "0001";
    carryinsel <= "001";
    carryin    <= '1';
    wait for 1 ns;
    a          <= (others => '0');
    b          <= (others => '0');
    opmode     <= "0000101";
    inmode     <= (others => '0');
    alumode    <= (others => '0');
    carryinsel <= (others => '0');
    carryin    <= '0';
    wait for 1 ns;

    check(7, 9, 63, "7x9");
    check(25, 25, 625, "25x25");
    check(1023, 17, 17391, "1023x17");
    check(0, 99, 0, "0x99");
    report "PASS tb_dsp48e1" severity note;
    finish(0);
  end process;
end architecture sim;
