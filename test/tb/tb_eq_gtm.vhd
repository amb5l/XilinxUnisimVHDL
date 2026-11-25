-- IBUFDS_GTE2, IBUFDS_GTM, OBUFDS_GTM and OBUFDS_GTM_ADV against
-- the submodule Verilog. XIL_TIMING stays undefined.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_gtm is
end entity tb_eq_gtm;

architecture sim of tb_eq_gtm is
  signal i2, ib2, ceb2 : std_ulogic := '0';
  signal im, ibm, cebm : std_ulogic := '0';
  signal imd, cebmd : std_ulogic := '0';
  signal oi : std_ulogic := '0';
  signal oceb : std_ulogic := '0';
  signal ai : std_logic_vector(3 downto 0) := "0000";
  signal aceb : std_ulogic := '0';

  signal g2o_h, g2o_v, g2d_h, g2d_v : std_ulogic;
  signal gmo_h, gmo_v, gmd_h, gmd_v : std_ulogic;
  signal gmz_h, gmz_v : std_ulogic;
  signal gmt_h, gmt_v : std_ulogic;
  signal gmdv_h, gmdv_v, gmdo_h, gmdo_v : std_ulogic;
  signal oo_h, oo_v, oob_h, oob_v : std_ulogic;
  signal oz_h, oz_v : std_ulogic;
  signal a0_h, a0_v, a0b_h, a0b_v : std_ulogic;
  signal a1_h, a1_v : std_ulogic;
  signal a3_h, a3_v : std_ulogic;
  signal az_h, az_v : std_ulogic;

  component IBUFDS_GTE2 is
    generic (
      CLKCM_CFG : boolean := true;
      CLKRCV_TRST : boolean := true;
      CLKSWING_CFG : bit_vector(1 downto 0) := "11"
    );
    port (
      O : out std_ulogic;
      ODIV2 : out std_ulogic;
      CEB : in std_ulogic;
      I : in std_ulogic;
      IB : in std_ulogic
    );
  end component;

  component IBUFDS_GTM is
    generic (
      REFCLK_EN_TX_PATH : bit := '0';
      REFCLK_HROW_CK_SEL : integer := 0;
      REFCLK_ICNTL_RX : integer := 0
    );
    port (
      O : out std_ulogic;
      ODIV2 : out std_ulogic;
      CEB : in std_ulogic;
      I : in std_ulogic;
      IB : in std_ulogic
    );
  end component;

  component OBUFDS_GTM is
    generic (
      REFCLK_EN_TX_PATH : bit := '0';
      REFCLK_ICNTL_TX : integer := 0
    );
    port (
      O : out std_ulogic;
      OB : out std_ulogic;
      CEB : in std_ulogic;
      I : in std_ulogic
    );
  end component;

  component OBUFDS_GTM_ADV is
    generic (
      REFCLK_EN_TX_PATH : bit := '0';
      REFCLK_ICNTL_TX : integer := 0;
      RXRECCLK_SEL : bit_vector(1 downto 0) := "00"
    );
    port (
      O : out std_ulogic;
      OB : out std_ulogic;
      CEB : in std_ulogic;
      I : in std_logic_vector(3 downto 0)
    );
  end component;
