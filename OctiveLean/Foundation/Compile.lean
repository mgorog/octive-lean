import OctiveLean.Foundation.Core
import OctiveLean.Foundation.Surface

/-!
# Foundation.Compile — `Surface → Core` as a homomorphism.

This file is the *only* place where surface conveniences are turned
into Core meaning.  Every surface constructor has exactly one case
here.  Every case is a small, mechanical lowering; each carries a
comment stating what semantic invariant it preserves.

When we later prove `eval (compile s) ≈ surfaceSemantics s`, the
proof obligation is one case per constructor.  No exceptions, no
"see also …", no special-cased rewrites.
-/

namespace OctiveLean.Foundation
namespace Compile

open Core

/-- BinOps lower to calls to primops in the initial environment.
    The primop names are *the literal source-level name* of the
    operator — `"+"`, `".*"`, `"=="`, etc.  No clash with user
    identifiers since user names must start with a letter or `_`. -/
def binopPrim : BinOp → String
  | .add => "+"  | .sub => "-"  | .mul => "*"  | .div => "/"  | .pow => "^"
  | .emul => ".*" | .ediv => "./" | .epow => ".^"
  | .lt => "<" | .le => "<=" | .gt => ">" | .ge => ">=" | .eq => "==" | .ne => "!="
  | .land => "&&" | .lor => "||" | .band => "&" | .bor => "|"

def unopPrim : UnOp → String
  | .neg => "-_" | .not => "!" | .transpose => ".'" | .htranspose => "'"

/-- Range-literal primop name. `a:b` is `range(a, b)`; `a:s:b` is
    `range(a, s, b)`. -/
def rangePrim : String := "range"

/-! ## Compilation of expressions, indices, and statements.

These are mutually recursive following the Surface AST. -/

