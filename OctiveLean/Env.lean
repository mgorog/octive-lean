import OctiveLean.Value

namespace OctiveLean

/-! Scope and environment management -/

/-- A single scope frame (function call frame or top-level) -/
structure Scope where
  vars     : Array (String × Value)   -- local variables
  globals  : Array String             -- names declared `global` in this scope
  persist  : Array String             -- names declared `persistent`
  retVals  : Array String             -- expected return variable names
  deriving Inhabited

namespace Scope
  def empty : Scope := { vars := #[], globals := #[], persist := #[], retVals := #[] }

  def get (s : Scope) (name : String) : Option Value :=
    s.vars.findSome? fun (k, v) => if k == name then some v else none

  def set (s : Scope) (name : String) (val : Value) : Scope :=
    let idx := s.vars.findIdx? fun (k, _) => k == name
    match idx with
    | some i => { s with vars := s.vars.set! i (name, val) }
    | none   => { s with vars := s.vars.push (name, val) }

  def del (s : Scope) (name : String) : Scope :=
    { s with vars := s.vars.filter fun (k, _) => k != name }
end Scope

/-- The interpreter environment: a call stack of scopes + global frame -/
structure Env where
  stack   : Array Scope          -- call stack; last = current frame
  globals : Array (String × Value)  -- global workspace
  builtinRegistry : Array (String × (Array Value → IO (Array Value)))
  deriving Inhabited

namespace Env
  def empty : Env := { stack := #[Scope.empty], globals := #[], builtinRegistry := #[] }

  /-- Current (innermost) scope -/
  def currentScope (env : Env) : Scope :=
    if env.stack.isEmpty then Scope.empty
    else env.stack.back!

  /-- Update the current scope -/
  def updateScope (env : Env) (f : Scope → Scope) : Env :=
    if env.stack.isEmpty then env
    else { env with stack := env.stack.set! (env.stack.size - 1) (f env.currentScope) }

  /-- Look up a variable: current scope, then globals -/
  def get (env : Env) (name : String) : Option Value :=
    let scope := env.currentScope
    -- if declared global in this scope, redirect to global frame
    if scope.globals.contains name then
      env.globals.findSome? fun (k, v) => if k == name then some v else none
    else
      match scope.get name with
      | some v => some v
      | none   =>
        -- also check global frame for top-level variables
        if env.stack.size == 1 then
          env.globals.findSome? fun (k, v) => if k == name then some v else none
        else
          -- inside a function: functions from top-level workspace are accessible
          let globalVal := env.stack[0]?.bind (·.get name)
          match globalVal with
          | some v => match v with
              | .fn _ => some v
              | _ => env.globals.findSome? fun (k, gv) => if k == name then some gv else none
          | none => env.globals.findSome? fun (k, v) => if k == name then some v else none

  /-- Set a variable in the current scope -/
  def set (env : Env) (name : String) (val : Value) : Env :=
    let scope := env.currentScope
    if scope.globals.contains name then
      -- write to global frame
      let idx := env.globals.findIdx? fun (k, _) => k == name
      match idx with
      | some i => { env with globals := env.globals.set! i (name, val) }
      | none   => { env with globals := env.globals.push (name, val) }
    else
      env.updateScope (·.set name val)

  /-- Declare a name as global in the current scope -/
  def declareGlobal (env : Env) (name : String) : Env :=
    env.updateScope fun s => { s with globals := s.globals.push name }

  /-- Push a new call frame -/
  def pushFrame (env : Env) (retVals : Array String) : Env :=
    { env with stack := env.stack.push { Scope.empty with retVals } }

  /-- Pop the current call frame; return (env without frame, frame's return values) -/
  def popFrame (env : Env) : Env × Scope :=
    if env.stack.size <= 1 then (env, Scope.empty)
    else
      let frame := env.stack.back!
      ({ env with stack := env.stack.pop }, frame)

  /-- Register a builtin function -/
  def registerBuiltin (env : Env) (name : String)
      (fn : Array Value → IO (Array Value)) : Env :=
    let idx := env.builtinRegistry.findIdx? fun (k, _) => k == name
    match idx with
    | some i => { env with builtinRegistry := env.builtinRegistry.set! i (name, fn) }
    | none   => { env with builtinRegistry := env.builtinRegistry.push (name, fn) }

  /-- Look up a builtin -/
  def getBuiltin (env : Env) (name : String)
      : Option (Array Value → IO (Array Value)) :=
    env.builtinRegistry.findSome? fun (k, v) => if k == name then some v else none
end Env

end OctiveLean
