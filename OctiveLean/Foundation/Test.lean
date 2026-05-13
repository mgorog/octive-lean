import OctiveLean.Foundation
import OctiveLean.Foundation.Initial

/-!
# Foundation.Test — round-trip Surface → Core → eval.

A minimal exercise: build a Surface AST for `x = 5; x + 7`,
compile to Core, evaluate via `Comp` in the pure interpreter, and
inspect the trace.

The exercise demonstrates that the foundation pieces are wired
correctly. Once primops (`+`, `*`, `disp`, `plot`, …) are added to
the initial env (their bindings written via `writeVar` at startup),
real programs will route through this same path.
-/

namespace OctiveLean.Foundation.Test

open OctiveLean.Foundation

/-- Hand-built Surface AST for `x = 5; x + 7`. -/
def example1 : Program :=
  [ .assign (.id "x") (.num 5.0) .silent
  , .exprS (.binop .add (.id "x") (.num 7.0)) .silent
  ]

/-- Compiled Core form. -/
def example1Core : Core := Compile.compile example1

/-- The pure-interpreter trace.  `+` is unbound here so a `print`
    effect for the call shows up in the trace; later, when an
    initial env binds `+` to a real closure, the same call returns
    `.num 12.0` directly. -/
def example1Trace : List String × Option Value :=
  Comp.runPure (Eval.eval Initial.primop Eval.defaultFuel example1Core Initial.env)
    { env := Initial.env }

#eval (toString (repr example1Core))
#eval example1Trace.fst
#eval (example1Trace.snd.map toString).getD "<no value>"

end OctiveLean.Foundation.Test
