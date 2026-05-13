import OctiveLean.Foundation.Eval

/-!
# Foundation.Initial — the primop registry and initial environment.

A `Value.builtin "name"` is a marker; the actual semantics is in
`primop : String → List Value → Comp Value`. The pre-eval setup is:

  * Bind every primop name to `Value.builtin "<name>"` in the initial env.
  * `Eval.app` dispatches builtin calls to `primop` here.

This is the *only* place where the meaning of `+`, `disp`, `plot`,
`sin`, etc. lives. Adding a new primop is one line in `primop`
plus one line in `initial`.
-/

namespace OctiveLean.Foundation

namespace Initial

open Comp

/-! ## Coercion helpers — float-typed views of values. -/

def asNum? : Value → Option Float
  | .num n  => some n
  | .bool b => some (if b then 1.0 else 0.0)
  | _       => none

def asBool? : Value → Option Bool
  | .bool b => some b
  | .num n  => some (n != 0.0)
  | _       => none

def asStr? : Value → Option String
  | .str s => some s
  | _      => none

/-! ## Primop interpreter.

`primop name args` returns the result value (in `Comp`) of calling
the named primitive on `args`. Unknown primops raise `fail`. -/

def numBinop (name : String) (f : Float → Float → Float)
    (args : List Value) : Comp Value :=
  match args with
  | [a, b] =>
      match asNum? a, asNum? b with
      | some x, some y => pure (.num (f x y))
      | _, _ => Comp.fail s!"{name}: expected two numbers"
  | _ => Comp.fail s!"{name}: expected 2 args"

def numUnop (name : String) (f : Float → Float)
    (args : List Value) : Comp Value :=
  match args with
  | [a] =>
      match asNum? a with
      | some x => pure (.num (f x))
      | none   => Comp.fail s!"{name}: expected a number"
  | _ => Comp.fail s!"{name}: expected 1 arg"

def cmpBinop (name : String) (f : Float → Float → Bool)
    (args : List Value) : Comp Value :=
  match args with
  | [a, b] =>
      match asNum? a, asNum? b with
      | some x, some y => pure (.bool (f x y))
      | _, _ => Comp.fail s!"{name}: expected two numbers"
  | _ => Comp.fail s!"{name}: expected 2 args"

def boolBinop (name : String) (f : Bool → Bool → Bool)
    (args : List Value) : Comp Value :=
  match args with
  | [a, b] =>
      match asBool? a, asBool? b with
      | some x, some y => pure (.bool (f x y))
      | _, _ => Comp.fail s!"{name}: expected two bools"
  | _ => Comp.fail s!"{name}: expected 2 args"

/-- The dispatch table. Keep alphabetical-ish within each section. -/
def primop : String → List Value → Comp Value
  -- Arithmetic
  | "+",  args => numBinop "+"  (· + ·) args
  | "-",  args => numBinop "-"  (· - ·) args
  | "*",  args => numBinop "*"  (· * ·) args
  | "/",  args => numBinop "/"  (· / ·) args
  | "^",  args => numBinop "^"  (· ^ ·) args
  | ".*", args => numBinop ".*" (· * ·) args
  | "./", args => numBinop "./" (· / ·) args
  | ".^", args => numBinop ".^" (· ^ ·) args
  | "-_", args => numUnop "-"   (-·)    args
  -- Comparisons
  | "<",  args => cmpBinop "<"  (· < ·) args
  | "<=", args => cmpBinop "<=" (· <= ·) args
  | ">",  args => cmpBinop ">"  (· > ·) args
  | ">=", args => cmpBinop ">=" (· >= ·) args
  | "==", args => cmpBinop "==" (· == ·) args
  | "!=", args => cmpBinop "!=" (· != ·) args
  -- Logic
  | "&&", args => boolBinop "&&" (· && ·) args
  | "||", args => boolBinop "||" (· || ·) args
  | "&",  args => boolBinop "&"  (· && ·) args
  | "|",  args => boolBinop "|"  (· || ·) args
  | "!",  args =>
      match args with
      | [a] => match asBool? a with
        | some b => pure (.bool !b)
        | none   => Comp.fail "!: expected bool"
      | _ => Comp.fail "!: expected 1 arg"
  -- Transcendentals
  | "sin",  args => numUnop "sin"  Float.sin  args
  | "cos",  args => numUnop "cos"  Float.cos  args
  | "tan",  args => numUnop "tan"  Float.tan  args
  | "sqrt", args => numUnop "sqrt" Float.sqrt args
  | "exp",  args => numUnop "exp"  Float.exp  args
  | "log",  args => numUnop "log"  Float.log  args
  | "abs",  args => numUnop "abs"  Float.abs  args
  -- Display & I/O
  | "disp", args =>
      match args with
      | [v] => do
          let _ ← Comp.print (toString v)
          pure .unit
      | _ => Comp.fail "disp: expected 1 arg"
  | "echo", args =>
      match args with
      | [v] => do
          let _ ← Comp.print s!"ans = {v}"
          pure v
      | _ => Comp.fail "echo: expected 1 arg"
  | "print", args =>
      do
        let _ ← Comp.print (String.intercalate " " (args.map toString))
        pure .unit
  -- Statement-level utilities. `bind` is the env-mutating side of
  -- assignment; `noop` is the unit-valued no-op the compiler uses
  -- for empty `else` / empty switch fallthrough.
  | "bind", args =>
      match args with
      | [.str name, v] => do
          let _ ← Comp.writeVar name v
          pure v
      | _ => Comp.fail "bind: expected (str, value)"
  | "noop", _   => pure .unit
  | "true",  _  => pure (.bool true)
  | "false", _  => pure (.bool false)
  | "fail",  args =>
      match args with
      | [.str msg] => Comp.fail msg
      | _          => Comp.fail "fail: expected (str message)"
  -- Unknown primop
  | name, _ => Comp.fail s!"unknown primop: {name}"

/-- Initial environment: bind every primop name to a `.builtin` value
    so name-lookup in `eval` finds it. The list mirrors `primop`. -/
def env : Env := [
  "+", "-", "*", "/", "^", ".*", "./", ".^", "-_",
  "<", "<=", ">", ">=", "==", "!=",
  "&&", "||", "&", "|", "!",
  "sin", "cos", "tan", "sqrt", "exp", "log", "abs",
  "disp", "echo", "print",
  "bind", "noop", "true", "false", "fail"
].map (fun n => (n, Value.builtin n))

end Initial
end OctiveLean.Foundation
