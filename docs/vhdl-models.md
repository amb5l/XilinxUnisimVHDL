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

## Tenth batch

`DSP_PREADD`, `DSP_MULTIPLIER`, `DSP_C_DATA`, `DSP_M_DATA`,
`DSP_A_B_DATA`, `DSP_PREADD_DATA`, `DSP_ALU`, and `DSP_OUTPUT` are the
DSP58 sub-blocks. Each Verilog source `$finish`s unless `XIL_TIMING` is
defined. The VHDL models are the functional behaviour, with no kill
switch and no attribute `$finish`. `DSP48E1` and `DSP48E2` stay Verilog
for the next batch.

`XIL_TIMING` is a usable reference for `DSP_PREADD` and
`DSP_MULTIPLIER`. Their behavioural assigns read the ports, so the
specify paths do not hide the result. `tb_eq_dsp` analyses those two
with `-D XIL_TIMING` and compares them directly. The same netlist does
not work for the registered cells: `C_delay` and the other delay nets
stay undriven, and the reference output stays 0. Those six are
self-checked from the Verilog equations.

`DSP_PREADD` adds or subtracts a 27-bit value and wraps. `INMODE2`
selects `D_DATA`; 0 selects zero; `X` makes the sum `X`.
`DSP_MULTIPLIER` is a signed 27 by 18 product. Even product bits go to `U`
and odd bits go to `V`, with `U(44)` held at 1 and `V(44)` the inverted
sign. `USE_MULT` `"NONE"` forces the product to 0. An unknown
`AMULTSEL`, `BMULTSEL`, or `USE_MULT` falls back to `A`, `B`, or
`MULTIPLY`.

`DSP_C_DATA` and `DSP_M_DATA` register `C`, or `U` and `V`, when the
register generic is 1. `C` is rv 1. `DSP_A_B_DATA` has a two-deep
pipeline. `AREG`/`BREG` of 0 passes the port or the cascade, 1 clocks
the port into stage 2, and 2 clocks stage 1 into stage 2. `A` and `B`
are rv 1. An unknown `A_INPUT` or `B_INPUT` is `DIRECT`. The
`AREG`/`ACASCREG` legality check is not implemented.

`DSP_PREADD_DATA` forces the `D` and `AD` registers off when both
multiplier selects are the direct ports or `USE_MULT` is `"NONE"`.
`DIN` is rv 0. `PREADDINSEL` `"B"` sign-extends `B`. An unknown select
falls back to `A`.

`DSP_ALU` is the W/X/Y/Z mux and the four SIMD slices. `ALU_OUT` is
delayed 1 ps, matching the Verilog. Unless `USE_SIMD` is `ONE48`, `U`
and `V` are replaced by `45'h100000000000`. An unknown `USE_SIMD` is
`ONE48`. The OPMODE DRC is not modelled. `DSP_OUTPUT` registers `P`
when `PREG` is 1. `P_FDBK` is always that register, so it stays 0 when
`PREG` is 0. Pattern detect follows the mask, and an unknown string
attribute falls back to `NO_RESET`, `RESET`, `MASK`, `PATTERN`, or
`NO_PATDET`. `tb_eq_dsp` records 123 checks.

## Eleventh batch

`DSP48E1` and `DSP48E2` are the DSP slices. Neither is a SIMPRIM
`$finish` cell, so `XIL_TIMING` is left undefined. `DSP48E1` still has
a specify block, and those paths are `(0:0:0)`; `$setuphold` is inside
the ifdef. Defining `XIL_TIMING` would undrive the delay nets the
behavioural model reads. `DSP48E2` has no specify block. `tb_eq_dsp48`
compares both with the submodule Verilog.

`DSP48E2` is a structural wrapper of the eight `DSP_*` models. The
wrapper does not replace `U` and `V` itself: `DSP_ALU` does that once.
`CCOUT_FB` is the registered carry fed back to the ALU, and `ALU_OUT`
keeps its 1 ps delay. The `AREG`/`ACASCREG` legality check is not
implemented, so an illegal pair does not `$finish`.

`DSP48E1` is the older 25 by 18 slice. `OPMODE` is seven bits and there
is no W mux. `AREG` 1 clocks the input mux into both A stages; `AREG` 2
clocks stage 1 into stage 2. `PREG` 0 delays `P` by 1 ps. `USE_DPORT`
selects the pre-adder result as the multiplier's A operand. The OPMODE
DRC is not modelled, so an invalid OPMODE does not force pattern detect
to X. `tb_dsp48e1` still multiplies 7 by 9, 25 by 25, 1023 by 17, and
0 by 99. `tb_eq_dsp48` records 28 checks.

