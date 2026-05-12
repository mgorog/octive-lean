#!/usr/bin/env python3
"""
Convert each .m file under projects/ to a sibling .lean file that wraps the
script body in octave! { ... } using octive-lean's DSL.

Mechanical rewrites (anything else is left for the user / parser):

  *  `%` line comments become `--`
  *  `'single-quoted'` strings become `"double-quoted"`
     (only when the `'` clearly starts a string — `1'` (transpose) is left alone)
  *  the entire body is wrapped in `octave! {  ... }`
  *  an `import OctiveLean` / `open OctiveLean.DSL` header is added

This produces a .lean file per .m. Whether each compiles is then a matter of
running `lake build` and looking at the diagnostics.
"""

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

# ── Mechanical rewrites ─────────────────────────────────────────────

# MATLAB `%` starts a line comment regardless of preceding char (it is NOT a
# binary modulo operator — `mod(a, b)` is). Any `%` runs to end of line.
COMMENT_RE = re.compile(r"%([^\n]*)$", flags=re.MULTILINE)
# MATLAB writes `.5` for `0.5`; Lean's numeric literal parser requires a digit
# before the dot. Insert a leading `0` when `.NN` is at a token start.
LEADING_DECIMAL_RE = re.compile(r"(^|[^A-Za-z0-9_)\]\.])\.([0-9])")


def rewrite_comments(src: str) -> str:
    """`%` (anywhere on a line outside strings) → `--`."""
    # Note: this runs before string-rewriting, so we must avoid touching `%`
    # inside string literals. Process line by line, skipping `%` that follows
    # an odd count of preceding apostrophes (rough string-aware heuristic;
    # good enough for the projects we transpile, falls back to literal `%`).
    out: list[str] = []
    for line in src.splitlines(keepends=True):
        # Quick path: no `%` on this line.
        if "%" not in line:
            out.append(line)
            continue
        # Find the first `%` not inside a single- or double-quoted string.
        i = 0
        in_single = False
        in_double = False
        comment_at = -1
        while i < len(line):
            c = line[i]
            if c == "\\" and i + 1 < len(line):
                i += 2
                continue
            if not in_double and c == "'":
                in_single = not in_single
            elif not in_single and c == '"':
                in_double = not in_double
            elif not in_single and not in_double and c == "%":
                comment_at = i
                break
            i += 1
        if comment_at < 0:
            out.append(line)
        else:
            out.append(line[:comment_at] + "--" + line[comment_at + 1:])
    return "".join(out)


def rewrite_leading_decimals(src: str) -> str:
    """`.5` at a token start → `0.5`."""
    return LEADING_DECIMAL_RE.sub(r"\g<1>0.\2", src)


def join_line_continuations(src: str) -> str:
    """MATLAB uses `...` at end-of-line to continue a statement on the next
    line. Strip `... \\n` (with optional surrounding whitespace) so the result
    is a single line."""
    return re.sub(r"\.\.\.[^\n]*\n\s*", " ", src)


def rewrite_backslash(src: str) -> str:
    """`A \\ b` is MATLAB's linear-solve operator. The DSL has no binary `\\`,
    but `linsolve(A, b)` is a registered builtin. Rewrite the binary form to
    a function call. Only matches when `\\` sits between two token-like
    operands separated by whitespace (avoids escapes and stray backslashes)."""
    return re.sub(
        r"(\b[A-Za-z_][A-Za-z0-9_]*|\)|\])\s*\\\s*(\b[A-Za-z_][A-Za-z0-9_]*|\()",
        r"linsolve(\1, \2",
        src,
    )


def rewrite_operators(src: str) -> str:
    """MATLAB writes `~=` for not-equal and `~x` for logical NOT;
    the DSL uses `!=` and `!`. Collapse stray `;,` and `,;`
    separator pairs that appear when MATLAB scripts squeeze multiple
    statements onto a line."""
    src = src.replace("~=", "!=")
    # Replace unary `~` (logical not) with `!` when it precedes an
    # identifier or paren. Avoid matching when `~=` was already there
    # (handled above) or when `~` is inside a string (we don't bother
    # being precise; the string-rewrite happens later and won't see `~`).
    src = re.sub(r"~(\s*)([A-Za-z_(])", r"!\1\2", src)
    # Strip empty separators like `;,` and `,;`.
    src = re.sub(r";\s*,", ";", src)
    src = re.sub(r",\s*;", ";", src)
    return src


# String tokeniser: walks the source and converts `'...'` to `"..."` only when
# the `'` is in a position where a string can start (after an operator, `,`,
# `;`, `(`, `[`, `=`, or at the start of a token / line). After an identifier
# or `)`/`]`, a `'` is transpose and is left alone.
STRING_OPEN_AFTER = set("=,;([+-*/<>:&|! \t\n{}")


