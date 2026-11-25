#!/usr/bin/env python3
"""Print the Verilog sources that make up library ``unisim``.

One path per line, relative to the repository root. glbl.v is first,
then every config/primitives.txt row whose lang is vlog. vhdl and skip
rows are left out; vhdl sources are printed by ``primitives.py --vhdl``.
"""

from __future__ import annotations

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from unisim_sources import ROOT, verilog_files


def main() -> int:
    files = verilog_files()
    if not files:
        print("filelist.py: no Verilog sources found (is the submodule checked out?)",
              file=sys.stderr)
        return 1
    for path in files:
        rel = os.path.relpath(path, ROOT)
        print(rel.replace("\\", "/"))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
