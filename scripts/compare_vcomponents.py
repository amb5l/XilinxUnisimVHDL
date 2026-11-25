#!/usr/bin/env python3
"""Compare generated/unisim_vcomponents.vhd with Vivado's unisim_VCOMP.vhd.

Vivado's sources stay on the machine that has Vivado installed. This script
reads that file only to compare component interfaces. The report names
components and normalised values; it does not copy Vivado source text.

    python scripts/compare_vcomponents.py --vivado "%XILINX_VIVADO%"

The Vivado root is read from --vivado, or from VIVADO_VCOMP (a file), or
from XILINX_VIVADO (a directory). The component package is
data/vhdl/src/unisims/unisim_VCOMP.vhd under that root. The filename match
is case-insensitive.

Exit status is 0 when both files parse, including when they differ.
--strict exits 1 when a difference is not marked expected (type_map).
A parse or path error exits 2.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from gen_vcomponents import ParseError as MapParseError
from gen_vcomponents import load_type_map

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_OURS = ROOT / "generated" / "unisim_vcomponents.vhd"
DEFAULT_MAP = ROOT / "config" / "type_map.yaml"
DEFAULT_REPORT = ROOT / "build" / "compare_report.txt"
DEFAULT_JSON = ROOT / "build" / "compare_report.json"

VCOMP_REL = ("data", "vhdl", "src", "unisims")
VCOMP_NAME = "unisim_vcomp.vhd"

MODES = {"in", "out", "inout", "buffer", "linkage"}
CLASSES = {"signal", "constant", "variable", "file", "quantity", "terminal"}
INTEGER_BASES = {"integer", "natural", "positive"}
VECTOR_BASES = {
    "std_logic_vector",
    "std_ulogic_vector",
    "bit_vector",
    "signed",
    "unsigned",
    "boolean_vector",
    "integer_vector",
    "real_vector",
    "time_vector",
}
EXPECTED = "expected (type_map)"
INT_VS_VEC = "integer-vs-vector"


class ParseError(Exception):
    pass


@dataclass
class Formal:
    name: str
    mode: str | None
    type_norm: str
    default_norm: str | None


@dataclass
class Component:
    name: str
    generics: list[Formal] = field(default_factory=list)
    ports: list[Formal] = field(default_factory=list)


@dataclass
class Diff:
    component: str
    kind: str
    name: str
    item: str
    ours: str | None
    vivado: str | None
    flags: list[str]

    @property
    def expected(self) -> bool:
        return EXPECTED in self.flags


@dataclass
class Report:
    ours_path: str
    vivado_path: str
    ours_count: int
    vivado_count: int
    diffs: list[Diff]

    @property
    def unexpected(self) -> int:
        return sum(1 for d in self.diffs if not d.expected)


def read_text(path: Path) -> str:
    data = path.read_bytes()
    if data.startswith(b"\xef\xbb\xbf"):
        data = data[3:]
    try:
        return data.decode("utf-8")
    except UnicodeDecodeError:
        return data.decode("latin-1")


def _child_ci(directory: Path, name: str) -> Path | None:
    try:
        children = list(directory.iterdir())
    except OSError:
        return None
    want = name.lower()
    for child in children:
        if child.name.lower() == want:
            return child
    return None


def locate_vcomp(spec: Path) -> Path:
    """Find unisim_VCOMP.vhd from a file path or a Vivado directory."""
    if spec.is_file():
        return spec
    if not spec.is_dir():
        raise FileNotFoundError(f"Vivado path does not exist: {spec}")
    parts = list(VCOMP_REL)
    for start in range(len(parts) + 1):
        cur = spec
        ok = True
        for part in parts[start:]:
            nxt = _child_ci(cur, part)
            if nxt is None or not nxt.is_dir():
                ok = False
                break
            cur = nxt
        if not ok:
            continue
        found = _child_ci(cur, VCOMP_NAME)
        if found is not None and found.is_file():
            return found
    raise FileNotFoundError(
        f"could not find {VCOMP_NAME} under {spec} "
        "(expected data/vhdl/src/unisims/unisim_VCOMP.vhd)"
    )


def resolve_vivado(cli: str | None) -> Path:
    if cli:
        spec = cli
    elif os.environ.get("VIVADO_VCOMP"):
        spec = os.environ["VIVADO_VCOMP"]
    elif os.environ.get("XILINX_VIVADO"):
        spec = os.environ["XILINX_VIVADO"]
    else:
        raise FileNotFoundError(
            "pass --vivado, or set VIVADO_VCOMP to the package file, "
            "or set XILINX_VIVADO to the Vivado root"
        )
    return locate_vcomp(Path(spec))


class Scan:
    def __init__(self, text: str):
        self.s = text
        self.n = len(text)
        self.i = 0
        self.line = 1

    def eof(self) -> bool:
        self.skip()
        return self.i >= self.n

    def skip(self) -> None:
        s, n = self.s, self.n
        i = self.i
        while i < n:
            c = s[i]
            if c in " \t\r\n":
                if c == "\n":
                    self.line += 1
                i += 1
                continue
            if c == "-" and i + 1 < n and s[i + 1] == "-":
                i += 2
                while i < n and s[i] != "\n":
                    i += 1
                continue
            if c == "/" and i + 1 < n and s[i + 1] == "*":
                i += 2
                while i + 1 < n and not (s[i] == "*" and s[i + 1] == "/"):
                    if s[i] == "\n":
                        self.line += 1
                    i += 1
                i = i + 2 if i + 1 < n else n
                continue
            break
        self.i = i

    def peek_ident(self) -> str | None:
        self.skip()
        if self.i >= self.n:
            return None
        if self.s[self.i] == "\\":
            end = self.s.find("\\", self.i + 1)
            if end < 0:
                return None
            return self.s[self.i : end + 1]
        c = self.s[self.i]
        if not (c.isalpha() or c == "_"):
            return None
        j = self.i + 1
        while j < self.n and (self.s[j].isalnum() or self.s[j] == "_"):
            j += 1
        return self.s[self.i:j]

    def keyword(self, word: str) -> bool:
        ident = self.peek_ident()
        if ident is None or ident.startswith("\\") or ident.lower() != word:
            return False
        self.i += len(ident)
        return True

    def punct(self, ch: str) -> bool:
        self.skip()
        if self.i < self.n and self.s[self.i] == ch:
            self.i += 1
            return True
        return False

    def consume_token(self) -> None:
        self.skip()
        if self.i >= self.n:
            return
        c = self.s[self.i]
        if c == '"':
            self.consume_string()
            return
        if c == "'":
            self.consume_tick()
            return
        if c == "\\":
            self.read_name()
            return
        if c.isalpha() or c == "_":
            ident = self.peek_ident()
            if ident is not None:
                self.i += len(ident)
                return
        if c == "\n":
            self.line += 1
        self.i += 1

    def consume_string(self) -> None:
        if self.i >= self.n or self.s[self.i] != '"':
            raise ParseError(f"line {self.line}: expected string")
        self.i += 1
        while self.i < self.n:
            c = self.s[self.i]
            if c == '"':
                if self.i + 1 < self.n and self.s[self.i + 1] == '"':
                    self.i += 2
                    continue
                self.i += 1
                return
            if c == "\n":
                raise ParseError(f"line {self.line}: unterminated string")
            self.i += 1
        raise ParseError(f"line {self.line}: unterminated string")

    def consume_tick(self) -> None:
        if self.i + 2 < self.n and self.s[self.i + 2] == "'":
            self.i += 3
            return
        self.i += 1

    def read_name(self) -> str:
        self.skip()
        if self.i >= self.n:
            raise ParseError(f"line {self.line}: expected a name")
        if self.s[self.i] == "\\":
            end = self.s.find("\\", self.i + 1)
            if end < 0:
                raise ParseError(f"line {self.line}: unterminated extended identifier")
            inner = self.s[self.i + 1 : end]
            self.i = end + 1
            return inner
        ident = self.peek_ident()
        if ident is None or ident.startswith("\\"):
            raise ParseError(f"line {self.line}: expected a name")
        self.i += len(ident)
        return ident

    def read_balanced(self) -> str:
        self.skip()
        if self.i >= self.n or self.s[self.i] != "(":
            raise ParseError(f"line {self.line}: expected '('")
        self.i += 1
        start = self.i
        depth = 1
        s, n = self.s, self.n
        while self.i < n and depth:
            c = s[self.i]
            if c == "-" and self.i + 1 < n and s[self.i + 1] == "-":
                while self.i < n and s[self.i] != "\n":
                    self.i += 1
                continue
            if c == "/" and self.i + 1 < n and s[self.i + 1] == "*":
                self.i += 2
                while self.i + 1 < n and not (s[self.i] == "*" and s[self.i + 1] == "/"):
                    if s[self.i] == "\n":
                        self.line += 1
                    self.i += 1
                self.i = self.i + 2 if self.i + 1 < n else n
                continue
            if c == '"':
                self.consume_string()
                continue
            if c == "'":
                self.consume_tick()
                continue
            if c == "(":
                depth += 1
            elif c == ")":
                depth -= 1
                if depth == 0:
                    body = s[start:self.i]
                    self.i += 1
                    return body
            if c == "\n":
                self.line += 1
            self.i += 1
        raise ParseError(f"line {self.line}: unclosed '('")

    def parse_component(self) -> Component:
        name = self.read_name()
        self.keyword("is")
        generics: list[Formal] = []
        ports: list[Formal] = []
        while True:
            if self.keyword("generic"):
                body = self.read_balanced()
                self.punct(";")
                generics.extend(parse_interface(body, "generic", self.line))
            elif self.keyword("port"):
                body = self.read_balanced()
                self.punct(";")
                ports.extend(parse_interface(body, "port", self.line))
            elif self.keyword("end"):
                break
            else:
                raise ParseError(
                    f"line {self.line}: expected generic, port, or end "
                    f"in component {name}"
                )
        if not self.keyword("component"):
            raise ParseError(f"line {self.line}: expected 'end component' after {name}")
        if self.peek_ident() is not None and not self.s[self.i] == "\\":
            # A following identifier may be the component name, or the next
            # declaration if the semicolon was omitted. Require ';' first when
            # the name does not match; always accept a matching name.
            ident = self.peek_ident()
            if ident is not None and ident.lower() == name.lower():
                self.read_name()
        elif self.peek_ident() is not None and self.s[self.i] == "\\":
            end_name = self.read_name()
            if end_name.lower() != name.lower():
                raise ParseError(
                    f"line {self.line}: end component {end_name} does not match {name}"
                )
        if not self.punct(";"):
            raise ParseError(f"line {self.line}: expected ';' after end component {name}")
        return Component(name=name, generics=generics, ports=ports)


def parse_components(text: str) -> dict[str, Component]:
    sc = Scan(text)
    found: dict[str, Component] = {}
    order: dict[str, str] = {}
    while not sc.eof():
        if sc.keyword("component"):
            comp = sc.parse_component()
            key = comp.name.lower()
            if key in found:
                raise ParseError(
                    f"line {sc.line}: component {comp.name} repeats {order[key]}"
                )
            found[key] = comp
            order[key] = comp.name
        else:
            sc.consume_token()
    return found


def _split_semicolons(body: str) -> list[str]:
    parts: list[str] = []
    buf: list[str] = []
    i, n = 0, len(body)
    depth = 0
    while i < n:
        c = body[i]
        if c == "-" and i + 1 < n and body[i + 1] == "-":
            while i < n and body[i] != "\n":
                buf.append(body[i])
                i += 1
            continue
        if c == "/" and i + 1 < n and body[i + 1] == "*":
            i += 2
            while i + 1 < n and not (body[i] == "*" and body[i + 1] == "/"):
                i += 1
            i = i + 2 if i + 1 < n else n
            continue
        if c == '"':
            buf.append(c)
            i += 1
            while i < n:
                buf.append(body[i])
                if body[i] == '"':
                    if i + 1 < n and body[i + 1] == '"':
                        buf.append(body[i + 1])
                        i += 2
                        continue
                    i += 1
                    break
                if body[i] == "\n":
                    raise ParseError("unterminated string in an interface list")
                i += 1
            continue
        if c == "'":
            if i + 2 < n and body[i + 2] == "'":
                buf.append(body[i : i + 3])
                i += 3
                continue
            buf.append(c)
            i += 1
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth = max(0, depth - 1)
        if c == ";" and depth == 0:
            parts.append("".join(buf))
            buf = []
            i += 1
            continue
        buf.append(c)
        i += 1
    tail = "".join(buf)
    if tail.strip():
        parts.append(tail)
    return parts


def _strip_comments(text: str) -> str:
    out: list[str] = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i = i + 2 if i + 1 < n else n
            continue
        if c == '"':
            out.append(c)
            i += 1
            while i < n:
                out.append(text[i])
                if text[i] == '"':
                    if i + 1 < n and text[i + 1] == '"':
                        out.append(text[i + 1])
                        i += 2
                        continue
                    i += 1
                    break
                i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def parse_interface(body: str, kind: str, line: int) -> list[Formal]:
    formals: list[Formal] = []
    for part in _split_semicolons(body):
        if not _strip_comments(part).strip():
            continue
        formals.extend(_parse_item(part, kind, line))
    return formals


def _parse_item(text: str, kind: str, line: int) -> list[Formal]:
    sc = Scan(_strip_comments(text))
    if sc.eof():
        return []
    ident = sc.peek_ident()
    if ident and not ident.startswith("\\") and ident.lower() in CLASSES:
        sc.keyword(ident.lower())
    names: list[str] = []
    while True:
        try:
            names.append(sc.read_name())
        except ParseError as exc:
            raise ParseError(f"line {line}: {exc}") from exc
        if sc.punct(","):
            continue
        break
    if not sc.punct(":"):
        raise ParseError(f"line {line}: expected ':' after {', '.join(names)}")
    mode = None
    ident = sc.peek_ident()
    if (
        kind == "port"
        and ident
        and not ident.startswith("\\")
        and ident.lower() in MODES
    ):
        mode = ident.lower()
        sc.keyword(mode)
    rest_at = sc.i
    # Keep the tail, then split on ':=' outside strings and parentheses.
    tail = sc.s[rest_at:]
    type_raw, default_raw = _split_default(tail)
    type_raw = re.sub(r"(?i)\s+\bbus\b\s*$", "", type_raw.strip())
    if not type_raw.strip():
        raise ParseError(f"line {line}: missing type for {', '.join(names)}")
    type_norm = norm_type(type_raw)
    default_norm = None if default_raw is None else norm_default(default_raw, type_norm)
    return [
        Formal(name=name, mode=mode, type_norm=type_norm, default_norm=default_norm)
        for name in names
    ]


def _split_default(text: str) -> tuple[str, str | None]:
    i, n = 0, len(text)
    depth = 0
    while i < n:
        c = text[i]
        if c == "-" and i + 1 < n and text[i + 1] == "-":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i = i + 2 if i + 1 < n else n
            continue
        if c == '"':
            i += 1
            while i < n:
                if text[i] == '"':
                    if i + 1 < n and text[i + 1] == '"':
                        i += 2
                        continue
                    i += 1
                    break
                i += 1
            continue
        if c == "'":
            if i + 2 < n and text[i + 2] == "'":
                i += 3
                continue
            i += 1
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth = max(0, depth - 1)
        if c == ":" and depth == 0 and i + 1 < n and text[i + 1] == "=":
            return text[:i], text[i + 2 :]
        i += 1
    return text, None


def norm_type(raw: str) -> str:
    s = _strip_comments(raw).strip()
    s = re.sub(r"\s+", " ", s)
    s = re.sub(r"\s*\(\s*", "(", s)
    s = re.sub(r"\s*\)\s*", ")", s)
    s = re.sub(r"\s+", " ", s).strip().lower()
    match = re.fullmatch(r"([a-z_][a-z0-9_]*)\((\d+)\s+(downto|to)\s+(\d+)\)", s)
    if match:
        base, a, _direction, b = match.group(1), int(match.group(2)), match.group(3), int(match.group(4))
        hi, lo = max(a, b), min(a, b)
        return f"{base}({hi} downto {lo})"
    return s


def base_name(type_norm: str) -> str:
    return type_norm.split("(", 1)[0].split()[0]


def type_kind(type_norm: str) -> str:
    base = base_name(type_norm)
    if base in INTEGER_BASES:
        return "integer"
    if base == "real":
        return "real"
    if base == "string":
        return "string"
    if base == "boolean":
        return "boolean"
    if base in VECTOR_BASES or base.endswith("_vector"):
        return "vector"
    if base in {"bit", "std_logic", "std_ulogic"}:
        return "scalar"
    return "other"


def vector_width(type_norm: str) -> int | None:
    match = re.fullmatch(r"[a-z_][a-z0-9_]*\((\d+) downto (\d+)\)", type_norm)
    if not match:
        return None
    hi, lo = int(match.group(1)), int(match.group(2))
    if hi < lo:
        return None
    return hi - lo + 1


def compact_expr(raw: str) -> str:
    """Lowercase keywords and drop decorative space, keeping string contents."""
    text = _strip_comments(raw).strip()
    out: list[str] = []
    i, n = 0, len(text)

    def pop_space() -> None:
        if out and out[-1] == " ":
            out.pop()

    while i < n:
        c = text[i]
        if c == '"':
            chars = ['"']
            i += 1
            while i < n:
                chars.append(text[i])
                if text[i] == '"':
                    if i + 1 < n and text[i + 1] == '"':
                        chars.append(text[i + 1])
                        i += 2
                        continue
                    i += 1
                    break
                i += 1
            pop_space()
            out.append("".join(chars))
            continue
        if c == "'":
            pop_space()
            if i + 2 < n and text[i + 2] == "'":
                out.append(text[i : i + 3])
                i += 3
                continue
            out.append(c)
            i += 1
            continue
        if c.isspace():
            if out and out[-1] not in " (,:" and out[-1] != " ":
                out.append(" ")
            i += 1
            continue
        if c in "(),:":
            pop_space()
            out.append(c)
            i += 1
            continue
        if c == "=" and i + 1 < n and text[i + 1] == ">":
            pop_space()
            out.append("=>")
            i += 2
            continue
        out.append(c.lower() if c.isalpha() else c)
        i += 1
    return "".join(out).strip()


def _fit_bits(bits: str, length: int | None, signed: bool) -> str:
    if length is None:
        return bits
    if len(bits) > length:
        return bits[-length:]
    if len(bits) < length:
        pad = bits[0] if signed and bits else "0"
        if pad not in {"0", "1"}:
            pad = "0"
        return pad * (length - len(bits)) + bits
    return bits


def _bits_from_literal(compact: str) -> str | None:
    match = re.fullmatch(
        r"(?P<length>\d+)?(?P<sign>[us])?(?P<base>[boxd])\"(?P<digits>[0-9a-fA-FxXzZ_]+)\"",
        compact,
    )
    if not match:
        return None
    length = int(match.group("length")) if match.group("length") else None
    signed = (match.group("sign") or "").lower() == "s"
    base = match.group("base").lower()
    digits = match.group("digits").replace("_", "")
    if base == "b":
        if not re.fullmatch(r"[01xzXZ]+", digits):
            return None
        bits = digits.lower()
    elif base == "x":
        parts = []
        for digit in digits:
            low = digit.lower()
            if low in "0123456789abcdef":
                parts.append(f"{int(low, 16):04b}")
            elif low == "x":
                parts.append("xxxx")
            elif low == "z":
                parts.append("zzzz")
            else:
                return None
        bits = "".join(parts)
    elif base == "o":
        parts = []
        for digit in digits:
            if digit not in "01234567":
                return None
            parts.append(f"{int(digit, 8):03b}")
        bits = "".join(parts)
    else:
        if length is None or not re.fullmatch(r"[0-9]+", digits):
            return None
        bits = f"{int(digits, 10):b}"
    return _fit_bits(bits, length, signed)


def _string_content(compact: str) -> str | None:
    if len(compact) < 2 or compact[0] != '"' or compact[-1] != '"':
        return None
    inner = compact[1:-1]
    if '"' in inner.replace('""', ""):
        return None
    return inner.replace('""', '"')


def norm_default(raw: str, type_norm: str) -> str:
    compact = compact_expr(raw)
    if compact == "":
        return "expr:"
    kind = type_kind(type_norm)
    if kind == "string":
        content = _string_content(compact)
        if content is not None:
            return "str:" + content
        return "expr:" + compact
    if kind == "boolean" and compact in {"true", "false"}:
        return "bool:" + compact
    if kind == "integer":
        parsed = _norm_integer(compact)
        if parsed is not None:
            return parsed
    if kind == "real":
        parsed = _norm_real(compact)
        if parsed is not None:
            return parsed
    if kind == "vector":
        bits = _vector_bits(compact, vector_width(type_norm))
        if bits is not None:
            return f"bits:{len(bits)}:{bits}"
    if kind == "scalar":
        char = re.fullmatch(r"'(.)'", compact)
        if char:
            return "bit:" + char.group(1).lower()
    if kind == "integer":
        return "expr:" + compact
    return "expr:" + compact


def _norm_integer(compact: str) -> str | None:
    plain = compact.replace("_", "")
    if re.fullmatch(r"[+-]?[0-9]+", plain):
        return "int:" + str(int(plain, 10))
    based = re.fullmatch(r"([0-9]+)#([0-9a-f]+)#", compact.replace("_", ""))
    if based:
        return "int:" + str(int(based.group(2), int(based.group(1))))
    return None


def _norm_real(compact: str) -> str | None:
    plain = compact.replace("_", "")
    if not re.fullmatch(r"[+-]?(?:\d+\.\d*|\.\d+|\d+)(?:e[+-]?\d+)?", plain):
        return None
    if re.fullmatch(r"[+-]?\d+", plain):
        # An integer token on a real generic is still that number.
        pass
    try:
        from decimal import Decimal, InvalidOperation

        value = Decimal(plain)
    except (InvalidOperation, ValueError):
        return None
    text = format(value, "f")
    if "." in text:
        text = text.rstrip("0").rstrip(".")
    return "real:" + text


def _vector_bits(compact: str, width: int | None) -> str | None:
    literal = _bits_from_literal(compact)
    if literal is not None:
        return literal
    others = re.fullmatch(r"\(others=>'(.)'\)", compact)
    if others and width is not None:
        return others.group(1).lower() * width
    if others and width is None:
        return None
    content = _string_content(compact)
    if content is not None and content and re.fullmatch(r"[01xzXZ]+", content):
        return content.lower()
    char = re.fullmatch(r"'(.)'", compact)
    if char and char.group(1).lower() in "01xz" and (width in {None, 1}):
        bit = char.group(1).lower()
        return bit if width is None else bit * width
    positional = re.fullmatch(r"\((?:'(.)')(?:,'(.)')*\)", compact)
    if positional:
        bits = re.findall(r"'(.)'", compact)
        if bits and all(b.lower() in "01xz" for b in bits):
            return "".join(b.lower() for b in bits)
    return None


def index_type_map(type_map: dict) -> dict[str, dict[str, dict]]:
    indexed: dict[str, dict[str, dict]] = {}
    for module, params in type_map.items():
        bucket = indexed.setdefault(module.lower(), {})
        for name, spec in params.items():
            bucket[name.lower()] = spec
    return indexed


def _ours_matches(type_norm: str, spec: dict) -> bool:
    want = str(spec.get("type", "")).strip().lower()
    if not want:
        return False
    base = base_name(type_norm)
    if want in INTEGER_BASES:
        return base in INTEGER_BASES
    if want in {"real", "string", "boolean"}:
        return base == want
    if want in VECTOR_BASES or want.endswith("_vector"):
        return base == want
    return type_norm == want or base == want


def _is_int_vs_vec(left: str, right: str) -> bool:
    return {type_kind(left), type_kind(right)} == {"integer", "vector"}


def _by_name(formals: list[Formal]) -> dict[str, Formal]:
    found: dict[str, Formal] = {}
    for formal in formals:
        found[formal.name.lower()] = formal
    return found


def _order_differs(ours: list[str], vivado: list[str]) -> bool:
    ours_set = set(ours)
    vivado_set = set(vivado)
    shared_ours = [name for name in ours if name in vivado_set]
    shared_vivado = [name for name in vivado if name in ours_set]
    return shared_ours != shared_vivado


def compare_sets(
    ours: dict[str, Component],
    vivado: dict[str, Component],
    type_map: dict,
) -> list[Diff]:
    indexed = index_type_map(type_map)
    diffs: list[Diff] = []
    for name in sorted(set(ours) | set(vivado)):
        if name not in ours:
            diffs.append(Diff(name, "only_in_vivado", "", "component", None, name, []))
            continue
        if name not in vivado:
            diffs.append(Diff(name, "only_in_ours", "", "component", name, None, []))
            continue
        diffs.extend(_compare_component(ours[name], vivado[name], indexed.get(name, {})))
    return diffs


def _compare_component(ours: Component, vivado: Component, specs: dict[str, dict]) -> list[Diff]:
    diffs: list[Diff] = []
    key = ours.name.lower()
    diffs.extend(_compare_formals(key, "generic", ours.generics, vivado.generics, specs))
    diffs.extend(_compare_formals(key, "port", ours.ports, vivado.ports, {}))
    return diffs


def _compare_formals(
    component: str,
    item: str,
    ours: list[Formal],
    vivado: list[Formal],
    specs: dict[str, dict],
) -> list[Diff]:
    diffs: list[Diff] = []
    ours_map = _by_name(ours)
    vivado_map = _by_name(vivado)
    names = sorted(set(ours_map) | set(vivado_map))
    for name in names:
        spec = specs.get(name, {})
        left = ours_map.get(name)
        right = vivado_map.get(name)
        if left is None:
            flags = [EXPECTED] if spec.get("skip") else []
            diffs.append(Diff(component, f"missing_{item}", name, item, None, right.type_norm if right else None, flags))
            continue
        if right is None:
            diffs.append(Diff(component, f"extra_{item}", name, item, left.type_norm, None, []))
            continue
        type_expected = False
        if left.type_norm != right.type_norm:
            flags = []
            if _is_int_vs_vec(left.type_norm, right.type_norm):
                flags.append(INT_VS_VEC)
            if spec.get("type") and _ours_matches(left.type_norm, spec):
                flags.append(EXPECTED)
                type_expected = True
            diffs.append(
                Diff(component, "type", name, item, left.type_norm, right.type_norm, flags)
            )
        if (left.mode or "") != (right.mode or ""):
            diffs.append(
                Diff(component, "mode", name, item, left.mode, right.mode, [])
            )
        if left.default_norm != right.default_norm:
            flags = [EXPECTED] if type_expected else []
            diffs.append(
                Diff(
                    component,
                    "default",
                    name,
                    item,
                    left.default_norm,
                    right.default_norm,
                    flags,
                )
            )
    ours_names = [f.name.lower() for f in ours]
    vivado_names = [f.name.lower() for f in vivado]
    if _order_differs(ours_names, vivado_names):
        diffs.append(
            Diff(
                component,
                f"{item}_order",
                "",
                item,
                ", ".join(ours_names),
                ", ".join(vivado_names),
                [],
            )
        )
    return diffs


def _count(diffs: list[Diff], kind: str, expected: bool | None = None) -> int:
    total = 0
    for diff in diffs:
        if diff.kind != kind:
            continue
        if expected is None or diff.expected == expected:
            total += 1
    return total


def summary_counts(diffs: list[Diff]) -> dict[str, int]:
    type_diffs = [d for d in diffs if d.kind == "type"]
    return {
        "only_in_vivado": _count(diffs, "only_in_vivado"),
        "only_in_ours": _count(diffs, "only_in_ours"),
        "missing_generics": _count(diffs, "missing_generic"),
        "missing_generics_expected": _count(diffs, "missing_generic", True),
        "extra_generics": _count(diffs, "extra_generic"),
        "missing_ports": _count(diffs, "missing_port"),
        "extra_ports": _count(diffs, "extra_port"),
        "type_differences": len(type_diffs),
        "integer_vs_vector": sum(1 for d in type_diffs if INT_VS_VEC in d.flags),
        "type_expected": sum(1 for d in type_diffs if d.expected),
        "mode_differences": _count(diffs, "mode"),
        "default_differences": _count(diffs, "default"),
        "default_expected": _count(diffs, "default", True),
        "port_order_differences": _count(diffs, "port_order"),
        "generic_order_differences": _count(diffs, "generic_order"),
        "unexpected": sum(1 for d in diffs if not d.expected),
    }


def render_text(report: Report) -> str:
    counts = summary_counts(report.diffs)
    lines = [
        "unisim component comparison",
        "Names and normalised values only. Vivado source text is not copied.",
        f"ours:   {report.ours_path} ({report.ours_count} components)",
        f"vivado: {report.vivado_path} ({report.vivado_count} components)",
        "",
        "summary",
        f"  only in vivado:       {counts['only_in_vivado']}",
        f"  only in ours:         {counts['only_in_ours']}",
        f"  missing generics:     {counts['missing_generics']} "
        f"(expected {counts['missing_generics_expected']})",
        f"  extra generics:       {counts['extra_generics']}",
        f"  missing ports:        {counts['missing_ports']}",
        f"  extra ports:          {counts['extra_ports']}",
        f"  type differences:     {counts['type_differences']} "
        f"(integer-vs-vector {counts['integer_vs_vector']}, "
        f"expected {counts['type_expected']})",
        f"  mode differences:     {counts['mode_differences']}",
        f"  default differences:  {counts['default_differences']} "
        f"(expected {counts['default_expected']})",
        f"  port order:           {counts['port_order_differences']}",
        f"  generic order:        {counts['generic_order_differences']}",
        f"  unexpected:           {counts['unexpected']}",
        "",
    ]
    by_comp: dict[str, list[Diff]] = {}
    for diff in report.diffs:
        by_comp.setdefault(diff.component, []).append(diff)
    if not by_comp:
        lines.append("no differences")
        lines.append("")
        return "\n".join(lines)
    for name in sorted(by_comp):
        lines.append(name)
        for diff in by_comp[name]:
            lines.extend(_format_diff(diff))
        lines.append("")
    return "\n".join(lines)


def _format_diff(diff: Diff) -> list[str]:
    flags = f" [{', '.join(diff.flags)}]" if diff.flags else ""
    if diff.kind == "only_in_vivado":
        return [f"  only in vivado{flags}"]
    if diff.kind == "only_in_ours":
        return [f"  only in ours{flags}"]
    if diff.kind in {"missing_generic", "missing_port"}:
        return [f"  {diff.item} {diff.name}: missing in ours{flags}"]
    if diff.kind in {"extra_generic", "extra_port"}:
        return [f"  {diff.item} {diff.name}: extra in ours{flags}"]
    if diff.kind in {"port_order", "generic_order"}:
        return [
            f"  {diff.item} order differs{flags}",
            f"    ours:   {diff.ours}",
            f"    vivado: {diff.vivado}",
        ]
    label = {"type": "type", "mode": "mode", "default": "default"}[diff.kind]
    return [
        f"  {diff.item} {diff.name}: {label} differs{flags}",
        f"    ours:   {diff.ours}",
        f"    vivado: {diff.vivado}",
    ]


def render_json(report: Report) -> str:
    counts = summary_counts(report.diffs)
    components: dict[str, list[dict]] = {}
    for diff in report.diffs:
        components.setdefault(diff.component, []).append(
            {
                "kind": diff.kind,
                "item": diff.item,
                "name": diff.name,
                "ours": diff.ours,
                "vivado": diff.vivado,
                "flags": list(diff.flags),
                "expected": diff.expected,
            }
        )
    payload = {
        "ours": report.ours_path,
        "vivado": report.vivado_path,
        "ours_components": report.ours_count,
        "vivado_components": report.vivado_count,
        "summary": counts,
        "only_in_vivado": sorted(
            d.component for d in report.diffs if d.kind == "only_in_vivado"
        ),
        "only_in_ours": sorted(
            d.component for d in report.diffs if d.kind == "only_in_ours"
        ),
        "components": [
            {"name": name, "diffs": components[name]} for name in sorted(components)
        ],
    }
    return json.dumps(payload, indent=2) + "\n"


def build_report(
    ours_text: str,
    vivado_text: str,
    type_map: dict,
    ours_path: str,
    vivado_path: str,
) -> Report:
    ours = parse_components(ours_text)
    vivado = parse_components(vivado_text)
    diffs = compare_sets(ours, vivado, type_map)
    return Report(ours_path, vivado_path, len(ours), len(vivado), diffs)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ours", type=Path, default=DEFAULT_OURS)
    parser.add_argument(
        "--vivado",
        help="Vivado root, unisims directory, or unisim_VCOMP.vhd file",
    )
    parser.add_argument("--type-map", type=Path, default=DEFAULT_MAP)
    parser.add_argument("--report", type=Path, default=DEFAULT_REPORT)
    parser.add_argument("--json", type=Path, default=DEFAULT_JSON)
    parser.add_argument(
        "--strict",
        action="store_true",
        help="exit 1 when a difference is not expected by config/type_map.yaml",
    )
    args = parser.parse_args(argv)
    try:
        vivado_path = resolve_vivado(args.vivado)
        if not args.ours.is_file():
            raise FileNotFoundError(f"generated package not found: {args.ours}")
        type_map = load_type_map(str(args.type_map)) if args.type_map.is_file() else {}
        report = build_report(
            read_text(args.ours),
            read_text(vivado_path),
            type_map,
            str(args.ours),
            str(vivado_path),
        )
    except (ParseError, MapParseError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    except FileNotFoundError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.json.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(render_text(report), encoding="utf-8")
    args.json.write_text(render_json(report), encoding="utf-8")
    counts = summary_counts(report.diffs)
    print(
        f"compared {report.ours_count} generated components with "
        f"{report.vivado_count} Vivado components: "
        f"{counts['unexpected']} unexpected, "
        f"{len(report.diffs) - counts['unexpected']} expected"
    )
    print(f"report: {args.report}")
    print(f"json:   {args.json}")
    if args.strict and counts["unexpected"]:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
