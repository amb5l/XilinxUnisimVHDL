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

- `IOBUF*` and `BIBUF` are native VHDL in the fourth batch. Their
  Verilog models are not an equivalence reference: NVC will not
  elaborate an `inout` port.
- `PULLUP`, `PULLDOWN`, and `KEEPER` drive weak or pull strengths.
  `std_ulogic` cannot represent them.
- `OBUFDS_DPHY` is a supply-strength LP/HS state machine.
- `IBUFDS_DPHY`, `IBUFDS_GTE2`, `IBUFDS_GTE3`, `IBUFDS_GTE4`,
  `IBUFDS_GTM`, `IBUFE3`, `IBUFDSE3`, `OBUFDS_GTE3_ADV`,
  `OBUFDS_GTE4_ADV`, and `OBUFDS_GTM` are larger than this batch
  (extra clocks, a vector data input, or an RXRECCLK select) and stay
  `vlog`. `INBUF`, `DIFFINBUF`, `DPHY_DIFFINBUF`, and `IBUFCTRL` are
  the seventh batch.

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

## Fourth batch

`BIBUF`, `IOBUF`, `IOBUF_ANALOG`, `IOBUF_DCIEN`, `IOBUF_INTERMDISABLE`,
`IOBUFDS`, `IOBUFDS_DCIEN`, `IOBUFDS_DIFF_OUT`,
`IOBUFDS_DIFF_OUT_DCIEN`, `IOBUFDS_DIFF_OUT_INTERMDISABLE`,
`IOBUFDS_INTERMDISABLE`, `IOBUFDSE3`, `IOBUFE3`.

Scalar `inout` ports are `std_logic`. The model drives `'Z'` when its
output buffer is disabled, and the pad signal resolves that driver with
whatever the testbench drives. There is no drive strength. NVC cannot
elaborate the Verilog `inout` models, so `test/tb/tb_iobuf.vhd` is
self-checking: the expected value is the equation below, not a second
simulation. The bench drives both directions over `0`, `1`, `X`, and
`Z`, including contention, and waits 1 ns so the local `GTS` is 0.
`DQS_BIAS` and `USE_IBUFDISABLE` are the generics directly; the Verilog
copies them into a reg after 1 ps.

`bufif0` and `notif0` are the NVC primitives (enable 0 passes or
inverts, and `Z` data stays `Z` on `bufif0`; any other enable drives
`Z`). `buf` maps `Z` to `X`. A Verilog `en ? 'Z' : data` is not
`bufif0`: an `X` or `Z` enable merges the branches, so both sides `Z`
stays `Z` and any other pair is `X`. `~T || IBUFDISABLE` is `not T or
IBUFDISABLE`. `sel == 1 ? a : sel == 0 ? b : X` (and the `===` form) is
`a` or `b` for 0 and 1, and `X` otherwise.

- `IOBUF`. `or(ts, GTS, T); bufif0(IO, I, ts); buf(O, IO)`. `O` is `buf`
  of the resolved pad, so an external `Z` is `X` on `O`. Contention of
  a driven 1 with an external 0 is `X`.
- `IOBUF_ANALOG`. `I` and `T` pass through `rv 1` (`Z` becomes 1) and
  then `IO = ~T_in ? I_in : 'Z'`. `T` of `Z` disables. `I` of `Z` is
  driven as 1. `O` is the resolved pad, so `Z` passes. No `GTS`.
- `IOBUF_DCIEN` and `IOBUF_INTERMDISABLE`. The pad driver is `IOBUF`.
  `DCITERMDISABLE` and `INTERMDISABLE` are not read by the functional
  assign. `USE_IBUFDISABLE` true:
  `O = (~T || IBUFDISABLE) == 1 ? out_val : == 0 ? IO : X`. `out_val`
  is 1 for `7SERIES` and 0 otherwise, so a disabled input does not
  follow the pad. `USE` false: `O` is the resolved pad.
