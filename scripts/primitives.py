#!/usr/bin/env python3
"""Read and rewrite config/primitives.txt.

The index is the single source of truth for which unisim primitive is
Verilog, a hand-written VHDL model, or skipped. mk/nvc.mk and
scripts/gen_vcomponents.py both consume it. Columns are fixed-width,
not CSV.

    python3 scripts/primitives.py --check
    python3 scripts/primitives.py --write
    python3 scripts/primitives.py --filelist
    python3 scripts/primitives.py --vhdl
"""

from __future__ import annotations

import argparse
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
INDEX = "config/primitives.txt"
LANGS = ("vlog", "vhdl", "skip")

PROLOGUE = (
    "# Primitive index for library unisim. Fixed-width columns, not CSV.",
    "# lang is vlog, vhdl, or skip.",
    "#   vlog  analyse XilinxUnisimLibrary/verilog/src/unisims/<NAME>.v",
    "#         (or <NAME>.sv when that is the only source)",
    "#   vhdl  analyse src/vhdl/<NAME>.vhd instead of that Verilog",
    "#   skip  do not analyse; the component is still emitted when the",
    "#         Verilog header parses, so a design can analyse against it",
    "# glbl.v is not listed; it is always analysed.",
    "# config/exclude.txt is gone. A primitive that used to be excluded is",
    "# lang skip, with the reason in notes. This pin had no exclusions.",
    "# Sort and realign with: python3 scripts/primitives.py --write",
)

# Notes applied only when --write adds a name that is not already indexed.
REALTIME = "needs NVC unisim/6-mmcm ($realtime)"
REALTIME_DIRECT = {
    "DCM_ADV",
    "DCM_SP",
    "MMCME2_ADV",
    "MMCME3_ADV",
    "MMCME3_BASE",
    "MMCME4_ADV",
    "MMCME4_BASE",
    "PLLE2_ADV",
    "PLLE3_ADV",
    "PLLE3_BASE",
    "PLLE4_ADV",
    "PLLE4_BASE",
}
REALTIME_WRAPS = {
    "MMCME2_BASE": "instantiates MMCME2_ADV; " + REALTIME,
    "PLLE2_BASE": "instantiates PLLE2_ADV; " + REALTIME,
}
IOBUF_NOTE = (
    "inout bufif0; NVC elaborates in/out only "
    "(drive strength on IO is not simulated)"
)
GTM_NOTE = "SystemVerilog (.sv); not analysed with the Verilog sources"


class IndexError(Exception):
    pass


class Entry:
    def __init__(self, name: str, lang: str, notes: str) -> None:
        self.name = name
        self.lang = lang
        self.notes = notes

    def sort_key(self) -> str:
        return self.name


def index_path(root: str) -> str:
    return os.path.join(root, INDEX)


def unisims_dir(root: str) -> str:
    return os.path.join(root, "XilinxUnisimLibrary", "verilog", "src", "unisims")


def glbl_path(root: str) -> str:
    return os.path.join(root, "XilinxUnisimLibrary", "verilog", "src", "glbl.v")


def verilog_path(root: str, name: str) -> str | None:
    folder = unisims_dir(root)
    for ext in (".v", ".sv"):
        path = os.path.join(folder, name + ext)
        if os.path.isfile(path):
            return path
    return None


def vhdl_path(root: str, name: str) -> str | None:
    path = os.path.join(root, "src", "vhdl", name + ".vhd")
    return path if os.path.isfile(path) else None


def submodule_primitives(root: str) -> dict[str, str]:
    """Map primitive name to its unisims/ filename (.v or .sv)."""
    folder = unisims_dir(root)
    found: dict[str, str] = {}
    if not os.path.isdir(folder):
        return found
    for filename in sorted(os.listdir(folder)):
        stem, ext = os.path.splitext(filename)
        if ext not in {".v", ".sv"}:
            continue
        if stem in found:
            raise IndexError(f"{filename}: both .v and .sv exist for {stem}")
        found[stem] = filename
    return found


def seed(name: str) -> tuple[str, str]:
    """lang, notes for a primitive that is not in the index yet."""
    if name == "GTM_DUAL":
        return "skip", GTM_NOTE
    if name in REALTIME_WRAPS:
        return "vlog", REALTIME_WRAPS[name]
    if name in REALTIME_DIRECT:
        return "vlog", REALTIME
    if name.startswith("IOBUF"):
        return "vlog", IOBUF_NOTE
    return "vlog", ""


def render(entries: list[Entry]) -> str:
    width = max([len("name")] + [len(entry.name) for entry in entries])
    lines = list(PROLOGUE)
    lines.append(f"# {'name'.ljust(width - 2)}  lang  notes")
    for entry in entries:
        line = f"{entry.name.ljust(width)}  {entry.lang}"
        if entry.notes:
            line += f"  {entry.notes}"
        lines.append(line)
    return "\n".join(lines) + "\n"


