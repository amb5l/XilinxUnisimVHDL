-- Equivalence: each hand-written VHDL primitive (entity unisim.<NAME>)
-- against the Apache-2.0 Verilog model analysed into library work.
-- A component of the same name binds to that Verilog module.
-- GLBL analysed into work supplies glbl.GSR for the Verilog side
-- (high for 100 ns). The Verilog xref does not see unisim.GLBL.
-- The VHDL side uses the local ROC/TOC in unisim_sim (same timing).

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq is
end entity tb_eq;

architecture sim of tb_eq is
  constant vals : std_logic_vector(0 to 3) := "01XZ";

  signal a, b, s : std_ulogic := '0';
  signal t : std_ulogic := '0';
  signal i0, i1, i2, i3, i4, i5 : std_ulogic := '0';
  signal ci, cy : std_ulogic := '0';
  signal di, sel : std_logic_vector(3 downto 0) := (others => '0');

  signal buf_h, buf_v, inv_h, inv_v, bufg_h, bufg_v : std_ulogic;
  signal ibuf_h, ibuf_v, obuf_h, obuf_v, obuft_h, obuft_v : std_ulogic;
  signal vcc_h, vcc_v, gnd_h, gnd_v : std_ulogic;
  signal xor_h, xor_v, mux7_h, mux7_v, mux8_h, mux8_v : std_ulogic;
  signal mux9_h, mux9_v, muxc_h, muxc_v : std_ulogic;
  signal ci8, cit : std_ulogic := '0';
  signal d8, s8 : std_logic_vector(7 downto 0) := (others => '0');
  signal co8_h, co8_v, o8_h, o8_v : std_logic_vector(7 downto 0);
  signal co8d_h, co8d_v, o8d_h, o8d_v : std_logic_vector(7 downto 0);
  signal and_h, and_v, andi_h, andi_v : std_ulogic;
  signal or_h, or_v, ori_h, ori_v : std_ulogic;
  signal l1_h, l1_v, l1z_h, l1z_v : std_ulogic;
  signal l2_h, l2_v, l3_h, l3_v, l4_h, l4_v, l5_h, l5_v, l6_h, l6_v : std_ulogic;
  signal co_h, co_v, o_h, o_v : std_logic_vector(3 downto 0);

  signal c : std_ulogic := '0';
  signal ce, d, r : std_ulogic := '0';
  signal ce1, d1 : std_ulogic := '0';
  signal ce_c, d_c : std_ulogic := '0';
  signal ce_d, d_d : std_ulogic := '0';
  signal ce_r, d_r, r_r : std_ulogic := '0';
  signal ce_s, d_s, s_s : std_ulogic := '0';
  signal ce_clr, d_clr, clr : std_ulogic := '0';
  signal ce_pre, d_pre, pre : std_ulogic := '0';

  signal fd_h, fd_v : std_ulogic;
  signal fd1_h, fd1_v : std_ulogic;
  signal fdc_h, fdc_v : std_ulogic;
  signal fdd_h, fdd_v : std_ulogic;
  signal fdr_h, fdr_v : std_ulogic;
  signal fds_h, fds_v : std_ulogic;
  signal fdce_h, fdce_v : std_ulogic;
  signal fdpe_h, fdpe_v : std_ulogic;

  component BUF is
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component INV is
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component BUFG is
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component VCC is
    port (P : out std_ulogic);
  end component;
  component GND is
    port (G : out std_ulogic);
  end component;
  component XORCY is
    port (O : out std_ulogic; CI, LI : in std_ulogic);
  end component;
  component MUXF7 is
    port (O : out std_ulogic; I0, I1, S : in std_ulogic);
  end component;
  component MUXF8 is
    port (O : out std_ulogic; I0, I1, S : in std_ulogic);
  end component;
  component MUXF9 is
    port (O : out std_ulogic; I0, I1, S : in std_ulogic);
  end component;
  component MUXCY is
    port (O : out std_ulogic; CI, DI, S : in std_ulogic);
  end component;
  component CARRY8 is
    generic (CARRY_TYPE : string := "SINGLE_CY8");
    port (
      CO : out std_logic_vector(7 downto 0);
      O : out std_logic_vector(7 downto 0);
      CI, CI_TOP : in std_ulogic;
      DI, S : in std_logic_vector(7 downto 0)
    );
  end component;
  component IBUF is
    generic (
      CAPACITANCE : string := "DONT_CARE";
      IBUF_DELAY_VALUE : string := "0";
      IBUF_LOW_PWR : boolean := TRUE;
      IFD_DELAY_VALUE : string := "AUTO";
      IOSTANDARD : string := "DEFAULT"
    );
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component OBUF is
    generic (
      CAPACITANCE : string := "DONT_CARE";
      DRIVE : integer := 12;
      IOSTANDARD : string := "DEFAULT";
      SLEW : string := "SLOW"
    );
    port (O : out std_ulogic; I : in std_ulogic);
  end component;
  component OBUFT is
    generic (
      CAPACITANCE : string := "DONT_CARE";
      DRIVE : integer := 12;
      IOSTANDARD : string := "DEFAULT";
      SLEW : string := "SLOW"
    );
    port (O : out std_ulogic; I, T : in std_ulogic);
  end component;
  component AND2B1L is
    generic (IS_SRI_INVERTED : bit := '0');
    port (O : out std_ulogic; DI, SRI : in std_ulogic);
  end component;
  component OR2L is
    generic (IS_SRI_INVERTED : bit := '0');
    port (O : out std_ulogic; DI, SRI : in std_ulogic);
  end component;
  component LUT1 is
    generic (INIT : bit_vector(1 downto 0) := "00");
    port (O : out std_ulogic; I0 : in std_ulogic);
  end component;
  component LUT2 is
    generic (INIT : bit_vector(3 downto 0) := X"0");
    port (O : out std_ulogic; I0, I1 : in std_ulogic);
  end component;
  component LUT3 is
    generic (INIT : bit_vector(7 downto 0) := X"00");
    port (O : out std_ulogic; I0, I1, I2 : in std_ulogic);
  end component;
  component LUT4 is
    generic (INIT : bit_vector(15 downto 0) := X"0000");
    port (O : out std_ulogic; I0, I1, I2, I3 : in std_ulogic);
  end component;
  component LUT5 is
    generic (INIT : bit_vector(31 downto 0) := X"00000000");
    port (O : out std_ulogic; I0, I1, I2, I3, I4 : in std_ulogic);
  end component;
  component LUT6 is
    generic (INIT : bit_vector(63 downto 0) := X"0000000000000000");
    port (O : out std_ulogic; I0, I1, I2, I3, I4, I5 : in std_ulogic);
  end component;
  component CARRY4 is
    port (
      CO : out std_logic_vector(3 downto 0);
      O : out std_logic_vector(3 downto 0);
      CI, CYINIT : in std_ulogic;
      DI, S : in std_logic_vector(3 downto 0)
    );
  end component;
  component FDRE is
    generic (
      INIT : bit := '0';
      IS_C_INVERTED : bit := '0';
      IS_D_INVERTED : bit := '0';
      IS_R_INVERTED : bit := '0'
    );
    port (Q : out std_ulogic; C, CE, D, R : in std_ulogic);
  end component;
  component FDSE is
    generic (
      INIT : bit := '1';
      IS_C_INVERTED : bit := '0';
      IS_D_INVERTED : bit := '0';
      IS_S_INVERTED : bit := '0'
    );
    port (Q : out std_ulogic; C, CE, D, S : in std_ulogic);
  end component;
  component FDCE is
    generic (
      INIT : bit := '0';
      IS_CLR_INVERTED : bit := '0';
      IS_C_INVERTED : bit := '0';
      IS_D_INVERTED : bit := '0'
    );
    port (Q : out std_ulogic; C, CE, CLR, D : in std_ulogic);
  end component;
  component FDPE is
    generic (
      INIT : bit := '1';
      IS_C_INVERTED : bit := '0';
      IS_D_INVERTED : bit := '0';
      IS_PRE_INVERTED : bit := '0'
    );
    port (Q : out std_ulogic; C, CE, D, PRE : in std_ulogic);
  end component;

  -- NVC delivers a Verilog X on an output port into VHDL as 'U'.
  function from_vlog(v : std_ulogic) return std_ulogic is
  begin
    if v = 'U' then
      return 'X';
    end if;
    return v;
  end function;

  function from_vlog(v : std_logic_vector) return std_logic_vector is
    variable r : std_logic_vector(v'range);
  begin
    for i in v'range loop
      r(i) := from_vlog(v(i));
    end loop;
    return r;
  end function;

  procedure eq(name : string; got, exp : std_ulogic) is
  begin
    assert got = from_vlog(exp)
      report name & " VHDL=" & std_ulogic'image(got)
        & " Verilog=" & std_ulogic'image(exp)
      severity failure;
  end procedure;

  procedure eqv(name : string; got, exp : std_logic_vector) is
  begin
    assert got = from_vlog(exp)
      report name & " VHDL=" & to_string(got) & " Verilog=" & to_string(exp)
      severity failure;
  end procedure;

  function bitat(n, b : natural) return std_ulogic is
  begin
    if (n / (2 ** b)) mod 2 = 1 then
      return '1';
    end if;
    return '0';
  end function;
begin
  u_buf_h : entity unisim.BUF port map (O => buf_h, I => a);
  u_buf_v : BUF port map (O => buf_v, I => a);
  u_inv_h : entity unisim.INV port map (O => inv_h, I => a);
  u_inv_v : INV port map (O => inv_v, I => a);
  u_bufg_h : entity unisim.BUFG port map (O => bufg_h, I => a);
  u_bufg_v : BUFG port map (O => bufg_v, I => a);
  u_vcc_h : entity unisim.VCC port map (P => vcc_h);
  u_vcc_v : VCC port map (P => vcc_v);
  u_gnd_h : entity unisim.GND port map (G => gnd_h);
  u_gnd_v : GND port map (G => gnd_v);
  u_xor_h : entity unisim.XORCY port map (O => xor_h, CI => a, LI => b);
  u_xor_v : XORCY port map (O => xor_v, CI => a, LI => b);
  u_m7_h : entity unisim.MUXF7 port map (O => mux7_h, I0 => a, I1 => b, S => s);
  u_m7_v : MUXF7 port map (O => mux7_v, I0 => a, I1 => b, S => s);
  u_m8_h : entity unisim.MUXF8 port map (O => mux8_h, I0 => a, I1 => b, S => s);
  u_m8_v : MUXF8 port map (O => mux8_v, I0 => a, I1 => b, S => s);
  u_m9_h : entity unisim.MUXF9 port map (O => mux9_h, I0 => a, I1 => b, S => s);
  u_m9_v : MUXF9 port map (O => mux9_v, I0 => a, I1 => b, S => s);
  u_mc_h : entity unisim.MUXCY port map (O => muxc_h, CI => b, DI => a, S => s);
  u_mc_v : MUXCY port map (O => muxc_v, CI => b, DI => a, S => s);

  u_ibuf_h : entity unisim.IBUF
    generic map (
      CAPACITANCE => "DONT_CARE",
      IBUF_DELAY_VALUE => "0",
      IBUF_LOW_PWR => TRUE,
      IFD_DELAY_VALUE => "AUTO",
      IOSTANDARD => "DEFAULT"
    )
    port map (O => ibuf_h, I => a);
  u_ibuf_v : IBUF
    generic map (
      CAPACITANCE => "DONT_CARE",
      IBUF_DELAY_VALUE => "0",
      IBUF_LOW_PWR => TRUE,
      IFD_DELAY_VALUE => "AUTO",
      IOSTANDARD => "DEFAULT"
    )
    port map (O => ibuf_v, I => a);

  u_obuf_h : entity unisim.OBUF
    generic map (
      CAPACITANCE => "DONT_CARE", DRIVE => 12,
      IOSTANDARD => "DEFAULT", SLEW => "SLOW"
    )
    port map (O => obuf_h, I => a);
  u_obuf_v : OBUF
    generic map (
      CAPACITANCE => "DONT_CARE", DRIVE => 12,
      IOSTANDARD => "DEFAULT", SLEW => "SLOW"
    )
    port map (O => obuf_v, I => a);

  u_obuft_h : entity unisim.OBUFT
    generic map (
      CAPACITANCE => "DONT_CARE", DRIVE => 12,
      IOSTANDARD => "DEFAULT", SLEW => "SLOW"
    )
    port map (O => obuft_h, I => a, T => t);
  u_obuft_v : OBUFT
    generic map (
      CAPACITANCE => "DONT_CARE", DRIVE => 12,
      IOSTANDARD => "DEFAULT", SLEW => "SLOW"
    )
    port map (O => obuft_v, I => a, T => t);

  u_and_h : entity unisim.AND2B1L
    generic map (IS_SRI_INVERTED => '0')
    port map (O => and_h, DI => a, SRI => b);
  u_and_v : AND2B1L
    generic map (IS_SRI_INVERTED => '0')
    port map (O => and_v, DI => a, SRI => b);
  u_andi_h : entity unisim.AND2B1L
    generic map (IS_SRI_INVERTED => '1')
    port map (O => andi_h, DI => a, SRI => b);
  u_andi_v : AND2B1L
    generic map (IS_SRI_INVERTED => '1')
    port map (O => andi_v, DI => a, SRI => b);
  u_or_h : entity unisim.OR2L
    generic map (IS_SRI_INVERTED => '0')
    port map (O => or_h, DI => a, SRI => b);
  u_or_v : OR2L
    generic map (IS_SRI_INVERTED => '0')
    port map (O => or_v, DI => a, SRI => b);
  u_ori_h : entity unisim.OR2L
    generic map (IS_SRI_INVERTED => '1')
    port map (O => ori_h, DI => a, SRI => b);
  u_ori_v : OR2L
    generic map (IS_SRI_INVERTED => '1')
    port map (O => ori_v, DI => a, SRI => b);

  u_l1_h : entity unisim.LUT1 generic map (INIT => "10") port map (O => l1_h, I0 => i0);
  u_l1_v : LUT1 generic map (INIT => "10") port map (O => l1_v, I0 => i0);
  u_l1z_h : entity unisim.LUT1 generic map (INIT => "00") port map (O => l1z_h, I0 => i0);
  u_l1z_v : LUT1 generic map (INIT => "00") port map (O => l1z_v, I0 => i0);
  u_l2_h : entity unisim.LUT2 generic map (INIT => "0110") port map (O => l2_h, I0 => i0, I1 => i1);
  u_l2_v : LUT2 generic map (INIT => "0110") port map (O => l2_v, I0 => i0, I1 => i1);
  u_l3_h : entity unisim.LUT3 generic map (INIT => X"96") port map (O => l3_h, I0 => i0, I1 => i1, I2 => i2);
  u_l3_v : LUT3 generic map (INIT => X"96") port map (O => l3_v, I0 => i0, I1 => i1, I2 => i2);
  u_l4_h : entity unisim.LUT4 generic map (INIT => X"6996") port map (l4_h, i0, i1, i2, i3);
  u_l4_v : LUT4 generic map (INIT => X"6996") port map (l4_v, i0, i1, i2, i3);
  u_l5_h : entity unisim.LUT5 generic map (INIT => X"96696996") port map (l5_h, i0, i1, i2, i3, i4);
  u_l5_v : LUT5 generic map (INIT => X"96696996") port map (l5_v, i0, i1, i2, i3, i4);
  u_l6_h : entity unisim.LUT6 generic map (INIT => X"6996966996696996")
    port map (l6_h, i0, i1, i2, i3, i4, i5);
  u_l6_v : LUT6 generic map (INIT => X"6996966996696996")
    port map (l6_v, i0, i1, i2, i3, i4, i5);

  u_cy_h : entity unisim.CARRY4 port map (co_h, o_h, ci, cy, di, sel);
  u_cy_v : CARRY4 port map (co_v, o_v, ci, cy, di, sel);
  u_cy8_h : entity unisim.CARRY8 generic map (CARRY_TYPE => "SINGLE_CY8")
    port map (CO => co8_h, O => o8_h, CI => ci8, CI_TOP => cit, DI => d8, S => s8);
  u_cy8_v : CARRY8 generic map (CARRY_TYPE => "SINGLE_CY8")
    port map (CO => co8_v, O => o8_v, CI => ci8, CI_TOP => cit, DI => d8, S => s8);
  u_cy8d_h : entity unisim.CARRY8 generic map (CARRY_TYPE => "DUAL_CY4")
    port map (CO => co8d_h, O => o8d_h, CI => ci8, CI_TOP => cit, DI => d8, S => s8);
  u_cy8d_v : CARRY8 generic map (CARRY_TYPE => "DUAL_CY4")
    port map (CO => co8d_v, O => o8d_v, CI => ci8, CI_TOP => cit, DI => d8, S => s8);

  u_fd_h : entity unisim.FDRE port map (Q => fd_h, C => c, CE => ce, D => d, R => r);
  u_fd_v : FDRE port map (Q => fd_v, C => c, CE => ce, D => d, R => r);
  u_fd1_h : entity unisim.FDRE generic map (INIT => '1')
    port map (Q => fd1_h, C => c, CE => ce1, D => d1, R => '0');
  u_fd1_v : FDRE generic map (INIT => '1')
    port map (Q => fd1_v, C => c, CE => ce1, D => d1, R => '0');
  u_fdc_h : entity unisim.FDRE generic map (IS_C_INVERTED => '1')
    port map (Q => fdc_h, C => c, CE => ce_c, D => d_c, R => '0');
  u_fdc_v : FDRE generic map (IS_C_INVERTED => '1')
    port map (Q => fdc_v, C => c, CE => ce_c, D => d_c, R => '0');
  u_fdd_h : entity unisim.FDRE generic map (IS_D_INVERTED => '1')
    port map (Q => fdd_h, C => c, CE => ce_d, D => d_d, R => '0');
  u_fdd_v : FDRE generic map (IS_D_INVERTED => '1')
    port map (Q => fdd_v, C => c, CE => ce_d, D => d_d, R => '0');
  u_fdr_h : entity unisim.FDRE generic map (IS_R_INVERTED => '1')
    port map (Q => fdr_h, C => c, CE => ce_r, D => d_r, R => r_r);
  u_fdr_v : FDRE generic map (IS_R_INVERTED => '1')
    port map (Q => fdr_v, C => c, CE => ce_r, D => d_r, R => r_r);
  u_fds_h : entity unisim.FDSE port map (Q => fds_h, C => c, CE => ce_s, D => d_s, S => s_s);
  u_fds_v : FDSE port map (Q => fds_v, C => c, CE => ce_s, D => d_s, S => s_s);
  u_fdce_h : entity unisim.FDCE port map (Q => fdce_h, C => c, CE => ce_clr, CLR => clr, D => d_clr);
  u_fdce_v : FDCE port map (Q => fdce_v, C => c, CE => ce_clr, CLR => clr, D => d_clr);
  u_fdpe_h : entity unisim.FDPE port map (Q => fdpe_h, C => c, CE => ce_pre, D => d_pre, PRE => pre);
  u_fdpe_v : FDPE port map (Q => fdpe_v, C => c, CE => ce_pre, D => d_pre, PRE => pre);

  process
    procedure step(delay : time := 1 ns) is
    begin
      wait for delay;
    end procedure;

    procedure pulse is
    begin
      c <= '1';
      step;
      c <= '0';
      step;
    end procedure;

  begin
    -- Past the 100 ps Q delay and the 0 ns GTS drop. GSR is still 1.
    -- A Verilog module instantiated from VHDL does not see glbl.GSR
    -- (the tri0 pull-down wins), so GSR is checked on the VHDL model
    -- against the known ROC behaviour. After 100 ns both sides have
    -- GSR low and the outputs are compared.
    step;
    eq("VCC", vcc_h, vcc_v);
    eq("GND", gnd_h, gnd_v);
    assert vcc_h = '1' and gnd_h = '0'
      report "VCC/GND levels" severity failure;

    a <= '1';
    b <= '0';
    ce <= '1';
    d <= '1';
    step;
    assert and_h = '0' and or_h = '0'
      report "GSR did not force AND2B1L/OR2L to 0" severity failure;
    assert fd_h = '0' and fd1_h = '1' and fds_h = '1'
      and fdce_h = '0' and fdpe_h = '1'
      report "GSR did not force INIT" severity failure;
    -- A clock during GSR must not capture on the VHDL model.
    pulse;
    assert fd_h = '0' and fd1_h = '1'
      report "GSR lost a clock" severity failure;
    ce <= '0';
    d <= '0';

    wait for 150 ns;
    assert and_h = '1' and or_h = '1'
      report "gates stayed forced after GSR" severity failure;
    eq("AND2B1L after GSR", and_h, and_v);
    eq("OR2L after GSR", or_h, or_v);
    assert fd_h = '0' and fd1_h = '1'
      report "INIT did not survive GSR" severity failure;

    for ai in vals'range loop
      a <= vals(ai);
      step;
      eq("BUF", buf_h, buf_v);
      eq("INV", inv_h, inv_v);
      eq("BUFG", bufg_h, bufg_v);
      eq("IBUF", ibuf_h, ibuf_v);
      eq("OBUF", obuf_h, obuf_v);
      for bi in vals'range loop
        b <= vals(bi);
        t <= vals(bi);
        step;
        eq("XORCY", xor_h, xor_v);
        eq("OBUFT", obuft_h, obuft_v);
        eq("AND2B1L", and_h, and_v);
        eq("AND2B1L/SRI", andi_h, andi_v);
        eq("OR2L", or_h, or_v);
        eq("OR2L/SRI", ori_h, ori_v);
        for si in vals'range loop
          s <= vals(si);
          step;
          eq("MUXF7", mux7_h, mux7_v);
          eq("MUXF8", mux8_h, mux8_v);
          eq("MUXF9", mux9_h, mux9_v);
          eq("MUXCY", muxc_h, muxc_v);
        end loop;
      end loop;
    end loop;

    for n in 0 to 1 loop
      i0 <= bitat(n, 0);
      step;
      eq("LUT1", l1_h, l1_v);
      eq("LUT1/0", l1z_h, l1z_v);
    end loop;
    i0 <= 'X';
    step;
    eq("LUT1 X", l1_h, l1_v);
    eq("LUT1/0 X", l1z_h, l1z_v);
    i0 <= 'Z';
    step;
    eq("LUT1 Z", l1_h, l1_v);

    for n in 0 to 3 loop
      i0 <= bitat(n, 0);
      i1 <= bitat(n, 1);
      step;
      eq("LUT2", l2_h, l2_v);
    end loop;
    i0 <= 'X';
    i1 <= '0';
    step;
    eq("LUT2 X", l2_h, l2_v);
    i0 <= 'X';
    i1 <= 'X';
    step;
    eq("LUT2 XX", l2_h, l2_v);

    for n in 0 to 7 loop
      i0 <= bitat(n, 0); i1 <= bitat(n, 1); i2 <= bitat(n, 2);
      step;
      eq("LUT3", l3_h, l3_v);
    end loop;
    for n in 0 to 15 loop
      i0 <= bitat(n, 0); i1 <= bitat(n, 1); i2 <= bitat(n, 2); i3 <= bitat(n, 3);
      step;
      eq("LUT4", l4_h, l4_v);
    end loop;
    for n in 0 to 31 loop
      i0 <= bitat(n, 0); i1 <= bitat(n, 1); i2 <= bitat(n, 2);
      i3 <= bitat(n, 3); i4 <= bitat(n, 4);
      step;
      eq("LUT5", l5_h, l5_v);
    end loop;
    for n in 0 to 63 loop
      i0 <= bitat(n, 0); i1 <= bitat(n, 1); i2 <= bitat(n, 2);
      i3 <= bitat(n, 3); i4 <= bitat(n, 4); i5 <= bitat(n, 5);
      step;
      eq("LUT6", l6_h, l6_v);
    end loop;
    i0 <= 'X'; i1 <= '0'; i2 <= '1'; i3 <= '0'; i4 <= '1'; i5 <= 'X';
    step;
    eq("LUT6 X", l6_h, l6_v);

    for n in 0 to 1023 loop
      ci <= bitat(n, 0);
      cy <= bitat(n, 1);
      di <= (bitat(n, 5), bitat(n, 4), bitat(n, 3), bitat(n, 2));
      sel <= (bitat(n, 9), bitat(n, 8), bitat(n, 7), bitat(n, 6));
      step;
      eqv("CARRY4 CO", co_h, co_v);
      eqv("CARRY4 O", o_h, o_v);
    end loop;
    ci <= 'Z'; cy <= '0'; di <= "0000"; sel <= "1111";
    step;
    eqv("CARRY4 Z", co_h, co_v);
    eqv("CARRY4 Z O", o_h, o_v);
    ci <= 'X'; sel <= "XXXX";
    step;
    eqv("CARRY4 X", co_h, co_v);
    eqv("CARRY4 X O", o_h, o_v);

    -- CARRY8. The Verilog CARRY_TYPE reg settles 2 ps after time 0.
    for ci_i in 0 to 1 loop
      if ci_i = 0 then
        ci8 <= '0';
      else
        ci8 <= '1';
      end if;
      for top_i in 0 to 1 loop
        if top_i = 0 then
          cit <= '0';
        else
          cit <= '1';
        end if;
        for n in 0 to 65535 loop
          for b in 0 to 7 loop
            s8(b) <= bitat(n, b);
            d8(b) <= bitat(n, b + 8);
          end loop;
          step(1 ps);
          eqv("CARRY8 CO", co8_h, co8_v);
          eqv("CARRY8 O", o8_h, o8_v);
          eqv("CARRY8 dual CO", co8d_h, co8d_v);
          eqv("CARRY8 dual O", o8d_h, o8d_v);
        end loop;
      end loop;
    end loop;
    ci8 <= 'Z';
    cit <= '0';
    s8 <= (others => '1');
    d8 <= (others => '0');
    step;
    eqv("CARRY8 Z CO", co8_h, co8_v);
    eqv("CARRY8 Z O", o8_h, o8_v);
    ci8 <= 'X';
    step;
    eqv("CARRY8 X CO", co8_h, co8_v);
    eqv("CARRY8 X O", o8_h, o8_v);
    ci8 <= '1';
    s8 <= (others => 'Z');
    d8 <= (others => '1');
    step;
    eqv("CARRY8 SZ CO", co8_h, co8_v);
    eqv("CARRY8 SZ O", o8_h, o8_v);
    cit <= 'Z';
    ci8 <= '0';
    s8 <= "11110000";
    d8 <= (others => '0');
    step;
    eqv("CARRY8 topZ CO", co8d_h, co8d_v);
    eqv("CARRY8 topZ O", o8d_h, o8d_v);
    cit <= 'X';
    step;
    eqv("CARRY8 topX CO", co8d_h, co8d_v);
    eqv("CARRY8 topX O", o8d_h, o8d_v);
    -- SINGLE_CY8 ignores CI_TOP. Both values of cit must match.
    cit <= '0';
    ci8 <= '1';
    s8 <= (others => '1');
    step;
    eqv("CARRY8 cit0 CO", co8_h, co8_v);
    cit <= '1';
    step;
    eqv("CARRY8 cit1 CO", co8_h, co8_v);

    -- Flops, after GSR. The Verilog side did not see GSR, so its Q is
    -- still X until the first capturing clock. Compare after that.
    ce <= '1'; d <= '1'; r <= '0';
    pulse;
    eq("FDRE D=1", fd_h, fd_v);
    assert fd_h = '1' report "FDRE did not load 1" severity failure;

    ce <= '0'; d <= '0';
    pulse;
    eq("FDRE CE=0", fd_h, fd_v);
    assert fd_h = '1' report "FDRE loaded while CE was 0" severity failure;

    ce <= '1'; d <= '0';
    pulse;
    eq("FDRE D=0", fd_h, fd_v);
    assert fd_h = '0' report "FDRE did not load 0" severity failure;

    r <= '1'; d <= '1';
    pulse;
    eq("FDRE reset", fd_h, fd_v);
    assert fd_h = '0' report "FDRE reset lost to D" severity failure;

    r <= '0';
    pulse;
    eq("FDRE after reset", fd_h, fd_v);
    assert fd_h = '1' report "FDRE did not load after reset" severity failure;

    ce <= 'Z'; d <= '0';
    pulse;
    eq("FDRE CE=Z", fd_h, fd_v);
    assert fd_h = '0' report "FDRE treated CE=Z as disabled" severity failure;

    ce <= 'X'; d <= '1';
    pulse;
    eq("FDRE CE=X hold", fd_h, fd_v);
    assert fd_h = '0' report "FDRE CE=X loaded a different D" severity failure;

    r <= 'X'; ce <= '1'; d <= '1';
    pulse;
    eq("FDRE R=X Q=0", fd_h, fd_v);
    assert fd_h = '0' report "FDRE R=X with Q=0" severity failure;

    r <= '0';
    pulse;
    eq("FDRE reload", fd_h, fd_v);
    r <= 'X';
    pulse;
    eq("FDRE R=X Q=1", fd_h, fd_v);
    assert fd_h = '1' report "FDRE R=X cleared a 1" severity failure;

    r <= 'Z'; d <= '0';
    pulse;
    eq("FDRE R=Z", fd_h, fd_v);
    assert fd_h = '0' report "FDRE treated R=Z as reset" severity failure;

    ce1 <= '1'; d1 <= '0';
    pulse;
    eq("FDRE INIT was loaded", fd1_h, fd1_v);
    assert fd1_h = '0' report "FDRE INIT=1 did not clock" severity failure;

    ce_c <= '1'; d_c <= '1';
    c <= '1';
    step;
    eq("FDRE negedge still 0", fdc_h, fdc_v);
    assert fdc_h = '0' report "inverted clock captured on rising edge" severity failure;
    c <= '0';
    step;
    eq("FDRE negedge load", fdc_h, fdc_v);
    assert fdc_h = '1' report "inverted clock missed the falling edge" severity failure;

    ce_d <= '1'; d_d <= '1';
    pulse;
    eq("FDRE D inverted", fdd_h, fdd_v);
    assert fdd_h = '0' report "IS_D_INVERTED did not invert" severity failure;
    d_d <= '0';
    pulse;
    eq("FDRE D inverted 0", fdd_h, fdd_v);
    assert fdd_h = '1' report "IS_D_INVERTED did not invert a 0" severity failure;

    ce_r <= '1'; d_r <= '1'; r_r <= '0';
    pulse;
    eq("FDRE R inverted active", fdr_h, fdr_v);
    assert fdr_h = '0' report "IS_R_INVERTED did not reset on 0" severity failure;
    r_r <= '1';
    pulse;
    eq("FDRE R inverted off", fdr_h, fdr_v);
    assert fdr_h = '1' report "IS_R_INVERTED reset while deasserted" severity failure;

    ce_s <= '1'; d_s <= '0'; s_s <= '0';
    pulse;
    eq("FDSE load 0", fds_h, fds_v);
    assert fds_h = '0' report "FDSE did not load 0" severity failure;
    s_s <= '1'; d_s <= '0';
    pulse;
    eq("FDSE set", fds_h, fds_v);
    assert fds_h = '1' report "FDSE set lost to D" severity failure;
    s_s <= 'X';
    pulse;
    eq("FDSE S=X", fds_h, fds_v);
    assert fds_h = '1' report "FDSE S=X with Q=1" severity failure;

    clr <= '1'; d_clr <= '1'; ce_clr <= '1';
    step;
    eq("FDCE async", fdce_h, fdce_v);
    assert fdce_h = '0' report "FDCE clear was not async" severity failure;
    clr <= '0';
    pulse;
    eq("FDCE load", fdce_h, fdce_v);
    assert fdce_h = '1' report "FDCE did not load after clear" severity failure;
    clr <= 'X';
    step;
    eq("FDCE X", fdce_h, fdce_v);
    assert fdce_h = 'X' report "FDCE X clear" severity failure;
    clr <= '0';
    step;
    ce_clr <= '0'; d_clr <= '0';
    pulse;
    eq("FDCE CE=0 after X", fdce_h, fdce_v);

    pre <= '0'; ce_pre <= '1'; d_pre <= '0';
    pulse;
    eq("FDPE load 0", fdpe_h, fdpe_v);
    assert fdpe_h = '0' report "FDPE did not load 0" severity failure;
    pre <= '1';
    step;
    eq("FDPE async", fdpe_h, fdpe_v);
    assert fdpe_h = '1' report "FDPE preset was not async" severity failure;
    pre <= 'X';
    step;
    eq("FDPE X", fdpe_h, fdpe_v);
    assert fdpe_h = 'X' report "FDPE X preset" severity failure;

    report "equivalence PASS";
    finish(0);
  end process;
end architecture sim;