- `IOBUFDS`. `IO = (GTS || T) ? 'Z' : I` and `IOB = (GTS || T) ? 'Z' : ~I`
  (the ternary, so an `X` enable merges). `O` is the differential
  receiver. The `X` arm is `IO === X || IOB == X`, and `==` never
  matches `X`, so `X` on `IOB` alone holds the previous value. `X` on
  `IO` forces `X`.
- `IOBUFDS_DCIEN` and `IOBUFDS_INTERMDISABLE`. Same pad drivers.
  `DCITERMDISABLE` and `INTERMDISABLE` are unused functionally. The
  receiver uses `===` on both pins. `USE_IBUFDISABLE` true:
  `O = (~T || IBUFDISABLE) === 1 ? out_val : === 0 ? receiver : X`,
  with the same `out_val` as `IOBUF_DCIEN`.
- `IOBUFDS_DIFF_OUT`. Separate enables: `bufif0(IO, I, GTS or TM)` and
  `notif0(IOB, I, GTS or TS)`. The receiver drives `X` when no row
  matches; it does not hold. `OB` is `~` of the bit written to `O`.
- `IOBUFDS_DIFF_OUT_DCIEN` and `IOBUFDS_DIFF_OUT_INTERMDISABLE`. Same
  drivers and receiver. The disable ports are unused functionally.
  `USE_IBUFDISABLE` true applies `~TM || IBUFDISABLE` to `O` and
  `~TS || IBUFDISABLE` to `OB`. The forced pair is 1/1 for `7SERIES`,
  0/`X` for `ULTRASCALE`, and 0/0 otherwise.
- `IOBUFE3`. `bufif0(IO, I, GTS or T)`. The functional delays are 0.
  `ULTRASCALE` and `ULTRASCALE_PLUS` use `OSC`; every other legal
  `SIM_DEVICE` forces `OSC` and `OSC_EN` to 0 (the Verilog flag is 0
  for UltraScale and 1 for Versal). `OSC[2:0] * 5` is negated when
  `OSC[3]` is 0. Compared with `SIM_INPUT_BUFFER_OFFSET`: negative
  yields 0, positive yields 1, and zero toggles `O_OSC` once per
  `OSC`/`OSC_EN` change. It does not free-run. A non-binary magnitude
  holds. `USE_IBUFDISABLE` false (the default): `O = OSC_EN ? O_OSC : IO`.
  `USE` true: `O` follows that mux when `~T || IBUFDISABLE` is 0, is 0
  when the flag is 1 and `OSC_EN` is 0, and is `X` otherwise.
  `VREF` and `DCITERMDISABLE` are not in the equation. `DRIVE` must be
  2 to 24 and the offset -50 to 50.
- `IOBUFDSE3`. `bufif0(IO, I, GTS or T)` and `notif0(IOB, I, same ts)`.
  `OSC_EN` is two bits: `11` selects `O_OSC`, `01` and `10` drive `X`,
  and any other value (including `00` and `X`) selects the receiver.
  The oscillator updates only when `OSC_EN == 1`, which is the vector
  `01`. `USE_IBUFDISABLE` true and `~T || IBUFDISABLE == 1` forces the
  receiver to 0; an `X` flag forces `X`. The `X` arm is `===` on both
  pins. `DCITERMDISABLE` is unused. The default `USE_IBUFDISABLE` is
  false, so the receiver runs.
- `BIBUF`. The Verilog copies each side to the other after 10 ps
  (`timescale 1 ps`) with strength `(weak1, weak0)`. A weak driver
  loses to a strong opposite value, so each pin would keep its own
  strong driver. `std_logic` cannot say weak. The model drives both
  ways at full strength, delayed 10 ps, initial driver `'Z'`. A value
  driven on one side with the other released appears on both pins.
  Releasing both external drivers leaves that value: the model's own
  drivers are strong, so they hold it. Two opposite drivers resolve
  to `X`, and releasing them afterwards leaves `X`, because those
  drivers are part of the resolution. `tb_iobuf` expects this
  strong-driver behaviour, not the weak-strength result.

