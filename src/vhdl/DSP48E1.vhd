-- DSP48E1. 25x18 multiply, 7-bit OPMODE, no W mux. AREG 1 loads both
-- A stages from the input mux; AREG 2 is the cascade. PREG 0 delays P
-- by 1 ps. The OPMODE DRC is not modelled, so an invalid OPMODE does
-- not force pattern detect to X, and an illegal attribute does not
-- $finish. Equivalence is without XIL_TIMING: the specify paths are
-- already (0:0:0) and $setuphold is inside that ifdef.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.unisim_sim.all;

entity DSP48E1 is
  generic (
    ACASCREG : integer := 1;
    ADREG : integer := 1;
    ALUMODEREG : integer := 1;
    AREG : integer := 1;
    AUTORESET_PATDET : string := "NO_RESET";
    A_INPUT : string := "DIRECT";
    BCASCREG : integer := 1;
    BREG : integer := 1;
    B_INPUT : string := "DIRECT";
    CARRYINREG : integer := 1;
    CARRYINSELREG : integer := 1;
    CREG : integer := 1;
    DREG : integer := 1;
    INMODEREG : integer := 1;
    IS_ALUMODE_INVERTED : bit_vector(3 downto 0) := X"0";
    IS_CARRYIN_INVERTED : bit := '0';
    IS_CLK_INVERTED : bit := '0';
    IS_INMODE_INVERTED : bit_vector(4 downto 0) := "00000";
    IS_OPMODE_INVERTED : bit_vector(6 downto 0) := "0000000";
    MASK : bit_vector(47 downto 0) := X"3FFFFFFFFFFF";
    MREG : integer := 1;
    OPMODEREG : integer := 1;
    PATTERN : bit_vector(47 downto 0) := X"000000000000";
    PREG : integer := 1;
    SEL_MASK : string := "MASK";
    SEL_PATTERN : string := "PATTERN";
    USE_DPORT : boolean := FALSE;
    USE_MULT : string := "MULTIPLY";
    USE_PATTERN_DETECT : string := "NO_PATDET";
    USE_SIMD : string := "ONE48"
  );
  port (
    ACOUT : out std_logic_vector(29 downto 0);
    BCOUT : out std_logic_vector(17 downto 0);
    CARRYCASCOUT : out std_ulogic;
    CARRYOUT : out std_logic_vector(3 downto 0);
    MULTSIGNOUT : out std_ulogic;
    OVERFLOW : out std_ulogic;
    P : out std_logic_vector(47 downto 0);
    PATTERNBDETECT : out std_ulogic;
    PATTERNDETECT : out std_ulogic;
    PCOUT : out std_logic_vector(47 downto 0);
    UNDERFLOW : out std_ulogic;
    A : in std_logic_vector(29 downto 0);
    ACIN : in std_logic_vector(29 downto 0);
    ALUMODE : in std_logic_vector(3 downto 0);
    B : in std_logic_vector(17 downto 0);
    BCIN : in std_logic_vector(17 downto 0);
    C : in std_logic_vector(47 downto 0);
    CARRYCASCIN : in std_ulogic;
    CARRYIN : in std_ulogic;
    CARRYINSEL : in std_logic_vector(2 downto 0);
    CEA1 : in std_ulogic;
    CEA2 : in std_ulogic;
    CEAD : in std_ulogic;
    CEALUMODE : in std_ulogic;
    CEB1 : in std_ulogic;
    CEB2 : in std_ulogic;
    CEC : in std_ulogic;
    CECARRYIN : in std_ulogic;
    CECTRL : in std_ulogic;
    CED : in std_ulogic;
    CEINMODE : in std_ulogic;
    CEM : in std_ulogic;
    CEP : in std_ulogic;
    CLK : in std_ulogic;
    D : in std_logic_vector(24 downto 0);
    INMODE : in std_logic_vector(4 downto 0);
    MULTSIGNIN : in std_ulogic;
    OPMODE : in std_logic_vector(6 downto 0);
    PCIN : in std_logic_vector(47 downto 0);
    RSTA : in std_ulogic;
    RSTALLCARRYIN : in std_ulogic;
    RSTALUMODE : in std_ulogic;
    RSTB : in std_ulogic;
    RSTC : in std_ulogic;
    RSTCTRL : in std_ulogic;
    RSTD : in std_ulogic;
    RSTINMODE : in std_ulogic;
    RSTM : in std_ulogic;
    RSTP : in std_ulogic
  );
