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
        # Quick path: no comment marker on this line.
        if "%" not in line and "#" not in line:
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
                # MATLAB rule: `'` is transpose if tight-bound to an
                # identifier-end / `)` / `]`. Otherwise it opens a string.
                prev = line[i - 1] if i > 0 else "\n"
                if prev.isalnum() or prev in "_)]" if not in_single else False:
                    pass  # transpose; don't toggle string state
                else:
                    in_single = not in_single
            elif not in_single and c == '"':
                in_double = not in_double
            elif not in_single and not in_double and (c == "%" or c == "#"):
                # Octave allows both `%` and `#` as line-comment markers.
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
    line. Strip `... \\n` (and trailing whitespace) so the result is a single
    line. Crucially, only match when `...` is followed by whitespace until
    end-of-line — otherwise a literal `...` inside a string (e.g. `'tutorial
    ...'`) would consume the rest of the statement."""
    return re.sub(r"\.\.\.[ \t]*\n[ \t]*", " ", src)


def rewrite_transpose(src: str) -> str:
    """MATLAB postfix `'` is transpose (or `.'` for non-conjugate). Rewrite
    each transpose site into a call `htranspose(...)`. The operand is the
    largest postfix-chain ending at `'`: an identifier, a bracket-pair,
    a paren-pair, or a chain like `M.f(i)`.

    We do this with a single left-to-right pass, building an output buffer
    and using output-side bracket matching to find the operand extent."""
    out: list[str] = []
    stack: list[tuple[int, str]] = []  # (out_pos, open-char) for currently open brackets
    in_string = False
    str_char: str | None = None
    i = 0
    n = len(src)

    def chain_start(end: int) -> int:
        """Walking backward from `end` in `out`, absorb the maximal postfix chain
        that can be the operand of `'`. The chain consists of identifiers, `.`
        for field access, and balanced bracket pairs."""
        start = end
        while start > 0:
            ch = out[start - 1]
            if ch.isalnum() or ch == "_" or ch == ".":
                start -= 1
                continue
            if ch == ")" or ch == "]":
                close, op = (")", "(") if ch == ")" else ("]", "[")
                depth = 1
                start -= 1
                while start > 0 and depth > 0:
                    start -= 1
                    if out[start] == close:
                        depth += 1
                    elif out[start] == op:
                        depth -= 1
                continue
            break
        return start

    while i < n:
        c = src[i]
        if in_string:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if c == str_char:
                in_string = False
                str_char = None
            i += 1
            continue
        if c == '"':
            in_string = True
            str_char = c
            out.append(c)
            i += 1
            continue
        # Skip line comments
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            while i < n and src[i] != "\n":
                out.append(src[i])
                i += 1
            continue
        if c in "([":
            stack.append((len(out), c))
            out.append(c)
            i += 1
            continue
        if c in ")]":
            if stack and ((c == ")" and stack[-1][1] == "(") or (c == "]" and stack[-1][1] == "[")):
                stack.pop()
            out.append(c)
            i += 1
            # Postfix `'` after a closing bracket — wrap the chain.
            if i < n and src[i] == "'" and (i + 1 >= n or src[i + 1] != "'"):
                start = chain_start(len(out))
                operand = "".join(out[start:])
                out = out[:start] + list(f"htranspose({operand})")
                i += 1
            continue
        # Postfix `'` after an identifier character.
        if c == "'" and out and (out[-1].isalnum() or out[-1] == "_") and (i + 1 >= n or src[i + 1] != "'"):
            start = chain_start(len(out))
            operand = "".join(out[start:])
            out = out[:start] + list(f"htranspose({operand})")
            i += 1
            continue
        # `.'` (non-conjugate transpose) — same operand search; rewrite to
        # `transpose(...)`. Distinguish from struct access `.field` by
        # requiring whitespace or end-of-token after `.`.
        if c == "." and i + 1 < n and src[i + 1] == "'" and out and (out[-1].isalnum() or out[-1] in "_)]"):
            start = chain_start(len(out))
            operand = "".join(out[start:])
            out = out[:start] + list(f"transpose({operand})")
            i += 2
            continue
        out.append(c)
        i += 1
    return "".join(out)


def rewrite_backslash(src: str) -> str:
    """`A \\ b` is MATLAB's linear-solve operator. The DSL has no binary `\\`,
    but `linsolve(A, b)` is a registered builtin. Rewrite the binary form to
    a function call.  The RHS must be either a plain identifier or a single
    parenthesised group so the rewrite stays balanced — complex RHS like
    `A \\ b + c` is left for the user."""
    src = re.sub(
        r"(\b[A-Za-z_][A-Za-z0-9_]*|\)|\])\s*\\\s*([A-Za-z_][A-Za-z0-9_]*)",
        r"linsolve(\1, \2)",
        src,
    )
    src = re.sub(
        r"(\b[A-Za-z_][A-Za-z0-9_]*|\)|\])\s*\\\s*(\([^()]*\))",
        r"linsolve(\1, \2)",
        src,
    )
    return src


LEAN_KEYWORDS = {
    "show", "from", "match", "with", "let", "def", "theorem", "instance",
    "class", "structure", "open", "namespace", "do", "fun", "axiom",
    "variable", "notation", "infix", "prefix", "attribute", "section",
    "deriving", "abbrev", "private", "protected", "partial", "mutual",
    "where", "by", "have",
}


def rewrite_lean_keyword_idents(src: str) -> str:
    """MATLAB scripts occasionally use words that Lean reserves (`show`,
    `from`, `match`, …) as variable or parameter names. Suffix them with
    `_` everywhere they appear as identifiers (outside strings/comments)."""
    out: list[str] = []
    i = 0
    n = len(src)
    in_string = False
    str_char: str | None = None
    while i < n:
        c = src[i]
        if in_string:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if c == str_char:
                in_string = False
                str_char = None
            i += 1
            continue
        if c == '"' or c == "'":
            in_string = True
            str_char = c
            out.append(c)
            i += 1
            continue
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            while i < n and src[i] != "\n":
                out.append(src[i])
                i += 1
            continue
        if c.isalpha() or c == "_":
            j = i
            while j < n and (src[j].isalnum() or src[j] == "_"):
                j += 1
            word = src[i:j]
            if word in LEAN_KEYWORDS:
                out.append(word + "_")
            else:
                out.append(word)
            i = j
            continue
        out.append(c)
        i += 1
    return "".join(out)


def rewrite_cell_index(src: str) -> str:
    """`M{i}` is MATLAB's cell-content access. The DSL can't add postfix
    `{…}` (the macro-pattern parser rejects `{` after `$expr`), so detect
    `<name>{args}` (i.e. `{` tightly after an identifier-chain) and rewrite
    to a `cellget(name, args)` call. Bare `{…}` standalone stays as a cell
    literal."""
    out: list[str] = []
    i = 0
    n = len(src)
    in_string = False
    str_char: str | None = None
    while i < n:
        c = src[i]
        if in_string:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if c == str_char:
                in_string = False
                str_char = None
            i += 1
            continue
        if c == '"' or c == "'":
            in_string = True
            str_char = c
            out.append(c)
            i += 1
            continue
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            while i < n and src[i] != "\n":
                out.append(src[i])
                i += 1
            continue
        if c == "{":
            # Cell-content access only when `{` is tight to an identifier-end
            # or `)` / `]` (continuation of a postfix chain).
            tight = (out and (out[-1].isalnum() or out[-1] in "_)]"))
            if not tight:
                out.append(c)
                i += 1
                continue
            # Walk back through `out` to find the chain start.
            start = len(out)
            while start > 0:
                ch = out[start - 1]
                if ch.isalnum() or ch in "_.":
                    start -= 1
                elif ch == ")" or ch == "]":
                    depth = 1
                    start -= 1
                    while start > 0 and depth > 0:
                        start -= 1
                        if out[start] in ")]":
                            depth += 1
                        elif out[start] in "([":
                            depth -= 1
                else:
                    break
            chain = "".join(out[start:])
            # Consume args until matching `}`.
            depth = 1
            j = i + 1
            args_buf: list[str] = []
            while j < n and depth > 0:
                cc = src[j]
                if cc == "{":
                    depth += 1
                    args_buf.append(cc)
                elif cc == "}":
                    depth -= 1
                    if depth == 0:
                        break
                    args_buf.append(cc)
                else:
                    args_buf.append(cc)
                j += 1
            args_str = "".join(args_buf)
            replacement = f"cellget({chain}, {args_str})" if args_str.strip() else f"cellget({chain})"
            out = out[:start] + list(replacement)
            i = j + 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def rewrite_end_in_index(src: str) -> str:
    """`A(…:end)` / `A(end, …)` / etc.  `end` inside an indexing context is
    MATLAB's "last index of this axis". Since the DSL can't accept `end` as
    an expression (it collides with the block terminator), rewrite each
    `end` token that sits inside a `(…)` to `numel(<array>)`. We bracket-
    match backward from the `(` to the array name and substitute."""
    out: list[str] = []
    i = 0
    n = len(src)
    in_string = False
    str_char: str | None = None
    # Stack: for each open `(`, store the array name (or empty if it was
    # `(expr)`, not indexing).
    paren_stack: list[str] = []
    while i < n:
        c = src[i]
        if in_string:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if c == str_char:
                in_string = False
                str_char = None
            i += 1
            continue
        if c == '"' or c == "'":
            in_string = True
            str_char = c
            out.append(c)
            i += 1
            continue
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            while i < n and src[i] != "\n":
                out.append(src[i])
                i += 1
            continue
        if c == "(":
            # Look back in `out` for an identifier chain (so this is an
            # indexing call `name(…)`, not a `(expr)` group).
            k = len(out)
            while k > 0 and (out[k - 1].isalnum() or out[k - 1] == "_"):
                k -= 1
            # Walk past any `.field` or `]` continuations behind the name.
            name = "".join(out[k:len(out)])
            paren_stack.append(name)
            out.append(c)
            i += 1
            continue
        if c == ")":
            if paren_stack:
                paren_stack.pop()
            out.append(c)
            i += 1
            continue
        # Detect bare `end` token only when inside a `(…)` opened on an
        # identifier (i.e., genuine indexing context).
        if (c == "e" and i + 2 < n and src[i + 1] == "n" and src[i + 2] == "d"
                and (i + 3 >= n or not (src[i + 3].isalnum() or src[i + 3] == "_"))
                and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == "_"))
                and paren_stack and paren_stack[-1]):
            name = paren_stack[-1]
            out.append(f"numel({name})")
            i += 3
            continue
        out.append(c)
        i += 1
    return "".join(out)


def rewrite_command_syntax(src: str) -> str:
    """A handful of MATLAB command-syntax calls show up frequently: `hold on`,
    `hold off`, `figure 1`, `format short`. Rewrite the well-known ones into
    explicit function calls so they parse through the DSL.  Anything not
    listed here is left alone."""
    src = re.sub(r"\bhold\s+on\b",       "hold_on()",        src)
    src = re.sub(r"\bhold\s+off\b",      "hold_off()",       src)
    src = re.sub(r"^[ \t]*hold[ \t]*$",  "hold_on()",        src, flags=re.MULTILINE)
    return src


def balance_function_ends(src: str) -> str:
    """MATLAB lets the final `function` in a file omit its closing `end`;
    the DSL doesn't. Count block-opening keywords (`function`, `if`, `for`,
    `while`, `switch`, `try`) vs block-closing keywords (`end`, `endif`,
    `endfor`, `endwhile`, `endswitch`, `end_try_catch`, `endfunction`).
    Append `end` keywords if the openers exceed the closers."""

    # Tokenise crudely: skip strings and comments, then count keywords.
    openers = 0
    closers = 0
    i = 0
    n = len(src)
    in_string = False
    str_char: str | None = None
    while i < n:
        c = src[i]
        if in_string:
            if c == "\\" and i + 1 < n:
                i += 2
                continue
            if c == str_char:
                in_string = False
                str_char = None
            i += 1
            continue
        if c == '"' or c == "'":
            in_string = True
            str_char = c
            i += 1
            continue
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            while i < n and src[i] != "\n":
                i += 1
            continue
        if c.isalpha() or c == "_":
            j = i
            while j < n and (src[j].isalnum() or src[j] == "_"):
                j += 1
            word = src[i:j]
            # Need word boundary before (avoid matching `endif` inside `xendif`).
            if i == 0 or not (src[i - 1].isalnum() or src[i - 1] == "_"):
                if word in {"function", "if", "for", "while", "switch", "try"}:
                    openers += 1
                elif word in {"end", "endif", "endfor", "endwhile",
                              "endswitch", "end_try_catch", "endfunction"}:
                    closers += 1
            i = j
            continue
        i += 1
    missing = openers - closers
    if missing > 0:
        src = src.rstrip() + ("\n" + "end\n" * missing)
    return src


_INLINE_BLOCK_KW = re.compile(r"\b(if|elseif|for|while)\b")
_INLINE_END_KW   = re.compile(r"\b(end|endif|endfor|endwhile)\b")


def split_toplevel_commas(src: str) -> str:
    """In MATLAB, a `,` at top-level paren depth is a statement separator
    (the same role as `;` but with non-silent display). The DSL treats
    `,` only as an element/argument separator, so convert top-level commas
    on each line to newlines. Strings, comments, and bracketed expressions
    are left alone."""
    out: list[str] = []
    i = 0
    n = len(src)
    in_string = False
    str_char: str | None = None
    depth = 0
    while i < n:
        c = src[i]
        if in_string:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if c == str_char:
                in_string = False
                str_char = None
            i += 1
            continue
        if c == '"' or c == "'":
            in_string = True
            str_char = c
            out.append(c)
            i += 1
            continue
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            while i < n and src[i] != "\n":
                out.append(src[i])
                i += 1
            continue
        if c in "([{":
            depth += 1
            out.append(c)
            i += 1
            continue
        if c in ")]}":
            depth = max(0, depth - 1)
            out.append(c)
            i += 1
            continue
        if c == "," and depth == 0:
            out.append("\n")
            i += 1
            continue
        out.append(c)
        i += 1
    return "".join(out)


def _split_inline_blocks(src: str) -> str:
    """Replace `,`s and `;`s that act as statement separators inside a
    single-line `if … , … , end` (or for/while). A paren-depth scan keeps
    function-call commas safe. Comments and strings are skipped so a stray
    `'` inside `-- transpose example A'` doesn't open a phantom string."""
    out: list[str] = []
    i = 0
    n = len(src)
    in_string = False
    str_char: str | None = None
    while i < n:
        c = src[i]
        if in_string:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(src[i + 1])
                i += 2
                continue
            if c == str_char:
                in_string = False
                str_char = None
            i += 1
            continue
        # Skip line comments so quotes inside them don't toggle string state.
        if c == "-" and i + 1 < n and src[i + 1] == "-":
            while i < n and src[i] != "\n":
                out.append(src[i])
                i += 1
            continue
        if c == '"' or c == "'":
            in_string = True
            str_char = c
            out.append(c)
            i += 1
            continue
        # Detect inline block: an `if`/`for`/`while` keyword followed (on the
        # same line, after the header) by a `,` then a body then `,end`.
        m = _INLINE_BLOCK_KW.match(src, i)
        # Must be at a token start
        if m and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == "_")):
            # Find the end-of-line position.
            eol = src.find("\n", i)
            if eol < 0:
                eol = n
            line = src[i:eol]
            # Does this line end with `,end` (or `,endif`/etc.) after a paren-
            # balanced scan? If so, rewrite `,`s at depth 0 to `\n`.
            if _INLINE_END_KW.search(line):
                depth = 0
                rebuilt = []
                k = 0
                while k < len(line):
                    cc = line[k]
                    if cc == "(" or cc == "[" or cc == "{":
                        depth += 1
                        rebuilt.append(cc)
                    elif cc == ")" or cc == "]" or cc == "}":
                        depth = max(0, depth - 1)
                        rebuilt.append(cc)
                    elif (cc == "," or cc == ";") and depth == 0:
                        # Both `,` and `;` are statement separators inside an
                        # inline block; turn them into newlines so each piece
                        # parses as its own octStmt.
                        rebuilt.append("\n")
                    else:
                        rebuilt.append(cc)
                    k += 1
                out.append("".join(rebuilt))
                i = eol
                continue
        out.append(c)
        i += 1
    return "".join(out)


