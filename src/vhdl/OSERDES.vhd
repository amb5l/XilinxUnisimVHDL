-- OSERDES. Master or slave output serializer.
-- DDR presents one bit on each CLK edge. SDR presents D1's path on
-- the high level of CLK. The load generator is the same divider as
-- ISERDES: it inserts the CLKDIV word when its count matches the
-- width, and shifts the pipeline otherwise. SAME_EDGE is the only
-- DDR clocking (c2p is CLK, c3 is not CLK). The 1 ps flop delays
-- are not copied. An illegal width or tristate pairing does not
-- $finish; the divider falls back to DDR width 4 and an unsupported
-- TQ mux holds its data inputs.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity OSERDES is
  generic (
    DATA_RATE_OQ : string := "DDR";
    DATA_RATE_TQ : string := "DDR";
    DATA_WIDTH : integer := 4;
    INIT_OQ : bit := '0';
    INIT_TQ : bit := '0';
    SERDES_MODE : string := "MASTER";
    SRVAL_OQ : bit := '0';
    SRVAL_TQ : bit := '0';
    TRISTATE_WIDTH : integer := 4
  );
  port (
    OQ : out std_ulogic;
    SHIFTOUT1 : out std_ulogic;
    SHIFTOUT2 : out std_ulogic;
    TQ : out std_ulogic;
    CLK : in std_ulogic;
    CLKDIV : in std_ulogic;
    D1 : in std_ulogic;
    D2 : in std_ulogic;
    D3 : in std_ulogic;
    D4 : in std_ulogic;
    D5 : in std_ulogic;
    D6 : in std_ulogic;
    OCE : in std_ulogic;
    REV : in std_ulogic;
    SHIFTIN1 : in std_ulogic;
    SHIFTIN2 : in std_ulogic;
    SR : in std_ulogic;
    T1 : in std_ulogic;
    T2 : in std_ulogic;
    T3 : in std_ulogic;
    T4 : in std_ulogic;
    TCE : in std_ulogic
  );
end entity OSERDES;

architecture behav of OSERDES is
  constant sdr : boolean := DATA_RATE_OQ = "SDR";
  constant slave : boolean := SERDES_MODE = "SLAVE";
  constant tq_sdr : boolean := DATA_RATE_TQ = "SDR";
  constant tq_ddr : boolean := DATA_RATE_TQ = "DDR";
  constant tq_buf : boolean := not tq_sdr and not tq_ddr;
  constant sr_oq : std_ulogic := to_sul(SRVAL_OQ);
  constant sr_tq : std_ulogic := to_sul(SRVAL_TQ);
  constant init_oq_s : std_ulogic := to_sul(INIT_OQ);
  constant init_tq_s : std_ulogic := to_sul(INIT_TQ);

  function c23_of return std_ulogic is
  begin
    if (not sdr and DATA_WIDTH = 6) or (sdr and DATA_WIDTH = 3) then
      return '1';
    end if;
    return '0';
  end function;

  function c45_of return std_ulogic is
  begin
    if (not sdr and DATA_WIDTH = 10) or (sdr and DATA_WIDTH = 5) then
      return '1';
    end if;
    return '0';
  end function;

  function c67_of return std_ulogic is
  begin
    if sdr and DATA_WIDTH = 7 then
      return '1';
    end if;
    return '0';
  end function;

  function sel_of return std_logic_vector is
  begin
    if not sdr then
      if DATA_WIDTH = 8 or DATA_WIDTH = 10 then
        return "01";
      end if;
      return "00";
    end if;
    if DATA_WIDTH = 4 or DATA_WIDTH = 5 then
      return "01";
    elsif DATA_WIDTH = 6 or DATA_WIDTH = 7 then
      return "10";
    elsif DATA_WIDTH = 8 then
      return "11";
    end if;
    return "00";
  end function;

  constant c23 : std_ulogic := c23_of;
  constant c45 : std_ulogic := c45_of;
  constant c67 : std_ulogic := c67_of;
  constant sel : std_logic_vector(1 downto 0) := sel_of;

  signal gsr : std_ulogic := '1';
  signal d1r, d2r, d3r, d4r, d5r, d6r : std_ulogic := '0';
  signal d1rnk2, d2rnk2, d2nrnk2 : std_ulogic := init_oq_s;
  signal d3rnk2, d4rnk2, d5rnk2, d6rnk2 : std_ulogic := '0';
  signal data1, data2, data3, data4, data5, data6 : std_ulogic := '0';
  signal q0, q1, q2, q3, mux, load : std_ulogic := '0';
  signal qlr, qhr : std_ulogic := '0';
  signal oqsr, oqrev, tqsr, tqrev : std_ulogic;
  signal io_ddr : std_ulogic;
  signal t1r, t2r, t3r, t4r : std_ulogic := '0';
  signal qt1, qt2, qt2n : std_ulogic := init_tq_s;
  signal data1t, data2t : std_ulogic := '0';
  signal iot_ddr : std_ulogic;
  signal oq_s : std_ulogic := init_oq_s;
  signal tq_s : std_ulogic := init_tq_s;
