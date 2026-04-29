import OctiveLean.Eval
import OctiveLean.Builtins
import OctiveLean.PlotData
import OctiveLean.PlotWidget
import OctiveLean.PlotBuiltins
import ProofWidgets.Component.HtmlDisplay
import Lean

/-!
# OctiveLean Syntax DSL

Octave as a first-class Lean 4 syntax category.  The LSP sees every keyword,
operator and structure — giving real syntax highlighting, hover and completion
inside `octave! ... octave_end` blocks.

## Usage

```lean
octave!
  x = 42;
  for k = 1:5
    x = x + k;
  endfor
  disp(x)
octave_end
```

## Syntax notes (differences from standard Octave)
- Block closers: `endif` `endfor` `endwhile` `endfunction` `endswitch` `endtry`
  (Octave supports these as aliases for `end` — they work in real Octave too)
- Outer block: `octave!` … `octave_end`
- Strings: use Lean double-quotes `"hello"` (not `'hello'`)
- Matrix literals: `[1.0, 2.0, 3.0]` (row vector), `[[1.0, 2.0], [3.0, 4.0]]` (matrix)
- Comments: `--` Lean style (parser limitation — `%` is the modulo token)
- `true` / `false` are valid Octave literals
-/

open OctiveLean
open Lean

-- ─────────────────────────────────────────────────────────────────
-- Syntax categories
-- ─────────────────────────────────────────────────────────────────

declare_syntax_cat octExpr
declare_syntax_cat octStmt

-- ─────────────────────────────────────────────────────────────────
-- EXPRESSIONS
-- ─────────────────────────────────────────────────────────────────

syntax num                                               : octExpr
syntax scientific                                        : octExpr
syntax str                                               : octExpr
syntax ident                                             : octExpr
syntax "(" octExpr ")"                                   : octExpr

-- Unary
syntax:90 "-" octExpr:90                                 : octExpr
syntax:90 "!" octExpr:90                                 : octExpr

-- Arithmetic
syntax:75 octExpr:76 "^"  octExpr:75                    : octExpr
syntax:75 octExpr:76 ".^" octExpr:75                    : octExpr
syntax:70 octExpr:70 "*"  octExpr:71                    : octExpr
syntax:70 octExpr:70 "/"  octExpr:71                    : octExpr
syntax:70 octExpr:70 ".*" octExpr:71                    : octExpr
syntax:70 octExpr:70 "./" octExpr:71                    : octExpr
syntax:65 octExpr:65 "+"  octExpr:66                    : octExpr
syntax:65 octExpr:65 "-"  octExpr:66                    : octExpr

-- Comparison
syntax:50 octExpr:51 "==" octExpr:51                    : octExpr
syntax:50 octExpr:51 "!=" octExpr:51                    : octExpr
syntax:50 octExpr:51 "<"  octExpr:51                    : octExpr
syntax:50 octExpr:51 "<=" octExpr:51                    : octExpr
syntax:50 octExpr:51 ">"  octExpr:51                    : octExpr
syntax:50 octExpr:51 ">=" octExpr:51                    : octExpr

-- Logical
syntax:40 octExpr:40 "&&" octExpr:41                    : octExpr
syntax:40 octExpr:40 "||" octExpr:41                    : octExpr
syntax:35 octExpr:35 "&"  octExpr:36                    : octExpr
syntax:35 octExpr:35 "|"  octExpr:36                    : octExpr

-- Range  a:b  and  a:step:b  (left-assoc; (a:step):b is the three-part form)
syntax:20 octExpr:20 ":" octExpr:21                     : octExpr

-- Call / index: f(a, b, ...) — ident-based to avoid left-recursion issues
syntax ident "(" octExpr,* ")"                          : octExpr

-- Struct field: s.field  (left-recursive, works for simple s.f cases)
syntax:max octExpr:max noWs "." noWs ident              : octExpr

