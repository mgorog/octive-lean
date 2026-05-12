# octive-lean

A Lean 4 reimplementation of [GNU Octave](https://www.gnu.org/software/octave/) — the MATLAB-compatible numerical language — built so that its **internals are formally provable**. The interpreter runs Octave scripts; the same syntax also exists as a typed Lean DSL; and the language's semantics live as inductive predicates you can write proofs against.

## Install Lean

This project uses [`elan`](https://github.com/leanprover/elan), the Lean toolchain manager. One line:

```sh
curl -sSf https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh | sh
```

`elan` reads [`lean-toolchain`](lean-toolchain) and installs the right compiler the first time you run `lake`. Nothing else needed.

Optional: [`just`](https://github.com/casey/just) for the shortcut commands in [`justfile`](justfile).

## Use the project

```sh
lake build                      # compile the library + executable
lake exe octive-lean             # interactive Octave REPL
lake exe octive-lean tutorial.m  # run an Octave script
lake exe corpus-check            # run the corpus tests
```

The executable is a full Octave interpreter for the supported subset: scalars, matrices, complex numbers, strings, structs, cell arrays, anonymous functions, closures, recursion, control flow, `printf`/`disp`, and a symbolic toolbox via a SymPy subprocess bridge.

## Prove things about the language

The proof surface lives under **[`OctiveLean/Core/`](OctiveLean/Core/)**. This is a clean kernel — call it TOC (Tiny Octave Core) — capturing the invariant skeleton of the language separately from the messy outer interpreter. Open any of these in your editor (VS Code + Lean extension, or any LSP-aware editor) and the proofs check live:

| File | What it proves |
| --- | --- |
| [`Core/Syntax.lean`](OctiveLean/Core/Syntax.lean) | The term grammar: literals, variables, lambdas, application, assignment, conditionals, `while`, binary ops. |
| [`Core/Semantics.lean`](OctiveLean/Core/Semantics.lean) | `BigStep : Env → Term → Value → Env → Prop` — the meaning of every program as an inductive relation. |
| [`Core/Determinism.lean`](OctiveLean/Core/Determinism.lean) | **`BigStep.deterministic`** — evaluating the same program twice from the same env yields the same value and the same env. |
| [`Core/Types.lean`](OctiveLean/Core/Types.lean) | A simple type system: `HasType : TyEnv → Term → Ty → Prop`. |
| [`Core/TypeSoundness.lean`](OctiveLean/Core/TypeSoundness.lean) | `HasTypeV`, `HasTypeEnv` — runtime data well-typedness. Asymmetric vs a heap-only language because `assign` mutates env. |
| [`Core/Preservation.lean`](OctiveLean/Core/Preservation.lean) | **`preservation`** — if `e : T` and `env` is well-typed and `e` big-step evaluates to `v` in `env'`, then `v : T` and `env'` is still well-typed. |
| [`Core/Eval.lean`](OctiveLean/Core/Eval.lean) | An executable evaluator on the same syntax — useful for `#eval` and as a comparison point with the relational `BigStep`. |

Every theorem in `Core/` is closed — **no `sorry`**. Read [`Determinism.lean`](OctiveLean/Core/Determinism.lean) first; its case-by-case structure (terminal / structural-functional / contradiction-collapse) is the template for proofs in the others.

To add your own theorem, import the relevant module:

```lean
import OctiveLean.Core.Semantics
import OctiveLean.Core.Determinism

open OctiveLean.Core

example {env env₁ env₂ : Env} {e : Term} {v₁ v₂ : Value}
    (D₁ : BigStep env e v₁ env₁)
    (D₂ : BigStep env e v₂ env₂) :
    v₁ = v₂ := (BigStep.deterministic D₁ D₂).1
```

## Showcase files

If you want to see what the project can do without writing your own scripts:

| File | What it shows |
| --- | --- |
| [`corpus/`](corpus/) | 11 paired `.m` / `.expected` test cases — minimal examples of every interpreter feature. Run `lake exe corpus-check`. |
| [`tutorial.m`](tutorial.m) | A 540-line Octave script: Horner, fixed-point iteration, bisection, Newton, secant, finite differences, trapezoidal/Simpson quadrature, Richardson extrapolation. Run it. |
| [`NumericalTutorial.lean`](NumericalTutorial.lean) | The same algorithms, formalized in Lean: each algorithm is a computable `def`, then structural theorems are proven, then convergence/accuracy theorems are stated (the convergence proofs require Mathlib's IVT / Taylor's theorem and are marked `sorry` with explicit proof sketches — pedagogical placeholders, not engine code). |
| [`RosettaStone.lean`](RosettaStone.lean) | Octave-as-Lean-syntax: the `octave! { ... }` macro compiles Octave source to typed `OctiveLean.Stmt` values at elaboration. LSP gives real highlighting, hover, and completion inside the block. |
| [`PlotDemo.lean`](PlotDemo.lean) | Plotting via [ProofWidgets](https://github.com/leanprover-community/ProofWidgets4) + SVG. Hover an `octave! { ... }` block in the infoview; the chart renders. |
| [`demos/Sim_Lorenz.m`](demos/Sim_Lorenz.m) | The Lorenz attractor as an `.m` script. Also `Sim_VanDerPol.m`, `Sim_Gravity.m`, `Lab7Interp.m`. |
| [`demos/SymToolboxDemo.m`](demos/SymToolboxDemo.m) | Symbolic toolbox demo: `sym('x')`, `diff`, `int`, `solve`, `simplify`. Requires SymPy on `PATH` — the interpreter spawns a persistent Python subprocess and routes operations on `.sym` values through it. |

## Layout

| Path | Role |
| --- | --- |
| `OctiveLean/Core/` | Proof kernel — syntax, semantics, types, soundness theorems. No `sorry`. |
| `OctiveLean/` (outer) | Interpreter surface: `Lexer`, `Parser`, `Eval`, `Builtins`, `REPL`, `SymPyBridge`, `PlotSVG`, the Lean-syntax `DSL`, etc. |
| `Main.lean` | Entry point — REPL or file runner. |
| `CorpusCheck.lean` | Test driver for `corpus/`. |
| `corpus/` | `.m` test cases paired with `.expected` outputs. |
| `demos/` | Standalone `.m` demo scripts. |
| `tutorial.m` + `NumericalTutorial.lean` | Side-by-side numerical-analysis tutorial — Octave script and Lean formalization of the same algorithms. |
| `widget/` | JavaScript widgets used by `PlotWidget` and `PlotSVG`. |
| `octave-upstream/` | Reference clone of GNU Octave (gitignored). |

## Project tasks

A [`justfile`](justfile) wraps the common operations: `just build`, `just repl`, `just run <script.m>`, `just test`, `just update-corpus`, `just clean`, `just fresh`.

## Companion projects

octive-lean's `Core/` shape is shared with two sibling projects: [`golang-lean`](https://github.com/) (Go subset; big-step over `Heap × Env`) and `tsm-lean` (Tiny Stack Machine; small-step). They are gathered together with a cross-language abstraction layer (`common-lean`, which defines `BigStepLang` / `SmallStepLang` typeclasses and packages each kernel as an instance) in the `crosslang` monorepo. The point: any theorem proven in `common-lean` against the abstract typeclass fires automatically on Octave, Go, and the stack machine. octive-lean stands on its own; the cross-language scaffolding is optional.

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md).
