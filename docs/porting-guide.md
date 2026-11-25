# Porting a primitive to VHDL

The library is the Verilog models in the `XilinxUnisimLibrary` submodule,
plus `package vcomponents` generated from their headers, plus VHDL added
under `src/vhdl` as primitives are replaced. The submodule is pinned and
is not edited. Vivado's VHDL unisim sources are not copied into this
tree.

## Build

`mk/nvc.mk` analyses, with `XIL_TIMING` and `XIL_DR` undefined:

1. `verilog/src/glbl.v`, then `verilog/src/unisims/*.v` except names
   listed in `config/exclude.txt`, into library `unisim`.
2. `generated/unisim_vcomponents.vhd`.
3. `src/vhdl/*.vhd`, into the same library.

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

`config/type_map.yaml` is empty. NVC `unisim/5-generics` elaborates
`integer`, `string`, `real`, and `std_logic_vector` generics, so the
sized parameters on `RAM32X1D`, `DSP48E1`, and `RAMB18E1` keep the
vector type of the Verilog literal. `DSP48E1.MASK` is
`std_logic_vector(47 downto 0)` with default `X"3FFFFFFFFFFF"`; it is
not omitted. An integer association is still accepted for a sized
parameter (zero-extended to the parameter width). The benches pass
vector literals instead, for example `x"3FFFFFFFFFFF"` and
`(others => '0')`.

`real` parameters (MMCM/PLL/DCM periods and phases) are `real` in the
package. Elaborating one of those primitives still depends on Verilog
`$realtime`, which this NVC branch does not provide.

String generics have a second constraint. NVC only accepts the value
when the generic map supplies a locally static string literal. A
component default such as `string := "TDP"` analyses, and elaboration
reports `generic NAME value is not a locally static string` if the
instantiation leaves that generic unmapped. Map every `string` generic
in the instance. Integer and vector defaults may be left to the
component; the benches map the vectors that used to be integer
overrides so the association itself is what gets elaborated.

## Replacing a Verilog model

1. Write the entity in `src/vhdl`, following `src/vhdl/README.md`.
2. Add the Verilog filename to `config/exclude.txt` so the file list and
   the generator both skip it.
3. Run `make vcomponents` if the component should change, or leave the
   generated component in place so existing port maps still bind to the
   VHDL entity.
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
