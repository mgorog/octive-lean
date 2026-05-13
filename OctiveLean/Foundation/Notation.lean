import OctiveLean.Foundation.Core
import OctiveLean.Foundation.Surface
import OctiveLean.Foundation.Compile
import OctiveLean.Foundation.Eval
import OctiveLean.Foundation.Initial
import OctiveLean.DSL

/-!
# Foundation.Notation — `octF! { … }` produces a `Program`.

The syntax categories `octExpr` / `octStmt` / `octArg` are declared by
`OctiveLean.DSL` (we import it to inherit the parsers); the macro
rules here are *different* from the imperative `octave!` macro:
they target `Foundation.Stmt` / `.Expr` instead of
`OctiveLean.Stmt` / `.Expr`, and the top-level command runs the
result through `Foundation.Compile + Eval`.

This file is small on purpose — every conversion case is one line of
boilerplate around a `Foundation.Surface` constructor. There's no
string smuggling, no IO refs, no macro-context-dependent state.

A subset of Octave is covered for now: numeric literals, identifiers,
basic arithmetic, comparisons, function calls, matrix literals,
ranges, simple assignment, `if`/`for`/`while`/function-def with
matching `end`, and bare expression statements. More surface
constructs are added one line at a time when needed.
-/

namespace OctiveLean.Foundation.Notation

open Lean OctiveLean.Foundation

