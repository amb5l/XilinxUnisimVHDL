# XilinxUnisimVHDL

Support for VHDL projects that use the AMD/Xilinx Unisim library when
Vivado is not available, for example in GitHub workflows. It is a
companion to [XilinxUnisimLibrary](https://github.com/Xilinx/XilinxUnisimLibrary)
and builds a `unisim` library that [NVC](https://github.com/nickg/nvc) can
simulate: the upstream Verilog primitives, a generated
`unisim.vcomponents` package, and native VHDL primitives as they are
ported.

Primitives are currently the Verilog models from XilinxUnisimLibrary, so
a mixed-language simulator is required. Native VHDL models are planned
for every primitive except encrypted IP.

The Verilog sources live in the `XilinxUnisimLibrary` submodule, pinned
at `1c8e05fd1e9a79ceb8b996a0996674122eed086f`. That tree is not modified.

## Licence

This repository is [Apache-2.0](LICENSE).

`generated/unisim_vcomponents.vhd` is derived from the Verilog module
headers in XilinxUnisimLibrary, which is itself Apache-2.0. See
[NOTICE](NOTICE). Vivado's VHDL unisim sources are not copied here and
are not a dependency of the generator.

## Quick start

NVC needs the mixed Verilog/VHDL fixes that are not in upstream yet.
Build that branch (the CI workflow does the same thing):

```sh
git clone https://github.com/amb5l/nvc
cd nvc
git checkout unisim/5-generics
./autogen.sh
mkdir build && cd build
../configure --prefix="$HOME/nvc"
make -j"$(nproc)"
make install
export PATH="$HOME/nvc/bin:$PATH"
```

The two environment variables CI uses, if you want a different fork or
commit, are `NVC_REPO` and `NVC_REF`.

Then, in this repository (the submodule has to be checked out):

```sh
git submodule update --init
make          # analyse glbl.v and every unisim into build/unisim
make test     # RAM32X1D, DSP48E1, RAMB18E1
```

`make` prints how many Verilog files it analysed. `config/primitives.txt`
is the index: `vlog` rows plus `glbl.v` are analysed, `vhdl` rows
analyse `src/vhdl/<NAME>.vhd` instead, and `skip` rows are left out of
the file list. This pin is 249 `vlog`, no `vhdl`, and `GTM_DUAL` `skip`
(SystemVerilog), so the Verilog analyse list is 250 including `glbl.v`.
`XIL_TIMING` and `XIL_DR` are left undefined.

Other targets:

| Command | Effect |
| --- | --- |
| `make vcomponents` | Regenerate `generated/unisim_vcomponents.vhd` |
| `make test` | Elaborate `tb_*` beside `unisim.GLBL` and run |
| `make check` | Check `config/primitives.txt` (complete, sorted, aligned) |
| `make clean` | Remove `build/` and `test/work/` |

`BUILD` is the directory that receives the library (default `build`).
`PREFIX`, when set, is prepended, so the library lands in
`$(PREFIX)/$(BUILD)`. `NVC` selects the binary. `NVC_M` is the heap
limit passed as `nvc -M` (default `1g`).

A VHDL design instantiates primitives with:

```vhdl
library unisim;
use unisim.vcomponents.all;
```

`glbl` must be elaborated as a second top (`nvc -e tb unisim.GLBL -r`).
Note that `GSR` is high for the first 100 ns.

## Status

Every primitive is still the Verilog model. Three of them have
self-checking benches. The per-primitive table is
[docs/status.md](docs/status.md). How to replace a model with VHDL is
[docs/porting-guide.md](docs/porting-guide.md).

Sized parameters become `bit` (width 1) or `bit_vector`, and a
`TRUE`/`FALSE` string parameter becomes `boolean`, matching Vivado's
`unisim_VCOMP` conventions. `config/type_map.yaml` has no integer
overrides. `real` generics (MMCM, PLL, DCM periods) analyse and do not
elaborate yet. Details are in the porting guide.

[config/primitives.txt](config/primitives.txt) names every primitive in
the submodule. Notes record the known NVC gaps: MMCM/PLL/DCM models that
call `$realtime` need `unisim/6-mmcm`, and `IOBUF*` `inout` ports use
`bufif0` drive strength, which NVC does not elaborate (`in` and `out`
only). `GTM_DUAL` is `skip` because the source is SystemVerilog. A
`skip` row is still given a component declaration when the header
parses, so a design that instantiates it can analyse. Details are in
the porting guide.
