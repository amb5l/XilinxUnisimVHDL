-- Equivalence for the SRL and distributed-RAM models against the
-- Apache-2.0 Verilog analysed into library work. These cells do not
-- use GSR. Clocks are at least 1 ns apart except where a check is
-- looking at the 100 ps write delay.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_ram is
end entity tb_eq_ram;

architecture sim of tb_eq_ram is
  constant i16 : bit_vector(15 downto 0) := X"8001";
  constant i32 : bit_vector(31 downto 0) := X"00000001";
  constant s32 : bit_vector(31 downto 0) := X"80000001";
  constant z32 : bit_vector(31 downto 0) := X"00000000";
  constant i64 : bit_vector(63 downto 0) := X"0000000000000001";
  constant p64 : bit_vector(63 downto 0) := X"0000000000000003";
  constant z64 : bit_vector(63 downto 0) := X"0000000000000000";
  constant i128 : bit_vector(127 downto 0) := X"00000000000000000000000000000001";
  constant i256 : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000001";
  constant i512 : bit_vector(511 downto 0) := X"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001";

  signal clk : std_ulogic := '0';
  signal rclk : std_ulogic := '1';
  signal we : std_ulogic := '0';
  signal d : std_ulogic := '0';
  signal sa : std_logic_vector(8 downto 0) := (others => '0');
  signal wa : std_logic_vector(7 downto 0) := (others => '0');
  signal ra : std_logic_vector(7 downto 0) := (others => '0');

  signal o32_h, o32_v : std_ulogic;
  signal o32n_h, o32n_v : std_ulogic;
  signal spo32_h, spo32_v, dpo32_h, dpo32_v : std_ulogic;
  signal o64_h, o64_v : std_ulogic;
  signal spo64_h, spo64_v, dpo64_h, dpo64_v : std_ulogic;
  signal o128_h, o128_v : std_ulogic;
  signal spo128_h, spo128_v, dpo128_h, dpo128_v : std_ulogic;
  signal o256_h, o256_v : std_ulogic;
  signal spo256_h, spo256_v, dpo256_h, dpo256_v : std_ulogic;
  signal o512_h, o512_v : std_ulogic;

  signal sclk : std_ulogic := '0';
  signal lclk : std_ulogic := '1';
  signal nclk : std_ulogic := '1';
  signal sce : std_ulogic := '0';
  signal sd : std_ulogic := '0';
  signal s0, s1, s2, s3 : std_ulogic := '0';
  signal s32a : std_logic_vector(4 downto 0) := (others => '0');
  signal q16_h, q16_v : std_ulogic;
  signal qc_h, qc_v, q15_h, q15_v : std_ulogic;
  signal q32_h, q32_v, q31_h, q31_v : std_ulogic;
  signal lq_h, lq_v : std_ulogic;
  signal nq_h, nq_v, nq31_h, nq31_v : std_ulogic;

  signal mclk : std_ulogic := '0';
  signal mwe : std_ulogic := '0';
  signal mdi : std_logic_vector(1 downto 0) := "00";
  signal maddra : std_logic_vector(4 downto 0) := (others => '0');
  signal maddrd : std_logic_vector(4 downto 0) := (others => '0');
  signal m64a : std_logic_vector(5 downto 0) := (others => '0');
  signal m_doa_h, m_doa_v : std_logic_vector(1 downto 0);
  signal m_dod_h, m_dod_v : std_logic_vector(1 downto 0);
  signal h_doh_h, h_doh_v : std_logic_vector(1 downto 0);
  signal a64_h, a64_v, d64_h, d64_v : std_ulogic;
  signal h64_h, h64_v : std_ulogic;
  signal x_doa_h, x_doa_v : std_ulogic;
  signal x_doh_h, x_doh_v : std_logic_vector(1 downto 0);
  signal xaddr : std_logic_vector(5 downto 0) := (others => '0');
  signal xaddrh : std_logic_vector(4 downto 0) := (others => '0');

  signal swclk : std_ulogic := '0';
  signal swnclk : std_ulogic := '1';
  signal swwe : std_ulogic := '0';
  signal swd : std_ulogic := '0';
  signal swa : std_logic_vector(5 downto 0) := (others => '0');
  signal swsel : std_logic_vector(2 downto 0) := "111";
  signal swo_h, swo_v : std_logic_vector(7 downto 0);
  signal swho_h, swho_v : std_logic_vector(7 downto 0);
  signal swno_h, swno_v : std_logic_vector(7 downto 0);

  component RAM32X1S is
    generic (INIT : bit_vector(31 downto 0) := X"00000000"; IS_WCLK_INVERTED : bit := '0');
    port (O : out std_ulogic; A0, A1, A2, A3, A4, D, WCLK, WE : in std_ulogic);
  end component;
  component RAM32X1D is
    generic (INIT : bit_vector(31 downto 0) := X"00000000"; IS_WCLK_INVERTED : bit := '0');
    port (
      DPO, SPO : out std_ulogic;
      A0, A1, A2, A3, A4, D : in std_ulogic;
      DPRA0, DPRA1, DPRA2, DPRA3, DPRA4, WCLK, WE : in std_ulogic
    );
  end component;
  component RAM64X1S is
    generic (INIT : bit_vector(63 downto 0) := X"0000000000000000"; IS_WCLK_INVERTED : bit := '0');
    port (O : out std_ulogic; A0, A1, A2, A3, A4, A5, D, WCLK, WE : in std_ulogic);
  end component;
  component RAM64X1D is
    generic (INIT : bit_vector(63 downto 0) := X"0000000000000000"; IS_WCLK_INVERTED : bit := '0');
    port (
      DPO, SPO : out std_ulogic;
      A0, A1, A2, A3, A4, A5, D : in std_ulogic;
      DPRA0, DPRA1, DPRA2, DPRA3, DPRA4, DPRA5, WCLK, WE : in std_ulogic
    );
  end component;
  component RAM128X1S is
    generic (INIT : bit_vector(127 downto 0) := X"00000000000000000000000000000000"; IS_WCLK_INVERTED : bit := '0');
    port (O : out std_ulogic; A0, A1, A2, A3, A4, A5, A6, D, WCLK, WE : in std_ulogic);
  end component;
  component RAM128X1D is
    generic (INIT : bit_vector(127 downto 0) := X"00000000000000000000000000000000"; IS_WCLK_INVERTED : bit := '0');
    port (
      DPO, SPO : out std_ulogic;
      A : in std_logic_vector(6 downto 0);
      D : in std_ulogic;
      DPRA : in std_logic_vector(6 downto 0);
      WCLK, WE : in std_ulogic
    );
  end component;
  component RAM256X1S is
    generic (
      INIT : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      IS_WCLK_INVERTED : bit := '0'
    );
    port (O : out std_ulogic; A : in std_logic_vector(7 downto 0); D, WCLK, WE : in std_ulogic);
  end component;
  component RAM256X1D is
    generic (
      INIT : bit_vector(255 downto 0) := X"0000000000000000000000000000000000000000000000000000000000000000";
      IS_WCLK_INVERTED : bit := '0'
    );
    port (
      DPO, SPO : out std_ulogic;
      A : in std_logic_vector(7 downto 0);
      D : in std_ulogic;
      DPRA : in std_logic_vector(7 downto 0);
      WCLK, WE : in std_ulogic
    );
  end component;
  component RAM512X1S is
    generic (
      INIT : bit_vector(511 downto 0) := X"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
      IS_WCLK_INVERTED : bit := '0'
    );
    port (O : out std_ulogic; A : in std_logic_vector(8 downto 0); D, WCLK, WE : in std_ulogic);
  end component;
  component SRL16E is
    generic (INIT : bit_vector(15 downto 0) := X"0000"; IS_CLK_INVERTED : bit := '0');
    port (Q : out std_ulogic; A0, A1, A2, A3, CE, CLK, D : in std_ulogic);
  end component;
  component SRLC16E is
    generic (INIT : bit_vector(15 downto 0) := X"0000"; IS_CLK_INVERTED : bit := '0');
    port (Q, Q15 : out std_ulogic; A0, A1, A2, A3, CE, CLK, D : in std_ulogic);
  end component;
  component SRLC32E is
    generic (INIT : bit_vector(31 downto 0) := X"00000000"; IS_CLK_INVERTED : bit := '0');
    port (
      Q, Q31 : out std_ulogic;
      A : in std_logic_vector(4 downto 0);
      CE, CLK, D : in std_ulogic
    );
  end component;
  component RAM32M is
    generic (
      INIT_A, INIT_B, INIT_C, INIT_D : bit_vector(63 downto 0) := X"0000000000000000";
      IS_WCLK_INVERTED : bit := '0'
    );
    port (
      DOA, DOB, DOC, DOD : out std_logic_vector(1 downto 0);
      ADDRA, ADDRB, ADDRC, ADDRD : in std_logic_vector(4 downto 0);
      DIA, DIB, DIC, DID : in std_logic_vector(1 downto 0);
      WCLK, WE : in std_ulogic
    );
  end component;
  component RAM32M16 is
    generic (
      INIT_A, INIT_B, INIT_C, INIT_D, INIT_E, INIT_F, INIT_G, INIT_H : bit_vector(63 downto 0) := X"0000000000000000";
      IS_WCLK_INVERTED : bit := '0'
    );
    port (
      DOA, DOB, DOC, DOD, DOE, DOF, DOG, DOH : out std_logic_vector(1 downto 0);
      ADDRA, ADDRB, ADDRC, ADDRD, ADDRE, ADDRF, ADDRG, ADDRH : in std_logic_vector(4 downto 0);
      DIA, DIB, DIC, DID, DIE, DIF, DIG, DIH : in std_logic_vector(1 downto 0);
      WCLK, WE : in std_ulogic
    );
  end component;
  component RAM64M is
    generic (
      INIT_A, INIT_B, INIT_C, INIT_D : bit_vector(63 downto 0) := X"0000000000000000";
      IS_WCLK_INVERTED : bit := '0'
    );
    port (
      DOA, DOB, DOC, DOD : out std_ulogic;
      ADDRA, ADDRB, ADDRC, ADDRD : in std_logic_vector(5 downto 0);
      DIA, DIB, DIC, DID, WCLK, WE : in std_ulogic
    );
  end component;
  component RAM64M8 is
    generic (
      INIT_A, INIT_B, INIT_C, INIT_D, INIT_E, INIT_F, INIT_G, INIT_H : bit_vector(63 downto 0) := X"0000000000000000";
      IS_WCLK_INVERTED : bit := '0'
    );
    port (
      DOA, DOB, DOC, DOD, DOE, DOF, DOG, DOH : out std_ulogic;
      ADDRA, ADDRB, ADDRC, ADDRD, ADDRE, ADDRF, ADDRG, ADDRH : in std_logic_vector(5 downto 0);
      DIA, DIB, DIC, DID, DIE, DIF, DIG, DIH, WCLK, WE : in std_ulogic
    );
  end component;
  component RAM32X16DR8 is
    generic (IS_WCLK_INVERTED : bit := '0');
    port (
      DOA, DOB, DOC, DOD, DOE, DOF, DOG : out std_ulogic;
      DOH : out std_logic_vector(1 downto 0);
      ADDRA, ADDRB, ADDRC, ADDRD, ADDRE, ADDRF, ADDRG : in std_logic_vector(5 downto 0);
      ADDRH : in std_logic_vector(4 downto 0);
      DIA, DIB, DIC, DID, DIE, DIF, DIG, DIH : in std_logic_vector(1 downto 0);
      WCLK, WE : in std_ulogic
    );
  end component;
  component RAM64X8SW is
    generic (
      INIT_A, INIT_B, INIT_C, INIT_D, INIT_E, INIT_F, INIT_G, INIT_H : bit_vector(63 downto 0) := X"0000000000000000";
      IS_WCLK_INVERTED : bit := '0'
    );
    port (
      O : out std_logic_vector(7 downto 0);
      A : in std_logic_vector(5 downto 0);
      D, WCLK, WE : in std_ulogic;
      WSEL : in std_logic_vector(2 downto 0)
    );
  end component;

  function from_vlog(v : std_ulogic) return std_ulogic is
  begin
    if v = 'U' then
      return 'X';
    end if;
    return v;
  end function;

  function from_vec(v : std_logic_vector) return std_logic_vector is
    variable r : std_logic_vector(v'range);
  begin
    for i in v'range loop
      r(i) := from_vlog(v(i));
    end loop;
    return r;
  end function;

begin
  u32_h : entity unisim.RAM32X1S generic map (INIT => i32)
    port map (O => o32_h, A0 => sa(0), A1 => sa(1), A2 => sa(2), A3 => sa(3), A4 => sa(4),
              D => d, WCLK => clk, WE => we);
  u32_v : RAM32X1S generic map (INIT => i32)
    port map (O => o32_v, A0 => sa(0), A1 => sa(1), A2 => sa(2), A3 => sa(3), A4 => sa(4),
              D => d, WCLK => clk, WE => we);
  u32n_h : entity unisim.RAM32X1S generic map (INIT => i32, IS_WCLK_INVERTED => '1')
    port map (O => o32n_h, A0 => sa(0), A1 => sa(1), A2 => sa(2), A3 => sa(3), A4 => sa(4),
              D => d, WCLK => rclk, WE => we);
  u32n_v : RAM32X1S generic map (INIT => i32, IS_WCLK_INVERTED => '1')
    port map (O => o32n_v, A0 => sa(0), A1 => sa(1), A2 => sa(2), A3 => sa(3), A4 => sa(4),
              D => d, WCLK => rclk, WE => we);
  u32d_h : entity unisim.RAM32X1D generic map (INIT => i32)
    port map (DPO => dpo32_h, SPO => spo32_h,
              A0 => wa(0), A1 => wa(1), A2 => wa(2), A3 => wa(3), A4 => wa(4), D => d,
              DPRA0 => ra(0), DPRA1 => ra(1), DPRA2 => ra(2), DPRA3 => ra(3), DPRA4 => ra(4),
              WCLK => clk, WE => we);
  u32d_v : RAM32X1D generic map (INIT => i32)
    port map (DPO => dpo32_v, SPO => spo32_v,
              A0 => wa(0), A1 => wa(1), A2 => wa(2), A3 => wa(3), A4 => wa(4), D => d,
              DPRA0 => ra(0), DPRA1 => ra(1), DPRA2 => ra(2), DPRA3 => ra(3), DPRA4 => ra(4),
              WCLK => clk, WE => we);

  u64_h : entity unisim.RAM64X1S generic map (INIT => i64)
    port map (O => o64_h, A0 => sa(0), A1 => sa(1), A2 => sa(2), A3 => sa(3), A4 => sa(4), A5 => sa(5),
              D => d, WCLK => clk, WE => we);
  u64_v : RAM64X1S generic map (INIT => i64)
    port map (O => o64_v, A0 => sa(0), A1 => sa(1), A2 => sa(2), A3 => sa(3), A4 => sa(4), A5 => sa(5),
              D => d, WCLK => clk, WE => we);
  u64d_h : entity unisim.RAM64X1D generic map (INIT => i64)
    port map (DPO => dpo64_h, SPO => spo64_h,
              A0 => wa(0), A1 => wa(1), A2 => wa(2), A3 => wa(3), A4 => wa(4), A5 => wa(5), D => d,
              DPRA0 => ra(0), DPRA1 => ra(1), DPRA2 => ra(2), DPRA3 => ra(3), DPRA4 => ra(4), DPRA5 => ra(5),
              WCLK => clk, WE => we);
  u64d_v : RAM64X1D generic map (INIT => i64)
    port map (DPO => dpo64_v, SPO => spo64_v,
              A0 => wa(0), A1 => wa(1), A2 => wa(2), A3 => wa(3), A4 => wa(4), A5 => wa(5), D => d,
              DPRA0 => ra(0), DPRA1 => ra(1), DPRA2 => ra(2), DPRA3 => ra(3), DPRA4 => ra(4), DPRA5 => ra(5),
              WCLK => clk, WE => we);

  u128_h : entity unisim.RAM128X1S generic map (INIT => i128)
    port map (O => o128_h, A0 => sa(0), A1 => sa(1), A2 => sa(2), A3 => sa(3), A4 => sa(4), A5 => sa(5), A6 => sa(6),
              D => d, WCLK => clk, WE => we);
  u128_v : RAM128X1S generic map (INIT => i128)
    port map (O => o128_v, A0 => sa(0), A1 => sa(1), A2 => sa(2), A3 => sa(3), A4 => sa(4), A5 => sa(5), A6 => sa(6),
              D => d, WCLK => clk, WE => we);
  u128d_h : entity unisim.RAM128X1D generic map (INIT => i128)
    port map (DPO => dpo128_h, SPO => spo128_h, A => wa(6 downto 0), D => d, DPRA => ra(6 downto 0), WCLK => clk, WE => we);
  u128d_v : RAM128X1D generic map (INIT => i128)
    port map (DPO => dpo128_v, SPO => spo128_v, A => wa(6 downto 0), D => d, DPRA => ra(6 downto 0), WCLK => clk, WE => we);

  u256_h : entity unisim.RAM256X1S generic map (INIT => i256)
    port map (O => o256_h, A => sa(7 downto 0), D => d, WCLK => clk, WE => we);
  u256_v : RAM256X1S generic map (INIT => i256)
    port map (O => o256_v, A => sa(7 downto 0), D => d, WCLK => clk, WE => we);
  u256d_h : entity unisim.RAM256X1D generic map (INIT => i256)
    port map (DPO => dpo256_h, SPO => spo256_h, A => wa, D => d, DPRA => ra, WCLK => clk, WE => we);
  u256d_v : RAM256X1D generic map (INIT => i256)
    port map (DPO => dpo256_v, SPO => spo256_v, A => wa, D => d, DPRA => ra, WCLK => clk, WE => we);

  u512_h : entity unisim.RAM512X1S generic map (INIT => i512)
    port map (O => o512_h, A => sa, D => d, WCLK => clk, WE => we);
  u512_v : RAM512X1S generic map (INIT => i512)
    port map (O => o512_v, A => sa, D => d, WCLK => clk, WE => we);

  us_h : entity unisim.SRL16E generic map (INIT => i16)
    port map (Q => q16_h, A0 => s0, A1 => s1, A2 => s2, A3 => s3, CE => sce, CLK => sclk, D => sd);
  us_v : SRL16E generic map (INIT => i16)
    port map (Q => q16_v, A0 => s0, A1 => s1, A2 => s2, A3 => s3, CE => sce, CLK => sclk, D => sd);
  uc_h : entity unisim.SRLC16E generic map (INIT => i16)
    port map (Q => qc_h, Q15 => q15_h, A0 => s0, A1 => s1, A2 => s2, A3 => s3, CE => sce, CLK => sclk, D => sd);
  uc_v : SRLC16E generic map (INIT => i16)
    port map (Q => qc_v, Q15 => q15_v, A0 => s0, A1 => s1, A2 => s2, A3 => s3, CE => sce, CLK => sclk, D => sd);
  u32e_h : entity unisim.SRLC32E generic map (INIT => s32)
    port map (Q => q32_h, Q31 => q31_h, A => s32a, CE => sce, CLK => sclk, D => sd);
  u32e_v : SRLC32E generic map (INIT => s32)
    port map (Q => q32_v, Q31 => q31_v, A => s32a, CE => sce, CLK => sclk, D => sd);
  ul_h : entity unisim.SRL16E generic map (INIT => i32(15 downto 0))
    port map (Q => lq_h, A0 => '0', A1 => '0', A2 => '0', A3 => '0', CE => sce, CLK => lclk, D => sd);
  ul_v : SRL16E generic map (INIT => i32(15 downto 0))
    port map (Q => lq_v, A0 => '0', A1 => '0', A2 => '0', A3 => '0', CE => sce, CLK => lclk, D => sd);
  un_h : entity unisim.SRLC32E generic map (INIT => i32, IS_CLK_INVERTED => '1')
    port map (Q => nq_h, Q31 => nq31_h, A => s32a, CE => sce, CLK => nclk, D => sd);
  un_v : SRLC32E generic map (INIT => i32, IS_CLK_INVERTED => '1')
    port map (Q => nq_v, Q31 => nq31_v, A => s32a, CE => sce, CLK => nclk, D => sd);

  um_h : entity unisim.RAM32M generic map (INIT_A => p64)
    port map (DOA => m_doa_h, DOB => open, DOC => open, DOD => m_dod_h,
              ADDRA => maddra, ADDRB => maddra, ADDRC => maddra, ADDRD => maddrd,
              DIA => mdi, DIB => "00", DIC => "00", DID => "00", WCLK => mclk, WE => mwe);
  um_v : RAM32M generic map (INIT_A => p64)
    port map (DOA => m_doa_v, DOB => open, DOC => open, DOD => m_dod_v,
              ADDRA => maddra, ADDRB => maddra, ADDRC => maddra, ADDRD => maddrd,
              DIA => mdi, DIB => "00", DIC => "00", DID => "00", WCLK => mclk, WE => mwe);
  uh_h : entity unisim.RAM32M16 generic map (INIT_H => p64)
    port map (
      DOA => open, DOB => open, DOC => open, DOD => open, DOE => open, DOF => open, DOG => open, DOH => h_doh_h,
      ADDRA => maddra, ADDRB => maddra, ADDRC => maddra, ADDRD => maddra,
      ADDRE => maddra, ADDRF => maddra, ADDRG => maddra, ADDRH => maddrd,
      DIA => "00", DIB => "00", DIC => "00", DID => "00", DIE => "00", DIF => "00", DIG => "00", DIH => mdi,
      WCLK => mclk, WE => mwe);
  uh_v : RAM32M16 generic map (INIT_H => p64)
    port map (
      DOA => open, DOB => open, DOC => open, DOD => open, DOE => open, DOF => open, DOG => open, DOH => h_doh_v,
      ADDRA => maddra, ADDRB => maddra, ADDRC => maddra, ADDRD => maddra,
      ADDRE => maddra, ADDRF => maddra, ADDRG => maddra, ADDRH => maddrd,
      DIA => "00", DIB => "00", DIC => "00", DID => "00", DIE => "00", DIF => "00", DIG => "00", DIH => mdi,
      WCLK => mclk, WE => mwe);

  u64m_h : entity unisim.RAM64M generic map (INIT_A => i64, INIT_D => i64)
    port map (DOA => a64_h, DOB => open, DOC => open, DOD => d64_h,
              ADDRA => m64a, ADDRB => m64a, ADDRC => m64a, ADDRD => m64a,
              DIA => d, DIB => '0', DIC => '0', DID => d, WCLK => mclk, WE => mwe);
  u64m_v : RAM64M generic map (INIT_A => i64, INIT_D => i64)
    port map (DOA => a64_v, DOB => open, DOC => open, DOD => d64_v,
              ADDRA => m64a, ADDRB => m64a, ADDRC => m64a, ADDRD => m64a,
              DIA => d, DIB => '0', DIC => '0', DID => d, WCLK => mclk, WE => mwe);
  u64m8_h : entity unisim.RAM64M8 generic map (INIT_H => i64)
    port map (
      DOA => open, DOB => open, DOC => open, DOD => open, DOE => open, DOF => open, DOG => open, DOH => h64_h,
      ADDRA => m64a, ADDRB => m64a, ADDRC => m64a, ADDRD => m64a,
      ADDRE => m64a, ADDRF => m64a, ADDRG => m64a, ADDRH => m64a,
      DIA => '0', DIB => '0', DIC => '0', DID => '0', DIE => '0', DIF => '0', DIG => '0', DIH => d,
      WCLK => mclk, WE => mwe);
  u64m8_v : RAM64M8 generic map (INIT_H => i64)
    port map (
      DOA => open, DOB => open, DOC => open, DOD => open, DOE => open, DOF => open, DOG => open, DOH => h64_v,
      ADDRA => m64a, ADDRB => m64a, ADDRC => m64a, ADDRD => m64a,
      ADDRE => m64a, ADDRF => m64a, ADDRG => m64a, ADDRH => m64a,
      DIA => '0', DIB => '0', DIC => '0', DID => '0', DIE => '0', DIF => '0', DIG => '0', DIH => d,
      WCLK => mclk, WE => mwe);

  ux_h : entity unisim.RAM32X16DR8
    port map (
      DOA => x_doa_h, DOB => open, DOC => open, DOD => open, DOE => open, DOF => open, DOG => open, DOH => x_doh_h,
      ADDRA => xaddr, ADDRB => xaddr, ADDRC => xaddr, ADDRD => xaddr, ADDRE => xaddr, ADDRF => xaddr, ADDRG => xaddr,
      ADDRH => xaddrh,
      DIA => mdi, DIB => "00", DIC => "00", DID => "00", DIE => "00", DIF => "00", DIG => "00", DIH => mdi,
      WCLK => mclk, WE => mwe);
  ux_v : RAM32X16DR8
    port map (
      DOA => x_doa_v, DOB => open, DOC => open, DOD => open, DOE => open, DOF => open, DOG => open, DOH => x_doh_v,
      ADDRA => xaddr, ADDRB => xaddr, ADDRC => xaddr, ADDRD => xaddr, ADDRE => xaddr, ADDRF => xaddr, ADDRG => xaddr,
      ADDRH => xaddrh,
      DIA => mdi, DIB => "00", DIC => "00", DID => "00", DIE => "00", DIF => "00", DIG => "00", DIH => mdi,
      WCLK => mclk, WE => mwe);

  usw_h : entity unisim.RAM64X8SW generic map (INIT_A => i64)
    port map (O => swo_h, A => swa, D => swd, WCLK => swclk, WE => swwe, WSEL => swsel);
  usw_v : RAM64X8SW generic map (INIT_A => i64)
    port map (O => swo_v, A => swa, D => swd, WCLK => swclk, WE => swwe, WSEL => swsel);
  uswh_h : entity unisim.RAM64X8SW generic map (INIT_A => i64)
    port map (O => swho_h, A => "000000", D => '0', WCLK => '0', WE => '0', WSEL => "000");
  uswh_v : RAM64X8SW generic map (INIT_A => i64)
    port map (O => swho_v, A => "000000", D => '0', WCLK => '0', WE => '0', WSEL => "000");
  uswn_h : entity unisim.RAM64X8SW generic map (INIT_A => i64, IS_WCLK_INVERTED => '1')
    port map (O => swno_h, A => swa, D => swd, WCLK => swnclk, WE => swwe, WSEL => swsel);
  uswn_v : RAM64X8SW generic map (INIT_A => i64, IS_WCLK_INVERTED => '1')
    port map (O => swno_v, A => swa, D => swd, WCLK => swnclk, WE => swwe, WSEL => swsel);

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

    procedure eqv(name : string; got, exp : std_logic_vector) is
    begin
      n := n + 1;
      assert got = from_vec(exp)
        report name & " mismatch" severity failure;
    end procedure;

    procedure rise(signal c : out std_ulogic) is
    begin
      c <= '0';
      wait for 1 ns;
      c <= '1';
      wait for 1 ns;
    end procedure;

    procedure fall(signal c : out std_ulogic) is
    begin
      c <= '1';
      wait for 1 ns;
      c <= '0';
      wait for 1 ns;
    end procedure;

    procedure put_addr(signal a : out std_logic_vector; value : natural) is
      variable tmp : std_logic_vector(a'length - 1 downto 0);
      variable rest : natural := value;
    begin
      tmp := (others => '0');
      for i in tmp'reverse_range loop
        if rest mod 2 = 1 then
          tmp(i) := '1';
        end if;
        rest := rest / 2;
      end loop;
      a <= tmp;
    end procedure;

    procedure check_init is
    begin
      eq("RAM32X1S init", o32_h, o32_v);
      eq("RAM32X1S inv init", o32n_h, o32n_v);
      eq("RAM32X1D SPO init", spo32_h, spo32_v);
      eq("RAM32X1D DPO init", dpo32_h, dpo32_v);
      eq("RAM64X1S init", o64_h, o64_v);
      eq("RAM64X1D SPO init", spo64_h, spo64_v);
      eq("RAM64X1D DPO init", dpo64_h, dpo64_v);
      eq("RAM128X1S init", o128_h, o128_v);
      eq("RAM128X1D SPO init", spo128_h, spo128_v);
      eq("RAM128X1D DPO init", dpo128_h, dpo128_v);
      eq("RAM256X1S init", o256_h, o256_v);
      eq("RAM256X1D SPO init", spo256_h, spo256_v);
      eq("RAM256X1D DPO init", dpo256_h, dpo256_v);
      eq("RAM512X1S init", o512_h, o512_v);
    end procedure;
  begin
    -- RAM64X8SW output stays X until the address changes or 100 ps pass.
    wait for 1 ps;
    eqv("SW X", swo_h, swo_v);
    eqv("SW hold X", swho_h, swho_v);
    assert swo_h = "XXXXXXXX"
      report "RAM64X8SW published O before 100 ps" severity failure;
    swa <= "000001";
    wait for 1 ps;
    eqv("SW address", swo_h, swo_v);
    assert swo_h = "00000000"
      report "RAM64X8SW address change did not publish" severity failure;

    -- Between the 1 ns INIT polls, so the sample does not see the low pulse.
    sce <= '1';
    sd <= '0';
    wait for 1500 ps;
    assert lq_h = '1' and from_vlog(lq_v) = '1'
      report "SRL16E lock lost INIT" severity failure;
    lclk <= '0';
    wait for 100 ps;
    lclk <= '1';
    wait for 1 ns;
    eq("SRL locked", lq_h, lq_v);
    assert lq_h = '1' report "SRL16E shifted while INIT was forced" severity failure;

    lclk <= '0';
    wait for 2 ns;
    sce <= '1';
    sd <= '0';
    lclk <= '1';
    wait for 1 ns;
    eq("SRL released", lq_h, lq_v);
    assert lq_h = '0' report "SRL16E did not shift after the INIT force" severity failure;

    wait for 2 ns;
    eq("SRL16E Q", q16_h, q16_v);
    eq("SRLC16E Q", qc_h, qc_v);
    eq("SRLC16E Q15", q15_h, q15_v);
    eq("SRLC32E Q", q32_h, q32_v);
    eq("SRLC32E Q31", q31_h, q31_v);
    assert q16_h = '1' and q15_h = '1' and q31_h = '1'
      report "SRL INIT bit was not visible" severity failure;

    sce <= '0';
    sd <= '0';
    rise(sclk);
    eq("SRL CE0", q16_h, q16_v);
    assert q16_h = '1' report "SRL shifted with CE 0" severity failure;
    sce <= 'X';
    rise(sclk);
    eq("SRL CEX", q16_h, q16_v);
    assert q16_h = '1' report "SRL shifted with CE X" severity failure;
    sce <= 'Z';
    rise(sclk);
    eq("SRL CEZ", q16_h, q16_v);
    eq("SRLC16E Q15 shift", q15_h, q15_v);
    eq("SRLC32E Q31 shift", q31_h, q31_v);
    assert q16_h = '0' report "SRL CE Z did not shift" severity failure;
    assert q15_h = '0' and q31_h = '0'
      report "cascade output did not follow the shift" severity failure;

    s0 <= '1';
    s32a <= "00001";
    wait for 1 ns;
    eq("SRL addr1", q16_h, q16_v);
    eq("SRLC32 addr1", q32_h, q32_v);
    assert q16_h = '1' and q32_h = '1'
      report "shifted bit was not at address 1" severity failure;
    s0 <= 'X';
    s32a <= "0000X";
    wait for 1 ns;
    eq("SRL X", q16_h, q16_v);
    eq("SRLC32 X", q32_h, q32_v);
    assert q16_h = 'X' and q32_h = 'X'
      report "SRL X address did not read X" severity failure;
    s0 <= '0';
    s32a <= "00000";

    sce <= '1';
    sd <= '0';
    wait for 2 ns;
    fall(nclk);
    eq("SRL neg Q", nq_h, nq_v);
    eq("SRL neg Q31", nq31_h, nq31_v);
    assert nq_h = '0' report "inverted SRL did not shift" severity failure;

    -- Distributed RAM. Address 0 is the INIT bit.
    wait for 1 ns;
    check_init;
    assert o32_h = '1' and o512_h = '1' and spo32_h = '1' and dpo32_h = '1'
      report "RAM INIT bit 0 was not 1" severity failure;

    put_addr(sa, 5);
    put_addr(wa, 5);
    put_addr(ra, 0);
    d <= '1';
    we <= '1';
    wait for 1 ns;
    eq("RAM32 before", o32_h, o32_v);
    assert o32_h = '0' and spo32_h = '0' and dpo32_h = '1'
      report "address 5 was not empty" severity failure;
    clk <= '1';
    wait for 50 ps;
    eq("RAM32 mid", o32_h, o32_v);
    eq("RAM32D SPO mid", spo32_h, spo32_v);
    eq("RAM32D DPO mid", dpo32_h, dpo32_v);
    assert o32_h = '0' and dpo32_h = '1'
      report "RAM write was visible before 100 ps" severity failure;
    wait for 100 ps;
    eq("RAM32 land", o32_h, o32_v);
    eq("RAM64 land", o64_h, o64_v);
    eq("RAM128 land", o128_h, o128_v);
    eq("RAM256 land", o256_h, o256_v);
    eq("RAM512 land", o512_h, o512_v);
    eq("RAM32D SPO land", spo32_h, spo32_v);
    eq("RAM32D DPO land", dpo32_h, dpo32_v);
    eq("RAM64D DPO land", dpo64_h, dpo64_v);
    eq("RAM128D DPO land", dpo128_h, dpo128_v);
    eq("RAM256D DPO land", dpo256_h, dpo256_v);
    assert o32_h = '1' and o512_h = '1' and spo32_h = '1' and dpo32_h = '1'
      report "RAM write did not land at 100 ps" severity failure;
    clk <= '0';
    wait for 1 ns;

    -- Last address of every depth is the low bits of 511.
    put_addr(sa, 511);
    put_addr(wa, 511);
    d <= '1';
    we <= '1';
    wait for 1 ns;
    rise(clk);
    eq("RAM32 top", o32_h, o32_v);
    eq("RAM64 top", o64_h, o64_v);
    eq("RAM128 top", o128_h, o128_v);
    eq("RAM256 top", o256_h, o256_v);
    eq("RAM512 top", o512_h, o512_v);
    eq("RAM32D top", spo32_h, spo32_v);
    eq("RAM64D top", spo64_h, spo64_v);
    eq("RAM128D top", spo128_h, spo128_v);
    eq("RAM256D top", spo256_h, spo256_v);
    eq("RAM32D DPO held", dpo32_h, dpo32_v);
    assert o32_h = '1' and o64_h = '1' and o128_h = '1' and o256_h = '1' and o512_h = '1'
      report "top address write failed" severity failure;
    assert dpo32_h = '1' report "read port followed the write port" severity failure;

    put_addr(sa, 6);
    d <= '1';
    we <= '0';
    rise(clk);
    eq("RAM WE0", o32_h, o32_v);
    assert o32_h = '0' report "WE 0 wrote" severity failure;
    we <= 'X';
    rise(clk);
    eq("RAM WEX", o32_h, o32_v);
    assert o32_h = '0' report "WE X wrote" severity failure;
    we <= 'Z';
    rise(clk);
    eq("RAM WEZ", o32_h, o32_v);
    assert o32_h = '1' report "WE Z did not write" severity failure;

    put_addr(sa, 2);
    wait for 1 ns;
    sa(0) <= 'X';
    wait for 1 ns;
    eq("RAM addr X", o32_h, o32_v);
    assert o32_h = 'X' report "X address did not read X" severity failure;
    d <= '1';
    we <= '1';
    rise(clk);
    put_addr(sa, 2);
    wait for 1 ns;
    eq("RAM addr X write", o32_h, o32_v);
    assert o32_h = '0' report "X address wrote a bit" severity failure;

    -- Two writes 40 ps apart both complete. Transport keeps the first.
    put_addr(sa, 8);
    d <= '1';
    we <= '1';
    clk <= '0';
    wait for 1 ns;
    clk <= '1';
    wait for 20 ps;
    clk <= '0';
    wait for 20 ps;
    d <= '0';
    clk <= '1';
    -- 100 ps from the first edge, plus a delta so the VHDL read updates.
    wait for 61 ps;
    eq("RAM transport first", o32_h, o32_v);
    assert o32_h = '1' report "first write was dropped" severity failure;
    wait for 50 ps;
    eq("RAM transport second", o32_h, o32_v);
    assert o32_h = '0' report "second write did not land" severity failure;
    clk <= '0';
    we <= '0';
    wait for 1 ns;

    put_addr(sa, 9);
    d <= '1';
    we <= '1';
    wait for 1 ns;
    rclk <= '0';
    wait for 50 ps;
    eq("RAM inv mid", o32n_h, o32n_v);
    assert o32n_h = '0' report "inverted write was early" severity failure;
    wait for 100 ps;
    eq("RAM inv land", o32n_h, o32n_v);
    eq("RAM pos held", o32_h, o32_v);
    assert o32n_h = '1' and o32_h = '0'
      report "inverted clock did not write on the falling edge" severity failure;
    we <= '0';
    wait for 1 ns;

    -- Pair RAM. A write before ADDRD changes does not land.
    mdi <= "10";
    mwe <= '1';
    put_addr(maddra, 0);
    put_addr(maddrd, 0);
    wait for 1 ns;
    eqv("RAM32M init", m_doa_h, m_doa_v);
    eqv("RAM32M16 init", h_doh_h, h_doh_v);
    assert m_doa_h = "11" and h_doh_h = "11"
      report "pair INIT was not bits 0 and 1" severity failure;
    rise(mclk);
    eqv("RAM32M unarmed", m_doa_h, m_doa_v);
    assert m_doa_h = "11" report "unarmed pair write landed" severity failure;
    put_addr(maddrd, 1);
    wait for 1 ns;
    put_addr(maddrd, 0);
    wait for 1 ns;
    mclk <= '0';
    wait for 1 ns;
    mclk <= '1';
    wait for 50 ps;
    eqv("RAM32M mid", m_doa_h, m_doa_v);
    assert m_doa_h = "11" report "pair write was early" severity failure;
    wait for 100 ps;
    eqv("RAM32M land", m_doa_h, m_doa_v);
    eqv("RAM32M DOD", m_dod_h, m_dod_v);
    eqv("RAM32M16 land", h_doh_h, h_doh_v);
    assert m_doa_h = "10" and m_dod_h = "00" and h_doh_h = "10"
      report "pair write mapping was wrong" severity failure;
    put_addr(maddra, 1);
    wait for 1 ns;
    eqv("RAM32M other", m_doa_h, m_doa_v);
    assert m_doa_h = "00" report "pair read port saw the write address" severity failure;
    mwe <= '0';
    mclk <= '0';

    -- RAM64M writes the live address. No arming step.
    put_addr(m64a, 0);
    d <= '0';
    mwe <= '1';
    wait for 1 ns;
    eq("RAM64M init", a64_h, a64_v);
    eq("RAM64M8 init", h64_h, h64_v);
    assert a64_h = '1' and h64_h = '1' report "RAM64M INIT" severity failure;
    mclk <= '1';
    wait for 50 ps;
    eq("RAM64M mid", a64_h, a64_v);
    assert a64_h = '1' report "RAM64M write was early" severity failure;
    wait for 100 ps;
    eq("RAM64M land", a64_h, a64_v);
    eq("RAM64M DOD", d64_h, d64_v);
    eq("RAM64M8 land", h64_h, h64_v);
    assert a64_h = '0' and d64_h = '0' and h64_h = '0'
      report "RAM64M write did not land" severity failure;
    mclk <= '0';
    mwe <= '0';

    -- RAM32X16DR8 starts at X. The write address arms like RAM32M.
    mdi <= "10";
    mwe <= '1';
    put_addr(xaddr, 0);
    put_addr(xaddrh, 0);
    wait for 1 ns;
    eq("DR8 init", x_doa_h, x_doa_v);
    eqv("DR8 DOH init", x_doh_h, x_doh_v);
    assert x_doa_h = 'X' report "RAM32X16DR8 did not start at X" severity failure;
    rise(mclk);
    eq("DR8 unarmed", x_doa_h, x_doa_v);
    assert x_doa_h = 'X' report "unarmed DR8 write landed" severity failure;
    put_addr(xaddrh, 1);
    wait for 1 ns;
    put_addr(xaddrh, 0);
    wait for 1 ns;
    mclk <= '0';
    wait for 1 ns;
    mclk <= '1';
    wait for 150 ps;
    eq("DR8 even", x_doa_h, x_doa_v);
    eqv("DR8 DOH", x_doh_h, x_doh_v);
    assert x_doa_h = '0' and x_doh_h = "10"
      report "DR8 even bit was not DI(0)" severity failure;
    put_addr(xaddr, 1);
    wait for 1 ns;
    eq("DR8 odd", x_doa_h, x_doa_v);
    assert x_doa_h = '1' report "DR8 odd bit was not DI(1)" severity failure;
    mwe <= '0';
    mclk <= '0';

    -- The hold instance never saw an address change, so 100 ps published INIT.
    eqv("SW hold", swho_h, swho_v);
    assert swho_h = "10000000" report "RAM64X8SW 100 ps publish" severity failure;

    swa <= "000000";
    swd <= '0';
    swwe <= '1';
    swsel <= "111";
    wait for 1 ns;
    swclk <= '1';
    wait for 1 ps;
    eqv("SW write", swo_h, swo_v);
    assert swo_h = "00000000" report "WSEL 111 did not clear bit 7" severity failure;
    swsel <= "XXX";
    swd <= '1';
    swclk <= '0';
    wait for 1 ns;
    swclk <= '1';
    wait for 1 ns;
    eqv("SW WSEL X", swo_h, swo_v);
    assert swo_h = "00000000" report "WSEL X wrote" severity failure;
    swsel <= "000";
    swwe <= '0';
    swclk <= '0';
    wait for 1 ns;
    swclk <= '1';
    wait for 1 ns;
    eqv("SW WE0", swo_h, swo_v);
    assert swo_h(0) = '0' report "WE 0 wrote mem_h" severity failure;
    swwe <= 'Z';
    swclk <= '0';
    wait for 1 ns;
    swclk <= '1';
    wait for 1 ns;
    eqv("SW WEZ", swo_h, swo_v);
    assert swo_h = "00000001" report "WE Z did not write mem_h" severity failure;

    swa <= "000000";
    swd <= '0';
    swwe <= '1';
    swsel <= "111";
    wait for 1 ns;
    swnclk <= '0';
    wait for 1 ns;
    eqv("SW neg", swno_h, swno_v);
    assert swno_h(7) = '0' report "inverted RAM64X8SW did not write" severity failure;

    report "tb_eq_ram PASS checks=" & integer'image(n) severity note;
    finish(0);
  end process;
end architecture sim;
