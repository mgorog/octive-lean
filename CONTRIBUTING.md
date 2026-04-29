# Contributing to octive-lean

## Module map

| Module | Purpose |
| --- | --- |
| `OctiveLean.AST` | Concrete + abstract syntax (statements, expressions, lvalues) |
| `OctiveLean.Lexer` | Tokenizer — mirrors `octave-upstream/libinterp/parse-tree/lex.ll` |
| `OctiveLean.Parser` | Parser — mirrors `octave-upstream/libinterp/parse-tree/oct-parse.yy` |
| `OctiveLean.Value` | Runtime values: scalar, matrix, cell, struct, function handle |
| `OctiveLean.Env` | Variable scopes, frames, builtin registry |
| `OctiveLean.Eval` | Big-step evaluator over the AST |
| `OctiveLean.Builtins` | Built-in functions (`sum`, `sin`, `printf`, …) |
| `OctiveLean.REPL` | Interactive line reader |
| `OctiveLean.PlotData`/`PlotSVG`/`PlotWidget` | Plotting backend |
| `OctiveLean.BigStep`/`PureEval`/`ValueEquiv` | Semantic specs / proofs |
| `OctiveLean.Corpus` | Driver behind `corpus-check` |

The monad stack is `ExceptT OctaveError (StateT Env IO)` — putting `StateT` outermost preserves variable state through `break`/`continue` exceptions.

## Adding a builtin

1. Add the implementation in `OctiveLean/Builtins.lean`.
2. Register it in `Env.builtinRegistry` (`OctiveLean/Env.lean`).
3. Add a corpus test (next section) exercising it.
4. `just test` to verify.

## Adding a corpus test

Drop a pair into `corpus/`:

```
corpus/NN_my_feature.m         # Octave source
corpus/NN_my_feature.expected  # expected stdout
```

Generate the expected file with:

```sh
just update-corpus
```

Inspect the diff — if the output looks right, commit both files.

## Reference: GNU Octave upstream

`octave-upstream/` is a shallow clone (gitignored) used as a reference. Key paths:

- `octave-upstream/libinterp/parse-tree/` — flex/bison sources for the original parser
- `octave-upstream/libinterp/corefcn/` — built-in function implementations
- `octave-upstream/libinterp/octave-value/` — value system

When adding a feature, check upstream's behavior first so the semantics match.
