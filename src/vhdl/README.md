# Hand-written VHDL in library `unisim`

A source here is analysed into the same `unisim` library as the Verilog
primitives and `vcomponents`, after the generated package, when
`config/primitives.txt` marks that primitive `vhdl`. The file name is
`src/vhdl/<NAME>.vhd`. There are none yet: every Verilog primitive is
still `vlog`.

## Conventions

- One design unit per file. Name the file after the primitive
  (`RAM32X1D.vhd`).
- The entity name matches the Verilog module and the component in
  `unisim.vcomponents`, including the Xilinx spelling. VHDL folds case;
  do not add a second unit that differs only by case.
- Use `std_ulogic` for scalar ports and `std_logic_vector(N-1 downto 0)`
  for vectors, the same mapping as `scripts/gen_vcomponents.py`.
- Generics use the types in the generated component: `bit`,
  `bit_vector`, `boolean`, `integer`, `real`, or `string`.
- Prefer VHDL-2008. No vendor packages, and no copies of Vivado's VHDL
  unisim sources.
- Behaviour that must survive `GSR` should wait until `glbl.GSR` has
  fallen. In these models that is 100 ns from time 0.
- When a VHDL entity replaces a Verilog primitive, set its `lang` to
  `vhdl` in `config/primitives.txt`. `make` then analyses this file and
  not the Verilog, so the two definitions of the same name are not both
  in the library. The component stays in `vcomponents`. Record the
  change in `docs/status.md`.

`src/overrides/` is reserved for sources that patch around the submodule
without editing it (the submodule is read-only). Nothing there is
compiled automatically.
