# Hand-written VHDL in library `unisim`

Sources in this directory are analysed into the same `unisim` library as
the Verilog primitives and `vcomponents`, after the generated package.
`make` picks up every `*.vhd` here. There are none yet: every primitive
is still the Verilog model from XilinxUnisimLibrary.

## Conventions

- One design unit per file. Name the file after the primitive
  (`RAM32X1D.vhd`).
- The entity name matches the Verilog module and the component in
  `unisim.vcomponents`, including the Xilinx spelling. VHDL folds case;
  do not add a second unit that differs only by case.
- Use `std_ulogic` for scalar ports and `std_logic_vector(N-1 downto 0)`
  for vectors, the same mapping as `scripts/gen_vcomponents.py`.
- Generics use the types in the generated component. Sized Verilog
  parameters are `std_logic_vector` unless `config/type_map.yaml`
  overrides that parameter. The override file is empty.
- Prefer VHDL-2008. No vendor packages, and no copies of Vivado's VHDL
  unisim sources.
- Behaviour that must survive `GSR` should wait until `glbl.GSR` has
  fallen. In these models that is 100 ns from time 0.
- When a VHDL entity replaces a Verilog primitive, add the Verilog file
  to `config/exclude.txt` so the two definitions of the same name are
  not both in the library. Leave the component in `vcomponents` so
  existing instantiations keep binding. Record the change in
  `docs/status.md`.

`src/overrides/` is reserved for sources that patch around the submodule
without editing it (the submodule is read-only). Nothing there is
compiled automatically.
