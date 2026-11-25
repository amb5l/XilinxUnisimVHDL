-- DSP_ALU. W/X/Y/Z operand mux, carry-save add, and the four SIMD
-- slices. ALU_OUT is delayed 1 ps, matching the Verilog. U and V are
-- replaced by 45'h100000000000 unless USE_SIMD is ONE48 (the fallback
-- for an unknown name). An unknown XORSIMD is the 24/48/96 tree.
-- Attribute checks and the OPMODE DRC are not modelled. No $finish.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.unisim_sim.all;

entity DSP_ALU is
  generic (
    ALUMODEREG : integer := 1;
    CARRYINREG : integer := 1;
    CARRYINSELREG : integer := 1;
    IS_ALUMODE_INVERTED : bit_vector(3 downto 0) := X"0";
    IS_CARRYIN_INVERTED : bit := '0';
    IS_CLK_INVERTED : bit := '0';
    IS_OPMODE_INVERTED : bit_vector(8 downto 0) := "000000000";
    IS_RSTALLCARRYIN_INVERTED : bit := '0';
    IS_RSTALUMODE_INVERTED : bit := '0';
    IS_RSTCTRL_INVERTED : bit := '0';
    MREG : integer := 1;
    OPMODEREG : integer := 1;
    RND : bit_vector(47 downto 0) := X"000000000000";
    USE_SIMD : string := "ONE48";
    USE_WIDEXOR : boolean := FALSE;
    XORSIMD : string := "XOR24_48_96"
  );
  port (
    ALUMODE10 : out std_ulogic;
    ALU_OUT : out std_logic_vector(47 downto 0);
    COUT : out std_logic_vector(3 downto 0);
    MULTSIGN_ALU : out std_ulogic;
    XOR_MX : out std_logic_vector(7 downto 0);
    ALUMODE : in std_logic_vector(3 downto 0);
    AMULT26 : in std_ulogic;
    A_ALU : in std_logic_vector(29 downto 0);
    BMULT17 : in std_ulogic;
    B_ALU : in std_logic_vector(17 downto 0);
    CARRYCASCIN : in std_ulogic;
    CARRYIN : in std_ulogic;
    CARRYINSEL : in std_logic_vector(2 downto 0);
    CCOUT : in std_ulogic;
    CEALUMODE : in std_ulogic;
    CECARRYIN : in std_ulogic;
    CECTRL : in std_ulogic;
    CEM : in std_ulogic;
    CLK : in std_ulogic;
    C_DATA : in std_logic_vector(47 downto 0);
    MULTSIGNIN : in std_ulogic;
    OPMODE : in std_logic_vector(8 downto 0);
    PCIN : in std_logic_vector(47 downto 0);
    P_FDBK : in std_logic_vector(47 downto 0);
    P_FDBK_47 : in std_ulogic;
    RSTALLCARRYIN : in std_ulogic;
    RSTALUMODE : in std_ulogic;
    RSTCTRL : in std_ulogic;
    U_DATA : in std_logic_vector(44 downto 0);
    V_DATA : in std_logic_vector(44 downto 0)
  );
end entity DSP_ALU;

