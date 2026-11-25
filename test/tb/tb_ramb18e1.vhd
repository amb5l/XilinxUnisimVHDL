-- Write 16'hA5A5 with parity 2'b10 into a RAMB18E1 in 18-bit mode
-- and read it back on the same port.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;
use unisim.vcomponents.all;

entity tb_ramb18e1 is
end entity tb_ramb18e1;

architecture sim of tb_ramb18e1 is
  signal clk    : std_ulogic := '0';
  signal en     : std_ulogic := '0';
  signal we     : std_logic_vector(1 downto 0) := "00";
  signal addr   : std_logic_vector(13 downto 0) := (others => '0');
  signal di     : std_logic_vector(15 downto 0) := (others => '0');
  signal dip    : std_logic_vector(1 downto 0) := "00";
  signal do     : std_logic_vector(15 downto 0);
  signal dop    : std_logic_vector(1 downto 0);
  signal zero16 : std_logic_vector(15 downto 0) := (others => '0');
  signal zero14 : std_logic_vector(13 downto 0) := (others => '0');
  signal zero4  : std_logic_vector(3 downto 0) := (others => '0');
  signal zero2  : std_logic_vector(1 downto 0) := "00";
begin
  dut : RAMB18E1
    generic map (
      DOA_REG                   => 0,
      INIT_A                    => "000000000000000000",
      INIT_B                    => "000000000000000000",
      IS_CLKARDCLK_INVERTED     => '0',
      IS_CLKBWRCLK_INVERTED     => '0',
      IS_ENARDEN_INVERTED       => '0',
      IS_ENBWREN_INVERTED       => '0',
      IS_RSTRAMARSTRAM_INVERTED => '0',
      IS_RSTRAMB_INVERTED       => '0',
      IS_RSTREGARSTREG_INVERTED => '0',
      IS_RSTREGB_INVERTED       => '0',
      SRVAL_A                   => "000000000000000000",
      SRVAL_B                   => "000000000000000000",
      DOB_REG                   => 0,
      INIT_FILE                 => "NONE",
      RAM_MODE                  => "TDP",
      RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
      READ_WIDTH_A              => 18,
      READ_WIDTH_B              => 18,
      RSTREG_PRIORITY_A         => "RSTREG",
      RSTREG_PRIORITY_B         => "RSTREG",
      SIM_COLLISION_CHECK       => "NONE",
      SIM_DEVICE                => "7SERIES",
      WRITE_MODE_A              => "WRITE_FIRST",
      WRITE_MODE_B              => "WRITE_FIRST",
      WRITE_WIDTH_A             => 18,
      WRITE_WIDTH_B             => 18
    )
    port map (
      DOADO         => do,
      DOBDO         => open,
      DOPADOP       => dop,
      DOPBDOP       => open,
      ADDRARDADDR   => addr,
      ADDRBWRADDR   => zero14,
      CLKARDCLK     => clk,
      CLKBWRCLK     => '0',
      DIADI         => di,
      DIBDI         => zero16,
      DIPADIP       => dip,
      DIPBDIP       => zero2,
      ENARDEN       => en,
      ENBWREN       => '0',
      REGCEAREGCE   => '0',
      REGCEB        => '0',
      RSTRAMARSTRAM => '0',
      RSTRAMB       => '0',
      RSTREGARSTREG => '0',
      RSTREGB       => '0',
      WEA           => we,
      WEBWE         => zero4
    );

  process
    procedure tick is
    begin
      clk <= '1';
      wait for 5 ns;
      clk <= '0';
      wait for 5 ns;
    end procedure;
  begin
    wait for 200 ns;

    en   <= '1';
    we   <= "11";
    di   <= x"A5A5";
    dip  <= "10";
    addr <= (others => '0');
    tick;

    assert do = x"A5A5"
      report "write cycle data was " & to_hstring(do) severity failure;
    assert dop = "10"
      report "write cycle parity was " & to_string(dop) severity failure;

    we <= "00";
    tick;
    assert do = x"A5A5"
      report "read cycle data was " & to_hstring(do) severity failure;
    assert dop = "10"
      report "read cycle parity was " & to_string(dop) severity failure;

    report "PASS tb_ramb18e1" severity note;
    finish(0);
  end process;
end architecture sim;