def rewrite_strings(src: str) -> str:
    out: list[str] = []
    i = 0
    n = len(src)
    while i < n:
        c = src[i]
        if c == "'":
            # Decide: string vs transpose. Look back for the last non-space
            # character; if it can precede a string start, treat as string.
            j = i - 1
            while j >= 0 and src[j] in " \t":
                j -= 1
            prev = src[j] if j >= 0 else "\n"
            if prev in STRING_OPEN_AFTER:
                # Find matching `'`. MATLAB doubles `''` to escape; we map to
                # an embedded `"` by collapsing pairs.
                k = i + 1
                buf: list[str] = []
                while k < n:
                    if src[k] == "'" and k + 1 < n and src[k + 1] == "'":
                        buf.append("'")
                        k += 2
                        continue
                    if src[k] == "'":
                        break
                    buf.append(src[k])
                    k += 1
                if k < n and src[k] == "'":
                    # In MATLAB single-quoted strings, `\` is literal — no
                    # escapes. Lean's double-quoted strings interpret `\`, so
                    # double every backslash, then escape any embedded `"`.
                    body = "".join(buf).replace("\\", "\\\\").replace('"', r"\"")
                    out.append(f'"{body}"')
                    i = k + 1
                    continue
            # Transpose or unterminated — leave the apostrophe alone.
        out.append(c)
        i += 1
    return "".join(out)


HEADER = """import OctiveLean
open OctiveLean.DSL

"""


def insert_bracket_commas(src: str) -> str:
    """MATLAB allows `[a b c]` for `[a, b, c]`. Walk the source, find every
    `[...]` not nested in a string, and insert commas between adjacent items
    that are separated only by whitespace. Items end at one of:
      * a closing `)` `]` `}` of a balanced bracket pair, or
      * an identifier, number, or string literal token end.
    The DSL still parses `,` and `;` explicitly, so we only insert commas
    where the current separator is plain whitespace.
    """
    out: list[str] = []
    i = 0
    n = len(src)
    # Index of `[`s currently open and the depth of `(`/`{` inside them.
    bracket_stack: list[int] = []  # depth of ( inside each open [
    while i < n:
        c = src[i]
        # Skip strings verbatim.
        if c == '"' or c == "'":
            quote = c
            out.append(c)
            i += 1
            while i < n and src[i] != quote:
                if src[i] == "\\" and i + 1 < n:
                    out.append(src[i])
                    out.append(src[i + 1])
                    i += 2
                    continue
                out.append(src[i])
                i += 1
            if i < n:
                out.append(src[i])
                i += 1
            continue
        # Skip line comments verbatim.
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            while i < n and src[i] != "\n":
                out.append(src[i])
                i += 1
            continue
        # Bracket tracking.
        if c == "[":
            bracket_stack.append(0)
            out.append(c)
            i += 1
            continue
        if c == "]":
            if bracket_stack:
                bracket_stack.pop()
            out.append(c)
            i += 1
            continue
        if c == "(":
            if bracket_stack:
                bracket_stack[-1] += 1
            out.append(c)
            i += 1
            continue
        if c == ")":
            if bracket_stack and bracket_stack[-1] > 0:
                bracket_stack[-1] -= 1
            out.append(c)
            i += 1
            continue
        # Whitespace handling inside a top-level (not nested) bracket pair.
        if (
            c == " "
            and bracket_stack
            and bracket_stack[-1] == 0
        ):
            # Look back for the last non-space char and forward for next.
            prev = out[-1] if out else "\n"
            j = i + 1
            while j < n and src[j] == " ":
                j += 1
            nxt = src[j] if j < n else "\n"
            # Insert `,` between item-ending and item-starting tokens.
            ITEM_END = set(")]}\"")
            NUMID = "0123456789_"
            if (prev.isalnum() or prev in ITEM_END or prev in NUMID) and (
                nxt.isalnum() or nxt in "(\"[-+." or nxt == "_"
            ):
                # Avoid double-insertion if there's already a `,` or `;` nearby.
                if prev != "," and prev != ";" and nxt != "," and nxt != ";":
                    out.append(",")
            # Always consume the run of spaces (collapsed) — leave a single
            # space for readability, except after the comma we just emitted.
            out.append(" ")
            i = j
            continue
        out.append(c)
        i += 1
    return "".join(out)


def to_lean(src: str, name: str) -> str:
    body = insert_bracket_commas(
        rewrite_operators(
            rewrite_leading_decimals(
                rewrite_strings(
                    rewrite_backslash(
                        join_line_continuations(
                            rewrite_comments(src.rstrip())
                        )
                    )
                )
            )
        )
    )
    return f"""{HEADER}/-! Auto-generated from `{name}` — mechanical translation only.
    Hand-edit if any constructs (matrix slicing, struct access, advanced
    cell/sym ops) don't survive the rewrite. -/

octave! {{
{body}
}}
"""


def convert(path: Path) -> Path:
    src = path.read_text(encoding="utf-8", errors="replace")
    lean = to_lean(src, path.name)
    out = path.with_suffix(".lean")
    out.write_text(lean, encoding="utf-8")
    return out


def main() -> int:
    n = 0
    for dirpath, _, filenames in os.walk(ROOT):
        for fn in filenames:
            if fn.endswith(".m"):
                p = Path(dirpath) / fn
                # Don't transpile .lean.m or backups.
                convert(p)
                n += 1
    print(f"transpiled {n} .m files")
    return 0


if __name__ == "__main__":
    sys.exit(main())