begin
  u_g2_h : entity unisim.IBUFDS_GTE2
    port map (O => g2o_h, ODIV2 => g2d_h, CEB => ceb2, I => i2, IB => ib2);
  u_g2_v : IBUFDS_GTE2
    port map (O => g2o_v, ODIV2 => g2d_v, CEB => ceb2, I => i2, IB => ib2);

  u_gm_h : entity unisim.IBUFDS_GTM
    port map (O => gmo_h, ODIV2 => gmd_h, CEB => cebm, I => im, IB => ibm);
  u_gm_v : IBUFDS_GTM
    port map (O => gmo_v, ODIV2 => gmd_v, CEB => cebm, I => im, IB => ibm);

  u_gmz_h : entity unisim.IBUFDS_GTM
    generic map (REFCLK_HROW_CK_SEL => 2)
    port map (O => open, ODIV2 => gmz_h, CEB => cebm, I => im, IB => ibm);
  u_gmz_v : IBUFDS_GTM
    generic map (REFCLK_HROW_CK_SEL => 2)
    port map (O => open, ODIV2 => gmz_v, CEB => cebm, I => im, IB => ibm);

  u_gmt_h : entity unisim.IBUFDS_GTM
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => gmt_h, ODIV2 => open, CEB => cebm, I => im, IB => ibm);
  u_gmt_v : IBUFDS_GTM
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => gmt_v, ODIV2 => open, CEB => cebm, I => im, IB => ibm);

  u_gmd_h : entity unisim.IBUFDS_GTM
    generic map (REFCLK_HROW_CK_SEL => 1)
    port map (O => gmdo_h, ODIV2 => gmdv_h, CEB => cebmd, I => imd, IB => ibm);
  u_gmd_v : IBUFDS_GTM
    generic map (REFCLK_HROW_CK_SEL => 1)
    port map (O => gmdo_v, ODIV2 => gmdv_v, CEB => cebmd, I => imd, IB => ibm);

  u_o_h : entity unisim.OBUFDS_GTM
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => oo_h, OB => oob_h, CEB => oceb, I => oi);
  u_o_v : OBUFDS_GTM
    generic map (REFCLK_EN_TX_PATH => '1')
    port map (O => oo_v, OB => oob_v, CEB => oceb, I => oi);

  u_oz_h : entity unisim.OBUFDS_GTM
    port map (O => oz_h, OB => open, CEB => oceb, I => oi);
  u_oz_v : OBUFDS_GTM
    port map (O => oz_v, OB => open, CEB => oceb, I => oi);

  u_a0_h : entity unisim.OBUFDS_GTM_ADV
    generic map (REFCLK_EN_TX_PATH => '1', RXRECCLK_SEL => "00")
    port map (O => a0_h, OB => a0b_h, CEB => aceb, I => ai);
  u_a0_v : OBUFDS_GTM_ADV
    generic map (REFCLK_EN_TX_PATH => '1', RXRECCLK_SEL => "00")
    port map (O => a0_v, OB => a0b_v, CEB => aceb, I => ai);

  u_a1_h : entity unisim.OBUFDS_GTM_ADV
    generic map (REFCLK_EN_TX_PATH => '1', RXRECCLK_SEL => "01")
    port map (O => a1_h, OB => open, CEB => aceb, I => ai);
  u_a1_v : OBUFDS_GTM_ADV
    generic map (REFCLK_EN_TX_PATH => '1', RXRECCLK_SEL => "01")
    port map (O => a1_v, OB => open, CEB => aceb, I => ai);

  u_a3_h : entity unisim.OBUFDS_GTM_ADV
    generic map (REFCLK_EN_TX_PATH => '1', RXRECCLK_SEL => "11")
    port map (O => a3_h, OB => open, CEB => aceb, I => ai);
  u_a3_v : OBUFDS_GTM_ADV
    generic map (REFCLK_EN_TX_PATH => '1', RXRECCLK_SEL => "11")
    port map (O => a3_v, OB => open, CEB => aceb, I => ai);

  u_az_h : entity unisim.OBUFDS_GTM_ADV
    generic map (RXRECCLK_SEL => "10")
    port map (O => az_h, OB => open, CEB => aceb, I => ai);
  u_az_v : OBUFDS_GTM_ADV
    generic map (RXRECCLK_SEL => "10")
    port map (O => az_v, OB => open, CEB => aceb, I => ai);

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
    ib2 <= '1';
    ibm <= '0';
    wait for 1 ns;

    -- GTE2: O ignores CEB until I changes. ODIV2 is one edge behind.
    i2 <= '1';
    settle;
    check1(g2o_h, g2o_v, "g2 o");
    check1(g2d_h, g2d_v, "g2 odiv2");
    expect1(g2o_h, '1', "g2 follows i");
    expect1(g2d_h, '0', "g2 first edge samples 0");
    ceb2 <= '1';
    settle;
    check1(g2o_h, g2o_v, "g2 hold");
    expect1(g2o_h, '1', "g2 ceb does not update o");
    i2 <= '0';
    settle;
    check1(g2o_h, g2o_v, "g2 fall");
    expect1(g2o_h, '0', "g2 o clears on i");
    expect1(g2d_h, '0', "g2 odiv2 holds through fall");
    i2 <= '1';
    settle;
    check1(g2d_h, g2d_v, "g2 second");
    expect1(g2d_h, '1', "g2 second edge");
    expect1(g2o_h, '0', "g2 ceb 1 forces o on i");
    i2 <= '0';
    ceb2 <= 'Z';
    settle;
    i2 <= '1';
    settle;
    check1(g2d_h, g2d_v, "g2 ceb z");
    expect1(g2d_h, '0', "g2 ceb z does not count");
    expect1(g2o_h, 'X', "g2 ceb z and");
    i2 <= 'Z';
    ceb2 <= '0';
    settle;
    check1(g2o_h, g2o_v, "g2 z");
    expect1(g2o_h, 'X', "g2 z and 1");

    im <= '1';
    cebm <= '0';
    settle;
    check1(gmo_h, gmo_v, "gm o");
    check1(gmd_h, gmd_v, "gm odiv2");
    expect1(gmo_h, '1', "gm follows i");
    expect1(gmd_h, '1', "gm sel0 odiv2");
    check1(gmz_h, gmz_v, "gm sel2");
    expect1(gmz_v, '0', "gm sel2 zero");
    check1(gmt_h, gmt_v, "gm tx");
    expect1(gmt_h, '0', "gm tx forces 0");
    im <= 'Z';
    settle;
    check1(gmo_h, gmo_v, "gm z");
    expect1(gmo_h, 'X', "gm z becomes x");
    im <= '1';
    cebm <= 'X';
    settle;
    check1(gmo_h, gmo_v, "gm ceb x");
    expect1(gmo_h, '1', "gm ceb x still passes");
    cebm <= '1';
    settle;
    check1(gmo_h, gmo_v, "gm ceb");
    expect1(gmo_h, '0', "gm ceb disables");

    imd <= '0';
    cebmd <= '0';
    settle;
    imd <= '1';
    settle;
    check1(gmdv_h, gmdv_v, "gmd first");
    expect1(gmdv_h, '1', "gmd first edge");
    imd <= '0';
    settle;
    imd <= '1';
    settle;
    check1(gmdv_h, gmdv_v, "gmd second");
    expect1(gmdv_h, '0', "gmd second edge");
    imd <= '0';
    cebmd <= 'Z';
    settle;
    imd <= '1';
    settle;
    check1(gmdv_h, gmdv_v, "gmd ceb z");
    expect1(gmdv_h, '1', "gmd ceb z counts");

    oi <= '1';
    oceb <= '0';
    settle;
    check1(oo_h, oo_v, "obuf o");
    check1(oob_h, oob_v, "obuf ob");
    expect1(oo_h, '1', "obuf drives");
    expect1(oob_h, '0', "obuf inv");
    check1(oz_h, oz_v, "obuf off");
    expect1(oz_h, 'Z', "obuf path off");
    oi <= 'Z';
    settle;
    check1(oo_h, oo_v, "obuf z");
    expect1(oo_h, 'Z', "obuf z passes");
    expect1(oob_h, 'X', "obuf ob of z");
    oceb <= 'X';
    oi <= '0';
    settle;
    check1(oo_h, oo_v, "obuf ceb x");
    expect1(oo_h, '0', "obuf ceb x still drives");
    oceb <= '1';
    settle;
    check1(oo_h, oo_v, "obuf ceb");
    expect1(oo_h, 'Z', "obuf ceb disables");

    ai <= "1001";
    aceb <= '0';
    settle;
    check1(a0_h, a0_v, "adv0");
    check1(a0b_h, a0b_v, "adv0 ob");
    expect1(a0_h, '1', "adv bit0");
    expect1(a0b_h, '0', "adv bit0 inv");
    check1(a1_h, a1_v, "adv1");
    expect1(a1_h, '0', "adv bit1");
    check1(a3_h, a3_v, "adv3");
    expect1(a3_h, '1', "adv bit3");
    check1(az_h, az_v, "adv off");
    expect1(az_h, 'Z', "adv path off");
    aceb <= '1';
    settle;
    check1(a0_h, a0_v, "adv ceb");
    expect1(a0_h, 'Z', "adv ceb z");

    report "tb_eq_gtm checks " & integer'image(checks) severity note;
    finish;
  end process;
end architecture sim;