## Fifth batch

`SRL16E`, `SRLC16E`, `SRLC32E`, `RAM32X1S`, `RAM32X1D`, `RAM64X1S`,
`RAM64X1D`, `RAM128X1S`, `RAM128X1D`, `RAM256X1S`, `RAM256X1D`,
`RAM512X1S`, `RAM32M`, `RAM32M16`, `RAM32X16DR8`, `RAM64M`, `RAM64M8`,
`RAM64X8SW`. `test/tb/tb_eq_ram.vhd` compares each one with the submodule
Verilog. None of these cells uses GSR.

`SRL16E` shifts `{data[14:0], D}` on the rising edge of `CLK`, or the
falling edge when `IS_CLK_INVERTED` is 1. `CE` of 1 or Z shifts; `CE` of
0 or X does not. `Q` is `data` at `{A3,A2,A1,A0}`, and a non-0/1 address
bit reads X. `SRLC16E` adds `Q15 = data(15)`. `SRLC32E` uses a vector
address and `Q31 = data(31)`. The Verilog forces `INIT` onto the shift
register until a 1 ns poll has seen `CLK` at its idle level (0, or 1
when the clock is inverted), or until 101 ns. A 100 ps pulse between
polls does not release the force and does not shift. The specify path
`(CLK => Q) = 100 ps` is not applied by this NVC, so `Q` updates on the
shift.

The single-port and dual-port `RAM*X1S` / `RAM*X1D` cells write
`mem[A] <= #100 D` on the rising edge of `WCLK xor IS_WCLK_INVERTED`,
and only when `rv1(WE)` is 1. `WE` of Z writes. `WE` of X does not. The
address is the pin value in that same delta, so a testbench that
changes `A` and `WCLK` together writes the new address. The 100 ps
delay is the functional delay at a 1 ps timescale, modeled with
`transport` so a second write inside that window does not drop the
first. A non-0/1 address bit reads X, and a write at that address does
not change the memory. The read port of a dual-port cell is
combinational and is not the write address.

`RAM32M` and `RAM32M16` store a pair. `DI(0)` is written at the even
bit `2*ADDR` and `DI(1)` at the odd bit, delayed 100 ps. The write
index is assigned from `always @(ADDRD)` or `always @(ADDRH)`. That
block does not run while the address is constant from time 0, so a
write before the address changes does not land. Reads are
combinational and do not use that copy. `RAM64M` and `RAM64M8` are one
bit wide and index the write address directly, so they do not need
that change. `RAM32X16DR8` has no `INIT`. Its memories are Verilog
regs and therefore start at X. `DOA` through `DOG` read one bit at a
6-bit address. `DOH` reads the pair at `ADDRH`, with the same even/odd
mapping.

`RAM64X8SW` writes one of eight memories, selected by `WSEL` from
`111` (`mem_a`, `O(7)`) down to `000` (`mem_h`, `O(0)`). Any other
code, including X, writes nothing. The write is not delayed. `O` is a
reg, so it stays X until `A` changes or 100 ps have passed. A write
before that publishes only the written bit.

Block RAM (`RAMB*`) is not part of this batch. The SIMPRIM
`$finish` RAMs are the seventh batch.

## Sixth batch

`MUXCY`, `MUXF9`, and `CARRY8`. `MUXF7`, `MUXF8`, and `CARRY4` were
already VHDL. `MUXF9` is the same select as `MUXF7`: `S` of 1 chooses
`I1` and every other value, including `X` and `Z`, chooses `I0`.
`MUXCY` chooses `CI` only when `S` is 1 and `DI` otherwise. `tb_eq`
sweeps both with the `MUXF7` stimulus.