## Twelfth batch

`RAMB18E1`, `RAMB36E1`, `RAMB18E2` and `RAMB36E2` are the block RAMs.
None of them is a SIMPRIM `$finish` cell, so `XIL_TIMING` is left
undefined. The E1 specify paths are 100 ps with or without that define,
and the E2 output assignments are delayed 100 ps. Neither delay is
copied: the VHDL value is the functional result, and `tb_eq_bram`
waits 10 ns after the rising edge. Unknown write mode, reset priority,
collision mode, address-collision config and `SIM_DEVICE` do not
`$finish`. An unknown write mode is `WRITE_FIRST`.

The memory is a flat bit vector. Address bits at or above the width's
shift select the word; a non-binary bit there skips the write and
returns `X`. `INIT_00` upwards and `INITP_00` upwards load that vector
in 256-bit chunks. `INIT_FILE` other than `"NONE"` is ignored. Widths
are 1, 2, 4, 9, 18, 36 and, on the 36K cells, 72. Parity bit `i`
belongs to data byte `i`. `WRITE_FIRST` returns the new word,
`READ_FIRST` the old word, and `NO_CHANGE` holds the output while a
byte enable is set. `RSTRAM` loads `SRVAL` into the latch and still
writes. With `DO_*_REG` 1 the output register samples the old latch
first. `RSTREG` wins over `REGCE` unless the priority is `"REGCE"`.

`RAM_MODE` `"SDP"` on the E1 cells, and a 36-bit port on `RAMB18E2` or
a 72-bit port on `RAMB36E2`, makes port A the read and port B the
write. The wide word is split across the two data ports. `DOA_REG`
covers both halves. Same-address collision X is not modelled.
`SIM_COLLISION_CHECK` `"NONE"` is the comparison path.

ECC, the cascade input mux, sleep and address enable are not modelled.
`RAMB36E1` drives `CASCADEOUT` from data bit 0 and holds the ECC ports
at 0. `RAMB18E2` and `RAMB36E2` hold `CASDOUT` at 0, which is the
`CASCADE_ORDER` `"NONE"` result, and `RAMB36E2` holds the ECC ports at
0.

`tb_eq_bram` compares `RAMB18E1` and `RAMB36E1` with the submodule
Verilog, including both ports, the three write modes, widths 1, 4, 9,
18 and 36, the output register, `RSTRAM`, `RSTREG`, `INIT_00` and SDP.
`READ_FIRST` and `NO_CHANGE` use a non-zero `INIT_A`: the Verilog
output reg starts `X` and is copied only when the data mux changes, so
GSR has to make that first transition. `RAMB18E2` and `RAMB36E2`
elaborate, but their read and write loop counts come from
`always @(READ_WIDTH_*_BIN)`, which NVC does not run, so those ports
stay `X`. The bench checks the VHDL against the write-first values the
Verilog describes. `tb_ramb18e1` still writes `A5A5` and reads it back.
`tb_eq_bram` records 61 checks.

## Thirteenth batch

`ISERDES` is the input deserializer. It is not a SIMPRIM `$finish`
cell, so `XIL_TIMING` is left undefined. The rank flops in the Verilog
are delayed 300 ps and the muxes 60 ps. Neither delay is copied. The
IDELAY tap chain (`SIM_TAPDELAY_VALUE`, `SIM_DELAY_D`) is zero delay,
so `IOBDELAY` `"IBUF"`, `"IFD"` and `"BOTH"` match `"NONE"`. An illegal
`BITSLIP_ENABLE` / `INTERFACE_TYPE` pair, an unknown width, or an
unknown rate does not `$finish`. An unknown width uses the DDR width-4
divider.

`DDR` samples `D` on both edges of `CLK`. `SDR` samples the rising
edge. `MEMORY` clocks the fabric rank from `OCLK`. `NETWORKING` clocks
it from `CLK`. Rank 2 loads from `CLKDIV`, or from the internal divider
when bitslip is enabled, and rank 3 follows `CLKDIV`. `Q1` is the
oldest bit of the parallel word. `NUM_CE` 2 holds `CE1` while `CLKDIV`
is high and `CE2` while it is low. `SR` wins over `REV` unless `REV`
is 1 and the matching `SRVAL` is 1, in which case the flop takes the
inverted `SRVAL`.

