"""Shared locations for the vendored XilinxUnisimLibrary sources.

The Verilog tree is a git submodule and is never modified. File lists and
the component generator both honour config/exclude.txt.
"""

from __future__ import annotations

import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
UNISIM_ROOT = os.path.join(ROOT, "XilinxUnisimLibrary")
VERILOG_SRC = os.path.join(UNISIM_ROOT, "verilog", "src")
UNISIMS_DIR = os.path.join(VERILOG_SRC, "unisims")
GLBL = os.path.join(VERILOG_SRC, "glbl.v")
EXCLUDE = os.path.join(ROOT, "config", "exclude.txt")


def load_excludes(path: str | None = None) -> set[str]:
    """Basenames and repo-relative paths listed in config/exclude.txt."""
    path = path or EXCLUDE
    found: set[str] = set()
    if not os.path.isfile(path):
        return found
    with open(path, encoding="utf-8") as fh:
        for raw in fh:
            line = raw.split("#", 1)[0].strip()
            if not line:
                continue
            found.add(line.replace("\\", "/"))
            found.add(os.path.basename(line))
    return found


def _excluded(path: str, excludes: set[str]) -> bool:
    rel = os.path.relpath(path, ROOT).replace("\\", "/")
    base = os.path.basename(path)
    return rel in excludes or base in excludes


def verilog_files(excludes: set[str] | None = None) -> list[str]:
    """glbl.v followed by verilog/src/unisims/*.v, minus exclusions.

    Order is stable: glbl first (other models refer to it), then primitives
    by filename.
    """
    excludes = load_excludes() if excludes is None else excludes
    files: list[str] = []
    if os.path.isfile(GLBL) and not _excluded(GLBL, excludes):
        files.append(GLBL)
    if os.path.isdir(UNISIMS_DIR):
        for name in sorted(os.listdir(UNISIMS_DIR)):
            if not name.endswith(".v"):
                continue
            path = os.path.join(UNISIMS_DIR, name)
            if _excluded(path, excludes):
                continue
            files.append(path)
    return files
