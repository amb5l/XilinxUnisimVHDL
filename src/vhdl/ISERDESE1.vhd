-- ISERDESE1. Input deserializer with a synchronous reset.
-- The falling-edge sample is posedge CLKB. Rank flops in the Verilog
-- are delayed 300 ps and the muxes 60 ps; neither delay is copied.
-- IOBDELAY selects D or DDLY. OFB_USED feeds OFB to O and to the
-- sampler. DYN_CLK_INV_EN swaps CLK and CLKB. DYN_CLKDIV_INV_EN
-- inverts CLKDIV. NETWORKING DDR width 4 and SDR width 2 clock rank 2
-- from the inverted divider. An unknown rate, width, or interface does
-- not $finish: the divider falls back to DDR width 4 and the interface
-- falls back to MEMORY. OVERSAMPLE and MEMORY_DDR3 keep the rank-3
-- output mux; their extra rank-2 clocks are not the comparison path.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity ISERDESE1 is
  generic (
    DATA_RATE : string := "DDR";
    DATA_WIDTH : integer := 4;
    DYN_CLKDIV_INV_EN : boolean := FALSE;
    DYN_CLK_INV_EN : boolean := FALSE;
    INIT_Q1 : bit := '0';
    INIT_Q2 : bit := '0';
    INIT_Q3 : bit := '0';
    INIT_Q4 : bit := '0';
    INTERFACE_TYPE : string := "MEMORY";
    NUM_CE : integer := 2;
    IOBDELAY : string := "NONE";
    OFB_USED : boolean := FALSE;
    SERDES_MODE : string := "MASTER";
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
    CLKB : in std_ulogic;
    CLKDIV : in std_ulogic;
    D : in std_ulogic;
    DDLY : in std_ulogic;
    DYNCLKDIVSEL : in std_ulogic;
    DYNCLKSEL : in std_ulogic;
    OCLK : in std_ulogic;
    OFB : in std_ulogic;
    RST : in std_ulogic;
    SHIFTIN1 : in std_ulogic;
    SHIFTIN2 : in std_ulogic
  );
end entity ISERDESE1;

