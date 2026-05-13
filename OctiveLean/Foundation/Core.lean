/-!
# Foundation.Core — the irreducible kernel of the language.

This is the small, total, decidable Core that all surface syntax
eventually compiles into. There is one constructor per fundamental
*meaning*; surface conveniences (`if`/`for`/`while`/matrix literals,
operator overloads, `;`-vs-`,` separators, etc.) are *not* present
here — they live in `Foundation.Surface` and are eliminated by
`Foundation.Compile`.

Design rules:

  1. **Tiny.**  Eight constructors. Anything more belongs in `Surface`.
  2. **Total.**  Every constructor is well-founded by structural
     recursion on its arguments.  No partial pattern matches.
  3. **Effect-free at the AST level.**  `print`/`plot`/`fail` are
     algebraic effects raised at evaluation time (`Foundation.Comp`),
     never tags on the AST.
  4. **Names everywhere.**  Variables, function names, primops all
     resolve through a single environment.  `sin`, `plot`, `+` are
     just identifiers bound in the initial env to primitive functions.
  5. **Sequence is explicit.**  `seq e₁ e₂` discards the value of `e₁`
     and yields the value of `e₂`.  This is what `;`-separation in
     Octave means.  It is *not* a list — recursion on Core is
     structural on the binary tree of `seq` nodes.
-/

namespace OctiveLean.Foundation

/-- Floats are our scalar literal type. Strings, bools, and integers
    live in `Value` (the evaluation result), not in `Core` literals —
    a literal `Core` term is always a float, and other shapes arise
    only by applying primops (e.g. `bool true`, `str "hello"`). -/
inductive Lit where
  | float : Float → Lit
  deriving Repr, BEq

/-- The eight-constructor Core. -/
inductive Core where
  /-- Bound variable lookup. -/
  | var    : String → Core
  /-- Literal value. -/
  | lit    : Lit → Core
  /-- Function application `f a₁ a₂ … aₙ`. Argument list is always
      finite. Primops (sin, plot, +) are `app (var "sin") …`. -/
  | app    : Core → List Core → Core
  /-- Lambda abstraction over zero or more parameters. -/
  | lam    : List String → Core → Core
  /-- `let x = e₁ in e₂`. Non-recursive. -/
  | letin  : String → Core → Core → Core
  /-- Recursive let: `letrec f = e₁ in e₂`. `f` is in scope in `e₁`. -/
  | letrec : String → Core → Core → Core
  /-- Conditional. The condition is interpreted as a bool by
      coercion at evaluation time (zero = false, nonzero = true,
      matching Octave). -/
  | ifte   : Core → Core → Core → Core
  /-- Sequential composition. Evaluates `e₁`, discards its value,
      then evaluates `e₂`. -/
  | seq    : Core → Core → Core
  deriving Repr, Inhabited

/-! Capture-avoiding substitution would go here, but Core's
    semantics is environment-based (see `Foundation.Eval`); we never
    substitute syntactically. The lemma `eval_subst : eval (subst e
    x v) = eval e (env.set x v)` is the proof obligation if we add
    syntactic substitution later.

    A free-variable test `hasFree : String → Core → Bool` also belongs
    here but requires explicit termination because `Core.app` carries
    a `List Core`; we'll add it (with `decreasing_by`) when first
    needed. -/

end OctiveLean.Foundation