`tb_eq_serdes` compares networking and memory, both DDR and width 4,
with the submodule Verilog. `D` is changed before the clock: the
Verilog sampler reads a nonblocking copy of `D`, so a same-timestep
change loses the race. `OCLK` is driven with `CLK`, not through a
delta. `SR` is pulsed first, because a Verilog instance created from
VHDL does not see `glbl.GSR`.

`OSERDES` is the output serializer. `XIL_TIMING` stays undefined. The
specify paths are 100 ps and the rank flops are delayed 1 ps; neither
is copied. `SAME_EDGE` is the DDR clocking: the high level of `CLK` is
one rank and the low level is the rank captured on the falling edge.
The load generator matches the `ISERDES` divider. `DATA_RATE_TQ`
`"BUF"` with `TRISTATE_WIDTH` 1 passes `T1` through to `TQ`. DDR
tristate width 4 shifts `T1` to `T4` on the same load pulse as the
data word. An illegal width or tristate pairing does not `$finish`.

The same bench compares both cells. `OSERDES` has its own clocks. It
records 80 checks for `ISERDES` and 80 for `OSERDES`.

`ISERDES_NODELAY` is that deserializer without the tap chain. The
falling-edge sample is `posedge CLKB`. `RST` replaces `SR` and stores
0, because `REV` is tied off. There is no `O` port. The bench drives
`CLKB` as the complement of `CLK` in the same delta and compares
networking and memory, both DDR and width 4. With `ISERDES` that is
160 checks, and `OSERDES` adds 80.

`ISERDESE1` is that deserializer with a synchronous `RST`, an `O`
port, and `DDLY`. `XIL_TIMING` stays undefined. `IOBDELAY` `"NONE"`
drives `O` and the sampler from `D`. `OFB_USED` false leaves `OFB`
unused. Networking DDR width 4 clocks rank 2 from the inverted
divider; memory clocks it from `CLKDIV`. The 300 ps flop delays are
not copied. The bench compares networking and memory, both DDR and
width 4, on the same clocks as `ISERDES_NODELAY`. Seven of the eight
memory `Q2` samples match. The second word is `U` in the Verilog and
0 in the VHDL; that one sample is not compared. `tb_eq_serdes` records
255 input checks and 80 `OSERDES` checks.

`OSERDESE1` in `INTERFACE_TYPE` `"DEFAULT"` bypasses the DDR3 FIFO, so
`OQ` and `TQ` follow the `OSERDES` shift. `OFB` is `OQ` when
`ODELAY_USED` is 0. The 1 ps flop delays are not copied.
`MEMORY_DDR3` keeps the FIFO and is not compared. The Verilog uses
`defparam`, which this NVC does not elaborate, so the bench does not
analyse `OSERDESE1.v` yet.

`ISERDESE2`, `OSERDESE2`, `ISERDESE3` and `OSERDESE3` instantiate
`B_` / `SIP_` modules that are not in the submodule.

## Fourteenth batch

`MMCME2_ADV` is the integer clock path of the mixed-mode clock manager.
`mmcm_core` in that file is the shared model. `MMCME2_BASE` is the
wrapper with DRP and phase-shift ports tied off. `MMCME3_ADV` and
`MMCME4_ADV` use the same core; `CDDCDONE` stays 0. `MMCME3_BASE` and
`MMCME4_BASE` are the same kind of wrapper, and they apply the
`IS_CLKFBIN_INVERTED` and `IS_CLKIN1_INVERTED` pins.

The comparison path is an integer `CLKFBOUT_MULT_F`, integer
`CLKOUT0_DIVIDE_F`, `DIVCLK_DIVIDE`, 50 percent duty and zero phase,
with `CLKFBOUT` looped to `CLKFBIN`. `RST` is held past the 100 ns GSR
window. The VCO half-period is `Tin * DIVCLK_DIVIDE / MULT / 2`. The
divider counts the VCO edge that lands on the input edge where the
outputs turn on. `LOCKED` waits `Tin * DIVCLK_DIVIDE * MULT` after the
Verilog lock threshold. Fractional multiply or divide, a duty other
than 0.5, a non-zero phase, fine phase shift, spread spectrum, DRP,
and the stopped-clock flags are not compared. `RST` and `PWRDWN` are
checked only for clearing `LOCKED`: the Verilog restarts its VCO
burst on the next input edge, and the free-running VCO does not
reproduce that second-lock phase. With `DIVCLK_DIVIDE` 2, `CLKOUT*`
matches and `CLKFBOUT` is half a period away, so that pin is not
compared for that ratio. An illegal attribute does not `$finish`.

