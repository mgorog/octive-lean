/-!
# Foundation.Surface — Octave syntax as data.

The Surface AST is what a parser (or the `octave! { … }` DSL) produces.
It mirrors Octave's surface forms one-for-one — control flow keywords,
matrix literals, indexing/field access, multi-clause `if`/`elseif`/`else`,
loops, function definitions, etc.  Every surface constructor exists
for a *syntactic* reason; the *meaning* of each is given by the
homomorphism `Foundation.Compile.compile : Surface → Core`.

Design rules:

  1. **Surface is data.**  No parser combinators here, no Lean
     `syntax` declarations — those are the *front end*, and they
     produce values of these types.
  2. **No partial constructors.**  Every variant is constructible
     and pattern-matchable.  No raw `Syntax` smuggled through.
  3. **Compile is one case per constructor.**  Adding a surface
     form means adding one constructor here and one case in
     `Compile`.  Nothing else changes.
  4. **Modality is explicit.**  A statement carries `Display`
     (silent / echo / disp), so `;` vs newline is data, not a `Bool`
     tagged onto exprs.
-/

namespace OctiveLean.Foundation

/-! ## Operators.  Kept as data so `Compile` can pick which primop
    they resolve to.  These names are stable across surface and
    runtime; no string-rewriting in between. -/

inductive BinOp where
  | add | sub | mul | div | pow
  | emul | ediv | epow            -- elementwise
  | lt | le | gt | ge | eq | ne
  | land | lor | band | bor
  deriving Repr, BEq, Inhabited

inductive UnOp where
  | neg | not | transpose | htranspose
  deriving Repr, BEq, Inhabited

/-! ## Display modality.  A statement either suppresses its value
    (`Silent`, trailing `;`), echoes name + value (`Echo`, the
    default), or wraps in `disp` (`Disp`, explicit). -/

inductive Display where
  | silent | echo | disp
  deriving Repr, BEq, Inhabited

/-! ## Indexing arguments.  An index can be an expression (`1`,
    `i+1`), a colon meaning "all of this axis" (`:`), or `end`
    meaning "the last index of this axis". -/

mutual
  inductive Expr where
    | num    : Float → Expr
    | str    : String → Expr
    | bool   : Bool → Expr
    | id     : String → Expr
    /-- `e₁ ⊕ e₂` for `⊕ : BinOp`. -/
    | binop  : BinOp → Expr → Expr → Expr
    /-- `⊝ e` for `⊝ : UnOp`. -/
    | unop   : UnOp → Expr → Expr
    /-- `f(a₁, …, aₙ)` — covers both function call and indexing,
        since Octave conflates them. -/
    | call   : Expr → List IdxArg → Expr
    /-- `obj.field`. -/
    | field  : Expr → String → Expr
    /-- `[…rows…]` — matrix literal. -/
    | matrix : List (List Expr) → Expr
    /-- `{…rows…}` — cell array literal. -/
    | cell   : List (List Expr) → Expr
    /-- `a:b` or `a:s:b`. The middle component is the step. -/
    | range  : Expr → Option Expr → Expr → Expr
    /-- `@name` — function handle. -/
    | handle : String → Expr
    /-- `@(p₁, …) body` — anonymous function. -/
    | anon   : List String → Expr → Expr
    deriving Repr, Inhabited

  inductive IdxArg where
    | arg   : Expr → IdxArg
    | colon : IdxArg
    | endIx : IdxArg
    deriving Repr, Inhabited
end

/-! ## Statements.  A statement is what appears between `;`/newlines
    in an Octave script body.  All forms are surface-only and
    desugared into Core by `Compile`. -/

mutual
  inductive Stmt where
    /-- Expression-as-statement, with display modality. -/
    | exprS  : Expr → Display → Stmt
    /-- Assignment.  LHS is itself an `Expr` (an id, index, or field
        chain); the compiler refuses anything else. -/
    | assign : Expr → Expr → Display → Stmt
    /-- Multi-return assignment `[a, b, c] = f(…)`. -/
    | massign : List String → Expr → Display → Stmt
    | ifS    : Expr → List Stmt → List (Expr × List Stmt) → Option (List Stmt) → Stmt
    | forS   : String → Expr → List Stmt → Stmt
    | whileS : Expr → List Stmt → Stmt
    | switchS : Expr → List (Expr × List Stmt) → Option (List Stmt) → Stmt
    | tryS   : List Stmt → Option (String × List Stmt) → Stmt
    | funDef : FunDef → Stmt
    | retS    : Stmt
    | breakS  : Stmt
    | contS   : Stmt
    | globalS : List String → Stmt
    | clearS  : List String → Stmt
    deriving Repr, Inhabited

  /-- Function definition.  `outs = name(ins) body`. -/
  structure FunDef where
    name : String
    ins  : List String
    outs : List String
    body : List Stmt
    deriving Repr, Inhabited
end

/-- A program is a list of statements at the top level. -/
abbrev Program := List Stmt

end OctiveLean.Foundation
