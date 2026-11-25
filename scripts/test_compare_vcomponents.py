#!/usr/bin/env python3
"""Unit tests for scripts/compare_vcomponents.py. No Vivado sources."""

from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

import compare_vcomponents as cv

ROOT = Path(__file__).resolve().parents[1]
OURS = ROOT / "generated" / "unisim_vcomponents.vhd"
SENTINEL = "VIVADO_SOURCE_SENTINEL_do_not_copy_this_block"


def _pkg(*components: str) -> str:
    body = "\n".join(components)
    return (
        f"-- {SENTINEL}\n"
        "library ieee;\n"
        "package vcomponents is\n"
        f"{body}\n"
        "end package vcomponents;\n"
    )


class ParseTests(unittest.TestCase):
    def test_grouped_names_comments_and_string_with_keywords(self) -> None:
        text = _pkg(
            """
            component FOO is
              generic (
                -- component decoy ; port (
                G : string := "component ; port ( end";
                A, B : integer := (2)
              );
              port (
                Y, Z : out std_logic; /* grouped */
                D : in std_logic_vector(0 to 3) := "1010"
              );
            end component FOO;
            """
        )
        comps = cv.parse_components(text)
        self.assertEqual(set(comps), {"foo"})
        foo = comps["foo"]
        generics = {g.name.lower(): g for g in foo.generics}
        self.assertEqual(generics["g"].default_norm, 'str:component ; port ( end')
        self.assertEqual(generics["a"].type_norm, "integer")
        self.assertEqual(generics["a"].default_norm, "expr:(2)")
        self.assertEqual(generics["b"].default_norm, "expr:(2)")
        ports = {p.name.lower(): p for p in foo.ports}
        self.assertEqual(ports["y"].mode, "out")
        self.assertEqual(ports["z"].mode, "out")
        self.assertEqual(ports["d"].type_norm, "std_logic_vector(3 downto 0)")
        self.assertEqual(ports["d"].default_norm, "bits:4:1010")

    def test_without_is_and_without_end_name(self) -> None:
        text = _pkg(
            """
            COMPONENT bar
              port (o : OUT STD_ULOGIC);
            end component;
            """
        )
        comps = cv.parse_components(text)
        self.assertIn("bar", comps)
        self.assertEqual(comps["bar"].ports[0].mode, "out")
        self.assertEqual(comps["bar"].ports[0].type_norm, "std_ulogic")

    def test_unclosed_component_is_a_parse_error(self) -> None:
        with self.assertRaises(cv.ParseError):
            cv.parse_components("component FOO is port (a : in std_logic;")

    def test_generated_package_parses_and_matches_itself(self) -> None:
        text = OURS.read_text(encoding="utf-8")
        comps = cv.parse_components(text)
        declared = text.lower().count("\n  component ")
        self.assertEqual(len(comps), declared)
        self.assertGreater(len(comps), 200)
        self.assertIn("ram32x1d", comps)
        self.assertIn("dsp48e1", comps)
        self.assertIn("ramb18e1", comps)
        diffs = cv.compare_sets(comps, comps, {})
        self.assertEqual(diffs, [])


class NormaliseTests(unittest.TestCase):
    def test_range_direction_and_case(self) -> None:
        self.assertEqual(
            cv.norm_type("STD_ULOGIC_VECTOR ( 0 to 31 )"),
            "std_ulogic_vector(31 downto 0)",
        )
        self.assertEqual(
            cv.norm_type("std_logic_vector(31 downto 0)"),
            "std_logic_vector(31 downto 0)",
        )

    def test_hex_binary_and_others_share_a_value(self) -> None:
        kind = "std_logic_vector(7 downto 0)"
        hex_value = cv.norm_default('X"A5"', kind)
        bin_value = cv.norm_default('B"10100101"', kind)
        str_value = cv.norm_default('"10100101"', kind)
        self.assertEqual(hex_value, "bits:8:10100101")
        self.assertEqual(hex_value, bin_value)
        self.assertEqual(hex_value, str_value)
        wide = "std_logic_vector(31 downto 0)"
        self.assertEqual(
            cv.norm_default("(others => '0')", wide),
            cv.norm_default('X"00000000"', wide),
        )

    def test_integer_real_and_string(self) -> None:
        self.assertEqual(cv.norm_default("1_0", "integer"), "int:10")
        self.assertEqual(cv.norm_default("2.00", "real"), cv.norm_default("2.0", "real"))
        self.assertEqual(cv.norm_default('"A""B"', "string"), 'str:A"B')


