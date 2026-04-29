import OctiveLean.Lexer
import OctiveLean.AST

namespace OctiveLean

/-! Recursive-descent Octave parser -/

structure ParseState where
  tokens : Array Token
  pos    : Nat

private def ParseState.curr (p : ParseState) : TokenKind :=
  if p.pos < p.tokens.size then p.tokens[p.pos]!.kind else .Eof

private def ParseState.currTok (p : ParseState) : Token :=
  if p.pos < p.tokens.size then p.tokens[p.pos]!
  else { kind := .Eof, line := 0, col := 0 }

private def ParseState.peek (p : ParseState) (offset : Nat := 1) : TokenKind :=
  let i := p.pos + offset
  if i < p.tokens.size then p.tokens[i]!.kind else .Eof

private def ParseState.advance (p : ParseState) : ParseState :=
  { p with pos := p.pos + 1 }

private partial def ParseState.skipNL (p : ParseState) : ParseState :=
  match p.curr with
  | .Newline => p.advance.skipNL
  | _ => p

private partial def ParseState.skipStmtEnd (p : ParseState) : ParseState :=
  match p.curr with
  | .Newline | .Semi => p.advance.skipStmtEnd
  | _ => p

private def ParseState.expect (p : ParseState) (k : TokenKind) :
    Except String ParseState :=
  if p.curr == k then .ok p.advance
  else .error s!"expected {reprStr k}, got {reprStr p.curr} at line {p.currTok.line}"

private def isBlockEnd (k : TokenKind) : Bool :=
  match k with
  | .KwEnd | .KwEndfor | .KwEndwhile | .KwEndif | .KwEndfunction | .KwEndswitch
  | .KwEndTryCatch | .KwEndUnwindProtect | .KwElse | .KwElseif
  | .KwCase | .KwOtherwise | .KwCatch | .KwUnwindProtectCleanup | .Eof => true
  | _ => false

/-! Helpers defined before the mutual block -/

private def eatEndKw (p : ParseState) : Except String ParseState :=
  match p.curr with
  | .KwEnd | .KwEndfor | .KwEndwhile | .KwEndif
  | .KwEndfunction | .KwEndswitch | .KwEndTryCatch | .KwEndUnwindProtect =>
      .ok p.advance
  | k => .error s!"expected 'end', got {reprStr k} at line {p.currTok.line}"

private def expectIdent (p : ParseState) : Except String (String × ParseState) :=
  match p.curr with
  | .Ident n => .ok (n, p.advance)
  | k => .error s!"expected identifier, got {reprStr k} at line {p.currTok.line}"

private partial def parseIdentList (p : ParseState) : Except String (Array String × ParseState) :=
  let rec go (p : ParseState) (acc : Array String) : Except String (Array String × ParseState) :=
    match p.curr with
    | .Ident n =>
        let p := p.advance
        let p := if p.curr == .Comma then p.advance else p
        go p (acc.push n)
    | _ => .ok (acc, p)
  go p #[]

/-! Operator precedence -/

private def infixPrec (k : TokenKind) : Option (Nat × BinOp) :=
  match k with
  | .AmpAmp    => some (20, .land) | .PipePipe  => some (15, .lor)
  | .Amp       => some (25, .band) | .Pipe      => some (22, .bor)
  | .Lt        => some (40, .lt)   | .Le        => some (40, .le)
  | .Gt        => some (40, .gt)   | .Ge        => some (40, .ge)
  | .EqEq      => some (40, .eq)   | .Neq       => some (40, .ne)
  | .TildeEq   => some (40, .ne)
  | .Plus      => some (60, .add)  | .Minus     => some (60, .sub)
  | .Star      => some (70, .mul)  | .Slash     => some (70, .div)
  | .Backslash => some (70, .ldiv) | .DotStar   => some (70, .emul)
  | .DotSlash  => some (70, .ediv) | .DotBackslash => some (70, .eldiv)
  | .Caret     => some (80, .pow)  | .DotCaret  => some (80, .epow)
  | _ => none

