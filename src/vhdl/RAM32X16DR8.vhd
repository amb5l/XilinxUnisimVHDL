-- RAM32X16DR8. Eight 64-bit memories, no INIT, so each bit starts at X.
-- DOA..DOG read one bit at a 6-bit address. DOH reads the pair at ADDRH:
-- DOH(0) is mem_h(2*ADDRH) and DOH(1) is mem_h(2*ADDRH+1).
-- A write stores DI(0) at the even bit and DI(1) at the odd bit of every
-- memory, delayed 100 ps, when rv1(WE) is 1. The write index is copied from
-- ADDRH by always @(ADDRH), which does not run while ADDRH is constant from
-- time 0. An X address reads X and does not write.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAM32X16DR8 is
  generic (
    IS_WCLK_INVERTED : bit := '0'
  );
  port (
    DOA : out std_ulogic;
    DOB : out std_ulogic;
    DOC : out std_ulogic;
    DOD : out std_ulogic;
    DOE : out std_ulogic;
    DOF : out std_ulogic;
    DOG : out std_ulogic;
    DOH : out std_logic_vector(1 downto 0);
    ADDRA : in std_logic_vector(5 downto 0);
    ADDRB : in std_logic_vector(5 downto 0);
    ADDRC : in std_logic_vector(5 downto 0);
    ADDRD : in std_logic_vector(5 downto 0);
    ADDRE : in std_logic_vector(5 downto 0);
    ADDRF : in std_logic_vector(5 downto 0);
    ADDRG : in std_logic_vector(5 downto 0);
    ADDRH : in std_logic_vector(4 downto 0);
    DIA : in std_logic_vector(1 downto 0);
    DIB : in std_logic_vector(1 downto 0);
    DIC : in std_logic_vector(1 downto 0);
    DID : in std_logic_vector(1 downto 0);
    DIE : in std_logic_vector(1 downto 0);
    DIF : in std_logic_vector(1 downto 0);
    DIG : in std_logic_vector(1 downto 0);
    DIH : in std_logic_vector(1 downto 0);
    WCLK : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAM32X16DR8;

architecture sim of RAM32X16DR8 is
  signal mem_a : std_logic_vector(63 downto 0) := (others => 'X');
  signal mem_b : std_logic_vector(63 downto 0) := (others => 'X');
  signal mem_c : std_logic_vector(63 downto 0) := (others => 'X');
  signal mem_d : std_logic_vector(63 downto 0) := (others => 'X');
  signal mem_e : std_logic_vector(63 downto 0) := (others => 'X');
  signal mem_f : std_logic_vector(63 downto 0) := (others => 'X');
  signal mem_g : std_logic_vector(63 downto 0) := (others => 'X');
  signal mem_h : std_logic_vector(63 downto 0) := (others => 'X');
  signal wr_even : integer := -1;
  signal wr_odd : integer := -1;
begin
  DOA <= mem_read(mem_a, ADDRA);
  DOB <= mem_read(mem_b, ADDRB);
  DOC <= mem_read(mem_c, ADDRC);
  DOD <= mem_read(mem_d, ADDRD);
  DOE <= mem_read(mem_e, ADDRE);
  DOF <= mem_read(mem_f, ADDRF);
  DOG <= mem_read(mem_g, ADDRG);
  DOH <= mem_pair(mem_h, ADDRH);
  arm : process (ADDRH) is
    variable seen : boolean := false;
    variable a : integer;
  begin
    if seen then
      a := bit_addr(ADDRH);
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
        ram_write_at(mem_e, wr_even, DIE(0), 100 ps);
        ram_write_at(mem_e, wr_odd, DIE(1), 100 ps);
        ram_write_at(mem_f, wr_even, DIF(0), 100 ps);
        ram_write_at(mem_f, wr_odd, DIF(1), 100 ps);
        ram_write_at(mem_g, wr_even, DIG(0), 100 ps);
        ram_write_at(mem_g, wr_odd, DIG(1), 100 ps);
        ram_write_at(mem_h, wr_even, DIH(0), 100 ps);
        ram_write_at(mem_h, wr_odd, DIH(1), 100 ps);
      end if;
      prev := curr;
      wait on WCLK;
    end loop;
  end process;
end architecture sim;
