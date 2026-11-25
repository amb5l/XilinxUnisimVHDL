-- DSP_OUTPUT. PREG 1 registers P, CARRYOUT, XOROUT and the pattern
-- flags. P_FDBK is always the register, so it stays 0 when PREG is 0.
-- CCOUT_FB is always the registered ALUMODE10 xor COUT(3). An unknown
-- string attribute falls back to NO_RESET, RESET, MASK, PATTERN or
-- NO_PATDET. The opmode-valid flag is stuck at 1, matching the Verilog.
-- No $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity DSP_OUTPUT is
  generic (
    AUTORESET_PATDET : string := "NO_RESET";
    AUTORESET_PRIORITY : string := "RESET";
    IS_CLK_INVERTED : bit := '0';
    IS_RSTP_INVERTED : bit := '0';
    MASK : bit_vector(47 downto 0) := X"3FFFFFFFFFFF";
    PATTERN : bit_vector(47 downto 0) := X"000000000000";
    PREG : integer := 1;
    SEL_MASK : string := "MASK";
    SEL_PATTERN : string := "PATTERN";
    USE_PATTERN_DETECT : string := "NO_PATDET"
  );
  port (
    CARRYCASCOUT : out std_ulogic;
    CARRYOUT : out std_logic_vector(3 downto 0);
    CCOUT_FB : out std_ulogic;
    MULTSIGNOUT : out std_ulogic;
    OVERFLOW : out std_ulogic;
    P : out std_logic_vector(47 downto 0);
    PATTERN_B_DETECT : out std_ulogic;
    PATTERN_DETECT : out std_ulogic;
    PCOUT : out std_logic_vector(47 downto 0);
    P_FDBK : out std_logic_vector(47 downto 0);
    P_FDBK_47 : out std_ulogic;
    UNDERFLOW : out std_ulogic;
    XOROUT : out std_logic_vector(7 downto 0);
    ALUMODE10 : in std_ulogic;
    ALU_OUT : in std_logic_vector(47 downto 0);
    CEP : in std_ulogic;
    CLK : in std_ulogic;
    COUT : in std_logic_vector(3 downto 0);
    C_DATA : in std_logic_vector(47 downto 0);
    MULTSIGN_ALU : in std_ulogic;
    RSTP : in std_ulogic;
    XOR_MX : in std_logic_vector(7 downto 0)
  );
end entity DSP_OUTPUT;

