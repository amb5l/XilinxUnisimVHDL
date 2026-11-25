-- BUFGCTRL. Two-clock mux with enables, selects, and ignore pins.
-- CE*, S*, and IGNORE* are rv 0 of (pin xor IS_*_INVERTED): Z is 0 and is
-- not inverted. I* is xor'd with IS_I*_INVERTED. Latches qb* update 1 ps
-- after their clock term is 1. CE* into the HARDSYNC shifter is delayed
-- 1 ps. HARDSYNC and STARTUP_SYNC are forced off unless SIM_DEVICE is
-- VERSAL*. Both PRESELECT generics TRUE is illegal in the Verilog and
-- would $finish; I0 wins gwe_sync and both latch pairs take their preset.
-- An illegal attribute does not abort.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFGCTRL is
  generic (
    CE_TYPE_CE0 : string := "SYNC";
    CE_TYPE_CE1 : string := "SYNC";
    INIT_OUT : integer := 0;
    IS_CE0_INVERTED : bit := '0';
    IS_CE1_INVERTED : bit := '0';
    IS_I0_INVERTED : bit := '0';
    IS_I1_INVERTED : bit := '0';
    IS_IGNORE0_INVERTED : bit := '0';
    IS_IGNORE1_INVERTED : bit := '0';
    IS_S0_INVERTED : bit := '0';
    IS_S1_INVERTED : bit := '0';
    PRESELECT_I0 : boolean := FALSE;
    PRESELECT_I1 : boolean := FALSE;
    SIM_DEVICE : string := "ULTRASCALE";
    STARTUP_SYNC : boolean := FALSE
  );
  port (
    O : out std_ulogic;
    CE0 : in std_ulogic;
    CE1 : in std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic;
    IGNORE0 : in std_ulogic;
    IGNORE1 : in std_ulogic;
    S0 : in std_ulogic;
    S1 : in std_ulogic
  );
end entity BUFGCTRL;

