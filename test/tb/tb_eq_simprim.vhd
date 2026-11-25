-- SIMPRIM RAMs and input buffers.
-- The Verilog is analysed with XIL_TIMING defined. Delayed nets are
-- zero-delay copies, so the RAM writes are compared with the Verilog.
-- DPHY_DIFFINBUF is compared too. Its LP mode needs a Strong strength,
-- which std_ulogic does not have, so both sides stay out of LP mode.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_simprim is
end entity tb_eq_simprim;

architecture sim of tb_eq_simprim is
  signal clk, iclk : std_ulogic := '0';
  signal din, we : std_ulogic := '0';
  signal radr, wadr : std_logic_vector(5 downto 0) := (others => '0');
  signal hi : std_logic_vector(2 downto 0) := (others => '0');

  signal d32_h, d32_v, d32i_h, d32i_v : std_ulogic;
  signal s32_h, s32_v : std_ulogic;
  signal d64_h, d64_v, d64m_h, d64m_v : std_ulogic;
  signal s64_h, s64_v, s64i_h, s64i_v : std_ulogic;
  signal m64_h, m64_v : std_ulogic;

  signal ii, ibd, imd, tt : std_ulogic := '0';
  signal ic_h, ic_v, ict_h, ict_v : std_ulogic;

  signal pad : std_ulogic := '0';
  signal osc : std_logic_vector(3 downto 0) := "0000";
  signal osc_en : std_ulogic := '0';
  signal in_h, in_v, in5, in0 : std_ulogic;

  signal dp, dn : std_ulogic := '0';
  signal den : std_logic_vector(1 downto 0) := "00";
  signal dosc : std_logic_vector(3 downto 0) := "0000";
  signal diff_h, diffb_h, diff_v, diffb_v : std_ulogic;
  signal diffq_h, diffqb_h, diffq_v, diffqb_v : std_ulogic;
  signal dsc_o, dsc_ob : std_ulogic;

  signal hsdis, ldis, di, dib : std_ulogic := '0';
  signal hs, lpp, lpn : std_ulogic;
  signal hs_v, lpp_v, lpn_v : std_ulogic;

  constant init32 : bit_vector(31 downto 0) := X"00000001";
  constant init64 : bit_vector(63 downto 0) := X"0000000000000001";

  component RAMD32 is
    generic (
      INIT : bit_vector(31 downto 0) := X"00000000";
      IS_CLK_INVERTED : bit := '0'
    );
    port (
      O : out std_ulogic;
      CLK : in std_ulogic;
      I : in std_ulogic;
      RADR0, RADR1, RADR2, RADR3, RADR4 : in std_ulogic;
      WADR0, WADR1, WADR2, WADR3, WADR4 : in std_ulogic;
      WE : in std_ulogic
    );
  end component;
  component RAMS32 is
    generic (
      INIT : bit_vector(31 downto 0) := X"00000000";
      IS_CLK_INVERTED : bit := '0'
    );
    port (
      O : out std_ulogic;
      ADR0, ADR1, ADR2, ADR3, ADR4 : in std_ulogic;
      CLK, I, WE : in std_ulogic
    );
  end component;
  component RAMD64E is
    generic (
      INIT : bit_vector(63 downto 0) := X"0000000000000000";
      IS_CLK_INVERTED : bit := '0';
      RAM_ADDRESS_MASK : bit_vector(1 downto 0) := "00";
      RAM_ADDRESS_SPACE : bit_vector(1 downto 0) := "00"
    );
    port (
      O : out std_ulogic;
      CLK, I : in std_ulogic;
      RADR0, RADR1, RADR2, RADR3, RADR4, RADR5 : in std_ulogic;
      WADR0, WADR1, WADR2, WADR3, WADR4, WADR5, WADR6, WADR7 : in std_ulogic;
      WE : in std_ulogic
    );
  end component;
  component RAMS64E is
    generic (
      INIT : bit_vector(63 downto 0) := X"0000000000000000";
      IS_CLK_INVERTED : bit := '0';
      RAM_ADDRESS_MASK : bit_vector(1 downto 0) := "00";
      RAM_ADDRESS_SPACE : bit_vector(1 downto 0) := "00"
    );
    port (
      O : out std_ulogic;
      ADR0, ADR1, ADR2, ADR3, ADR4, ADR5 : in std_ulogic;
      CLK, I, WADR6, WADR7, WE : in std_ulogic
    );
  end component;
  component RAMS64E1 is
    generic (
      INIT : bit_vector(63 downto 0) := X"0000000000000000";
      IS_CLK_INVERTED : bit := '0';
      RAM_ADDRESS_MASK : bit_vector(2 downto 0) := "000";
      RAM_ADDRESS_SPACE : bit_vector(2 downto 0) := "000"
    );
    port (
      O : out std_ulogic;
      ADR0, ADR1, ADR2, ADR3, ADR4, ADR5 : in std_ulogic;
      CLK, I, WADR6, WADR7, WADR8, WE : in std_ulogic
    );
  end component;
  component RAMD32M64 is
    generic (
      INIT : bit_vector(63 downto 0) := X"0000000000000000";
      IS_CLK_INVERTED : bit := '0'
    );
    port (
      O : out std_ulogic;
      CLK, I : in std_ulogic;
      RADR0, RADR1, RADR2, RADR3, RADR4, RADR5 : in std_ulogic;
      WADR0, WADR1, WADR2, WADR3, WADR4, WE : in std_ulogic
    );
  end component;
  component IBUFCTRL is
    generic (
      ISTANDARD : string := "UNUSED";
      USE_IBUFDISABLE : boolean := FALSE
    );
    port (
      O : out std_ulogic;
      I, IBUFDISABLE, INTERMDISABLE, T : in std_ulogic
    );
  end component;
  component INBUF is
    generic (
      IBUF_LOW_PWR : boolean := TRUE;
      ISTANDARD : string := "UNUSED";
      SIM_INPUT_BUFFER_OFFSET : integer := 0
    );
    port (
      O : out std_ulogic;
      OSC : in std_logic_vector(3 downto 0);
      OSC_EN, PAD, VREF : in std_ulogic
    );
  end component;
  component DIFFINBUF is
    generic (
      DIFF_TERM : boolean := FALSE;
      DQS_BIAS : boolean := FALSE;
      IBUF_LOW_PWR : boolean := TRUE;
      ISTANDARD : string := "UNUSED";
      SIM_INPUT_BUFFER_OFFSET : integer := 0
    );
    port (
      O, O_B : out std_ulogic;
      DIFF_IN_N, DIFF_IN_P : in std_ulogic;
      OSC : in std_logic_vector(3 downto 0);
      OSC_EN : in std_logic_vector(1 downto 0);
      VREF : in std_ulogic
    );
  end component;
  component DPHY_DIFFINBUF is
    generic (
      DIFF_TERM : boolean := TRUE;
      ISTANDARD : string := "DEFAULT"
    );
    port (
      HSRX_O, LPRX_O_N, LPRX_O_P : out std_ulogic;
      HSRX_DISABLE, I, IB, LPRX_DISABLE : in std_ulogic
    );
  end component;

  function from_vlog(v : std_ulogic) return std_ulogic is
  begin
    if v = 'U' then
      return 'X';
    end if;
    return v;
  end function;

  function bitat(n, b : natural) return std_ulogic is
  begin
    if (n / (2 ** b)) mod 2 = 1 then
      return '1';
    end if;
    return '0';
  end function;
