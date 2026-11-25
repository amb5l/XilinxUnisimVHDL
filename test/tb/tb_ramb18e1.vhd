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
      DOB_REG                   => 0,
      INITP_00                  => (others => '0'),
      INITP_01                  => (others => '0'),
      INITP_02                  => (others => '0'),
      INITP_03                  => (others => '0'),
      INITP_04                  => (others => '0'),
      INITP_05                  => (others => '0'),
      INITP_06                  => (others => '0'),
      INITP_07                  => (others => '0'),
      INIT_00                   => (others => '0'),
      INIT_01                   => (others => '0'),
      INIT_02                   => (others => '0'),
      INIT_03                   => (others => '0'),
      INIT_04                   => (others => '0'),
      INIT_05                   => (others => '0'),
      INIT_06                   => (others => '0'),
      INIT_07                   => (others => '0'),
      INIT_08                   => (others => '0'),
      INIT_09                   => (others => '0'),
      INIT_0A                   => (others => '0'),
      INIT_0B                   => (others => '0'),
      INIT_0C                   => (others => '0'),
      INIT_0D                   => (others => '0'),
      INIT_0E                   => (others => '0'),
      INIT_0F                   => (others => '0'),
      INIT_10                   => (others => '0'),
      INIT_11                   => (others => '0'),
      INIT_12                   => (others => '0'),
      INIT_13                   => (others => '0'),
      INIT_14                   => (others => '0'),
      INIT_15                   => (others => '0'),
      INIT_16                   => (others => '0'),
      INIT_17                   => (others => '0'),
      INIT_18                   => (others => '0'),
      INIT_19                   => (others => '0'),
      INIT_1A                   => (others => '0'),
      INIT_1B                   => (others => '0'),
      INIT_1C                   => (others => '0'),
      INIT_1D                   => (others => '0'),
      INIT_1E                   => (others => '0'),
      INIT_1F                   => (others => '0'),
      INIT_20                   => (others => '0'),
      INIT_21                   => (others => '0'),
      INIT_22                   => (others => '0'),
      INIT_23                   => (others => '0'),
      INIT_24                   => (others => '0'),
      INIT_25                   => (others => '0'),
      INIT_26                   => (others => '0'),
      INIT_27                   => (others => '0'),
      INIT_28                   => (others => '0'),
      INIT_29                   => (others => '0'),
      INIT_2A                   => (others => '0'),
      INIT_2B                   => (others => '0'),
      INIT_2C                   => (others => '0'),
      INIT_2D                   => (others => '0'),
      INIT_2E                   => (others => '0'),
      INIT_2F                   => (others => '0'),
      INIT_30                   => (others => '0'),
      INIT_31                   => (others => '0'),
      INIT_32                   => (others => '0'),
      INIT_33                   => (others => '0'),
      INIT_34                   => (others => '0'),
      INIT_35                   => (others => '0'),
      INIT_36                   => (others => '0'),
      INIT_37                   => (others => '0'),
      INIT_38                   => (others => '0'),
      INIT_39                   => (others => '0'),
      INIT_3A                   => (others => '0'),
      INIT_3B                   => (others => '0'),
      INIT_3C                   => (others => '0'),
      INIT_3D                   => (others => '0'),
      INIT_3E                   => (others => '0'),
      INIT_3F                   => (others => '0'),
      INIT_A                    => (others => '0'),
      INIT_B                    => (others => '0'),
      INIT_FILE                 => "NONE",
      IS_CLKARDCLK_INVERTED     => "0",
      IS_CLKBWRCLK_INVERTED     => "0",
      IS_ENARDEN_INVERTED       => "0",
      IS_ENBWREN_INVERTED       => "0",
      IS_RSTRAMARSTRAM_INVERTED => "0",
      IS_RSTRAMB_INVERTED       => "0",
      IS_RSTREGARSTREG_INVERTED => "0",
      IS_RSTREGB_INVERTED       => "0",
      RAM_MODE                  => "TDP",
      RDADDR_COLLISION_HWCONFIG => "DELAYED_WRITE",
      READ_WIDTH_A              => 18,
      READ_WIDTH_B              => 18,
      RSTREG_PRIORITY_A         => "RSTREG",
      RSTREG_PRIORITY_B         => "RSTREG",
      SIM_COLLISION_CHECK       => "NONE",
      SIM_DEVICE                => "7SERIES",
      SRVAL_A                   => (others => '0'),
      SRVAL_B                   => (others => '0'),
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
