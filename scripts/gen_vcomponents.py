#!/usr/bin/env python3
"""Generate unisim.vcomponents from XilinxUnisimLibrary Verilog headers.

Each primitive in config/primitives.txt contributes one component when its
Verilog header parses, including lang skip. The header is parsed with
XIL_TIMING and XIL_DR left undefined, matching mk/nvc.mk. A vhdl row is
still declared from the Verilog header; mk/nvc.mk analyses
src/vhdl/<NAME>.vhd instead of the Verilog. A skip row is not analysed.

Parameter defaults map to VHDL generics as follows:

  * a string literal "TRUE" or "FALSE" -> boolean
  * any other string literal    -> string
  * an unsized integer          -> integer
  * a real literal              -> real
  * a 1-bit sized literal       -> bit
  * a wider sized literal       -> bit_vector of that width

config/type_map.yaml overrides the heuristic per module and parameter.
Ports become std_ulogic, or std_logic_vector(N-1 downto 0) when the Verilog
port is a vector.

Pure Python 3 (stdlib only).
"""

from __future__ import annotations

import argparse
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from unisim_sources import ROOT, UNISIMS_DIR
import primitives

TYPE_MAP = os.path.join(ROOT, "config", "type_map.yaml")
DEFAULT_OUT = os.path.join(ROOT, "generated", "unisim_vcomponents.vhd")

# Macros left undefined by the NVC build. Unknown macros are also undefined.
UNDEFINED_BY_DEFAULT = True

VHDL_RESERVED = {
    "abs", "access", "after", "alias", "all", "and", "architecture", "array",
    "assert", "assume", "assume_guarantee", "attribute", "begin", "block",
    "body", "buffer", "bus", "case", "component", "configuration", "constant",
    "context", "cover", "default", "disconnect", "downto", "else", "elsif",
    "end", "entity", "exit", "fairness", "file", "for", "force", "function",
    "generate", "generic", "group", "guarded", "if", "impure", "in", "inertial",
    "inout", "is", "label", "library", "linkage", "literal", "loop", "map",
    "mod", "nand", "new", "next", "nor", "not", "null", "of", "on", "open",
    "or", "others", "out", "package", "parameter", "port", "postponed",
    "procedure", "process", "property", "protected", "pure", "range", "record",
    "register", "reject", "release", "rem", "report", "restrict",
    "restrict_guarantee", "return", "rol", "ror", "select", "sequence",
    "severity", "shared", "signal", "sla", "sll", "sra", "srl", "strong",
    "subtype", "then", "to", "transport", "type", "unaffected", "units",
    "until", "use", "variable", "vmode", "vprop", "vunit", "wait", "when",
    "while", "with", "xnor", "xor",
}

NET_TYPES = {
    "wire", "reg", "logic", "bit", "tri", "wand", "wor", "tri0", "tri1",
    "trireg", "supply0", "supply1", "uwire", "var", "signed", "unsigned",
}

TYPE_KEYWORDS = {"integer", "real", "realtime", "time", "string", "genvar"}

SIZED_RE = re.compile(
    r"^(\d+)'([sS])?([bBoOdDhH])([0-9a-fA-FxzXZ_]+)$"
)
INT_RE = re.compile(r"^[+-]?\d+$")
REAL_RE = re.compile(
    r"^[+-]?(?:\d+\.\d*|\.\d+)(?:[eE][+-]?\d+)?$|^[+-]?\d+[eE][+-]?\d+$"
)
IDENT_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_$]*$")


class ParseError(Exception):
    pass


# ---------------------------------------------------------------------------
# Text preparation
# ---------------------------------------------------------------------------

def strip_comments(text: str) -> str:
    out: list[str] = []
    i = 0
    n = len(text)
    while i < n:
        c = text[i]
        if c == '"':
            j = i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == '"':
                    j += 1
                    break
                j += 1
            out.append(text[i:j])
            i = j
        elif text.startswith("//", i):
            j = text.find("\n", i)
            if j < 0:
                break
            out.append("\n")
            i = j + 1
        elif text.startswith("/*", i):
            j = text.find("*/", i + 2)
            if j < 0:
                break
            out.append("\n" * text[i:j].count("\n"))
            i = j + 2
        else:
            out.append(c)
            i += 1
    return "".join(out)


