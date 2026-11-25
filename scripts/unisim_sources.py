"""Shared locations for the vendored XilinxUnisimLibrary sources.

The Verilog tree is a git submodule and is never modified. Which primitives
are analysed comes from config/primitives.txt (see scripts/primitives.py).
"""

from __future__ import annotations

import os

import primitives

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
UNISIM_ROOT = os.path.join(ROOT, "XilinxUnisimLibrary")
VERILOG_SRC = os.path.join(UNISIM_ROOT, "verilog", "src")
UNISIMS_DIR = os.path.join(VERILOG_SRC, "unisims")
GLBL = os.path.join(VERILOG_SRC, "glbl.v")


def verilog_files() -> list[str]:
    """glbl.v followed by primitives whose index lang is vlog.

    Order is stable: glbl first (other models refer to it), then the index
    order, which is sorted by primitive name.
    """
    return [os.path.join(ROOT, rel) for rel in primitives.filelist(ROOT)]
