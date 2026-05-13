# Proving things about Octave programs in Lean

octive-lean lets you write a program in Octave-flavored syntax and
state, then prove, theorems about how it behaves — all in the same
Lean file, all mechanically checked.

## The loop

```lean
import OctiveLean.Foundation.Reasoning
open OctiveLean.Foundation OctiveLean.Foundation.Logic OctiveLean.Foundation.Reasoning

-- 1. Write the program.
octthm! computeY {
  x = 5;
  y = x + 7;
} shows computeY ⇓bind "y" ↦ Value.num 12.0
```

That single block does three things:

1. Defines `computeY : Surface.Program` from the Octave source.
2. States the theorem `property.computeY : computeY ⇓bind "y" ↦ Value.num 12.0`.
3. Proves it with `native_decide` — the program is run, the
   postcondition is checked, no `sorry`.

If the postcondition is wrong, the file fails to compile. Octave +
Lean reach a single source of truth.

## The four pieces of vocabulary

### `p ⇓ v` — "program `p` evaluates to value `v`"

```lean
octthm! arith { x = 3 * 4; } shows arith ⇓ Value.num 12.0
```

The value of a program is the value of its last statement.

### `p ⇓bind "x" ↦ v` — "after running, identifier `x` holds `v`"

```lean
octthm! multiBind {
  a = 3;
  b = 4;
  c = a * a + b * b;
} shows multiBind ⇓bind "c" ↦ Value.num 25.0
```

Use this to talk about side effects without caring about the
program's return value.

### `octs` tactic — symbolic execution

```lean
octProg! mine { … }

theorem mine_ok : mine ⇓ Value.num 7.0 := by octs
```

`octs` is currently a thin wrapper over `native_decide` (the
compiler runs your program, checks the result). The name is stable
so when symbolic execution lands, your proofs upgrade for free.

### `octProg!` vs `octthm!` — defining vs proving

`octProg! name { … }` defines the program; you state and prove
theorems later. `octthm! name { … } shows P` does both in one
breath.

## The proof obligations are real

Try changing one of the expected values in `Foundation/ProofExample2.lean`:

```diff
-} shows squareSix ⇓bind "ans" ↦ Value.num 36.0
+} shows squareSix ⇓bind "ans" ↦ Value.num 37.0
```

`lake build OctiveLean.Foundation.ProofExample2` will fail with
`Tactic native_decide evaluated that the proposition … is false`.
The Octave source is the implementation; the `shows` is the spec;
the proof is the agreement.

## What you can write

The DSL covers a working Octave subset:

  * numeric and string literals, identifiers, true/false
  * binary arithmetic, comparison, logical operators
  * unary `-`, `!`
  * if / elseif / else / end, for, while
  * function definitions, calls, anonymous `@(x,y) body`
  * matrix and cell literals, ranges `a:b` and `a:s:b`
  * field access `s.field`, indexing `M(i,j)`, slicing `M(:,1)`
  * simple, multi-return, and complex-LHS assignments

The full grammar is in `OctiveLean/DSL.lean`; the macros for the
proof-side (`octthm!`, `octProg!`, `octF!`) live in
`OctiveLean/Foundation/`.

## What's coming

  * `octs` tactic that unfolds step-by-step so you can read
    intermediate states (rather than just succeeding or failing).
  * `assert!` inside the Octave body, so program-level invariants
    appear in source.
  * Inversion lemmas for proofs about parameterized programs.
  * A library of algebraic identities (`x + 0 ≡ x`, `M' '  ≡ M`)
    so transformations preserve semantics by lemma rather than
    by re-running.
  * Loop-invariant rules for while-style proofs.

For now: write the program, state the postcondition, let `octs`
discharge it. Iterate.
