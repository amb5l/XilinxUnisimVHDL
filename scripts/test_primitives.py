#!/usr/bin/env python3
"""Unit tests for config/primitives.txt. No simulator and no Vivado."""

from __future__ import annotations

import os
import shutil
import tempfile
import unittest

import primitives


def _touch(path: str, text: str = "module stub;\nendmodule\n") -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(text)


class Tree(unittest.TestCase):
    def setUp(self) -> None:
        self.root = tempfile.mkdtemp()
        self.unisims = os.path.join(
            self.root, "XilinxUnisimLibrary", "verilog", "src", "unisims"
        )
        os.makedirs(self.unisims)
        _touch(os.path.join(self.root, "XilinxUnisimLibrary", "verilog", "src", "glbl.v"))
        _touch(os.path.join(self.unisims, "AND2.v"))
        _touch(os.path.join(self.unisims, "GTM_DUAL.sv"), "module GTM_DUAL;\nendmodule\n")
        _touch(os.path.join(self.unisims, "IOBUF.v"))

    def tearDown(self) -> None:
        shutil.rmtree(self.root)

    def test_write_seeds_and_check_passes(self) -> None:
        entries = primitives.write(self.root)
        by_name = {entry.name: entry for entry in entries}
        self.assertEqual(by_name["AND2"].lang, "vlog")
        self.assertEqual(by_name["AND2"].notes, "")
        self.assertEqual(by_name["GTM_DUAL"].lang, "skip")
        self.assertIn("SystemVerilog", by_name["GTM_DUAL"].notes)
        self.assertIn("bufif0", by_name["IOBUF"].notes)
        self.assertEqual(primitives.check(self.root), [])
        self.assertEqual(
            primitives.filelist(self.root),
            [
                "XilinxUnisimLibrary/verilog/src/glbl.v",
                "XilinxUnisimLibrary/verilog/src/unisims/AND2.v",
                "XilinxUnisimLibrary/verilog/src/unisims/IOBUF.v",
            ],
        )

    def test_unsorted_or_misaligned_fails(self) -> None:
        primitives.write(self.root)
        path = primitives.index_path(self.root)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        lines = text.splitlines()
        body = [line for line in lines if line and not line.startswith("#")]
        self.assertGreaterEqual(len(body), 2)
        body[0], body[1] = body[1], body[0]
        broken = "\n".join(lines[: len(lines) - len(body)] + body) + "\n"
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(broken)
        errors = primitives.check(self.root)
        self.assertTrue(any("not canonical" in error for error in errors), errors)
        primitives.write(self.root)
        self.assertEqual(primitives.check(self.root), [])

    def test_missing_primitive_and_orphan_entry(self) -> None:
        primitives.write(self.root)
        path = primitives.index_path(self.root)
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        text = "\n".join(
            line for line in text.splitlines() if not line.startswith("AND2")
        ) + "\n"
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(text)
        errors = primitives.check(self.root)
        self.assertTrue(any("AND2" in error and "missing" in error for error in errors))

        _touch(os.path.join(self.unisims, "NEWONE.v"))
        primitives.write(self.root)
        entries = {entry.name: entry for entry in primitives.load(self.root)}
        self.assertEqual(entries["NEWONE"].lang, "vlog")
        self.assertEqual(entries["NEWONE"].notes, "")
        self.assertEqual(primitives.check(self.root), [])

        # An index row with no submodule file and no VHDL model.
        entries["GONE"] = primitives.Entry("GONE", "skip", "removed")
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(primitives.render(sorted(entries.values(), key=lambda e: e.name)))
        errors = primitives.check(self.root)
        self.assertTrue(any("GONE" in error and "no source" in error for error in errors))

    def test_vhdl_requires_both_sources(self) -> None:
        primitives.write(self.root)
        path = primitives.index_path(self.root)
        entries = primitives.load(self.root)
        for entry in entries:
            if entry.name == "AND2":
                entry.lang = "vhdl"
                entry.notes = "hand-written"
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(primitives.render(entries))
        errors = primitives.check(self.root)
        self.assertTrue(any("AND2.vhd" in error for error in errors), errors)
        _touch(
            os.path.join(self.root, "src", "vhdl", "AND2.vhd"),
            "entity AND2 is end entity AND2;\n",
        )
        self.assertEqual(primitives.check(self.root), [])
        self.assertEqual(
            primitives.vhdl_files(self.root),
            ["src/vhdl/AND2.vhd"],
        )
        listed = primitives.filelist(self.root)
        self.assertFalse(any(path.endswith("AND2.v") for path in listed))


class Repo(unittest.TestCase):
    def test_checked_in_index(self) -> None:
        errors = primitives.check(primitives.ROOT)
        self.assertEqual(errors, [])


if __name__ == "__main__":
    unittest.main()
