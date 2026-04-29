# octive-lean

A Lean 4 reimplementation of [GNU Octave](https://www.gnu.org/software/octave/) — the MATLAB-compatible numerical language — aiming to be more versatile than upstream.

## Build

```sh
lake build
```

Requires the Lean toolchain pinned in [`lean-toolchain`](lean-toolchain). [`elan`](https://github.com/leanprover/elan) will pick it up automatically.

## Run

```sh
# REPL
lake exe octive-lean

# Run an .m script
lake exe octive-lean path/to/script.m

# Verify the corpus against expected outputs
lake build corpus-check
lake exe corpus-check
```

## Layout

| Path | What's there |
| --- | --- |
| `OctiveLean/` | Library: `Lexer`, `Parser`, `AST`, `Eval`, `Builtins`, `REPL`, `BigStep`, `PlotSVG`, … |
| `Main.lean` | Entry point — REPL or file runner |
| `CorpusCheck.lean` | Test driver for `corpus/` |
| `corpus/` | `.m` test cases paired with `.expected` outputs |
| `NumericalTutorial.lean`, `RosettaStone.lean` | Lean-side tutorials and Octave⇄Lean translations |
| `PlotDemo.lean`, `widget/` | Plotting via ProofWidgets + SVG |
| `octave-upstream/` | Shallow clone of GNU Octave (gitignored, used as reference) |

## Status

Working interpreter: matrices, arithmetic, control flow, functions (incl. recursion, closures, anonymous `@(x)`), cell arrays, structs, `printf`-family, REPL, file execution. See `corpus/` for what's covered.

## Tests

```sh
lake build && lake exe corpus-check
```

Pass `--update` to regenerate `.expected` files after intentional behavior changes.
