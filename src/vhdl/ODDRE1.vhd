-- ODDRE1. Rising edge of C drives Q from D1 and remembers D2. The
-- falling edge drives Q from that remembered D2. SR uses rv 0.
-- ULTRASCALE, ULTRASCALE_PLUS, and the two PLUS ES devices also hold
-- the reset for three rising edges after SR falls. Every other legal
-- SIM_DEVICE, and an unknown name (the Verilog BIN fallback), treats
-- SR as a level. GSR and an active reset force SRVAL. No clock enable.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity ODDRE1 is
  generic (
    IS_C_INVERTED : bit := '0';
    IS_D1_INVERTED : bit := '0';
    IS_D2_INVERTED : bit := '0';
    SIM_DEVICE : string := "ULTRASCALE";
    SRVAL : bit := '0'
  );
  port (
    Q : out std_ulogic;
    C : in std_ulogic;
    D1 : in std_ulogic;
    D2 : in std_ulogic;
    SR : in std_ulogic
  );
end entity ODDRE1;

architecture sim of ODDRE1 is
  signal gsr : std_ulogic := '1';
  signal c_in : std_ulogic;
  signal sr_in : std_ulogic;

  function sync_sr(s : string) return boolean is
  begin
    return s = "ULTRASCALE" or s = "ULTRASCALE_PLUS"
        or s = "ULTRASCALE_PLUS_ES1" or s = "ULTRASCALE_PLUS_ES2";
  end function;
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  c_in <= vxor(C, IS_C_INVERTED);
  sr_in <= rv0(SR);

  ddr : process (gsr, c_in, sr_in)
    variable armed : boolean := false;
    variable prev : std_ulogic := 'U';
    variable forced : boolean := true;
    variable q_val : std_ulogic := 'X';
    variable qd2 : std_ulogic := 'X';
    variable rs1, rs2, rs3 : std_ulogic := '0';
    variable r_sync : std_ulogic;
    variable rise, fall : boolean;
    constant sr_val : std_ulogic := to_sul(SRVAL);
    constant synced : boolean := sync_sr(SIM_DEVICE);
  begin
    if synced then
      r_sync := rs1 or rs2 or rs3;
    else
      r_sync := sr_in;
    end if;

    if gsr = '1' then
      forced := true;
      q_val := sr_val;
      qd2 := sr_val;
    elsif gsr = '0' then
      if sr_in = '1' or r_sync = '1' then
        forced := true;
        q_val := sr_val;
        qd2 := sr_val;
      elsif r_sync = '0' then
        forced := false;
      end if;
    end if;

    rise := false;
    fall := false;
    if armed then
      rise := verilog_posedge(prev, c_in);
      fall := verilog_negedge(prev, c_in);
    end if;
    armed := true;
    prev := c_in;

    if rise and not forced then
      if sr_in = '1' or r_sync = '1' then
        q_val := sr_val;
        qd2 := sr_val;
      elsif r_sync = '0' then
        q_val := vxor(D1, IS_D1_INVERTED);
        qd2 := vxor(D2, IS_D2_INVERTED);
      end if;
    end if;

    if fall and not forced then
      if sr_in = '1' or r_sync = '1' then
        q_val := sr_val;
      elsif r_sync = '0' then
        q_val := qd2;
      end if;
    end if;

    if rise and synced then
      rs3 := rs2;
      rs2 := rs1;
      rs1 := sr_in;
    end if;

    Q <= q_val;
  end process;
end architecture sim;