`CARRY8` is the eight-bit form of `CARRY4`. `CI`, `CI_TOP`, `DI`, and
`S` pass through `rv 0`, so `Z` becomes 0 and `X` stays `X`.
`O = S xor CO_fb` and `CO = (S and CO_fb) or (not S and DI)`, with
`CO_fb = {CO[6:4], CI_TOP_in, CO[2:0], CI}`. `SINGLE_CY8` (the
default) uses `CO(3)` as `CI_TOP_in`, so `CI_TOP` is ignored.
`DUAL_CY4` uses `CI_TOP` and the chain splits into two nibbles. Any
other `CARRY_TYPE` makes the Verilog `$finish`; the model uses the
single chain, which is also the parameter's fallback. The Verilog
copies `CARRY_TYPE` into a reg 2 ps after time 0. `tb_eq` compares
after that, over every binary `S`/`DI` word with `CI` and `CI_TOP` at
0 and 1, then the `X` and `Z` cases.

## Seventh batch

The SIMPRIM cells whose Verilog executes `$finish` when `XIL_TIMING`
is undefined. This pin has 22 of them. `LUTCY1`, `LUTCY2`, `LCLK_DELAY`,
`RAMD64E5`, and `RAMS64E5` are not in the submodule. This batch is the
RAMs and the input buffers. `DSP_*` stays with the DSP batch.
`BUFCE_ROW` stays with the clock buffers. `HBM_*` stays later.

`RAMD32` and `RAMS32` write on the rising edge of `CLK xor
IS_CLK_INVERTED` when `rv 1` of `WE` is 1, with no transport delay.
`Z` on `WE` writes and `X` does not. A non-binary address reads `X`
and the write is ignored. `RAMD64E`, `RAMS64E`, and `RAMS64E1` add
the address-space compare on `WADR6` and up: a mask bit of 0 requires
that write-address bit to equal the space bit. `RAMD32M64` has an
empty behavioral model, so `O` stays `Z`.

`IBUFCTRL` passes `I` through when `USE_IBUFDISABLE` is false. When it
is true, `O` is `I` if `not T or IBUFDISABLE` is 0, `0` if that is 1,
and `X` otherwise. `INTERMDISABLE` is unused. `INBUF` follows `PAD`
unless `OSC_EN` is 1, which selects the offset oscillator already used
by `IOBUFE3`. `DIFFINBUF` is that oscillator plus the `IBUFDS`
receiver. `DPHY_DIFFINBUF` resolves the HS pair the same way. Its LP
outputs are 0: the Verilog enables them only for Strong strength, and
`std_ulogic` has no strength.

`tb_eq_simprim` analyses the Verilog with `-D XIL_TIMING`. NVC accepts
the specify blocks and the simulation runs. `$setuphold` does not drive
the delayed data and clock nets, so a RAM write in that elaboration
never happens and it is not a functional reference. The RAM checks are
self-checking. `IBUFCTRL`, the `DIFFINBUF` receiver, `INBUF` with
`OSC_EN` held at 0, and the empty `RAMD32M64` do not depend on those
nets and are compared with the Verilog. The oscillator is self-checked.
`DPHY_DIFFINBUF` calls `$sformat`, which this NVC does not implement, so
that reference aborts and the cell is self-checked.

## Eighth batch

Clock buffers: `BUFCE_LEAF`, `BUFCE_ROW`, `BUFGCE`, `BUFGCE_DIV`,
`BUFGCTRL`, `BUFG_GT`, `BUFG_GT_SYNC`, `BUFG_PS`, `BUFHCE`, `BUFIO`,
`BUFMR`, `BUFMRCE`, and `BUFR`. `BUFIO` and `BUFMR` are a `buf`.
`BUFG_GT_SYNC` drives `CESYNC` with rv 1 and `CLRSYNC` with rv 0.

