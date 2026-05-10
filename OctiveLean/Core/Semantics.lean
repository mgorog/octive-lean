import OctiveLean.Core.Syntax

namespace OctiveLean.Core

/-! # Big-step operational semantics for TOC.

Threads `Env` (no heap — Octave has no explicit references). `assign x e`
mutates the env by prepending; subsequent `var x` lookups see the new
binding. Closures capture the env at λ-evaluation time (lexical scope).

Compare with TGC's `BigStep : Heap → Env → Term → Value → Heap → Prop`:
TOC's signature `BigStep : Env → Term → Value → Env → Prop` differs in
the *state type* (Env vs Heap × Env). Constructors for the shared subset
(unitR, intLitR, boolLitR, varR, lamR, appR, letInR, ifTR, ifFR, binopR,
seqR) match TGC's structure rule-for-rule. -/

mutual

  inductive Value where
    | vUnit  : Value
    | vInt   : Int  → Value
    | vBool  : Bool → Value
    | vClos  : String → Term → EnvList → Value

  inductive EnvList where
    | nil    : EnvList
    | cons   : String → Value → EnvList → EnvList

end

abbrev Env := EnvList

namespace EnvList

def lookup : EnvList → String → Option Value
  | .nil,        _ => none
  | .cons k v r, x => if k = x then some v else lookup r x

def extend (env : EnvList) (x : String) (v : Value) : EnvList :=
  .cons x v env

end EnvList

namespace BinOp

def apply : BinOp → Value → Value → Option Value
  | .add, .vInt a,  .vInt b  => some (.vInt (a + b))
  | .sub, .vInt a,  .vInt b  => some (.vInt (a - b))
  | .mul, .vInt a,  .vInt b  => some (.vInt (a * b))
  | .eq,  .vInt a,  .vInt b  => some (.vBool (a == b))
  | .eq,  .vBool a, .vBool b => some (.vBool (a == b))
  | .lt,  .vInt a,  .vInt b  => some (.vBool (a < b))
  | _,    _,        _        => none

end BinOp

inductive BigStep : Env → Term → Value → Env → Prop where
  | unitR    {env} :
      BigStep env .unitT .vUnit env
  | intLitR  {env} (n : Int) :
      BigStep env (.intLit n) (.vInt n) env
  | boolLitR {env} (b : Bool) :
      BigStep env (.boolLit b) (.vBool b) env
  | varR     {env x v} (hLook : env.lookup x = some v) :
      BigStep env (.var x) v env
  | lamR     {env} (x : String) (body : Term) :
      BigStep env (.lam x body) (.vClos x body env) env
  | appR     {env e1 e2 x body env_clos v_arg v env1 env2 env3}
             (D1 : BigStep env  e1 (.vClos x body env_clos) env1)
             (D2 : BigStep env1 e2 v_arg env2)
             (Db : BigStep (env_clos.extend x v_arg) body v env3) :
      BigStep env (.app e1 e2) v env2
  | letInR   {env x e1 e2 v1 v2 env1 env2}
             (D1 : BigStep env  e1 v1 env1)
             (D2 : BigStep (env1.extend x v1) e2 v2 env2) :
      BigStep env (.letIn x e1 e2) v2 env2
  | ifTR     {env ec e1 e2 v env1 env2}
             (Dc : BigStep env  ec (.vBool true) env1)
             (Dt : BigStep env1 e1 v env2) :
      BigStep env (.ifte ec e1 e2) v env2
  | ifFR     {env ec e1 e2 v env1 env2}
             (Dc : BigStep env  ec (.vBool false) env1)
             (Df : BigStep env1 e2 v env2) :
      BigStep env (.ifte ec e1 e2) v env2
  | binopR   {env op e1 e2 v1 v2 v env1 env2}
             (D1 : BigStep env  e1 v1 env1)
             (D2 : BigStep env1 e2 v2 env2)
             (Hop : op.apply v1 v2 = some v) :
      BigStep env (.binop op e1 e2) v env2
  | seqR     {env e1 e2 v1 v2 env1 env2}
             (D1 : BigStep env  e1 v1 env1)
             (D2 : BigStep env1 e2 v2 env2) :
      BigStep env (.seq e1 e2) v2 env2
  | assignR  {env x e v env1}
             (D : BigStep env e v env1) :
      BigStep env (.assign x e) .vUnit (env1.extend x v)
  | whileFR  {env c b env1}
             (Dc : BigStep env c (.vBool false) env1) :
      BigStep env (.whileT c b) .vUnit env1
  | whileTR  {env c b env1 env2 env3 v_b}
             (Dc : BigStep env  c (.vBool true) env1)
             (Db : BigStep env1 b v_b env2)
             (Dw : BigStep env2 (.whileT c b) .vUnit env3) :
      BigStep env (.whileT c b) .vUnit env3

end OctiveLean.Core
