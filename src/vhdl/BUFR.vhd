-- BUFR. Regional clock buffer with an optional divider.
-- I, CE, CLR, and O pass through buf (Z maps to X). BUFR_DIVIDE BYPASS
-- forwards I and ignores CE and CLR. "1".."8" count edges of I while CE
-- is 1. 7SERIES, VIRTEX5, and VIRTEX6 (and any other SIM_DEVICE, which
-- would $finish in the Verilog) use the i_ce counter. VIRTEX4 waits four
-- falling edges before CE enables the counter and resets the count when
-- CE is not 1. GSR or CLR forces the divider to 0; GSR also clears the
-- VIRTEX4 CE pipeline. An illegal BUFR_DIVIDE does not $finish; it is BYPASS.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity BUFR is
  generic (
    BUFR_DIVIDE : string := "BYPASS";
    SIM_DEVICE : string := "7SERIES"
  );
  port (
    O : out std_ulogic;
    CE : in std_ulogic;
    CLR : in std_ulogic;
    I : in std_ulogic
  );
end entity BUFR;

architecture sim of BUFR is
  function half_of(s : string) return integer is
  begin
    if s = "1" then
      return 1;
    elsif s = "2" or s = "3" then
      return 2;
    elsif s = "4" or s = "5" then
      return 4;
    elsif s = "6" or s = "7" then
      return 6;
    elsif s = "8" then
      return 8;
    end if;
    return 0;
  end function;

  function per_of(s : string) return integer is
  begin
    if s = "1" then
      return 1;
    elsif s = "2" then
      return 2;
    elsif s = "3" or s = "4" then
      return 4;
    elsif s = "5" or s = "6" then
      return 6;
    elsif s = "7" or s = "8" then
      return 8;
    end if;
    return 0;
  end function;

  constant v4 : boolean := SIM_DEVICE = "VIRTEX4";
  constant half_n : integer := half_of(BUFR_DIVIDE);
  constant per_n : integer := per_of(BUFR_DIVIDE);

  signal gsr : std_ulogic := '1';
  signal i_in, ce_in, clr_in, ce_en, i_ce, o_div, o_out : std_ulogic;
  signal ce4_s : std_ulogic := 'X';
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  i_in <= buf1(I);
  ce_in <= buf1(CE);
  clr_in <= buf1(CLR);
  ce_en <= ce4_s when v4 else ce_in;
  i_ce <= i_in and ce_en;
  o_out <= i_in when per_n = 0 else o_div;
  O <= buf1(o_out);

  div : process (gsr, clr_in, i_in, ce_in, i_ce, ce_en)
    variable o_v : std_ulogic := '0';
    variable count : integer := 0;
    variable first_rise : std_ulogic := 'X';
    variable half_done : std_ulogic := 'X';
    variable ce1, ce2, ce3, ce4 : std_ulogic := 'X';
    variable held, ce_held : boolean := false;
    variable pi, pce : std_ulogic := 'U';
    variable armed : boolean := false;
    variable i_fall, i_chg, ce_chg, ice_chg : boolean;
  begin
    if gsr = '1' or clr_in = '1' then
      held := true;
      o_v := '0';
      count := 0;
      first_rise := '1';
      half_done := '0';
      if gsr = '1' then
        ce_held := true;
        ce1 := '0';
        ce2 := '0';
        ce3 := '0';
        ce4 := '0';
        ce4_s <= '0';
      end if;
    elsif gsr = '0' or clr_in = '0' then
      held := false;
      if gsr = '0' then
        ce_held := false;
      end if;
    end if;

    i_fall := false;
    i_chg := false;
    ce_chg := false;
    ice_chg := false;
    if armed then
      i_fall := verilog_negedge(pi, i_in);
      i_chg := pi /= i_in;
      ce_chg := pce /= ce_en;
      ice_chg := i_ce'event;
    end if;

    if not held then
      if v4 then
        if i_chg or ce_chg then
          if ce_en = '1' then
            if i_in = '1' and first_rise = '1' then
              o_v := '1';
              first_rise := '0';
            elsif count = half_n and half_done = '0' then
              o_v := not o_v;
              half_done := '1';
              count := 0;
            elsif count = per_n and half_done = '1' then
              o_v := not o_v;
              half_done := '0';
              count := 0;
            end if;
            if first_rise = '0' then
              count := count + 1;
            end if;
          else
            count := 0;
            first_rise := '1';
          end if;
        end if;
      elsif ice_chg then
        if i_ce = '1' and first_rise = '1' then
          o_v := '1';
          first_rise := '0';
        elsif count = half_n and half_done = '0' then
          o_v := not o_v;
          half_done := '1';
          count := 0;
        elsif count = per_n and half_done = '1' then
          o_v := not o_v;
          half_done := '0';
          count := 0;
        end if;
        if first_rise = '0' then
          count := count + 1;
        end if;
      end if;
    end if;

    if armed and i_fall and not ce_held then
      ce4 := ce3;
      ce3 := ce2;
      ce2 := ce1;
      ce1 := ce_in;
      ce4_s <= ce4;
    end if;

    armed := true;
    pi := i_in;
    pce := ce_en;
    o_div <= o_v;
  end process;
end architecture sim;
