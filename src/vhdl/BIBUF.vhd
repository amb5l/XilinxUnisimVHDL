-- BIBUF. The Verilog copies each side to the other after 10 ps with
-- a weak1/weak0 strength. std_logic has no weak strength, so both
-- drivers are strong: a value driven on one side with the other
-- released appears on both pins, and opposite drivers resolve to X.
-- See docs/vhdl-models.md.

library ieee;
use ieee.std_logic_1164.all;

entity BIBUF is
  port (
    IO : inout std_logic;
    PAD : inout std_logic
  );
end entity BIBUF;

architecture sim of BIBUF is
  signal io_d : std_logic := 'Z';
  signal pad_d : std_logic := 'Z';
begin
  io_d <= IO after 10 ps;
  pad_d <= PAD after 10 ps;
  IO <= pad_d;
  PAD <= io_d;
end architecture sim;
