-- BUFG_GT. GT clock buffer with enable, clear, masks, and a divider port.
-- CE is rv 1. CLR, CLRMASK, CEMASK, and each DIV bit are rv 0. I is not
-- buffered, so Z stays Z. DIV 000 copies the enabled clock; 001..111 match
-- BUFGCE_DIV's divides 2..8. On a non-versal device CE and the inverted
-- CLR are synchronised for two rising edges and O is delayed 1 ps.
-- VERSAL* uses CE and not CLR directly and does not delay O. STARTUP_SYNC
-- is forced off unless SIM_DEVICE is VERSAL*. An illegal device does not
-- $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFG_GT is
  generic (
    SIM_DEVICE : string := "ULTRASCALE";
    STARTUP_SYNC : boolean := FALSE
  );
  port (
    O : out std_ulogic;
    CE : in std_ulogic;
    CEMASK : in std_ulogic;
    CLR : in std_ulogic;
    CLRMASK : in std_ulogic;
    DIV : in std_logic_vector(2 downto 0);
    I : in std_ulogic
  );
end entity BUFG_GT;

architecture sim of BUFG_GT is
  constant versal : boolean := sim_versal(SIM_DEVICE);
  constant startup : boolean := STARTUP_SYNC and versal;

  signal gsr : std_ulogic := '1';
  signal ce_in, cem_in, clr_in, clrm_in, i_in : std_ulogic;
  signal div_in : std_logic_vector(2 downto 0);
  signal gwe_sync : std_ulogic_vector(2 downto 0) := "000";
  signal gsr_m, ce_sync_b, clr_inv, clr_sync_b : std_ulogic;
  signal ce_s, clr_s : std_ulogic_vector(1 downto 0) := "00";
  signal ce_masked, clr_masked, i_inv, ce_en, i_ce : std_ulogic;
  signal first_n : integer := 1;
  signal second_n : integer := 1;
  signal o_raw, o_dly : std_ulogic := '0';
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  ce_in <= rv1(CE);
  cem_in <= rv0(CEMASK);
  clr_in <= rv0(CLR);
  clrm_in <= rv0(CLRMASK);
  div_in <= rv0(DIV(2)) & rv0(DIV(1)) & rv0(DIV(0));
  i_in <= I;

  gsr_m <= not gwe_sync(2) when startup else gsr;
  ce_sync_b <= ce_in when versal else ce_s(1);
  clr_inv <= not clr_in;
  clr_sync_b <= clr_inv when versal else clr_s(1);

  ce_masked <= ce_sync_b or cem_in;
  clr_masked <= (not clr_sync_b) and (not clrm_in);
  i_inv <= not i_in;
  i_ce <= i_in and ce_en;

  counts : process (div_in)
  begin
    case div_in is
      when "000" => first_n <= 1; second_n <= 1;
      when "001" => first_n <= 2; second_n <= 2;
      when "010" => first_n <= 2; second_n <= 4;
      when "011" => first_n <= 4; second_n <= 4;
      when "100" => first_n <= 4; second_n <= 6;
      when "101" => first_n <= 6; second_n <= 6;
      when "110" => first_n <= 6; second_n <= 8;
      when "111" => first_n <= 8; second_n <= 8;
      when others => null;
    end case;
  end process;

  gwe_p : process (i_in)
    variable prev : std_ulogic := 'U';
  begin
    if verilog_posedge(prev, i_in) and i_in = '1' then
      gwe_sync <= gwe_sync(1 downto 0) & (not gsr);
    end if;
    prev := i_in;
  end process;

  ce_p : process (i_in, gsr_m)
    variable pi, pg : std_ulogic := 'U';
    variable armed : boolean := false;
  begin
    if armed then
      if verilog_posedge(pi, i_in) or verilog_posedge(pg, gsr_m) then
        if gsr_m = '1' then
          ce_s <= "00";
        else
          ce_s <= ce_s(0) & ce_in;
        end if;
      end if;
    end if;
    armed := true;
    pi := i_in;
    pg := gsr_m;
  end process;

  clr_p : process (i_in, clr_inv)
    variable pi, pc : std_ulogic := 'U';
    variable armed : boolean := false;
  begin
    if armed then
      if verilog_posedge(pi, i_in) or verilog_negedge(pc, clr_inv) then
        if (not clr_inv) = '1' then
          clr_s <= "00";
        else
          clr_s <= clr_s(0) & '1';
        end if;
      end if;
    end if;
    armed := true;
    pi := i_in;
    pc := clr_inv;
  end process;

  en : process (i_inv, gsr_m, ce_masked, clr_masked)
  begin
    if (gsr_m or clr_masked) = '1' then
      ce_en <= '0';
    elsif i_inv = '1' then
      ce_en <= ce_masked;
    end if;
  end process;

  div_p : process (i_ce, gsr_m, clr_masked)
    variable st : bufg_div_t := ('0', 1, '0', '0');
    variable pi, pg, pc : std_ulogic := 'U';
    variable armed : boolean := false;
    variable step : boolean;
  begin
    step := false;
    if armed then
      if pi /= i_ce or verilog_posedge(pg, gsr_m) or verilog_posedge(pc, clr_masked) then
        step := true;
      end if;
    end if;
    armed := true;
    if gsr_m = '1' then
      st := bufg_div_held;
    elsif step then
      st := bufg_div_step(st, i_ce, clr_masked, first_n, second_n);
    end if;
    pi := i_ce;
    pg := gsr_m;
    pc := clr_masked;
    o_raw <= st.o;
  end process;

  o_dly <= o_raw after 1 ps;
  O <= o_raw when versal else o_dly;
end architecture sim;