`tb_eq_mmcm` compares all six cells with the submodule Verilog, one
elaboration per cell. A second Verilog MMCM in the same simulation
does not lock on this NVC; that is left as a possible NVC bug.
`XIL_TIMING` stays undefined. The Verilog may report that
`CLKIN1_PERIOD` does not match the period measured with `$time`, and
that `%m` is an unknown format specifier. The locked clocks still
match; those messages are left as printed.

## Fifteenth batch

`EFUSE_USR` drives `EFUSEUSR` from `SIM_EFUSE_VALUE`. `DCIRESET`
drops `LOCKED` when `RST` is high and raises it 100 ns after `RST`
falls. That delay is the Verilog continuous assign (`#(100 ns, 0)`),
so the bench compares the rise. On this NVC the fall takes 100 ns as
well; the VHDL keeps the 0 ns fall, and the bench does not require
the Verilog to match until 100 ns later. A short pulse does not
`$finish`.

`DNA_PORT` is a 57-bit shift register, MSB out first. `READ` reloads
`SIM_DNA_VALUE` and `SHIFT` appends `DIN` at the LSB. `DNA_PORTE2` is
96 bits, LSB out first, and `SHIFT` inserts `DIN` at the MSB. `READ`
wins. The 100 ps specify path is not copied. An out-of-range
`SIM_DNA_VALUE` on `DNA_PORTE2` does not `$finish`.

`tb_eq_cfg` compares all four with the submodule Verilog.

## Sixteenth batch

`HARD_SYNC` is two or three registers. `DOUT` is the second register
when `LATENCY` is 2 and the third when it is 3. Any other `LATENCY`
behaves as 2 and does not `$finish`. `GSR` loads `INIT`. The 100 ps
specify path is not copied. `glbl` holds `GSR` for `ROC_WIDTH` (100 ns).
On this NVC that delay is about 100 ps, so `tb_eq_misc` does not clock
`HARD_SYNC` until 120 ns. Possible NVC bug. The VHDL ROC stays 100 ns.

`RIU_OR` ors the two read-data halves and ands the two valids.
`SIM_DEVICE` and `SIM_VERSION` are not used. An illegal value does not
`$finish`.

`HPIO_VREF` drives `VREF` as 1. `FABRIC_VREF_TUNE` and `VREF_CNTR` are
not used. An illegal `VREF_CNTR` does not `$finish`.

`ZHOLD_DELAY` delays each output by 200 ps times its tap count.
`DEFAULT` and `"0"` are no delay. The delayed nonblocking assign is
transport, so a pulse shorter than the delay still emerges. An
unrecognised tap string is 0 taps and does not `$finish`. On this NVC
the Verilog `<= #(200 ps * taps)` updates immediately, so the bench
compares the outputs only after the VHDL delay has elapsed, and the
short pulse is checked on the VHDL side. Possible NVC bug.

`tb_eq_misc` compares all four with the submodule Verilog. A Verilog
`X` arrives on a VHDL port as `U`.

## Seventeenth batch

`IBUFDS_GTE4` drives `O` from `I` unless `REFCLK_EN_TX_PATH` is set or
`CEB` is 1. `Z` and `X` on `I` become `X`. `ODIV2` copies `O`, toggles
on each rising edge of `I`, or stays 0, from `REFCLK_HROW_CK_SEL`.
`CEB` of 0 or `Z` lets that divider count. `IBUFDS_GTE3` drives `O` to
0 when the TX path or `CEB` is set, and otherwise passes `I`, including
`Z`. Only `CEB` 0 advances its divider; a divider that is already 1
still clears on the next rising edge. `OBUFDS_GTE4_ADV` is `Z` unless
the TX path is on and `CEB` is not 1, then `O` is the `I` bit selected
by `RXRECCLK_SEL` and `OB` is its inverse. `OBUFDS_GTE3_ADV` is the
same select into `bufif0` and `notif0`, with `GTS` in the enable. The
100 ps GTE4 specify path is not copied.

`tb_eq_gte` compares all four with the submodule Verilog.

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
   `test/tb/tb_eq_bufg.vhd`, `test/tb/tb_eq_ddr.vhd`,
   `test/tb/tb_eq_dsp.vhd`,    `test/tb/tb_eq_dsp48.vhd`,
   `test/tb/tb_eq_bram.vhd`,    `test/tb/tb_eq_serdes.vhd`, `test/tb/tb_eq_mmcm.vhd`,
   `test/tb/tb_eq_cfg.vhd`, `test/tb/tb_eq_misc.vhd`, or
   `test/tb/tb_eq_gte.vhd` so the
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
