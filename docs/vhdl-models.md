# VHDL primitive models

The files in `src/vhdl/<NAME>.vhd` are hand-written VHDL-2008 models. They
are derived from the Apache-2.0 Verilog in the `XilinxUnisimLibrary`
submodule (functional model, `XIL_TIMING` and `XIL_DR` undefined). They
are not copies of Vivado's VHDL unisim sources, and those sources are
not in this repository.

`config/primitives.txt` marks a converted primitive `vhdl`. `make` then
analyses `src/vhdl/<NAME>.vhd` and does not analyse that primitive's
Verilog, so the name exists once in library `unisim`. The component in
`generated/unisim_vcomponents.vhd` still comes from the Verilog header.

## First batch

24 primitives:

`BUF`, `INV`, `BUFG`, `IBUF`, `OBUF`, `OBUFT`, `VCC`, `GND`, `AND2B1L`,
`OR2L`, `XORCY`, `MUXF7`, `MUXF8`, `LUT1`, `LUT2`, `LUT3`, `LUT4`,
`LUT5`, `LUT6`, `FDRE`, `FDSE`, `FDCE`, `FDPE`, `CARRY4`.

This pin of the submodule has no `AND2`, `OR2`, `XOR2`, `NAND*`, `NOR*`,
`XNOR*`, or `IBUFG`. The gate cells that do exist are `AND2B1L`, `OR2L`,
and `XORCY`.

## Conventions

- One entity and one architecture per file. The entity name is the
  primitive name.
- Ports are `std_ulogic` or `std_logic_vector`, matching the generator.
- Generics match the generated component: `bit` for a 1-bit parameter,
  `bit_vector` for a wider one, `boolean` for a `TRUE`/`FALSE` string,
  `integer` or `string` otherwise. Defaults match the component.
- Simulation is zero-delay except where the Verilog functional model
  itself delays an output. `FDRE`, `FDSE`, `FDCE`, and `FDPE` use
  `assign #100 Q = Q_out` at a 1 ps timescale, so `Q` is delayed 100 ps
  even with `XIL_TIMING` undefined.
- `X` and `Z` follow the Verilog primitives (`buf` maps `Z` to `X`, LUT
  UDPs, `MUXF7`/`MUXF8` select `I0` unless `S` is 1, `CARRY4` treats `Z`
  on `CI`/`CYINIT` as 0).

Helpers that are not primitives live in `src/vhdl/unisim_sim.vhd`. `make`
analyses that package before the entities.

## GSR and GTS

The Verilog models read `glbl.GSR` and `glbl.GTS`. A VHDL external name
such as `<<signal .glbl.GSR : std_ulogic>>` crashes this NVC
(`missing class_of for T_VERILOG`), so the models do not use one.

Each model that needs GSR or GTS drives a local signal with the same
default timing as `glbl.v`:

- `GSR` is `'1'` from time 0 until 100 ns (`ROC_WIDTH = 100000` ps), then
  `'0'`.
- `GTS` is `'1'`, then `'0'` after 0 ns (`TOC_WIDTH = 0`).

`test/tb/tb_eq.vhd` analyses `glbl.v` into library `work` and elaborates
it next to the bench, which is what a pure Verilog design needs in order
to see `glbl.GSR`. A Verilog module instantiated from VHDL does not see
that net on this NVC: the `tri0` pull-down wins and GSR stays 0. The
equivalence bench therefore checks GSR on the VHDL model (INIT held, gates
forced to 0, a clock during the first 100 ns does not capture) and
compares the two models after GSR has fallen. A testbench cannot pulse
the VHDL GSR again later by driving `glbl.GSR`. `CARRY4` declares
`glbl.GSR` in the Verilog and does not use it; the VHDL model does not
either.

`OBUF` and `OBUFT` use `bufif0`. On NVC that primitive drives `Z` for an
enable of 1, `X`, or `Z`, passes `Z` data through when the enable is 0,
and drives `X` only when the data is `X`. IEEE 1364 `bufif0` instead maps
enabled `Z` data to `X` and an `X` enable to a strength (`L`/`H`). The
model follows NVC so the equivalence bench matches this simulator.

NVC also presents a Verilog `X` on an output port to a VHDL signal as
`'U'`. `tb_eq` treats that `'U'` as `'X'` when it compares. `0`, `1`, and
`Z` cross the language boundary unchanged.

## Adding another primitive

1. Read the Verilog functional model (`XIL_TIMING` undefined). Reimplement
   that behaviour. Do not copy Vivado VHDL.
2. Add `src/vhdl/<NAME>.vhd` with generics and ports matching the
   component in `vcomponents`.
3. Set that row's `lang` to `vhdl` in `config/primitives.txt`
   (`python3 scripts/primitives.py --check` must pass).
4. Extend `test/tb/tb_eq.vhd` and `EQ_PRIMS` in `test/Makefile` so the
   VHDL model and `vref.<NAME>` (the submodule Verilog) see the same
   stimulus. Exhaustive for a small combinational cell. For a register,
   cover GSR, clock enable, reset priority, `INIT`, and `IS_*_INVERTED`.
5. `make test`.

`make` rebuilds library `unisim` without that Verilog file. The
equivalence bench analyses it into library `work` instead, and a
component of the same name binds to that module. NVC prefers a Verilog
module in the instantiating library over a VHDL entity of the same name
in `unisim`.
