# XilinxUnisimVHDL

VHDL companion to [XilinxUnisimLibrary](https://github.com/Xilinx/XilinxUnisimLibrary).
It builds a `unisim` library that [NVC](https://github.com/nickg/nvc) can
simulate: the upstream Verilog primitives, a generated
`unisim.vcomponents` package, and native VHDL primitives as they are
ported. [jarv](https://github.com/amb5l/jarv) consumes this repository
as a submodule.

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
git checkout cursor/vlog-unisim-mixed-c281
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

`make` prints how many Verilog files it analysed. With nothing in
`config/exclude.txt` that is 250: `glbl.v` plus 249 primitives.
`XIL_TIMING` and `XIL_DR` are left undefined.

Other targets:

| Command | Effect |
| --- | --- |
| `make vcomponents` | Regenerate `generated/unisim_vcomponents.vhd` |
| `make test` | Elaborate `tb_*` beside `unisim.GLBL` and run |
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
`GSR` is high for the first 100 ns.

## Status

Every primitive is still the Verilog model. Three of them have
self-checking benches. The per-primitive table is
[docs/status.md](docs/status.md). How to replace a model with VHDL is
[docs/porting-guide.md](docs/porting-guide.md).

Sized bit-vector parameters become `std_logic_vector` generics. NVC
currently elaborates only `integer` and `string` generics, so the
primitives under test override those vectors in
[config/type_map.yaml](config/type_map.yaml). `real` generics (MMCM, PLL,
DCM periods) analyse and do not elaborate yet. Details are in the
porting guide.
