namespace OctiveLean

/-! Operators -/

inductive BinOp where
  -- arithmetic
  | add | sub | mul | div | ldiv | pow
  -- element-wise
  | emul | ediv | eldiv | epow
  -- comparison
  | lt | le | gt | ge | eq | ne
  -- bitwise / logical
  | band | bor | land | lor
  deriving Repr, BEq, Inhabited

inductive UnOp where
  | neg | uplus | lnot | transpose | htranspose
  deriving Repr, BEq, Inhabited

/-! Literals -/

inductive Literal where
  | float  : Float  → Literal
  | int    : Int    → Literal
  | str    : String → Literal
  | bool   : Bool   → Literal
  deriving Repr, BEq

/-! AST (mutually recursive: Expr ↔ Arg, Stmt ↔ FuncDef) -/

mutual

  /-- An Octave expression -/
  inductive Expr where
    | lit       : Literal → Expr
    | ident     : String → Expr
    | binop     : BinOp → Expr → Expr → Expr
    | unop      : UnOp → Expr → Expr
    | index     : Expr → Array Arg → Expr       -- f(a,b) or A(i,j)
    | dotIndex  : Expr → String → Expr          -- s.field
    | dynField  : Expr → Expr → Expr            -- s.(expr)
    | matrix    : Array (Array Expr) → Expr     -- [a b; c d]
    | cellArr   : Array (Array Expr) → Expr     -- {a b; c d}
    | range     : Expr → Option Expr → Expr → Expr  -- a:b  or  a:step:b
    | fnHandle  : String → Expr                 -- @name
    | anon      : Array String → Expr → Expr    -- @(x,y) expr
    | endIdx    : Expr                          -- 'end' inside index
    | colonIdx  : Expr                          -- bare ':' inside index

  /-- An argument in a call or index expression -/
  inductive Arg where
    | pos    : Expr → Arg     -- positional expression
    | colon  : Arg            -- bare :
    | kw     : String → Expr → Arg   -- name = value (not standard Octave but useful)

  /-- A statement -/
  inductive Stmt where
    | exprS     : Expr → Bool → Stmt              -- expr; silent?
    | assign    : Array String → Expr → Bool → Stmt     -- [a,b]=rhs  silent?
    | indexAssign : Expr → Expr → Bool → Stmt          -- lhs(...)=rhs / lhs.f=rhs
    | ifS       : Expr → Array Stmt
                  → Array (Expr × Array Stmt)
                  → Option (Array Stmt) → Stmt
    | forS      : String → Expr → Array Stmt → Stmt
    | whileS    : Expr → Array Stmt → Stmt
    | doUntil   : Array Stmt → Expr → Stmt
    | returnS   : Stmt
    | breakS    : Stmt
    | continueS : Stmt
    | funcDefS  : FuncDef → Stmt
    | switchS   : Expr
                  → Array (Expr × Array Stmt)
                  → Option (Array Stmt) → Stmt
    | tryS      : Array Stmt → Option (String × Array Stmt) → Stmt
    | globalS   : Array String → Stmt
    | persistS  : Array String → Stmt
    | clearS    : Array String → Stmt
    | unwindS   : Array Stmt → Array Stmt → Stmt

  /-- A function definition (name, params, return vars, body) -/
  inductive FuncDef where
    | mk : String → Array String → Array String → Array Stmt → FuncDef

end

namespace FuncDef
  def name    : FuncDef → String       | .mk n _ _ _ => n
  def params  : FuncDef → Array String | .mk _ p _ _ => p
  def retVals : FuncDef → Array String | .mk _ _ r _ => r
  def body    : FuncDef → Array Stmt   | .mk _ _ _ b => b
end FuncDef

end OctiveLean