def preprocess(text: str) -> str:
    """Evaluate `ifdef / `ifndef / `else / `elsif / `endif.

    No macros are predefined. `define inside a taken branch is honoured so
    that a header can test a macro it just set; XIL_TIMING and XIL_DR are
    not defined.
    """
    defines: set[str] = set()
    # frames: parent was active, this branch is active, a branch already taken
    stack: list[tuple[bool, bool, bool]] = []
    out: list[str] = []

    def active() -> bool:
        return all(frame[1] for frame in stack)

    for line in text.splitlines(keepends=True):
        stripped = line.strip()
        mdef = re.match(r"`define\s+(\w+)", stripped)
        mundef = re.match(r"`undef\s+(\w+)", stripped)
        mifdef = re.match(r"`ifdef\s+(\w+)", stripped)
        mifndef = re.match(r"`ifndef\s+(\w+)", stripped)
        melsif = re.match(r"`elsif\s+(\w+)", stripped)
        if mifdef or mifndef:
            parent = active()
            name = (mifdef or mifndef).group(1)
            cond = name in defines
            if mifndef:
                cond = not cond
            taken = parent and cond
            stack.append((parent, taken, taken))
            continue
        if melsif:
            if not stack:
                raise ParseError("elsif without ifdef")
            parent, _cur, seen = stack[-1]
            if (not parent) or seen:
                stack[-1] = (parent, False, seen)
            else:
                cond = melsif.group(1) in defines
                stack[-1] = (parent, cond, cond)
            continue
        if stripped.startswith("`else"):
            if not stack:
                raise ParseError("else without ifdef")
            parent, _cur, seen = stack[-1]
            if (not parent) or seen:
                stack[-1] = (parent, False, True)
            else:
                stack[-1] = (parent, True, True)
            continue
        if stripped.startswith("`endif"):
            if not stack:
                raise ParseError("endif without ifdef")
            stack.pop()
            continue
        if active():
            if mdef:
                defines.add(mdef.group(1))
            elif mundef:
                defines.discard(mundef.group(1))
            out.append(line)
    if stack:
        raise ParseError("unclosed ifdef")
    return "".join(out)


# ---------------------------------------------------------------------------
# Scanner
# ---------------------------------------------------------------------------

class Scan:
    def __init__(self, text: str, filename: str):
        self.text = text
        self.n = len(text)
        self.i = 0
        self.filename = filename

    def _fail(self, msg: str) -> ParseError:
        line = self.text.count("\n", 0, self.i) + 1
        return ParseError(f"{self.filename}:{line}: {msg}")

    def skip(self) -> None:
        while self.i < self.n and self.text[self.i] in " \t\r\n":
            self.i += 1

    def peek_kw(self) -> str | None:
        self.skip()
        m = re.match(r"[A-Za-z_][A-Za-z0-9_$]*", self.text[self.i:])
        return m.group(0) if m else None

    def starts(self, word: str) -> bool:
        return self.peek_kw() == word

    def eat(self, word: str) -> bool:
        if self.starts(word):
            self.i += len(word)
            return True
        return False

    def expect(self, word: str) -> None:
        if not self.eat(word):
            got = self.text[self.i:self.i + 24].replace("\n", " ")
            raise self._fail(f"expected {word!r}, got {got!r}")

    def ident(self) -> str:
        self.skip()
        if self.i < self.n and self.text[self.i] == "\\":
            j = self.text.find(" ", self.i)
            if j < 0:
                raise self._fail("unterminated escaped identifier")
            name = self.text[self.i + 1:j]
            self.i = j + 1
            return name
        m = re.match(r"[A-Za-z_][A-Za-z0-9_$]*", self.text[self.i:])
        if not m:
            raise self._fail("expected identifier")
        self.i += len(m.group(0))
        return m.group(0)

    def punct(self, ch: str) -> bool:
        self.skip()
        if self.i < self.n and self.text[self.i] == ch:
            self.i += 1
            return True
        return False

    def expect_punct(self, ch: str) -> None:
        if not self.punct(ch):
            raise self._fail(f"expected {ch!r}")

    def expr_until(self, terminators: str) -> str:
        """Read an expression, stopping at an un-nested terminator."""
        self.skip()
        start = self.i
        depth_paren = depth_brack = depth_brace = 0
        in_str = False
        while self.i < self.n:
            c = self.text[self.i]
            if in_str:
                if c == "\\":
                    self.i += 2
                    continue
                if c == '"':
                    in_str = False
                self.i += 1
                continue
            if c == '"':
                in_str = True
                self.i += 1
                continue
            # A requested terminator at depth 0 ends the expression, even
            # when that character is also a nesting closer (']', ')').
            if (c in terminators or c == ";") and depth_paren == depth_brack == depth_brace == 0:
                break
            if c == "(":
                depth_paren += 1
            elif c == ")":
                if depth_paren == 0:
                    break
                depth_paren -= 1
            elif c == "[":
                depth_brack += 1
            elif c == "]":
                if depth_brack == 0:
                    break
                depth_brack -= 1
            elif c == "{":
                depth_brace += 1
            elif c == "}":
                if depth_brace == 0:
                    break
                depth_brace -= 1
            self.i += 1
        expr = self.text[start:self.i].strip()
        if not expr:
            raise self._fail("empty expression")
        return re.sub(r"\s+", "", expr)


