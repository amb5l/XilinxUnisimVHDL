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

## Second batch

21 more primitives: `AUTOBUF`, `BUFGP`, `BUFH`, `IBUF_ANALOG`,
`IBUF_IBUFDISABLE`, `IBUF_INTERMDISABLE`, `IBUFDS`, `IBUFDS_DIFF_OUT`,
`IBUFDS_IBUFDISABLE`, `IBUFDS_IBUFDISABLE_INT`, `IBUFDS_INTERMDISABLE`,
`IBUFDS_INTERMDISABLE_INT`, `IBUFDS_DIFF_OUT_IBUFDISABLE`,
`IBUFDS_DIFF_OUT_INTERMDISABLE`, `OBUFDS`, `OBUFTDS`, `OBUFT_DCIEN`,
`OBUFTDS_DCIEN`, `OBUFDS_GTE3`, `OBUFDS_GTE4`, `LUT6_2`.

`IBUFDS` resolves a complementary pair to 0 or 1. A `Z`/`0` pin with a
`Z`/`1` pin yields 0 when `DQS_BIAS` is true and `X` otherwise. An `X`
yields `X`. Any other pair holds the previous value, which starts at
`X`. `IBUFDS_DIFF_OUT` is the same receiver except its `X` test is
Verilog `==`, which never matches, so an `X` holds. `OB` is `not` of
the resolved bit. The `*_IBUFDISABLE` cells pass the receiver through
when the disable pin is 0, force a constant when it is 1 (1 on
`7SERIES`, 0 otherwise; the differential-out companion is 1, `X` on
`ULTRASCALE`, or 0), and drive `X` for any other disable value.
`USE_IBUFDISABLE` false passes the receiver through. `INTERMDISABLE`
and `DCITERMDISABLE` are ports in the functional model and are not
read. `IBUF_ANALOG` is a plain assign, so `Z` passes. `AUTOBUF`,
`BUFGP`, and `BUFH` are `buf`.

`OBUFDS` is `bufif0` on `O` and `notif0` on `OB`, enabled by `GTS`.
`OBUFTDS` ors `T` into that enable. `OBUFDS_GTE3` ors in the complement
of `REFCLK_EN_TX_PATH` and `CEB`, so the default generic holds both
outputs at `Z`. `OBUFDS_GTE4` uses a ternary instead of `bufif0`: `Z`
when the path is off, `CEB` is 1, or `GTS` is 1, otherwise `I` (so `Z`
passes) and `not I`. `LUT6_2` is a `LUT6` on `O6` and the lower 32
`INIT` bits as a 5-input LUT on `O5`. The Verilog `O5`/`O6` regs stay
`X` until an input changes; the VHDL model is combinational, so the two
match from the first input event.

`DQS_BIAS` and `USE_IBUFDISABLE` on the differential cells are copied
into a reg with a 1 ps delay in the Verilog. The VHDL model uses the
generic immediately. `tb_eq_io` compares after 1 ns, when that delay
has elapsed and `GTS` has fallen.

`notif0` on NVC inverts when the enable is 0 (`Z` and `X` data become
`X`) and drives `Z` for an enable of 1, `X`, or `Z`.

Left as Verilog this batch, and why:

- `IOBUF*` and `BIBUF` have `inout` ports. NVC elaborates `in` and `out`
  only, so a model of the `bufif0` driver would not elaborate.
- `PULLUP`, `PULLDOWN`, and `KEEPER` drive weak or pull strengths.
  `std_ulogic` cannot represent them.
- `INBUF` and `DIFFINBUF` `$finish` at time 0 when `XIL_TIMING` is
  undefined, so the Verilog reference cannot sit in an equivalence
  bench. The functional path is a small mux, but it is not converted
  until that `$finish` is handled.
- `OBUFDS_DPHY` is a supply-strength LP/HS state machine.
- `IBUFDS_DPHY`, `IBUFDS_GTE2`, `IBUFDS_GTE3`, `IBUFDS_GTE4`,
  `IBUFDS_GTM`, `IBUFE3`, `IBUFDSE3`, `DPHY_DIFFINBUF`, `IBUFCTRL`,
  `OBUFDS_GTE3_ADV`, `OBUFDS_GTE4_ADV`, and `OBUFDS_GTM` are larger than
  this batch (extra clocks, a vector data input, or an RXRECCLK select)
  and stay `vlog`.

## Third batch

`LDCE`, `LDPE`, and `CFGLUT5`.

This pin has no other latch or flop. `FDCE`, `FDPE`, `FDRE`, and `FDSE`
are already VHDL. There is no `FD`, `FDR`, `FDS`, `LD`, or `LUT*_D` /
`LUT*_L`.

`LDCE` and `LDPE` follow the `latchsre` UDP. A row that names an output
drives it, a `-` row holds, and no match drives `X`. `GE` of `Z` enables.
`CLR` or `PRE` of `Z` does not. `GSR` forces `INIT` for 100 ns. The
specify path on `D` and `G` is present even without `XIL_TIMING`; this
NVC does not apply it, so `Q` is not delayed.

`CFGLUT5` is a 32-bit shift register. `O6` reads `data(I4 downto I0)`,
`O5` reads the low 16 bits (`I4` is ignored), and `CDO` is `data(31)`.
An `X` or `Z` address bit reads `X`. `CE` must be 1 to shift on the
clock edge (`negedge` when `IS_CLK_INVERTED`). The Verilog forces `INIT`
until a 1 ns poll has seen `CLK` at its idle level, or until 101 ns.
A pulse shorter than that poll does not shift.

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
4. Extend `test/tb/tb_eq.vhd` (`EQ_PRIMS`), `test/tb/tb_eq_io.vhd`
   (`EQ_IO_PRIMS`), or `test/tb/tb_eq_ff.vhd` (`EQ_FF_PRIMS`) so the
   VHDL model and the submodule Verilog see the same stimulus.
   Exhaustive for a small combinational cell. For a register, cover
   GSR, clock enable, reset priority, `INIT`, and `IS_*_INVERTED`.
5. `make test`.

`make` rebuilds library `unisim` without that Verilog file. The
equivalence bench analyses it into library `work` instead, and a
component of the same name binds to that module. NVC prefers a Verilog
module in the instantiating library over a VHDL entity of the same name
in `unisim`.
