namespace OctiveLean.Core

/-! # Tiny Octave Core (TOC) — abstract syntax.

Parallel to golang-lean's TGC. Shared kernel: ten constructors covering
λ-calculus core + conditionals + sequencing. Octave-specific extensions:
`assign` (variable mutation in the env) and `whileT` (loop until false).

What is *not* here: matrices, cell arrays, ranges, anonymous-function
captures with `@(x) expr` syntax, `printf`-family builtins. Those are
desugaring targets for the surface-Octave→TOC translator (later). -/

inductive BinOp where
  | add | sub | mul
  | eq  | lt
  deriving Repr, BEq, DecidableEq, Inhabited

inductive Term where
  | unitT   : Term
  | intLit  : Int  → Term
  | boolLit : Bool → Term
  | var     : String → Term
  | lam     : String → Term → Term            -- λ x. e
  | app     : Term → Term → Term
  | letIn   : String → Term → Term → Term     -- let x = e₁ in e₂  (lexical)
  | ifte    : Term → Term → Term → Term
  | binop   : BinOp → Term → Term → Term
  | seq     : Term → Term → Term
  | assign  : String → Term → Term            -- x = e   (mutates env)
  | whileT  : Term → Term → Term              -- while c do b
  deriving Repr, Inhabited

end OctiveLean.Core