architecture sim of DSP_OUTPUT is
  function bits(b : bit_vector) return std_logic_vector is
    variable r : std_logic_vector(b'range);
  begin
    for i in b'range loop
      r(i) := to_sul(b(i));
    end loop;
    return r;
  end function;

  function and_reduce(s : std_logic_vector) return std_ulogic is
    variable saw_x : boolean := false;
  begin
    for i in s'range loop
      if s(i) = '0' then
        return '0';
      elsif s(i) /= '1' then
        saw_x := true;
      end if;
    end loop;
    if saw_x then
      return 'X';
    end if;
    return '1';
  end function;

  signal gsr : std_ulogic := '1';
  signal clk_in : std_ulogic;
  signal cout_reg : std_logic_vector(3 downto 0) := (others => '0');
  signal alumode_reg : std_ulogic := '0';
  signal mult_reg : std_ulogic := '0';
  signal alu_reg : std_logic_vector(47 downto 0) := (others => '0');
  signal xor_reg : std_logic_vector(7 downto 0) := (others => '0');
  signal pdet_r1, pdet_r2, pdetb_r1, pdetb_r2 : std_ulogic := '0';
  signal the_pattern, the_mask : std_logic_vector(47 downto 0);
  signal pdet_o, pdetb_o, pdet_mux, pdetb_mux : std_ulogic;
  signal overflow_data, underflow_data, auto_reset : std_ulogic;
  signal carryout_s : std_logic_vector(3 downto 0);
  signal alumode_mux : std_ulogic;
  constant patdet : boolean := USE_PATTERN_DETECT = "PATDET";
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  clk_in <= gate_in(CLK, IS_CLK_INVERTED);

  the_pattern <= C_DATA when SEL_PATTERN = "C" else bits(PATTERN);

  mask_p : process (C_DATA)
    variable m : std_logic_vector(47 downto 0);
  begin
    if not patdet then
      m := (others => '1');
    elsif SEL_MASK = "C" then
      m := C_DATA;
    elsif SEL_MASK = "ROUNDING_MODE1" then
      m := (not C_DATA(46 downto 0)) & '0';
    elsif SEL_MASK = "ROUNDING_MODE2" then
      m := (not C_DATA(45 downto 0)) & "00";
    else
      m := bits(MASK);
    end if;
    the_mask <= m;
  end process;

  pdet_o <= and_reduce((not (the_pattern xor ALU_OUT)) or the_mask);
  pdetb_o <= and_reduce((the_pattern xor ALU_OUT) or the_mask);
  pdet_mux <= pdet_r1 when PREG = 1 else pdet_o;
  pdetb_mux <= pdetb_r1 when PREG = 1 else pdetb_o;
  overflow_data <= pdet_r2 when PREG = 1 else pdet_o;
  underflow_data <= pdetb_r2 when PREG = 1 else pdetb_o;

  auto_p : process (pdet_mux, overflow_data, CEP)
    variable pri : std_ulogic;
  begin
    if AUTORESET_PRIORITY = "CEP" then
      pri := rv0(CEP);
    else
      pri := '1';
    end if;
    if AUTORESET_PATDET = "RESET_MATCH" then
      auto_reset <= pri and pdet_mux;
    elsif AUTORESET_PATDET = "RESET_NOT_MATCH" then
      auto_reset <= pri and overflow_data and (not pdet_mux);
    else
      auto_reset <= '0';
    end if;
  end process;

  reg : process (gsr, clk_in)
    variable prev : std_ulogic := 'U';
    variable armed : boolean := false;
  begin
    if gsr = '1' then
      cout_reg <= (others => '0');
      alumode_reg <= '0';
      mult_reg <= '0';
      alu_reg <= (others => '0');
      xor_reg <= (others => '0');
      pdet_r1 <= '0';
      pdet_r2 <= '0';
      pdetb_r1 <= '0';
      pdetb_r2 <= '0';
    elsif armed and verilog_posedge(prev, clk_in) then
      if gate_in(RSTP, IS_RSTP_INVERTED) = '1' or auto_reset = '1' then
        cout_reg <= (others => '0');
        alumode_reg <= '0';
        mult_reg <= '0';
        alu_reg <= (others => '0');
        xor_reg <= (others => '0');
        pdet_r1 <= '0';
        pdet_r2 <= '0';
        pdetb_r1 <= '0';
        pdetb_r2 <= '0';
      elsif rv0(CEP) = '1' and PREG = 1 then
        pdet_r2 <= pdet_r1;
        pdetb_r2 <= pdetb_r1;
        pdet_r1 <= pdet_o;
        pdetb_r1 <= pdetb_o;
        cout_reg <= COUT;
        alumode_reg <= ALUMODE10;
        mult_reg <= MULTSIGN_ALU;
        alu_reg <= ALU_OUT;
        xor_reg <= XOR_MX;
      end if;
    end if;
    armed := true;
    prev := clk_in;
  end process;

  alumode_mux <= alumode_reg when PREG = 1 else ALUMODE10;
  carryout_s <= cout_reg when PREG = 1 else COUT;
  CARRYOUT <= carryout_s;
  MULTSIGNOUT <= mult_reg when PREG = 1 else MULTSIGN_ALU;
  P <= alu_reg when PREG = 1 else ALU_OUT;
  PCOUT <= alu_reg when PREG = 1 else ALU_OUT;
  XOROUT <= xor_reg when PREG = 1 else XOR_MX;
  CCOUT_FB <= alumode_reg xor cout_reg(3);
  CARRYCASCOUT <= alumode_mux xor carryout_s(3);
  P_FDBK <= alu_reg;
  P_FDBK_47 <= alu_reg(47);
  PATTERN_DETECT <= pdet_mux;
  PATTERN_B_DETECT <= pdetb_mux;
  OVERFLOW <= (not pdet_mux) and (not pdetb_mux) and overflow_data when patdet else 'X';
  UNDERFLOW <= (not pdet_mux) and (not pdetb_mux) and underflow_data when patdet else 'X';
end architecture sim;
