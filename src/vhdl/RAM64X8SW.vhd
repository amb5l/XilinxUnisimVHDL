-- RAM64X8SW. Eight 64x1 memories. O(7) is mem_a[A] through O(0) = mem_h[A].
-- WSEL selects one memory: 111 writes mem_a, 110 mem_b, down to 000 mem_h.
-- Any other WSEL, including X, writes nothing. The write is not delayed.
-- WE of Z writes; WE of 0 or X does not. The clock is posedge WCLK, or
-- negedge when IS_WCLK_INVERTED is 1.
-- O_out is a reg, so it stays X until A changes or 100 ps have passed.
-- A write before that publishes only the written bit.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity RAM64X8SW is
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
    O : out std_logic_vector(7 downto 0);
    A : in std_logic_vector(5 downto 0);
    D : in std_ulogic;
    WCLK : in std_ulogic;
    WE : in std_ulogic;
    WSEL : in std_logic_vector(2 downto 0)
  );
end entity RAM64X8SW;

architecture sim of RAM64X8SW is
  signal mem_a : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_A);
  signal mem_b : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_B);
  signal mem_c : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_C);
  signal mem_d : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_D);
  signal mem_e : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_E);
  signal mem_f : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_F);
  signal mem_g : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_G);
  signal mem_h : std_logic_vector(63 downto 0) := to_stdlogicvector(INIT_H);
  signal tick100 : std_ulogic := '0';
  signal o_q : std_logic_vector(7 downto 0) := (others => 'X');
begin
  tick100 <= '1' after 100 ps;
  O <= o_q;

  out_p : process is
    variable prev_a : std_logic_vector(5 downto 0);
  begin
    prev_a := A;
    loop
      wait on mem_a, mem_b, mem_c, mem_d, mem_e, mem_f, mem_g, mem_h, A, tick100;
      if A /= prev_a then
        prev_a := A;
        o_q <= mem_read(mem_a, A) & mem_read(mem_b, A) & mem_read(mem_c, A)
             & mem_read(mem_d, A) & mem_read(mem_e, A) & mem_read(mem_f, A)
             & mem_read(mem_g, A) & mem_read(mem_h, A);
      elsif tick100'event then
        o_q <= mem_read(mem_a, A) & mem_read(mem_b, A) & mem_read(mem_c, A)
             & mem_read(mem_d, A) & mem_read(mem_e, A) & mem_read(mem_f, A)
             & mem_read(mem_g, A) & mem_read(mem_h, A);
      elsif mem_a'event then
        o_q(7) <= mem_read(mem_a, A);
      elsif mem_b'event then
        o_q(6) <= mem_read(mem_b, A);
      elsif mem_c'event then
        o_q(5) <= mem_read(mem_c, A);
      elsif mem_d'event then
        o_q(4) <= mem_read(mem_d, A);
      elsif mem_e'event then
        o_q(3) <= mem_read(mem_e, A);
      elsif mem_f'event then
        o_q(2) <= mem_read(mem_f, A);
      elsif mem_g'event then
        o_q(1) <= mem_read(mem_g, A);
      elsif mem_h'event then
        o_q(0) <= mem_read(mem_h, A);
      end if;
    end loop;
  end process;

  writer : process is
    variable prev : std_ulogic := 'U';
    variable curr : std_ulogic;
    constant sel_a : std_logic_vector(2 downto 0) := "111";
    constant sel_b : std_logic_vector(2 downto 0) := "110";
    constant sel_c : std_logic_vector(2 downto 0) := "101";
    constant sel_d : std_logic_vector(2 downto 0) := "100";
    constant sel_e : std_logic_vector(2 downto 0) := "011";
    constant sel_f : std_logic_vector(2 downto 0) := "010";
    constant sel_g : std_logic_vector(2 downto 0) := "001";
    constant sel_h : std_logic_vector(2 downto 0) := "000";
  begin
    loop
      curr := WCLK xor to_sul(IS_WCLK_INVERTED);
      if verilog_posedge(prev, curr) and rv1(WE) = '1' then
        if WSEL = sel_a then
          ram_write(mem_a, A, D, 0 ps);
        elsif WSEL = sel_b then
          ram_write(mem_b, A, D, 0 ps);
        elsif WSEL = sel_c then
          ram_write(mem_c, A, D, 0 ps);
        elsif WSEL = sel_d then
          ram_write(mem_d, A, D, 0 ps);
        elsif WSEL = sel_e then
          ram_write(mem_e, A, D, 0 ps);
        elsif WSEL = sel_f then
          ram_write(mem_f, A, D, 0 ps);
        elsif WSEL = sel_g then
          ram_write(mem_g, A, D, 0 ps);
        elsif WSEL = sel_h then
          ram_write(mem_h, A, D, 0 ps);
        end if;
      end if;
      prev := curr;
      wait on WCLK;
    end loop;
  end process;
end architecture sim;