`BUFCE_LEAF` keeps an enable that GSR forces to 1. `ASYNC` copies `CE`
whenever GSR is low. `SYNC` copies `CE` only while `I` is 0. `O` is
that enable and `I`. `BUFCE_ROW` is the same cell with `HARDSYNC`
accepted; `HARDSYNC` is not `ASYNC`, so it matches `SYNC`. The Verilog
`$finish` is not in the model.

`BUFGCE` starts with the enable at 0. `SYNC` samples `CE` while `I` is
0, `ASYNC` follows `CE`, and `HARDSYNC` samples `ce_sync(2)` after three
rising edges. `STARTUP_SYNC` uses that same shifter on `not GSR` and is
honoured on every `SIM_DEVICE`. `BUFG_PS` latches `not GSR` while `I` is
0 and forces `STARTUP_SYNC` off unless `SIM_DEVICE` is `VERSAL*`.

`BUFGCTRL` is the mux those enables are built from. `CE`, `S`, and
`IGNORE` are rv 0 of the optional invert, so `Z` is 0 and is not
inverted. The `qb` latches and the `CE` delay into a `HARDSYNC` shifter
are 1 ps. `HARDSYNC` and `STARTUP_SYNC` are forced off unless
`SIM_DEVICE` is `VERSAL*`. `glbl.GRESTORE` is reproduced locally: low,
high from 10 ns to 20 ns, then low. `BUFHCE` is two `BUFGCTRL` cells
with `I1` tied to 0 and 1; `ASYNC` drives `IGNORE0`. `BUFMRCE` is the
same structure with `IGNORE0` tied to 0, so `CE_TYPE` has no effect,
and the second cell's `INIT_OUT` generic is 1.

`BUFGCE_DIV` and `BUFG_GT` share the edge counter. Divide value 1 copies
`I` gated by the enable. 2 through 8 (and `BUFG_GT` `DIV` `001` through
`111`) toggle on the counts in the Verilog case. `GSR` holds the counter
at 0. A non-versal `BUFG_GT` synchronises `CE` and `not CLR` for two
rising edges and delays `O` by 1 ps. `VERSAL*` skips both. `BUFR`
`BYPASS` is a `buf`. `"1"` through `"8"` count edges of `I` while `CE`
is 1. `VIRTEX4` uses the four-stage `CE` pipeline; `7SERIES`, `VIRTEX5`,
and `VIRTEX6` use `CE` directly.

`tb_eq_bufg` compares the VHDL with the Verilog after the 100 ns ROC.
`BUFCE_ROW` is the SIMPRIM `$finish` cell in this batch. Analysing it
with `-D XIL_TIMING` is accepted, and the simulation runs, but `O` stays
at X: the specify targets `I_delay` and `CE_delay` are not driven. Without
the define the model executes `$finish`. `BUFCE_ROW` is checked against
`BUFCE_LEAF` instead. `BUFHCE` uses `defparam`, which this NVC does not
elaborate, so that cell is self-checked; `BUFMRCE` passes parameters in
the instance and is compared with the Verilog. `BUFGCE_DIV` values other
than 1 are self-checked: the Verilog chooses the toggle counts in an
`always` that races `BUFGCE_DIVIDE_BIN`, and on this NVC the counts stay
at 1.

## Conventions

- One entity and one architecture per file. The entity name is the
  primitive name.
- Ports are `std_ulogic` or `std_logic_vector`, matching the generator.
  A scalar `inout` is `std_logic` so an external driver resolves with
  the model.
- Generics match the generated component: `bit` for a 1-bit parameter,
  `bit_vector` for a wider one, `boolean` for a `TRUE`/`FALSE` string,
  `integer` or `string` otherwise. Defaults match the component.
- Simulation is zero-delay except where the Verilog functional model
  itself delays an output. `FDRE`, `FDSE`, `FDCE`, and `FDPE` use
  `assign #100 Q = Q_out` at a 1 ps timescale, so `Q` is delayed 100 ps
  even with `XIL_TIMING` undefined. The distributed RAMs use the same
  100 ps on the write, with `transport` delay. `RAM64X8SW` does not.
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

