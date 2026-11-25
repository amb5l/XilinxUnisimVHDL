-- MMCME2_ADV. Integer multiply and divide.
-- The Verilog measures the input period with $time and builds a VCO
-- burst of CLKFBOUT_MULT_F cycles on each input edge, then divides that
-- VCO for CLKOUT*. This model follows that integer path: 50 percent duty,
-- zero phase, DIVCLK_DIVIDE, and a direct CLKFBOUT-to-CLKFBIN loop.
-- Fractional multiply or divide, duty other than 0.5, a non-zero phase,
-- fine phase shift, spread spectrum, DRP, and the stopped-clock flags
-- are not the comparison path. An illegal attribute does not $finish.
-- The 1 ps lock tap and the picosecond VCO remainder are not copied;
-- the bench compares the locked waveform.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity mmcm_core is
  generic (
    CLKFBOUT_MULT_F : real := 5.000;
    CLKOUT0_DIVIDE_F : real := 1.000;
    CLKOUT1_DIVIDE : integer := 1;
    CLKOUT2_DIVIDE : integer := 1;
    CLKOUT3_DIVIDE : integer := 1;
    CLKOUT4_DIVIDE : integer := 1;
    CLKOUT5_DIVIDE : integer := 1;
    CLKOUT6_DIVIDE : integer := 1;
    DIVCLK_DIVIDE : integer := 1;
    IS_CLKINSEL_INVERTED : bit := '0';
    IS_PWRDWN_INVERTED : bit := '0';
    IS_RST_INVERTED : bit := '0'
  );
  port (
    CLKFBOUT : out std_ulogic;
    CLKFBOUTB : out std_ulogic;
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
    LOCKED : out std_ulogic;
    CLKFBIN : in std_ulogic;
    CLKIN1 : in std_ulogic;
    CLKIN2 : in std_ulogic;
    CLKINSEL : in std_ulogic;
    PWRDWN : in std_ulogic;
    RST : in std_ulogic
  );
end entity mmcm_core;

