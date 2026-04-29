import OctiveLean.Error

namespace OctiveLean

/-! Token kinds -/

inductive TokenKind where
  -- Literals
  | LitInt    : Int    → TokenKind
  | LitFloat  : Float  → TokenKind
  | LitStr    : String → TokenKind
  -- Identifiers
  | Ident     : String → TokenKind
  -- Keywords
  | KwFor | KwWhile | KwDo | KwUntil
  | KwIf | KwElseif | KwElse
  | KwEnd | KwEndfor | KwEndwhile | KwEndif | KwEndfunction
  | KwFunction | KwReturn | KwBreak | KwContinue
  | KwSwitch | KwCase | KwOtherwise | KwEndswitch
  | KwTry | KwCatch | KwEndTryCatch
  | KwUnwindProtect | KwUnwindProtectCleanup | KwEndUnwindProtect
  | KwGlobal | KwPersistent | KwClear
  -- Arithmetic operators
  | Plus | Minus | Star | Slash | Backslash | Caret
  | DotStar | DotSlash | DotBackslash | DotCaret
  -- Comparison
  | Lt | Le | Gt | Ge | EqEq | Neq | TildeEq
  -- Logical
  | Amp | Pipe | AmpAmp | PipePipe | Tilde | Bang
  -- Assignment operators
  | Eq | PlusEq | MinusEq | StarEq | SlashEq | CaretEq
  -- Postfix
  | Transpose | HTranspose   -- .'  and '
  -- Punctuation
  | LParen | RParen
  | LBracket | RBracket
  | LBrace | RBrace
  | Comma | Semi | Colon | Dot | At
  -- Statement terminators
  | Newline
  | Eof
  deriving Repr, BEq

structure Token where
  kind : TokenKind
  line : Nat
  col  : Nat
  deriving Repr

instance : Inhabited Token := ⟨{ kind := .Eof, line := 0, col := 0 }⟩

/-! Lexer state -/

private structure LexState where
  chars            : Array Char  -- source as char array for O(1) indexing
  pos              : Nat
  line             : Nat
  col              : Nat
  matDepth         : Nat          -- depth of '[' nesting
  prevCanTranspose : Bool         -- last token permits ' → transpose

private def LexState.fromSrc (src : String) : LexState :=
  { chars := src.toList.toArray, pos := 0, line := 1, col := 1,
    matDepth := 0, prevCanTranspose := false }

private def LexState.curr (s : LexState) : Option Char :=
  if s.pos < s.chars.size then some s.chars[s.pos]! else none

private def LexState.peek (s : LexState) (offset : Nat := 1) : Option Char :=
  let i := s.pos + offset
  if i < s.chars.size then some s.chars[i]! else none

private def LexState.advance (s : LexState) : LexState :=
  match s.curr with
  | some '\n' => { s with pos := s.pos + 1, line := s.line + 1, col := 1 }
  | some _    => { s with pos := s.pos + 1, col := s.col + 1 }
  | none      => s

private def LexState.advanceN (s : LexState) (n : Nat) : LexState :=
  List.range n |>.foldl (fun acc _ => acc.advance) s

private def LexState.slice (s : LexState) (start stop : Nat) : String :=
  String.ofList (s.chars.toList.drop start |>.take (stop - start))

/-! Keyword table -/

private def keyword? (w : String) : Option TokenKind :=
  match w with
  | "for"       => some .KwFor       | "while"     => some .KwWhile
  | "do"        => some .KwDo        | "until"     => some .KwUntil
  | "if"        => some .KwIf        | "elseif"    => some .KwElseif
  | "else"      => some .KwElse
  | "end"       => some .KwEnd       | "endfor"    => some .KwEndfor
  | "endwhile"  => some .KwEndwhile  | "endif"     => some .KwEndif
  | "endfunction" => some .KwEndfunction
  | "function"  => some .KwFunction  | "return"    => some .KwReturn
  | "break"     => some .KwBreak     | "continue"  => some .KwContinue
  | "switch"    => some .KwSwitch    | "case"      => some .KwCase
  | "otherwise" => some .KwOtherwise | "endswitch" => some .KwEndswitch
  | "try"       => some .KwTry       | "catch"     => some .KwCatch
  | "end_try_catch"          => some .KwEndTryCatch
  | "unwind_protect"         => some .KwUnwindProtect
  | "unwind_protect_cleanup" => some .KwUnwindProtectCleanup
  | "end_unwind_protect"     => some .KwEndUnwindProtect
  | "global"     => some .KwGlobal   | "persistent" => some .KwPersistent
  | "clear"      => some .KwClear
  | _            => none