## Ninth batch

`IDDR`, `IDDR_2CLK`, `IDDRE1`, `ODDR`, and `ODDRE1` are the DDR input and
output registers. `Q1` samples on the rising edge. `IDDR` samples `Q2`
on the falling edge; `IDDR_2CLK` and `IDDRE1` sample `Q2` on the rising
edge of `CB`. `OPPOSITE_EDGE` presents each sample on its own edge.
`SAME_EDGE` presents `Q2` on the following rising edge.
`SAME_EDGE_PIPELINED` delays `Q1` by one more rising edge. An unknown
`DDR_CLK_EDGE` holds the outputs. The Verilog `$finish` on a bad
attribute is not implemented.

`IDDR` and `ODDR` pull `R` and `S` down, so `Z` is 0. `ASYNC` forces 0
on `R` and 1 on `S` with `R` clear. `SYNC` applies that on the clock.
`GSR` forces `INIT_Q1` / `INIT_Q2` or `INIT`. `IDDR_2CLK` buffers `CE`,
`R`, and `S`, so `Z` is `X`, and `CB` is rv 1. `IDDRE1` has no clock
enable and no set; `R` is always an async clear to 0. `ODDR` with
`CE` = 0 remembers the current `Q` instead of `D2`. `SAME_EDGE` replays
that remembered value on the falling edge; `OPPOSITE_EDGE` takes `D2`.

`ODDRE1` has no clock enable. `SR` is rv 0 and forces `SRVAL`. On
`ULTRASCALE`, `ULTRASCALE_PLUS`, `ULTRASCALE_PLUS_ES1`, and
`ULTRASCALE_PLUS_ES2` the reset also stays asserted for three rising
edges after `SR` falls. Every other device, including `VERSAL_PRIME`,
treats `SR` as a level. An unknown `SIM_DEVICE` follows the Verilog
`SIM_DEVICE_BIN` fallback and behaves as `ULTRASCALE`.

The specify `(C => Q)` paths are 100 ps. The VHDL models are the
functional value, with no path delay. `tb_eq_ddr` waits two steps after
a clock before comparing: on this NVC a Verilog nonblocking assignment
and the continuous assign to the port each become visible to the VHDL
testbench on the next resume of the stimulus process.

## Adding another primitive

1. Read the Verilog functional model (`XIL_TIMING` undefined). Reimplement
   that behaviour. Do not copy Vivado VHDL.
2. Add `src/vhdl/<NAME>.vhd` with generics and ports matching the
   component in `vcomponents`.
3. Set that row's `lang` to `vhdl` in `config/primitives.txt`
   (`python3 scripts/primitives.py --check` must pass).
4. Extend    `test/tb/tb_eq.vhd` (`EQ_PRIMS`), `test/tb/tb_eq_io.vhd`
   (`EQ_IO_PRIMS`), `test/tb/tb_eq_ff.vhd` (`EQ_FF_PRIMS`),
   `test/tb/tb_eq_ram.vhd` (`EQ_RAM_PRIMS`), `test/tb/tb_eq_simprim.vhd`,
   `test/tb/tb_eq_bufg.vhd`, or `test/tb/tb_eq_ddr.vhd` so the
   VHDL model and the submodule Verilog see the same stimulus.
   Exhaustive for a small combinational cell. For a register, cover
   GSR, clock enable, reset priority, `INIT`, and `IS_*_INVERTED`.
   An `inout` model that NVC cannot elaborate from Verilog is checked
   by `test/tb/tb_iobuf.vhd` instead, against the equations in this
   file.
5. `make test`.

`make` rebuilds library `unisim` without that Verilog file. The
equivalence bench analyses it into library `work` instead, and a
component of the same name binds to that module. NVC prefers a Verilog
module in the instantiating library over a VHDL entity of the same name
in `unisim`.