end entity DSP48E1;

architecture sim of DSP48E1 is
  function bits(b : bit_vector) return std_logic_vector is
    variable r : std_logic_vector(b'range);
  begin
    for i in b'range loop
      r(i) := to_sul(b(i));
    end loop;
    return r;
  end function;

  function xv(s : std_logic_vector; inv : bit_vector) return std_logic_vector is
    variable r : std_logic_vector(s'range);
  begin
    for i in s'range loop
      r(i) := vxor(s(i), inv(i));
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

  -- Verilog == : X if any bit is X or Z, else 1 or 0.
  function veq(a, b : std_logic_vector) return std_ulogic is
    alias aa : std_logic_vector(a'length - 1 downto 0) is a;
    alias bb : std_logic_vector(b'length - 1 downto 0) is b;
  begin
    if aa'length /= bb'length then
      return 'X';
    end if;
    for i in aa'range loop
      if (aa(i) /= '0' and aa(i) /= '1') or (bb(i) /= '0' and bb(i) /= '1') then
        return 'X';
      elsif aa(i) /= bb(i) then
        return '0';
      end if;
    end loop;
    return '1';
  end function;

  function vor(a, b : std_ulogic) return std_ulogic is
  begin
    if a = '1' or b = '1' then
      return '1';
    elsif a = '0' and b = '0' then
      return '0';
    else
      return 'X';
    end if;
  end function;

  function merge(sel : std_ulogic; a, b : std_logic_vector) return std_logic_vector is
    alias aa : std_logic_vector(a'length - 1 downto 0) is a;
    alias bb : std_logic_vector(b'length - 1 downto 0) is b;
    variable r : std_logic_vector(aa'range);
  begin
    if sel = '1' then
      r := aa;
    elsif sel = '0' then
      r := bb;
    else
      for i in aa'range loop
        if aa(i) = bb(i) then
          r(i) := aa(i);
        else
          r(i) := 'X';
        end if;
      end loop;
    end if;
    return r;
  end function;

  -- Sum of two equal-length vectors plus cin. Result is one bit wider
  -- and the top bit is the carry. Non-binary inputs return X.
  function addn(a, b : std_logic_vector; cin : std_ulogic) return std_logic_vector is
    alias aa : std_logic_vector(a'length - 1 downto 0) is a;
    alias bb : std_logic_vector(b'length - 1 downto 0) is b;
    variable acc : unsigned(aa'length downto 0);
  begin
    if aa'length /= bb'length or (cin /= '0' and cin /= '1')
       or not binary(aa) or not binary(bb) then
      return (aa'length downto 0 => 'X');
    end if;
    acc := resize(unsigned(aa), aa'length + 1) + resize(unsigned(bb), aa'length + 1);
    if cin = '1' then
      acc := acc + 1;
    end if;
    return std_logic_vector(acc);
  end function;

  function add25(sub : std_ulogic; a, d : std_logic_vector(24 downto 0))
    return std_logic_vector is
    variable acc : unsigned(24 downto 0);
  begin
    if (sub /= '0' and sub /= '1') or not binary(a) or not binary(d) then
      return (24 downto 0 => 'X');
    end if;
    if sub = '1' then
      acc := unsigned(d) - unsigned(a);
    else
      acc := unsigned(a) + unsigned(d);
    end if;
    return std_logic_vector(acc);
  end function;

  function and_red(s : std_logic_vector) return std_ulogic is
    variable r : std_ulogic := '1';
  begin
    for i in s'range loop
      if s(i) = '0' then
        return '0';
      elsif s(i) /= '1' then
        r := 'X';
      end if;
    end loop;
    return r;
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

  function vxnor(a, b : std_ulogic) return std_ulogic is
  begin
    if (a /= '0' and a /= '1') or (b /= '0' and b /= '1') then
      return 'X';
    elsif a = b then
      return '1';
    else
      return '0';
    end if;
  end function;

  signal gsr : std_ulogic := '1';
  signal clk_in : std_ulogic;
  signal alumode_in : std_logic_vector(3 downto 0);
  signal inmode_in : std_logic_vector(4 downto 0);
  signal opmode_in : std_logic_vector(6 downto 0);
  signal carryin_in : std_ulogic;

  signal a1_reg, a2_reg : std_logic_vector(29 downto 0) := (others => '0');
  signal b1_reg, b2_reg : std_logic_vector(17 downto 0) := (others => '0');
  signal c_reg, p_reg : std_logic_vector(47 downto 0) := (others => '0');
  signal d_reg, ad_reg : std_logic_vector(24 downto 0) := (others => '0');
  signal in_reg : std_logic_vector(4 downto 0) := (others => '0');
  signal op_reg : std_logic_vector(6 downto 0) := (others => '0');
  signal alum_reg : std_logic_vector(3 downto 0) := (others => '0');
  signal csel_reg : std_logic_vector(2 downto 0) := (others => '0');
  signal mult_reg : std_logic_vector(42 downto 0) := (others => '0');
  signal cin0_reg, cin7_reg : std_ulogic := '0';
  signal cout_reg : std_logic_vector(3 downto 0) := (others => '0');
  signal cc_reg, msign_reg : std_ulogic := '0';
  signal pdet_r1, pdet_r2, pdetb_r1, pdetb_r2 : std_ulogic := '0';

  signal a_omux, qa_mux : std_logic_vector(29 downto 0);
  signal b_omux, qb_mux : std_logic_vector(17 downto 0);
  signal c_mux, p_fb, p_hold, alu : std_logic_vector(47 downto 0);
  signal d_mux, ad_mux, a_pre, ad_sum : std_logic_vector(24 downto 0);
  signal in_mux : std_logic_vector(4 downto 0);
  signal op_mux : std_logic_vector(6 downto 0);
  signal alum_mux : std_logic_vector(3 downto 0);
  signal csel_mux : std_logic_vector(2 downto 0);
  signal qmult, mult_w : std_logic_vector(42 downto 0);
  signal ad_mult : std_logic_vector(24 downto 0);
  signal b_mult : std_logic_vector(17 downto 0);
  signal cin_mux, cc_o, msign_o : std_ulogic;
  signal cout_o, cout_x : std_logic_vector(3 downto 0);
  signal the_mask : std_logic_vector(47 downto 0) := (others => '0');
  signal pdet, pdetb : std_ulogic;

  constant four12 : boolean := USE_SIMD = "FOUR12";
  constant two24 : boolean := USE_SIMD = "TWO24";
  constant mask_v : std_logic_vector(47 downto 0) := bits(MASK);
  constant pat_v : std_logic_vector(47 downto 0) := bits(PATTERN);
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  clk_in <= vxor(CLK, IS_CLK_INVERTED);
  alumode_in <= xv(ALUMODE, IS_ALUMODE_INVERTED);
  inmode_in <= xv(INMODE, IS_INMODE_INVERTED);
  opmode_in <= xv(OPMODE, IS_OPMODE_INVERTED);
  carryin_in <= vxor(CARRYIN, IS_CARRYIN_INVERTED);

  a_omux <= ACIN when A_INPUT = "CASCADE" else
            A when A_INPUT = "DIRECT" else
            (others => 'X');
  qa_mux <= a_omux when AREG = 0 else
            a2_reg when (AREG = 1 or AREG = 2) else
            (others => 'X');
  ACOUT <= a1_reg when (ACASCREG = 1 and AREG = 2) else
           qa_mux when (ACASCREG = 0 or ACASCREG = 2 or ACASCREG = 1) else
           (others => 'X');

  b_omux <= BCIN when B_INPUT = "CASCADE" else
            B when B_INPUT = "DIRECT" else
            (others => 'X');
  qb_mux <= b_omux when BREG = 0 else
            b2_reg when (BREG = 1 or BREG = 2) else
            (others => 'X');
  BCOUT <= b1_reg when (BCASCREG = 1 and BREG = 2) else
           qb_mux when (BCASCREG = 0 or BCASCREG = 2 or BCASCREG = 1) else
           (others => 'X');

  c_mux <= C when CREG = 0 else c_reg when CREG = 1 else (others => 'X');
  d_mux <= D when DREG = 0 else d_reg when DREG = 1 else (others => 'X');
  ad_mux <= ad_sum when ADREG = 0 else ad_reg when ADREG = 1 else (others => 'X');
  in_mux <= inmode_in when INMODEREG = 0 else in_reg when INMODEREG = 1 else (others => 'X');
  op_mux <= opmode_in when OPMODEREG = 0 else op_reg when OPMODEREG = 1 else (others => 'X');
  alum_mux <= alumode_in when ALUMODEREG = 0 else alum_reg when ALUMODEREG = 1 else (others => 'X');
  csel_mux <= CARRYINSEL when CARRYINSELREG = 0 else csel_reg when CARRYINSELREG = 1 else (others => 'X');

  pre_p : process (in_mux, a1_reg, qa_mux, b1_reg, qb_mux, d_mux, ad_reg, CARRYINSEL, csel_mux, mult_reg) is
    variable a25, d25, am : std_logic_vector(24 downto 0);
    variable b18 : std_logic_vector(17 downto 0);
    variable prod : signed(85 downto 0);
    variable mult_o : std_logic_vector(42 downto 0);
  begin
    if in_mux(1) = '1' then
      a25 := (others => '0');
    elsif in_mux(1) = '0' then
      if in_mux(0) = '1' then
        a25 := a1_reg(24 downto 0);
      elsif in_mux(0) = '0' then
        a25 := qa_mux(24 downto 0);
      else
        a25 := (others => 'X');
      end if;
    else
      a25 := (others => 'X');
    end if;
    a_pre <= a25;

    if in_mux(4) = '1' then
      b18 := b1_reg;
    elsif in_mux(4) = '0' then
      b18 := qb_mux;
    else
      b18 := (others => 'X');
    end if;

    if in_mux(2) = '1' then
      d25 := d_mux;
    elsif in_mux(2) = '0' then
      d25 := (others => '0');
    else
      d25 := (others => 'X');
    end if;
    ad_sum <= add25(in_mux(3), a25, d25);
    if USE_DPORT then
      if ADREG = 0 then
        am := add25(in_mux(3), a25, d25);
      elsif ADREG = 1 then
        am := ad_reg;
      else
        am := (others => 'X');
      end if;
    else
      am := a25;
    end if;
    ad_mult <= am;
    b_mult <= b18;

    if USE_MULT = "NONE" or USE_SIMD /= "ONE48" then
      mult_o := (others => '0');
    elsif CARRYINSEL = "010" then
      mult_o := (others => 'X');
    elsif not binary(am) or not binary(b18) then
      mult_o := (others => 'X');
    else
      prod := resize(signed(am), 43) * resize(signed(b18), 43);
      mult_o := std_logic_vector(prod(42 downto 0));
    end if;
    mult_w <= mult_o;
    if csel_mux = "010" then
      qmult <= (others => 'X');
    elsif MREG = 1 then
      qmult <= mult_reg;
    else
      qmult <= mult_o;
    end if;
  end process;

  alu_p : process (qa_mux, qb_mux, c_mux, p_fb, qmult, op_mux, alum_mux, csel_mux,
                   PCIN, CARRYCASCIN, cin0_reg, carryin_in, cin7_reg, ad_mult,
                   b_mult, cc_reg, cc_o, MULTSIGNIN, the_mask) is
    variable xmux, ymux, zmux, co, s, co0, s0, comux, smux : std_logic_vector(47 downto 0);
    variable sum0, sum1, sum2 : std_logic_vector(12 downto 0);
    variable sum3 : std_logic_vector(13 downto 0);
    variable alu_v : std_logic_vector(47 downto 0);
    variable cin_tmp, cin_v, c1, c2, c3 : std_ulogic;
    variable co11, co23, co35, cout0, cout1, cout2, cout3 : std_ulogic;
    variable hw, cx : std_logic_vector(3 downto 0);
    variable bitp : std_ulogic;
    variable pd, pdb : std_logic_vector(47 downto 0);
    variable pat : std_logic_vector(47 downto 0);
  begin
    xmux := (others => '0');
    if op_mux(1 downto 0) = "00" then
      xmux := (others => '0');
    elsif op_mux(1 downto 0) = "01" then
      xmux(47 downto 43) := (others => qmult(42));
      xmux(42 downto 0) := qmult;
    elsif op_mux(1 downto 0) = "10" then
      xmux := p_fb;
    elsif op_mux(1 downto 0) = "11" then
      if not (USE_MULT = "MULTIPLY" and (
            (AREG = 0 and BREG = 0 and MREG = 0) or
            (AREG = 0 and BREG = 0 and PREG = 0) or
            (MREG = 0 and PREG = 0))) then
        xmux := qa_mux & qb_mux;
      end if;
    end if;

    if op_mux(6 downto 4) = "100" then
      ymux := (others => MULTSIGNIN);
    else
      ymux := (others => '1');
    end if;
    if op_mux(3 downto 2) = "00" or op_mux(3 downto 2) = "01" then
      ymux := (others => '0');
    elsif op_mux(3 downto 2) = "11" then
      ymux := c_mux;
    elsif op_mux(3 downto 2) /= "10" then
      ymux := (others => 'X');
    end if;

    zmux := (others => '0');
    if casex_hit(std_logic_vector'("000"), op_mux(6 downto 4)) then
      zmux := (others => '0');
    elsif casex_hit(std_logic_vector'("001"), op_mux(6 downto 4)) then
      zmux := PCIN;
    elsif casex_hit(std_logic_vector'("010"), op_mux(6 downto 4)) then
      zmux := p_fb;
    elsif casex_hit(std_logic_vector'("011"), op_mux(6 downto 4)) then
      zmux := c_mux;
    elsif casex_hit(std_logic_vector'("100"), op_mux(6 downto 4)) then
      zmux := p_fb;
    elsif casex_hit(std_logic_vector'("101"), op_mux(6 downto 4)) then
      zmux(47 downto 31) := (others => PCIN(47));
      zmux(30 downto 0) := PCIN(47 downto 17);
    elsif casex_hit(std_logic_vector'("11X"), op_mux(6 downto 4)) then
      zmux(47 downto 31) := (others => p_fb(47));
      zmux(30 downto 0) := p_fb(47 downto 17);
    end if;

    co := (xmux and ymux) or (zmux and ymux) or (xmux and zmux);
    s := zmux xor xmux xor ymux;
    co0 := (xmux and ymux) or ((not zmux) and ymux) or (xmux and (not zmux));
    s0 := (not zmux) xor xmux xor ymux;
    comux := merge(alum_mux(0), co0, co);
    -- comux here is co/s with Z optionally inverted. alumode(2) then gates co.
    co := merge(alum_mux(0), co0, co);
    s := merge(alum_mux(0), s0, s);
    comux := merge(alum_mux(2), (47 downto 0 => '0'), co);
    smux := merge(alum_mux(3), co, s);

    cin_tmp := '0';
    if csel_mux = "000" then
      if CARRYINREG = 1 then
        cin_tmp := cin0_reg;
      else
        cin_tmp := carryin_in;
      end if;
    elsif csel_mux = "001" then
      cin_tmp := not PCIN(47);
    elsif csel_mux = "010" then
      cin_tmp := CARRYCASCIN;
    elsif csel_mux = "011" then
      cin_tmp := PCIN(47);
    elsif csel_mux = "100" then
      if PREG = 1 then
        cin_tmp := cc_reg;
      else
        cin_tmp := cc_o;
      end if;
    elsif csel_mux = "101" then
      cin_tmp := not p_fb(47);
    elsif csel_mux = "110" then
      if MREG = 1 then
        cin_tmp := cin7_reg;
      else
        cin_tmp := vxnor(ad_mult(24), b_mult(17));
      end if;
    elsif csel_mux = "111" then
      cin_tmp := p_fb(47);
    end if;
    if alum_mux(3) = '1' or alum_mux(2) = '1' then
      cin_v := '0';
    elsif alum_mux(3) = '0' and alum_mux(2) = '0' then
      cin_v := cin_tmp;
    else
      cin_v := 'X';
    end if;
    cin_mux <= cin_v;

    sum0 := addn(comux(10 downto 0) & cin_v, smux(11 downto 0), '0');
    cout0 := 'X';
    if (comux(11) = '0' or comux(11) = '1') and (sum0(12) = '0' or sum0(12) = '1') then
      cout0 := comux(11) xor sum0(12);
    end if;
    if (alum_mux(0) and alum_mux(1)) = '1' then
      hw(0) := not cout0;
    elsif (alum_mux(0) and alum_mux(1)) = '0' then
      hw(0) := cout0;
    else
      hw(0) := 'X';
    end if;
    if four12 then
      c1 := '0';
      co11 := '0';
    else
      c1 := sum0(12);
      co11 := comux(11);
    end if;

    sum1 := addn(comux(22 downto 12) & co11, smux(23 downto 12), c1);
    cout1 := 'X';
    if (comux(23) = '0' or comux(23) = '1') and (sum1(12) = '0' or sum1(12) = '1') then
      cout1 := comux(23) xor sum1(12);
    end if;
    if (alum_mux(0) and alum_mux(1)) = '1' then
      hw(1) := not cout1;
    elsif (alum_mux(0) and alum_mux(1)) = '0' then
      hw(1) := cout1;
    else
      hw(1) := 'X';
    end if;
    if two24 or four12 then
      c2 := '0';
      co23 := '0';
    else
      c2 := sum1(12);
      co23 := comux(23);
    end if;

    sum2 := addn(comux(34 downto 24) & co23, smux(35 downto 24), c2);
    cout2 := 'X';
    if (comux(35) = '0' or comux(35) = '1') and (sum2(12) = '0' or sum2(12) = '1') then
      cout2 := comux(35) xor sum2(12);
    end if;
    if (alum_mux(0) and alum_mux(1)) = '1' then
      hw(2) := not cout2;
    elsif (alum_mux(0) and alum_mux(1)) = '0' then
      hw(2) := cout2;
    else
      hw(2) := 'X';
    end if;
    if four12 then
      c3 := '0';
      co35 := '0';
    else
      c3 := sum2(12);
      co35 := comux(35);
    end if;

    sum3 := addn(comux(47 downto 36) & co35, '0' & smux(47 downto 36), c3);
    cout3 := sum3(12);
    if (alum_mux(0) and alum_mux(1)) = '1' then
      hw(3) := not cout3;
    elsif (alum_mux(0) and alum_mux(1)) = '0' then
      hw(3) := cout3;
    else
      hw(3) := 'X';
    end if;

    alu_v := sum3(11 downto 0) & sum2(11 downto 0) & sum1(11 downto 0) & sum0(11 downto 0);
    alu_v := merge(alum_mux(1), not alu_v, alu_v);
    alu <= alu_v;
    cc_o <= cout3;

    if op_mux(6 downto 4) = "100" then
      msign_o <= MULTSIGNIN;
    else
      msign_o <= qmult(42);
    end if;

    -- X when (OPMODE[3:0] == 0101) or (ALUMODE[3:2] != 00). An X
    -- operand makes Verilog == unknown, which also forces X here.
    if veq(op_mux(3 downto 0), "0101") = '0' and veq(alum_mux(3 downto 2), "00") = '1' then
      cx := hw;
    else
      cx := (others => 'X');
    end if;
    if not four12 then
      cx(2) := 'X';
      cx(0) := 'X';
    end if;
    if not (two24 or four12) then
      cx(1) := 'X';
    end if;
    cout_o <= cx;

    if SEL_PATTERN = "PATTERN" then
      pat := pat_v;
    else
      pat := c_mux;
    end if;
    for i in 47 downto 0 loop
      bitp := 'X';
      if (pat(i) = '0' or pat(i) = '1') and (alu_v(i) = '0' or alu_v(i) = '1') then
        bitp := pat(i) xor alu_v(i);
      end if;
      if the_mask(i) = '1' then
        pd(i) := '1';
        pdb(i) := '1';
      elsif the_mask(i) = '0' then
        pd(i) := not bitp;
        pdb(i) := bitp;
      else
        pd(i) := 'X';
        pdb(i) := 'X';
      end if;
    end loop;
    pdet <= and_red(pd);
    pdetb <= and_red(pdb);
  end process;

  mask_p : process (c_mux) is
    variable m : std_logic_vector(47 downto 0);
  begin
    if USE_PATTERN_DETECT = "NO_PATDET" then
      the_mask <= (others => '1');
    elsif SEL_MASK = "MASK" then
      the_mask <= mask_v;
    elsif SEL_MASK = "C" then
      the_mask <= c_mux;
    elsif SEL_MASK = "ROUNDING_MODE1" then
      m(0) := '0';
      for i in 1 to 47 loop
        m(i) := not c_mux(i - 1);
      end loop;
      the_mask <= m;
    elsif SEL_MASK = "ROUNDING_MODE2" then
      m(1 downto 0) := "00";
      for i in 2 to 47 loop
        m(i) := not c_mux(i - 2);
      end loop;
      the_mask <= m;
    end if;
  end process;

  reg : process (gsr, clk_in) is
    variable prev : std_ulogic := 'U';
    variable armed : boolean := false;
    variable auto : std_ulogic;
  begin
    if gsr = '1' then
      cin0_reg <= '0';
      csel_reg <= (others => '0');
      op_reg <= (others => '0');
      alum_reg <= (others => '0');
      a1_reg <= (others => '0');
      a2_reg <= (others => '0');
      b1_reg <= (others => '0');
      b2_reg <= (others => '0');
      c_reg <= (others => '0');
      p_reg <= (others => '0');
      mult_reg <= (others => '0');
      pdet_r1 <= '0';
      pdet_r2 <= '0';
      pdetb_r1 <= '0';
      pdetb_r2 <= '0';
      cc_reg <= '0';
      msign_reg <= '0';
      d_reg <= (others => '0');
      ad_reg <= (others => '0');
      in_reg <= (others => '0');
      cin7_reg <= '0';
    elsif armed and verilog_posedge(prev, clk_in) then
      if RSTINMODE = '1' then
        in_reg <= (others => '0');
      elsif CEINMODE = '1' then
        in_reg <= inmode_in;
      end if;

      if AREG = 1 or AREG = 2 then
        if RSTA = '1' then
          a1_reg <= (others => '0');
          a2_reg <= (others => '0');
        else
          if CEA1 = '1' then
            a1_reg <= a_omux;
          end if;
          if CEA2 = '1' then
            if AREG = 1 then
              a2_reg <= a_omux;
            else
              a2_reg <= a1_reg;
            end if;
          end if;
        end if;
      end if;

      if BREG = 1 or BREG = 2 then
        if RSTB = '1' then
          b1_reg <= (others => '0');
          b2_reg <= (others => '0');
        else
          if CEB1 = '1' then
            b1_reg <= b_omux;
          end if;
          if CEB2 = '1' then
            if BREG = 1 then
              b2_reg <= b_omux;
            else
              b2_reg <= b1_reg;
            end if;
          end if;
        end if;
      end if;

      if RSTC = '1' then
        c_reg <= (others => '0');
      elsif CEC = '1' then
        c_reg <= C;
      end if;
      if RSTD = '1' then
        d_reg <= (others => '0');
        ad_reg <= (others => '0');
      else
        if CED = '1' then
          d_reg <= D;
        end if;
        if CEAD = '1' then
          ad_reg <= ad_sum;
        end if;
      end if;
      if RSTCTRL = '1' then
        csel_reg <= (others => '0');
        op_reg <= (others => '0');
      elsif CECTRL = '1' then
        csel_reg <= CARRYINSEL;
        op_reg <= opmode_in;
      end if;
      if RSTALUMODE = '1' then
        alum_reg <= (others => '0');
      elsif CEALUMODE = '1' then
        alum_reg <= alumode_in;
      end if;
      if RSTM = '1' then
        mult_reg <= (others => '0');
      elsif CEM = '1' then
        mult_reg <= mult_w;
      end if;
      if RSTALLCARRYIN = '1' then
        cin0_reg <= '0';
        cin7_reg <= '0';
      else
        if CECARRYIN = '1' then
          cin0_reg <= carryin_in;
        end if;
        if CEM = '1' then
          cin7_reg <= vxnor(ad_mult(24), b_mult(17));
        end if;
      end if;

      auto := '0';
      if AUTORESET_PATDET = "RESET_MATCH" and pdet_r1 = '1' then
        auto := '1';
      elsif AUTORESET_PATDET = "RESET_NOT_MATCH" and pdet_r2 = '1' and pdet_r1 = '0' then
        auto := '1';
      end if;
      if RSTP = '1' or auto = '1' then
        cout_reg <= (others => '0');
        cc_reg <= '0';
        msign_reg <= '0';
        p_reg <= (others => '0');
        pdet_r1 <= '0';
        pdet_r2 <= '0';
        pdetb_r1 <= '0';
        pdetb_r2 <= '0';
      elsif CEP = '1' then
        cout_reg <= cout_o;
        cc_reg <= cc_o;
        msign_reg <= msign_o;
        p_reg <= alu;
        pdet_r2 <= pdet_r1;
        pdet_r1 <= pdet;
        pdetb_r2 <= pdetb_r1;
        pdetb_r1 <= pdetb;
      end if;
    end if;
    armed := true;
    prev := clk_in;
  end process;

  p_hold <= alu after 1 ps;
  p_fb <= p_hold when PREG = 0 else p_reg;
  P <= p_fb;
  PCOUT <= p_fb;
  CARRYCASCOUT <= cc_reg when PREG = 1 else cc_o;
  MULTSIGNOUT <= msign_reg when PREG = 1 else msign_o;
  cout_x <= cout_reg when PREG = 1 else cout_o;
  CARRYOUT(3) <= cout_x(3);
  CARRYOUT(2) <= cout_x(2) when four12 else 'X';
  CARRYOUT(1) <= cout_x(1) when (two24 or four12) else 'X';
  CARRYOUT(0) <= cout_x(0) when four12 else 'X';
  PATTERNDETECT <= pdet_r1 when PREG = 1 else pdet;
  PATTERNBDETECT <= pdetb_r1 when PREG = 1 else pdetb;
  OVERFLOW <= 'X' when not (USE_PATTERN_DETECT = "PATDET" or PREG = 1) else
              pdet_r2 and (not pdet_r1) and (not pdetb_r1);
  UNDERFLOW <= 'X' when not (USE_PATTERN_DETECT = "PATDET" or PREG = 1) else
               pdetb_r2 and (not pdet_r1) and (not pdetb_r1);
end architecture sim;
