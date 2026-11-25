-- Self-checking bench for the IOBUF* family and BIBUF.
-- Expected values are the equations in docs/vhdl-models.md, evaluated
-- here independently of unisim_sim. Stimulus waits 1 ns so the local
-- GTS has fallen. The VHDL models are unchanged: drive strength is not
-- represented, and two drivers resolve with std_logic.
-- The tail of the bench also elaborates the Verilog IOBUF, BIBUF,
-- PULLUP, PULLDOWN and KEEPER and compares them. A mismatch is left
-- in the log as a possible NVC bug.

library ieee;
use ieee.std_logic_1164.all;
library unisim;

entity tb_iobuf is
end entity tb_iobuf;

architecture sim of tb_iobuf is
  type sul4 is array (0 to 3) of std_ulogic;
  constant VALS : sul4 := ('0', '1', 'X', 'Z');

  signal i, t, tm, ts, dis : std_ulogic := '0';
  signal dci, inter : std_ulogic := '0';
  signal ext, extb : std_logic := 'Z';
  signal vref : std_ulogic := '1';
  signal osc : std_logic_vector(3 downto 0) := "0000";
  signal osc_en : std_ulogic := '0';
  signal osc_en_ver : std_ulogic := '1';
  signal osc_en2 : std_logic_vector(1 downto 0) := "00";
  signal osc_en2_ver : std_logic_vector(1 downto 0) := "11";

  signal io_buf, io_ana, io_dci, io_dci_off, io_dci_us, io_int : std_logic := 'Z';
  signal io_e3, io_e3_use, io_e3_ver, io_e3_off, io_e3_plus : std_logic := 'Z';
  signal o_buf, o_ana, o_dci, o_dci_off, o_dci_us, o_int : std_ulogic;
  signal o_e3, o_e3_use, o_e3_ver, o_e3_off, o_e3_plus : std_ulogic;

  signal io_ds, iob_ds, io_dsb, iob_dsb : std_logic := 'Z';
  signal io_dd, iob_dd, io_dd_off, iob_dd_off, io_dd_us, iob_dd_us : std_logic := 'Z';
  signal io_di, iob_di : std_logic := 'Z';
  signal io_e3d, iob_e3d, io_e3d_use, iob_e3d_use : std_logic := 'Z';
  signal io_e3d_ver, iob_e3d_ver, io_e3d_off, iob_e3d_off : std_logic := 'Z';
  signal o_ds, o_dsb, o_dd, o_dd_off, o_dd_us, o_di : std_ulogic;
  signal o_e3d, o_e3d_use, o_e3d_ver, o_e3d_off : std_ulogic;

  signal io_do, iob_do, io_dob, iob_dob : std_logic := 'Z';
  signal io_dod, iob_dod, io_dod_off, iob_dod_off : std_logic := 'Z';
  signal io_dod_us, iob_dod_us, io_dod_vp, iob_dod_vp : std_logic := 'Z';
  signal io_doi, iob_doi : std_logic := 'Z';
  signal o_do, ob_do, o_dob, ob_dob : std_ulogic;
  signal o_dod, ob_dod, o_dod_off, ob_dod_off : std_ulogic;
  signal o_dod_us, ob_dod_us, o_dod_vp, ob_dod_vp : std_ulogic;
  signal o_doi, ob_doi : std_ulogic;

  signal b_io, b_pad : std_logic := 'Z';
  signal b_ext_io, b_ext_pad : std_logic := 'Z';

  -- Verilog reference nets. Separate from the equation checks above.
  signal vi, vt : std_ulogic := '0';
  signal vext_h, vext_v : std_logic := 'Z';
  signal vio_h, vio_v : std_logic := 'Z';
  signal vo_h, vo_v : std_ulogic;
  signal bvio_h, bvpad_h, bvio_v, bvpad_v : std_logic := 'Z';
  signal bext_io_h, bext_pad_h, bext_io_v, bext_pad_v : std_logic := 'Z';
  signal pvio_h, pvpad_h, pvio_v, pvpad_v : std_logic := 'Z';
  signal pext_io_h, pext_pad_h, pext_io_v, pext_pad_v : std_logic := 'Z';
  signal ovio_h, ovpad_h, ovio_v, ovpad_v : std_logic := 'Z';
  signal oext_io_h, oext_io_v : std_logic := '1';
  signal oext_pad_h, oext_pad_v : std_logic := '0';
  signal pu, pd, keep : std_logic := 'Z';
  signal kdrv : std_logic := 'Z';
  signal pu_io_h, pu_io_v : std_logic := 'Z';
  signal piext_h, piext_v : std_logic := 'Z';
  signal puo_h, puo_v : std_ulogic;

  component IOBUF is
    generic (
      DRIVE : integer := 12;
      IBUF_LOW_PWR : string := "TRUE";
      IOSTANDARD : string := "DEFAULT";
      SLEW : string := "SLOW"
    );
    port (
      O : out std_ulogic;
      IO : inout std_logic;
      I : in std_ulogic;
      T : in std_ulogic
    );
  end component;

  component BIBUF is
    port (
      IO : inout std_logic;
      PAD : inout std_logic
    );
  end component;

  component PULLUP is
    port (O : out std_ulogic);
  end component;

  component PULLDOWN is
    port (O : out std_ulogic);
  end component;

  component KEEPER is
    port (O : inout std_logic);
  end component;

  function res2(a, b : std_ulogic) return std_ulogic is
    variable v : std_ulogic_vector(1 downto 0);
  begin
    v := (a, b);
    return resolved(v);
  end function;

  function exp_buf(d : std_ulogic) return std_ulogic is
  begin
    if d = '0' or d = '1' then
      return d;
    end if;
    return 'X';
  end function;

  function exp_bufif0(d, en : std_ulogic) return std_ulogic is
  begin
    if en = '0' then
      if d = '0' or d = '1' or d = 'Z' then
        return d;
      end if;
      return 'X';
    end if;
    return 'Z';
  end function;

  function exp_notif0(d, en : std_ulogic) return std_ulogic is
  begin
    if en = '0' then
      return exp_buf(not d);
    end if;
    return 'Z';
  end function;

  function exp_rv1(s : std_ulogic) return std_ulogic is
  begin
    if s = 'Z' or s = '1' then
      return '1';
    elsif s = '0' then
      return '0';
    else
      return 'X';
    end if;
  end function;

  function exp_tri(data, en : std_ulogic) return std_ulogic is
  begin
    if en = '0' then
      return data;
    elsif en = '1' then
      return 'Z';
    elsif data = 'Z' then
      return 'Z';
    else
      return 'X';
    end if;
  end function;

  function exp_mux(en, when1, when0 : std_ulogic) return std_ulogic is
  begin
    if en = '1' then
      return when1;
    elsif en = '0' then
      return when0;
    elsif when1 = when0 then
      return when1;
    else
      return 'X';
    end if;
  end function;

  function exp_mux01(sel, when1, when0 : std_ulogic) return std_ulogic is
  begin
    if sel = '1' then
      return when1;
    elsif sel = '0' then
      return when0;
    else
      return 'X';
    end if;
  end function;

  function exp_diff(
    prev, pi, pb : std_ulogic;
    bias, x_i, x_ib, else_x : boolean
  ) return std_ulogic is
  begin
    if pi = '1' and pb = '0' then
      return '1';
    elsif pi = '0' and pb = '1' then
      return '0';
    elsif (pi = 'Z' or pi = '0') and (pb = 'Z' or pb = '1') then
      if bias then
        return '0';
      else
        return 'X';
      end if;
    elsif (x_i and pi = 'X') or (x_ib and pb = 'X') then
      return 'X';
    elsif else_x then
      return 'X';
    else
      return prev;
    end if;
  end function;

  function exp_code(oscv : std_logic_vector(3 downto 0)) return integer is
    variable mag : integer := 0;
  begin
    if (oscv(0) /= '0' and oscv(0) /= '1')
      or (oscv(1) /= '0' and oscv(1) /= '1')
      or (oscv(2) /= '0' and oscv(2) /= '1') then
      return -1000;
    end if;
    if oscv(0) = '1' then
      mag := mag + 5;
    end if;
    if oscv(1) = '1' then
      mag := mag + 10;
    end if;
    if oscv(2) = '1' then
      mag := mag + 20;
    end if;
    if oscv(3) = '0' then
      return -mag;
    end if;
    return mag;
  end function;
