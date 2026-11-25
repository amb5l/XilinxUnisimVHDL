-- RAM64M8. 64 x 1 octal distributed RAM.
-- Eight or four 64x1 memories. The write address is ADDRH.
-- posedge of (WCLK xor IS_WCLK_INVERTED) stores each DI there, delayed
-- 100 ps, when rv1(WE) is 1. Each DO reads its own address. No GSR.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAM64M8 is
  generic (
    INIT_A : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_B : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_C : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_D : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_E : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_F : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_G : bit_vector(63 downto 0) := X"0000000000000000";
    INIT_H : bit_vector(63 downto 0) := X"0000000000000000";
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
    DOH : out std_ulogic;
    ADDRA : in std_logic_vector(5 downto 0);
    ADDRB : in std_logic_vector(5 downto 0);
    ADDRC : in std_logic_vector(5 downto 0);
    ADDRD : in std_logic_vector(5 downto 0);
    ADDRE : in std_logic_vector(5 downto 0);
    ADDRF : in std_logic_vector(5 downto 0);
    ADDRG : in std_logic_vector(5 downto 0);
    ADDRH : in std_logic_vector(5 downto 0);
    DIA : in std_ulogic;
    DIB : in std_ulogic;
    DIC : in std_ulogic;
    DID : in std_ulogic;
    DIE : in std_ulogic;
    DIF : in std_ulogic;
    DIG : in std_ulogic;
    DIH : in std_ulogic;
    WCLK : in std_ulogic;
    WE : in std_ulogic
  );
end entity RAM64M8;

architecture sim of RAM64M8 is
  signal mem_a : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_A);
  signal mem_b : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_B);
  signal mem_c : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_C);
  signal mem_d : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_D);
  signal mem_e : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_E);
  signal mem_f : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_F);
  signal mem_g : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_G);
  signal mem_h : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_H);
begin
  DOA <= mem_read(mem_a, ADDRA);
  DOB <= mem_read(mem_b, ADDRB);
  DOC <= mem_read(mem_c, ADDRC);
  DOD <= mem_read(mem_d, ADDRD);
  DOE <= mem_read(mem_e, ADDRE);
  DOF <= mem_read(mem_f, ADDRF);
  DOG <= mem_read(mem_g, ADDRG);
  DOH <= mem_read(mem_h, ADDRH);
  writer : process is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
  begin
    loop
      curr := WCLK xor to_sul(IS_WCLK_INVERTED);
      if verilog_posedge(prev, curr) and rv1(WE) = '1' then
        ram_write(mem_a, ADDRH, DIA, 100 ps);
        ram_write(mem_b, ADDRH, DIB, 100 ps);
        ram_write(mem_c, ADDRH, DIC, 100 ps);
        ram_write(mem_d, ADDRH, DID, 100 ps);
        ram_write(mem_e, ADDRH, DIE, 100 ps);
        ram_write(mem_f, ADDRH, DIF, 100 ps);
        ram_write(mem_g, ADDRH, DIG, 100 ps);
        ram_write(mem_h, ADDRH, DIH, 100 ps);
      end if;
      prev := curr;
      wait on WCLK;
    end loop;
  end process;
end architecture sim;
