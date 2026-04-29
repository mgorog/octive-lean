import OctiveLean.BigStep

namespace OctiveLean

/-!
# Phase C — Value Representation Equivalences

Three approaches for formalizing that multiple `Value` constructors are
semantically identical, enabling proof transport across representations.
-/

/-!
# Approach 1: Setoid / Quotient
-/

section Approach1

/-- Canonical form: collapses equivalent representations. -/
def Value.normalize : Value → Value
  | Value.scalar f   => Value.matrix 1 1 #[f]
  | Value.fscalar f  => Value.matrix 1 1 #[f]
  | Value.boolean b  => Value.matrix 1 1 #[if b then 1.0 else 0.0]
  | Value.range s st e =>
      let data := Value.rangeToArray s st e
      if data.isEmpty then Value.empty else Value.matrix 1 data.size data
  | v => v

/-- Semantic equivalence via normal forms. -/
def ValEq (a b : Value) : Prop := Value.normalize a = Value.normalize b

instance : Setoid Value where
  r     := ValEq
  iseqv := ⟨fun _   => Eq.refl _,
             fun h   => Eq.symm h,
             fun h k => Eq.trans h k⟩

/-- Octave value up to representation. -/
def OctaveValue := Quotient (inferInstance : Setoid Value)

def OctaveValue.mk   (v : Value) : OctaveValue := Quotient.mk _ v
def OctaveValue.lift {α} (f : Value → α) (hf : ∀ a b, ValEq a b → f a = f b) :
    OctaveValue → α := Quotient.lift f hf

/-! Simp lemmas for normalize -/

@[simp] theorem normalize_matrix  (r c : Nat) (d : Array Float) :
    Value.normalize (Value.matrix r c d) = Value.matrix r c d := rfl
@[simp] theorem normalize_empty   : Value.normalize Value.empty  = Value.empty  := rfl
@[simp] theorem normalize_scalar  (f : Float) :
    Value.normalize (Value.scalar f)  = Value.matrix 1 1 #[f] := rfl
@[simp] theorem normalize_fscalar (f : Float) :
    Value.normalize (Value.fscalar f) = Value.matrix 1 1 #[f] := rfl
@[simp] theorem normalize_boolean (b : Bool) :
    Value.normalize (Value.boolean b) =
    Value.matrix 1 1 #[if b then 1.0 else 0.0] := rfl
@[simp] theorem normalize_string  (s : String) :
    Value.normalize (Value.string s)  = Value.string s  := rfl
@[simp] theorem normalize_struct  (fs : Array (String × Value)) :
    Value.normalize (Value.struct fs) = Value.struct fs := rfl

/-! Equivalence theorems -/