-- Dynamic field: s.(expr)  — ".(" is a single token in Lean 4
-- Note: nested use like disp(p.(f)) is limited; use as a statement or top-level expr
syntax ident ".(" octExpr ")"                           : octExpr

-- Function handles
syntax "@" ident                                         : octExpr
syntax "@" "(" ident,* ")" octExpr                      : octExpr

-- Vector / matrix literals
-- [a, b, c] = row vector;  [[a,b], [c,d]] = matrix
syntax "[" octExpr,* "]"                                 : octExpr

-- ─────────────────────────────────────────────────────────────────
-- STATEMENTS
-- ─────────────────────────────────────────────────────────────────

syntax octExpr                                           : octStmt
syntax octExpr ";"                                       : octStmt

syntax ident " = " octExpr                               : octStmt
syntax ident " = " octExpr ";"                           : octStmt

syntax "[" ident,+ "]" " = " octExpr                    : octStmt
syntax "[" ident,+ "]" " = " octExpr ";"                : octStmt

-- Struct field assignment: s.f = expr
syntax ident noWs "." noWs ident " = " octExpr          : octStmt
syntax ident noWs "." noWs ident " = " octExpr ";"      : octStmt

-- IF / ENDIF
syntax "if" octExpr octStmt*
  ("elseif" octExpr octStmt*)*
  ("else" octStmt*)?
  "endif"                                                : octStmt

-- FOR / ENDFOR
syntax "for" ident " = " octExpr octStmt* "endfor"      : octStmt

-- WHILE / ENDWHILE
syntax "while" octExpr octStmt* "endwhile"              : octStmt

-- SWITCH / ENDSWITCH
syntax "switch" octExpr
  ("case" octExpr octStmt*)*
  ("otherwise" octStmt*)?
  "endswitch"                                            : octStmt

-- TRY / ENDTRY
syntax "try" octStmt*
  ("catch" ident octStmt*)?
  "endtry"                                               : octStmt

syntax "return"                                          : octStmt
syntax "break"                                           : octStmt
syntax "continue"                                        : octStmt

syntax "global" ident,+                                  : octStmt
syntax "clear"  ident,+                                  : octStmt

-- Function definitions
syntax "function" ident " = " ident "(" ident,* ")"
  octStmt* "endfunction"                                 : octStmt
syntax "function" "[" ident,+ "]" " = " ident "(" ident,* ")"
  octStmt* "endfunction"                                 : octStmt
syntax "function" ident "(" ident,* ")"
  octStmt* "endfunction"                                 : octStmt

-- Top-level blocks
syntax (name := octaveRun)   "octave!"       octStmt* "octave_end" : command
syntax (name := octaveStmts) "octave_stmts!" ident octStmt* "octave_end" : command

-- ─────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────

