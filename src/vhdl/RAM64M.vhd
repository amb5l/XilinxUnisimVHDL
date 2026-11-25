-- RAM64M. 64 x 1 quad distributed RAM.
-- Eight or four 64x1 memories. The write address is ADDRD.
-- posedge of (WCLK xor IS_WCLK_INVERTED) stores each DI there, delayed
-- 100 ps, when rv1(WE) is 1. Each DO reads its own address. No GSR.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAM64M is
  generic (
    INIT_A : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_B : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_C : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_D : bit_vector(63 downto 0) := X"0000000000000000";
    IS_WCLK_INVERTED : bit := '0'
  );
  port (
    DOA : out std_ulogic;
    DOB : out std_ulogic;
    DOC : out std_ulogic;
    DOD : out std_ulogic;
    ADDRA : in std_logic_vector(5 downto 0);
    ADDRB : in std_logic_vector(5 downto 0);
    ADDRC : in std_logic_vector(5 downto 0);
    ADDRD : in std_logic_vector(5 downto 0);
    DIA : in std_ulogic;
    DIB : in std_ulogic;
    DIC : in std_ulogic;
    DID : in std_ulogic;
    WCLK : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAM64M;

architecture sim of RAM64M is
  signal mem_a : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_A);
  signal mem_b : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_B);
  signal mem_c : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_C);
  signal mem_d : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_D);
begin
  DOA <= mem_read(mem_a, ADDRA);
  DOB <= mem_read(mem_b, ADDRB);
  DOC <= mem_read(mem_c, ADDRC);
  DOD <= mem_read(mem_d, ADDRD);
  writer : process is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
  begin
    loop
      curr := WCLK xor to_sul(IS_WCLK_INVERTED);
      if verilog_posedge(prev, curr) and rv1(WE) = '1' then
        ram_write(mem_a, ADDRD, DIA, 100 ps);
        ram_write(mem_b, ADDRD, DIB, 100 ps);
        ram_write(mem_c, ADDRD, DIC, 100 ps);
        ram_write(mem_d, ADDRD, DID, 100 ps);
      end if;
      prev := curr;
      wait on WCLK;
    end loop;
  end process;
end architecture sim;