def _range(scan: Scan) -> tuple[str, str] | None:
    scan.skip()
    if not scan.punct("["):
        return None
    msb = scan.expr_until(":")
    scan.expect_punct(":")
    lsb = scan.expr_until("]")
    scan.expect_punct("]")
    return msb, lsb


# ---------------------------------------------------------------------------
# Literals and types
# ---------------------------------------------------------------------------

class Lit:
    def __init__(self, kind: str, **kw):
        self.kind = kind
        self.__dict__.update(kw)


def parse_literal(expr: str) -> Lit | None:
    e = expr.strip()
    if len(e) >= 2 and e[0] == '"' and e[-1] == '"':
        return Lit("string", text=_verilog_string(e))
    m = SIZED_RE.match(e)
    if m:
        width = int(m.group(1))
        base = m.group(3).lower()
        digits = m.group(4).replace("_", "")
        return Lit("sized", width=width, base=base, digits=digits)
    if INT_RE.match(e):
        return Lit("int", value=int(e))
    if REAL_RE.match(e):
        return Lit("real", text=_vhdl_real(e))
    # Replication of a sized or unsized 0/1: {32{1'b0}} or {8{1'b1}}
    rep = re.match(r"^\{(\d+)\{(\d+)'([bBhH])([01]+)\}\}$", e)
    if rep:
        count = int(rep.group(1))
        width = int(rep.group(2))
        bit = rep.group(4)
        if len(bit) == width and set(bit) <= {"0", "1"}:
            return Lit("sized", width=count * width, base="b", digits=bit * count)
    return None


def _verilog_string(quoted: str) -> str:
    body = quoted[1:-1]
    out: list[str] = []
    i = 0
    while i < len(body):
        if body[i] == "\\" and i + 1 < len(body):
            n = body[i + 1]
            mapping = {"n": "\n", "t": "\t", '"': '"', "\\": "\\"}
            out.append(mapping.get(n, n))
            i += 2
        else:
            out.append(body[i])
            i += 1
    return "".join(out)


def _vhdl_real(text: str) -> str:
    if text.startswith("."):
        text = "0" + text
    elif text.startswith("-."):
        text = "-0" + text[1:]
    elif text.startswith("+."):
        text = "0" + text[2:]
    if re.match(r"^[+-]?\d+$", text.split("e")[0].split("E")[0]) and re.search(r"[eE]", text):
        # 1e-9 -> 1.0e-9
        text = re.sub(r"^([+-]?\d+)([eE])", r"\1.0\2", text)
    if "." not in text and "e" not in text.lower():
        text += ".0"
    return text


def _bits(width: int, base: str, digits: str) -> str:
    """Return a width-bit string of 0/1/X/Z, MSB first."""
    if any(c in digits.lower() for c in "xz"):
        if base == "b":
            raw = digits
        else:
            raise ParseError(f"X/Z in non-binary literal {width}'{base}{digits}")
        raw = raw.replace("x", "X").replace("z", "Z")
        if len(raw) > width:
            raw = raw[-width:]
        return raw.rjust(width, "0")
    bmap = {"b": 2, "o": 8, "d": 10, "h": 16}
    value = int(digits, bmap[base]) if digits else 0
    return format(value, f"0{width}b")[-width:]


def _vhdl_slv_default(bits: str) -> str:
    if set(bits) == {"0"}:
        return "(others => '0')"
    if set(bits) == {"1"}:
        return "(others => '1')"
    return _vhdl_bitstring(bits)


def _vhdl_bitstring(bits: str) -> str:
    """Bit-string literal: X\"...\" when the width is a multiple of 4."""
    if bits and set(bits) <= set("01") and len(bits) % 4 == 0:
        hexdigits = []
        for i in range(0, len(bits), 4):
            hexdigits.append(format(int(bits[i:i + 4], 2), "X"))
        return 'X"' + "".join(hexdigits) + '"'
    return '"' + bits + '"'