architecture sim of BUFGCTRL is
  function pre_bit(p : boolean) return std_ulogic is
  begin
    if p then
      return '1';
    end if;
    return '0';
  end function;

  function lsb(n : integer) return std_ulogic is
  begin
    if (n mod 2) /= 0 then
      return '1';
    end if;
    return '0';
  end function;

  constant versal : boolean := sim_versal(SIM_DEVICE);
  constant hs0 : boolean := versal and CE_TYPE_CE0 = "HARDSYNC";
  constant hs1 : boolean := versal and CE_TYPE_CE1 = "HARDSYNC";
  constant startup : boolean := versal and STARTUP_SYNC;
  constant init_b : std_ulogic := lsb(INIT_OUT);
  constant pre0 : std_ulogic := pre_bit(PRESELECT_I0);
  constant pre1 : std_ulogic := pre_bit(PRESELECT_I1);

  signal gsr : std_ulogic := '1';
  signal gr : std_ulogic := '0';
  signal ce0_in, ce1_in, i0_in, i1_in : std_ulogic;
  signal ign0, ign1, s0_in, s1_in : std_ulogic;
  signal i0_opt, i1_opt, gwe, gwe_bit, gwe_muxed : std_ulogic;
  signal gwe0_sync, gwe1_sync : std_ulogic_vector(2 downto 0) := "000";
  signal ce0_dly, ce1_dly : std_ulogic := 'X';
  signal ce0_sync, ce1_sync : std_ulogic_vector(2 downto 0) := "000";
  signal ce0_m, ce1_m : std_ulogic;
  signal d00, d01, d10, d11 : std_ulogic;
  signal cb00, cb01, cb10, cb11 : std_ulogic;
  signal qb00, qb01 : std_ulogic := pre0;
  signal qb10, qb11 : std_ulogic := pre1;
  signal state0, state1 : std_ulogic;
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  gr_p : process
  begin
    grestore(gr);
  end process;

  ce0_in <= gate_in(CE0, IS_CE0_INVERTED);
  ce1_in <= gate_in(CE1, IS_CE1_INVERTED);
  i0_in <= vxor(I0, IS_I0_INVERTED);
  i1_in <= vxor(I1, IS_I1_INVERTED);
  ign0 <= gate_in(IGNORE0, IS_IGNORE0_INVERTED);
  ign1 <= gate_in(IGNORE1, IS_IGNORE1_INVERTED);
  s0_in <= gate_in(S0, IS_S0_INVERTED);
  s1_in <= gate_in(S1, IS_S1_INVERTED);

  i0_opt <= init_b xor i0_in;
  i1_opt <= init_b xor i1_in;
  gwe <= not gsr;

  gwe_bit <= gwe0_sync(2) when PRESELECT_I0 else
             gwe1_sync(2) when PRESELECT_I1 else
             (gwe0_sync(2) or gwe1_sync(2));
  gwe_muxed <= gwe_bit when startup else gwe;

  ce0_dly <= ce0_in after 1 ps;
  ce1_dly <= ce1_in after 1 ps;
  ce0_m <= ce0_sync(2) when hs0 else ce0_in;
  ce1_m <= ce1_sync(2) when hs1 else ce1_in;

  d00 <= not (state1 and s0_in);
  d01 <= not (qb00 and ce0_m);
  d10 <= not (state0 and s1_in);
  d11 <= not (qb10 and ce1_m);

  cb00 <= not ((not gwe_muxed) or ((not ign0) and (not i0_opt)));
  cb01 <= not ((not gwe_muxed) or ((not ign0) and i0_opt));
  cb10 <= not ((not gwe_muxed) or ((not ign1) and (not i1_opt)));
  cb11 <= not ((not gwe_muxed) or ((not ign1) and i1_opt));

  state0 <= not (qb01 or (not gwe_muxed));
  state1 <= not (qb11 or (not gwe_muxed));

  gwe0_p : process (i0_opt, gr)
    variable pi, pg : std_ulogic := 'U';
    variable armed : boolean := false;
  begin
    if armed then
      if verilog_negedge(pi, i0_opt) or verilog_posedge(pg, gr) then
        if gr = '1' then
          gwe0_sync <= "000";
        else
          gwe0_sync <= gwe0_sync(1 downto 0) & gwe;
        end if;
      end if;
    end if;
    armed := true;
    pi := i0_opt;
    pg := gr;
  end process;

  gwe1_p : process (i1_opt, gr)
    variable pi, pg : std_ulogic := 'U';
    variable armed : boolean := false;
  begin
    if armed then
      if verilog_negedge(pi, i1_opt) or verilog_posedge(pg, gr) then
        if gr = '1' then
          gwe1_sync <= "000";
        else
          gwe1_sync <= gwe1_sync(1 downto 0) & gwe;
        end if;
      end if;
    end if;
    armed := true;
    pi := i1_opt;
    pg := gr;
  end process;

  ce0_p : process (i0_opt, gr)
    variable pi, pg : std_ulogic := 'U';
    variable armed : boolean := false;
  begin
    if armed then
      if verilog_posedge(pi, i0_opt) or verilog_posedge(pg, gr) then
        if gr = '1' then
          ce0_sync <= "000";
        else
          ce0_sync <= ce0_sync(1 downto 0) & ce0_dly;
        end if;
      end if;
    end if;
    armed := true;
    pi := i0_opt;
    pg := gr;
  end process;

  ce1_p : process (i1_opt, gr)
    variable pi, pg : std_ulogic := 'U';
    variable armed : boolean := false;
  begin
    if armed then
      if verilog_posedge(pi, i1_opt) or verilog_posedge(pg, gr) then
        if gr = '1' then
          ce1_sync <= "000";
        else
          ce1_sync <= ce1_sync(1 downto 0) & ce1_dly;
        end if;
      end if;
    end if;
    armed := true;
    pi := i1_opt;
    pg := gr;
  end process;

  qb00_p : process (gr, cb00, d00)
  begin
    if gr = '1' and pre0 = '0' then
      qb00 <= '0';
    elsif gr = '1' and pre0 = '1' then
      qb00 <= '1';
    elsif cb00 = '1' then
      qb00 <= not d00 after 1 ps;
    end if;
  end process;

  qb01_p : process (gr, cb01, d01)
  begin
    if gr = '1' and pre0 = '0' then
      qb01 <= '0';
    elsif gr = '1' and pre0 = '1' then
      qb01 <= '1';
    elsif cb01 = '1' then
      qb01 <= not d01 after 1 ps;
    end if;
  end process;

  qb10_p : process (gr, cb10, d10)
  begin
    if gr = '1' and pre1 = '0' then
      qb10 <= '0';
    elsif gr = '1' and pre1 = '1' then
      qb10 <= '1';
    elsif cb10 = '1' then
      qb10 <= not d10 after 1 ps;
    end if;
  end process;

  qb11_p : process (gr, cb11, d11)
  begin
    if gr = '1' and pre1 = '0' then
      qb11 <= '0';
    elsif gr = '1' and pre1 = '1' then
      qb11 <= '1';
    elsif cb11 = '1' then
      qb11 <= not d11 after 1 ps;
    end if;
  end process;

  out_p : process (state1, state0, i0_in, i1_in)
  begin
    if state1 = '0' and state0 = '0' then
      O <= '0';
    elsif state1 = '0' and state0 = '1' then
      O <= i1_in;
    elsif state1 = '1' and state0 = '0' then
      O <= i0_in;
    elsif state1 = '1' and state0 = '1' then
      O <= init_b;
    else
      O <= 'X';
    end if;
  end process;
end architecture sim;
