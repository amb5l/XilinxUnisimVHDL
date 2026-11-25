-- Write and read a RAM32X1D through unisim.vcomponents.
-- glbl drives GSR high for the first 100 ns; stimulus starts after that.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;
use unisim.vcomponents.all;

entity tb_ram32x1d is
end entity tb_ram32x1d;

architecture sim of tb_ram32x1d is
  signal wclk : std_ulogic := '0';
  signal we   : std_ulogic := '0';
  signal d    : std_ulogic := '0';
  signal a    : std_ulogic_vector(4 downto 0) := (others => '0');
  signal dpra : std_ulogic_vector(4 downto 0) := (others => '0');
  signal spo  : std_ulogic;
  signal dpo  : std_ulogic;
begin
  dut : RAM32X1D
    generic map (
      INIT             => x"00000000",
      IS_WCLK_INVERTED => "0"
    )
    port map (
      DPO   => dpo,
      SPO   => spo,
      A0    => a(0),
      A1    => a(1),
      A2    => a(2),
      A3    => a(3),
      A4    => a(4),
      D     => d,
      DPRA0 => dpra(0),
      DPRA1 => dpra(1),
      DPRA2 => dpra(2),
      DPRA3 => dpra(3),
      DPRA4 => dpra(4),
      WCLK  => wclk,
      WE    => we
    );

  process
    procedure tick is
    begin
      wclk <= '1';
      wait for 1 ns;
      wclk <= '0';
      wait for 1 ns;
    end procedure;
  begin
    wait for 200 ns;

    we   <= '1';
    d    <= '1';
    a    <= "00101";
    dpra <= "00101";
    tick;
    assert spo = '1'
      report "SPO was not 1 after writing addr 5" severity failure;
    assert dpo = '1'
      report "DPO was not 1 after writing addr 5" severity failure;

    dpra <= "00000";
    wait for 1 ns;
    assert spo = '1'
      report "SPO changed while the write address stayed at 5" severity failure;
    assert dpo = '0'
      report "DPO of unwritten address 0 was not 0" severity failure;

    d <= '0';
    tick;
    assert spo = '0'
      report "SPO was not 0 after clearing addr 5" severity failure;

    report "PASS tb_ram32x1d" severity note;
    finish(0);
  end process;
end architecture sim;