class CompareTests(unittest.TestCase):
    def test_integer_vector_type_map_is_expected(self) -> None:
        ours = _pkg(
            """
            component RAM32X1D is
              generic (INIT : integer := 0);
              port (D : in std_ulogic; O : out std_ulogic);
            end component;
            """
        )
        vivado = _pkg(
            """
            component RAM32X1D is
              generic (INIT : bit_vector(31 downto 0) := X"00000000");
              port (O : out std_ulogic; D : in std_ulogic);
            end component;
            """
        )
        type_map = {"RAM32X1D": {"INIT": {"type": "integer"}}}
        report = cv.build_report(ours, vivado, type_map, "ours.vhd", "vivado.vhd")
        kinds = {(d.kind, d.name, tuple(d.flags)) for d in report.diffs}
        self.assertIn(("type", "init", (cv.INT_VS_VEC, cv.EXPECTED)), kinds)
        self.assertIn(("default", "init", (cv.EXPECTED,)), kinds)
        self.assertIn(("port_order", "", ()), kinds)
        self.assertEqual(report.unexpected, 1)

    def test_skip_hides_a_missing_generic(self) -> None:
        ours = _pkg(
            """
            component DSP48E1 is
              generic (AREG : integer := 1);
              port (P : out std_logic_vector(47 downto 0));
            end component;
            """
        )
        vivado = _pkg(
            """
            component DSP48E1 is
              generic (
                AREG : integer := 1;
                MASK : bit_vector(47 downto 0) := X"3FFFFFFFFFFF"
              );
              port (P : out std_logic_vector(47 downto 0));
            end component;
            """
        )
        type_map = {"DSP48E1": {"MASK": {"skip": True}}}
        report = cv.build_report(ours, vivado, type_map, "ours.vhd", "vivado.vhd")
        self.assertEqual(len(report.diffs), 1)
        self.assertEqual(report.diffs[0].kind, "missing_generic")
        self.assertEqual(report.diffs[0].flags, [cv.EXPECTED])
        self.assertEqual(report.unexpected, 0)

    def test_only_in_one_side_mode_and_extra_port(self) -> None:
        ours = _pkg(
            """
            component ONLY_OURS is
              port (A : in std_logic);
            end component;
            component BOTH is
              port (A : in std_logic; B : out std_logic);
            end component;
            """
        )
        vivado = _pkg(
            """
            component ONLY_VIV is
              port (A : in std_logic);
            end component;
            component BOTH is
              port (A : out std_logic);
            end component;
            """
        )
        report = cv.build_report(ours, vivado, {}, "ours.vhd", "vivado.vhd")
        kinds = {(d.component, d.kind, d.name) for d in report.diffs}
        self.assertIn(("only_ours", "only_in_ours", ""), kinds)
        self.assertIn(("only_viv", "only_in_vivado", ""), kinds)
        self.assertIn(("both", "mode", "a"), kinds)
        self.assertIn(("both", "extra_port", "b"), kinds)
        self.assertGreater(report.unexpected, 0)

    def test_report_does_not_copy_source_text(self) -> None:
        ours = _pkg(
            """
            component T is
              generic (G : integer := 1);
              port (A : in std_logic);
            end component;
            """
        )
        vivado = _pkg(
            """
            component T is
              generic (G : integer := 2);
              port (A : in std_logic);
            end component;
            """
        )
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            report_path = folder / "compare_report.txt"
            json_path = folder / "compare_report.json"
            ours_path = folder / "ours.vhd"
            vivado_path = folder / "unisim_VCOMP.vhd"
            ours_path.write_text(ours, encoding="utf-8")
            vivado_path.write_text(vivado, encoding="utf-8")
            rc = cv.main(
                [
                    "--ours",
                    str(ours_path),
                    "--vivado",
                    str(vivado_path),
                    "--type-map",
                    str(folder / "missing.yaml"),
                    "--report",
                    str(report_path),
                    "--json",
                    str(json_path),
                ]
            )
            self.assertEqual(rc, 0)
            text = report_path.read_text(encoding="utf-8")
            payload = json.loads(json_path.read_text(encoding="utf-8"))
            self.assertNotIn(SENTINEL, text)
            self.assertNotIn(SENTINEL, json.dumps(payload))
            self.assertNotIn("library ieee", text)
            self.assertIn("int:1", text)
            self.assertIn("int:2", text)
            self.assertEqual(payload["summary"]["unexpected"], 1)
            strict = cv.main(
                [
                    "--ours",
                    str(ours_path),
                    "--vivado",
                    str(vivado_path),
                    "--type-map",
                    str(folder / "missing.yaml"),
                    "--report",
                    str(report_path),
                    "--json",
                    str(json_path),
                    "--strict",
                ]
            )
            self.assertEqual(strict, 1)

    def test_strict_allows_only_expected_diffs(self) -> None:
        ours = _pkg(
            """
            component RAM32X1D is
              generic (INIT : integer := 0);
              port (O : out std_ulogic);
            end component;
            """
        )
        vivado = _pkg(
            """
            component RAM32X1D is
              generic (INIT : std_logic_vector(31 downto 0) := (others => '0'));
              port (O : out std_ulogic);
            end component;
            """
        )
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            ours_path = folder / "ours.vhd"
            vivado_path = folder / "v.vhd"
            map_path = folder / "type_map.yaml"
            ours_path.write_text(ours, encoding="utf-8")
            vivado_path.write_text(vivado, encoding="utf-8")
            map_path.write_text("RAM32X1D:\n  INIT: integer\n", encoding="utf-8")
            rc = cv.main(
                [
                    "--ours",
                    str(ours_path),
                    "--vivado",
                    str(vivado_path),
                    "--type-map",
                    str(map_path),
                    "--report",
                    str(folder / "r.txt"),
                    "--json",
                    str(folder / "r.json"),
                    "--strict",
                ]
            )
            self.assertEqual(rc, 0)

    def test_parse_failure_exits_nonzero_without_a_report(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            bad = folder / "bad.vhd"
            bad.write_text("component BROKEN is\n", encoding="utf-8")
            report = folder / "compare_report.txt"
            rc = cv.main(
                [
                    "--ours",
                    str(bad),
                    "--vivado",
                    str(bad),
                    "--report",
                    str(report),
                    "--json",
                    str(folder / "compare_report.json"),
                ]
            )
            self.assertEqual(rc, 2)
            self.assertFalse(report.exists())


class LocateTests(unittest.TestCase):
    def test_case_insensitive_search_from_root_and_leaf(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "Vivado"
            leaf = root / "Data" / "VHDL" / "src" / "Unisims"
            leaf.mkdir(parents=True)
            target = leaf / "unisim_VCOMP.vhd"
            target.write_text("component Z is end component;\n", encoding="utf-8")
            self.assertEqual(cv.locate_vcomp(root), target)
            self.assertEqual(cv.locate_vcomp(leaf), target)
            self.assertEqual(cv.locate_vcomp(target), target)

    def test_env_override_order(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            folder = Path(tmp)
            from_env = folder / "from_env.vhd"
            from_root = folder / "data" / "vhdl" / "src" / "unisims" / "unisim_VCOMP.vhd"
            from_root.parent.mkdir(parents=True)
            from_env.write_text("component E is end component;\n", encoding="utf-8")
            from_root.write_text("component R is end component;\n", encoding="utf-8")
            old_file = os.environ.get("VIVADO_VCOMP")
            old_root = os.environ.get("XILINX_VIVADO")
            try:
                os.environ["VIVADO_VCOMP"] = str(from_env)
                os.environ["XILINX_VIVADO"] = str(folder)
                self.assertEqual(cv.resolve_vivado(None), from_env)
                self.assertEqual(cv.resolve_vivado(str(folder)), from_root)
            finally:
                if old_file is None:
                    os.environ.pop("VIVADO_VCOMP", None)
                else:
                    os.environ["VIVADO_VCOMP"] = old_file
                if old_root is None:
                    os.environ.pop("XILINX_VIVADO", None)
                else:
                    os.environ["XILINX_VIVADO"] = old_root


if __name__ == "__main__":
    unittest.main()