architecture behav of ISERDESE1 is
  constant sdr : boolean := DATA_RATE = "SDR";
  constant slave : boolean := SERDES_MODE = "SLAVE";
  constant networking : boolean := INTERFACE_TYPE = "NETWORKING";
  constant oversample : boolean := INTERFACE_TYPE = "OVERSAMPLE";
  constant ce_two : boolean := NUM_CE = 2;
  -- interface_type[0] is 1 for NETWORKING, OVERSAMPLE and MEMORY_DDR3.
  constant use_rank3 : boolean := networking or oversample
    or INTERFACE_TYPE = "MEMORY_DDR3";
  -- cntr 00100 (DDR 4) and 10010 (SDR 2) invert the divider into rank 2.
  constant rank2_inv : boolean := networking
    and ((not sdr and DATA_WIDTH = 4) or (sdr and DATA_WIDTH = 2));

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
  signal data_in : std_ulogic := '0';
  signal clk_i, clkb_i, clkdiv_i : std_ulogic := '0';
  signal ice : std_ulogic := '0';
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

  -- OFB replaces both O and the sampler. Otherwise IOBDELAY picks D or DDLY.
  src_p : process (D, DDLY, OFB) is
  begin
    if OFB_USED then
      O <= OFB;
      data_in <= OFB;
    elsif IOBDELAY = "IBUF" then
      O <= DDLY;
      data_in <= D;
    elsif IOBDELAY = "IFD" then
      O <= D;
      data_in <= DDLY;
    elsif IOBDELAY = "BOTH" then
      O <= DDLY;
      data_in <= DDLY;
    else
      O <= D;
      data_in <= D;
    end if;
  end process;

  -- DYN_CLK_INV_EN FALSE copies CLK and CLKB. TRUE swaps them when
  -- DYNCLKSEL is 0.
  clk_i <= CLKB when DYN_CLK_INV_EN and DYNCLKSEL = '0' else CLK;
  clkb_i <= CLK when DYN_CLK_INV_EN and DYNCLKSEL = '0' else CLKB;
  clkdiv_i <= not CLKDIV when DYN_CLKDIV_INV_EN and DYNCLKDIVSEL = '1' else CLKDIV;

  bsmux(2) <= '1' when use_rank3 else '0';
  bsmux(1) <= '1' when sdr else '0';
  bsmux(0) <= muxc;

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

  -- Reset is synchronous. GSR still forces the init value.
  q1_p : process (gsr, clk_i) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      q1rnk1 <= init1;
    elsif verilog_posedge(prev, clk_i) then
      if RST = '1' then
        q1rnk1 <= sr1;
      elsif ice = '1' then
        q1rnk1 <= data_in;
      end if;
    end if;
    prev := clk_i;
  end process;

  q2n_p : process (gsr, clkb_i) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      q2nrnk1 <= init2;
    elsif verilog_posedge(prev, clkb_i) then
      if RST = '1' then
        q2nrnk1 <= sr2;
      elsif ice = '1' then
        q2nrnk1 <= data_in;
      end if;
    end if;
    prev := clkb_i;
  end process;

  -- Fabric clocks are memmux and its complement. The flops sample the
  -- raw CLK or OCLK so a same-edge transfer still sees the old rank.
  q2p_p : process (gsr, clk_i, OCLK) is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
  begin
    curr := clk_i when networking or oversample else not OCLK;
    if gsr = '1' then
      q2prnk1 <= init4;
    elsif verilog_posedge(prev, curr) then
      if RST = '1' then
        q2prnk1 <= sr4;
      elsif ice = '1' then
        q2prnk1 <= q2nrnk1;
      end if;
    end if;
    prev := curr;
  end process;

  q1p_p : process (gsr, clk_i, OCLK) is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
  begin
    curr := clk_i when networking or oversample else OCLK;
    if gsr = '1' then
      q1prnk1 <= init3;
    elsif verilog_posedge(prev, curr) then
      if RST = '1' then
        q1prnk1 <= sr3;
      elsif ice = '1' then
        q1prnk1 <= q1rnk1;
      end if;
    end if;
    prev := curr;
  end process;

  qhi_p : process (gsr, clk_i) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      q5rnk1 <= '0';
      q6rnk1 <= '0';
      q6prnk1 <= '0';
    elsif verilog_posedge(prev, clk_i) then
      if RST = '1' then
        q5rnk1 <= '0';
        q6rnk1 <= '0';
        q6prnk1 <= '0';
      else
        q5rnk1 <= dataq5rnk1;
        q6rnk1 <= dataq6rnk1;
        q6prnk1 <= q6rnk1;
      end if;
    end if;
    prev := clk_i;
  end process;

  q34_p : process (gsr, clk_i, OCLK) is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
  begin
    curr := clk_i when networking or oversample else OCLK;
    if gsr = '1' then
      q3rnk1 <= '0';
      q4rnk1 <= '0';
    elsif verilog_posedge(prev, curr) then
      if RST = '1' then
        q3rnk1 <= '0';
        q4rnk1 <= '0';
      else
        q3rnk1 <= dataq3rnk1;
        q4rnk1 <= dataq4rnk1;
      end if;
    end if;
    prev := curr;
  end process;

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

  -- Rank 2 clock. Networking uses the divider; DDR width 4 inverts it.
  -- Memory uses CLKDIV. The level is computed in the process so the flop
  -- does not wait a delta for a separate mux.
  r2_p : process (gsr, clkdiv_int, clkdiv_i) is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
  begin
    if rank2_inv then
      curr := not clkdiv_int;
    elsif networking or oversample then
      curr := clkdiv_int;
    else
      curr := clkdiv_i;
    end if;
    if gsr = '1' then
      q1rnk2 <= '0';
      q2rnk2 <= '0';
      q3rnk2 <= '0';
      q4rnk2 <= '0';
      q5rnk2 <= '0';
      q6rnk2 <= '0';
    elsif verilog_posedge(prev, curr) then
      if RST = '1' then
        q1rnk2 <= '0';
        q2rnk2 <= '0';
        q3rnk2 <= '0';
        q4rnk2 <= '0';
        q5rnk2 <= '0';
        q6rnk2 <= '0';
      else
        q1rnk2 <= dataq1rnk2;
        q2rnk2 <= dataq2rnk2;
        q3rnk2 <= dataq3rnk2;
        q4rnk2 <= dataq4rnk2;
        q5rnk2 <= dataq5rnk2;
        q6rnk2 <= dataq6rnk2;
      end if;
    end if;
    prev := curr;
  end process;

  r3_p : process (gsr, clkdiv_i) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      q1rnk3 <= '0';
      q2rnk3 <= '0';
      q3rnk3 <= '0';
      q4rnk3 <= '0';
      q5rnk3 <= '0';
      q6rnk3 <= '0';
    elsif verilog_posedge(prev, clkdiv_i) then
      if RST = '1' then
        q1rnk3 <= '0';
        q2rnk3 <= '0';
        q3rnk3 <= '0';
        q4rnk3 <= '0';
        q5rnk3 <= '0';
        q6rnk3 <= '0';
      else
        q1rnk3 <= q1rnk2;
        q2rnk3 <= q2rnk2;
        q3rnk3 <= q3rnk2;
        q4rnk3 <= q4rnk2;
        q5rnk3 <= q5rnk2;
        q6rnk3 <= q6rnk2;
      end if;
    end if;
    prev := clkdiv_i;
  end process;

  Q1 <= q1rnk3 when use_rank3 else q1rnk2;
  Q2 <= q2rnk3 when use_rank3 else q2rnk2;
  Q3 <= q3rnk3 when use_rank3 else q3rnk2;
  Q4 <= q4rnk3 when use_rank3 else q4rnk2;
  Q5 <= q5rnk3 when use_rank3 else q5rnk2;
  Q6 <= q6rnk3 when use_rank3 else q6rnk2;
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

  -- Bitslip controller, SRTYPE 0: reset is the clocked path.
  -- The Verilog clocks it on posedge of not CLK, which is negedge CLK.
  qr1_p : process (clkdiv_i) is
    variable prev : std_ulogic := 'U';
  begin
    if verilog_posedge(prev, clkdiv_i) then
      if RST = '1' then
        qr1 <= '1';
      else
        qr1 <= '0';
      end if;
    end if;
    prev := clkdiv_i;
  end process;

  qr2_p : process (clk_i) is
    variable prev : std_ulogic := 'U';
  begin
    if verilog_negedge(prev, clk_i) then
      if RST = '1' then
        qr2 <= '1';
      else
        qr2 <= qr1;
      end if;
    end if;
    prev := clk_i;
  end process;

  qlc_p : process (qr1, clkdiv_i) is
    variable prev : std_ulogic := 'U';
  begin
    if qr1 = '1' then
      qlc1 <= '0';
      qlc2 <= '0';
    elsif verilog_posedge(prev, clkdiv_i) then
      if BITSLIP = '0' then
        qlc2 <= '0';
      else
        qlc1 <= not qlc1;
        qlc2 <= BITSLIP and mux1;
      end if;
    end if;
    prev := clkdiv_i;
  end process;

  qhc_p : process (qr2, clk_i) is
    variable prev : std_ulogic := 'U';
  begin
    if qr2 = '1' then
      qhc1 <= '0';
      qhc2 <= '0';
    elsif verilog_negedge(prev, clk_i) then
      qhc1 <= qlc2 and not qhc2;
      qhc2 <= qlc2;
    end if;
    prev := clk_i;
  end process;

  cnt_p : process (gsr, qr2, clk_i) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      clkdiv_int <= '0';
      bts_q1 <= '0';
      bts_q2 <= '0';
      bts_q3 <= '0';
    elsif verilog_negedge(prev, clk_i) then
      if qr2 = '1' then
        clkdiv_int <= '0';
        bts_q1 <= '0';
        bts_q2 <= '0';
        bts_q3 <= '0';
      elsif qhc1 = '0' then
        bts_q3 <= bts_q2;
        bts_q2 <= (clkdiv_int or bts_q2) and bts_q1;
        bts_q1 <= clkdiv_int;
        clkdiv_int <= mux;
      end if;
    end if;
    prev := clk_i;
  end process;

  ce_p : process (gsr, clkdiv_i) is
    variable prev : std_ulogic := 'U';
  begin
    if gsr = '1' then
      ce1r <= '0';
      ce2r <= '0';
    elsif verilog_posedge(prev, clkdiv_i) then
      if RST = '1' then
        ce1r <= '0';
        ce2r <= '0';
      else
        ce1r <= CE1;
        ce2r <= CE2;
      end if;
    end if;
    prev := clkdiv_i;
  end process;

  ice_p : process (clkdiv_i, CE1, ce1r, ce2r) is
  begin
    if not ce_two then
      ice <= CE1;
    elsif clkdiv_i = '0' then
      ice <= ce2r;
    else
      ice <= ce1r;
    end if;
  end process;

end architecture behav;
