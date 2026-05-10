import OctiveLean.Core.Semantics

namespace OctiveLean.Core

/-! # Determinism of TOC big-step.

  `BigStep env e v₁ env₁ → BigStep env e v₂ env₂ → v₁ = v₂ ∧ env₁ = env₂`

Proof structure mirrors TGC's `Determinism` line-for-line on the shared
ten constructors. Octave-specific cases (`assign`, `whileT`) follow the
same three patterns: terminal, structural-functional, contradiction-collapse.

The `whileFR`/`whileTR` cross-case is closed exactly like `ifTR`/`ifFR`:
the IH on the condition produces `vBool true = vBool false`, dispatched
by `Bool.noConfusion`. -/

theorem BigStep.deterministic
    {env : Env} {e : Term} {v₁ v₂ : Value} {env₁ env₂ : Env}
    (D₁ : BigStep env e v₁ env₁) (D₂ : BigStep env e v₂ env₂) :
    v₁ = v₂ ∧ env₁ = env₂ := by
  induction D₁ generalizing v₂ env₂ with
  | unitR => cases D₂; exact ⟨rfl, rfl⟩
  | intLitR n => cases D₂; exact ⟨rfl, rfl⟩
  | boolLitR b => cases D₂; exact ⟨rfl, rfl⟩
  | varR hLook =>
    cases D₂ with
    | varR hLook' =>
      have heq := hLook.symm.trans hLook'
      exact ⟨Option.some.inj heq, rfl⟩
  | lamR x body => cases D₂; exact ⟨rfl, rfl⟩
  | appR _ _ _ ih1 ih2 ihb =>
    cases D₂ with
    | appR D1' D2' Db' =>
      have ⟨hClos, hE1⟩ := ih1 D1'
      injection hClos with hx hbody henv
      subst hx; subst hbody; subst henv; subst hE1
      have ⟨hArg, hE2⟩ := ih2 D2'
      subst hArg; subst hE2
      have ⟨hv, _⟩ := ihb Db'
      exact ⟨hv, rfl⟩
  | letInR _ _ ih1 ih2 =>
    cases D₂ with
    | letInR D1' D2' =>
      have ⟨hv1, hE1⟩ := ih1 D1'
      subst hv1; subst hE1
      exact ih2 D2'
  | ifTR _ _ ihc iht =>
    cases D₂ with
    | ifTR Dc' Dt' =>
      have ⟨_, hE1⟩ := ihc Dc'; subst hE1
      exact iht Dt'
    | ifFR Dc' _ =>
      have ⟨hb, _⟩ := ihc Dc'
      injection hb with hb_eq
      exact Bool.noConfusion hb_eq
  | ifFR _ _ ihc ihf =>
    cases D₂ with
    | ifTR Dc' _ =>
      have ⟨hb, _⟩ := ihc Dc'
      injection hb with hb_eq
      exact Bool.noConfusion hb_eq
    | ifFR Dc' Df' =>
      have ⟨_, hE1⟩ := ihc Dc'; subst hE1
      exact ihf Df'
  | binopR _ _ Hop ih1 ih2 =>
    cases D₂ with
    | binopR D1' D2' Hop' =>
      have ⟨hv1, hE1⟩ := ih1 D1'
      subst hv1; subst hE1
      have ⟨hv2, hE2⟩ := ih2 D2'
      subst hv2; subst hE2
      have heq := Hop.symm.trans Hop'
      exact ⟨Option.some.inj heq, rfl⟩
  | seqR _ _ ih1 ih2 =>
    cases D₂ with
    | seqR D1' D2' =>
      have ⟨_, hE1⟩ := ih1 D1'; subst hE1
      exact ih2 D2'
  | assignR _ ih =>
    cases D₂ with
    | assignR D' =>
      have ⟨hv, hE⟩ := ih D'
      subst hv; subst hE
      exact ⟨rfl, rfl⟩
  | whileFR _ ihc =>
    cases D₂ with
    | whileFR Dc' =>
      have ⟨_, hE⟩ := ihc Dc'; subst hE
      exact ⟨rfl, rfl⟩
    | whileTR Dc' _ _ =>
      have ⟨hb, _⟩ := ihc Dc'
      injection hb with hb_eq
      exact Bool.noConfusion hb_eq
  | whileTR _ _ _ ihc ihb ihw =>
    cases D₂ with
    | whileFR Dc' =>
      have ⟨hb, _⟩ := ihc Dc'
      injection hb with hb_eq
      exact Bool.noConfusion hb_eq
    | whileTR Dc' Db' Dw' =>
      have ⟨_, hE1⟩ := ihc Dc'; subst hE1
      have ⟨_, hE2⟩ := ihb Db'; subst hE2
      exact ihw Dw'

end OctiveLean.Core
