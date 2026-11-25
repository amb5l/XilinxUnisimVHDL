-- HARD_SYNC, RIU_OR, HPIO_VREF and ZHOLD_DELAY against the submodule
-- Verilog. XIL_TIMING is left undefined. HARD_SYNC's 100 ps specify
-- path is not copied; the bench waits 5 ns after the clock. ZHOLD_DELAY's
-- 200 ps tap delay is the functional delay and is compared.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_misc is
end entity tb_eq_misc;

architecture sim of tb_eq_misc is
  signal clk2, clk3 : std_ulogic := '0';
  signal din : std_ulogic := '0';
  signal hs2_h, hs2_v, hs3_h, hs3_v : std_ulogic;
  signal riu_lo, riu_up : std_logic_vector(15 downto 0) := (others => '0');
  signal riu_vl, riu_vu : std_ulogic := '0';
  signal riu_h, riu_v : std_logic_vector(15 downto 0);
  signal riu_ok_h, riu_ok_v : std_ulogic;
  signal tune : std_logic_vector(6 downto 0) := (others => '0');
  signal vref_h, vref_v : std_ulogic;
  signal dly0, dlyd : std_ulogic := '0';
  signal fab0_h, fab0_v, iff0_h, iff0_v : std_ulogic;
  signal fab_h, fab_v, iff_h, iff_v : std_ulogic;

  component HARD_SYNC is
    generic (
      INIT : bit := '0';
      IS_CLK_INVERTED : bit := '0';
      LATENCY : integer := 2
    );
    port (
      DOUT : out std_ulogic;
      CLK : in std_ulogic;
      DIN : in std_ulogic
    );
  end component;

  component RIU_OR is
    generic (
      SIM_DEVICE : string := "ULTRASCALE";
      SIM_VERSION : real := 2.0
    );
    port (
      RIU_RD_DATA : out std_logic_vector(15 downto 0);
      RIU_RD_VALID : out std_ulogic;
      RIU_RD_DATA_LOW : in std_logic_vector(15 downto 0);
      RIU_RD_DATA_UPP : in std_logic_vector(15 downto 0);
      RIU_RD_VALID_LOW : in std_ulogic;
      RIU_RD_VALID_UPP : in std_ulogic
    );
  end component;

  component HPIO_VREF is
    generic (VREF_CNTR : string := "OFF");
    port (
      VREF : out std_ulogic;
      FABRIC_VREF_TUNE : in std_logic_vector(6 downto 0)
    );
  end component;

  component ZHOLD_DELAY is
    generic (
      IS_DLYIN_INVERTED : bit := '0';
      ZHOLD_FABRIC : string := "DEFAULT";
      ZHOLD_IFF : string := "DEFAULT"
    );
    port (
      DLYFABRIC : out std_ulogic;
      DLYIFF : out std_ulogic;
      DLYIN : in std_ulogic
    );
  end component;