begin
  io_buf <= ext;
  io_ana <= ext;
  io_dci <= ext;
  io_dci_off <= ext;
  io_dci_us <= ext;
  io_int <= ext;
  io_e3 <= ext;
  io_e3_use <= ext;
  io_e3_ver <= ext;
  io_e3_off <= ext;
  io_e3_plus <= ext;

  io_ds <= ext;
  iob_ds <= extb;
  io_dsb <= ext;
  iob_dsb <= extb;
  io_dd <= ext;
  iob_dd <= extb;
  io_dd_off <= ext;
  iob_dd_off <= extb;
  io_dd_us <= ext;
  iob_dd_us <= extb;
  io_di <= ext;
  iob_di <= extb;
  io_e3d <= ext;
  iob_e3d <= extb;
  io_e3d_use <= ext;
  iob_e3d_use <= extb;
  io_e3d_ver <= ext;
  iob_e3d_ver <= extb;
  io_e3d_off <= ext;
  iob_e3d_off <= extb;

  io_do <= ext;
  iob_do <= extb;
  io_dob <= ext;
  iob_dob <= extb;
  io_dod <= ext;
  iob_dod <= extb;
  io_dod_off <= ext;
  iob_dod_off <= extb;
  io_dod_us <= ext;
  iob_dod_us <= extb;
  io_dod_vp <= ext;
  iob_dod_vp <= extb;
  io_doi <= ext;
  iob_doi <= extb;

  b_io <= b_ext_io;
  b_pad <= b_ext_pad;

  u_buf : entity unisim.IOBUF
    port map (O => o_buf, IO => io_buf, I => i, T => t);

  u_ana : entity unisim.IOBUF_ANALOG
    port map (O => o_ana, IO => io_ana, I => i, T => t);

  u_dci : entity unisim.IOBUF_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES", SLEW => "SLOW")
    port map (O => o_dci, IO => io_dci, DCITERMDISABLE => dci, I => i,
              IBUFDISABLE => dis, T => t);

  u_dci_off : entity unisim.IOBUF_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES", SLEW => "SLOW",
                 USE_IBUFDISABLE => FALSE)
    port map (O => o_dci_off, IO => io_dci_off, DCITERMDISABLE => dci, I => i,
              IBUFDISABLE => dis, T => t);

  u_dci_us : entity unisim.IOBUF_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE", SLEW => "SLOW")
    port map (O => o_dci_us, IO => io_dci_us, DCITERMDISABLE => dci, I => i,
              IBUFDISABLE => dis, T => t);

  u_int : entity unisim.IOBUF_INTERMDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES", SLEW => "SLOW")
    port map (O => o_int, IO => io_int, I => i, IBUFDISABLE => dis,
              INTERMDISABLE => inter, T => t);

  u_e3 : entity unisim.IOBUFE3
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE")
    port map (O => o_e3, IO => io_e3, DCITERMDISABLE => dci, I => i,
              IBUFDISABLE => dis, OSC => osc, OSC_EN => osc_en, T => t, VREF => vref);

  u_e3_use : entity unisim.IOBUFE3
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE",
                 USE_IBUFDISABLE => TRUE)
    port map (O => o_e3_use, IO => io_e3_use, DCITERMDISABLE => dci, I => i,
              IBUFDISABLE => dis, OSC => osc, OSC_EN => osc_en, T => t, VREF => vref);

  u_e3_ver : entity unisim.IOBUFE3
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "VERSAL_PRIME")
    port map (O => o_e3_ver, IO => io_e3_ver, DCITERMDISABLE => dci, I => i,
              IBUFDISABLE => dis, OSC => osc, OSC_EN => osc_en_ver, T => t,
              VREF => vref);

  u_e3_off : entity unisim.IOBUFE3
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE",
                 SIM_INPUT_BUFFER_OFFSET => 10)
    port map (O => o_e3_off, IO => io_e3_off, DCITERMDISABLE => dci, I => i,
              IBUFDISABLE => dis, OSC => osc, OSC_EN => osc_en, T => t, VREF => vref);

  u_e3_plus : entity unisim.IOBUFE3
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE_PLUS",
                 SIM_INPUT_BUFFER_OFFSET => 10)
    port map (O => o_e3_plus, IO => io_e3_plus, DCITERMDISABLE => dci, I => i,
              IBUFDISABLE => dis, OSC => osc, OSC_EN => osc_en, T => t, VREF => vref);

  u_ds : entity unisim.IOBUFDS
    generic map (IOSTANDARD => "DEFAULT", SLEW => "SLOW")
    port map (O => o_ds, IO => io_ds, IOB => iob_ds, I => i, T => t);

  u_dsb : entity unisim.IOBUFDS
    generic map (DQS_BIAS => TRUE, IOSTANDARD => "DEFAULT", SLEW => "SLOW")
    port map (O => o_dsb, IO => io_dsb, IOB => iob_dsb, I => i, T => t);

  u_dd : entity unisim.IOBUFDS_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES", SLEW => "SLOW")
    port map (O => o_dd, IO => io_dd, IOB => iob_dd, DCITERMDISABLE => dci,
              I => i, IBUFDISABLE => dis, T => t);

  u_dd_off : entity unisim.IOBUFDS_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES", SLEW => "SLOW",
                 USE_IBUFDISABLE => FALSE)
    port map (O => o_dd_off, IO => io_dd_off, IOB => iob_dd_off,
              DCITERMDISABLE => dci, I => i, IBUFDISABLE => dis, T => t);

  u_dd_us : entity unisim.IOBUFDS_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE", SLEW => "SLOW")
    port map (O => o_dd_us, IO => io_dd_us, IOB => iob_dd_us, DCITERMDISABLE => dci,
              I => i, IBUFDISABLE => dis, T => t);

  u_di : entity unisim.IOBUFDS_INTERMDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES", SLEW => "SLOW")
    port map (O => o_di, IO => io_di, IOB => iob_di, I => i, IBUFDISABLE => dis,
              INTERMDISABLE => inter, T => t);

  u_e3d : entity unisim.IOBUFDSE3
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE")
    port map (O => o_e3d, IO => io_e3d, IOB => iob_e3d, DCITERMDISABLE => dci,
              I => i, IBUFDISABLE => dis, OSC => osc, OSC_EN => osc_en2, T => t);

  u_e3d_use : entity unisim.IOBUFDSE3
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE",
                 USE_IBUFDISABLE => TRUE)
    port map (O => o_e3d_use, IO => io_e3d_use, IOB => iob_e3d_use,
              DCITERMDISABLE => dci, I => i, IBUFDISABLE => dis,
              OSC => osc, OSC_EN => osc_en2, T => t);

  u_e3d_ver : entity unisim.IOBUFDSE3
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "VERSAL_PRIME")
    port map (O => o_e3d_ver, IO => io_e3d_ver, IOB => iob_e3d_ver,
              DCITERMDISABLE => dci, I => i, IBUFDISABLE => dis,
              OSC => osc, OSC_EN => osc_en2_ver, T => t);

  u_e3d_off : entity unisim.IOBUFDSE3
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE",
                 SIM_INPUT_BUFFER_OFFSET => 10)
    port map (O => o_e3d_off, IO => io_e3d_off, IOB => iob_e3d_off,
              DCITERMDISABLE => dci, I => i, IBUFDISABLE => dis,
              OSC => osc, OSC_EN => osc_en2, T => t);

  u_do : entity unisim.IOBUFDS_DIFF_OUT
    generic map (IOSTANDARD => "DEFAULT")
    port map (O => o_do, OB => ob_do, IO => io_do, IOB => iob_do,
              I => i, TM => tm, TS => ts);

  u_dob : entity unisim.IOBUFDS_DIFF_OUT
    generic map (DQS_BIAS => TRUE, IOSTANDARD => "DEFAULT")
    port map (O => o_dob, OB => ob_dob, IO => io_dob, IOB => iob_dob,
              I => i, TM => tm, TS => ts);

  u_dod : entity unisim.IOBUFDS_DIFF_OUT_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => o_dod, OB => ob_dod, IO => io_dod, IOB => iob_dod,
              DCITERMDISABLE => dci, I => i, IBUFDISABLE => dis, TM => tm, TS => ts);

  u_dod_off : entity unisim.IOBUFDS_DIFF_OUT_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES",
                 USE_IBUFDISABLE => FALSE)
    port map (O => o_dod_off, OB => ob_dod_off, IO => io_dod_off, IOB => iob_dod_off,
              DCITERMDISABLE => dci, I => i, IBUFDISABLE => dis, TM => tm, TS => ts);

  u_dod_us : entity unisim.IOBUFDS_DIFF_OUT_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "ULTRASCALE")
    port map (O => o_dod_us, OB => ob_dod_us, IO => io_dod_us, IOB => iob_dod_us,
              DCITERMDISABLE => dci, I => i, IBUFDISABLE => dis, TM => tm, TS => ts);

  u_dod_vp : entity unisim.IOBUFDS_DIFF_OUT_DCIEN
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "VERSAL_PRIME")
    port map (O => o_dod_vp, OB => ob_dod_vp, IO => io_dod_vp, IOB => iob_dod_vp,
              DCITERMDISABLE => dci, I => i, IBUFDISABLE => dis, TM => tm, TS => ts);

  u_doi : entity unisim.IOBUFDS_DIFF_OUT_INTERMDISABLE
    generic map (IOSTANDARD => "DEFAULT", SIM_DEVICE => "7SERIES")
    port map (O => o_doi, OB => ob_doi, IO => io_doi, IOB => iob_doi,
              I => i, IBUFDISABLE => dis, INTERMDISABLE => inter, TM => tm, TS => ts);

  u_bibuf : entity unisim.BIBUF
    port map (IO => b_io, PAD => b_pad);

  vio_h <= vext_h;
  vio_v <= vext_v;
  bvio_h <= bext_io_h;
  bvpad_h <= bext_pad_h;
  bvio_v <= bext_io_v;
  bvpad_v <= bext_pad_v;
  pvio_h <= pext_io_h;
  pvpad_h <= pext_pad_h;
  pvio_v <= pext_io_v;
  pvpad_v <= pext_pad_v;
  ovio_h <= oext_io_h;
  ovpad_h <= oext_pad_h;
  ovio_v <= oext_io_v;
  ovpad_v <= oext_pad_v;
  keep <= kdrv;
  pu_io_h <= piext_h;
  pu_io_v <= piext_v;

  u_vio_h : entity unisim.IOBUF
    port map (O => vo_h, IO => vio_h, I => vi, T => vt);
  u_vio_v : IOBUF
    port map (O => vo_v, IO => vio_v, I => vi, T => vt);

  u_biv_h : entity unisim.BIBUF
    port map (IO => bvio_h, PAD => bvpad_h);
  u_biv_v : BIBUF
    port map (IO => bvio_v, PAD => bvpad_v);
  u_bp_h : entity unisim.BIBUF
    port map (IO => pvio_h, PAD => pvpad_h);
  u_bp_v : BIBUF
    port map (IO => pvio_v, PAD => pvpad_v);
  u_bo_h : entity unisim.BIBUF
    port map (IO => ovio_h, PAD => ovpad_h);
  u_bo_v : BIBUF
    port map (IO => ovio_v, PAD => ovpad_v);

  u_pu : PULLUP port map (O => pu);
  u_pd : PULLDOWN port map (O => pd);
  u_keep : KEEPER port map (O => keep);

  u_pi_h : entity unisim.IOBUF
    port map (O => puo_h, IO => pu_io_h, I => vi, T => vt);
  u_pi_v : IOBUF
    port map (O => puo_v, IO => pu_io_v, I => vi, T => vt);
  u_pi_pu_h : PULLUP port map (O => pu_io_h);
  u_pi_pu_v : PULLUP port map (O => pu_io_v);

  run : process
    variable n : natural := 0;
    variable q_ds, q_dsb, q_dd, q_dd_off, q_dd_us, q_di : std_ulogic := 'X';
    variable q_e3d, q_e3d_use, q_e3d_ver, q_e3d_off : std_ulogic := 'X';
    variable q_do, q_dob, q_dod, q_dod_off, q_dod_us, q_dod_vp, q_doi : std_ulogic := 'X';
    variable en, drv, pad, dio, diob, pio, piob, flag, nt : std_ulogic;
    variable dio_e, diob_e, pio_e, piob_e : std_ulogic;
    -- Pads seen by IOBUFDSE3 on the previous vector. The receiver
    -- process wakes on T and IBUFDISABLE before the pad drivers
    -- resolve, so the golden takes that intermediate step too.
    variable prev_pio_e : std_ulogic := '1';
    variable prev_piob_e : std_ulogic := '0';

    procedure phase_e3(
      variable q : inout std_ulogic;
      pi, pb, nt : std_ulogic;
      use_dis : boolean
    ) is
    begin
      if use_dis and nt = '1' then
        q := '0';
      elsif (use_dis and nt = '0') or not use_dis then
        q := exp_diff(q, pi, pb, false, true, true, false);
      else
        q := 'X';
      end if;
    end procedure;
    variable level : std_ulogic := '1';

    procedure expect(name : string; got, exp : std_ulogic) is
    begin
      n := n + 1;
      assert got = exp
        report name & " got " & std_ulogic'image(got)
          & " expected " & std_ulogic'image(exp)
        severity failure;
    end procedure;

    -- Verilog X arrives as U. The VHDL model drives a weak copy as a
    -- strong value, so H/L compare equal to 1/0. A different logic
    -- level is a possible NVC bug.
    function logic_bit(s : std_ulogic) return std_ulogic is
    begin
      if s = 'H' then
        return '1';
      elsif s = 'L' then
        return '0';
      elsif s = 'U' or s = 'W' then
        return 'X';
      else
        return s;
      end if;
    end function;

    procedure vcmp(h, v : std_ulogic; what : string) is
    begin
      n := n + 1;
      if logic_bit(h) /= logic_bit(v) then
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(v)
          & " (possible NVC bug)" severity failure;
      end if;
    end procedure;

    procedure check_se is
    begin
      en := '0' or t;
      drv := exp_bufif0(i, en);
      pad := res2(drv, ext);
      expect("IOBUF.IO", io_buf, pad);
      expect("IOBUF.O", o_buf, exp_buf(pad));

      drv := exp_tri(exp_rv1(i), exp_rv1(t));
      pad := res2(drv, ext);
      expect("IOBUF_ANALOG.IO", io_ana, pad);
      expect("IOBUF_ANALOG.O", o_ana, pad);

      drv := exp_bufif0(i, en);
      pad := res2(drv, ext);
      flag := (not t) or dis;
      expect("IOBUF_DCIEN.IO", io_dci, pad);
      expect("IOBUF_DCIEN.O", o_dci, exp_mux01(flag, '1', pad));
      expect("IOBUF_DCIEN off.O", o_dci_off, pad);
      expect("IOBUF_DCIEN US.O", o_dci_us, exp_mux01(flag, '0', pad));
      expect("IOBUF_INTERMDISABLE.O", o_int, exp_mux01(flag, '1', pad));

      expect("IOBUFE3.IO", io_e3, pad);
      expect("IOBUFE3.O", o_e3, pad);
      nt := (not t) or dis;
      if nt = '0' then
        expect("IOBUFE3 use.O", o_e3_use, pad);
      elsif nt = '1' then
        expect("IOBUFE3 use.O", o_e3_use, '0');
      else
        expect("IOBUFE3 use.O", o_e3_use, 'X');
      end if;
      expect("IOBUFE3 versal.O", o_e3_ver, pad);
      expect("IOBUFE3 off.O", o_e3_off, pad);
    end procedure;

    procedure check_ds is
    begin
      en := '0' or t;
      dio := exp_tri(i, en);
      diob := exp_tri(not i, en);
      pio := res2(dio, ext);
      piob := res2(diob, extb);
      expect("IOBUFDS.IO", io_ds, pio);
      expect("IOBUFDS.IOB", iob_ds, piob);
      q_ds := exp_diff(q_ds, pio, piob, false, true, false, false);
      q_dsb := exp_diff(q_dsb, pio, piob, true, true, false, false);
      expect("IOBUFDS.O", o_ds, q_ds);
      expect("IOBUFDS bias.O", o_dsb, q_dsb);

      flag := (not t) or dis;
      q_dd := exp_diff(q_dd, pio, piob, false, true, true, false);
      q_dd_off := exp_diff(q_dd_off, pio, piob, false, true, true, false);
      q_dd_us := exp_diff(q_dd_us, pio, piob, false, true, true, false);
      q_di := exp_diff(q_di, pio, piob, false, true, true, false);
      expect("IOBUFDS_DCIEN.O", o_dd, exp_mux01(flag, '1', q_dd));
      expect("IOBUFDS_DCIEN off.O", o_dd_off, q_dd_off);
      expect("IOBUFDS_DCIEN US.O", o_dd_us, exp_mux01(flag, '0', q_dd_us));
      expect("IOBUFDS_INTERMDISABLE.O", o_di, exp_mux01(flag, '1', q_di));

      -- IOBUFDSE3 drives with bufif0/notif0, not the IOBUFDS ternary.
      dio_e := exp_bufif0(i, en);
      diob_e := exp_notif0(i, en);
      pio_e := res2(dio_e, ext);
      piob_e := res2(diob_e, extb);
      nt := (not t) or dis;
      phase_e3(q_e3d, prev_pio_e, prev_piob_e, nt, false);
      phase_e3(q_e3d, pio_e, piob_e, nt, false);
      phase_e3(q_e3d_use, prev_pio_e, prev_piob_e, nt, true);
      phase_e3(q_e3d_use, pio_e, piob_e, nt, true);
      phase_e3(q_e3d_ver, prev_pio_e, prev_piob_e, nt, false);
      phase_e3(q_e3d_ver, pio_e, piob_e, nt, false);
      phase_e3(q_e3d_off, prev_pio_e, prev_piob_e, nt, false);
      phase_e3(q_e3d_off, pio_e, piob_e, nt, false);
      prev_pio_e := pio_e;
      prev_piob_e := piob_e;
      expect("IOBUFDSE3.IO", io_e3d, pio_e);
      expect("IOBUFDSE3.IOB", iob_e3d, piob_e);
      expect("IOBUFDSE3.O", o_e3d, q_e3d);
      expect("IOBUFDSE3 use.O", o_e3d_use, q_e3d_use);
      expect("IOBUFDSE3 versal.O", o_e3d_ver, q_e3d_ver);
    end procedure;

    procedure check_do is
      variable po, pob, fo, fs : std_ulogic;
    begin
      dio := exp_bufif0(i, '0' or tm);
      diob := exp_notif0(i, '0' or ts);
      po := res2(dio, ext);
      pob := res2(diob, extb);
      expect("DIFF_OUT.IO", io_do, po);
      expect("DIFF_OUT.IOB", iob_do, pob);
      q_do := exp_diff(q_do, po, pob, false, false, false, true);
      q_dob := exp_diff(q_dob, po, pob, true, false, false, true);
      expect("DIFF_OUT.O", o_do, q_do);
      expect("DIFF_OUT.OB", ob_do, exp_buf(not q_do));
      expect("DIFF_OUT bias.O", o_dob, q_dob);
      expect("DIFF_OUT bias.OB", ob_dob, exp_buf(not q_dob));

      q_dod := exp_diff(q_dod, po, pob, false, false, false, true);
      q_dod_off := exp_diff(q_dod_off, po, pob, false, false, false, true);
      q_dod_us := exp_diff(q_dod_us, po, pob, false, false, false, true);
      q_dod_vp := exp_diff(q_dod_vp, po, pob, false, false, false, true);
      q_doi := exp_diff(q_doi, po, pob, false, false, false, true);
      fo := (not tm) or dis;
      fs := (not ts) or dis;
      expect("DIFF_OUT_DCIEN.O", o_dod, exp_mux01(fo, '1', q_dod));
      expect("DIFF_OUT_DCIEN.OB", ob_dod, exp_mux01(fs, '1', exp_buf(not q_dod)));
      expect("DIFF_OUT_DCIEN off.O", o_dod_off, q_dod_off);
      expect("DIFF_OUT_DCIEN off.OB", ob_dod_off, exp_buf(not q_dod_off));
      expect("DIFF_OUT_DCIEN US.O", o_dod_us, exp_mux01(fo, '0', q_dod_us));
      expect("DIFF_OUT_DCIEN US.OB", ob_dod_us, exp_mux01(fs, 'X', exp_buf(not q_dod_us)));
      expect("DIFF_OUT_DCIEN VP.O", o_dod_vp, exp_mux01(fo, '0', q_dod_vp));
      expect("DIFF_OUT_DCIEN VP.OB", ob_dod_vp, exp_mux01(fs, '0', exp_buf(not q_dod_vp)));
      expect("DIFF_OUT_INTERM.O", o_doi, exp_mux01(fo, '1', q_doi));
      expect("DIFF_OUT_INTERM.OB", ob_doi, exp_mux01(fs, '1', exp_buf(not q_doi)));
    end procedure;
  begin
    -- GTS falls at time 0. Sample after 1 ns.
    i <= '1';
    t <= '0';
    tm <= '0';
    ts <= '0';
    dis <= '0';
    ext <= 'Z';
    extb <= 'Z';
    wait for 1 ns;

    -- IOBUF: bufif0, then buf of the resolved pad.
    expect("lit buf IO", io_buf, '1');
    expect("lit buf O", o_buf, '1');
    i <= 'Z';
    wait for 1 ns;
    expect("lit buf Z passes on IO", io_buf, 'Z');
    expect("lit buf Z is X on O", o_buf, 'X');
    i <= '1';
    t <= '0';
    ext <= '0';
    wait for 1 ns;
    expect("lit buf contention", io_buf, 'X');
    expect("lit buf contention O", o_buf, 'X');
    t <= '1';
    ext <= '0';
    wait for 1 ns;
    expect("lit buf released", io_buf, '0');
    expect("lit buf released O", o_buf, '0');
    t <= 'X';
    ext <= '1';
    wait for 1 ns;
    expect("lit buf X enable", io_buf, '1');

    -- IOBUF_ANALOG: rv1, so Z on I is driven as 1 and Z on T disables.
    i <= 'Z';
    t <= '0';
    ext <= 'Z';
    wait for 1 ns;
    expect("lit analog Z data", io_ana, '1');
    expect("lit analog Z data O", o_ana, '1');
    i <= '0';
    t <= 'Z';
    wait for 1 ns;
    expect("lit analog Z enable", io_ana, 'Z');
    expect("lit analog Z enable O", o_ana, 'Z');

    -- Disable constant while the pad is driven the other way.
    i <= '0';
    t <= '0';
    dis <= '0';
    ext <= 'Z';
    dci <= '1';
    inter <= '1';
    wait for 1 ns;
    expect("lit dcien pad", io_dci, '0');
    expect("lit dcien 7series O", o_dci, '1');
    expect("lit dcien ultra O", o_dci_us, '0');
    expect("lit dcien use false", o_dci_off, '0');
    expect("lit interm ignores INTERMDISABLE", o_int, '1');
    t <= '1';
    ext <= 'Z';
    wait for 1 ns;
    expect("lit dcien follows Z", o_dci, 'Z');
    expect("lit dcien use false Z", o_dci_off, 'Z');

    -- IOBUFDS hold vs === on both pins. Release the driver first.
    t <= '1';
    dis <= '0';
    ext <= '1';
    extb <= '0';
    wait for 1 ns;
    expect("lit ds complementary", o_ds, '1');
    expect("lit ds dcien complementary", o_dd, '1');
    extb <= 'X';
    wait for 1 ns;
    expect("lit ds holds X on IOB", o_ds, '1');
    expect("lit ds bias holds X on IOB", o_dsb, '1');
    expect("lit ds dcien X on IOB", o_dd, 'X');
    ext <= 'Z';
    extb <= 'Z';
    wait for 1 ns;
    expect("lit ds Z pair", o_ds, 'X');
    expect("lit ds bias Z pair", o_dsb, '0');

    -- Separate TM/TS, and the disable constants on O versus OB.
    i <= '1';
    tm <= '0';
    ts <= '1';
    dis <= '0';
    ext <= 'Z';
    extb <= 'Z';
    wait for 1 ns;
    expect("lit diff IO", io_do, '1');
    expect("lit diff IOB", iob_do, 'Z');
    expect("lit diff else X", o_do, 'X');
    tm <= '0';
    ts <= '0';
    wait for 1 ns;
    expect("lit diff pair O", o_do, '1');
    expect("lit diff pair OB", ob_do, '0');
    expect("lit diff dcien O forced", o_dod, '1');
    expect("lit diff dcien OB forced", ob_dod, '1');
    expect("lit diff dcien US O", o_dod_us, '0');
    expect("lit diff dcien US OB", ob_dod_us, 'X');
    expect("lit diff dcien VP OB", ob_dod_vp, '0');
    expect("lit diff dcien off OB", ob_dod_off, '0');
    expect("lit diff interm OB", ob_doi, '1');

    -- BIBUF: strong copy. Releasing both external drivers holds the
    -- copied value. Opposite drivers resolve to X, and that X sticks
    -- because the model's own drivers are part of the resolution.
    b_ext_io <= 'Z';
    b_ext_pad <= 'Z';
    wait for 1 ns;
    expect("lit bibuf idle IO", b_io, 'Z');
    expect("lit bibuf idle PAD", b_pad, 'Z');
    b_ext_io <= '1';
    b_ext_pad <= 'Z';
    wait for 1 ns;
    expect("lit bibuf copy IO", b_io, '1');
    expect("lit bibuf copy PAD", b_pad, '1');
    b_ext_io <= 'Z';
    b_ext_pad <= 'Z';
    wait for 1 ns;
    expect("lit bibuf hold IO", b_io, '1');
    expect("lit bibuf hold PAD", b_pad, '1');
    b_ext_io <= '1';
    b_ext_pad <= '0';
    wait for 1 ns;
    expect("lit bibuf contention IO", b_io, 'X');
    expect("lit bibuf contention PAD", b_pad, 'X');
    b_ext_io <= 'Z';
    b_ext_pad <= 'Z';
    wait for 1 ns;
    expect("lit bibuf stuck IO", b_io, 'X');
    expect("lit bibuf stuck PAD", b_pad, 'X');

    -- Known receiver state, then every 0/1/X/Z combination.
    i <= '0';
    t <= '1';
    tm <= '1';
    ts <= '1';
    dis <= '0';
    ext <= '1';
    extb <= '0';
    dci <= '0';
    inter <= '0';
    wait for 1 ns;
    q_ds := 'X';
    q_dsb := 'X';
    q_dd := 'X';
    q_dd_off := 'X';
    q_dd_us := 'X';
    q_di := 'X';
    q_e3d := 'X';
    q_e3d_use := 'X';
    q_e3d_ver := 'X';
    q_e3d_off := 'X';
    q_do := 'X';
    q_dob := 'X';
    q_dod := 'X';
    q_dod_off := 'X';
    q_dod_us := 'X';
    q_dod_vp := 'X';
    q_doi := 'X';
    check_se;
    check_ds;
    check_do;

    for a_i in 0 to 3 loop
      for a_t in 0 to 3 loop
        for a_e in 0 to 3 loop
          for a_b in 0 to 3 loop
            for a_d in 0 to 3 loop
              i <= VALS(a_i);
              t <= VALS(a_t);
              tm <= VALS(a_t);
              ts <= VALS(a_t);
              dis <= VALS(a_d);
              ext <= VALS(a_e);
              extb <= VALS(a_b);
              dci <= VALS((a_i + 1) mod 4);
              inter <= VALS((a_t + 2) mod 4);
              wait for 1 ns;
              check_se;
              check_ds;
              check_do;
            end loop;
          end loop;
        end loop;
      end loop;
    end loop;

    dis <= '0';
    for a_i in 0 to 3 loop
      for a_tm in 0 to 3 loop
        for a_ts in 0 to 3 loop
          for a_e in 0 to 3 loop
            for a_b in 0 to 3 loop
              i <= VALS(a_i);
              tm <= VALS(a_tm);
              ts <= VALS(a_ts);
              ext <= VALS(a_e);
              extb <= VALS(a_b);
              wait for 1 ns;
              check_do;
            end loop;
          end loop;
        end loop;
      end loop;
    end loop;

    -- IOBUFE3 oscillator. Offset 10, OSC_EN was 0, so O_OSC is still 1.
    -- "1010" is +10: the difference is 0 and O_OSC toggles once.
    osc <= "1010";
    osc_en <= '1';
    wait for 1 ns;
    level := '0';
    expect("e3 toggle", o_e3_off, '0');
    expect("e3 plus toggle", o_e3_plus, '0');
    osc <= "0000";
    wait for 1 ns;
    expect("e3 diff positive", o_e3_off, '1');
    osc <= "1111";
    wait for 1 ns;
    expect("e3 diff negative", o_e3_off, '0');
    osc_en <= '0';
    i <= '1';
    t <= '0';
    ext <= 'Z';
    wait for 1 ns;
    expect("e3 en 0 follows pad", o_e3_off, '1');
    osc_en <= 'X';
    wait for 1 ns;
    expect("e3 en X merges", o_e3_off, 'X');
    osc_en <= '0';

    -- IOBUFDSE3: 01 updates O_OSC, 11 selects it, 10 is X, 00 is the receiver.
    osc <= "1111";
    osc_en2 <= "01";
    wait for 1 ns;
    expect("dse3 en 01 is X", o_e3d_off, 'X');
    osc_en2 <= "11";
    wait for 1 ns;
    expect("dse3 en 11 is osc", o_e3d_off, '0');
    osc_en2 <= "10";
    wait for 1 ns;
    expect("dse3 en 10 is X", o_e3d_off, 'X');
    osc <= "10X0";
    osc_en2 <= "01";
    wait for 1 ns;
    osc_en2 <= "11";
    wait for 1 ns;
    expect("dse3 X code holds", o_e3d_off, '0');
    osc_en2 <= "00";
    t <= '1';
    dis <= '0';
    ext <= '1';
    extb <= '0';
    wait for 1 ns;
    expect("dse3 en 00 receiver", o_e3d_off, '1');

    -- Verilog IOBUF, BIBUF, PULLUP, PULLDOWN, KEEPER. NVC presents a
    -- Verilog X as U. The VHDL models stay as they are.
    vi <= '0';
    vt <= '0';
    vext_h <= 'Z';
    vext_v <= 'Z';
    wait for 1 ns;
    vcmp(vio_h, vio_v, "vlog iobuf drive 0 pad");
    vcmp(vo_h, vo_v, "vlog iobuf drive 0 o");
    vi <= '1';
    wait for 1 ns;
    vcmp(vio_h, vio_v, "vlog iobuf drive 1 pad");
    vcmp(vo_h, vo_v, "vlog iobuf drive 1 o");
    vi <= 'X';
    wait for 1 ns;
    vcmp(vio_h, vio_v, "vlog iobuf drive X pad");
    vcmp(vo_h, vo_v, "vlog iobuf drive X o");
    vi <= 'Z';
    wait for 1 ns;
    vcmp(vio_h, vio_v, "vlog iobuf drive Z pad");
    vcmp(vo_h, vo_v, "vlog iobuf drive Z o");
    vt <= '1';
    vext_h <= '0';
    vext_v <= '0';
    wait for 1 ns;
    vcmp(vio_h, vio_v, "vlog iobuf release pad");
    vcmp(vo_h, vo_v, "vlog iobuf release o");
    vt <= '0';
    vi <= '1';
    wait for 1 ns;
    vcmp(vio_h, vio_v, "vlog iobuf fight pad");
    vcmp(vo_h, vo_v, "vlog iobuf fight o");

    -- Each BIBUF starts undriven. A strong copy fights a later opposite
    -- value and sticks at X, so the pad-driven case is a second pair.
    bext_io_h <= '1';
    bext_pad_h <= 'Z';
    bext_io_v <= '1';
    bext_pad_v <= 'Z';
    pext_io_h <= 'Z';
    pext_pad_h <= '0';
    pext_io_v <= 'Z';
    pext_pad_v <= '0';
    wait for 1 ns;
    vcmp(bvio_h, bvio_v, "vlog bibuf io");
    vcmp(bvpad_h, bvpad_v, "vlog bibuf pad");
    vcmp(pvio_h, pvio_v, "vlog bibuf from pad io");
    vcmp(pvpad_h, pvpad_v, "vlog bibuf from pad");
    -- Opposite strong drivers from time 0. The VHDL copy is strong, so
    -- both pins are X. Verilog's copy is weak and leaves the strong values.
    if ovio_h /= 'X' or ovpad_h /= 'X' then
      report "bibuf vhdl opposite io=" & to_string(ovio_h)
        & " pad=" & to_string(ovpad_h) severity failure;
    end if;
    n := n + 2;
    if not (ovio_v = '1' or ovio_v = 'X' or ovio_v = 'U')
      or not (ovpad_v = '0' or ovpad_v = 'X' or ovpad_v = 'U') then
      report "bibuf vlog opposite io=" & to_string(ovio_v)
        & " pad=" & to_string(ovpad_v)
        & " (possible NVC bug)" severity failure;
    end if;
    if ovio_h /= ovio_v or ovpad_h /= ovpad_v then
      report "bibuf opposite vhdl io=" & to_string(ovio_h)
        & " pad=" & to_string(ovpad_h)
        & " vlog io=" & to_string(ovio_v)
        & " pad=" & to_string(ovpad_v)
        & " (vhdl copy is strong)"
        severity note;
    end if;

    wait for 1 ns;
    if pu /= '1' and pu /= 'H' then
      report "pullup vlog=" & to_string(pu) & " (possible NVC bug)"
        severity failure;
    end if;
    n := n + 1;
    if pd /= '0' and pd /= 'L' then
      report "pulldown vlog=" & to_string(pd) & " (possible NVC bug)"
        severity failure;
    end if;
    n := n + 1;
    kdrv <= '1';
    wait for 1 ns;
    kdrv <= 'Z';
    wait for 1 ns;
    if keep /= '1' and keep /= 'H' then
      report "keeper high vlog=" & to_string(keep) & " (possible NVC bug)"
        severity failure;
    end if;
    n := n + 1;
    kdrv <= '0';
    wait for 1 ns;
    kdrv <= 'Z';
    wait for 1 ns;
    if keep /= '0' and keep /= 'L' then
      report "keeper low vlog=" & to_string(keep) & " (possible NVC bug)"
        severity failure;
    end if;
    n := n + 1;

    piext_h <= 'Z';
    piext_v <= 'Z';
    vt <= '1';
    wait for 1 ns;
    vcmp(pu_io_h, pu_io_v, "vlog iobuf pullup released");
    -- buf of a weak 1 is X in the VHDL model and 1 in Verilog buf.
    if puo_h /= 'X' then
      report "pullup released vhdl O=" & to_string(puo_h) severity failure;
    end if;
    n := n + 1;
    if puo_v /= '1' and puo_v /= 'H' then
      report "pullup released vlog O=" & to_string(puo_v)
        & " (possible NVC bug)" severity failure;
    end if;
    n := n + 1;
    vt <= '0';
    vi <= '0';
    wait for 1 ns;
    vcmp(pu_io_h, pu_io_v, "vlog iobuf pullup strong 0");
    vcmp(puo_h, puo_v, "vlog iobuf pullup strong 0 o");

    report "tb_iobuf PASS checks=" & integer'image(n) severity note;
    wait;
  end process;
end architecture sim;