private def strTerm (s : String) : TSyntax `term := ⟨Syntax.mkStrLit s⟩

private def identStr (id : TSyntax `ident) : TSyntax `term :=
  strTerm id.getId.toString

-- ─────────────────────────────────────────────────────────────────
-- convExpr : octExpr syntax → term of type OctiveLean.Expr
-- ─────────────────────────────────────────────────────────────────

private partial def convExpr : TSyntax `octExpr → MacroM (TSyntax `term)
  | `(octExpr| $n:num)        => `(Expr.lit (.float ($n : Float)))
  | `(octExpr| $f:scientific)  => `(Expr.lit (.float ($f : Float)))
  | `(octExpr| $s:str)         => `(Expr.lit (.str $s))
  | `(octExpr| $id:ident)      =>
      match id.getId.toString with
      | "true"  => `(Expr.lit (.bool true))
      | "false" => `(Expr.lit (.bool false))
      | name    => `(Expr.ident $(strTerm name))
  | `(octExpr| ($inner:octExpr))       => convExpr inner
  | `(octExpr| - $x:octExpr)           => do `(Expr.unop .neg   $(← convExpr x))
  | `(octExpr| ! $x:octExpr)           => do `(Expr.unop .lnot  $(← convExpr x))
  | `(octExpr| $a:octExpr ^  $b:octExpr) => do `(Expr.binop .pow  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr .^ $b:octExpr) => do `(Expr.binop .epow $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr *  $b:octExpr) => do `(Expr.binop .mul  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr /  $b:octExpr) => do `(Expr.binop .div  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr .* $b:octExpr) => do `(Expr.binop .emul $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr ./ $b:octExpr) => do `(Expr.binop .ediv $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr +  $b:octExpr) => do `(Expr.binop .add  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr -  $b:octExpr) => do `(Expr.binop .sub  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr == $b:octExpr) => do `(Expr.binop .eq   $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr != $b:octExpr) => do `(Expr.binop .ne   $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr <  $b:octExpr) => do `(Expr.binop .lt   $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr <= $b:octExpr) => do `(Expr.binop .le   $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr >  $b:octExpr) => do `(Expr.binop .gt   $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr >= $b:octExpr) => do `(Expr.binop .ge   $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr && $b:octExpr) => do `(Expr.binop .land $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr || $b:octExpr) => do `(Expr.binop .lor  $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr &  $b:octExpr) => do `(Expr.binop .band $(← convExpr a) $(← convExpr b))
  | `(octExpr| $a:octExpr |  $b:octExpr) => do `(Expr.binop .bor  $(← convExpr a) $(← convExpr b))
  -- Range: a:b or (a:step):b → three-part
  | `(octExpr| $lo:octExpr : $hi:octExpr) => do
      match lo with
      | `(octExpr| $a:octExpr : $step:octExpr) =>
          `(Expr.range $(← convExpr a) (some $(← convExpr step)) $(← convExpr hi))
      | _ =>
          `(Expr.range $(← convExpr lo) none $(← convExpr hi))
  -- Call / index (ident-based)
  | `(octExpr| $f:ident ($args,*)) => do
      let fT ← `(Expr.ident $(identStr f))
      let aTs ← args.getElems.mapM fun a => do
        let t ← convExpr a; `(Arg.pos $t)
      `(Expr.index $fT #[$aTs,*])
  -- Struct field: s.field
  | `(octExpr| $s:octExpr.$field:ident) => do
      `(Expr.dotIndex $(← convExpr s) $(strTerm field.getId.toString))
  -- Dynamic field: s.(expr) — ident base only
  | `(octExpr| $s:ident .($field:octExpr)) => do
      `(Expr.dynField (Expr.ident $(identStr s)) $(← convExpr field))
  -- Function handles
  | `(octExpr| @$id:ident) =>
      `(Expr.fnHandle $(strTerm id.getId.toString))
  | `(octExpr| @($params,*) $body:octExpr) => do
      let ps := params.getElems.map identStr
      `(Expr.anon #[$ps,*] $(← convExpr body))
  -- Vector / matrix
  | `(octExpr| [$elems,*]) => do
      let es := elems.getElems
      if es.isEmpty then
        return ← `(Expr.matrix #[])
      -- If first element is also [...], treat as multi-row matrix
      let firstIsRow : Bool := match es[0]! with
        | `(octExpr| [$_,*]) => true | _ => false
      if firstIsRow then
        let rowTerms ← es.mapM fun row => do
          match row with
          | `(octExpr| [$cols,*]) => do
              let colTs ← cols.getElems.mapM convExpr
              `(#[$colTs,*])
          | _ => Macro.throwError s!"expected [...] row in matrix literal, got: {row}"
        `(Expr.matrix #[$rowTerms,*])
      else
        let colTs ← es.mapM convExpr
        `(Expr.matrix #[#[$colTs,*]])
  | e => Macro.throwError s!"unsupported octExpr: {e}"

-- ─────────────────────────────────────────────────────────────────
-- convStmt : octStmt syntax → term of type OctiveLean.Stmt
-- ─────────────────────────────────────────────────────────────────

private partial def convStmt : TSyntax `octStmt → MacroM (TSyntax `term)
  -- Expression statement
  | `(octStmt| $e:octExpr)   => do `(Stmt.exprS $(← convExpr e) false)
  | `(octStmt| $e:octExpr ;) => do `(Stmt.exprS $(← convExpr e) true)
  -- Assignment
  | `(octStmt| $x:ident = $e:octExpr)   => do
      `(Stmt.assign #[$(identStr x)] $(← convExpr e) false)
  | `(octStmt| $x:ident = $e:octExpr ;) => do
      `(Stmt.assign #[$(identStr x)] $(← convExpr e) true)
  -- Struct field assignment: s.f = expr
  | `(octStmt| $s:ident.$f:ident = $e:octExpr ;) => do
      `(Stmt.indexAssign (Expr.dotIndex (Expr.ident $(identStr s)) $(strTerm f.getId.toString)) $(← convExpr e) true)
  | `(octStmt| $s:ident.$f:ident = $e:octExpr) => do
      `(Stmt.indexAssign (Expr.dotIndex (Expr.ident $(identStr s)) $(strTerm f.getId.toString)) $(← convExpr e) false)
  -- Multi-assignment
  | `(octStmt| [$xs,*] = $e:octExpr) => do
      let names := xs.getElems.map identStr
      `(Stmt.assign #[$names,*] $(← convExpr e) false)
  | `(octStmt| [$xs,*] = $e:octExpr ;) => do
      let names := xs.getElems.map identStr
      `(Stmt.assign #[$names,*] $(← convExpr e) true)
  -- IF
  | `(octStmt| if $cond:octExpr $thenB:octStmt*
               $[elseif $eiconds:octExpr $eibodies:octStmt*]*
               $[else $elseB:octStmt*]?
               endif) => do
      let condT  ← convExpr cond
      let thenBT ← thenB.mapM convStmt
      let eiBranches ← (Array.zip eiconds eibodies).mapM fun (c, body) => do
        let cT    ← convExpr c
        let bodyT ← body.mapM convStmt
        `(($cT, #[$bodyT,*]))
      let elseBT ← match elseB with
        | none   => `(none)
        | some b => do let bt ← b.mapM convStmt; `(some #[$bt,*])
      `(Stmt.ifS $condT #[$thenBT,*] #[$eiBranches,*] $elseBT)
  -- FOR
  | `(octStmt| for $k:ident = $range:octExpr $body:octStmt* endfor) => do
      let bodyT ← body.mapM convStmt
      `(Stmt.forS $(identStr k) $(← convExpr range) #[$bodyT,*])
  -- WHILE
  | `(octStmt| while $cond:octExpr $body:octStmt* endwhile) => do
      let bodyT ← body.mapM convStmt
      `(Stmt.whileS $(← convExpr cond) #[$bodyT,*])
  -- SWITCH
  | `(octStmt| switch $val:octExpr
               $[case $caseVals:octExpr $caseBodies:octStmt*]*
               $[otherwise $otherwiseB:octStmt*]?
               endswitch) => do
      let valT     ← convExpr val
      let branches ← (Array.zip caseVals caseBodies).mapM fun (cv, cb) => do
        let cvT ← convExpr cv
        let cbT ← cb.mapM convStmt
        `(($cvT, #[$cbT,*]))
      let otherwiseT ← match otherwiseB with
        | none   => `(none)
        | some b => do let bt ← b.mapM convStmt; `(some #[$bt,*])
      `(Stmt.switchS $valT #[$branches,*] $otherwiseT)
  -- TRY
  | `(octStmt| try $tryB:octStmt*
               $[catch $evar:ident $catchB:octStmt*]?
               endtry) => do
      let tryBT  ← tryB.mapM convStmt
      let catchT ← match evar, catchB with
        | some ev, some cb => do
            let cbt ← cb.mapM convStmt
            `(some ($(identStr ev), #[$cbt,*]))
        | _, _ => `(none)
      `(Stmt.tryS #[$tryBT,*] $catchT)
  -- Control flow
  | `(octStmt| return)   => `(Stmt.returnS)
  | `(octStmt| break)    => `(Stmt.breakS)
  | `(octStmt| continue) => `(Stmt.continueS)
  -- Scope
  | `(octStmt| global $ids,*) => do
      let names := ids.getElems.map identStr
      `(Stmt.globalS #[$names,*])
  | `(octStmt| clear $ids,*) => do
      let names := ids.getElems.map identStr
      `(Stmt.clearS #[$names,*])
  -- Function: single return
  | `(octStmt| function $ret:ident = $name:ident ($params,*) $body:octStmt* endfunction) => do
      let pns   := params.getElems.map identStr
      let bodyT ← body.mapM convStmt
      `(Stmt.funcDefS (FuncDef.mk $(identStr name) #[$pns,*]
          #[$(identStr ret)] #[$bodyT,*]))
  -- Function: multi-return
  | `(octStmt| function [$rets,*] = $name:ident ($params,*) $body:octStmt* endfunction) => do
      let pns   := params.getElems.map identStr
      let rns   := rets.getElems.map   identStr
      let bodyT ← body.mapM convStmt
      `(Stmt.funcDefS (FuncDef.mk $(identStr name) #[$pns,*] #[$rns,*] #[$bodyT,*]))
  -- Function: no return
  | `(octStmt| function $name:ident ($params,*) $body:octStmt* endfunction) => do
      let pns   := params.getElems.map identStr
      let bodyT ← body.mapM convStmt
      `(Stmt.funcDefS (FuncDef.mk $(identStr name) #[$pns,*] #[] #[$bodyT,*]))
  | s => Macro.throwError s!"unsupported octStmt: {s}"

-- ─────────────────────────────────────────────────────────────────
-- Helpers to mark expanded syntax as canonical
-- (Macro-generated syntax has SourceInfo.synthetic canonical:=false,
--  so savePanelWidgetInfo can't find the position.  We flip the flag.)
-- ─────────────────────────────────────────────────────────────────

private def mkCanonicalInfo : SourceInfo → SourceInfo
  | .synthetic s e _ => .synthetic s e true
  | si => si

private def mkCanonicalSyntax : Syntax → Syntax
  | .node i k a => .node (mkCanonicalInfo i) k a
  | .atom i v   => .atom (mkCanonicalInfo i) v
  | .ident i r v p => .ident (mkCanonicalInfo i) r v p
  | s => s

-- ─────────────────────────────────────────────────────────────────
-- Commands
-- ─────────────────────────────────────────────────────────────────

macro_rules
  | `(octave! $stmts:octStmt* octave_end) => do
      let stmtTerms ← stmts.mapM convStmt
      let result : TSyntax `command ← `(#html (show IO ProofWidgets.Html from do
          let plotBuf ← IO.mkRef (#[] : Array OctiveLean.Figure)
          let env := OctiveLean.PlotBuiltins.register plotBuf
                     (OctiveLean.registerAllBuiltins OctiveLean.Env.empty)
          match ← OctiveLean.runProgram #[$stmtTerms,*] env with
          | .ok _    => pure ()
          | .error e => IO.eprintln s!"runtime error: {e}"
          let figs ← plotBuf.get
          return OctiveLean.PlotWidget.render figs))
      return (⟨mkCanonicalSyntax result.raw⟩ : TSyntax `command)

macro_rules
  | `(octave_stmts! $name:ident $stmts:octStmt* octave_end) => do
      let stmtTerms ← stmts.mapM convStmt
      `(def $name : Array OctiveLean.Stmt := #[$stmtTerms,*])