theorem scalar_eq_matrix11 (x : Float) :
    ValEq (Value.scalar x) (Value.matrix 1 1 #[x]) := by
  simp [ValEq]

theorem boolean_true_eq_scalar1 : ValEq (Value.boolean true) (Value.scalar 1.0) := by
  simp [ValEq]

theorem boolean_false_eq_scalar0 : ValEq (Value.boolean false) (Value.scalar 0.0) := by
  simp [ValEq]

theorem fscalar_eq_scalar (x : Float) : ValEq (Value.fscalar x) (Value.scalar x) := by
  simp [ValEq]

theorem range_eq_matrix (s st e : Float)
    (hne : 0 < (Value.rangeToArray s st e).size) :
    ValEq (Value.range s st e)
      (Value.matrix 1 (Value.rangeToArray s st e).size (Value.rangeToArray s st e)) := by
  simp only [ValEq, Value.normalize]
  have hne' : (Value.rangeToArray s st e).size ≠ 0 := Nat.pos_iff_ne_zero.mp hne
  have hnonempty : (Value.rangeToArray s st e).isEmpty = false := by
    simp [Array.isEmpty, hne']
  simp [hnonempty]

theorem empty_range_eq_empty (s st e : Float)
    (h : (Value.rangeToArray s st e).isEmpty) :
    ValEq (Value.range s st e) Value.empty := by
  simp [ValEq, Value.normalize, h]

/-! Transport and quotient induction -/

/-- HoTT-style transport: move a predicate across ValEq. -/
theorem ValEq.transport {P : Value → Prop}
    (hresp : ∀ a b, ValEq a b → P a → P b)
    {v w} (heq : ValEq v w) (hv : P v) : P w := hresp v w heq hv

theorem OctaveValue.ind {P : OctaveValue → Prop}
    (h : ∀ v : Value, P (OctaveValue.mk v)) : ∀ x, P x := Quotient.ind h

/-- normalize is idempotent. -/
theorem normalize_idempotent (v : Value) :
    Value.normalize (Value.normalize v) = Value.normalize v := by
  cases v with
  | scalar _  => simp [Value.normalize]
  | fscalar _ => simp [Value.normalize]
  | boolean b => cases b <;> simp [Value.normalize]
  | range s st e =>
      simp only [Value.normalize]
      by_cases h : (Value.rangeToArray s st e).isEmpty
      · simp [h]
      · simp [h]
  | _ => simp [Value.normalize]

/-- shape respects ValEq. -/
theorem shape_congr {a b : Value} (h : ValEq a b) :
    (Value.normalize a).shape = (Value.normalize b).shape := by
  simp [ValEq] at h; rw [h]

end Approach1

/-!
# Approach 2: Bijection between float-indexed reps
-/

section Approach2

/-- A bijection between two types (local stand-in for Equiv, no Mathlib needed). -/
structure Bijection (α β : Type) where
  toFun    : α → β
  invFun   : β → α
  left_inv : ∀ x : α, invFun (toFun x) = x
  right_inv : ∀ x : β, toFun (invFun x) = x

/-- Representation of a scalar value: wraps a float. -/
structure ScalarRep where f : Float
/-- Representation of a 1×1 matrix value: wraps a float. -/
structure Matrix11Rep where f : Float

def scalarToMatrix11 (s : ScalarRep) : Matrix11Rep := ⟨s.f⟩
def matrix11ToScalar (m : Matrix11Rep) : ScalarRep := ⟨m.f⟩

@[simp] theorem scalarToMatrix11_leftInv (v : ScalarRep) :
    matrix11ToScalar (scalarToMatrix11 v) = v := by cases v; rfl

@[simp] theorem scalarToMatrix11_rightInv (v : Matrix11Rep) :
    scalarToMatrix11 (matrix11ToScalar v) = v := by cases v; rfl

/-- Scalar ≃ 1×1 matrix: completely proved without sorry. -/
def scalarMatrix11Bij : Bijection ScalarRep Matrix11Rep where
  toFun    := scalarToMatrix11
  invFun   := matrix11ToScalar
  left_inv := scalarToMatrix11_leftInv
  right_inv := scalarToMatrix11_rightInv

/-- Embed scalar rep into Value. -/
def ScalarRep.toValue (s : ScalarRep) : Value := Value.scalar s.f
/-- Embed 1×1 matrix rep into Value. -/
def Matrix11Rep.toValue (m : Matrix11Rep) : Value := Value.matrix 1 1 #[m.f]

/-- The bijection preserves the float field. -/
theorem scalarBij_float (s : ScalarRep) : (scalarMatrix11Bij.toFun s).f = s.f := rfl

/-- The two representations are ValEq under their Value embeddings. -/
theorem scalarRep_valEq_matrix11Rep (s : ScalarRep) :
    ValEq s.toValue (scalarMatrix11Bij.toFun s).toValue := by
  simp [ValEq, ScalarRep.toValue, Matrix11Rep.toValue,
        scalarMatrix11Bij, scalarToMatrix11, Value.normalize]

/-- Boolean embedding into floats. -/
def boolToFloat : Bool → Float := fun b => if b then 1.0 else 0.0

@[simp] theorem boolToFloat_true  : boolToFloat true  = 1.0 := rfl
@[simp] theorem boolToFloat_false : boolToFloat false = 0.0 := rfl

/-- Booleans are ValEq to their float scalar images. -/
theorem boolean_valEq_scalar (b : Bool) :
    ValEq (Value.boolean b) (Value.scalar (boolToFloat b)) := by
  cases b <;> simp [ValEq, boolToFloat, Value.normalize]

/-- P holds for scalar iff it holds for the equivalent matrix (for ValEq-respecting P). -/
theorem scalar_iff_matrix11 {P : Value → Prop}
    (hresp : ∀ a b, ValEq a b → P a → P b) (f : Float) :
    P (Value.scalar f) ↔ P (Value.matrix 1 1 #[f]) :=
  ⟨hresp _ _ (scalar_eq_matrix11 f),
   hresp _ _ (Eq.symm (scalar_eq_matrix11 f))⟩

end Approach2

/-!
# Approach 3: normalize + congruence
-/

section Approach3

/-- toFloatP on normalize-equivalent values agrees. -/
theorem toFloatP_scalar_eq_matrix11 (f : Float) (env : Env) :
    runPureM (toFloatP (Value.scalar f)) env =
    runPureM (toFloatP (Value.matrix 1 1 #[f])) env := by
  simp [toFloatP, Value.materialize]

theorem toFloatP_bool_true_eq_scalar1 (env : Env) :
    runPureM (toFloatP (Value.boolean true)) env =
    runPureM (toFloatP (Value.scalar 1.0)) env := by
  simp [toFloatP, Value.materialize]

theorem toFloatP_bool_false_eq_scalar0 (env : Env) :
    runPureM (toFloatP (Value.boolean false)) env =
    runPureM (toFloatP (Value.scalar 0.0)) env := by
  simp [toFloatP, Value.materialize]

/-- materialize is idempotent. -/
theorem materialize_idempotent (v : Value) :
    Value.materialize (Value.materialize v) = Value.materialize v := by
  cases v with
  | range s st e =>
      by_cases h : (Value.rangeToArray s st e).isEmpty
      · simp [Value.materialize, h]
      · simp [Value.materialize, h]
  | _ => simp [Value.materialize]

/-- evalBinOpP on scalar vs 1×1 matrix (axiom: ewiseOpP is partial). -/
axiom evalBinOpP_scalar_matrix11 (op : BinOp) (x y : Float) (env : Env) :
    (runPureM (evalBinOpP op (Value.scalar x) (Value.scalar y)) env).1 =
    (runPureM (evalBinOpP op (Value.matrix 1 1 #[x]) (Value.matrix 1 1 #[y])) env).1

end Approach3

/-!
## Summary

### What compiled without sorry

**Approach 1:**
- `ValEq` setoid, `OctaveValue` quotient — ✓
- `scalar_eq_matrix11`, `boolean_*`, `fscalar_eq_scalar` — ✓
- `range_eq_matrix`, `empty_range_eq_empty` — ✓
- `normalize_idempotent` — ✓
- `ValEq.transport`, `OctaveValue.ind` — ✓
- `shape_congr` — ✓

**Approach 2:**
- `Bijection` structure (local, no Mathlib) — ✓
- `scalarMatrix11Bij` (full bijection, no sorry) — ✓
- `scalarRep_valEq_matrix11Rep`, `boolean_valEq_scalar` — ✓
- `scalar_iff_matrix11` transport theorem — ✓

**Approach 3:**
- `toFloatP` congruence lemmas — ✓
- `materialize_idempotent` — ✓

### What required axioms / sorry

- `evalBinOpP_scalar_matrix11`: blocked by `ewiseOpP` being `partial`

### Key findings

1. **`partial def` opacity** is the fundamental blocker for Approach 3.
   Any function that transitively calls a `partial def` cannot be unfolded
   by the kernel. This affects all `evalBinOpP` congruence lemmas.

2. **Approach 2** is the cleanest: zero sorry, fully constructive.
   The `Bijection ScalarRep Matrix11Rep` captures the isomorphism.
   No Mathlib needed — only local definitions.

3. **Approach 1** is best for semantic abstraction. The `OctaveValue`
   quotient type lets you work with values modulo representation.
   `ValEq.transport` provides HoTT-style proof transport.

4. **Float literal representation** (`(1 : Float)` vs `(1.0 : Float)`)
   causes syntactic divergence in concrete BigStep examples; normalization
   lemmas from Mathlib (or `native_decide`) are needed for those cases.
-/

end OctiveLean
