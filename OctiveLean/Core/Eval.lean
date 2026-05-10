import OctiveLean.Core.Semantics

namespace OctiveLean.Core

/-! # Executable evaluator and soundness for TOC.

Fuel-bounded recursive evaluator
  `eval : Nat → Env → Term → Option (Value × Env)`
together with
  `eval_sound : eval n env e = some (v, env') → BigStep env e v env'`.

Function-call semantics: the body's post-env is *discarded* — only the
arg-evaluation env propagates outward. This matches Octave/MATLAB scoping
where mutations inside a function do not leak.

`whileT` recursion uses one fuel step per iteration. A run that uses `n`
fuel covers up to `n` iterations of the loop. -/

def eval : Nat → Env → Term → Option (Value × Env)
  | 0,     _,   _              => none
  | _ + 1, env, .unitT         => some (.vUnit, env)
  | _ + 1, env, .intLit k      => some (.vInt k, env)
  | _ + 1, env, .boolLit b     => some (.vBool b, env)
  | _ + 1, env, .var x         =>
      match env.lookup x with
      | some v => some (v, env)
      | none   => none
  | _ + 1, env, .lam x body    => some (.vClos x body env, env)
  | n + 1, env, .app e1 e2     =>
      match eval n env e1 with
      | some (.vClos x body env_clos, env1) =>
          match eval n env1 e2 with
          | some (v_arg, env2) =>
              match eval n (env_clos.extend x v_arg) body with
              | some (v, _) => some (v, env2)
              | none        => none
          | none => none
      | _ => none
  | n + 1, env, .letIn x e1 e2 =>
      match eval n env e1 with
      | some (v1, env1) => eval n (env1.extend x v1) e2
      | none            => none
  | n + 1, env, .ifte ec e1 e2 =>
      match eval n env ec with
      | some (.vBool true,  env1) => eval n env1 e1
      | some (.vBool false, env1) => eval n env1 e2
      | _                         => none
  | n + 1, env, .binop op e1 e2 =>
      match eval n env e1 with
      | some (v1, env1) =>
          match eval n env1 e2 with
          | some (v2, env2) =>
              match op.apply v1 v2 with
              | some v => some (v, env2)
              | none   => none
          | none => none
      | none => none
  | n + 1, env, .seq e1 e2     =>
      match eval n env e1 with
      | some (_, env1) => eval n env1 e2
      | none           => none
  | n + 1, env, .assign x e    =>
      match eval n env e with
      | some (v, env1) => some (.vUnit, env1.extend x v)
      | none           => none
  | n + 1, env, .whileT c b    =>
      match eval n env c with
      | some (.vBool true, env1) =>
          match eval n env1 b with
          | some (_, env2) => eval n env2 (.whileT c b)
          | none           => none
      | some (.vBool false, env1) => some (.vUnit, env1)
      | _                         => none

theorem eval_sound :
    ∀ (n : Nat) (env : Env) (e : Term) (v : Value) (env' : Env),
      eval n env e = some (v, env') → BigStep env e v env' := by
  intro n
  induction n with
  | zero => intro env e v env' heq; simp [eval] at heq
  | succ n ih =>
    intro env e v env' heq
    cases e with
    | unitT =>
      simp [eval] at heq; obtain ⟨rfl, rfl⟩ := heq; exact .unitR
    | intLit k =>
      simp [eval] at heq; obtain ⟨rfl, rfl⟩ := heq; exact .intLitR k
    | boolLit b =>
      simp [eval] at heq; obtain ⟨rfl, rfl⟩ := heq; exact .boolLitR b
    | var x =>
      simp only [eval] at heq
      split at heq
      next vv hL =>
        simp at heq; obtain ⟨rfl, rfl⟩ := heq
        exact .varR hL
      next => simp at heq
    | lam x body =>
      simp [eval] at heq; obtain ⟨rfl, rfl⟩ := heq; exact .lamR x body
    | app e1 e2 =>
      simp only [eval] at heq
      split at heq
      next x body env_clos env1 heq1 =>
        split at heq
        next v_arg env2 heq2 =>
          split at heq
          next v_body _ heqb =>
            simp at heq; obtain ⟨rfl, rfl⟩ := heq
            exact .appR (ih _ _ _ _ heq1) (ih _ _ _ _ heq2) (ih _ _ _ _ heqb)
          next => simp at heq
        next => simp at heq
      all_goals simp at heq
    | letIn x e1 e2 =>
      simp only [eval] at heq
      split at heq
      next v1 env1 heq1 =>
        exact .letInR (ih _ _ _ _ heq1) (ih _ _ _ _ heq)
      next => simp at heq
    | ifte ec e1 e2 =>
      simp only [eval] at heq
      split at heq
      next env1 heq1 => exact .ifTR (ih _ _ _ _ heq1) (ih _ _ _ _ heq)
      next env1 heq1 => exact .ifFR (ih _ _ _ _ heq1) (ih _ _ _ _ heq)
      all_goals simp at heq
    | binop op e1 e2 =>
      simp only [eval] at heq
      split at heq
      next v1 env1 heq1 =>
        split at heq
        next v2 env2 heq2 =>
          split at heq
          next vv heqop =>
            simp at heq; obtain ⟨rfl, rfl⟩ := heq
            exact .binopR (ih _ _ _ _ heq1) (ih _ _ _ _ heq2) heqop
          next => simp at heq
        next => simp at heq
      next => simp at heq
    | seq e1 e2 =>
      simp only [eval] at heq
      split at heq
      next _ env1 heq1 =>
        exact .seqR (ih _ _ _ _ heq1) (ih _ _ _ _ heq)
      next => simp at heq
    | assign x e =>
      simp only [eval] at heq
      split at heq
      next vv env1 heq1 =>
        simp at heq; obtain ⟨rfl, rfl⟩ := heq
        exact .assignR (ih _ _ _ _ heq1)
      next => simp at heq
    | whileT c b =>
      simp only [eval] at heq
      split at heq
      next env1 heq1 =>
        split at heq
        next _ env2 heq2 =>
          have hbs_rec := ih _ _ _ _ heq
          have hv_unit : v = .vUnit := by cases hbs_rec <;> rfl
          subst hv_unit
          exact .whileTR (ih _ _ _ _ heq1) (ih _ _ _ _ heq2) hbs_rec
        next => simp at heq
      next env1 heq1 =>
        simp at heq; obtain ⟨rfl, rfl⟩ := heq
        exact .whileFR (ih _ _ _ _ heq1)
      all_goals simp at heq

end OctiveLean.Core
