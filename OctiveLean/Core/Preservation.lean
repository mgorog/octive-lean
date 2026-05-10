import OctiveLean.Core.TypeSoundness

namespace OctiveLean.Core

/-! # Preservation theorem for TOC big-step semantics.

  `Γ ⊢ e : T  ∧  HasTypeEnv env Γ  ∧  BigStep env e v env'
     ⟹  HasTypeV v T  ∧  HasTypeEnv env' Γ`

Compare with TGC's preservation: there's no heap-typing extension, no
heap-update lemmas — the state is just the env. Γ is unchanged by big
steps (`assign` requires `x` already typed; mutates value only).

`letIn` has scope-restoring semantics — its post-env is the env after
evaluating the bound expression, not after evaluating the body. This
differs from TGC's letIn (which has no env to leak) and is what makes
preservation provable in the presence of mutation. -/

/-! ## Inversion for binop typing — same shape as TGC's. -/

theorem binop_apply_sound
    {op : BinOp} {v1 v2 v : Value} {T1 T2 T : Ty}
    (hOp : op.typeOf T1 T2 = some T)
    (hV1 : HasTypeV v1 T1) (hV2 : HasTypeV v2 T2)
    (hApp : op.apply v1 v2 = some v) :
    HasTypeV v T := by
  cases op <;> cases T1 <;> cases T2 <;> simp [BinOp.typeOf] at hOp <;>
    (try (cases hOp; cases hV1; cases hV2; simp [BinOp.apply] at hApp; cases hApp; constructor))

/-! ## Preservation. -/

theorem preservation :
    ∀ {env e v env'} (_D : BigStep env e v env')
      {Γ T} (_hT : HasType Γ e T) (_hE : HasTypeEnv env Γ),
      HasTypeV v T ∧ HasTypeEnv env' Γ := by
  intros env e v env' D
  induction D with
  | unitR =>
    intros Γ T hT hE; cases hT; exact ⟨.vUnit, hE⟩
  | intLitR n =>
    intros Γ T hT hE; cases hT; exact ⟨.vInt n, hE⟩
  | boolLitR b =>
    intros Γ T hT hE; cases hT; exact ⟨.vBool b, hE⟩
  | varR hLook =>
    intros Γ T hT hE
    cases hT with
    | var hLookT =>
      have ⟨v', hLook', hTV⟩ := hE _ _ hLookT
      rw [hLook] at hLook'; cases hLook'
      exact ⟨hTV, hE⟩
  | lamR x body =>
    intros Γ T hT hE
    cases hT with
    | lam hBody => exact ⟨HasTypeV.vClos_of_env hE hBody, hE⟩
  | appR _ _ _ ih1 ih2 ihb =>
    intros Γ T hT hE
    cases hT with
    | app hT1 hT2 =>
      have ⟨hClosT, hE1⟩ := ih1 hT1 hE
      have ⟨hArgT, hE2⟩ := ih2 hT2 hE1
      have ⟨_, _, _, hArrow, hE_clos, hBody⟩ := hClosT.vClos_to_env
      cases hArrow
      have ⟨hValT, _⟩ := ihb hBody (hE_clos.extend_letIn hArgT)
      exact ⟨hValT, hE2⟩
  | letInR _ _ ih1 ih2 =>
    intros Γ T hT hE
    cases hT with
    | letIn hT1 hT2 =>
      have ⟨hV1, hE1⟩ := ih1 hT1 hE
      have ⟨hV2, _⟩ := ih2 hT2 (hE1.extend_letIn hV1)
      exact ⟨hV2, hE1⟩
  | ifTR _ _ ihc iht =>
    intros Γ T hT hE
    cases hT with
    | ifte hTc hT1 _ =>
      have ⟨_, hE1⟩ := ihc hTc hE
      exact iht hT1 hE1
  | ifFR _ _ ihc ihf =>
    intros Γ T hT hE
    cases hT with
    | ifte hTc _ hT2 =>
      have ⟨_, hE1⟩ := ihc hTc hE
      exact ihf hT2 hE1
  | binopR _ _ Hop ih1 ih2 =>
    intros Γ T hT hE
    cases hT with
    | binop hT1 hT2 hOpT =>
      have ⟨hV1, hE1⟩ := ih1 hT1 hE
      have ⟨hV2, hE2⟩ := ih2 hT2 hE1
      exact ⟨binop_apply_sound hOpT hV1 hV2 Hop, hE2⟩
  | seqR _ _ ih1 ih2 =>
    intros Γ T hT hE
    cases hT with
    | seq hT1 hT2 =>
      have ⟨_, hE1⟩ := ih1 hT1 hE
      exact ih2 hT2 hE1
  | assignR _ ih =>
    intros Γ T hT hE
    cases hT with
    | assign hx hT1 =>
      have ⟨hV, hE1⟩ := ih hT1 hE
      exact ⟨.vUnit, hE1.extend_typed hx hV⟩
  | whileFR _ ihc =>
    intros Γ T hT hE
    cases hT with
    | whileT hTc _ =>
      have ⟨_, hE1⟩ := ihc hTc hE
      exact ⟨.vUnit, hE1⟩
  | whileTR _ _ _ ihc ihb ihw =>
    intros Γ T hT hE
    cases hT with
    | whileT hTc hTb =>
      have ⟨_, hE1⟩ := ihc hTc hE
      have ⟨_, hE2⟩ := ihb hTb hE1
      -- Reconstruct typing for the recursive while step.
      exact ihw (HasType.whileT hTc hTb) hE2

end OctiveLean.Core
