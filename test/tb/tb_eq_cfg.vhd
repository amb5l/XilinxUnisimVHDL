-- EFUSE_USR, DCIRESET, DNA_PORT and DNA_PORTE2 against the submodule
-- Verilog. XIL_TIMING is left undefined. The 100 ps DNA specify path
-- is not copied; the bench waits 5 ns after the clock. DCIRESET's
-- 100 ns LOCKED rise is the functional delay and is compared.
-- DNA_PORTE2 does not $finish on an out-of-range SIM_DNA_VALUE.

library ieee;
use ieee.std_logic_1164.all;
use std.env.all;

library unisim;

entity tb_eq_cfg is
end entity tb_eq_cfg;

architecture sim of tb_eq_cfg is
  constant dna57 : bit_vector(56 downto 0) :=
    "110000000000000000000000000000000000000000000000000000001";
  constant dna96 : bit_vector(95 downto 0) := X"800000000000000000000003";
  constant fuse : bit_vector(31 downto 0) := X"A5A55A5A";

  signal clk : std_ulogic := '0';
  signal din, rd, sh : std_ulogic := '0';
  signal dout_h, dout_v, dout2_h, dout2_v : std_ulogic;
  signal rst : std_ulogic := '0';
  signal locked_h, locked_v : std_ulogic;
  signal fuse_h, fuse_v : std_logic_vector(31 downto 0);

  component EFUSE_USR is
    generic (SIM_EFUSE_VALUE : bit_vector(31 downto 0) := X"00000000");
    port (EFUSEUSR : out std_logic_vector(31 downto 0));
  end component;

  component DCIRESET is
    port (LOCKED : out std_ulogic; RST : in std_ulogic);
  end component;

  component DNA_PORT is
    generic (
      SIM_DNA_VALUE : bit_vector(56 downto 0) :=
        "000000000000000000000000000000000000000000000000000000000"
    );
    port (
      DOUT : out std_ulogic;
      CLK, DIN, READ, SHIFT : in std_ulogic
    );
  end component;

  component DNA_PORTE2 is
    generic (
      SIM_DNA_VALUE : bit_vector(95 downto 0) := X"000000000000000000000000"
    );
    port (
      DOUT : out std_ulogic;
      CLK, DIN, READ, SHIFT : in std_ulogic
    );
  end component;
begin
  u_fuse_h : entity unisim.EFUSE_USR
    generic map (SIM_EFUSE_VALUE => fuse)
    port map (EFUSEUSR => fuse_h);
  u_fuse_v : EFUSE_USR
    generic map (SIM_EFUSE_VALUE => fuse)
    port map (EFUSEUSR => fuse_v);

  u_dci_h : entity unisim.DCIRESET
    port map (LOCKED => locked_h, RST => rst);
  u_dci_v : DCIRESET
    port map (LOCKED => locked_v, RST => rst);

  u_dna_h : entity unisim.DNA_PORT
    generic map (SIM_DNA_VALUE => dna57)
    port map (DOUT => dout_h, CLK => clk, DIN => din, READ => rd, SHIFT => sh);
  u_dna_v : DNA_PORT
    generic map (SIM_DNA_VALUE => dna57)
    port map (DOUT => dout_v, CLK => clk, DIN => din, READ => rd, SHIFT => sh);

  u_e2_h : entity unisim.DNA_PORTE2
    generic map (SIM_DNA_VALUE => dna96)
    port map (DOUT => dout2_h, CLK => clk, DIN => din, READ => rd, SHIFT => sh);
  u_e2_v : DNA_PORTE2
    generic map (SIM_DNA_VALUE => dna96)
    port map (DOUT => dout2_v, CLK => clk, DIN => din, READ => rd, SHIFT => sh);

  stim : process
    variable checks : integer := 0;

    procedure check(h, v : std_ulogic; what : string) is
    begin
      checks := checks + 1;
      if h /= v then
        report what & " vhdl=" & to_string(h) & " vlog=" & to_string(v)
          & " at " & time'image(now) severity failure;
      end if;
    end procedure;

    procedure edge(v : std_ulogic) is
    begin
      clk <= '0';
      wait for 1 ns;
      clk <= '1';
      wait for 5 ns;
      check(dout_h, dout_v, "dna");
      check(dout2_h, dout2_v, "dnae2");
      if dout_h /= v then
        report "dna expected " & to_string(v) & " got " & to_string(dout_h)
          severity failure;
      end if;
    end procedure;
  begin
    wait for 10 ns;
    if fuse_h /= to_stdlogicvector(fuse) or fuse_v /= to_stdlogicvector(fuse) then
      report "efuse mismatch" severity failure;
    end if;
    checks := checks + 32;

    -- RST starts low. LOCKED rises 100 ns later, falls in the same
    -- delta as RST, and rises again 100 ns after RST falls.
    wait for 100 ns;
    check(locked_h, locked_v, "dci rise");
    if locked_h /= '1' then
      report "dci did not rise" severity failure;
    end if;
    rst <= '1';
    wait for 1 ns;
    if locked_h /= '0' then
      report "dci did not fall" severity failure;
    end if;
    -- The Verilog is #(100 ns, 0 ns). On this NVC the fall takes the
    -- rise delay as well, so LOCKED is still 1 here. Both are 0 after
    -- 100 ns. Left as a possible NVC bug; the VHDL keeps the 0 ns fall.
    wait for 110 ns;
    check(locked_h, locked_v, "dci reset");
    rst <= '0';
    wait for 50 ns;
    check(locked_h, locked_v, "dci early");
    if locked_h /= '0' then
      report "dci rose early" severity failure;
    end if;
    wait for 60 ns;
    check(locked_h, locked_v, "dci late");
    if locked_h /= '1' then
      report "dci did not rise again" severity failure;
    end if;

    -- READ presents the top bit. SHIFT then walks the word. DIN is
    -- changed a nanosecond before the edge.
    rd <= '1';
    sh <= '0';
    din <= '0';
    edge('1');
    rd <= '0';
    sh <= '1';
    for i in 55 downto 0 loop
      din <= '0';
      edge(to_stdulogic(dna57(i)));
    end loop;
    -- The bit shifted in on the first SHIFT has now reached DOUT.
    din <= '1';
    edge('0');

    -- E2 walks LSB first. The loop above already checked it against
    -- the Verilog on every edge. Spot-check the first bit after a
    -- fresh READ: LSB of dna96 is 1.
    rd <= '1';
    sh <= '0';
    edge('1');
    if dout2_h /= '1' then
      report "dnae2 read lsb" severity failure;
    end if;

    report "PASS tb_eq_cfg checks=" & integer'image(checks);
    finish;
  end process;
end architecture sim;