def _fits_integer(bits: str) -> int | None:
    if any(c in bits for c in "XZ"):
        return None
    value = int(bits, 2) if bits else 0
    # VHDL INTEGER is at least 32-bit two's complement. Accept the unsigned
    # magnitude when it fits, and a 32-bit pattern whose high bit is set
    # when it is exactly 32 bits (the usual Xilinx "all ones" mask).
    if -2147483648 <= value <= 2147483647:
        return value
    if len(bits) == 32 and bits[0] == "1":
        signed = value - (1 << 32)
        if -2147483648 <= signed <= 2147483647:
            return signed
    return None


class Generic:
    def __init__(self, name: str, vhdl_type: str, default: str):
        self.name = name
        self.vhdl_type = vhdl_type
        self.default = default


class Port:
    def __init__(self, name: str, direction: str, vhdl_type: str):
        self.name = name
        self.direction = direction
        self.vhdl_type = vhdl_type


class Component:
    def __init__(self, name: str, generics: list[Generic], ports: list[Port], source: str,
                 lang: str = "vlog", note: str = "", parsed: bool = True):
        self.name = name
        self.generics = generics
        self.ports = ports
        self.source = source
        self.lang = lang
        self.note = note
        self.parsed = parsed


# ---------------------------------------------------------------------------
# Header parser
# ---------------------------------------------------------------------------

def _eval_int(expr: str, env: dict[str, int]) -> int | None:
    e = expr.strip()
    if INT_RE.match(e):
        return int(e)
    if e in env:
        return env[e]
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_$]*|\d+)\s*([+-])\s*(\d+)$", expr.replace(" ", ""))
    # expr may already have spaces removed by caller; try both
    compact = re.sub(r"\s+", "", expr)
    m = re.match(r"^([A-Za-z_][A-Za-z0-9_$]*)([+-])(\d+)$", compact)
    if m and m.group(1) in env:
        base = env[m.group(1)]
        off = int(m.group(3))
        return base + off if m.group(2) == "+" else base - off
    m = re.match(r"^(\d+)([+-])(\d+)$", compact)
    if m:
        base = int(m.group(1))
        off = int(m.group(3))
        return base + off if m.group(2) == "+" else base - off
    return None


def _port_type(bounds: tuple[str, str] | None, env: dict[str, int]) -> str:
    if bounds is None:
        return "std_ulogic"
    msb_s, lsb_s = bounds
    msb = _eval_int(msb_s, env)
    lsb = _eval_int(lsb_s, env)
    if msb is None or lsb is None:
        # Symbolic width. Prefer the form (E-1 downto 0) / (0 to E-1).
        compact_m = re.sub(r"\s+", "", msb_s)
        compact_l = re.sub(r"\s+", "", lsb_s)
        if compact_l in {"0"} and compact_m.endswith("-1"):
            return f"std_logic_vector({_vhdl_expr(compact_m)} downto 0)"
        if compact_m in {"0"} and compact_l.endswith("-1"):
            width = compact_l[:-2]
            return f"std_logic_vector({_vhdl_expr(width)}-1 downto 0)"
        raise ParseError(f"cannot resolve port range [{msb_s}:{lsb_s}]")
    width = abs(msb - lsb) + 1
    if width <= 0:
        raise ParseError(f"non-positive port width [{msb_s}:{lsb_s}]")
    if width == 1 and bounds is not None:
        # A Verilog vector of width 1 is still a vector.
        return "std_logic_vector(0 downto 0)"
    return f"std_logic_vector({width - 1} downto 0)"


def _vhdl_expr(expr: str) -> str:
    return expr