architecture sim of mmcm_core is
  function as_int(x : real) return integer is
  begin
    return integer(x);
  end function;

  constant mult : integer := as_int(CLKFBOUT_MULT_F);
  constant div0 : integer := as_int(CLKOUT0_DIVIDE_F);
  constant divclk : integer := DIVCLK_DIVIDE;

  signal gsr : std_ulogic := '1';
  signal clkin, rst_i : std_ulogic;
  signal period : time := 10 ns;
  signal lock_cnt : natural := 0;
  signal fb_found, tst, delay_seen, found_tmp : std_ulogic := '0';
  signal vco, clkout_en : std_ulogic := '0';
  signal clkfb_s, c0, c1, c2, c3, c4, c5, c6 : std_ulogic := '0';
  signal locked_s : std_ulogic := '0';
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  clkin <= CLKIN1 when xor_inv(CLKINSEL, IS_CLKINSEL_INVERTED) = '1' else CLKIN2;
  rst_i <= '1' when gsr = '1'
        or xor_inv(RST, IS_RST_INVERTED) = '1'
        or xor_inv(PWRDWN, IS_PWRDWN_INVERTED) = '1'
      else '0';

  -- Feedback search. Until the loop is seen, every output follows tst,
  -- which toggles on the input. The lock counter starts once that
  -- search has completed.
  fb_tog : process
  begin
    wait on clkin, rst_i;
    if rst_i = '1' then
      tst <= '0';
    elsif rising_edge(clkin) and fb_found = '0' then
      tst <= not tst;
    end if;
  end process;

  fb_edge : process
  begin
    wait on tst, rst_i;
    if rst_i = '1' then
      delay_seen <= '0';
    elsif rising_edge(tst) then
      delay_seen <= '1';
    end if;
  end process;

  fb_hit : process
  begin
    wait on CLKFBIN, rst_i;
    if rst_i = '1' then
      found_tmp <= '0';
    elsif rising_edge(CLKFBIN) and delay_seen = '1' then
      found_tmp <= '1';
    end if;
  end process;

  fb_done : process
  begin
    wait on tst, found_tmp, rst_i;
    if rst_i = '1' then
      fb_found <= '0';
    elsif falling_edge(tst) then
      fb_found <= found_tmp;
    end if;
  end process;

  measure : process
    variable prev : time := 0 ns;
  begin
    wait on clkin, rst_i;
    if rst_i = '1' then
      lock_cnt <= 0;
      prev := 0 ns;
    elsif rising_edge(clkin) then
      if prev /= 0 ns then
        period <= now - prev;
      end if;
      prev := now;
      if fb_found = '1' then
        lock_cnt <= lock_cnt + 1;
      end if;
    end if;
  end process;

  -- pll_lock_time is 12. Outputs turn on md_product clocks later.
  -- md_product is mult * divclk for an integer feedback multiply.
  en_p : process (lock_cnt, rst_i)
    constant en_at : natural := mult * divclk + 12;
  begin
    if rst_i = '1' then
      clkout_en <= '0';
    elsif lock_cnt >= en_at then
      clkout_en <= '1';
    else
      clkout_en <= '0';
    end if;
  end process;

  -- VCO half-period is Tin * DIVCLK_DIVIDE / MULT / 2. The Verilog
  -- restarts a burst on each delayed input edge; a free-running toggle
  -- at that half-period has the same rate. It starts once the lock
  -- counter has passed pll_lock_time (12).
  vco_p : process
    variable half : time;
  begin
    vco <= '0';
    loop
      if rst_i = '1' or lock_cnt < 12 or mult < 1 or divclk < 1 then
        vco <= '0';
        wait on rst_i, lock_cnt;
      else
        half := (period * divclk) / (mult * 2);
        if half = 0 ns then
          half := 1 ns;
        end if;
        -- The first edge is immediate, matching a burst that starts on
        -- the input edge where the lock counter passes 12. The wait also
        -- watches reset so the next start is aligned again.
        vco <= not vco;
        wait on rst_i for half;
      end if;
    end loop;
  end process;

  -- Divider. cnt_max = 2*N-1 and cnt_ht = N is 50 percent, phase 0.
  -- The output uses the count from before this edge, then the count steps.
  div : process (vco, clkout_en, rst_i)
    variable n0, n1, n2, n3, n4, n5, n6, nfb : natural := 0;
    variable armed : boolean := false;
    procedure step(signal y : out std_ulogic; variable n : inout natural; cycles : integer) is
      variable cnt_max, cnt_ht : natural;
    begin
      if cycles < 1 then
        y <= '0';
        n := 0;
      else
        cnt_max := 2 * cycles - 1;
        cnt_ht := cycles;
        if n < cnt_ht then
          y <= '1';
        else
          y <= '0';
        end if;
        if n < cnt_max then
          n := n + 1;
        else
          n := 0;
        end if;
      end if;
    end procedure;
    procedure all_step is
    begin
      step(clkfb_s, nfb, mult);
      step(c0, n0, div0);
      step(c1, n1, CLKOUT1_DIVIDE);
      step(c2, n2, CLKOUT2_DIVIDE);
      step(c3, n3, CLKOUT3_DIVIDE);
      step(c4, n4, CLKOUT4_DIVIDE);
      step(c5, n5, CLKOUT5_DIVIDE);
      step(c6, n6, CLKOUT6_DIVIDE);
    end procedure;
  begin
    if rst_i = '1' or clkout_en = '0' then
      n0 := 0; n1 := 0; n2 := 0; n3 := 0; n4 := 0; n5 := 0; n6 := 0; nfb := 0;
      c0 <= '0'; c1 <= '0'; c2 <= '0'; c3 <= '0';
      c4 <= '0'; c5 <= '0'; c6 <= '0'; clkfb_s <= '0';
      armed := false;
    elsif vco'event then
      all_step;
      armed := true;
    elsif not armed then
      -- clkout_en rises one delta after the VCO edge that landed on the
      -- same input edge, so that edge was cleared above. Count it now.
      all_step;
      armed := true;
    end if;
  end process;

  -- locked_en_time = md + (md + 12) + 2, then hold for Tin * divclk * mult.
  lock_p : process
    constant lock_at : natural := mult * divclk + (mult * divclk + 12) + 2;
    variable hold : time;
  begin
    locked_s <= '0';
    loop
      wait on lock_cnt, clkout_en, rst_i;
      if rst_i = '0' and clkout_en = '1' and lock_cnt >= lock_at then
        hold := period * divclk * mult;
        wait for hold;
        if rst_i = '0' then
          locked_s <= '1';
        end if;
        wait until rst_i = '1';
        locked_s <= '0';
      elsif rst_i = '1' then
        locked_s <= '0';
      end if;
    end loop;
  end process;

  CLKFBOUT  <= clkfb_s when fb_found = '1' else tst;
  CLKFBOUTB <= not clkfb_s when fb_found = '1' else not tst;
  CLKOUT0   <= c0 when fb_found = '1' else tst;
  CLKOUT0B  <= not c0 when fb_found = '1' else not tst;
  CLKOUT1   <= c1 when fb_found = '1' else tst;
  CLKOUT1B  <= not c1 when fb_found = '1' else not tst;
  CLKOUT2   <= c2 when fb_found = '1' else tst;
  CLKOUT2B  <= not c2 when fb_found = '1' else not tst;
  CLKOUT3   <= c3 when fb_found = '1' else tst;
  CLKOUT3B  <= not c3 when fb_found = '1' else not tst;
  CLKOUT4   <= c4 when fb_found = '1' else tst;
  CLKOUT5   <= c5 when fb_found = '1' else tst;
  CLKOUT6   <= c6 when fb_found = '1' else tst;
  LOCKED    <= locked_s;
end architecture sim;

library ieee;
use ieee.std_logic_1164.all;

entity MMCME2_ADV is
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
    COMPENSATION : string := "ZHOLD";
    DIVCLK_DIVIDE : integer := 1;
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
end entity MMCME2_ADV;

library unisim;

architecture sim of MMCME2_ADV is
begin
  -- DRP, fine PS, and the stopped-clock detectors are not modelled.
  CLKFBSTOPPED <= '0';
  CLKINSTOPPED <= '0';
  DO <= (others => '0');
  DRDY <= '0';
  PSDONE <= '0';

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
      CLKFBIN => CLKFBIN, CLKIN1 => CLKIN1, CLKIN2 => CLKIN2,
      CLKINSEL => CLKINSEL, PWRDWN => PWRDWN, RST => RST
    );
end architecture sim;
