import OctiveLean.Foundation.Core

/-!
# Foundation.Eval — total operational semantics of Core.

`Comp α` is a transformer stack `ExceptT String (StateT RunState Id) α`
— equivalently a pure function `RunState → (Except String α × RunState)`.
Both `bind` and `pure` are inherited from Lean stdlib and are total.

`eval` is a `def` (not `partial`) bounded by an explicit fuel
parameter. Determinism is then trivial — `eval` is a Lean function,
and two calls with equal inputs yield equal outputs by `rfl`.

Effects (`print`, `plot`, env reads/writes) are recorded as state
mutations; the resulting `RunState` carries the trace.
-/

namespace OctiveLean.Foundation

/-! ## Values.  See `Foundation.Surface` for the surface analogue. -/

inductive Value where
  | num     : Float → Value
  | str     : String → Value
  | bool    : Bool → Value
  | matrix  : Nat → Nat → Array Float → Value
  | range   : Float → Float → Float → Value
  | closure : List String → Core → List (String × Value) → Value
  | builtin : String → Value
  | unit    : Value
  deriving Inhabited, BEq

abbrev Env := List (String × Value)

/-- A textual rendering for trace output.  Doesn't fully render
    closures — environments are self-referential. -/
partial def Value.toString : Value → String
  | .num n      => s!"{n}"
  | .str s      => s!"\"{s}\""
  | .bool b     => if b then "true" else "false"
  | .matrix r c _ => s!"<matrix {r}×{c}>"
  | .range a s b => s!"<range {a}:{s}:{b}>"
  | .closure ps _ _ => s!"<closure ({String.intercalate ", " ps})>"
  | .builtin n  => s!"<builtin {n}>"
  | .unit       => "()"

instance : ToString Value := ⟨Value.toString⟩

/-! ## Computation monad.

`RunState` accumulates effects (output, plots) and carries the
current binding table. `Comp` is the standard monad-transformer
stack — Lean's stdlib provides total instances. -/

structure Plot where
  -- abstract for now; the runtime fills this in via a richer state.
  payload : String
  deriving Inhabited

structure RunState where
  env   : Env := []
  out   : List String := []
  plots : List Plot := []
  deriving Inhabited

abbrev Comp (α : Type) := ExceptT String (StateT RunState Id) α

namespace Comp

/-- Read the state. -/
def get : Comp RunState :=
  fun s => pure (.ok s, s)

/-- Mutate the state. -/
def modify (f : RunState → RunState) : Comp Unit :=
  fun s => pure (.ok (), f s)

/-- Raise a runtime error. -/
def fail (msg : String) : Comp α :=
  fun s => pure (.error msg, s)

/-- Append a line to the trace. -/
def print (msg : String) : Comp Unit :=
  modify (fun s => { s with out := s.out ++ [msg] })

/-- Add a plot to the trace. -/
def plot (p : Plot) : Comp Unit :=
  modify (fun s => { s with plots := s.plots ++ [p] })

/-- Read a binding from the *global* state. Local lexical env is
    threaded as a function argument in `eval`. -/
def readVar (name : String) : Comp Value :=
  fun s =>
    match s.env.find? (·.1 == name) with
    | some (_, v) => pure (.ok v, s)
    | none        => pure (.error s!"unbound name: {name}", s)

/-- Write a binding to the *global* state, replacing any prior value
    for the same name. -/
def writeVar (name : String) (v : Value) : Comp Unit :=
  modify (fun s =>
    { s with env := (name, v) :: s.env.filter (·.1 != name) })

/-- Run a `Comp` against an initial state, returning the final
    state plus the result-or-error. -/
def run (m : Comp α) (s : RunState := {}) : RunState × Except String α :=
  let (r, s') := (m s).run
  (s', r)

/-- Pure wrapper that returns (trace, optional-value). -/
def runPure (m : Comp Value) (s : RunState := {}) : List String × Option Value :=
  let (s', r) := run m s
  match r with
  | .ok v    => (s'.out, some v)
  | .error _ => (s'.out, none)

end Comp

/-! ## Evaluation.

`eval fuel prim e env` returns the meaning of `e` under the lexical
binding list `env`, using `prim` to dispatch built-in calls.

Eight Core constructors, one case per constructor. Fuel decreases
on every recursive call; running out yields a `fail` effect.

`partial`-free: structural recursion on `fuel : Nat`. -/

namespace Eval

abbrev PrimopDispatch := String → List Value → Comp Value

def lookupEnv (x : String) : Env → Option Value
  | []          => none
  | (y, v) :: r => if y == x then some v else lookupEnv x r

def truthy : Value → Bool
  | .num n  => n != 0.0
  | .bool b => b
  | .unit   => false
  | _       => true

/-- Helper that walks a list of Core terms, evaluating each and
    accumulating values. Structural recursion on the list. -/
def evalArgs (eval : Core → Env → Comp Value) (args : List Core) (env : Env)
    : Comp (List Value) :=
  match args with
  | []        => pure []
  | a :: rest => do
      let v ← eval a env
      let vs ← evalArgs eval rest env
      pure (v :: vs)

/-- The evaluator, structurally recursive on `fuel`. The actual
    expression `e` may be arbitrarily large but each recursive call
    decreases `fuel` by 1; on exhaustion we fail. -/
def eval (prim : PrimopDispatch) : Nat → Core → Env → Comp Value
  | 0, _, _ => Comp.fail "fuel exhausted"
  | _+1, .var x, env =>
      match lookupEnv x env with
      | some v => pure v
      | none   => Comp.readVar x
  | _+1, .lit (.float f), _ => pure (.num f)
  | _+1, .lit (.str s), _   => pure (.str s)
  | _+1, .lit (.bool b), _  => pure (.bool b)
  | _+1, .lam ps body, env  => pure (.closure ps body env)
  | n+1, .letin x e₁ e₂, env => do
      let v ← eval prim n e₁ env
      eval prim n e₂ ((x, v) :: env)
  | n+1, .letrec x e₁ e₂, env => do
      let v ← eval prim n e₁ ((x, .unit) :: env)
      let v' := match v with
        | .closure ps b _ => .closure ps b ((x, v) :: env)
        | other            => other
      eval prim n e₂ ((x, v') :: env)
  | n+1, .ifte c t e', env => do
      let cv ← eval prim n c env
      if truthy cv then eval prim n t env else eval prim n e' env
  | n+1, .seq a b, env => do
      let _ ← eval prim n a env
      eval prim n b env
  | n+1, .app f args, env => do
      let fv ← eval prim n f env
      let argvs ← evalArgs (eval prim n) args env
      match fv with
      | .closure ps body capEnv =>
          let bindings := List.zip ps argvs
          eval prim n body (bindings ++ capEnv)
      | .builtin name =>
          prim name argvs
      | _ =>
          Comp.fail "call of non-function value"

/-- Default fuel budget for "small" programs. Real callers should
    pick a value appropriate to their workload (or use a streaming
    variant once we add one). -/
def defaultFuel : Nat := 1000

/-- Determinism: `eval` is a function — equal inputs give equal
    outputs. The theorem is `rfl` because `eval` is a `def`. -/
theorem eval_deterministic
    (prim : PrimopDispatch) (fuel : Nat) (e : Core) (env : Env) :
    eval prim fuel e env = eval prim fuel e env := rfl

end Eval
end OctiveLean.Foundation
