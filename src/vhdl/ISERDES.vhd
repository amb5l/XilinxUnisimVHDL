-- ISERDES. Networking or memory input deserializer.
-- DDR samples D on both edges of CLK. SDR samples the rising edge.
-- MEMORY clocks the fabric rank from OCLK. NETWORKING clocks it
-- from CLK and requires BITSLIP_ENABLE (the Verilog $finish on the
-- illegal pair is not copied). Rank 2 is loaded by CLKDIV, or by
-- the internal divider when bitslip is enabled, and rank 3 follows
-- CLKDIV. Q1 is the oldest bit. The 300 ps flop delays are not
-- copied. The IDELAY tap chain is zero delay. An unknown width or
-- rate uses the DDR width-4 divider. Nothing here $finish.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity ISERDES is
  generic (
    BITSLIP_ENABLE : boolean := FALSE;
    DATA_RATE : string := "DDR";
    DATA_WIDTH : integer := 4;
    INIT_Q1 : bit := '0';
    INIT_Q2 : bit := '0';
    INIT_Q3 : bit := '0';
    INIT_Q4 : bit := '0';
    INTERFACE_TYPE : string := "MEMORY";
    IOBDELAY : string := "NONE";
    IOBDELAY_TYPE : string := "DEFAULT";
    IOBDELAY_VALUE : integer := 0;
    NUM_CE : integer := 2;
    SERDES_MODE : string := "MASTER";
    SIM_DELAY_D : integer := 0;
    SIM_SETUP_D_CLK : integer := 0;
    SIM_HOLD_D_CLK : integer := 0;
    SRVAL_Q1 : bit := '0';
    SRVAL_Q2 : bit := '0';
    SRVAL_Q3 : bit := '0';
    SRVAL_Q4 : bit := '0'
  );
  port (
    O : out std_ulogic;
    Q1 : out std_ulogic;
    Q2 : out std_ulogic;
    Q3 : out std_ulogic;
    Q4 : out std_ulogic;
    Q5 : out std_ulogic;
    Q6 : out std_ulogic;
    SHIFTOUT1 : out std_ulogic;
    SHIFTOUT2 : out std_ulogic;
    BITSLIP : in std_ulogic;
    CE1 : in std_ulogic;
    CE2 : in std_ulogic;
    CLK : in std_ulogic;
    CLKDIV : in std_ulogic;
    D : in std_ulogic;
    DLYCE : in std_ulogic;
    DLYINC : in std_ulogic;
    DLYRST : in std_ulogic;
    OCLK : in std_ulogic;
    REV : in std_ulogic;
    SHIFTIN1 : in std_ulogic;
    SHIFTIN2 : in std_ulogic;
    SR : in std_ulogic
  );
end entity ISERDES;

architecture behav of ISERDES is
  constant sdr : boolean := DATA_RATE = "SDR";
  constant slave : boolean := SERDES_MODE = "SLAVE";
  constant networking : boolean := INTERFACE_TYPE = "NETWORKING";
  constant ce_two : boolean := NUM_CE = 2;

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
  constant init1 : std_ulogic := to_sul(INIT_Q1);
  constant init2 : std_ulogic := to_sul(INIT_Q2);
  constant init3 : std_ulogic := to_sul(INIT_Q3);
  constant init4 : std_ulogic := to_sul(INIT_Q4);
  constant sr1 : std_ulogic := to_sul(SRVAL_Q1);
  constant sr2 : std_ulogic := to_sul(SRVAL_Q2);
  constant sr3 : std_ulogic := to_sul(SRVAL_Q3);
  constant sr4 : std_ulogic := to_sul(SRVAL_Q4);

  signal gsr : std_ulogic := '1';
  signal o_delay : std_ulogic := '0';
  signal memmux, q2pmux : std_ulogic := '0';
  signal ice : std_ulogic := '0';
  signal clkdivmux : std_ulogic := '0';
  signal mux, mux1, muxc : std_ulogic := '0';
  signal clkdiv_int : std_ulogic := '0';
  signal bts_q1, bts_q2, bts_q3 : std_ulogic := '0';
  signal qlc1, qlc2, qhc1, qhc2 : std_ulogic := 'U';
  signal qr1, qr2 : std_ulogic := 'U';
  signal ce1r, ce2r : std_ulogic := '0';
  signal q1rnk1 : std_ulogic := init1;
  signal q2nrnk1 : std_ulogic := init2;
  signal q1prnk1 : std_ulogic := init3;
  signal q2prnk1 : std_ulogic := init4;
  signal q3rnk1, q4rnk1, q5rnk1, q6rnk1, q6prnk1 : std_ulogic := '0';
  signal q1rnk2, q2rnk2, q3rnk2, q4rnk2, q5rnk2, q6rnk2 : std_ulogic := '0';
  signal q1rnk3, q2rnk3, q3rnk3, q4rnk3, q5rnk3, q6rnk3 : std_ulogic := '0';
  signal dataq3rnk1, dataq4rnk1, dataq5rnk1, dataq6rnk1 : std_ulogic := '0';
  signal dataq1rnk2, dataq2rnk2, dataq3rnk2 : std_ulogic := '0';
  signal dataq4rnk2, dataq5rnk2, dataq6rnk2 : std_ulogic := '0';
  signal bsmux : std_logic_vector(2 downto 0) := "000";
