-- BUFGCE_DIV. Global buffer with enable, clear, and an integer divider.
-- CE is rv 1 xor IS_CE_INVERTED. CLR is rv 0 xor IS_CLR_INVERTED; X on
-- that result is forced to 1. Divide 1 copies I and the enable. Divides
-- 2..8 use the BUFGCE_DIV edge counter. While GSR is 1 the counter is
-- held at O=0, count=0, first_rise=1, first_half=0. HARDSYNC, HARDSYNC_CLR,
-- and STARTUP_SYNC are forced off unless SIM_DEVICE is VERSAL*. An illegal
-- divide or attribute does not $finish; the divide falls back to 1 and a
-- non-versal device keeps the synchronous pins.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFGCE_DIV is
  generic (
    BUFGCE_DIVIDE : integer := 1;
    CE_TYPE : string := "SYNC";
    HARDSYNC_CLR : boolean := FALSE;
    IS_CE_INVERTED : bit := '0';
    IS_CLR_INVERTED : bit := '0';
    IS_I_INVERTED : bit := '0';
    SIM_DEVICE : string := "ULTRASCALE";
    STARTUP_SYNC : boolean := FALSE
  );
  port (
    O : out std_ulogic;
    CE : in std_ulogic;
    CLR : in std_ulogic;
    I : in std_ulogic
  );
end entity BUFGCE_DIV;

architecture sim of BUFGCE_DIV is
  function toggles(div : integer) return integer is
  begin
    case div is
      when 2 => return 2;
      when 3 => return 2;
      when 4 => return 4;
      when 5 => return 4;
      when 6 => return 6;
      when 7 => return 6;
      when 8 => return 8;
      when others => return 1;
    end case;
  end function;

  function toggles2(div : integer) return integer is
  begin
    case div is
      when 2 => return 2;
      when 3 => return 4;
      when 4 => return 4;
      when 5 => return 6;
      when 6 => return 6;
      when 7 => return 8;
      when 8 => return 8;
      when others => return 1;
    end case;
  end function;

  constant versal : boolean := sim_versal(SIM_DEVICE);
  constant startup : boolean := STARTUP_SYNC and versal;
  constant hardsync : boolean := CE_TYPE = "HARDSYNC" and versal;
  constant hclr : boolean := HARDSYNC_CLR and versal;
  constant first_n : integer := toggles(BUFGCE_DIVIDE);
  constant second_n : integer := toggles2(BUFGCE_DIVIDE);

  signal gsr : std_ulogic := '1';
  signal ce_in, clr_in, i_in : std_ulogic;
  signal gwe_sync, ce_sync : std_ulogic_vector(2 downto 0) := "000";
  signal clr_sync : std_ulogic_vector(2 downto 0) := "111";
  signal gsr_m, ce_m, clr_m, clr_x, ce_en, i_ce : std_ulogic;
  signal o_raw : std_ulogic := '0';
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  ce_in <= rv1x(CE, IS_CE_INVERTED);
  clr_in <= gate_in(CLR, IS_CLR_INVERTED);
  i_in <= vxor(I, IS_I_INVERTED);

  gsr_m <= not gwe_sync(2) when startup else gsr;
  ce_m <= ce_sync(2) when hardsync else ce_in;
  clr_m <= clr_sync(2) when hclr else clr_in;
  clr_x <= '1' when clr_m = 'X' else clr_m;

  i_ce <= i_in and ce_en;

  rise : process (i_in)
    variable prev : std_ulogic := 'U';
  begin
    if verilog_posedge(prev, i_in) and i_in = '1' then
      gwe_sync <= gwe_sync(1 downto 0) & (not gsr);
      ce_sync <= ce_sync(1 downto 0) & ce_in;
    end if;
    prev := i_in;
  end process;

  fall : process (i_in)
    variable prev : std_ulogic := 'U';
  begin
    if verilog_negedge(prev, i_in) and i_in = '0' then
      clr_sync <= clr_sync(1 downto 0) & clr_in;
    end if;
    prev := i_in;
  end process;

  en : process (i_in, gsr_m, ce_m, clr_x)
  begin
    if (gsr_m or clr_x) = '1' then
      ce_en <= '0';
    elsif (not i_in) = '1' then
      ce_en <= ce_m;
    end if;
  end process;

  div : process (i_ce, gsr_m, clr_x)
    variable st : bufg_div_t := ('0', 1, 'X', 'X');
    variable pi, pg, pc : std_ulogic := 'U';
    variable armed : boolean := false;
    variable step : boolean;
  begin
    step := false;
    if armed then
      if pi /= i_ce or verilog_posedge(pg, gsr_m) or verilog_posedge(pc, clr_x) then
        step := true;
      end if;
    end if;
    armed := true;
    if gsr_m = '1' then
      st := bufg_div_held;
    elsif step then
      st := bufg_div_step(st, i_ce, clr_x, first_n, second_n);
    end if;
    pi := i_ce;
    pg := gsr_m;
    pc := clr_x;
    o_raw <= st.o;
  end process;

  O <= o_raw;
end architecture sim;