def _classify_generic(name: str, type_kw: str | None, bounds, expr: str,
                      override: dict | None) -> Generic:
    if override and override.get("skip"):
        return None  # type: ignore[return-value]
    lit = parse_literal(expr)
    kind = None
    width = None
    default = None
    if override and override.get("type"):
        kind = override["type"]
        width = override.get("width")
    elif type_kw == "integer":
        kind = "integer"
    elif type_kw in {"real", "realtime"}:
        kind = "real"
    elif type_kw == "string":
        kind = "string"
    elif lit is not None:
        kind = {"string": "string", "int": "integer", "real": "real",
                "sized": "logic"}[lit.kind]
        if lit.kind == "sized":
            width = lit.width
    else:
        raise ParseError(f"parameter {name}: unrecognised default {expr}")

    if kind == "string":
        if lit is None or lit.kind != "string":
            raise ParseError(f"parameter {name}: string generic without a string default")
        # Vivado's unisim_VCOMP maps a TRUE/FALSE string parameter to boolean.
        # An explicit type_map type keeps the override (including string).
        if (not override or not override.get("type")) and lit.text.upper() in {"TRUE", "FALSE"}:
            word = "TRUE" if lit.text.upper() == "TRUE" else "FALSE"
            return Generic(name, "boolean", word)
        default = '"' + lit.text.replace('"', '""') + '"'
        return Generic(name, "string", default)
    if kind == "integer":
        if lit is not None and lit.kind == "int":
            default = str(lit.value)
        elif lit is not None and lit.kind == "sized":
            bits = _bits(lit.width, lit.base, lit.digits)
            as_int = _fits_integer(bits)
            if as_int is None:
                raise ParseError(
                    f"parameter {name}: sized value {expr} does not fit in INTEGER"
                )
            default = str(as_int)
        elif lit is not None and lit.kind == "real":
            raise ParseError(f"parameter {name}: real default cannot be an integer generic")
        else:
            raise ParseError(f"parameter {name}: no integer default in {expr}")
        return Generic(name, "integer", default)
    if kind == "real":
        if lit is not None and lit.kind == "real":
            default = lit.text
        elif lit is not None and lit.kind == "int":
            default = f"{lit.value}.0"
        else:
            raise ParseError(f"parameter {name}: no real default in {expr}")
        return Generic(name, "real", default)
    if kind == "std_logic_vector":
        if width is None:
            if lit is not None and lit.kind == "sized":
                width = lit.width
            elif bounds is not None:
                msb = _eval_int(bounds[0], {})
                lsb = _eval_int(bounds[1], {})
                if msb is None or lsb is None:
                    raise ParseError(f"parameter {name}: vector width is not constant")
                width = abs(msb - lsb) + 1
            else:
                raise ParseError(f"parameter {name}: std_logic_vector width unknown")
        if lit is not None and lit.kind == "sized":
            bits = _bits(lit.width, lit.base, lit.digits)
            if len(bits) != width:
                # Literal width wins; the declared range should match.
                if lit.width != width:
                    bits = _bits(width, lit.base, lit.digits) if False else bits
                width = len(bits)
            default = _vhdl_slv_default(bits)
        elif lit is not None and lit.kind == "int":
            bits = format(lit.value, f"0{width}b")[-width:]
            default = _vhdl_slv_default(bits)
        else:
            default = "(others => '0')"
        if width == 1:
            vtype = "std_logic_vector(0 downto 0)"
        else:
            vtype = f"std_logic_vector({width - 1} downto 0)"
        return Generic(name, vtype, default)
    if kind == "logic":
        if width is None:
            if lit is not None and lit.kind == "sized":
                width = lit.width
            elif bounds is not None:
                msb = _eval_int(bounds[0], {})
                lsb = _eval_int(bounds[1], {})
                if msb is None or lsb is None:
                    raise ParseError(f"parameter {name}: vector width is not constant")
                width = abs(msb - lsb) + 1
            else:
                raise ParseError(f"parameter {name}: logic generic width unknown")
        if lit is not None and lit.kind == "sized":
            bits = _bits(lit.width, lit.base, lit.digits)
            width = len(bits)
        elif lit is not None and lit.kind == "int":
            bits = format(lit.value, f"0{width}b")[-width:]
        else:
            bits = "0" * width
        if any(c not in "01" for c in bits):
            # bit / bit_vector cannot represent X or Z. Keep std_logic_vector.
            default = _vhdl_slv_default(bits)
            if width == 1:
                vtype = "std_logic_vector(0 downto 0)"
            else:
                vtype = f"std_logic_vector({width - 1} downto 0)"
            return Generic(name, vtype, default)
        if width == 1:
            return Generic(name, "bit", "'" + bits + "'")
        return Generic(name, f"bit_vector({width - 1} downto 0)", _vhdl_bitstring(bits))
    raise ParseError(f"parameter {name}: unsupported type {kind}")


def _parse_param_type(scan: Scan) -> tuple[str | None, tuple[str, str] | None]:
    type_kw = None
    if scan.peek_kw() in TYPE_KEYWORDS:
        type_kw = scan.peek_kw()
        scan.eat(type_kw)
    if scan.eat("signed") or scan.eat("unsigned"):
        pass
    bounds = _range(scan)
    return type_kw, bounds