/-! Recursive lexer helpers — all marked `partial` since Lean can't prove
    termination through the LexState wrapper without significant effort. -/

private partial def skipHorizWS (s : LexState) : LexState :=
  match s.curr with
  | some ' ' | some '\t' | some '\r' => skipHorizWS s.advance
  | _ => s

private partial def skipLineComment (s : LexState) : LexState :=
  match s.curr with
  | some '\n' | none => s
  | _                => skipLineComment s.advance

private partial def skipBlockComment (s : LexState) : LexState :=
  match s.curr with
  | none      => s
  | some '%'  => if s.peek == some '}' then s.advanceN 2
                 else skipBlockComment s.advance
  | _         => skipBlockComment s.advance

private partial def skipLineContinuation (s : LexState) : LexState :=
  match s.curr with
  | some '\n' | none => s.advance
  | _                => skipLineContinuation s.advance

/-! Number parsing -/

private partial def eatDigits (s : LexState) : LexState × String :=
  let start := s.pos
  let rec go (st : LexState) : LexState :=
    match st.curr with
    | some c => if c.isDigit then go st.advance else st
    | none   => st
  let st := go s
  (st, s.slice start st.pos)

-- Build a float from separate integer, fractional, sign, and exponent strings.
private def buildFloat (intStr fracStr : String) (negExp : Bool) (expStr : String) : Float :=
  let iv  := Float.ofNat (intStr.toNat? |>.getD 0)
  let fv  := if fracStr.isEmpty then 0.0
             else Float.ofNat (fracStr.toNat? |>.getD 0) /
                  Float.ofNat (10 ^ fracStr.length)
  let ev  := expStr.toNat? |>.getD 0
  let mlt := Float.ofNat (10 ^ ev)
  let base := iv + fv
  if negExp then base / mlt else base * mlt