def rewrite_operators(src: str) -> str:
    """MATLAB writes `~=` for not-equal and `~x` for logical NOT;
    the DSL uses `!=` and `!`. Collapse stray `;,` and `,;`
    separator pairs that appear when MATLAB scripts squeeze multiple
    statements onto a line."""
    src = src.replace("~=", "!=")
    # Pad two-character relational operators so the DSL lexer doesn't
    # mis-tokenise `x!=1` as `x ! = 1`.
    src = re.sub(r"([A-Za-z0-9_)\]])(!=|<=|>=|==)", r"\1 \2", src)
    src = re.sub(r"(!=|<=|>=|==)([A-Za-z0-9_(\[])", r"\1 \2", src)
    # MATLAB allows a stray `;` at the end of an `if`/`for`/`while`/
    # `elseif`/`else` header line — purely visual. Strip it before parse.
    src = re.sub(r"(^[ \t]*(?:if|elseif|while|for)\b[^\n;]*);\s*$",
                 r"\1", src, flags=re.MULTILINE)
    src = re.sub(r"(^[ \t]*else)\s*;\s*$", r"\1", src, flags=re.MULTILINE)
    # Inline `if cond, body, end` (and similar one-liner) — split at any `,`
    # that appears at paren-depth zero between an `if`/`for`/`while` keyword
    # and a closing `end`. This is paren-aware, unlike a flat regex.
    src = _split_inline_blocks(src)
    # Anywhere else, a top-level `,` is a statement separator in MATLAB.
    # Convert to a newline so each piece parses as its own octStmt.
    src = split_toplevel_commas(src)
    # Replace unary `~` (logical not) with `!` when it precedes an
    # identifier or paren. Avoid matching when `~=` was already there
    # (handled above) or when `~` is inside a string (we don't bother
    # being precise; the string-rewrite happens later and won't see `~`).
    src = re.sub(r"~(\s*)([A-Za-z_(])", r"!\1\2", src)
    # Strip empty separators like `;,`, `,;`, and double `;;`.
    src = re.sub(r";\s*,", ";", src)
    src = re.sub(r",\s*;", ";", src)
    src = re.sub(r";\s*;+", ";", src)
    # Add a `;` to bare `global`/`clear` declarations so the ident+ rule
    # doesn't keep absorbing identifiers from the next line. Match end-of-line
    # OR a trailing `--…` comment.
    src = re.sub(r"^(\s*global\s+[A-Za-z_]\w*(?:\s+[A-Za-z_]\w*)*)\s*(--[^\n]*)?$",
                 lambda m: f"{m.group(1)};{('  ' + m.group(2)) if m.group(2) else ''}",
                 src, flags=re.MULTILINE)
    src = re.sub(r"^(\s*clear\s+[A-Za-z_]\w*(?:\s+[A-Za-z_]\w*)*)\s*(--[^\n]*)?$",
                 lambda m: f"{m.group(1)};{('  ' + m.group(2)) if m.group(2) else ''}",
                 src, flags=re.MULTILINE)
    # Trailing `,` immediately before a closing `)` or `]` or `}` — MATLAB
    # permits it, the DSL doesn't.
    src = re.sub(r",(\s*[\)\]\}])", r"\1", src)
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
            # MATLAB rule: `'` is transpose iff it's tight-bound (no
            # whitespace) to an identifier-end, `)`, or `]`. Any other
            # preceding character — including whitespace — opens a string.
            prev = src[i - 1] if i > 0 else "\n"
            is_transpose = prev.isalnum() or prev == "_" or prev == ")" or prev == "]"
            if not is_transpose:
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
    """MATLAB allows `[a b c]` for `[a, b, c]` and `{a b c}` for `{a, b, c}`.
    Walk the source, find every `[...]` or `{...}` not nested in a string,
    and insert commas between adjacent items separated only by whitespace.
    Items end at a closing `)` `]` `}` of a balanced pair, or at an
    identifier / number / string literal token end. The DSL still parses
    `,` and `;` explicitly, so we only insert commas where the current
    separator is plain whitespace.
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
        # Bracket tracking (both `[…]` and `{…}` are treated as item-bearing
        # bracket pairs that take comma insertion).
        if c == "[" or c == "{":
            bracket_stack.append(0)
            out.append(c)
            i += 1
            continue
        if c == "]" or c == "}":
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
            c in " \t\n"
            and bracket_stack
            and bracket_stack[-1] == 0
        ):
            # Look back for the last non-whitespace char and forward for next.
            prev = out[-1] if out else "\n"
            j = i + 1
            while j < n and src[j] in " \t\n":
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
    # Lean's parser rejects tab characters; expand to 4 spaces.
    src = src.replace("\t", "    ")
    # Order matters:
    #   `rewrite_strings` runs before `rewrite_backslash` so the MATLAB
    #   linear-solve regex does not match `\eta` etc. inside string literals
    #   (after string-conversion, those backslashes are doubled and escaped).
    body = balance_function_ends(
        insert_bracket_commas(
            rewrite_operators(
                rewrite_leading_decimals(
                    rewrite_transpose(
                        rewrite_backslash(
                            rewrite_lean_keyword_idents(
                                rewrite_cell_index(
                                rewrite_end_in_index(
                                rewrite_command_syntax(
                                    rewrite_strings(
                                        join_line_continuations(
                                            rewrite_comments(src.rstrip())
                                        )
                                    )))
                                )
                            )
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