def _parse_param_decl(scan: Scan, overrides: dict, env: dict[str, int]) -> list[Generic]:
    scan.expect("parameter")
    type_kw, bounds = _parse_param_type(scan)
    generics: list[Generic] = []
    while True:
        name = scan.ident()
        # unpacked dimension is not used on unisim parameters; reject quietly
        # by failing if a second range appears before '='
        scan.expect_punct("=")
        expr = scan.expr_until(",);")
        ov = overrides.get(name)
        try:
            generic = _classify_generic(name, type_kw, bounds, expr, ov)
        except ParseError:
            raise
        if generic is not None:
            generics.append(generic)
            if generic.vhdl_type == "integer":
                try:
                    env[name] = int(generic.default)
                except ValueError:
                    pass
        saved = scan.i
        if scan.punct(","):
            nxt = scan.peek_kw()
            if nxt in {None, "parameter", "input", "output", "inout"} or nxt in TYPE_KEYWORDS:
                scan.i = saved
                break
            continue
        break
    return generics


def _parse_direction_decl(scan: Scan, env: dict[str, int]) -> list[Port]:
    direction = scan.peek_kw()
    if direction not in {"input", "output", "inout"}:
        raise scan._fail("expected a port direction")
    scan.eat(direction)
    # optional net type / signed, possibly repeated (output reg, input wire)
    while scan.peek_kw() in NET_TYPES or scan.peek_kw() in TYPE_KEYWORDS:
        kw = scan.peek_kw()
        if kw in TYPE_KEYWORDS and kw not in {"integer", "real", "time"}:
            break
        scan.eat(kw)
    bounds = _range(scan)
    vtype = _port_type(bounds, env)
    mode = {"input": "in", "output": "out", "inout": "inout"}[direction]
    ports: list[Port] = []
    while True:
        name = scan.ident()
        extra = _range(scan)  # unpacked
        if extra is not None:
            raise scan._fail(f"unpacked port dimension on {name} is not supported")
        ports.append(Port(name, mode, vtype))
        saved = scan.i
        if scan.punct(","):
            nxt = scan.peek_kw()
            if nxt in {"input", "output", "inout", "parameter", None}:
                # The comma separates declarations. Give it back.
                scan.i = saved
                break
            continue
        break
    return ports


def parse_module(text: str, filename: str, overrides: dict) -> Component:
    scan = Scan(text, filename)
    # first module
    while True:
        scan.skip()
        if scan.i >= scan.n:
            raise ParseError(f"{filename}: no module")
        if scan.eat("module"):
            break
        scan.i += 1
    name = scan.ident()
    generics: list[Generic] = []
    ports: list[Port] = []
    env: dict[str, int] = {}

    scan.skip()
    if scan.punct("#"):
        scan.expect_punct("(")
        while True:
            scan.skip()
            if scan.punct(")"):
                break
            if scan.starts("parameter"):
                generics.extend(_parse_param_decl(scan, overrides, env))
            else:
                raise scan._fail("expected parameter in ANSI parameter list")
            scan.skip()
            if scan.punct(","):
                continue
            if scan.punct(")"):
                break
            raise scan._fail("expected ',' or ')' after parameter")

    scan.skip()
    if scan.punct("("):
        scan.skip()
        if scan.peek_kw() in {"input", "output", "inout", "parameter"}:
            # ANSI ports (and the occasional parameter mixed in).
            # Do not consume ')' in the loop test: that drops the closer
            # the iteration below still needs to see.
            while True:
                scan.skip()
                if scan.punct(")"):
                    break
                if scan.starts("parameter"):
                    generics.extend(_parse_param_decl(scan, overrides, env))
                elif scan.peek_kw() in {"input", "output", "inout"}:
                    ports.extend(_parse_direction_decl(scan, env))
                else:
                    raise scan._fail("expected a port declaration")
                scan.skip()
                if scan.punct(","):
                    continue
                if scan.punct(")"):
                    break
                raise scan._fail("expected ',' or ')' after port")
        else:
            # Non-ANSI name list. Directions follow the semicolon.
            order: list[str] = []
            if not scan.punct(")"):
                while True:
                    order.append(scan.ident())
                    if scan.punct(","):
                        if scan.punct(")"):
                            break
                        continue
                    scan.expect_punct(")")
                    break
            scan.expect_punct(";")
            declared: dict[str, Port] = {}
            # Port and parameter declarations may be interrupted by
            # localparam / net declarations (DCM_ADV does this).
            skip_kw = {
                "localparam", "wire", "reg", "integer", "real", "time",
                "realtime", "genvar", "event", "tri", "tri0", "tri1",
                "wand", "wor", "supply0", "supply1", "logic", "bit",
                "defparam", "uwire",
            }
            stop_kw = {
                "assign", "always", "initial", "specify", "function",
                "task", "generate", "endmodule", "begin", "module",
                "for", "if", "case", "casex", "casez",
            }
            while True:
                scan.skip()
                kw = scan.peek_kw()
                if kw == "parameter":
                    generics.extend(_parse_param_decl(scan, overrides, env))
                    scan.expect_punct(";")
                elif kw in {"input", "output", "inout"}:
                    for port in _parse_direction_decl(scan, env):
                        declared[port.name] = port
                    scan.expect_punct(";")
                elif kw in skip_kw:
                    scan.eat(kw)
                    scan.expr_until(";")
                    scan.expect_punct(";")
                elif kw in stop_kw or kw is None:
                    break
                else:
                    break
            if not order:
                order = list(declared)
            for pname in order:
                if pname not in declared:
                    raise ParseError(f"{filename}: port {pname} has no direction")
                ports.append(declared[pname])
            return Component(name, generics, ports, filename)
        scan.expect_punct(";")
    else:
        scan.expect_punct(";")
        # declarations may still follow a bare `module name;`
        while True:
            kw = scan.peek_kw()
            if kw == "parameter":
                generics.extend(_parse_param_decl(scan, overrides, env))
                scan.expect_punct(";")
            elif kw in {"input", "output", "inout"}:
                ports.extend(_parse_direction_decl(scan, env))
                scan.expect_punct(";")
            else:
                break
    return Component(name, generics, ports, filename)


