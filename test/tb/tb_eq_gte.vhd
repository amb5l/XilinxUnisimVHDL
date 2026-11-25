-- IBUFDS_GTE3/GTE4 and OBUFDS_GTE3_ADV/GTE4_ADV against the submodule
-- Verilog. XIL_TIMING stays undefined. The 100 ps GTE4 specify path
-- is not copied; the bench waits 5 ns after a rising edge.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_gte is
end entity tb_eq_gte;

architecture sim of tb_eq_gte is
  signal i4, ib4, ceb4 : std_ulogic := '0';
  signal i4d, ceb4d : std_ulogic := '0';
  signal i3, ib3, ceb3 : std_ulogic := '0';
  signal i3d, ceb3d : std_ulogic := '0';
  signal a4i : std_logic_vector(3 downto 0) := "0000";
  signal a4ceb : std_ulogic := '0';
  signal a4sel : std_logic_vector(1 downto 0) := "00";
  signal a3i : std_logic_vector(3 downto 0) := "0000";
  signal a3ceb : std_ulogic := '0';
  signal a3sel : std_logic_vector(1 downto 0) := "00";

  signal g4o_h, g4o_v, g4d2_h, g4d2_v : std_ulogic;
  signal g4zo_h, g4zo_v, g4z_h, g4z_v : std_ulogic;
  signal g4tx_h, g4tx_v, g4txd_h, g4txd_v : std_ulogic;
  signal g4dv_h, g4dv_v, g4do_h, g4do_v : std_ulogic;
  signal g3o_h, g3o_v, g3d2_h, g3d2_v : std_ulogic;
  signal g3tx_h, g3tx_v, g3txd_h, g3txd_v : std_ulogic;
  signal g3dv_h, g3dv_v, g3do_h, g3do_v : std_ulogic;
  signal a4o_h, a4o_v, a4b_h, a4b_v : std_ulogic;
  signal a4z_h, a4z_v, a4zb_h, a4zb_v : std_ulogic;
  signal a3o_h, a3o_v, a3b_h, a3b_v : std_ulogic;
  signal a3z_h, a3z_v, a3zb_h, a3zb_v : std_ulogic;

  component IBUFDS_GTE4 is
    generic (
      REFCLK_EN_TX_PATH : bit := '0';
      REFCLK_HROW_CK_SEL : bit_vector(1 downto 0) := "00";
      REFCLK_ICNTL_RX : bit_vector(1 downto 0) := "00"
    );
    port (
      O : out std_ulogic;
      ODIV2 : out std_ulogic;
      CEB : in std_ulogic;
      I : in std_ulogic;
      IB : in std_ulogic
    );
  end component;

  component IBUFDS_GTE3 is
    generic (
      REFCLK_EN_TX_PATH : bit := '0';
      REFCLK_HROW_CK_SEL : bit_vector(1 downto 0) := "00";
      REFCLK_ICNTL_RX : bit_vector(1 downto 0) := "00"
    );
    port (
      O : out std_ulogic;
      ODIV2 : out std_ulogic;
      CEB : in std_ulogic;
      I : in std_ulogic;
      IB : in std_ulogic
    );
  end component;

  component OBUFDS_GTE4_ADV is
    generic (
      REFCLK_EN_TX_PATH : bit := '0';
      REFCLK_ICNTL_TX : bit_vector(4 downto 0) := "00000"
    );
    port (
      O : out std_ulogic;
      OB : out std_ulogic;
      CEB : in std_ulogic;
      I : in std_logic_vector(3 downto 0);
      RXRECCLK_SEL : in std_logic_vector(1 downto 0)
    );
  end component;

  component OBUFDS_GTE3_ADV is
    generic (
      REFCLK_EN_TX_PATH : bit := '0';
      REFCLK_ICNTL_TX : bit_vector(4 downto 0) := "00000"
    );
    port (
      O : out std_ulogic;
      OB : out std_ulogic;
      CEB : in std_ulogic;
      I : in std_logic_vector(3 downto 0);
      RXRECCLK_SEL : in std_logic_vector(1 downto 0)
    );
  end component;