mutual
  partial def compileExpr : Expr → Core
    -- Atoms.  String / bool literals lower to calls of primitive
    -- coercion functions, since `Core.Lit` only carries floats.
    | .num n     => .lit (.float n)
    | .str s     => .lit (.str s)
    | .bool b    => .lit (.bool b)
    | .id x      => .var x
    -- Operators.  Each is `app (var "<primop>") [compile e₁, compile e₂]`.
    -- Invariant: evaluating the result reduces to evaluating the
    -- primop with the operand values, which equals the surface meaning.
    | .binop op a b =>
        .app (.var (binopPrim op)) [compileExpr a, compileExpr b]
    | .unop op a =>
        .app (.var (unopPrim op)) [compileExpr a]
    -- Function call / indexing.  Conflated in surface and Core.
    -- Indices like `:` and `end` lower to literal sentinel calls
    -- the primop interprets.
    | .call f args =>
        .app (compileExpr f) (args.map compileIdx)
    | .field obj name =>
        -- `obj.field` is `field(obj, "field")` in Core.
        .app (.var "field") [compileExpr obj, .lit (.str name)]
    | .matrix rows =>
        -- `[r₁; r₂; …]` is `matrix([row(c₁,c₂,…), row(…), …])`.
        let rowCores := rows.map (fun row => .app (.var "row") (row.map compileExpr))
        .app (.var "matrix") rowCores
    | .cell rows =>
        let rowCores := rows.map (fun row => .app (.var "cellrow") (row.map compileExpr))
        .app (.var "cell") rowCores
    | .range a none b =>
        .app (.var rangePrim) [compileExpr a, compileExpr b]
    | .range a (some s) b =>
        .app (.var rangePrim) [compileExpr a, compileExpr s, compileExpr b]
    | .handle name =>
        .app (.var "handle") [.var name]
    | .anon ps body =>
        .lam ps (compileExpr body)

  /-- Index arguments lower to ordinary expressions, with `:` and
      `end` becoming calls to sentinel primops. -/
  partial def compileIdx : IdxArg → Core
    | .arg e   => compileExpr e
    | .colon   => .app (.var "colon") []
    | .endIx   => .app (.var "end") []

  /-- Statement lowering.  Display modality is folded into a wrapper
      call: `disp(e)`, `echo(e)`, or the bare value (silent). -/
  partial def compileStmt : Stmt → Core
    | .exprS e .silent =>
        compileExpr e
    | .exprS e .echo =>
        -- Echo prints the value with its expression-source name.
        -- We lower to `echo(value)`; the env-bound `echo` primop
        -- handles formatting.
        .app (.var "echo") [compileExpr e]
    | .exprS e .disp =>
        .app (.var "disp") [compileExpr e]
    | .assign lhs rhs dpy =>
        -- The LHS is either an `id` (simple), `call id args`
        -- (index assign), or `field e name` (field assign).  Each
        -- lowers to a distinct primop so the evaluator can do the
        -- right thing without inspecting Core shape.
        match lhs with
        | .id x =>
            -- Simple assignment: bind `x` in the env, then run the
            -- display-modal statement form on the new binding.
            .seq (.app (.var "bind") [.lit (.str x), compileExpr rhs])
                 (compileStmt (.exprS lhs dpy))
        | .call f args =>
            .app (.var "indexAssign") (compileExpr f :: args.map compileIdx ++ [compileExpr rhs])
        | .field obj name =>
            .app (.var "fieldAssign") [compileExpr obj, .lit (.str name), compileExpr rhs]
        | _ =>
            .app (.var "fail") [.lit (.str "unsupported LHS")]
    | .massign names rhs _ =>
        .app (.var "multiAssign")
             (compileExpr rhs :: names.map (fun n => .lit (.str n)))
    | .ifS cond thenB elifs elseB =>
        compileIf cond thenB elifs elseB
    | .forS i range body =>
        -- `for i = range; body; end` is `iterate(range, λi.body)`.
        .app (.var "iterate")
             [compileExpr range,
              .lam [i] (compileStmts body)]
    | .whileS cond body =>
        .app (.var "loop") [.lam [] (compileExpr cond), .lam [] (compileStmts body)]
    | .switchS val cases other =>
        -- Switch lowers to nested ifte on equality with each case.
        let mkChain : List (Expr × List Stmt) → Option (List Stmt) → Core := fun cs ot =>
          let otCore := match ot with
            | none => .app (.var "noop") []
            | some ss => compileStmts ss
          cs.foldr (fun (cv, body) acc =>
            .ifte (.app (.var "==") [compileExpr val, compileExpr cv])
                  (compileStmts body) acc) otCore
        mkChain cases other
    | .tryS tryB catchB =>
        .app (.var "tryCatch")
             [.lam [] (compileStmts tryB),
              match catchB with
              | none => .lam ["_"] (.app (.var "noop") [])
              | some (e, ss) => .lam [e] (compileStmts ss)]
    | .funDef fd =>
        .app (.var "bind") [.lit (.str fd.name), .lam fd.ins (compileStmts fd.body)]
    | .retS    => .app (.var "return") []
    | .breakS  => .app (.var "break") []
    | .contS   => .app (.var "continue") []
    | .globalS xs =>
        .app (.var "global") (xs.map (fun x => .lit (.str x)))
    | .clearS xs =>
        .app (.var "clear") (xs.map (fun x => .lit (.str x)))

  /-- A list of statements lowers to a right-nested `seq`. -/
  partial def compileStmts : List Stmt → Core
    | []      => .app (.var "noop") []
    | [s]     => compileStmt s
    | s :: ss => .seq (compileStmt s) (compileStmts ss)

  /-- If/elseif/else chain lowers to right-nested ifte. -/
  partial def compileIf
      (cond : Expr) (thenB : List Stmt)
      (elifs : List (Expr × List Stmt))
      (elseB : Option (List Stmt)) : Core :=
    let elseCore : Core := match elseB with
      | none => .app (.var "noop") []
      | some ss => compileStmts ss
    let elifsCore : Core := elifs.foldr
      (fun (c, body) acc => .ifte (compileExpr c) (compileStmts body) acc)
      elseCore
    .ifte (compileExpr cond) (compileStmts thenB) elifsCore
end

/-- Top-level program lowering. -/
def compile (p : Program) : Core := compileStmts p

end Compile
end OctiveLean.Foundation