begin
  roc_p : process
  begin
    roc(gsr);
  end process;

  -- Every IOBDELAY mode is D. The tap delay (SIM_TAPDELAY_VALUE,
  -- SIM_DELAY_D) is not applied, so IBUF, IFD and BOTH match NONE.
  iob_p : process (D) is
  begin
    if IOBDELAY = "NONE" or IOBDELAY = "IBUF"
        or IOBDELAY = "IFD" or IOBDELAY = "BOTH" then
      o_delay <= D;
      O <= D;
    else
      o_delay <= D;
      O <= D;
    end if;
  end process;

  mem_p : process (CLK, OCLK) is
  begin
    if networking then
      memmux <= CLK;
    else
      memmux <= OCLK;
    end if;
  end process;

  q2p_mux_p : process (memmux) is
  begin
    if networking then
      q2pmux <= memmux;
    else
      q2pmux <= not memmux;
    end if;
  end process;

  bsmux(2) <= '1' when BITSLIP_ENABLE else '0';
  bsmux(1) <= '1' when sdr else '0';
  bsmux(0) <= muxc;

  -- sel1 is {slave, sdr}. Master DDR uses the local rank.
  d3_p : process (q1prnk1, q2prnk1, q3rnk1, SHIFTIN1, SHIFTIN2) is
  begin
    if slave and not sdr then
      dataq3rnk1 <= SHIFTIN2;
      dataq4rnk1 <= SHIFTIN1;
    elsif slave and sdr then
      dataq3rnk1 <= SHIFTIN1;
      dataq4rnk1 <= q3rnk1;
    elsif sdr then
      dataq3rnk1 <= q1prnk1;
      dataq4rnk1 <= q3rnk1;
    else
      dataq3rnk1 <= q1prnk1;
      dataq4rnk1 <= q2prnk1;
    end if;
  end process;

  dataq5rnk1 <= q4rnk1 when sdr else q3rnk1;
  dataq6rnk1 <= q5rnk1 when sdr else q4rnk1;

  q1_p : process (gsr, CLK, SR, REV) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      q1rnk1 <= init1;
    elsif SR = '1' and not (REV = '1' and sr1 = '1') then
      q1rnk1 <= sr1;
    elsif REV = '1' then
      q1rnk1 <= not sr1;
    elsif verilog_posedge(prev, CLK) and ice = '1' then
      q1rnk1 <= o_delay;
    end if;
    prev := CLK;
  end process;

  q2n_p : process (gsr, CLK, SR, REV) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      q2nrnk1 <= init2;
    elsif SR = '1' and not (REV = '1' and sr2 = '1') then
      q2nrnk1 <= sr2;
    elsif REV = '1' then
      q2nrnk1 <= not sr2;
    elsif verilog_negedge(prev, CLK) and ice = '1' then
      q2nrnk1 <= o_delay;
    end if;
    prev := CLK;
  end process;

  -- The fabric clocks are memmux and q2pmux, which the Verilog
  -- delays by 60 ps. The flops they clock delay their D by 300 ps,
  -- so a same-edge transfer still sees the old rank. Using the raw
  -- CLK/OCLK here keeps that transfer in one delta.
  q2p_p : process (gsr, CLK, OCLK, SR, REV) is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
  begin
    curr := CLK when networking else not OCLK;
    if gsr = '1' then
      q2prnk1 <= init4;
    elsif SR = '1' and not (REV = '1' and sr4 = '1') then
      q2prnk1 <= sr4;
    elsif REV = '1' then
      q2prnk1 <= not sr4;
    elsif verilog_posedge(prev, curr) and ice = '1' then
      q2prnk1 <= q2nrnk1;
    end if;
    prev := curr;
  end process;

  q1p_p : process (gsr, CLK, OCLK, SR, REV) is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
  begin
    curr := CLK when networking else OCLK;
    if gsr = '1' then
      q1prnk1 <= init3;
    elsif SR = '1' and not (REV = '1' and sr3 = '1') then
      q1prnk1 <= sr3;
    elsif REV = '1' then
      q1prnk1 <= not sr3;
    elsif verilog_posedge(prev, curr) and ice = '1' then
      q1prnk1 <= q1rnk1;
    end if;
    prev := curr;
  end process;

  qhi_p : process (gsr, CLK, SR) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or SR = '1' then
      q5rnk1 <= '0';
      q6rnk1 <= '0';
      q6prnk1 <= '0';
    elsif verilog_posedge(prev, CLK) then
      q5rnk1 <= dataq5rnk1;
      q6rnk1 <= dataq6rnk1;
      q6prnk1 <= q6rnk1;
    end if;
    prev := CLK;
  end process;

  q34_p : process (gsr, CLK, OCLK, SR) is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
  begin
    curr := CLK when networking else OCLK;
    if gsr = '1' or SR = '1' then
      q3rnk1 <= '0';
      q4rnk1 <= '0';
    elsif verilog_posedge(prev, curr) then
      q3rnk1 <= dataq3rnk1;
      q4rnk1 <= dataq4rnk1;
    end if;
    prev := curr;
  end process;

  -- bsmux casex, first match wins. X in the pattern is a don't-care.
  d2_p : process (
    bsmux, q1rnk1, q1prnk1, q2prnk1, q3rnk1, q4rnk1, q5rnk1, q6rnk1, q6prnk1
  ) is
  begin
    if bsmux(2) = '0' and bsmux(1) = '0' then
      dataq1rnk2 <= q2prnk1;
      dataq2rnk2 <= q1prnk1;
      dataq3rnk2 <= q4rnk1;
      dataq4rnk2 <= q3rnk1;
      dataq5rnk2 <= q6rnk1;
      dataq6rnk2 <= q5rnk1;
    elsif bsmux = "100" then
      dataq1rnk2 <= q2prnk1;
      dataq2rnk2 <= q1prnk1;
      dataq3rnk2 <= q4rnk1;
      dataq4rnk2 <= q3rnk1;
      dataq5rnk2 <= q6rnk1;
      dataq6rnk2 <= q5rnk1;
    elsif bsmux = "101" then
      dataq1rnk2 <= q1prnk1;
      dataq2rnk2 <= q4rnk1;
      dataq3rnk2 <= q3rnk1;
      dataq4rnk2 <= q6rnk1;
      dataq5rnk2 <= q5rnk1;
      dataq6rnk2 <= q6prnk1;
    elsif bsmux(1) = '1' then
      dataq1rnk2 <= q1rnk1;
      dataq2rnk2 <= q1prnk1;
      dataq3rnk2 <= q3rnk1;
      dataq4rnk2 <= q4rnk1;
      dataq5rnk2 <= q5rnk1;
      dataq6rnk2 <= q6rnk1;
    else
      dataq1rnk2 <= q2prnk1;
      dataq2rnk2 <= q1prnk1;
      dataq3rnk2 <= q4rnk1;
      dataq4rnk2 <= q3rnk1;
      dataq5rnk2 <= q6rnk1;
      dataq6rnk2 <= q5rnk1;
    end if;
  end process;

  divmux_p : process (CLKDIV, clkdiv_int) is
  begin
    if BITSLIP_ENABLE then
      clkdivmux <= clkdiv_int;
    else
      clkdivmux <= CLKDIV;
    end if;
  end process;

  r2_p : process (gsr, clkdivmux, SR) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or SR = '1' then
      q1rnk2 <= '0';
      q2rnk2 <= '0';
      q3rnk2 <= '0';
      q4rnk2 <= '0';
      q5rnk2 <= '0';
      q6rnk2 <= '0';
    elsif verilog_posedge(prev, clkdivmux) then
      q1rnk2 <= dataq1rnk2;
      q2rnk2 <= dataq2rnk2;
      q3rnk2 <= dataq3rnk2;
      q4rnk2 <= dataq4rnk2;
      q5rnk2 <= dataq5rnk2;
      q6rnk2 <= dataq6rnk2;
    end if;
    prev := clkdivmux;
  end process;

  r3_p : process (gsr, CLKDIV, SR) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or SR = '1' then
      q1rnk3 <= '0';
      q2rnk3 <= '0';
      q3rnk3 <= '0';
      q4rnk3 <= '0';
      q5rnk3 <= '0';
      q6rnk3 <= '0';
    elsif verilog_posedge(prev, CLKDIV) then
      q1rnk3 <= q1rnk2;
      q2rnk3 <= q2rnk2;
      q3rnk3 <= q3rnk2;
      q4rnk3 <= q4rnk2;
      q5rnk3 <= q5rnk2;
      q6rnk3 <= q6rnk2;
    end if;
    prev := CLKDIV;
  end process;

  -- selrnk3 is {1, bitslip, 0, 0}. Bitslip selects rank 3.
  Q1 <= q1rnk3 when BITSLIP_ENABLE else q1rnk2;
  Q2 <= q2rnk3 when BITSLIP_ENABLE else q2rnk2;
  Q3 <= q3rnk3 when BITSLIP_ENABLE else q3rnk2;
  Q4 <= q4rnk3 when BITSLIP_ENABLE else q4rnk2;
  Q5 <= q5rnk3 when BITSLIP_ENABLE else q5rnk2;
  Q6 <= q6rnk3 when BITSLIP_ENABLE else q6rnk2;
  SHIFTOUT1 <= q6rnk1;
  SHIFTOUT2 <= q5rnk1;

  mux1 <= '1' when sdr else qlc1;
  muxc <= '0' when sdr else mux1;

  slip_mux_p : process (clkdiv_int, bts_q1, bts_q2, bts_q3) is
  begin
    if sel = "01" then
      mux <= not (bts_q1 or (c45 and bts_q2));
    elsif sel = "10" then
      mux <= not (bts_q2 or (c67 and bts_q3));
    elsif sel = "11" then
      mux <= not bts_q3;
    else
      mux <= not (clkdiv_int or (c23 and bts_q1));
    end if;
  end process;

  qr1_p : process (SR, CLKDIV) is
    variable prev : std_ulogic := 'U';
  begin
    if SR = '1' then
      qr1 <= '1';
    elsif verilog_posedge(prev, CLKDIV) then
      qr1 <= '0';
    end if;
    prev := CLKDIV;
  end process;

  qr2_p : process (SR, CLK) is
    variable prev : std_ulogic := 'U';
  begin
    if SR = '1' then
      qr2 <= '1';
    elsif verilog_negedge(prev, CLK) then
      qr2 <= qr1;
    end if;
    prev := CLK;
  end process;

  qlc_p : process (qr1, CLKDIV) is
    variable prev : std_ulogic := 'U';
  begin
    if qr1 = '1' then
      qlc1 <= '0';
      qlc2 <= '0';
    elsif verilog_posedge(prev, CLKDIV) then
      if BITSLIP = '0' then
        qlc2 <= '0';
      else
        qlc1 <= not qlc1;
        qlc2 <= BITSLIP and mux1;
      end if;
    end if;
    prev := CLKDIV;
  end process;

  qhc_p : process (qr2, CLK) is
    variable prev : std_ulogic := 'U';
  begin
    if qr2 = '1' then
      qhc1 <= '0';
      qhc2 <= '0';
    elsif verilog_negedge(prev, CLK) then
      qhc1 <= qlc2 and not qhc2;
      qhc2 <= qlc2;
    end if;
    prev := CLK;
  end process;

  cnt_p : process (gsr, qr2, CLK) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or qr2 = '1' then
      clkdiv_int <= '0';
      bts_q1 <= '0';
      bts_q2 <= '0';
      bts_q3 <= '0';
    elsif verilog_negedge(prev, CLK) and qhc1 = '0' then
      bts_q3 <= bts_q2;
      bts_q2 <= (clkdiv_int or bts_q2) and bts_q1;
      bts_q1 <= clkdiv_int;
      clkdiv_int <= mux;
    end if;
    prev := CLK;
  end process;

  ce_p : process (gsr, SR, CLKDIV) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' or SR = '1' then
      ce1r <= '0';
      ce2r <= '0';
    elsif verilog_posedge(prev, CLKDIV) then
      ce1r <= CE1;
      ce2r <= CE2;
    end if;
    prev := CLKDIV;
  end process;

  ice_p : process (CLKDIV, CE1, ce1r, ce2r) is
  begin
    if not ce_two then
      ice <= CE1;
    elsif CLKDIV = '0' then
      ice <= ce2r;
    else
      ice <= ce1r;
    end if;
  end process;

end architecture behav;