begin
  roc(gsr);

  -- sel1_4 is {1, load, sdr}. A load inserts the CLKDIV rank.
  -- Otherwise the pipeline shifts, and a slave's extra bits come
  -- from SHIFTIN rather than D5 and D6.
  data_mux : process (load, d1r, d2r, d3r, d4r, d5r, d6r, d2rnk2, d3rnk2, d4rnk2, d5rnk2, d6rnk2, SHIFTIN1, SHIFTIN2) is
  begin
    if load = '1' then
      data1 <= d1r;
      data2 <= d2r;
      data3 <= d3r;
      data4 <= d4r;
      data5 <= d5r;
      data6 <= d6r;
    elsif sdr then
      data1 <= d2rnk2;
      data2 <= d3rnk2;
      data3 <= d4rnk2;
      data4 <= d5rnk2;
      if slave then
        data5 <= d6rnk2;
        data6 <= '0';
      else
        data5 <= d6rnk2;
        data6 <= SHIFTIN1;
      end if;
    else
      data1 <= d3rnk2;
      data2 <= d4rnk2;
      data3 <= d5rnk2;
      data4 <= d6rnk2;
      if slave then
        data5 <= '0';
        data6 <= '0';
      else
        data5 <= SHIFTIN1;
        data6 <= SHIFTIN2;
      end if;
    end if;
  end process;

  -- c2p is CLK. Both of these flops clock on that rising edge, so
  -- the second reads the first's previous value.
  d12_p : process (gsr, CLK, SR, REV) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      d1rnk2 <= init_oq_s;
      d2rnk2 <= init_oq_s;
    elsif SR = '1' and not (REV = '1' and SRVAL_OQ = '1') then
      d1rnk2 <= sr_oq;
      d2rnk2 <= sr_oq;
    elsif REV = '1' then
      d1rnk2 <= not sr_oq;
      d2rnk2 <= not sr_oq;
    elsif verilog_posedge(prev, CLK) then
      if OCE = '1' then
        d1rnk2 <= data1;
        d2rnk2 <= data2;
      elsif OCE = '0' then
        d1rnk2 <= oq_s;
        d2rnk2 <= oq_s;
      end if;
    end if;
    prev := CLK;
  end process;

  -- c3 is not CLK, so this is the falling edge, after d2rnk2 has settled.
  d2n_p : process (gsr, CLK, SR, REV) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      d2nrnk2 <= init_oq_s;
    elsif SR = '1' and not (REV = '1' and SRVAL_OQ = '1') then
      d2nrnk2 <= sr_oq;
    elsif REV = '1' then
      d2nrnk2 <= not sr_oq;
    elsif verilog_negedge(prev, CLK) and OCE = '1' then
      d2nrnk2 <= d2rnk2;
    elsif verilog_negedge(prev, CLK) and OCE = '0' then
      d2nrnk2 <= oq_s;
    end if;
    prev := CLK;
  end process;

  dhi_p : process (gsr, CLK, SR) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or SR = '1' then
      d3rnk2 <= '0';
      d4rnk2 <= '0';
      d5rnk2 <= '0';
      d6rnk2 <= '0';
    elsif verilog_posedge(prev, CLK) then
      d3rnk2 <= data3;
      d4rnk2 <= data4;
      d5rnk2 <= data5;
      d6rnk2 <= data6;
    end if;
    prev := CLK;
  end process;

  rank_p : process (gsr, CLKDIV, SR) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or SR = '1' then
      d1r <= '0';
      d2r <= '0';
      d3r <= '0';
      d4r <= '0';
      d5r <= '0';
      d6r <= '0';
    elsif verilog_posedge(prev, CLKDIV) then
      d1r <= D1;
      d2r <= D2;
      d3r <= D3;
      d4r <= D4;
      d5r <= D5;
      d6r <= D6;
    end if;
    prev := CLKDIV;
  end process;

  -- SAME_EDGE: the high level is d1rnk2 and the low level is d2nrnk2.
  io_ddr <= (d1rnk2 and CLK) or (d2nrnk2 and not CLK);

  oqsr <= (SR and not sr_oq) or (REV and sr_oq);
  oqrev <= (SR and sr_oq) or (REV and not sr_oq);

  oq_p : process (OCE, oqsr, oqrev, d1rnk2, io_ddr) is
  begin
    if oqrev = '1' and oqsr = '0' then
      oq_s <= '1';
    elsif oqsr = '1' then
      oq_s <= '0';
    elsif OCE = '0' then
      null;
    elsif sdr then
      oq_s <= d1rnk2;
    else
      oq_s <= io_ddr;
    end if;
  end process;
  OQ <= oq_s;

  SHIFTOUT1 <= d3rnk2 when slave else '0';
  SHIFTOUT2 <= d4rnk2 when slave else '0';

  -- Divider. sel 00 toggles q0. load is q0 for a DDR width of 4.
  mux_p : process (q0, q1, q2, q3) is
  begin
    if sel = "01" then
      mux <= not q1 and not (c45 and q2);
      load <= q0 and q1;
    elsif sel = "10" then
      mux <= not q2 and not (c67 and q3);
      load <= q0 and q2;
    elsif sel = "11" then
      mux <= not q3;
      load <= q0 and q3;
    else
      mux <= not q0 and not (c23 and q1);
      load <= q0;
    end if;
  end process;

  cnt_p : process (gsr, CLK, qhr) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or qhr = '1' then
      q0 <= '0';
      q1 <= '0';
      q2 <= '0';
      q3 <= '0';
    elsif verilog_posedge(prev, CLK) then
      q3 <= q2;
      q2 <= (q0 or q2) and q1;
      q1 <= q0;
      q0 <= mux;
    end if;
    prev := CLK;
  end process;

  qlr_p : process (gsr, CLKDIV, SR) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or SR = '1' then
      qlr <= '1';
    elsif verilog_posedge(prev, CLKDIV) then
      qlr <= '0';
    end if;
    prev := CLKDIV;
  end process;

  qhr_p : process (gsr, CLK, SR) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or SR = '1' then
      qhr <= '1';
    elsif verilog_posedge(prev, CLK) then
      qhr <= qlr;
    end if;
    prev := CLK;
  end process;

  -- sel_tri is {load, rate, width}. BUF and SDR width 1 pass T1 and
  -- T2 through. DDR width 4 shifts t3/t4, then loads t1/t2.
  tri_mux : process (load, T1, T2, t1r, t2r, t3r, t4r) is
  begin
    if tq_ddr and TRISTATE_WIDTH = 4 then
      if load = '1' then
        data1t <= t1r;
        data2t <= t2r;
      elsif load = '0' then
        data1t <= t3r;
        data2t <= t4r;
      end if;
    elsif tq_ddr and TRISTATE_WIDTH = 2 then
      data1t <= T1;
      data2t <= T2;
    elsif (tq_buf and TRISTATE_WIDTH = 1) or (tq_sdr and TRISTATE_WIDTH = 1) then
      data1t <= T1;
      data2t <= T2;
    end if;
  end process;

  t12_p : process (gsr, CLK, SR, REV) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      qt1 <= init_tq_s;
      qt2 <= init_tq_s;
    elsif SR = '1' and not (REV = '1' and SRVAL_TQ = '1') then
      qt1 <= sr_tq;
      qt2 <= sr_tq;
    elsif REV = '1' then
      qt1 <= not sr_tq;
      qt2 <= not sr_tq;
    elsif verilog_posedge(prev, CLK) then
      if TCE = '1' then
        qt1 <= data1t;
        qt2 <= data2t;
      elsif TCE = '0' then
        qt1 <= tq_s;
        qt2 <= tq_s;
      end if;
    end if;
    prev := CLK;
  end process;

  t2n_p : process (gsr, CLK, SR, REV) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      qt2n <= init_tq_s;
    elsif SR = '1' and not (REV = '1' and SRVAL_TQ = '1') then
      qt2n <= sr_tq;
    elsif REV = '1' then
      qt2n <= not sr_tq;
    elsif verilog_negedge(prev, CLK) and TCE = '1' then
      qt2n <= qt2;
    elsif verilog_negedge(prev, CLK) and TCE = '0' then
      qt2n <= tq_s;
    end if;
    prev := CLK;
  end process;

  trank_p : process (gsr, CLKDIV, SR) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or SR = '1' then
      t1r <= '0';
      t2r <= '0';
      t3r <= '0';
      t4r <= '0';
    elsif verilog_posedge(prev, CLKDIV) then
      t1r <= T1;
      t2r <= T2;
      t3r <= T3;
      t4r <= T4;
    end if;
    prev := CLKDIV;
  end process;

  iot_ddr <= (qt1 and CLK) or (qt2n and not CLK);
  tqsr <= (SR and not sr_tq) or (REV and sr_tq);
  tqrev <= (SR and sr_tq) or (REV and not sr_tq);

  tq_p : process (TCE, tqsr, tqrev, data1t, qt1, iot_ddr) is
  begin
    if (tq_sdr or tq_ddr) and tqrev = '1' and tqsr = '0' then
      tq_s <= '1';
    elsif (tq_sdr or tq_ddr) and tqsr = '1' then
      tq_s <= '0';
    elsif tq_buf and TRISTATE_WIDTH = 1 then
      tq_s <= data1t;
    elsif TCE = '0' and tqsr = '0' and tqrev = '0' and ((tq_sdr and TRISTATE_WIDTH = 1) or (tq_ddr and (TRISTATE_WIDTH = 2 or TRISTATE_WIDTH = 4))) then
      null;
    elsif TCE = '1' and tq_sdr and TRISTATE_WIDTH = 1 then
      tq_s <= qt1;
    elsif TCE = '1' and tq_ddr and (TRISTATE_WIDTH = 2 or TRISTATE_WIDTH = 4) then
      tq_s <= iot_ddr;
    else
      tq_s <= iot_ddr;
    end if;
  end process;
  TQ <= tq_s;
end architecture behav;
