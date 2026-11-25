# Compare `vcomponents` with Vivado

`generated/unisim_vcomponents.vhd` is produced from the Verilog headers in
the XilinxUnisimLibrary submodule. Vivado ships its own component
package, `unisim_VCOMP.vhd`. This repository does not contain that file
and CI does not install Vivado. On a machine that has Vivado, the
comparison reads the package, writes a report of interface differences,
and leaves the Vivado tree untouched.

The report lists component names and normalised values (a type, a
default, a port order). It does not copy Vivado source text. Do not
commit the report; `build/` is gitignored.

## Windows

Python 3 is enough. There is no pip package to install. From the
repository root, with Vivado installed at
`C:\AMDDevTools\2026.1\Vivado`:

```bat
python scripts/compare_vcomponents.py --vivado "C:\AMDDevTools\2026.1\Vivado"
```

`--vivado` accepts the Vivado root, the `unisims` directory, or the
`.vhd` file. The search is case-insensitive and looks for
`data\vhdl\src\unisims\unisim_VCOMP.vhd`.

The same paths can come from the environment. `VIVADO_VCOMP` is a file
and wins over `XILINX_VIVADO`, which is the Vivado root:

```bat
set XILINX_VIVADO=C:\AMDDevTools\2026.1\Vivado
python scripts/compare_vcomponents.py
```

If GNU make is installed and `python` is the interpreter name:

```bat
set XILINX_VIVADO=C:\AMDDevTools\2026.1\Vivado
make compare PYTHON=python
```

`make compare VIVADO=C:\AMDDevTools\2026.1\Vivado` passes the root on the
command line. `make compare STRICT=1` exits non-zero when a difference
is not one of the deliberate `config/type_map.yaml` overrides.

## What the report contains

Text goes to `build/compare_report.txt` and the same data as JSON to
`build/compare_report.json` (both under the repository, even if the
shell's current directory is somewhere else). `make compare` uses
`$(BUILD)`, or `$(PREFIX)/$(BUILD)` when `PREFIX` is set.

The summary at the top counts:

- components only in Vivado, or only in this package
- generics and ports missing or extra
- type, mode, and default differences
- port order and generic order (positional maps follow that order)
- how many of those are unexpected

A sized bit-string default is compared by value and width, so `X"A5"`,
`B"10100101"`, and `"10100101"` are the same 8-bit pattern.
`STD_ULOGIC_VECTOR(0 to 31)` and `std_ulogic_vector(31 downto 0)` are
the same type. String contents keep their case.

`config/type_map.yaml` records generics whose VHDL type was changed on
purpose, and generics omitted with `skip: true`. Those show up as
`expected (type_map)`. An integer generic against a Vivado vector is
also marked `integer-vs-vector`. Other differences are unexpected.

The script exits 0 when both files parse, even if they differ. A missing
path or a component the parser cannot read exits 2. `--strict` exits 1
when the unexpected count is not zero. `make compare` does not pass
`--strict` unless `STRICT=1`.

## CI

`.github/workflows/ci.yml` runs `scripts/test_compare_vcomponents.py`.
Those tests use short synthetic component declarations. They do not
need Vivado, and they do not run `make compare`.