begin
  u_g4_h : entity unisim.IBUFDS_GTE4
    port map (O => g4o_h, ODIV2 => g4d2_h, CEB => ceb4, I => i4, IB => ib4);
  u_g4_v : IBUFDS_GTE4
    port map (O => g4o_v, ODIV2 => g4d2_v, CEB => ceb4, I => i4, IB => ib4);

  u_g4z_h : entity unisim.IBUFDS_GTE4
    generic map (REFCLK_HROW_CK_SEL => "10")
    port map (O => g4zo_h, ODIV2 => g4z_h, CEB => ceb4, I => i4, IB => ib4);
  u_g4z_v : IBUFDS_GTE4
    generic map (REFCLK_HROW_CK_SEL => "10")
    port map (O => g4zo_v, ODIV2 => g4z_v, CEB => ceb4, I => i4, IB => ib4);

  u_g4tx_h : entity unisim.IBUFDS_GTE4
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => g4tx_h, ODIV2 => g4txd_h, CEB => ceb4, I => i4, IB => ib4);
  u_g4tx_v : IBUFDS_GTE4
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => g4tx_v, ODIV2 => g4txd_v, CEB => ceb4, I => i4, IB => ib4);

  u_g4d_h : entity unisim.IBUFDS_GTE4
    generic map (REFCLK_HROW_CK_SEL => "01")
    port map (O => g4do_h, ODIV2 => g4dv_h, CEB => ceb4d, I => i4d, IB => ib4);
  u_g4d_v : IBUFDS_GTE4
    generic map (REFCLK_HROW_CK_SEL => "01")
    port map (O => g4do_v, ODIV2 => g4dv_v, CEB => ceb4d, I => i4d, IB => ib4);

  u_g3_h : entity unisim.IBUFDS_GTE3
    port map (O => g3o_h, ODIV2 => g3d2_h, CEB => ceb3, I => i3, IB => ib3);
  u_g3_v : IBUFDS_GTE3
    port map (O => g3o_v, ODIV2 => g3d2_v, CEB => ceb3, I => i3, IB => ib3);

  u_g3tx_h : entity unisim.IBUFDS_GTE3
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => g3tx_h, ODIV2 => g3txd_h, CEB => ceb3, I => i3, IB => ib3);
  u_g3tx_v : IBUFDS_GTE3
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => g3tx_v, ODIV2 => g3txd_v, CEB => ceb3, I => i3, IB => ib3);

  u_g3d_h : entity unisim.IBUFDS_GTE3
    generic map (REFCLK_HROW_CK_SEL => "01")
    port map (O => g3do_h, ODIV2 => g3dv_h, CEB => ceb3d, I => i3d, IB => ib3);
  u_g3d_v : IBUFDS_GTE3
    generic map (REFCLK_HROW_CK_SEL => "01")
    port map (O => g3do_v, ODIV2 => g3dv_v, CEB => ceb3d, I => i3d, IB => ib3);

  u_a4_h : entity unisim.OBUFDS_GTE4_ADV
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => a4o_h, OB => a4b_h, CEB => a4ceb, I => a4i, RXRECCLK_SEL => a4sel);
  u_a4_v : OBUFDS_GTE4_ADV
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => a4o_v, OB => a4b_v, CEB => a4ceb, I => a4i, RXRECCLK_SEL => a4sel);

  u_a4z_h : entity unisim.OBUFDS_GTE4_ADV
    port map (O => a4z_h, OB => a4zb_h, CEB => a4ceb, I => a4i, RXRECCLK_SEL => a4sel);
  u_a4z_v : OBUFDS_GTE4_ADV
    port map (O => a4z_v, OB => a4zb_v, CEB => a4ceb, I => a4i, RXRECCLK_SEL => a4sel);

  u_a3_h : entity unisim.OBUFDS_GTE3_ADV
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => a3o_h, OB => a3b_h, CEB => a3ceb, I => a3i, RXRECCLK_SEL => a3sel);
  u_a3_v : OBUFDS_GTE3_ADV
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => a3o_v, OB => a3b_v, CEB => a3ceb, I => a3i, RXRECCLK_SEL => a3sel);

  u_a3z_h : entity unisim.OBUFDS_GTE3_ADV
    port map (O => a3z_h, OB => a3zb_h, CEB => a3ceb, I => a3i, RXRECCLK_SEL => a3sel);
  u_a3z_v : OBUFDS_GTE3_ADV
    port map (O => a3z_v, OB => a3zb_v, CEB => a3ceb, I => a3i, RXRECCLK_SEL => a3sel);

  stimulus : process
    variable checks : natural := 0;

    function from_vlog(v : std_ulogic) return std_ulogic is
    begin
      if v = 'U' then
        return 'X';
      end if;
      return v;
    end function;

    procedure check1(h, v : std_ulogic; what : string) is
    begin
      checks := checks + 1;
      if h /= from_vlog(v) then
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(v)
          & " at " & time'image(now) severity failure;
      end if;
    end procedure;

    procedure expect1(got, exp : std_ulogic; what : string) is
    begin
      if got /= exp then
        report what & " expected " & to_string(exp) & " got " & to_string(got)
          & " at " & time'image(now) severity failure;
      end if;
    end procedure;

    procedure settle is
    begin
      wait for 5 ns;
    end procedure;
  begin
    ib4 <= '1';
    ib3 <= '0';
    wait for 1 ns;

    i4 <= '1';
    ceb4 <= '0';
    settle;
    check1(g4o_h, g4o_v, "g4 o");
    check1(g4d2_h, g4d2_v, "g4 odiv2");
    expect1(g4o_h, '1', "g4 follows i");
    expect1(g4d2_h, '1', "g4 sel00 odiv2");
    check1(g4z_h, g4z_v, "g4 sel10");
    expect1(g4z_h, '0', "g4 sel10 zero");
    check1(g4tx_h, g4tx_v, "g4 tx o");
    check1(g4txd_h, g4txd_v, "g4 tx odiv2");
    expect1(g4tx_h, '0', "g4 tx forces 0");

    i4 <= 'Z';
    settle;
    check1(g4o_h, g4o_v, "g4 z");
    expect1(g4o_h, 'X', "g4 z becomes x");
    i4 <= 'X';
    settle;
    check1(g4o_h, g4o_v, "g4 x");
    expect1(g4o_h, 'X', "g4 x stays x");

    i4 <= '1';
    ceb4 <= '1';
    settle;
    check1(g4o_h, g4o_v, "g4 ceb");
    expect1(g4o_h, '0', "g4 ceb disables");
    ceb4 <= 'Z';
    settle;
    check1(g4o_h, g4o_v, "g4 ceb z");
    expect1(g4o_h, '1', "g4 ceb z still passes");
    ceb4 <= 'X';
    settle;
    check1(g4o_h, g4o_v, "g4 ceb x");
    expect1(g4o_h, '1', "g4 ceb x still passes");
    ceb4 <= '0';

    i3 <= '1';
    ceb3 <= '0';
    settle;
    check1(g3o_h, g3o_v, "g3 o");
    check1(g3d2_h, g3d2_v, "g3 odiv2");
    expect1(g3o_h, '1', "g3 follows i");
    expect1(g3d2_h, '1', "g3 sel00 odiv2");
    check1(g3tx_h, g3tx_v, "g3 tx");
    expect1(g3tx_h, '0', "g3 tx forces 0");
    i3 <= 'Z';
    settle;
    check1(g3o_h, g3o_v, "g3 z");
    expect1(g3o_h, 'Z', "g3 z passes");
    i3 <= '1';
    ceb3 <= 'X';
    settle;
    check1(g3o_h, g3o_v, "g3 ceb x");
    expect1(g3o_h, 'X', "g3 ceb x merges");
    i3 <= '0';
    settle;
    check1(g3o_h, g3o_v, "g3 ceb x zero");
    expect1(g3o_h, '0', "g3 both sides 0");
    ceb3 <= '1';
    i3 <= '1';
    settle;
    check1(g3o_h, g3o_v, "g3 ceb");
    expect1(g3o_h, '0', "g3 ceb disables");
    ceb3 <= '0';

    -- Divider: first rising edge sets ODIV2, the next clears it.
    i4d <= '0';
    ceb4d <= '0';
    settle;
    i4d <= '1';
    settle;
    check1(g4do_h, g4do_v, "g4d o");
    check1(g4dv_h, g4dv_v, "g4d odiv2");
    expect1(g4dv_h, '1', "g4d first edge");
    expect1(g4do_h, '1', "g4d o follows");
    i4d <= '0';
    settle;
    check1(g4dv_h, g4dv_v, "g4d hold");
    expect1(g4dv_h, '1', "g4d holds through fall");
    i4d <= '1';
    settle;
    check1(g4dv_h, g4dv_v, "g4d second");
    expect1(g4dv_h, '0', "g4d second edge");
    i4d <= '0';
    ceb4d <= '1';
    settle;
    i4d <= '1';
    settle;
    check1(g4dv_h, g4dv_v, "g4d ceb1");
    expect1(g4dv_h, '0', "g4d ceb1 does not count");
    expect1(g4do_h, '0', "g4d ceb1 forces o");
    i4d <= '0';
    ceb4d <= 'Z';
    settle;
    i4d <= '1';
    settle;
    check1(g4dv_h, g4dv_v, "g4d ceb z");
    expect1(g4dv_h, '1', "g4d ceb z counts");

    i3d <= '0';
    ceb3d <= '0';
    settle;
    i3d <= '1';
    settle;
    check1(g3dv_h, g3dv_v, "g3d first");
    expect1(g3dv_h, '1', "g3d first edge");
    -- allEqual resets on the next rising edge even when CEB is not 0.
    i3d <= '0';
    ceb3d <= 'Z';
    settle;
    i3d <= '1';
    settle;
    check1(g3dv_h, g3dv_v, "g3d reset");
    expect1(g3dv_h, '0', "g3d reset ignores ceb");
    i3d <= '0';
    settle;
    i3d <= '1';
    settle;
    check1(g3dv_h, g3dv_v, "g3d ceb z");
    expect1(g3dv_h, '0', "g3d ceb z does not count");
    i3d <= '0';
    ceb3d <= '0';
    settle;
    i3d <= '1';
    settle;
    check1(g3dv_h, g3dv_v, "g3d second");
    expect1(g3dv_h, '1', "g3d counts again");

    a4i <= "0001";
    a4ceb <= '0';
    a4sel <= "00";
    a3i <= "0001";
    a3ceb <= '0';
    a3sel <= "00";
    settle;
    check1(a4o_h, a4o_v, "a4 o");
    check1(a4b_h, a4b_v, "a4 ob");
    expect1(a4o_h, '1', "a4 bit0");
    expect1(a4b_h, '0', "a4 ob inv");
    check1(a4z_h, a4z_v, "a4 off");
    check1(a4zb_h, a4zb_v, "a4 off ob");
    expect1(a4z_h, 'Z', "a4 path off");
    check1(a3o_h, a3o_v, "a3 o");
    check1(a3b_h, a3b_v, "a3 ob");
    expect1(a3o_h, '1', "a3 bit0");
    expect1(a3b_h, '0', "a3 ob inv");
    check1(a3z_h, a3z_v, "a3 off");
    expect1(a3z_h, 'Z', "a3 path off");

    a4i <= "0010";
    a4sel <= "01";
    a3i <= "0100";
    a3sel <= "10";
    settle;
    check1(a4o_h, a4o_v, "a4 sel1");
    expect1(a4o_h, '1', "a4 bit1");
    check1(a3o_h, a3o_v, "a3 sel2");
    expect1(a3o_h, '1', "a3 bit2");
    a4i <= "1000";
    a4sel <= "11";
    settle;
    check1(a4o_h, a4o_v, "a4 sel3");
    expect1(a4o_h, '1', "a4 bit3");
    a4sel <= "XX";
    settle;
    check1(a4o_h, a4o_v, "a4 sel x");
    expect1(a4o_h, '0', "a4 sel x is bit0");

    a4i <= "ZZZZ";
    a4sel <= "00";
    a3i <= "ZZZZ";
    a3sel <= "00";
    settle;
    check1(a4o_h, a4o_v, "a4 z data");
    expect1(a4o_h, 'Z', "a4 z passes");
    expect1(a4b_h, 'X', "a4 ob of z");
    check1(a3o_h, a3o_v, "a3 z data");
    expect1(a3o_h, 'Z', "a3 z passes");
    check1(a3b_h, a3b_v, "a3 ob z");
    expect1(a3b_h, 'X', "a3 ob of z");

    a4ceb <= '1';
    a3ceb <= '1';
    a4i <= "0001";
    a3i <= "0001";
    settle;
    check1(a4o_h, a4o_v, "a4 ceb");
    expect1(a4o_h, 'Z', "a4 ceb z");
    check1(a3o_h, a3o_v, "a3 ceb");
    expect1(a3o_h, 'Z', "a3 ceb z");
    a4ceb <= 'X';
    a3ceb <= 'X';
    settle;
    check1(a4o_h, a4o_v, "a4 ceb x");
    expect1(a4o_h, '1', "a4 ceb x still drives");
    check1(a3o_h, a3o_v, "a3 ceb x");
    expect1(a3o_h, 'Z', "a3 ceb x is z");

    report "tb_eq_gte checks " & integer'image(checks) severity note;
    finish;
  end process;
end architecture sim;