def parse(text: str, path: str = INDEX) -> list[Entry]:
    entries: list[Entry] = []
    seen: set[str] = set()
    for lineno, raw in enumerate(text.splitlines(), 1):
        if raw.endswith((" ", "\t")):
            raise IndexError(f"{path}:{lineno}: trailing whitespace")
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            continue
        parts = raw.split(None, 2)
        if len(parts) < 2:
            raise IndexError(f"{path}:{lineno}: expected name, lang, notes")
        name, lang = parts[0], parts[1]
        notes = parts[2].strip() if len(parts) > 2 else ""
        if not name.isidentifier():
            raise IndexError(f"{path}:{lineno}: bad primitive name {name!r}")
        if lang not in LANGS:
            raise IndexError(f"{path}:{lineno}: lang must be vlog, vhdl, or skip")
        if name in seen:
            raise IndexError(f"{path}:{lineno}: duplicate primitive {name}")
        seen.add(name)
        entries.append(Entry(name, lang, notes))
    return entries


def load(root: str | None = None) -> list[Entry]:
    root = root or ROOT
    path = index_path(root)
    if not os.path.isfile(path):
        raise IndexError(f"missing {path}")
    with open(path, encoding="utf-8") as fh:
        return parse(fh.read(), os.path.relpath(path, root).replace("\\", "/"))


def rel(root: str, path: str) -> str:
    return os.path.relpath(path, root).replace("\\", "/")


def filelist(root: str | None = None) -> list[str]:
    """glbl.v, then each vlog primitive, repo-relative."""
    root = root or ROOT
    paths: list[str] = []
    glbl = glbl_path(root)
    if os.path.isfile(glbl):
        paths.append(rel(root, glbl))
    for entry in load(root):
        if entry.lang != "vlog":
            continue
        path = verilog_path(root, entry.name)
        if path is None:
            raise IndexError(f"{entry.name}: vlog entry has no Verilog source")
        paths.append(rel(root, path))
    return paths


def vhdl_files(root: str | None = None) -> list[str]:
    root = root or ROOT
    paths: list[str] = []
    for entry in load(root):
        if entry.lang != "vhdl":
            continue
        path = vhdl_path(root, entry.name)
        if path is None:
            raise IndexError(f"{entry.name}: vhdl entry has no src/vhdl/{entry.name}.vhd")
        paths.append(rel(root, path))
    return paths


def check(root: str | None = None) -> list[str]:
    """Empty list means the index matches the submodule and the canonical text."""
    root = root or ROOT
    path = index_path(root)
    errors: list[str] = []
    if not os.path.isfile(path):
        return [f"missing {INDEX}"]
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    try:
        entries = parse(text, INDEX)
    except IndexError as exc:
        return [str(exc)]

    try:
        present = submodule_primitives(root)
    except IndexError as exc:
        return [str(exc)]

    canonical = render(sorted(entries, key=Entry.sort_key))
    if text != canonical:
        errors.append(
            f"{INDEX} is not canonical (sorted, aligned, fixed prologue). "
            "Run: python3 scripts/primitives.py --write"
        )

    indexed = {entry.name: entry for entry in entries}
    for name in sorted(present):
        if name not in indexed:
            errors.append(f"submodule primitive {name} is missing from {INDEX}")
    for entry in entries:
        verilog = verilog_path(root, entry.name)
        vhdl = vhdl_path(root, entry.name)
        if entry.lang == "vlog" and verilog is None:
            errors.append(f"{entry.name}: vlog entry has no source")
        elif entry.lang == "skip" and verilog is None:
            errors.append(f"{entry.name}: skip entry has no source")
        elif entry.lang == "vhdl":
            if vhdl is None:
                errors.append(
                    f"{entry.name}: vhdl entry has no src/vhdl/{entry.name}.vhd"
                )
            if verilog is None:
                errors.append(
                    f"{entry.name}: vhdl entry has no submodule Verilog to replace"
                )
    return errors


def write(root: str | None = None) -> list[Entry]:
    """Realign the index and add submodule primitives that are absent."""
    root = root or ROOT
    path = index_path(root)
    existing: list[Entry] = []
    if os.path.isfile(path):
        with open(path, encoding="utf-8") as fh:
            existing = parse(fh.read(), INDEX)
    by_name = {entry.name: entry for entry in existing}
    for name in submodule_primitives(root):
        if name not in by_name:
            lang, notes = seed(name)
            by_name[name] = Entry(name, lang, notes)
    entries = sorted(by_name.values(), key=Entry.sort_key)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(render(entries))
    return entries


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--check", action="store_true",
                      help="fail if the index is incomplete, unsorted, or misaligned")
    mode.add_argument("--write", action="store_true",
                      help="realign columns, sort, and add new submodule primitives")
    mode.add_argument("--filelist", action="store_true",
                      help="print glbl.v and the vlog sources, repo-relative")
    mode.add_argument("--vhdl", action="store_true",
                      help="print src/vhdl sources for vhdl rows, repo-relative")
    args = parser.parse_args(argv)
    try:
        if args.check:
            errors = check()
            if errors:
                for error in errors:
                    print(f"error: {error}", file=sys.stderr)
                return 1
            entries = load()
            counts = {lang: sum(1 for e in entries if e.lang == lang) for lang in LANGS}
            print(
                f"{INDEX}: {len(entries)} primitives "
                f"(vlog {counts['vlog']}, vhdl {counts['vhdl']}, skip {counts['skip']})"
            )
            return 0
        if args.write:
            entries = write()
            print(f"wrote {INDEX}: {len(entries)} primitives", file=sys.stderr)
            return 0
        if args.filelist:
            for path in filelist():
                print(path)
            return 0
        for path in vhdl_files():
            print(path)
        return 0
    except IndexError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
