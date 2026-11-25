# Porting a primitive to VHDL

The library is the Verilog models in the `XilinxUnisimLibrary` submodule,
plus `package vcomponents` generated from their headers, plus VHDL added
under `src/vhdl` as primitives are replaced. The submodule is pinned and
is not edited. Vivado's VHDL unisim sources are not copied into this
tree.

## Build

`mk/nvc.mk` analyses, with `XIL_TIMING` and `XIL_DR` undefined:

1. `verilog/src/glbl.v`, then every `vlog` row in
   `config/primitives.txt`, into library `unisim`.
2. `generated/unisim_vcomponents.vhd`.
3. `src/vhdl/<NAME>.vhd` for each `vhdl` row, into the same library,
   instead of that primitive's Verilog.

`glbl` is a second top-level Verilog unit. Elaborate it beside the
testbench:

```text
nvc -e tb_x unisim.GLBL -r
```

`glbl` holds `GSR` high for `ROC_WIDTH` (100000 ps, so 100 ns) from time
0. Stimulus that writes state has to wait until after that, or the model
will still be in global reset.

Several models, including `DSP48E1` with its pipeline registers set to
0, copy an input in `always @(that_input)`. That block does not run for
a value that is constant from time 0, so the internal copy stays `X`
until the input changes. A testbench has to toggle those inputs once
before checking a result.

NVC has to be the mixed-language build named in the README. Upstream NVC
does not yet bind a VHDL component onto a Verilog module in another
library, and it does not accept `unisim.GLBL` as a second top.

## Generating `vcomponents`

`scripts/gen_vcomponents.py` reads each module header (not the body) and
emits one component. `make vcomponents` rewrites
`generated/unisim_vcomponents.vhd`. The package is committed so a
consumer does not have to regenerate it.

Ports become `std_ulogic`, or `std_logic_vector(N-1 downto 0)` when the
Verilog port has a range. Width-1 vectors stay vectors
(`std_logic_vector(0 downto 0)`). `inout` is preserved on the component.
NVC's binder currently accepts only `in` and `out` at elaboration, so an
`inout` primitive analyses and does not yet simulate.

Generics follow the parameter's default, unless `config/type_map.yaml`
overrides that parameter:

| Verilog default | VHDL generic |
| --- | --- |
| `"..."` string | `string` |
| unsized integer, or an explicit `integer` parameter | `integer` |
| real literal, or an explicit `real` parameter | `real` |
| sized literal such as `32'h0` or `1'b0` | `std_logic_vector` of that width |

An explicit `parameter integer` / `real` / `string` keeps that type even
when the literal would suggest another one.

### Type-mapping exceptions

The mixed-language elaborator accepts a VHDL generic only when it is
`integer` or `string`. A `std_logic_vector` or `real` generic analyses
with the package and is rejected when that component is elaborated
(`generic NAME should have type INTEGER` or `STRING`).

`config/type_map.yaml` records the overrides required by the primitives
under `test/tb`:

- `RAM32X1D.INIT` and `IS_WCLK_INVERTED` are `integer`. Both defaults
  are zero and fit in `INTEGER`.
- `DSP48E1` mask-style vectors whose default fits (`IS_*_INVERTED`,
  `PATTERN`) are `integer`. `MASK` is `48'h3FFFFFFFFFFF`, which does not
  fit in VHDL `INTEGER`, so the generic is omitted (`skip: true`) and
  the Verilog default is kept.
- Every sized init / invert / `SRVAL` parameter on `RAMB18E1` is
  `integer`. Each default is zero.

Other primitives keep `std_logic_vector` for sized literals. Extending a
test to a new primitive means either mapping that primitive's vectors
the same way, or teaching NVC to pass `std_logic_vector` and `real`
generics through. `real` parameters (MMCM/PLL/DCM periods and phases)
are the same kind of gap: they are `real` in the package and cannot be
elaborated until NVC grows a real generic mapping.

String generics have a second constraint. NVC only accepts the value
when the generic map supplies a locally static string literal. A
component default such as `string := "TDP"` analyses, and elaboration
reports `generic NAME value is not a locally static string` if the
instantiation leaves that generic unmapped. Map every `string` generic
in the instance. Integer defaults may be left to the component.

## The primitive index

`config/primitives.txt` is the list `mk/nvc.mk` and
`scripts/gen_vcomponents.py` both read. It is fixed-width, not CSV.
`lang` is `vlog`, `vhdl`, or `skip`. `glbl.v` is not a row; it is always
analysed. `python3 scripts/primitives.py --write` sorts the file, aligns
the columns, and adds a submodule primitive that is not listed yet
(`vlog`, with a note when the name is one of the known NVC gaps).
`python3 scripts/primitives.py --check` (and `make check`, which CI runs)
fails when a submodule primitive is missing, an entry has no source, or
the file is not exactly that canonical text.

`config/exclude.txt` is removed. This submodule pin had no exclusions, so
nothing was migrated into `skip` from that file. `GTM_DUAL` is `skip`
because `GTM_DUAL.sv` is SystemVerilog and is not part of the Verilog
analyse list.

A `skip` primitive is not analysed. Its component is still emitted when
the Verilog header parses, so a design that instantiates it analyses
against `unisim.vcomponents` and fails later, at elaboration, instead of
at the component lookup. The generated package comments the row
`-- skip: not analysed (...)`. If the header does not parse, the
component is omitted and the generator prints the parse error; `vlog`
and `vhdl` headers that do not parse still fail the generator.

## Replacing a Verilog model

1. Write the entity in `src/vhdl/<NAME>.vhd`, following `src/vhdl/README.md`.
2. Change that primitive's `lang` to `vhdl` in `config/primitives.txt`
   and realign with `python3 scripts/primitives.py --write`. The Verilog
   file stays in the submodule; it is no longer analysed.
3. Run `make vcomponents`. The component is still generated from the
   Verilog header, with a comment that the VHDL file is what gets
   analysed, so existing port maps bind to the new entity.
4. Add a self-checking bench under `test/tb` that
   `use unisim.vcomponents.all` and waits out `GSR`.
5. Update the row in `docs/status.md` from "Verilog only" to "VHDL native"
   (and "tested" once the bench is in `test/Makefile`).

`src/overrides/` is for a local Verilog or VHDL patch that must not be
applied by editing the submodule. Files there are not on the default
file list; wire one in deliberately.

Do not copy headers, comments, or statements out of a Vivado VHDL unisim
install. New models are written from the public Verilog behaviour and
the generated component.