begin
  u_d32_h : entity unisim.RAMD32 generic map (INIT => init32)
    port map (d32_h, clk, din,
      radr(0), radr(1), radr(2), radr(3), radr(4),
      wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), we);
  u_d32_v : RAMD32 generic map (INIT => init32)
    port map (d32_v, clk, din,
      radr(0), radr(1), radr(2), radr(3), radr(4),
      wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), we);
  u_d32i_h : entity unisim.RAMD32 generic map (INIT => init32, IS_CLK_INVERTED => '1')
    port map (d32i_h, iclk, din,
      radr(0), radr(1), radr(2), radr(3), radr(4),
      wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), we);
  u_d32i_v : RAMD32 generic map (INIT => init32, IS_CLK_INVERTED => '1')
    port map (d32i_v, iclk, din,
      radr(0), radr(1), radr(2), radr(3), radr(4),
      wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), we);

  u_s32_h : entity unisim.RAMS32 generic map (INIT => init32)
    port map (s32_h, wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), clk, din, we);
  u_s32_v : RAMS32 generic map (INIT => init32)
    port map (s32_v, wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), clk, din, we);

  u_d64_h : entity unisim.RAMD64E generic map (INIT => init64)
    port map (d64_h, clk, din,
      radr(0), radr(1), radr(2), radr(3), radr(4), radr(5),
      wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), wadr(5), hi(0), hi(1), we);
  u_d64_v : RAMD64E generic map (INIT => init64)
    port map (d64_v, clk, din,
      radr(0), radr(1), radr(2), radr(3), radr(4), radr(5),
      wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), wadr(5), hi(0), hi(1), we);
  u_d64m_h : entity unisim.RAMD64E
    generic map (INIT => init64, RAM_ADDRESS_MASK => "11")
    port map (d64m_h, clk, din,
      radr(0), radr(1), radr(2), radr(3), radr(4), radr(5),
      wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), wadr(5), hi(0), hi(1), we);
  u_d64m_v : RAMD64E
    generic map (INIT => init64, RAM_ADDRESS_MASK => "11")
    port map (d64m_v, clk, din,
      radr(0), radr(1), radr(2), radr(3), radr(4), radr(5),
      wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), wadr(5), hi(0), hi(1), we);

  u_s64_h : entity unisim.RAMS64E generic map (INIT => init64)
    port map (s64_h, wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), wadr(5),
      clk, din, hi(0), hi(1), we);
  u_s64_v : RAMS64E generic map (INIT => init64)
    port map (s64_v, wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), wadr(5),
      clk, din, hi(0), hi(1), we);
  u_s64i_h : entity unisim.RAMS64E1 generic map (INIT => init64)
    port map (s64i_h, wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), wadr(5),
      clk, din, hi(0), hi(1), hi(2), we);
  u_s64i_v : RAMS64E1 generic map (INIT => init64)
    port map (s64i_v, wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), wadr(5),
      clk, din, hi(0), hi(1), hi(2), we);

  u_m64_h : entity unisim.RAMD32M64 generic map (INIT => init64)
    port map (m64_h, clk, din,
      radr(0), radr(1), radr(2), radr(3), radr(4), radr(5),
      wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), we);
  u_m64_v : RAMD32M64 generic map (INIT => init64)
    port map (m64_v, clk, din,
      radr(0), radr(1), radr(2), radr(3), radr(4), radr(5),
      wadr(0), wadr(1), wadr(2), wadr(3), wadr(4), we);

  u_ic_h : entity unisim.IBUFCTRL
    port map (ic_h, ii, ibd, imd, tt);
  u_ic_v : IBUFCTRL
    port map (ic_v, ii, ibd, imd, tt);
  u_ict_h : entity unisim.IBUFCTRL generic map (USE_IBUFDISABLE => TRUE)
    port map (ict_h, ii, ibd, imd, tt);
  u_ict_v : IBUFCTRL generic map (USE_IBUFDISABLE => TRUE)
    port map (ict_v, ii, ibd, imd, tt);

  u_in_h : entity unisim.INBUF
    port map (in_h, osc, '0', pad, '0');
  u_in_v : INBUF
    port map (in_v, osc, '0', pad, '0');
  u_in5 : entity unisim.INBUF generic map (SIM_INPUT_BUFFER_OFFSET => 5)
    port map (in5, osc, osc_en, pad, '0');
  u_in0 : entity unisim.INBUF
    port map (in0, osc, osc_en, pad, '0');

  u_df_h : entity unisim.DIFFINBUF
    port map (diff_h, diffb_h, dn, dp, dosc, "00", '0');
  u_df_v : DIFFINBUF
    port map (diff_v, diffb_v, dn, dp, dosc, "00", '0');
  u_dfq_h : entity unisim.DIFFINBUF generic map (DQS_BIAS => TRUE)
    port map (diffq_h, diffqb_h, dn, dp, dosc, "00", '0');
  u_dfq_v : DIFFINBUF generic map (DQS_BIAS => TRUE)
    port map (diffq_v, diffqb_v, dn, dp, dosc, "00", '0');
  u_dsc : entity unisim.DIFFINBUF
    port map (dsc_o, dsc_ob, dn, dp, dosc, den, '0');

  u_dp : entity unisim.DPHY_DIFFINBUF
    port map (hs, lpn, lpp, hsdis, di, dib, ldis);
  u_dp_v : DPHY_DIFFINBUF
    port map (hs_v, lpn_v, lpp_v, hsdis, di, dib, ldis);

  stim : process is
    variable n : natural := 0;

    procedure eq(name : string; got, exp : std_ulogic) is
    begin
      n := n + 1;
      assert got = from_vlog(exp)
        report name & " VHDL=" & std_ulogic'image(got)
          & " Verilog=" & std_ulogic'image(from_vlog(exp))
        severity failure;
    end procedure;

    procedure expect(name : string; got, exp : std_ulogic) is
    begin
      n := n + 1;
      assert got = exp
        report name & " got " & std_ulogic'image(got)
          & " expected " & std_ulogic'image(exp)
        severity failure;
    end procedure;

    procedure step(delay : time := 1 ns) is
    begin
      wait for delay;
    end procedure;

    procedure rise is
    begin
      clk <= '1';
      step;
      clk <= '0';
      step;
    end procedure;

    procedure put_addr(signal s : out std_logic_vector; value : natural) is
    begin
      for b in s'range loop
        s(b) <= bitat(value, b);
      end loop;
    end procedure;
  begin
    step;
    expect("RAMD32 init 1", d32_h, '1');
    eq("RAMD32 init 1", d32_h, d32_v);
    expect("RAMS32 init 1", s32_h, '1');
    eq("RAMS32 init 1", s32_h, s32_v);
    expect("RAMD64E init 1", d64_h, '1');
    eq("RAMD64E init 1", d64_h, d64_v);
    expect("RAMS64E init 1", s64_h, '1');
    eq("RAMS64E init 1", s64_h, s64_v);
    expect("RAMS64E1 init 1", s64i_h, '1');
    eq("RAMS64E1 init 1", s64i_h, s64i_v);
    eq("RAMD32M64 Z", m64_h, m64_v);
    expect("RAMD32M64 Z", m64_h, 'Z');

    we <= '0';
    din <= '0';
    rise;
    expect("RAMD32 WE0 holds", d32_h, '1');
    eq("RAMD32 WE0 holds", d32_h, d32_v);

    -- Address-space bits block the write unless the mask opens them.
    -- RAMD32 and RAMS32 ignore those pins, so this edge does write them.
    hi <= "001";
    din <= '0';
    we <= '1';
    rise;
    expect("RAMD64E masked holds", d64_h, '1');
    eq("RAMD64E masked holds", d64_h, d64_v);
    expect("RAMD64E open wrote", d64m_h, '0');
    eq("RAMD64E open wrote", d64m_h, d64m_v);
    expect("RAMS64E masked holds", s64_h, '1');
    eq("RAMS64E masked holds", s64_h, s64_v);
    expect("RAMS64E1 masked holds", s64i_h, '1');
    eq("RAMS64E1 masked holds", s64i_h, s64i_v);
    hi <= "000";

    we <= '1';
    din <= '1';
    rise;
    expect("RAMD32 reload", d32_h, '1');
    eq("RAMD32 reload", d32_h, d32_v);
    we <= 'Z';
    din <= '0';
    rise;
    expect("RAMD32 WEZ wrote", d32_h, '0');
    eq("RAMD32 WEZ wrote", d32_h, d32_v);
    expect("RAMS32 WEZ wrote", s32_h, '0');
    eq("RAMS32 WEZ wrote", s32_h, s32_v);
    expect("RAMD64E WEZ wrote", d64_h, '0');
    eq("RAMD64E WEZ wrote", d64_h, d64_v);

    we <= 'X';
    din <= '1';
    rise;
    expect("RAMD32 WEX holds", d32_h, '0');
    eq("RAMD32 WEX holds", d32_h, d32_v);

    we <= '1';
    wadr(0) <= 'X';
    din <= '1';
    rise;
    wadr(0) <= '0';
    step;
    expect("RAMD32 WADR X holds", d32_h, '0');
    eq("RAMD32 WADR X holds", d32_h, d32_v);

    radr(0) <= 'X';
    step;
    expect("RAMD32 RADR X", d32_h, 'X');
    eq("RAMD32 RADR X", d32_h, d32_v);
    radr <= (others => '0');

    for i in 0 to 31 loop
      put_addr(wadr, i);
      put_addr(radr, i);
      din <= bitat(i, 0);
      we <= '1';
      rise;
      expect("RAMD32 data", d32_h, bitat(i, 0));
      eq("RAMD32 data", d32_h, d32_v);
      expect("RAMS32 data", s32_h, bitat(i, 0));
      eq("RAMS32 data", s32_h, s32_v);
    end loop;
    -- Read port stays on the last write while the write port moves.
    put_addr(wadr, 0);
    din <= '1';
    rise;
    expect("RAMD32 read holds", d32_h, '1');
    eq("RAMD32 read holds", d32_h, d32_v);
    expect("RAMS32 moved", s32_h, '1');
    eq("RAMS32 moved", s32_h, s32_v);

    for i in 0 to 63 loop
      put_addr(wadr, i);
      put_addr(radr, i);
      din <= bitat(i, 1);
      rise;
      expect("RAMD64E data", d64_h, bitat(i, 1));
      eq("RAMD64E data", d64_h, d64_v);
      eq("RAMD32M64 stays Z", m64_h, m64_v);
      expect("RAMD32M64 stays Z", m64_h, 'Z');
    end loop;

    -- Inverted clock captures on the falling edge of the pin.
    -- This instance has not been written, so address 0 is still the INIT 1.
    put_addr(wadr, 0);
    put_addr(radr, 0);
    din <= '0';
    we <= '1';
    iclk <= '1';
    step;
    expect("RAMD32 inv rise holds", d32i_h, '1');
    eq("RAMD32 inv rise holds", d32i_h, d32i_v);
    iclk <= '0';
    step;
    expect("RAMD32 inv fall wrote", d32i_h, '0');
    eq("RAMD32 inv fall wrote", d32i_h, d32i_v);

    for a in 0 to 3 loop
      ii <= bitat(a, 0);
      ibd <= bitat(a, 1);
      step;
      for b in 0 to 3 loop
        tt <= bitat(b, 0);
        imd <= bitat(b, 1);
        step;
        eq("IBUFCTRL", ic_h, ic_v);
        eq("IBUFCTRL dis", ict_h, ict_v);
        expect("IBUFCTRL follows I", ic_h, ii);
      end loop;
    end loop;
    ii <= '1';
    ibd <= '0';
    tt <= '1';
    step;
    expect("IBUFCTRL true passes", ict_h, '1');
    tt <= '0';
    step;
    expect("IBUFCTRL true T0", ict_h, '0');
    ibd <= '1';
    tt <= '1';
    step;
    expect("IBUFCTRL true disable", ict_h, '0');
    ibd <= '0';
    tt <= 'X';
    step;
    expect("IBUFCTRL true X", ict_h, 'X');

    for a in 0 to 3 loop
      pad <= bitat(a, 0);
      if a > 1 then
        pad <= 'X' when a = 2 else 'Z';
      end if;
      step;
      eq("INBUF pad", in_h, in_v);
      expect("INBUF pad", in_h, pad);
    end loop;

    -- Oscillator, from the Verilog equations (OSC_EN === 1).
    pad <= 'Z';
    osc_en <= '0';
    osc <= "0000";
    step;
    expect("INBUF en0", in5, 'Z');
    osc_en <= '1';
    step;
    expect("INBUF osc0", in5, '1');
    osc <= "1001";
    step;
    expect("INBUF +5", in5, '0');
    osc <= "0001";
    step;
    expect("INBUF -5", in5, '1');
    osc <= "1010";
    step;
    expect("INBUF +10", in5, '0');
    osc <= "0010";
    step;
    expect("INBUF -10", in5, '1');
    osc <= "XXXX";
    step;
    expect("INBUF oscX holds", in5, '1');
    osc <= "1000";
    step;
    expect("INBUF offset5 code0", in5, '1');
    expect("INBUF toggle", in0, '0');
    osc_en <= 'X';
    pad <= '0';
    step;
    expect("INBUF enX", in5, '0');
    osc_en <= '0';
    step;
    expect("INBUF en0 again", in5, '0');

    dp <= '1';
    dn <= '0';
    step;
    eq("DIFFINBUF 10", diff_h, diff_v);
    eq("DIFFINBUF 10b", diffb_h, diffb_v);
    expect("DIFFINBUF 10", diff_h, '1');
    expect("DIFFINBUF 10b", diffb_h, '0');
    eq("DIFFINBUF bias 10", diffq_h, diffq_v);
    dp <= '0';
    dn <= '1';
    step;
    eq("DIFFINBUF 01", diff_h, diff_v);
    expect("DIFFINBUF 01", diff_h, '0');
    expect("DIFFINBUF 01b", diffb_h, '1');
    dp <= 'Z';
    dn <= 'Z';
    step;
    eq("DIFFINBUF ZZ", diff_h, diff_v);
    eq("DIFFINBUF ZZb", diffb_h, diffb_v);
    expect("DIFFINBUF ZZ", diff_h, 'X');
    eq("DIFFINBUF bias ZZ", diffq_h, diffq_v);
    eq("DIFFINBUF bias ZZb", diffqb_h, diffqb_v);
    expect("DIFFINBUF bias ZZ", diffq_h, '0');
    expect("DIFFINBUF bias ZZb", diffqb_h, '1');
    dp <= 'X';
    dn <= '0';
    step;
    eq("DIFFINBUF X", diff_h, diff_v);
    expect("DIFFINBUF X", diff_h, 'X');
    dp <= '1';
    dn <= '1';
    step;
    eq("DIFFINBUF hold", diff_h, diff_v);
    expect("DIFFINBUF hold", diff_h, 'X');

    den <= "11";
    dosc <= "1001";
    step;
    expect("DIFFINBUF osc", dsc_o, '0');
    expect("DIFFINBUF oscb", dsc_ob, '1');
    den <= "01";
    step;
    expect("DIFFINBUF half", dsc_o, 'X');
    expect("DIFFINBUF halfb", dsc_ob, 'X');
    den <= "00";
    dp <= '0';
    dn <= '1';
    step;
    expect("DIFFINBUF back", dsc_o, '0');
    expect("DIFFINBUF backb", dsc_ob, '1');

    step(2 ps);
    expect("DPHY lp0", lpp, '0');
    eq("DPHY lp0", lpp, lpp_v);
    expect("DPHY lpn0", lpn, '0');
    eq("DPHY lpn0", lpn, lpn_v);
    expect("DPHY hs init", hs, 'X');
    eq("DPHY hs init", hs, hs_v);
    di <= '1';
    dib <= '0';
    step;
    expect("DPHY 10", hs, '1');
    eq("DPHY 10", hs, hs_v);
    di <= '0';
    dib <= '1';
    step;
    expect("DPHY 01", hs, '0');
    eq("DPHY 01", hs, hs_v);
    di <= '1';
    dib <= '1';
    step;
    expect("DPHY hold", hs, '0');
    eq("DPHY hold", hs, hs_v);
    di <= 'X';
    step;
    expect("DPHY X", hs, 'X');
    eq("DPHY X", hs, hs_v);
    di <= '1';
    dib <= '0';
    step;
    expect("DPHY restored", hs, '1');
    eq("DPHY restored", hs, hs_v);
    hsdis <= '1';
    step;
    expect("DPHY dis", hs, '0');
    eq("DPHY dis", hs, hs_v);
    hsdis <= 'Z';
    step;
    expect("DPHY disZ", hs, 'X');
    eq("DPHY disZ", hs, hs_v);
    hsdis <= '0';
    ldis <= '1';
    step;
    expect("DPHY lp dis", lpp, '0');
    eq("DPHY lp dis", lpp, lpp_v);
    expect("DPHY lpn dis", lpn, '0');
    eq("DPHY lpn dis", lpn, lpn_v);
    ldis <= 'X';
    step;
    expect("DPHY lp X", lpp, 'X');
    eq("DPHY lp X", lpp, lpp_v);
    expect("DPHY lpn X", lpn, 'X');
    eq("DPHY lpn X", lpn, lpn_v);

    report "tb_eq_simprim PASS checks=" & integer'image(n) severity note;
    finish;
  end process;
end architecture sim;
