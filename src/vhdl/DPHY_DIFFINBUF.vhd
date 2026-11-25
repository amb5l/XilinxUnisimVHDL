-- DPHY_DIFFINBUF. The SIMPRIM $finish under `ifndef XIL_TIMING` is not
-- part of the model. HSRX_O follows the differential pair while
-- HSRX_DISABLE is 0: 1/0 yields 1, 0/1 yields 0, and X or Z yields X.
-- Any other pair holds, starting at X, until an input event. Disable of
-- 1 forces 0. Disable of X or Z forces X.
-- LPRX is the same gate around a 1 ps delayed LP value. The Verilog LP
-- mode is true only when both pins have Strong strength (%v = "S").
-- std_ulogic has no strength, so LP mode is false and both LP bits are 0.
-- DIFF_TERM and ISTANDARD are unused. glbl.GSR is unused.
-- NVC does not implement $sformat, so the Verilog model cannot be elaborated
-- as an equivalence reference.

library ieee;
use ieee.std_logic_1164.all;

entity DPHY_DIFFINBUF is
  generic (
    DIFF_TERM : boolean := TRUE;
    ISTANDARD : string := "DEFAULT"
  );
  port (
    HSRX_O : out std_ulogic;
    LPRX_O_N : out std_ulogic;
    LPRX_O_P : out std_ulogic;
    HSRX_DISABLE : in std_ulogic;
    I : in std_ulogic;
    IB : in std_ulogic;
    LPRX_DISABLE : in std_ulogic
  );
end entity DPHY_DIFFINBUF;

architecture sim of DPHY_DIFFINBUF is
  signal hs : std_ulogic := 'X';
  signal lp_p, lp_n : std_ulogic := 'Z';
begin
  lp_p <= '0' after 1 ps;
  lp_n <= '0' after 1 ps;

  pair : process is
  begin
    wait on I, IB;
    if I = '1' and IB = '0' then
      hs <= '1';
    elsif I = '0' and IB = '1' then
      hs <= '0';
    elsif I = 'X' or IB = 'X' or I = 'Z' or IB = 'Z' then
      hs <= 'X';
    end if;
  end process;

  HSRX_O <= hs when HSRX_DISABLE = '0' else
            'X' when HSRX_DISABLE = 'X' or HSRX_DISABLE = 'Z' else
            '0';
  LPRX_O_P <= lp_p when LPRX_DISABLE = '0' else
              'X' when LPRX_DISABLE = 'X' or LPRX_DISABLE = 'Z' else
              '0';
  LPRX_O_N <= lp_n when LPRX_DISABLE = '0' else
              'X' when LPRX_DISABLE = 'X' or LPRX_DISABLE = 'Z' else
              '0';
end architecture sim;
