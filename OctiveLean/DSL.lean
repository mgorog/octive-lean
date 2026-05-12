import OctiveLean.Eval
import OctiveLean.Builtins
import OctiveLean.PlotData
import OctiveLean.PlotBuiltins
import OctiveLean.PlotWidget
import ProofWidgets.Component.HtmlDisplay
import Lean

/-!
# OctiveLean Syntax DSL

Octave embedded as a Lean 4 syntax category. The LSP recognizes every
keyword and operator inside an `octave! { ... }` block — giving real
syntax highlighting, hover, and completion.

## Usage

```
octave! {
  x = 42;
  for k = 1:5
    x = x + k;
  endfor
  disp(x)
}
```

## Departures from standard Octave

- Outer block:  `octave! { ... }`  (curly braces avoid collisions with Lean's `end`)
- `endif` / `endfor` / `endwhile` / `endswitch` / `end_try_catch` / `endfunction`
  to close each control structure (these are real Octave keywords too)
- Strings: `"..."`  (Lean string literals — `'...'` is not supported)
- Comments: `--`  (Lean style — `%` is the modulo operator token)
- Matrix rows are separated by `;`, columns by `,`:  `[1.0, 2.0; 3.0, 4.0]`
-/

namespace OctiveLean.DSL

open Lean
open OctiveLean

/-- Convert a `String` to a `TSyntax `term` whose representation is a string literal. -/
private def quoteStr (s : String) : TSyntax `term :=
  ⟨Lean.Syntax.mkStrLit s⟩

-- ─────────────────────────────────────────────────────────────────
-- Syntax categories
-- ─────────────────────────────────────────────────────────────────

declare_syntax_cat octExpr
declare_syntax_cat octStmt
declare_syntax_cat octRow
declare_syntax_cat octMatBody

-- ─────────────────────────────────────────────────────────────────
-- EXPRESSIONS
-- ─────────────────────────────────────────────────────────────────

-- Literals  (true/false handled as identifiers in convExpr)
-- Atomic forms must be at :max so they can be left-args of postfix rules.
syntax:max num                                            : octExpr
syntax:max scientific                                     : octExpr
syntax:max str                                            : octExpr

-- Identifier
syntax:max ident                                          : octExpr

-- Grouped
syntax:max "(" octExpr ")"                                : octExpr

-- Matrix literal: rows separated by ';', columns by ','
syntax octExpr,+                                          : octRow
syntax octRow                                             : octMatBody
syntax octRow ";" octMatBody                              : octMatBody
syntax:max "[" octMatBody "]"                             : octExpr
syntax:max "[" "]"                                        : octExpr   -- empty matrix

-- Function handles
syntax:max "@" ident                                      : octExpr
syntax:max "@(" ident,* ")" octExpr                       : octExpr

-- Unary
syntax:75 "-" octExpr:75                                  : octExpr
syntax:75 "!" octExpr:75                                  : octExpr

-- Power (right-associative)
syntax:74 octExpr:75 " ^ "  octExpr:74                    : octExpr
syntax:74 octExpr:75 " .^ " octExpr:74                    : octExpr

-- Multiplication / division (left-associative)
syntax:70 octExpr:70 " * "  octExpr:71                    : octExpr
syntax:70 octExpr:70 " / "  octExpr:71                    : octExpr
syntax:70 octExpr:70 " .* " octExpr:71                    : octExpr
syntax:70 octExpr:70 " ./ " octExpr:71                    : octExpr

-- Addition / subtraction
syntax:65 octExpr:65 " + "  octExpr:66                    : octExpr
syntax:65 octExpr:65 " - "  octExpr:66                    : octExpr

-- Range  a:b
syntax:60 octExpr:61 " : "  octExpr:61                    : octExpr

-- Comparison
syntax:50 octExpr:51 " == " octExpr:51                    : octExpr
syntax:50 octExpr:51 " != " octExpr:51                    : octExpr
syntax:50 octExpr:51 " <= " octExpr:51                    : octExpr
syntax:50 octExpr:51 " >= " octExpr:51                    : octExpr
syntax:50 octExpr:51 " < "  octExpr:51                    : octExpr
syntax:50 octExpr:51 " > "  octExpr:51                    : octExpr

-- Logical
syntax:40 octExpr:40 " && " octExpr:41                    : octExpr
syntax:40 octExpr:40 " || " octExpr:41                    : octExpr
syntax:40 octExpr:40 " & "  octExpr:41                    : octExpr
syntax:40 octExpr:40 " | "  octExpr:41                    : octExpr

-- Function call / matrix index
syntax:max octExpr:max "(" octExpr,* ")"                  : octExpr

-- ─────────────────────────────────────────────────────────────────
-- STATEMENTS
-- ─────────────────────────────────────────────────────────────────

-- Expression statement
syntax octExpr                                            : octStmt
syntax octExpr ";"                                        : octStmt

-- Assignment
syntax ident " = " octExpr                                : octStmt
syntax ident " = " octExpr ";"                            : octStmt

-- Multi-assignment
syntax "[" ident,+ "]" " = " octExpr                      : octStmt
syntax "[" ident,+ "]" " = " octExpr ";"                  : octStmt

-- IF / ELSEIF / ELSE / ENDIF
syntax "if" octExpr octStmt*
       ("elseif" octExpr octStmt*)*
       ("else" octStmt*)?
       "endif"                                            : octStmt

-- FOR / ENDFOR
syntax "for" ident " = " octExpr octStmt* "endfor"        : octStmt

-- WHILE / ENDWHILE
syntax "while" octExpr octStmt* "endwhile"                : octStmt

-- SWITCH / CASE / OTHERWISE / ENDSWITCH
syntax "switch" octExpr
       ("case" octExpr octStmt*)*
       ("otherwise" octStmt*)?
       "endswitch"                                        : octStmt

-- TRY / CATCH / END_TRY_CATCH
syntax "try" octStmt*
       ("catch" ident octStmt*)?
       "end_try_catch"                                    : octStmt

-- Control flow
syntax "return"                                           : octStmt
syntax "break"                                            : octStmt
syntax "continue"                                         : octStmt

-- Scope
syntax "global" ident+                                    : octStmt
syntax "clear"  ident+                                    : octStmt

-- Function definition
syntax "function" ident " = " ident "(" ident,* ")"
       octStmt* "endfunction"                             : octStmt
syntax "function" "[" ident,+ "]" " = " ident "(" ident,* ")"
       octStmt* "endfunction"                             : octStmt
syntax "function" ident "(" ident,* ")"
       octStmt* "endfunction"                             : octStmt

-- ─────────────────────────────────────────────────────────────────
-- Macro conversion: octExpr → Term  (of type OctiveLean.Expr)
-- ─────────────────────────────────────────────────────────────────

private partial def convExpr (e : Syntax) : MacroM (TSyntax `term) := do
  match e with
  -- Literals
  | `(octExpr| $n:num)         => `(Expr.lit (.float ($n : Float)))
  | `(octExpr| $f:scientific)  => `(Expr.lit (.float ($f : Float)))
  | `(octExpr| $s:str)         => `(Expr.lit (.str $s))
  -- Identifier (with special handling for `true`/`false`)
  | `(octExpr| $id:ident) =>
      match id.getId.toString with
      | "true"  => `(Expr.lit (.bool true))
      | "false" => `(Expr.lit (.bool false))
      | name    => `(Expr.ident $(Lean.quote name))
  -- Grouped
  | `(octExpr| ($x))           => convExpr x
  -- Unary
  | `(octExpr| - $x)           => do `(Expr.unop .neg  $(← convExpr x))
  | `(octExpr| ! $x)           => do `(Expr.unop .lnot $(← convExpr x))
  -- Power
  | `(octExpr| $a ^ $b)        => do `(Expr.binop .pow  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a .^ $b)       => do `(Expr.binop .epow $(← convExpr a) $(← convExpr b))
  -- Mul/Div
  | `(octExpr| $a * $b)        => do `(Expr.binop .mul  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a / $b)        => do `(Expr.binop .div  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a .* $b)       => do `(Expr.binop .emul $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a ./ $b)       => do `(Expr.binop .ediv $(← convExpr a) $(← convExpr b))
  -- Add/Sub
  | `(octExpr| $a + $b)        => do `(Expr.binop .add  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a - $b)        => do `(Expr.binop .sub  $(← convExpr a) $(← convExpr b))
  -- Range  (a:b — step defaults to 1; nested a:s:b parses as (a:s):b)
  | `(octExpr| $lo : $hi) => do
      match lo with
      | `(octExpr| $a : $step) =>
          `(Expr.range $(← convExpr a) (some $(← convExpr step)) $(← convExpr hi))
      | _ =>
          `(Expr.range $(← convExpr lo) none $(← convExpr hi))
  -- Comparison
  | `(octExpr| $a == $b)       => do `(Expr.binop .eq $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a != $b)       => do `(Expr.binop .ne $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a <= $b)       => do `(Expr.binop .le $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a >= $b)       => do `(Expr.binop .ge $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a < $b)        => do `(Expr.binop .lt $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a > $b)        => do `(Expr.binop .gt $(← convExpr a) $(← convExpr b))
  -- Logical
  | `(octExpr| $a && $b)       => do `(Expr.binop .land $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a || $b)       => do `(Expr.binop .lor  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a & $b)        => do `(Expr.binop .band $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a | $b)        => do `(Expr.binop .bor  $(← convExpr a) $(← convExpr b))
  -- Function call / matrix index
  | `(octExpr| $f:octExpr ( $args:octExpr,* )) => do
      let fT  ← convExpr f
      let aTs ← args.getElems.mapM (fun a => do `(Arg.pos $(← convExpr a)))
      `(Expr.index $fT #[$aTs,*])
  -- Function handles
  | `(octExpr| @ $id:ident) =>
      `(Expr.fnHandle $(Lean.quote id.getId.toString))
  | `(octExpr| @( $params:ident,* ) $body:octExpr) => do
      let pNames := params.getElems.map (fun p => quoteStr p.getId.toString)
      `(Expr.anon #[$pNames,*] $(← convExpr body))
  -- Matrix literal: empty
  | `(octExpr| [ ])  => `(Expr.matrix #[])
  -- Matrix literal: with body (one or more rows)
  | `(octExpr| [ $body:octMatBody ]) => do
      let rowTerms ← collectRows body
      `(Expr.matrix #[$rowTerms,*])
  | _ => Macro.throwErrorAt e "unsupported expression syntax"
where
  convRow (row : Syntax) : MacroM (TSyntax `term) := do
    match row with
    | `(octRow| $cols:octExpr,*) => do
        let colTerms ← cols.getElems.mapM convExpr
        `(#[$colTerms,*])
    | _ => Macro.throwErrorAt row "bad matrix row"
  collectRows (body : Syntax) : MacroM (Array (TSyntax `term)) := do
    match body with
    | `(octMatBody| $r:octRow) => do
        return #[← convRow r]
    | `(octMatBody| $r:octRow ; $rest:octMatBody) => do
        let rt ← convRow r
        let restRows ← collectRows rest
        return #[rt] ++ restRows
    | _ => Macro.throwErrorAt body "bad matrix body"

-- ─────────────────────────────────────────────────────────────────
-- Macro conversion: octStmt → Term  (of type OctiveLean.Stmt)
-- ─────────────────────────────────────────────────────────────────

private partial def convStmt (s : Syntax) : MacroM (TSyntax `term) := do
  match s with
  -- Expression statements
  | `(octStmt| $e:octExpr ;)   => do `(Stmt.exprS $(← convExpr e) true)
  | `(octStmt| $e:octExpr)     => do `(Stmt.exprS $(← convExpr e) false)
  -- Assignments
  | `(octStmt| $x:ident = $e:octExpr ;) =>
      do `(Stmt.assign #[$(Lean.quote x.getId.toString)] $(← convExpr e) true)
  | `(octStmt| $x:ident = $e:octExpr) =>
      do `(Stmt.assign #[$(Lean.quote x.getId.toString)] $(← convExpr e) false)
  -- Multi-assignment
  | `(octStmt| [ $xs:ident,* ] = $e:octExpr ;) => do
      let names := xs.getElems.map (fun x => quoteStr x.getId.toString)
      `(Stmt.assign #[$names,*] $(← convExpr e) true)
  | `(octStmt| [ $xs:ident,* ] = $e:octExpr) => do
      let names := xs.getElems.map (fun x => quoteStr x.getId.toString)
      `(Stmt.assign #[$names,*] $(← convExpr e) false)
  -- IF
  | `(octStmt| if $cond:octExpr $thenB:octStmt*
               $[elseif $eiconds:octExpr $eibodies:octStmt*]*
               $[else $elseB:octStmt*]?
               endif) => do
      let condT  ← convExpr cond
      let thenT  ← thenB.mapM convStmt
      let eiTs   ← (Array.zip eiconds eibodies).mapM (fun (c, body) => do
        let ct ← convExpr c
        let bt ← body.mapM convStmt
        `(($ct, #[$bt,*])))
      let elseT ← match elseB with
        | none   => `((none : Option (Array Stmt)))
        | some b => do let bt ← b.mapM convStmt; `(some #[$bt,*])
      `(Stmt.ifS $condT #[$thenT,*] #[$eiTs,*] $elseT)
  -- FOR
  | `(octStmt| for $k:ident = $range:octExpr $body:octStmt* endfor) => do
      `(Stmt.forS $(Lean.quote k.getId.toString)
         $(← convExpr range)
         #[$(← body.mapM convStmt),*])
  -- WHILE
  | `(octStmt| while $cond:octExpr $body:octStmt* endwhile) => do
      `(Stmt.whileS $(← convExpr cond) #[$(← body.mapM convStmt),*])
  -- SWITCH
  | `(octStmt| switch $val:octExpr
               $[case $cvs:octExpr $cbs:octStmt*]*
               $[otherwise $ob:octStmt*]?
               endswitch) => do
      let valT  ← convExpr val
      let brs   ← (Array.zip cvs cbs).mapM (fun (cv, cb) => do
        let cvt ← convExpr cv
        let cbt ← cb.mapM convStmt
        `(($cvt, #[$cbt,*])))
      let otT ← match ob with
        | none   => `((none : Option (Array Stmt)))
        | some b => do let bt ← b.mapM convStmt; `(some #[$bt,*])
      `(Stmt.switchS $valT #[$brs,*] $otT)
  -- TRY / CATCH
  | `(octStmt| try $tryB:octStmt*
               $[catch $evar:ident $catchB:octStmt*]?
               end_try_catch) => do
      let tryT ← tryB.mapM convStmt
      let catchT ←
        match evar, catchB with
        | some ev, some cb => do
            let cbt ← cb.mapM convStmt
            `(some ($(Lean.quote ev.getId.toString), #[$cbt,*]))
        | _, _ => `((none : Option (String × Array Stmt)))
      `(Stmt.tryS #[$tryT,*] $catchT)
  -- Control flow
  | `(octStmt| return)     => `(Stmt.returnS)
  | `(octStmt| break)      => `(Stmt.breakS)
  | `(octStmt| continue)   => `(Stmt.continueS)
  -- Scope
  | `(octStmt| global $ids*) => do
      let names := ids.map (fun i => quoteStr i.getId.toString)
      `(Stmt.globalS #[$names,*])
  | `(octStmt| clear $ids*) => do
      let names := ids.map (fun i => quoteStr i.getId.toString)
      `(Stmt.clearS #[$names,*])
  -- Function defs
  | `(octStmt| function $ret:ident = $name:ident ( $params:ident,* )
               $body:octStmt* endfunction) => do
      let pNames := params.getElems.map (fun p => quoteStr p.getId.toString)
      let bt ← body.mapM convStmt
      `(Stmt.funcDefS (FuncDef.mk
          $(quoteStr name.getId.toString)
          #[$pNames,*]
          #[$(quoteStr ret.getId.toString)]
          #[$bt,*]))
  | `(octStmt| function [ $rets:ident,* ] = $name:ident ( $params:ident,* )
               $body:octStmt* endfunction) => do
      let pNames := params.getElems.map (fun p => quoteStr p.getId.toString)
      let rNames := rets.getElems.map   (fun r => quoteStr r.getId.toString)
      let bt ← body.mapM convStmt
      `(Stmt.funcDefS (FuncDef.mk
          $(quoteStr name.getId.toString)
          #[$pNames,*]
          #[$rNames,*]
          #[$bt,*]))
  | `(octStmt| function $name:ident ( $params:ident,* )
               $body:octStmt* endfunction) => do
      let pNames := params.getElems.map (fun p => quoteStr p.getId.toString)
      let bt ← body.mapM convStmt
      `(Stmt.funcDefS (FuncDef.mk
          $(quoteStr name.getId.toString)
          #[$pNames,*]
          #[]
          #[$bt,*]))
  | _ => Macro.throwErrorAt s "unsupported statement syntax"

-- ─────────────────────────────────────────────────────────────────
-- Source info helper: macro-generated syntax has canonical := false,
-- which prevents `savePanelWidgetInfo` from binding the widget to a
-- source position.  Flip the flag.
-- ─────────────────────────────────────────────────────────────────

private def mkCanonicalInfo : Lean.SourceInfo → Lean.SourceInfo
  | .synthetic s e _ => .synthetic s e true
  | si => si

private def mkCanonicalSyntax : Lean.Syntax → Lean.Syntax
  | .node i k a    => .node (mkCanonicalInfo i) k a
  | .atom i v      => .atom (mkCanonicalInfo i) v
  | .ident i r v p => .ident (mkCanonicalInfo i) r v p
  | s              => s

-- ─────────────────────────────────────────────────────────────────
-- Top-level commands
-- ─────────────────────────────────────────────────────────────────

/-- `octave! { stmts }` — parse, type-check, and run the block. -/
syntax (name := octaveRun) "octave!" "{" octStmt* "}" : command

macro_rules
  | `(command| octave! { $stmts:octStmt* }) => do
      let stmtTerms ← stmts.mapM convStmt
      let result : Lean.TSyntax `command ← `(#html (show Lean.Elab.Command.CommandElabM ProofWidgets.Html from do
          let opts ← Lean.getOptions
          let theme : String := opts.get `octive.plotTheme "auto"
          let (figs, errMsg) ← (do
            let plotBuf ← IO.mkRef (#[] : Array OctiveLean.Figure)
            let env := OctiveLean.PlotBuiltins.register plotBuf
                       (OctiveLean.registerAllBuiltins OctiveLean.Env.empty)
            let errMsg : Option String ← try
                match ← OctiveLean.runProgram #[$stmtTerms,*] env with
                | .ok _    => pure none
                | .error e => pure (some s!"runtime error: {e}")
              catch ex =>
                pure (some s!"IO exception: {ex.toString}")
            let figs ← plotBuf.get
            pure (figs, errMsg) : IO _)
          return OctiveLean.PlotWidget.renderWithError figs theme errMsg))
      return (⟨mkCanonicalSyntax result.raw⟩ : Lean.TSyntax `command)

/-- `octave_program! name { stmts }` — bind the parsed AST to a Lean def. -/
syntax (name := octaveProg) "octave_program!" ident "{" octStmt* "}" : command

macro_rules
  | `(command| octave_program! $name:ident { $stmts:octStmt* }) => do
      let stmtTerms ← stmts.mapM convStmt
      `(def $name : Array OctiveLean.Stmt := #[$stmtTerms,*])

end OctiveLean.DSL
