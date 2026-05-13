import OctiveLean.Foundation.Core

/-!
# Foundation.Eval — operational semantics of Core via a free monad.

The evaluator yields a `Comp a` — an algebraic-effects free monad —
which separates the *meaning* of a Core term from *how* its effects
are interpreted.  A pure caller can:

  * inspect a `Comp` and verify which effects it raises in what order
    (great for testing plot programs without rendering),
  * interpret it in IO (the real runtime), or
  * interpret it in a pure runner (`runPure`) used in property tests.

The eight Core constructors yield exactly eight cases in `eval`.
Effects are introduced *only* at primop calls or variable lookups
that miss the local env.  All other Core constructors are pure data
flow.
-/

namespace OctiveLean.Foundation

/-! ## Values.

`Value` is the runtime payload — what `eval` returns.  `closure`
captures its lexical environment as a list of bindings, which closes
the recursion between `Value` and the binding list (`Env`).  We
don't make `Env` an `abbrev` of `List (String × Value)` because that
would put it in the same definition group as `Value`, which is
already inductive — mixed-kind mutual groups are rejected. -/

inductive Value where
  | num     : Float → Value
  | str     : String → Value
  | bool    : Bool → Value
  | matrix  : Nat → Nat → Array Float → Value
  | range   : Float → Float → Float → Value
  | closure : List String → Core → List (String × Value) → Value
  | builtin : String → Value
  | unit    : Value
  deriving Inhabited

/-- A finite display of a Value — full Repr would need to handle the
    self-referential closure env; we summarise instead. -/
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

/-- An environment is a stack of name→value bindings. -/
abbrev Env := List (String × Value)

/-! ## Effects.

Each constructor names one observable side-effect; the continuation
in `Comp` consumes the effect's *result value*. `writeVar` and
`print` return `unit`; `readVar` returns the looked-up value.  -/

inductive Eff where
  | readVar  : String → Eff
  | writeVar : String → Value → Eff
  | print    : String → Eff
  | plot     : Value → Eff
  | fail     : String → Eff
  deriving Inhabited

/-- The free monad over `Eff`.  `pure a` finishes the computation;
    `bind e k` raises an effect and continues with the result. -/
inductive Comp (α : Type) : Type where
  | pure : α → Comp α
  | bind : Eff → (Value → Comp α) → Comp α

instance [Inhabited α] : Inhabited (Comp α) := ⟨.pure default⟩

namespace Comp

def map (f : α → β) : Comp α → Comp β
  | .pure a    => .pure (f a)
  | .bind e k  => .bind e (fun v => map f (k v))

def andThen : Comp α → (α → Comp β) → Comp β
  | .pure a,   k => k a
  | .bind e g, k => .bind e (fun v => andThen (g v) k)

instance : Monad Comp where
  pure := .pure
  bind := Comp.andThen

/-- Lift one effect into the monad, returning its result. -/
def perform (e : Eff) : Comp Value :=
  .bind e .pure

/-! ## Pure interpreter.

`runPure` interprets a `Comp` deterministically, accumulating
output and an optional error, with no IO.  This is the model the
proofs reason about (e.g., "evaluating a determined program yields
a determined trace"). -/

structure PureState where
  env : Env := []
  out : List String := []
  err : Option String := none

partial def runPure (m : Comp Value) (s : PureState := {}) : PureState × Option Value :=
  match m with
  | .pure v          => (s, some v)
  | .bind eff k =>
      match eff with
      | .readVar x =>
          let v := (s.env.find? (·.1 == x)).map (·.2) |>.getD .unit
          runPure (k v) s
      | .writeVar x v =>
          let env' := (x, v) :: s.env.filter (·.1 != x)
          runPure (k .unit) { s with env := env' }
      | .print msg =>
          runPure (k .unit) { s with out := s.out ++ [msg] }
      | .plot _ =>
          runPure (k .unit) s
      | .fail msg =>
          ({ s with err := some msg }, none)

end Comp

/-! ## Evaluation.

`eval e env` returns a `Comp Value` whose pure interpretation is
the meaning of `e` under `env`.  Cases:

  * `var x`   — local lookup; missing → `readVar` effect
                (the host runtime can resolve global names there).
  * `lit (.float f)` — pure `.num f`.
  * `lam ps b` — `.closure ps b env`.
  * `letin x e₁ e₂` — evaluate e₁, extend env, eval e₂.
  * `letrec x e₁ e₂` — bind a placeholder, evaluate e₁, repair the
                       closure's captured env to point at itself,
                       then evaluate e₂.  Sound when e₁ reduces to
                       a closure without entering it (the body
                       isn't executed during the initial reduction).
  * `ifte c t e'` — eval c, branch by `truthy`.
  * `seq a b` — eval a, discard, eval b.
  * `app f as` — eval f, eval each a in order, dispatch:
                 closure → extend env, eval body.
                 builtin → raise an effect the runtime resolves.
                 anything else → fail.
-/

namespace Eval

def lookupEnv (x : String) : Env → Option Value
  | []          => none
  | (y, v) :: r => if y == x then some v else lookupEnv x r

def truthy : Value → Bool
  | .num n  => n != 0.0
  | .bool b => b
  | .unit   => false
  | _       => true

partial def eval (e : Core) (env : Env) : Comp Value := do
  match e with
  | .var x =>
      match lookupEnv x env with
      | some v => pure v
      | none   => Comp.perform (.readVar x)
  | .lit (.float f) =>
      pure (.num f)
  | .lam ps body =>
      pure (.closure ps body env)
  | .letin x e₁ e₂ => do
      let v ← eval e₁ env
      eval e₂ ((x, v) :: env)
  | .letrec x e₁ e₂ => do
      let v ← eval e₁ ((x, .unit) :: env)
      let v' := match v with
        | .closure ps b _ => .closure ps b ((x, v) :: env)
        | other            => other
      eval e₂ ((x, v') :: env)
  | .ifte c t e' => do
      let cv ← eval c env
      if truthy cv then eval t env else eval e' env
  | .seq a b => do
      let _ ← eval a env
      eval b env
  | .app f args => do
      let fv ← eval f env
      let argvs ← args.foldlM (init := ([] : List Value)) (fun acc a => do
        let v ← eval a env
        pure (acc ++ [v]))
      match fv with
      | .closure ps body capEnv =>
          let bindings := List.zip ps argvs
          eval body (bindings ++ capEnv)
      | .builtin name =>
          Comp.perform (.print s!"call {name}({argvs.length} args)")
      | _ =>
          Comp.perform (.fail "call of non-function value")

end Eval
end OctiveLean.Foundation
