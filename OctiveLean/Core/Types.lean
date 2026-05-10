import OctiveLean.Core.Syntax

namespace OctiveLean.Core

/-! # Static type system for TOC.

Four base types — `unit`, `int`, `bool`, `arrow`. No `ref` (Octave has
no explicit references, unlike TGC). Two new typing rules over TGC's
shared core:

  * `assign x e` requires `x` to already be typed in Γ with the same
    type as `e`. New variables enter scope via `letIn`, not assign.
  * `whileT c b` types as `unit` whenever `c : bool` and `b` types at
    any T (the body's value is discarded). -/

inductive Ty where
  | unit  : Ty
  | int   : Ty
  | bool  : Ty
  | arrow : Ty → Ty → Ty
  deriving Repr, BEq, DecidableEq, Inhabited

abbrev TyEnv := List (String × Ty)

namespace TyEnv

def lookup : TyEnv → String → Option Ty
  | [],            _ => none
  | (k, T) :: rs, x => if k = x then some T else lookup rs x

def extend (Γ : TyEnv) (x : String) (T : Ty) : TyEnv :=
  (x, T) :: Γ

end TyEnv

namespace BinOp

def typeOf : BinOp → Ty → Ty → Option Ty
  | .add, .int,  .int  => some .int
  | .sub, .int,  .int  => some .int
  | .mul, .int,  .int  => some .int
  | .eq,  .int,  .int  => some .bool
  | .eq,  .bool, .bool => some .bool
  | .lt,  .int,  .int  => some .bool
  | _,    _,     _     => none

end BinOp

inductive HasType : TyEnv → Term → Ty → Prop where
  | unitT  {Γ} : HasType Γ .unitT .unit
  | intLit {Γ} (n : Int) : HasType Γ (.intLit n) .int
  | boolLit {Γ} (b : Bool) : HasType Γ (.boolLit b) .bool
  | var    {Γ x T} (h : Γ.lookup x = some T) :
      HasType Γ (.var x) T
  | lam    {Γ x body T_arg T_ret}
           (h : HasType (Γ.extend x T_arg) body T_ret) :
      HasType Γ (.lam x body) (.arrow T_arg T_ret)
  | app    {Γ e1 e2 T_arg T_ret}
           (h1 : HasType Γ e1 (.arrow T_arg T_ret))
           (h2 : HasType Γ e2 T_arg) :
      HasType Γ (.app e1 e2) T_ret
  | letIn  {Γ x e1 e2 T1 T2}
           (h1 : HasType Γ e1 T1)
           (h2 : HasType (Γ.extend x T1) e2 T2) :
      HasType Γ (.letIn x e1 e2) T2
  | ifte   {Γ ec e1 e2 T}
           (hc : HasType Γ ec .bool)
           (h1 : HasType Γ e1 T)
           (h2 : HasType Γ e2 T) :
      HasType Γ (.ifte ec e1 e2) T
  | binop  {Γ op e1 e2 T1 T2 T}
           (h1 : HasType Γ e1 T1)
           (h2 : HasType Γ e2 T2)
           (hOp : op.typeOf T1 T2 = some T) :
      HasType Γ (.binop op e1 e2) T
  | seq    {Γ e1 e2 T1 T2}
           (h1 : HasType Γ e1 T1)
           (h2 : HasType Γ e2 T2) :
      HasType Γ (.seq e1 e2) T2
  | assign {Γ x e T}
           (hx : Γ.lookup x = some T)
           (h : HasType Γ e T) :
      HasType Γ (.assign x e) .unit
  | whileT {Γ c b T_b}
           (hc : HasType Γ c .bool)
           (hb : HasType Γ b T_b) :
      HasType Γ (.whileT c b) .unit

end OctiveLean.Core