# ---------------------------------------------------------------------------
# type_map.yaml (a small subset: maps and scalars, no PyYAML)
# ---------------------------------------------------------------------------

def load_type_map(path: str) -> dict[str, dict[str, dict]]:
    if not os.path.isfile(path):
        return {}
    modules: dict[str, dict[str, dict]] = {}
    current_mod: str | None = None
    current_param: str | None = None
    with open(path, encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = raw.split("#", 1)[0].rstrip()
            if not line.strip():
                continue
            indent = len(line) - len(line.lstrip(" "))
            key, sep, value = line.strip().partition(":")
            if not sep:
                raise ParseError(f"{path}:{lineno}: expected key:")
            key = key.strip().strip('"').strip("'")
            value = value.strip().strip('"').strip("'")
            if indent == 0:
                current_mod = key
                current_param = None
                modules.setdefault(current_mod, {})
                if value:
                    raise ParseError(f"{path}:{lineno}: module entry must be a map")
            elif indent <= 2:
                if current_mod is None:
                    raise ParseError(f"{path}:{lineno}: parameter outside a module")
                current_param = key
                if value:
                    modules[current_mod][current_param] = {"type": value}
                else:
                    modules[current_mod][current_param] = {}
            else:
                if current_mod is None or current_param is None:
                    raise ParseError(f"{path}:{lineno}: field outside a parameter")
                entry = modules[current_mod][current_param]
                if key == "width":
                    entry["width"] = int(value)
                elif key == "skip":
                    entry["skip"] = value.lower() in {"true", "yes", "1"}
                elif key == "type":
                    entry["type"] = value
                else:
                    raise ParseError(f"{path}:{lineno}: unknown field {key}")
    return modules


# ---------------------------------------------------------------------------
# VHDL
# ---------------------------------------------------------------------------

def vhdl_name(name: str) -> str:
    if name.lower() in VHDL_RESERVED or not IDENT_RE.match(name):
        return "\\" + name + "\\"
    return name


def emit(components: list[Component]) -> str:
    lines: list[str] = []
    a = lines.append
    a("-- unisim.vcomponents")
    a("--")
    a("-- Generated by scripts/gen_vcomponents.py from the Verilog headers in")
    a("-- XilinxUnisimLibrary (Apache License 2.0). Do not edit by hand;")
    a("-- change the generator, config/type_map.yaml, or config/primitives.txt")
    a("-- and run `make vcomponents`.")
    a("--")
    a("-- config/primitives.txt selects vlog, vhdl, or skip. skip is not")
    a("-- analysed; its component is still declared when the header parses.")
    a("-- vhdl is analysed from src/vhdl/<NAME>.vhd instead of the Verilog.")
    a("--")
    a("-- Vivado's VHDL unisim sources are not used. XIL_TIMING and XIL_DR")
    a("-- are undefined, so parameters those macros hide are omitted.")
    a("-- Sized parameters are bit (width 1) or bit_vector. A string default")
    a("-- of TRUE or FALSE is boolean. Ports stay std_ulogic / std_logic_vector.")
    a("--")
    a("-- Copyright Xilinx, Inc. / Advanced Micro Devices, Inc. (source models)")
    a("-- Licensed under the Apache License, Version 2.0.")
    a("")
    a("library ieee;")
    a("use ieee.std_logic_1164.all;")
    a("")
    a("package vcomponents is")
    for comp in components:
        a("")
        a(f"  -- {os.path.basename(comp.source)}")
        if comp.lang == "skip":
            detail = comp.note or "no note"
            a(f"  -- skip: not analysed ({detail})")
        elif comp.lang == "vhdl":
            a(f"  -- vhdl: src/vhdl/{comp.name}.vhd is analysed instead of this Verilog")
        if not comp.parsed:
            continue
        a(f"  component {vhdl_name(comp.name)} is")
        if comp.generics:
            a("    generic (")
            for i, generic in enumerate(comp.generics):
                comma = ";" if i + 1 < len(comp.generics) else ""
                a(f"      {vhdl_name(generic.name)} : {generic.vhdl_type} := {generic.default}{comma}")
            a("    );")
        if comp.ports:
            a("    port (")
            for i, port in enumerate(comp.ports):
                comma = ";" if i + 1 < len(comp.ports) else ""
                a(f"      {vhdl_name(port.name)} : {port.direction} {port.vhdl_type}{comma}")
            a("    );")
        else:
            a("    -- no ports")
        a(f"  end component {vhdl_name(comp.name)};")
    a("")
    a("end package vcomponents;")
    a("")
    return "\n".join(lines)


def _parse_indexed(filename: str, path: str, type_map: dict[str, dict[str, dict]]) -> Component:
    raw = open(path, encoding="utf-8", errors="replace").read()
    prepared = preprocess(strip_comments(raw))
    stem = os.path.splitext(filename)[0]
    overrides = type_map.get(stem, {})
    comp = parse_module(prepared, filename, {})
    ov = type_map.get(comp.name, overrides)
    if ov:
        comp = parse_module(prepared, filename, ov)
    return comp


def components_from_tree(type_map: dict[str, dict[str, dict]]) -> tuple[list[Component], list[str]]:
    notes: list[str] = []
    components: list[Component] = []
    seen: dict[str, str] = {}
    if not os.path.isdir(UNISIMS_DIR):
        raise SystemExit(f"missing {UNISIMS_DIR} (check out the submodule)")
    for entry in primitives.load(ROOT):
        filename = None
        path = primitives.verilog_path(ROOT, entry.name)
        if path is None:
            if entry.lang == "skip":
                notes.append(f"skip {entry.name}: no Verilog source")
                continue
            raise ParseError(f"{entry.name}: index entry has no Verilog source")
        filename = os.path.basename(path)
        try:
            comp = _parse_indexed(filename, path, type_map)
        except ParseError as exc:
            # A skipped primitive still has a row so designs can be checked
            # later. If the header is not the Verilog this parser accepts,
            # leave the component out and say why. vlog and vhdl must parse:
            # the package is what those models are instantiated against.
            if entry.lang != "skip":
                raise
            notes.append(f"skip {entry.name}: header did not parse ({exc})")
            components.append(Component(
                entry.name, [], [], filename, lang="skip", note=entry.notes, parsed=False,
            ))
            continue
        comp.lang = entry.lang
        comp.note = entry.notes
        key = comp.name.lower()
        if key in seen:
            raise ParseError(
                f"{filename}: component {comp.name} collides with {seen[key]} "
                "after VHDL case folding"
            )
        seen[key] = filename
        components.append(comp)
    components.sort(key=lambda c: c.name.lower())
    return components, notes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-o", "--output", default=DEFAULT_OUT)
    parser.add_argument("--type-map", default=TYPE_MAP)
    parser.add_argument("--list-exceptions", action="store_true",
                        help="print type_map overrides that applied")
    args = parser.parse_args()
    type_map = load_type_map(args.type_map)
    components, notes = components_from_tree(type_map)
    text = emit(components)
    os.makedirs(os.path.dirname(os.path.abspath(args.output)), exist_ok=True)
    with open(args.output, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)
    ngen = sum(len(c.generics) for c in components)
    nports = sum(len(c.ports) for c in components)
    print(f"wrote {args.output}: {len(components)} components, "
          f"{ngen} generics, {nports} ports", file=sys.stderr)
    if args.list_exceptions:
        for mod, params in sorted(type_map.items()):
            for param, spec in sorted(params.items()):
                print(f"{mod}.{param}: {spec}")
    for note in notes:
        print(note, file=sys.stderr)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ParseError as exc:
        print(f"error: {exc}", file=sys.stderr)
        raise SystemExit(1)
