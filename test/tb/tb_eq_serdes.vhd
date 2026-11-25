-- ISERDES against the submodule Verilog. XIL_TIMING is left undefined.
-- The Verilog flop delays are 300 ps; the bench waits 5 ns after the
-- edge. glbl.GSR is not visible to a Verilog module instantiated from
-- VHDL, so SR is pulsed before the comparisons.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_serdes is
end entity tb_eq_serdes;

architecture sim of tb_eq_serdes is
  constant step : time := 5 ns;

  signal clk, clkdiv, d, oclk, sr, slip : std_ulogic := '0';
  signal q1_h, q2_h, q3_h, q4_h, q5_h, q6_h : std_ulogic;
  signal q1_v, q2_v, q3_v, q4_v, q5_v, q6_v : std_ulogic;
  signal qm1_h, qm2_h, qm3_h, qm4_h : std_ulogic;
  signal qm1_v, qm2_v, qm3_v, qm4_v : std_ulogic;

  component ISERDES is
    generic (
      BITSLIP_ENABLE : boolean := FALSE;
      DATA_RATE : string := "DDR";
      DATA_WIDTH : integer := 4;
      INTERFACE_TYPE : string := "MEMORY";
      NUM_CE : integer := 2
    );
    port (
      O : out std_ulogic;
      Q1, Q2, Q3, Q4, Q5, Q6 : out std_ulogic;
      SHIFTOUT1, SHIFTOUT2 : out std_ulogic;
      BITSLIP, CE1, CE2, CLK, CLKDIV, D : in std_ulogic;
      DLYCE, DLYINC, DLYRST, OCLK, REV : in std_ulogic;
      SHIFTIN1, SHIFTIN2, SR : in std_ulogic
    );
  end component;
begin
  net_h : entity unisim.ISERDES
    generic map (
      BITSLIP_ENABLE => TRUE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "NETWORKING", NUM_CE => 2
    )
    port map (
      O => open, Q1 => q1_h, Q2 => q2_h, Q3 => q3_h, Q4 => q4_h,
      Q5 => q5_h, Q6 => q6_h, SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => slip, CE1 => '1', CE2 => '1', CLK => clk, CLKDIV => clkdiv,
      D => d, DLYCE => '0', DLYINC => '0', DLYRST => '0', OCLK => '0',
      REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0', SR => sr
    );
  net_v : ISERDES
    generic map (
      BITSLIP_ENABLE => TRUE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "NETWORKING", NUM_CE => 2
    )
    port map (
      O => open, Q1 => q1_v, Q2 => q2_v, Q3 => q3_v, Q4 => q4_v,
      Q5 => q5_v, Q6 => q6_v, SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => slip, CE1 => '1', CE2 => '1', CLK => clk, CLKDIV => clkdiv,
      D => d, DLYCE => '0', DLYINC => '0', DLYRST => '0', OCLK => '0',
      REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0', SR => sr
    );

  mem_h : entity unisim.ISERDES
    generic map (
      BITSLIP_ENABLE => FALSE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "MEMORY", NUM_CE => 1
    )
    port map (
      O => open, Q1 => qm1_h, Q2 => qm2_h, Q3 => qm3_h, Q4 => qm4_h,
      Q5 => open, Q6 => open, SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => '0', CE1 => '1', CE2 => '1', CLK => clk, CLKDIV => clkdiv,
      D => d, DLYCE => '0', DLYINC => '0', DLYRST => '0', OCLK => oclk,
      REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0', SR => sr
    );
  mem_v : ISERDES
    generic map (
      BITSLIP_ENABLE => FALSE, DATA_RATE => "DDR", DATA_WIDTH => 4,
      INTERFACE_TYPE => "MEMORY", NUM_CE => 1
    )
    port map (
      O => open, Q1 => qm1_v, Q2 => qm2_v, Q3 => qm3_v, Q4 => qm4_v,
      Q5 => open, Q6 => open, SHIFTOUT1 => open, SHIFTOUT2 => open,
      BITSLIP => '0', CE1 => '1', CE2 => '1', CLK => clk, CLKDIV => clkdiv,
      D => d, DLYCE => '0', DLYINC => '0', DLYRST => '0', OCLK => oclk,
      REV => '0', SHIFTIN1 => '0', SHIFTIN2 => '0', SR => sr
    );

  stim : process
    variable checks : integer := 0;
    variable pat : std_logic_vector(31 downto 0) := x"A5C33C96";

    procedure check(h, v : std_ulogic; what : string) is
    begin
      checks := checks + 1;
      assert h = v
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(v)
        severity failure;
    end procedure;

    -- D changes, then the clock. The Verilog sampler reads o_delay,
    -- which is a nonblocking copy of D, so D has to be stable before
    -- the edge or the copy loses the race.
    procedure edge(bit : std_ulogic; rise : boolean; div_rise : boolean) is
    begin
      d <= bit;
      wait for 1 ns;
      if rise then
        clk <= '1';
        oclk <= '1';
        if div_rise then
          clkdiv <= '1';
        end if;
      else
        clk <= '0';
        oclk <= '0';
      end if;
      wait for step;
    end procedure;
  begin
    wait for 120 ns;
    sr <= '1';
    clk <= '1';
    oclk <= '1';
    clkdiv <= '1';
    wait for step;
    clk <= '0';
    oclk <= '0';
    wait for step;
    clkdiv <= '0';
    sr <= '0';
    wait for step;
    for e in 0 to 31 loop
      edge(pat(e), e mod 2 = 0, e mod 4 = 0);
      if e mod 4 = 3 then
        wait for step;
        check(q1_h, q1_v, "net q1");
        check(q2_h, q2_v, "net q2");
        check(q3_h, q3_v, "net q3");
        check(q4_h, q4_v, "net q4");
        check(q5_h, q5_v, "net q5");
        check(q6_h, q6_v, "net q6");
        check(qm1_h, qm1_v, "mem q1");
        check(qm2_h, qm2_v, "mem q2");
        check(qm3_h, qm3_v, "mem q3");
        check(qm4_h, qm4_v, "mem q4");
        clkdiv <= '0';
        wait for step;
      end if;
    end loop;
    report "PASS tb_eq_serdes checks=" & integer'image(checks);
    finish;
  end process;
end architecture sim;