private def isRightAssoc : BinOp → Bool
  | .pow | .epow => true
  | _ => false

/-! Forward declarations via mutual block (all `partial`) -/

mutual

  partial def parseBlock (p : ParseState) : Except String (Array Stmt × ParseState) := do
    let p := p.skipStmtEnd
    if isBlockEnd p.curr then return (#[], p)
    let (stmt, p) ← parseStmt p
    let p := p.skipStmtEnd
    let (rest, p) ← parseBlock p
    return (#[stmt] ++ rest, p)

  partial def parseStmt (p : ParseState) : Except String (Stmt × ParseState) := do
    let p := p.skipNL
    match p.curr with
    | .KwIf =>
        let p := p.advance.skipNL
        let (cond, p) ← parseExpr p
        let p := p.skipStmtEnd
        let (thenB, p) ← parseBlock p
        let (elseifs, elseB, p) ← parseIfTail p
        return (.ifS cond thenB elseifs elseB, p)
    | .KwFor =>
        let p := p.advance
        let (varName, p) ← expectIdent p
        let p ← p.expect .Eq
        let (iter, p) ← parseExpr p
        let p := p.skipStmtEnd
        let (body, p) ← parseBlock p
        let p ← eatEndKw p
        return (.forS varName iter body, p)
    | .KwWhile =>
        let p := p.advance.skipNL
        let (cond, p) ← parseExpr p
        let p := p.skipStmtEnd
        let (body, p) ← parseBlock p
        let p ← eatEndKw p
        return (.whileS cond body, p)
    | .KwDo =>
        let p := p.advance.skipStmtEnd
        let (body, p) ← parseBlock p
        let p ← p.expect .KwUntil
        let (cond, p) ← parseExpr p
        return (.doUntil body cond, p)
    | .KwSwitch =>
        let p := p.advance.skipNL
        let (expr, p) ← parseExpr p
        let p := p.skipStmtEnd
        let (cases, oth, p) ← parseSwitchBody p
        let p ← eatEndKw p
        return (.switchS expr cases oth, p)
    | .KwTry =>
        let p := p.advance.skipStmtEnd
        let (tryB, p) ← parseBlock p
        let (catchC, p) ← parseCatch p
        let p ← eatEndKw p
        return (.tryS tryB catchC, p)
    | .KwUnwindProtect =>
        let p := p.advance.skipStmtEnd
        let (body, p) ← parseBlock p
        let p ← p.expect .KwUnwindProtectCleanup
        let p := p.skipStmtEnd
        let (cleanup, p) ← parseBlock p
        let p ← eatEndKw p
        return (.unwindS body cleanup, p)
    | .KwFunction => parseFuncDef p
    | .KwReturn   => return (.returnS,   p.advance)
    | .KwBreak    => return (.breakS,    p.advance)
    | .KwContinue => return (.continueS, p.advance)
    | .KwGlobal =>
        let (names, p) ← parseIdentList p.advance
        return (.globalS names, p)
    | .KwPersistent =>
        let (names, p) ← parseIdentList p.advance
        return (.persistS names, p)
    | .KwClear =>
        let (names, p) ← parseIdentList p.advance
        return (.clearS names, p)
    | _ => parseExprOrAssign p

  partial def parseIfTail (p : ParseState) :
      Except String (Array (Expr × Array Stmt) × Option (Array Stmt) × ParseState) := do
    match p.curr with
    | .KwElseif =>
        let p := p.advance.skipNL
        let (cond, p) ← parseExpr p
        let p := p.skipStmtEnd
        let (branch, p) ← parseBlock p
        let (rest, els, p) ← parseIfTail p
        return (#[(cond, branch)] ++ rest, els, p)
    | .KwElse =>
        let p := p.advance.skipStmtEnd
        let (body, p) ← parseBlock p
        let p ← eatEndKw p
        return (#[], some body, p)
    | _ =>
        let p ← eatEndKw p
        return (#[], none, p)

  partial def parseSwitchBody (p : ParseState) :
      Except String (Array (Expr × Array Stmt) × Option (Array Stmt) × ParseState) := do
    match p.curr with
    | .KwCase =>
        let p := p.advance.skipNL
        let (expr, p) ← parseExpr p
        let p := p.skipStmtEnd
        let (body, p) ← parseBlock p
        let (rest, oth, p) ← parseSwitchBody p
        return (#[(expr, body)] ++ rest, oth, p)
    | .KwOtherwise =>
        let p := p.advance.skipStmtEnd
        let (body, p) ← parseBlock p
        return (#[], some body, p)
    | _ => return (#[], none, p)

  partial def parseCatch (p : ParseState) :
      Except String (Option (String × Array Stmt) × ParseState) := do
    match p.curr with
    | .KwCatch | .KwEndTryCatch =>
        let p := p.advance
        let (varOpt, p) := match p.curr with
          | .Ident n => (some n, p.advance)
          | _        => (none, p)
        let p := p.skipStmtEnd
        let (body, p) ← parseBlock p
        return (some (varOpt.getD "_e", body), p)
    | _ => return (none, p)

  partial def parseFuncDef (p : ParseState) : Except String (Stmt × ParseState) := do
    let p := p.advance  -- consume 'function'
    let (retVals, p) ← parseFuncRetVals p
    let (name, p) ← expectIdent p
    let (params, p) ←
      if p.curr == .LParen then do
        let p := p.advance
        let (ps, p) ← parseParamList p
        let p ← p.expect .RParen
        pure (ps, p)
      else pure (#[], p)
    let p := p.skipStmtEnd
    let (body, p) ← parseBlock p
    let p ← eatEndKw p
    return (.funcDefS (.mk name params retVals body), p)

  partial def parseFuncRetVals (p : ParseState) :
      Except String (Array String × ParseState) := do
    match p.curr with
    | .LBracket =>
        let p := p.advance
        let (names, p) ← parseParamList p
        let p ← p.expect .RBracket
        let p ← p.expect .Eq
        return (names, p)
    | .Ident n =>
        if p.peek == .Eq && p.peek (offset := 2) != .Eq then
          return (#[n], p.advance.advance)
        else
          return (#[], p)
    | _ => return (#[], p)

  partial def parseParamList (p : ParseState) : Except String (Array String × ParseState) := do
    let rec go (p : ParseState) (acc : Array String) : Except String (Array String × ParseState) :=
      match p.curr with
      | .Ident n =>
          let p := p.advance
          let p := if p.curr == .Comma then p.advance else p
          go p (acc.push n)
      | _ => .ok (acc, p)
    go p #[]

  partial def parseExprOrAssign (p : ParseState) : Except String (Stmt × ParseState) := do
    -- Speculatively detect simple/multi-return assignment: ident= or [a,b]=
    match ← tryParseAssign p with
    | some (lhs, rhs, p) =>
        let silent := p.curr == .Semi
        return (.assign lhs rhs silent, p)
    | none =>
        let (e, p) ← parseExpr p
        -- Detect indexed assignment: expr(...)= or expr.f= after expression parse
        if p.curr == .Eq && p.peek (offset := 1) != .Eq then
          let p := p.advance  -- skip =
          let (rhs, p) ← parseExpr p
          let silent := p.curr == .Semi
          return (.indexAssign e rhs silent, p)
        else
          let silent := p.curr == .Semi
          return (.exprS e silent, p)

  /-- Try to parse `ident =` or `[idents] = ` assignment.
      Returns none if it doesn't look like an assignment. -/
  partial def tryParseAssign (p : ParseState) :
      Except String (Option (Array String × Expr × ParseState)) := do
    match p.curr with
    | .Ident n =>
        if p.peek == .Eq && p.peek (offset := 2) != .Eq then
          let p := p.advance.advance  -- skip ident and =
          let (rhs, p) ← parseExpr p
          return some (#[n], rhs, p)
        else return none
    | .LBracket =>
        -- [a, b, ...] = rhs
        let rec eatNames (p : ParseState) (acc : Array String) :
            Except String (Option (Array String × ParseState)) :=
          match p.curr with
          | .Ident n =>
              let p := p.advance
              let p := if p.curr == .Comma then p.advance else p
              eatNames p (acc.push n)
          | .RBracket =>
              let p := p.advance
              if p.curr == .Eq && p.peek != .Eq then .ok (some (acc, p.advance))
              else .ok none
          | _ => .ok none
        match ← eatNames p.advance #[] with
        | some (names, p) =>
            let (rhs, p) ← parseExpr p
            return some (names, rhs, p)
        | none => return none
    | _ => return none

  /-- Parse an expression (Pratt climbing) -/
  partial def parseExpr (p : ParseState) : Except String (Expr × ParseState) :=
    parseExprPrec p 0

  partial def parseExprPrec (p : ParseState) (minPrec : Nat) :
      Except String (Expr × ParseState) := do
    let (lhs, p) ← parseUnary p
    parseInfix lhs p minPrec

  partial def parseUnary (p : ParseState) : Except String (Expr × ParseState) := do
    match p.curr with
    | .Minus => let (e, p) ← parseExprPrec p.advance 90; return (.unop .neg e,   p)
    | .Plus  => let (e, p) ← parseExprPrec p.advance 90; return (.unop .uplus e, p)
    | .Tilde | .Bang =>
        let (e, p) ← parseExprPrec p.advance 90
        return (.unop .lnot e, p)
    | _ => parsePostfix p

  partial def parseInfix (lhs : Expr) (p : ParseState) (minPrec : Nat) :
      Except String (Expr × ParseState) := do
    if p.curr == .Colon && minPrec <= 50 then
      let p := p.advance
      let (mid, p) ← parseExprPrec p 51
      if p.curr == .Colon then
        let p := p.advance
        let (stop, p) ← parseExprPrec p 51
        parseInfix (.range lhs (some mid) stop) p minPrec
      else
        parseInfix (.range lhs none mid) p minPrec
    else
    match infixPrec p.curr with
    | none => return (lhs, p)
    | some (prec, op) =>
        if prec < minPrec then return (lhs, p)
        else
          let nextPrec := if isRightAssoc op then prec else prec + 1
          let (rhs, p) ← parseExprPrec p.advance nextPrec
          parseInfix (.binop op lhs rhs) p minPrec

  partial def parsePostfix (p : ParseState) : Except String (Expr × ParseState) := do
    let (base, p) ← parsePrimary p
    parsePostfixOps base p

  partial def parsePostfixOps (e : Expr) (p : ParseState) :
      Except String (Expr × ParseState) := do
    match p.curr with
    | .LParen =>
        let p := p.advance
        let (args, p) ← parseArgList p
        let p ← p.expect .RParen
        parsePostfixOps (.index e args) p
    | .LBrace =>
        -- cell indexing: A{i} is like A(i) but always extracts the value
        let p := p.advance
        let (args, p) ← parseArgList p
        let p ← p.expect .RBrace
        parsePostfixOps (.index e args) p
    | .Dot =>
        match p.peek with
        | .Ident field => parsePostfixOps (.dotIndex e field) (p.advance.advance)
        | .LParen =>
            let p := p.advance.advance
            let (fe, p) ← parseExpr p
            let p ← p.expect .RParen
            parsePostfixOps (.dynField e fe) p
        | _ => return (e, p)
    | .HTranspose => parsePostfixOps (.unop .htranspose e) p.advance
    | .Transpose  => parsePostfixOps (.unop .transpose  e) p.advance
    | _ => return (e, p)

  partial def parseArgList (p : ParseState) : Except String (Array Arg × ParseState) := do
    if p.curr == .RParen then return (#[], p)
    let rec go (p : ParseState) (acc : Array Arg) :
        Except String (Array Arg × ParseState) := do
      if p.curr == .Colon && (p.peek == .Comma || p.peek == .RParen) then
        let acc := acc.push .colon
        if p.curr == .Comma then go p.advance.advance acc
        else return (acc, p.advance)
      else
        let (e, p) ← parseExpr p
        let acc := acc.push (.pos e)
        if p.curr == .Comma then go p.advance acc
        else return (acc, p)
    go p #[]

  partial def parsePrimary (p : ParseState) : Except String (Expr × ParseState) := do
    match p.curr with
    | .LitFloat f => return (.lit (.float f), p.advance)
    | .LitInt   n => return (.lit (.int n),   p.advance)
    | .LitStr   s => return (.lit (.str s),   p.advance)
    | .KwEnd      => return (.endIdx,          p.advance)
    | .Ident n    => return (.ident n,          p.advance)
    | .LParen =>
        let p := p.advance
        let (e, p) ← parseExpr p
        let p ← p.expect .RParen
        return (e, p)
    | .At    => parseAnonOrHandle p
    | .LBracket => parseMatrixLiteral p
    | .LBrace   => parseCellLiteral   p
    | k => throw s!"unexpected token {reprStr k} at line {p.currTok.line}"

  partial def parseAnonOrHandle (p : ParseState) : Except String (Expr × ParseState) := do
    let p := p.advance  -- '@'
    match p.curr with
    | .LParen =>
        let p := p.advance
        let (params, p) ← parseParamList p
        let p ← p.expect .RParen
        let (body, p) ← parseExpr p
        return (.anon params body, p)
    | .Ident n => return (.fnHandle n, p.advance)
    | k => throw s!"expected identifier or '(' after @, got {reprStr k}"

  partial def parseMatrixLiteral (p : ParseState) : Except String (Expr × ParseState) := do
    let p := p.advance  -- '['
    let (rows, p) ← parseMatrixRows p .RBracket
    let p ← p.expect .RBracket
    return (.matrix rows, p)

  partial def parseCellLiteral (p : ParseState) : Except String (Expr × ParseState) := do
    let p := p.advance  -- '{'
    let (rows, p) ← parseMatrixRows p .RBrace
    let p ← p.expect .RBrace
    return (.cellArr rows, p)

  partial def parseMatrixRows (p : ParseState) (closer : TokenKind) :
      Except String (Array (Array Expr) × ParseState) := do
    let p := p.skipNL
    if p.curr == closer then return (#[], p)
    let (row, p) ← parseMatrixRow p closer
    let p := if p.curr == .Semi || p.curr == .Newline then p.advance else p
    let (rest, p) ← parseMatrixRows p closer
    return (#[row] ++ rest, p)

  partial def parseMatrixRow (p : ParseState) (closer : TokenKind) :
      Except String (Array Expr × ParseState) := do
    let rec go (p : ParseState) (acc : Array Expr) :
        Except String (Array Expr × ParseState) := do
      if p.curr == closer || p.curr == .Semi || p.curr == .Newline || p.curr == .Eof
      then return (acc, p)
      let (e, p) ← parseExpr p
      let p := if p.curr == .Comma then p.advance else p
      go p (acc.push e)
    go p #[]

end

/-- Parse a complete Octave source string into an array of statements. -/
def parse (src : String) : Except String (Array Stmt) := do
  let tokens ← tokenize src
  let ps : ParseState := { tokens, pos := 0 }
  let ps := ps.skipStmtEnd
  let (stmts, _) ← parseBlock ps
  return stmts

end OctiveLean
