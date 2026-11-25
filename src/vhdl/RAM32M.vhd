-- RAM32M. 32 x 2 quad distributed RAM.
-- Each port is a 32-deep pair: bit 0 is mem(2*ADDR), bit 1 is mem(2*ADDR+1).
-- A write on posedge of (WCLK xor IS_WCLK_INVERTED) stores DI(0) at the even
-- bit of ADDRD and DI(1) at the odd bit, delayed 100 ps, when rv1(WE) is 1.
-- The Verilog copies ADDRD into the write index from always @(ADDRD), which
-- does not run while that address is constant from time 0. Reads are
-- combinational and do not use that copy. An X address reads X and does not write.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAM32M is
  generic (
    INIT_A : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_B : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_C : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_D : bit_vector(63 downto 0) := X"0000000000000000";
    IS_WCLK_INVERTED : bit := '0'
  );
  port (
    DOA : out std_logic_vector(1 downto 0);
    DOB : out std_logic_vector(1 downto 0);
    DOC : out std_logic_vector(1 downto 0);
    DOD : out std_logic_vector(1 downto 0);
    ADDRA : in std_logic_vector(4 downto 0);
    ADDRB : in std_logic_vector(4 downto 0);
    ADDRC : in std_logic_vector(4 downto 0);
    ADDRD : in std_logic_vector(4 downto 0);
    DIA : in std_logic_vector(1 downto 0);
    DIB : in std_logic_vector(1 downto 0);
    DIC : in std_logic_vector(1 downto 0);
    DID : in std_logic_vector(1 downto 0);
    WCLK : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAM32M;

architecture sim of RAM32M is
  signal mem_a : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_A);
  signal mem_b : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_B);
  signal mem_c : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_C);
  signal mem_d : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_D);
  signal wr_even : integer := -1;
  signal wr_odd : integer := -1;
begin
  DOA <= mem_pair(mem_a, ADDRA);
  DOB <= mem_pair(mem_b, ADDRB);
  DOC <= mem_pair(mem_c, ADDRC);
  DOD <= mem_pair(mem_d, ADDRD);
  arm : process (ADDRD) is
    variable seen : boolean := false;
    variable a : integer;
  begin
    if seen then
      a := bit_addr(ADDRD);
      if a < 0 then
        wr_even <= -1;
        wr_odd <= -1;
      else
        wr_even <= 2 * a;
        wr_odd <= 2 * a + 1;
      end if;
    else
      seen := true;
    end if;
  end process;
  writer : process is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
  begin
    loop
      curr := WCLK xor to_sul(IS_WCLK_INVERTED);
      if verilog_posedge(prev, curr) and rv1(WE) = '1' then
        ram_write_at(mem_a, wr_even, DIA(0), 100 ps);
        ram_write_at(mem_a, wr_odd, DIA(1), 100 ps);
        ram_write_at(mem_b, wr_even, DIB(0), 100 ps);
        ram_write_at(mem_b, wr_odd, DIB(1), 100 ps);
        ram_write_at(mem_c, wr_even, DIC(0), 100 ps);
        ram_write_at(mem_c, wr_odd, DIC(1), 100 ps);
        ram_write_at(mem_d, wr_even, DID(0), 100 ps);
        ram_write_at(mem_d, wr_odd, DID(1), 100 ps);
      end if;
      prev := curr;
      wait on WCLK;
    end loop;
  end process;
end architecture sim;
