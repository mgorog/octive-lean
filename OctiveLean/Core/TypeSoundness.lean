import OctiveLean.Core.Types
import OctiveLean.Core.Semantics

namespace OctiveLean.Core

/-! # Type soundness infrastructure for TOC.

Asymmetry vs TGC: TOC's `assign` mutates env, so the "runtime data is
well-typed" property must be permissive — env may have *more* bindings
than Γ requires. So `HasTypeEnv` is a function-form predicate (Π → ∃),
not a structural inductive (TGC could afford structural because its
env is scoped; only the heap mutates).

Closure typing: `vClos` would naturally take `HasTypeEnv` as a premise,
but the kernel rejects nested ∃ in inductive constructors with locally
bound parameters. So we split into two strictly-positive premises —
domain coverage and pointwise typing — and rebuild `HasTypeEnv` outside.
The two formulations are interconvertible (lemmas below). -/

inductive HasTypeV : Value → Ty → Prop where
  | vUnit  : HasTypeV .vUnit .unit
  | vInt   (n : Int)  : HasTypeV (.vInt n) .int
  | vBool  (b : Bool) : HasTypeV (.vBool b) .bool
  | vClos  {x : String} {body : Term} {env : Env}
           {Γ : TyEnv} {T_arg T_ret : Ty}
           (he_dom   : ∀ y T_y, Γ.lookup y = some T_y → (env.lookup y).isSome)
           (he_typed : ∀ y T_y v, Γ.lookup y = some T_y →
                        env.lookup y = some v → HasTypeV v T_y)
           (hb : HasType (Γ.extend x T_arg) body T_ret) :
      HasTypeV (.vClos x body env) (.arrow T_arg T_ret)

def HasTypeEnv (env : Env) (Γ : TyEnv) : Prop :=
  ∀ y T_y, Γ.lookup y = some T_y → ∃ v, env.lookup y = some v ∧ HasTypeV v T_y

namespace HasTypeEnv

theorem extend_typed
    {env : Env} {Γ : TyEnv} {x : String} {v : Value} {T : Ty}
    (hE : HasTypeEnv env Γ)
    (hx : Γ.lookup x = some T)
    (hv : HasTypeV v T) :
    HasTypeEnv (env.extend x v) Γ := by
  intro y T_y hLy
  by_cases hxy : x = y
  · subst hxy
    rw [hLy] at hx
    cases hx
    refine ⟨v, ?_, hv⟩
    simp [EnvList.lookup, EnvList.extend]
  · have ⟨v', hLv', hVT'⟩ := hE y T_y hLy
    refine ⟨v', ?_, hVT'⟩
    simp [EnvList.lookup, EnvList.extend, hxy]
    exact hLv'

theorem extend_letIn
    {env : Env} {Γ : TyEnv} {x : String} {v : Value} {T : Ty}
    (hE : HasTypeEnv env Γ) (hv : HasTypeV v T) :
    HasTypeEnv (env.extend x v) (Γ.extend x T) := by
  intro y T_y hLy
  by_cases hxy : x = y
  · subst hxy
    simp only [TyEnv.extend, TyEnv.lookup] at hLy
    simp at hLy
    subst hLy
    refine ⟨v, ?_, hv⟩
    simp [EnvList.lookup, EnvList.extend]
  · simp only [TyEnv.extend, TyEnv.lookup] at hLy
    simp [hxy] at hLy
    have ⟨v', hLv', hVT'⟩ := hE y T_y hLy
    refine ⟨v', ?_, hVT'⟩
    simp [EnvList.lookup, EnvList.extend, hxy]
    exact hLv'

end HasTypeEnv

/-! ## Bridge between vClos's two-part formulation and HasTypeEnv. -/

theorem HasTypeV.vClos_of_env
    {x : String} {body : Term} {env : Env} {Γ : TyEnv}
    {T_arg T_ret : Ty}
    (hE : HasTypeEnv env Γ)
    (hb : HasType (Γ.extend x T_arg) body T_ret) :
    HasTypeV (.vClos x body env) (.arrow T_arg T_ret) := by
  apply HasTypeV.vClos
  · intros y T_y hLy
    have ⟨_, hLv, _⟩ := hE y T_y hLy
    rw [hLv]; rfl
  · intros y T_y v hLy hLv
    have ⟨v', hLv', hVT'⟩ := hE y T_y hLy
    rw [hLv'] at hLv
    cases hLv
    exact hVT'
  · exact hb

end OctiveLean.Core