begin
  u_hs2_h : entity unisim.HARD_SYNC
    generic map (INIT => '0', LATENCY => 2)
    port map (DOUT => hs2_h, CLK => clk2, DIN => din);
  u_hs2_v : HARD_SYNC
    generic map (INIT => '0', LATENCY => 2)
    port map (DOUT => hs2_v, CLK => clk2, DIN => din);

  u_hs3_h : entity unisim.HARD_SYNC
    generic map (INIT => '1', IS_CLK_INVERTED => '1', LATENCY => 3)
    port map (DOUT => hs3_h, CLK => clk3, DIN => din);
  u_hs3_v : HARD_SYNC
    generic map (INIT => '1', IS_CLK_INVERTED => '1', LATENCY => 3)
    port map (DOUT => hs3_v, CLK => clk3, DIN => din);

  u_riu_h : entity unisim.RIU_OR
    port map (
      RIU_RD_DATA => riu_h,
      RIU_RD_VALID => riu_ok_h,
      RIU_RD_DATA_LOW => riu_lo,
      RIU_RD_DATA_UPP => riu_up,
      RIU_RD_VALID_LOW => riu_vl,
      RIU_RD_VALID_UPP => riu_vu
    );
  u_riu_v : RIU_OR
    port map (
      RIU_RD_DATA => riu_v,
      RIU_RD_VALID => riu_ok_v,
      RIU_RD_DATA_LOW => riu_lo,
      RIU_RD_DATA_UPP => riu_up,
      RIU_RD_VALID_LOW => riu_vl,
      RIU_RD_VALID_UPP => riu_vu
    );

  u_vref_h : entity unisim.HPIO_VREF
    port map (VREF => vref_h, FABRIC_VREF_TUNE => tune);
  u_vref_v : HPIO_VREF
    port map (VREF => vref_v, FABRIC_VREF_TUNE => tune);

  u_z0_h : entity unisim.ZHOLD_DELAY
    port map (DLYFABRIC => fab0_h, DLYIFF => iff0_h, DLYIN => dly0);
  u_z0_v : ZHOLD_DELAY
    port map (DLYFABRIC => fab0_v, DLYIFF => iff0_v, DLYIN => dly0);

  u_zd_h : entity unisim.ZHOLD_DELAY
    generic map (ZHOLD_FABRIC => "2", ZHOLD_IFF => "5")
    port map (DLYFABRIC => fab_h, DLYIFF => iff_h, DLYIN => dlyd);
  u_zd_v : ZHOLD_DELAY
    generic map (ZHOLD_FABRIC => "2", ZHOLD_IFF => "5")
    port map (DLYFABRIC => fab_v, DLYIFF => iff_v, DLYIN => dlyd);

  stim : process
    variable checks : integer := 0;
    variable sh2 : std_ulogic_vector(2 downto 0) := "000";
    variable sh3 : std_ulogic_vector(2 downto 0) := "111";

    -- NVC presents a Verilog X on a VHDL port as U.
    function from_vlog(v : std_ulogic) return std_ulogic is
    begin
      if v = 'U' then
        return 'X';
      end if;
      return v;
    end function;

    function from_vlogv(v : std_logic_vector) return std_logic_vector is
      variable r : std_logic_vector(v'range);
    begin
      for i in v'range loop
        r(i) := from_vlog(v(i));
      end loop;
      return r;
    end function;

    procedure check1(h, v : std_ulogic; what : string) is
    begin
      checks := checks + 1;
      if h /= from_vlog(v) then
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(v)
          & " at " & time'image(now) severity failure;
      end if;
    end procedure;

    procedure checkv(h, v : std_logic_vector; what : string) is
    begin
      checks := checks + h'length;
      if h /= from_vlogv(v) then
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(v)
          & " at " & time'image(now) severity failure;
      end if;
    end procedure;

    procedure expect1(got, exp : std_ulogic; what : string) is
    begin
      if got /= exp then
        report what & " expected " & to_string(exp) & " got " & to_string(got)
          severity failure;
      end if;
    end procedure;

    -- Active edge of the non-inverted cell. DIN changes 1 ns before it.
    procedure rise2(d : std_ulogic) is
    begin
      din <= d;
      clk2 <= '0';
      wait for 1 ns;
      clk2 <= '1';
      wait for 5 ns;
      sh2 := sh2(1 downto 0) & d;
      check1(hs2_h, hs2_v, "hs2");
      expect1(hs2_h, sh2(1) and '1', "hs2 golden");
    end procedure;

    -- Active edge of the inverted cell is the falling pin.
    procedure fall3(d : std_ulogic) is
    begin
      din <= d;
      clk3 <= '1';
      wait for 1 ns;
      clk3 <= '0';
      wait for 5 ns;
      sh3 := sh3(1 downto 0) & d;
      check1(hs3_h, hs3_v, "hs3");
      expect1(hs3_h, sh3(2) and '1', "hs3 golden");
    end procedure;
  begin
    wait for 1 ns;
    check1(vref_h, vref_v, "vref");
    expect1(vref_h, '1', "vref level");
    tune <= "1010101";
    wait for 1 ns;
    check1(vref_h, vref_v, "vref tune");
    expect1(vref_h, '1', "vref held");

    riu_lo <= X"00FF";
    riu_up <= X"0F0F";
    riu_vl <= '1';
    riu_vu <= '1';
    wait for 1 ns;
    checkv(riu_h, riu_v, "riu data");
    check1(riu_ok_h, riu_ok_v, "riu valid");
    expect1(riu_ok_h, '1', "riu both valid");
    if riu_h /= X"0FFF" then
      report "riu or" severity failure;
    end if;
    riu_vu <= '0';
    wait for 1 ns;
    check1(riu_ok_h, riu_ok_v, "riu one valid");
    expect1(riu_ok_h, '0', "riu and");
    riu_vl <= 'X';
    riu_vu <= '1';
    riu_lo <= (others => 'X');
    riu_up <= (others => '0');
    wait for 1 ns;
    checkv(riu_h, riu_v, "riu x or 0");
    check1(riu_ok_h, riu_ok_v, "riu x valid");
    riu_lo <= (others => 'Z');
    wait for 1 ns;
    checkv(riu_h, riu_v, "riu z or 0");
    riu_up <= (others => '1');
    riu_vl <= '0';
    riu_vu <= 'Z';
    wait for 1 ns;
    checkv(riu_h, riu_v, "riu z or 1");
    check1(riu_ok_h, riu_ok_v, "riu 0 and z");
    expect1(riu_ok_h, '0', "riu 0 and z level");

    check1(fab0_h, fab0_v, "zhold0 init");
    check1(iff0_h, iff0_v, "zhold0 iff init");
    dly0 <= '1';
    wait for 1 ns;
    check1(fab0_h, fab0_v, "zhold0 rise");
    check1(iff0_h, iff0_v, "zhold0 iff rise");
    expect1(fab0_h, '1', "zhold0 followed");
    dly0 <= 'Z';
    wait for 1 ns;
    check1(fab0_h, fab0_v, "zhold0 z");
    check1(iff0_h, iff0_v, "zhold0 iff z");
    dly0 <= '0';
    wait for 1 ns;

    -- 2 taps is 400 ps, 5 taps is 1 ns. On this NVC the Verilog
    -- `<= #(200 ps * taps)` updates immediately, so the bench compares
    -- the two only after the VHDL delay has elapsed. A 100 ps pulse
    -- is checked on the VHDL side only. Possible NVC bug.
    dlyd <= '0';
    wait for 2 ns;
    check1(fab_h, fab_v, "zhold settle fab");
    check1(iff_h, iff_v, "zhold settle iff");
    expect1(fab_h, '0', "zhold settled");
    dlyd <= '1';
    wait for 100 ps;
    expect1(fab_h, '0', "zhold fab waiting");
    expect1(iff_h, '0', "zhold iff waiting");
    wait for 2 ns;
    check1(fab_h, fab_v, "zhold fab rise");
    check1(iff_h, iff_v, "zhold iff rise");
    expect1(fab_h, '1', "zhold fab rose");
    expect1(iff_h, '1', "zhold iff rose");
    dlyd <= '0';
    wait for 100 ps;
    expect1(fab_h, '1', "zhold fab held");
    expect1(iff_h, '1', "zhold iff held");
    wait for 2 ns;
    check1(fab_h, fab_v, "zhold fab fall");
    check1(iff_h, iff_v, "zhold iff fall");
    expect1(fab_h, '0', "zhold fab fell");
    dlyd <= '1';
    wait for 100 ps;
    dlyd <= '0';
    wait for 350 ps;
    expect1(fab_h, '1', "zhold short pulse");
    wait for 2 ns;
    check1(fab_h, fab_v, "zhold after pulse");
    expect1(fab_h, '0', "zhold pulse ended");

    -- glbl ROC_WIDTH is 100 ns. On this NVC the Verilog delay is about
    -- 100 ps, so a clock before 100 ns would shift the Verilog model
    -- while the VHDL GSR still forces INIT. Compared only after both
    -- have released. Possible NVC bug.
    din <= '1';
    check1(hs2_h, hs2_v, "hs2 init");
    check1(hs3_h, hs3_v, "hs3 init");
    expect1(hs2_h, '0', "hs2 init level");
    expect1(hs3_h, '1', "hs3 init level");
    wait for 120 ns;
    check1(hs2_h, hs2_v, "hs2 after gsr");
    check1(hs3_h, hs3_v, "hs3 after gsr");
    expect1(hs2_h, '0', "hs2 held init");
    expect1(hs3_h, '1', "hs3 held init");
    rise2('1');
    rise2('1');
    rise2('0');
    rise2('1');
    rise2('X');
    rise2('Z');
    rise2('0');
    fall3('0');
    fall3('0');
    fall3('0');
    fall3('1');
    fall3('1');
    fall3('Z');
    fall3('0');

    report "PASS tb_eq_misc checks=" & integer'image(checks);
    finish;
  end process;
end architecture sim;
