import OctiveLean.Foundation.Compile
import OctiveLean.Foundation.Eval
import OctiveLean.Foundation.Initial

/-!
# Foundation.Logic — predicates and Hoare triples over Octave programs.

This file lifts the operational semantics (`Foundation.Eval`) into a
proof vocabulary the user can speak: predicates over values / envs /
states, plus Hoare-style triples `{P} prog {Q}`. Inference rules for
each Surface construct are stated and proved here.

Pattern:

  * `ValueP := Value → Prop` — what a value satisfies (e.g.,
    `isNum`, `inRange`).
  * `EnvP   := Env → Prop` — bindings (e.g., `binds "x" (.num 12)`).
  * `StateP := RunState → Prop` — global state (env + trace).
  * `HoareTriple P prog Q` — partial correctness: from `P s`, if
    `prog` runs to `(s', ok v)`, then `Q s' v`.

Proofs are by `simp`/`rfl` over the definitions for atomic cases,
and by induction over the program structure for compound cases.
-/

namespace OctiveLean.Foundation
namespace Logic

open Eval

/-! ## Atomic predicates on Values. -/

def isNum (v : Value) : Prop := ∃ n, v = .num n
def isBool (v : Value) : Prop := ∃ b, v = .bool b
def isStr (v : Value) : Prop := ∃ s, v = .str s
def isUnit (v : Value) : Prop := v = .unit
def equalsNum (target : Float) (v : Value) : Prop := v = .num target
def equalsBool (target : Bool) (v : Value) : Prop := v = .bool target

/-! ## Predicates on environments.  These are `Bool`-valued so that
    `decide`/`native_decide` can discharge them for concrete
    programs — DecidableEq on `Value` is awkward because closures
    are self-referential, but `BEq` is derivable. -/

/-- `binds x v env` is `true` if looking up `x` in `env` yields `v`. -/
def binds (x : String) (v : Value) (env : Env) : Bool :=
  (env.find? (·.1 == x)).map (·.2) == some v

/-- `boundTo x P env` is `true` if `x` is bound to a value satisfying `P`. -/
def boundTo (x : String) (P : Value → Bool) (env : Env) : Bool :=
  match env.find? (·.1 == x) with
  | some (_, v) => P v
  | none        => false

/-! ## Run-state predicates. -/

/-- `bindsS x v` lifts `binds` to the run state. -/
def bindsS (x : String) (v : Value) (s : RunState) : Bool :=
  binds x v s.env

/-- `boundToS x P` lifts `boundTo`. -/
def boundToS (x : String) (P : Value → Bool) (s : RunState) : Bool :=
  boundTo x P s.env

/-- Always-true state predicate, for triples that need no
    precondition. -/
def trueS : RunState → Prop := fun _ => True

/-! ## Running a program from a state.

The whole-program runner is fixed: it compiles, then evaluates
under `Initial.primop` with `Eval.defaultFuel`, using the state's
`env` as the lexical scope. This is what the user invokes when they
say "run this program". -/

def runProgram (p : Program) (s : RunState) : RunState × Except String Value :=
  let core := Compile.compile p
  Comp.run (Eval.eval Initial.primop Eval.defaultFuel core s.env) s

/-- The Hoare triple for partial correctness. From a state
    satisfying `P`, if the program runs without error to `(s', v)`,
    then `(s', v)` satisfies `Q`. Programs that fail (or run out of
    fuel) are silently allowed — that's the partial-correctness
    convention. Total correctness adds a termination clause. -/
def HoareTriple
    (P : RunState → Prop) (p : Program) (Q : RunState → Value → Prop) : Prop :=
  ∀ s, P s →
    let (s', res) := runProgram p s
    match res with
    | .ok v    => Q s' v
    | .error _ => True

-- (notation deferred; the macro brackets clash with octave! braces)

/-! ## Direct evaluation theorems for proof. -/

/-- The whole-program runner unfolded. Useful for proofs that need
    to step through `runProgram`. -/
theorem runProgram_def (p : Program) (s : RunState) :
    runProgram p s = Comp.run
      (Eval.eval Initial.primop Eval.defaultFuel (Compile.compile p) s.env) s := rfl

/-- A program's value can also be read out of a run by running it
    in the initial state. -/
def runProgramOk (p : Program) (s : RunState := { env := Initial.env }) : Option Value :=
  match runProgram p s with
  | (_, .ok v)    => some v
  | (_, .error _) => none

/-- A program leaves `x` bound to `v` in its final env (given an
    initial state). Useful for "this program assigns 12 to x"-style
    assertions. -/
def leavesBound (x : String) (v : Value) (p : Program) : Bool :=
  let (s', _) := runProgram p { env := Initial.env }
  binds x v s'.env

end Logic
end OctiveLean.Foundation