architecture sim of DSP_ALU is
  function bits(b : bit_vector) return std_logic_vector is
    variable r : std_logic_vector(b'range);
  begin
    for i in b'range loop
      r(i) := to_sul(b(i));
    end loop;
    return r;
  end function;

  function binary(s : std_logic_vector) return boolean is
  begin
    for i in s'range loop
      if s(i) /= '0' and s(i) /= '1' then
        return false;
      end if;
    end loop;
    return true;
  end function;

  function casex_hit(pat, val : std_logic_vector) return boolean is
    alias pa : std_logic_vector(pat'length - 1 downto 0) is pat;
    alias va : std_logic_vector(val'length - 1 downto 0) is val;
  begin
    if pa'length /= va'length then
      return false;
    end if;
    for i in pa'range loop
      if pa(i) /= 'X' and pa(i) /= 'Z' and va(i) /= 'X' and va(i) /= 'Z'
         and va(i) /= 'U' and va(i) /= 'W' and va(i) /= '-' then
        if pa(i) /= va(i) then
          return false;
        end if;
      end if;
    end loop;
    return true;
  end function;

  function xor_reduce(s : std_logic_vector) return std_ulogic is
    variable r : std_ulogic := '0';
  begin
    for i in s'range loop
      if s(i) /= '0' and s(i) /= '1' then
        return 'X';
      end if;
      r := r xor s(i);
    end loop;
    return r;
  end function;

  function add_uv(a, b : std_logic_vector; c : std_ulogic; w : positive)
    return std_logic_vector is
    variable acc : unsigned(w downto 0);
  begin
    if (c /= '0' and c /= '1') or not binary(a) or not binary(b) then
      return (w - 1 downto 0 => 'X');
    end if;
    acc := resize(unsigned(a), w + 1) + resize(unsigned(b), w + 1);
    if c = '1' then
      acc := acc + 1;
    end if;
    return std_logic_vector(acc(w - 1 downto 0));
  end function;

  -- 0 && x is 0. 1 && x is x.
  function band(en : boolean; s : std_ulogic) return std_ulogic is
  begin
    if not en then
      return '0';
    end if;
    return s;
  end function;

  signal gsr : std_ulogic := '1';
  signal clk_in : std_ulogic;
  signal opmode_reg : std_logic_vector(8 downto 0) := (others => '0');
  signal carryinsel_reg : std_logic_vector(2 downto 0) := (others => '0');
  signal alumode_reg : std_logic_vector(3 downto 0) := (others => '0');
  signal carryin_reg : std_ulogic := '0';
  signal qmult : std_ulogic := '0';
  signal alu_raw : std_logic_vector(47 downto 0) := (others => '0');
  signal opmode_in : std_logic_vector(8 downto 0);
  signal alumode_in : std_logic_vector(3 downto 0);
  signal carryinsel_in : std_logic_vector(2 downto 0);
  signal u_in, v_in : std_logic_vector(44 downto 0);
  constant rnd_v : std_logic_vector(47 downto 0) := bits(RND);
  constant four12 : boolean := USE_SIMD = "FOUR12";
  constant two24 : boolean := USE_SIMD = "TWO24";
  constant one48 : boolean := not four12 and not two24;
  constant xor12 : boolean := XORSIMD = "XOR12";
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  clk_in <= gate_in(CLK, IS_CLK_INVERTED);
  opmode_in <= gate_inv(OPMODE, IS_OPMODE_INVERTED);
  alumode_in <= gate_inv(ALUMODE, IS_ALUMODE_INVERTED);
  carryinsel_in <= rv0v(CARRYINSEL);
  u_in <= U_DATA when one48 else (44 => '1', others => '0');
  v_in <= V_DATA when one48 else (44 => '1', others => '0');

  reg : process (gsr, clk_in)
    variable prev : std_ulogic := 'U';
    variable armed : boolean := false;
    variable rst_ctrl, rst_alu, rst_cin : std_ulogic;
    variable c_mult, ce_m, d_c, dr_c : std_ulogic;
  begin
    rst_ctrl := gate_in(RSTCTRL, IS_RSTCTRL_INVERTED);
    rst_alu := gate_in(RSTALUMODE, IS_RSTALUMODE_INVERTED);
    rst_cin := gate_in(RSTALLCARRYIN, IS_RSTALLCARRYIN_INVERTED);
    c_mult := not (AMULT26 xor BMULT17);
    if gsr = '1' then
      ce_m := '0';
    else
      ce_m := rv0(CEM);
    end if;
    if ce_m = '1' then
      d_c := c_mult;
    elsif ce_m = '0' then
      d_c := qmult;
    else
      d_c := 'X';
    end if;
    if gsr = '0' and rst_cin = '1' then
      dr_c := '0';
    elsif gsr = '0' and rst_cin = '0' then
      dr_c := d_c;
    else
      dr_c := '0';
    end if;
    if gsr = '1' then
      opmode_reg <= (others => '0');
      carryinsel_reg <= (others => '0');
      alumode_reg <= (others => '0');
      carryin_reg <= '0';
      qmult <= '0';
    elsif armed and verilog_posedge(prev, clk_in) then
      if rst_ctrl = '1' then
        opmode_reg <= (others => '0');
        carryinsel_reg <= (others => '0');
      elsif rv0(CECTRL) = '1' then
        opmode_reg <= opmode_in;
        carryinsel_reg <= carryinsel_in;
      end if;
      if rst_alu = '1' then
        alumode_reg <= (others => '0');
      elsif rv0(CEALUMODE) = '1' then
        alumode_reg <= alumode_in;
      end if;
      if rst_cin = '1' then
        carryin_reg <= '0';
      elsif rv0(CECARRYIN) = '1' then
        carryin_reg <= gate_in(CARRYIN, IS_CARRYIN_INVERTED);
      end if;
      qmult <= dr_c;
    end if;
    armed := true;
    prev := clk_in;
  end process;

  alu : process (all)
    variable opm : std_logic_vector(8 downto 0);
    variable alum : std_logic_vector(3 downto 0);
    variable csel : std_logic_vector(2 downto 0);
    variable cin_m, cin_b, cin, mult_c : std_ulogic;
    variable wmux, xmux, ymux, zmux : std_logic_vector(47 downto 0);
    variable z_opt, co, s, comux, smux : std_logic_vector(47 downto 0);
    variable comux4, shifted, smux_w, comux_w : std_logic_vector(47 downto 0);
    variable a_int : std_logic_vector(48 downto 0);
    variable s0, s1, s2 : std_logic_vector(12 downto 0);
    variable s3 : std_logic_vector(13 downto 0);
    variable alumode10_v, cout0, cout1, cout2, cout3 : std_ulogic;
    variable intc1, intc2, intc3, co12, co24, co36 : std_ulogic;
    variable logic_op : std_ulogic;
    variable cout_0, cout_1, cout_2 : std_ulogic;
    variable x12 : std_logic_vector(7 downto 0);
    variable result : std_logic_vector(47 downto 0);
    variable opz : std_logic_vector(2 downto 0);
  begin
    if OPMODEREG = 1 then
      opm := opmode_reg;
    else
      opm := opmode_in;
    end if;
    if ALUMODEREG = 1 then
      alum := alumode_reg;
    else
      alum := alumode_in;
    end if;
    if CARRYINSELREG = 1 then
      csel := carryinsel_reg;
    else
      csel := carryinsel_in;
    end if;
    if CARRYINREG = 1 then
      cin_m := carryin_reg;
    else
      cin_m := gate_in(CARRYIN, IS_CARRYIN_INVERTED);
    end if;
    if MREG = 1 then
      mult_c := qmult;
    else
      mult_c := not (AMULT26 xor BMULT17);
    end if;

    if opm(8 downto 7) = "00" then
      wmux := (others => '0');
    elsif opm(8 downto 7) = "01" then
      wmux := P_FDBK;
    elsif opm(8 downto 7) = "10" then
      wmux := rnd_v;
    elsif opm(8 downto 7) = "11" then
      wmux := C_DATA;
    else
      wmux := (others => 'X');
    end if;

    if opm(1 downto 0) = "00" then
      xmux := (others => '0');
      if opm(6 downto 4) = "100" then
        xmux(1) := MULTSIGNIN;
      elsif not binary(opm(6 downto 4)) then
        xmux := (others => 'X');
      end if;
    elsif opm(1 downto 0) = "01" then
      xmux := u_in(44) & u_in(44) & u_in(44) & u_in;
    elsif opm(1 downto 0) = "10" then
      xmux := P_FDBK;
    elsif opm(1 downto 0) = "11" then
      xmux := A_ALU & B_ALU;
    else
      xmux := (others => 'X');
    end if;

    if opm(3 downto 2) = "00" then
      ymux := (others => '0');
    elsif opm(3 downto 2) = "01" then
      ymux := "000" & v_in;
    elsif opm(3 downto 2) = "10" then
      ymux := (others => '1');
    elsif opm(3 downto 2) = "11" then
      ymux := C_DATA;
    else
      ymux := (others => 'X');
    end if;

    opz := opm(6 downto 4);
    if casex_hit(std_logic_vector'("000"), opz) then
      zmux := (others => '0');
    elsif casex_hit(std_logic_vector'("001"), opz) then
      zmux := PCIN;
    elsif casex_hit(std_logic_vector'("010"), opz) then
      zmux := P_FDBK;
    elsif casex_hit(std_logic_vector'("011"), opz) then
      zmux := C_DATA;
    elsif casex_hit(std_logic_vector'("100"), opz) then
      zmux := P_FDBK;
    elsif casex_hit(std_logic_vector'("101"), opz) then
      zmux(47 downto 31) := (others => PCIN(47));
      zmux(30 downto 0) := PCIN(47 downto 17);
    elsif casex_hit(std_logic_vector'("11X"), opz) then
      zmux(47 downto 39) := (others => P_FDBK_47);
      zmux(38 downto 31) := (others => P_FDBK(47));
      zmux(30 downto 0) := P_FDBK(47 downto 17);
    else
      zmux := (others => 'X');
    end if;

    for i in z_opt'range loop
      z_opt(i) := alum(0) xor zmux(i);
    end loop;
    co := (xmux and ymux) or (z_opt and ymux) or (xmux and z_opt);
    s := z_opt xor xmux xor ymux;
    if alum(2) = '1' then
      comux := (others => '0');
    elsif alum(2) = '0' then
      comux := co;
    else
      comux := (others => 'X');
    end if;
    if alum(3) = '1' then
      smux := co;
    elsif alum(3) = '0' then
      smux := s;
    else
      smux := (others => 'X');
    end if;

    comux4 := comux;
    if four12 or two24 then
      comux4(23) := '0';
    end if;
    if four12 then
      comux4(35) := '0';
      comux4(11) := '0';
    end if;

    shifted := comux4(46 downto 0) & '0';
    smux_w := smux xor shifted xor wmux;
    comux_w := (smux and shifted) or (wmux and shifted) or (smux and wmux);

    if csel = "000" then
      cin_b := not cin_m;
    elsif csel = "001" then
      cin_b := PCIN(47);
    elsif csel = "010" then
      cin_b := not CARRYCASCIN;
    elsif csel = "011" then
      cin_b := not PCIN(47);
    elsif csel = "100" then
      cin_b := not CCOUT;
    elsif csel = "101" then
      cin_b := P_FDBK(47);
    elsif csel = "110" then
      cin_b := not mult_c;
    elsif csel = "111" then
      cin_b := not P_FDBK(47);
    else
      cin_b := 'X';
    end if;
    if alum(3) = '0' and alum(2) = '0' then
      cin := not cin_b;
    elsif alum(3) = '1' or alum(2) = '1' then
      cin := '0';
    else
      cin := 'X';
    end if;

    a_int := comux_w & cin;
    s0 := add_uv(a_int(11 downto 0), smux_w(11 downto 0), '0', 13);
    alumode10_v := alum(0) and alum(1);
    cout0 := alumode10_v xor a_int(12) xor s0(12) xor comux(11);
    intc1 := band(not four12, s0(12));
    co12 := band(not four12, a_int(12));
    s1 := add_uv(a_int(23 downto 13) & co12, smux_w(23 downto 12), intc1, 13);
    cout1 := alumode10_v xor a_int(24) xor s1(12) xor comux(23);
    intc2 := band(one48, s1(12));
    co24 := band(one48, a_int(24));
    s2 := add_uv(a_int(35 downto 25) & co24, smux_w(35 downto 24), intc2, 13);
    cout2 := alumode10_v xor a_int(36) xor s2(12) xor comux(35);
    intc3 := band(not four12, s2(12));
    co36 := band(not four12, a_int(36));
    s3 := add_uv(a_int(48 downto 37) & co36, comux4(47) & smux_w(47 downto 36), intc3, 14);
    cout3 := alumode10_v xor s3(12);

    if opm(3 downto 0) = "0101" then
      logic_op := '1';
    elsif alum(3 downto 2) = "00" and binary(opm(3 downto 0)) then
      logic_op := '0';
    elsif alum(3) = '1' or alum(2) = '1' then
      logic_op := '1';
    else
      logic_op := 'X';
    end if;
    if logic_op = '0' then
      cout_0 := cout0;
      cout_1 := cout1;
      cout_2 := cout2;
    else
      cout_0 := 'X';
      cout_1 := 'X';
      cout_2 := 'X';
    end if;

    ALUMODE10 <= alumode10_v;
    COUT(3) <= cout3;
    if four12 then
      COUT(2) <= cout_2;
      COUT(0) <= cout_0;
    else
      COUT(2) <= 'X';
      COUT(0) <= 'X';
    end if;
    if one48 then
      COUT(1) <= 'X';
    else
      COUT(1) <= cout_1;
    end if;
    MULTSIGN_ALU <= s3(13);
    result := s3(11 downto 0) & s2(11 downto 0) & s1(11 downto 0) & s0(11 downto 0);
    for i in result'range loop
      result(i) := alum(1) xor result(i);
    end loop;
    alu_raw <= result;

    if USE_WIDEXOR then
      x12(0) := xor_reduce(s(5 downto 0));
      x12(1) := xor_reduce(s(11 downto 6));
      x12(2) := xor_reduce(s(17 downto 12));
      x12(3) := xor_reduce(s(23 downto 18));
      x12(4) := xor_reduce(s(29 downto 24));
      x12(5) := xor_reduce(s(35 downto 30));
      x12(6) := xor_reduce(s(41 downto 36));
      x12(7) := xor_reduce(s(47 downto 42));
      if xor12 then
        XOR_MX <= x12;
      else
        XOR_MX(0) <= x12(0) xor x12(1);
        XOR_MX(1) <= x12(0) xor x12(1) xor x12(2) xor x12(3);
        XOR_MX(2) <= x12(2) xor x12(3);
        XOR_MX(3) <= xor_reduce(x12);
        XOR_MX(4) <= x12(4) xor x12(5);
        XOR_MX(5) <= x12(4) xor x12(5) xor x12(6) xor x12(7);
        XOR_MX(6) <= x12(6) xor x12(7);
        XOR_MX(7) <= x12(7);
      end if;
    else
      XOR_MX <= (others => '0');
    end if;
  end process;

  ALU_OUT <= alu_raw after 1 ps;
end architecture sim;