/-- Lift a String into a Lean term that evaluates to that String. -/
private def quoteStr (s : String) : TSyntax `term :=
  ⟨Lean.Syntax.mkStrLit s⟩

mutual
  partial def convExpr (e : Syntax) : MacroM (TSyntax `term) := do
    match e with
    -- Literals
    | `(octExpr| $n:num) =>
        `(Expr.num ($n : Float))
    | `(octExpr| $f:scientific) =>
        `(Expr.num ($f : Float))
    | `(octExpr| $s:str) =>
        `(Expr.str $s)
    -- Identifiers (with true/false specialised)
    | `(octExpr| $id:ident) =>
        match id.getId.toString with
        | "true"  => `(Expr.bool true)
        | "false" => `(Expr.bool false)
        | name    => `(Expr.id $(quoteStr name))
    -- Grouped
    | `(octExpr| ($x)) => convExpr x
    -- Unary
    | `(octExpr| - $x) => do `(Expr.unop .neg $(← convExpr x))
    | `(octExpr| ! $x) => do `(Expr.unop .not $(← convExpr x))
    -- Power
    | `(octExpr| $a ^ $b)  => do `(Expr.binop .pow  $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a .^ $b) => do `(Expr.binop .epow $(← convExpr a) $(← convExpr b))
    -- Mul / div
    | `(octExpr| $a * $b)  => do `(Expr.binop .mul  $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a / $b)  => do `(Expr.binop .div  $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a .* $b) => do `(Expr.binop .emul $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a ./ $b) => do `(Expr.binop .ediv $(← convExpr a) $(← convExpr b))
    -- Add / sub
    | `(octExpr| $a + $b)  => do `(Expr.binop .add $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a - $b)  => do `(Expr.binop .sub $(← convExpr a) $(← convExpr b))
    -- Range  a:b  or  (a:s):b
    | `(octExpr| $lo : $hi) =>
        match lo with
        | `(octExpr| $a : $step) =>
            do `(Expr.range $(← convExpr a) (some $(← convExpr step)) $(← convExpr hi))
        | _ =>
            do `(Expr.range $(← convExpr lo) none $(← convExpr hi))
    -- Comparison
    | `(octExpr| $a == $b) => do `(Expr.binop .eq $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a != $b) => do `(Expr.binop .ne $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a <= $b) => do `(Expr.binop .le $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a >= $b) => do `(Expr.binop .ge $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a < $b)  => do `(Expr.binop .lt $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a > $b)  => do `(Expr.binop .gt $(← convExpr a) $(← convExpr b))
    -- Logical
    | `(octExpr| $a && $b) => do `(Expr.binop .land $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a || $b) => do `(Expr.binop .lor  $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a & $b)  => do `(Expr.binop .band $(← convExpr a) $(← convExpr b))
    | `(octExpr| $a | $b)  => do `(Expr.binop .bor  $(← convExpr a) $(← convExpr b))
    -- Function call / indexing
    | `(octExpr| $f:octExpr ( $args:octArg,* )) => do
        let fT  ← convExpr f
        let aTs ← args.getElems.mapM (fun a => match a with
          | `(octArg| :)            => `(IdxArg.colon)
          | `(octArg| $e:octExpr)   => do `(IdxArg.arg $(← convExpr e))
          | _ => Macro.throwErrorAt a "unsupported indexing argument")
        `(Expr.call $fT [$aTs,*])
    -- Field access
    | `(octExpr| $obj:octExpr . $f:ident) => do
        `(Expr.field $(← convExpr obj) $(quoteStr f.getId.toString))
    -- Matrix literal
    | `(octExpr| [ ])             => `(Expr.matrix [])
    | `(octExpr| [ $body:octMatBody ]) => do
        let rows ← collectRows body
        `(Expr.matrix [$rows,*])
    -- Cell literal
    | `(octExpr| { })             => `(Expr.cell [])
    | `(octExpr| { $body:octMatBody }) => do
        let rows ← collectRows body
        `(Expr.cell [$rows,*])
    -- Function handles
    | `(octExpr| @ $id:ident) =>
        `(Expr.handle $(quoteStr id.getId.toString))
    | `(octExpr| @( $params:ident,* ) $body:octExpr) => do
        let pNames := params.getElems.map (fun p => quoteStr p.getId.toString)
        `(Expr.anon [$pNames,*] $(← convExpr body))
    | _ => Macro.throwErrorAt e "unsupported octF! expression"

  partial def convRow (row : Syntax) : MacroM (TSyntax `term) := do
    match row with
    | `(octRow| $cols:octExpr,*) => do
        let colTs ← cols.getElems.mapM convExpr
        `([$colTs,*])
    | _ => Macro.throwErrorAt row "bad matrix row"

  partial def collectRows (body : Syntax) : MacroM (Array (TSyntax `term)) := do
    match body with
    | `(octMatBody| $r:octRow) => do return #[← convRow r]
    | `(octMatBody| $r:octRow ; $rest:octMatBody) => do
        let rt ← convRow r
        let restRows ← collectRows rest
        return #[rt] ++ restRows
    | _ => Macro.throwErrorAt body "bad matrix body"

  partial def convStmt (s : Syntax) : MacroM (TSyntax `term) := do
    match s with
    -- Expression statements
    | `(octStmt| $e:octExpr ;) =>
        do `(Stmt.exprS $(← convExpr e) .silent)
    | `(octStmt| $e:octExpr) =>
        do `(Stmt.exprS $(← convExpr e) .echo)
    -- Simple assignments
    | `(octStmt| $x:ident = $e:octExpr ;) =>
        do `(Stmt.assign
              (Expr.id $(quoteStr x.getId.toString))
              $(← convExpr e) .silent)
    | `(octStmt| $x:ident = $e:octExpr) =>
        do `(Stmt.assign
              (Expr.id $(quoteStr x.getId.toString))
              $(← convExpr e) .echo)
    -- Multi-assignment
    | `(octStmt| [ $xs:ident,* ] = $e:octExpr ;) => do
        let names := xs.getElems.map (fun x => quoteStr x.getId.toString)
        `(Stmt.massign [$names,*] $(← convExpr e) .silent)
    | `(octStmt| [ $xs:ident,* ] = $e:octExpr) => do
        let names := xs.getElems.map (fun x => quoteStr x.getId.toString)
        `(Stmt.massign [$names,*] $(← convExpr e) .echo)
    -- Complex LHS assignments
    | `(octStmt| $lhs:octExpr = $e:octExpr ;) =>
        do `(Stmt.assign $(← convExpr lhs) $(← convExpr e) .silent)
    | `(octStmt| $lhs:octExpr = $e:octExpr) =>
        do `(Stmt.assign $(← convExpr lhs) $(← convExpr e) .echo)
    -- IF
    | `(octStmt| if $cond:octExpr $thenB:octStmt*
                 $[elseif $eiconds:octExpr $eibodies:octStmt*]*
                 $[else $elseB:octStmt*]?
                 endif)
    | `(octStmt| if $cond:octExpr $thenB:octStmt*
                 $[elseif $eiconds:octExpr $eibodies:octStmt*]*
                 $[else $elseB:octStmt*]?
                 end) => do
        let condT  ← convExpr cond
        let thenT  ← thenB.mapM convStmt
        let eiTs   ← (Array.zip eiconds eibodies).mapM (fun (c, body) => do
          let ct ← convExpr c
          let bt ← body.mapM convStmt
          `(($ct, [$bt,*])))
        let elseT ← match elseB with
          | none   => `((none : Option (List Stmt)))
          | some b => do let bt ← b.mapM convStmt; `(some [$bt,*])
        `(Stmt.ifS $condT [$thenT,*] [$eiTs,*] $elseT)
    -- FOR
    | `(octStmt| for $k:ident = $range:octExpr $body:octStmt* endfor)
    | `(octStmt| for $k:ident = $range:octExpr $body:octStmt* end) => do
        `(Stmt.forS $(quoteStr k.getId.toString)
           $(← convExpr range)
           [$(← body.mapM convStmt),*])
    -- WHILE
    | `(octStmt| while $cond:octExpr $body:octStmt* endwhile)
    | `(octStmt| while $cond:octExpr $body:octStmt* end) => do
        `(Stmt.whileS $(← convExpr cond) [$(← body.mapM convStmt),*])
    -- Control flow
    | `(octStmt| return)     | `(octStmt| return ;)   => `(Stmt.retS)
    | `(octStmt| break)      | `(octStmt| break ;)    => `(Stmt.breakS)
    | `(octStmt| continue)   | `(octStmt| continue ;) => `(Stmt.contS)
    -- Function definition
    | `(octStmt| function $ret:ident = $name:ident ( $params:ident,* )
                 $body:octStmt* endfunction)
    | `(octStmt| function $ret:ident = $name:ident ( $params:ident,* )
                 $body:octStmt* end) => do
        let pNames := params.getElems.map (fun p => quoteStr p.getId.toString)
        let bt ← body.mapM convStmt
        `(Stmt.funDef (FunDef.mk
            $(quoteStr name.getId.toString)
            [$pNames,*]
            [$(quoteStr ret.getId.toString)]
            [$bt,*]))
    | `(octStmt| function $name:ident ( $params:ident,* )
                 $body:octStmt* endfunction)
    | `(octStmt| function $name:ident ( $params:ident,* )
                 $body:octStmt* end) => do
        let pNames := params.getElems.map (fun p => quoteStr p.getId.toString)
        let bt ← body.mapM convStmt
        `(Stmt.funDef (FunDef.mk
            $(quoteStr name.getId.toString)
            [$pNames,*]
            []
            [$bt,*]))
    | _ => Macro.throwErrorAt s "unsupported octF! statement"
end

/-! ## Top-level command

`octF! { … }` evaluates a program through the foundation pipeline and
prints the output trace + final value to the messages panel. No
plotting, no widgets — that machinery layers on later by replacing
`Initial.primop` and `Initial.env` with richer versions. -/

syntax (name := octFRun) "octF!" "{" octStmt* "}" : command

/-- `octProg! name { … }` defines `name : Program` from Octave source.
    No evaluation happens — the program is just a Lean value, ready to
    have theorems proven about it. -/
syntax (name := octProgDef) "octProg!" ident "{" octStmt* "}" : command

macro_rules
  | `(command| octProg! $name:ident { $stmts:octStmt* }) => do
      let stmtTerms ← stmts.mapM convStmt
      `(section
         open OctiveLean.Foundation
         def $name : Program := [$stmtTerms,*]
         end)

macro_rules
  | `(command| octF! { $stmts:octStmt* }) => do
      let stmtTerms ← stmts.mapM convStmt
      `(section
         open OctiveLean.Foundation
         #eval show IO Unit from do
            let prog : Program := [$stmtTerms,*]
            let core := Compile.compile prog
            let (state, res) :=
              Comp.run (Eval.eval Initial.primop Eval.defaultFuel core Initial.env)
                { env := Initial.env }
            for line in state.out do
              IO.println line
            match res with
            | .error e => IO.eprintln s!"error: {e}"
            | .ok v    => IO.println s!"=> {v}"
         end)

end OctiveLean.Foundation.Notation