private def lexNumber (s : LexState) : LexState × TokenKind :=
  let (s1, intStr) := eatDigits s
  -- optional '.' followed by more digits
  let (s2, fracStr, hasDot) :=
    if s1.curr == some '.' then
      -- make sure it's not '..' range or '.*' etc.
      let nextOk := match s1.peek with
        | some '.' | some '*' | some '/' | some '\\' | some '^' | some '\'' => false
        | _ => true
      if nextOk then
        let (s1', fs) := eatDigits s1.advance
        (s1', fs, true)
      else (s1, "", false)
    else (s1, "", false)
  -- optional exponent
  let (s3, negExp, expStr, hasExp) :=
    match s2.curr with
    | some 'e' | some 'E' =>
        let s2' := s2.advance
        let (neg, s2'') := match s2'.curr with
          | some '-' => (true,  s2'.advance)
          | some '+' => (false, s2'.advance)
          | _        => (false, s2')
        let (s2''', es) := eatDigits s2''
        (s2''', neg, es, true)
    | _ => (s2, false, "", false)
  if hasDot || hasExp then
    (s3, .LitFloat (buildFloat intStr fracStr negExp expStr))
  else
    (s3, .LitInt (intStr.toInt? |>.getD 0))

/-! String lexing -/

private partial def lexSQString (s : LexState) : LexState × String :=
  let rec go (st : LexState) (acc : String) : LexState × String :=
    match st.curr with
    | none | some '\n' => (st, acc)
    | some '\'' =>
        if st.peek == some '\'' then go (st.advanceN 2) (acc.push '\'')
        else (st.advance, acc)
    | some c => go st.advance (acc.push c)
  go s ""

private partial def lexDQString (s : LexState) : LexState × String :=
  let rec go (st : LexState) (acc : String) : LexState × String :=
    match st.curr with
    | none | some '"' => (st.advance, acc)
    | some '\\' =>
        let c := match st.peek with
          | some 'n'  => '\n' | some 't'  => '\t' | some 'r'  => '\r'
          | some '\'' => '\'' | some '"'  => '"'  | some '\\' => '\\'
          | some '0'  => '\x00'
          | _         => '\\'
        go (st.advanceN 2) (acc.push c)
    | some c => go st.advance (acc.push c)
  go s ""

/-! Token emission helpers -/

private def transposePrev : TokenKind → Bool
  | .Ident _ | .LitInt _ | .LitFloat _ | .RParen | .RBracket | .RBrace
  | .Transpose | .HTranspose => true
  | _ => false

/-! Main tokeniser — partial since it advances through an arbitrary string -/

private partial def tokenizeFrom (s : LexState) (acc : Array Token) :
    Except String (Array Token) :=
  let s  := skipHorizWS s
  let ln := s.line
  let cl := s.col
  let emit (k : TokenKind) (s' : LexState) :=
    tokenizeFrom { s' with prevCanTranspose := transposePrev k }
      (acc.push { kind := k, line := ln, col := cl })
  let emitNoPrev (k : TokenKind) (s' : LexState) :=
    tokenizeFrom { s' with prevCanTranspose := false }
      (acc.push { kind := k, line := ln, col := cl })
  match s.curr with
  | none => .ok (acc.push { kind := .Eof, line := ln, col := cl })
  | some c =>
    match c with
    -- Comments
    | '%' =>
        if s.peek == some '{' then tokenizeFrom (skipBlockComment (s.advanceN 2)) acc
        else tokenizeFrom (skipLineComment s.advance) acc
    | '#' => tokenizeFrom (skipLineComment s.advance) acc
    -- Newlines (statement separators, collapse runs)
    | '\n' =>
        let acc' := match acc.back? with
          | some t =>
            match t.kind with
            | .Newline | .Semi | .Comma | .LBracket | .LBrace | .LParen
            | .Plus | .Minus | .Star | .Slash | .Backslash | .Caret
            | .DotStar | .DotSlash | .DotCaret | .Eq | .Colon
            | .AmpAmp | .PipePipe | .Amp | .Pipe
            | .KwElse | .KwElseif | .KwFor | .KwWhile | .KwDo
            | .KwIf | .KwSwitch | .KwCase | .KwFunction
            | .KwOtherwise | .KwTry | .KwCatch
            | .KwUnwindProtect | .KwUnwindProtectCleanup => acc
            | _ => acc.push { kind := .Newline, line := ln, col := cl }
          | none => acc
        tokenizeFrom s.advance acc'
    -- Numbers
    | d =>
      if d.isDigit then
        let (s', k) := lexNumber s
        tokenizeFrom { s' with prevCanTranspose := true }
          (acc.push { kind := k, line := ln, col := cl })
      -- Identifiers / keywords
      else if d.isAlpha || d == '_' then
        let start := s.pos
        let rec eatId (st : LexState) : LexState :=
          match st.curr with
          | some x => if x.isAlphanum || x == '_' then eatId st.advance else st
          | none   => st
        let s' := eatId s
        let word := s.slice start s'.pos
        let k := keyword? word |>.getD (.Ident word)
        tokenizeFrom { s' with prevCanTranspose := transposePrev k }
          (acc.push { kind := k, line := ln, col := cl })
      else
      -- Everything else: single/multi-char tokens
      match c with
      | '\'' =>
          if s.prevCanTranspose then emit .HTranspose s.advance
          else
            let (s', str) := lexSQString s.advance
            emitNoPrev (.LitStr str) s'
      | '"' =>
          let (s', str) := lexDQString s.advance
          emitNoPrev (.LitStr str) s'
      | '.' =>
          if s.peek == some '.' && s.peek (offset := 2) == some '.' then
            tokenizeFrom (skipLineContinuation (s.advanceN 3)) acc
          else if s.peek == some '\'' then emitNoPrev .Transpose (s.advanceN 2)
          else if s.peek == some '*'  then emitNoPrev .DotStar   (s.advanceN 2)
          else if s.peek == some '/'  then emitNoPrev .DotSlash  (s.advanceN 2)
          else if s.peek == some '\\' then emitNoPrev .DotBackslash (s.advanceN 2)
          else if s.peek == some '^'  then emitNoPrev .DotCaret  (s.advanceN 2)
          else emitNoPrev .Dot s.advance
      | '+' =>
          if s.peek == some '=' then emitNoPrev .PlusEq  (s.advanceN 2)
          else                       emitNoPrev .Plus    s.advance
      | '-' =>
          if s.peek == some '=' then emitNoPrev .MinusEq (s.advanceN 2)
          else                       emitNoPrev .Minus   s.advance
      | '*' =>
          if s.peek == some '=' then emitNoPrev .StarEq  (s.advanceN 2)
          else                       emitNoPrev .Star    s.advance
      | '/' =>
          if s.peek == some '=' then emitNoPrev .SlashEq (s.advanceN 2)
          else                       emitNoPrev .Slash   s.advance
      | '\\' =>                      emitNoPrev .Backslash s.advance
      | '^' =>
          if s.peek == some '=' then emitNoPrev .CaretEq  (s.advanceN 2)
          else                       emitNoPrev .Caret   s.advance
      | '<' =>
          if s.peek == some '=' then emitNoPrev .Le (s.advanceN 2)
          else                       emitNoPrev .Lt s.advance
      | '>' =>
          if s.peek == some '=' then emitNoPrev .Ge (s.advanceN 2)
          else                       emitNoPrev .Gt s.advance
      | '=' =>
          if s.peek == some '=' then emitNoPrev .EqEq (s.advanceN 2)
          else                       emitNoPrev .Eq   s.advance
      | '!' =>
          if s.peek == some '=' then emitNoPrev .Neq  (s.advanceN 2)
          else                       emitNoPrev .Bang s.advance
      | '~' =>
          if s.peek == some '=' then emitNoPrev .TildeEq (s.advanceN 2)
          else                       emitNoPrev .Tilde   s.advance
      | '&' =>
          if s.peek == some '&' then emitNoPrev .AmpAmp (s.advanceN 2)
          else                       emitNoPrev .Amp    s.advance
      | '|' =>
          if s.peek == some '|' then emitNoPrev .PipePipe (s.advanceN 2)
          else                       emitNoPrev .Pipe     s.advance
      | '@' => emitNoPrev .At s.advance
      | '(' => emitNoPrev .LParen  s.advance
      | ')' => emit     .RParen  s.advance
      | '[' =>
          tokenizeFrom { s.advance with prevCanTranspose := false,
                                        matDepth := s.matDepth + 1 }
            (acc.push { kind := .LBracket, line := ln, col := cl })
      | ']' =>
          tokenizeFrom { s.advance with prevCanTranspose := true,
                                        matDepth := s.matDepth - min s.matDepth 1 }
            (acc.push { kind := .RBracket, line := ln, col := cl })
      | '{' => emitNoPrev .LBrace s.advance
      | '}' => emit     .RBrace s.advance
      | ',' => emitNoPrev .Comma s.advance
      | ';' =>
          let acc' := match acc.back? with
            | some t =>
              match t.kind with
              | .Newline => acc.set! (acc.size - 1) { kind := .Semi, line := ln, col := cl }
              | .Semi    => acc
              | _        => acc.push { kind := .Semi, line := ln, col := cl }
            | none => acc.push { kind := .Semi, line := ln, col := cl }
          tokenizeFrom { s.advance with prevCanTranspose := false } acc'
      | ':' => emitNoPrev .Colon s.advance
      -- skip unrecognised chars (BOM etc.)
      | _   => tokenizeFrom s.advance acc

/-- Tokenise an Octave source string. -/
def tokenize (src : String) : Except String (Array Token) :=
  tokenizeFrom (LexState.fromSrc src) #[]

end OctiveLean
