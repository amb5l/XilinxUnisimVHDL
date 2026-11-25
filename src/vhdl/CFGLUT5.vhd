-- CFGLUT5. 32-bit shift register addressed as a LUT.
-- O6 is data[I4:I0]. O5 is data[0,I3:I0], so I4 does not affect it.
-- CDO is data[31]. A non-0/1 address bit reads X (a variable select,
-- not the LUT6 "all bits agree" rule). CE must be 1 to shift.
-- The Verilog forces INIT until CLK has been seen at its idle level
-- by a 1 ns poll, or until 101 ns if it never is. XIL_TIMING is off.

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.unisim_sim.all;

entity CFGLUT5 is
  generic (
    INIT : bit_vector(31 downto 0) := X"00000000";
    IS_CLK_INVERTED : bit := '0'
  );
  port (
    CDO : out std_ulogic;
    O5 : out std_ulogic;
    O6 : out std_ulogic;
    CDI : in std_ulogic;
    CE : in std_ulogic;
    CLK : in std_ulogic;
    I0 : in std_ulogic;
    I1 : in std_ulogic;
    I2 : in std_ulogic;
    I3 : in std_ulogic;
    I4 : in std_ulogic
  );
end entity CFGLUT5;

architecture sim of CFGLUT5 is
  function cfg_bit(mem : std_logic_vector; sel : std_ulogic_vector) return std_ulogic is
    variable addr : natural := 0;
  begin
    for i in sel'range loop
      if sel(i) /= '0' and sel(i) /= '1' then
        return 'X';
      end if;
    end loop;
    for i in sel'range loop
      if sel(i) = '1' then
        addr := addr + 2 ** (i - sel'low);
      end if;
    end loop;
    return mem(mem'low + addr);
  end function;

  signal data : std_logic_vector(31 downto 0) := to_stdlogicvector(INIT);
begin
  -- Poll CLK the way the Verilog initial does: every 1 ns, up to 101 ns.
  shift : process
    variable idle : std_ulogic;
    variable ticks : natural := 0;
    variable prev : std_ulogic;
    variable edge : boolean;
    variable mem : std_logic_vector(31 downto 0);
  begin
    if IS_CLK_INVERTED = '0' then
      idle := '0';
    else
      idle := '1';
    end if;
    mem := to_stdlogicvector(INIT);
    data <= mem;
    while CLK /= idle and ticks < 101 loop
      wait for 1 ns;
      ticks := ticks + 1;
    end loop;
    prev := CLK;
    loop
      wait on CLK;
      if IS_CLK_INVERTED = '0' then
        edge := verilog_posedge(prev, CLK);
      else
        edge := verilog_negedge(prev, CLK);
      end if;
      if edge and CE = '1' then
        mem := mem(30 downto 0) & CDI;
        data <= mem;
      end if;
      prev := CLK;
    end loop;
  end process;

  CDO <= data(31);
  O5 <= cfg_bit(data, (0 => I0, 1 => I1, 2 => I2, 3 => I3));
  O6 <= cfg_bit(data, (0 => I0, 1 => I1, 2 => I2, 3 => I3, 4 => I4));
end architecture sim;
