import OctiveLean.AST

namespace OctiveLean

/-- Integer variants matching Octave's int8/16/32/64, uint8/16/32/64 -/
inductive IntValue where
  | i8  : Int8   → IntValue
  | i16 : Int16  → IntValue
  | i32 : Int32  → IntValue
  | i64 : Int64  → IntValue
  | u8  : UInt8  → IntValue
  | u16 : UInt16 → IntValue
  | u32 : UInt32 → IntValue
  | u64 : UInt64 → IntValue
  deriving Repr

def IntValue.toFloat : IntValue → Float
  | .i8  x => Float.ofInt x.toInt
  | .i16 x => Float.ofInt x.toInt
  | .i32 x => Float.ofInt x.toInt
  | .i64 x => Float.ofInt x.toInt
  | .u8  x => Float.ofNat x.toNat
  | .u16 x => Float.ofNat x.toNat
  | .u32 x => Float.ofNat x.toNat
  | .u64 x => Float.ofNat x.toNat

def IntValue.display : IntValue → String
  | .i8  x => toString x
  | .i16 x => toString x
  | .i32 x => toString x
  | .i64 x => toString x
  | .u8  x => toString x
  | .u16 x => toString x
  | .u32 x => toString x
  | .u64 x => toString x

/-! Runtime values (Value ↔ FuncVal ↔ UserFunc are mutually recursive via closures) -/

mutual

  /-- The universal Octave runtime value -/
  inductive Value where
    | scalar   : Float → Value
    | fscalar  : Float → Value                      -- float32 scalar
    | complex  : Float → Float → Value              -- re, im (double)
    | integer  : IntValue → Value
    | boolean  : Bool → Value
    | matrix   : Nat → Nat → Array Float → Value    -- rows cols data (row-major)
    | cmatrix  : Nat → Nat → Array Float → Value    -- complex: [re0 im0 re1 im1 ...]
    | boolMat  : Nat → Nat → Array Bool → Value
    | string   : String → Value
    | cell     : Nat → Nat → Array Value → Value    -- rows cols data
    | struct   : Array (String × Value) → Value
    | fn       : FuncVal → Value
    | range    : Float → Float → Float → Value      -- start step stop (lazy)
    | empty    : Value                              -- []

  /-- A callable function value -/
  inductive FuncVal where
    | builtin  : String → FuncVal              -- name → registry lookup at call time
    | userDef  : UserFunc → FuncVal
    | anon     : Array String → Expr → Array (String × Value) → FuncVal
    | handle   : String → FuncVal             -- @ident

  /-- A user-defined function with its captured closure -/
  inductive UserFunc where
    | mk :
        (name    : String) →
        (params  : Array String) →
        (retVals : Array String) →
        (body    : Array Stmt) →
        (closure : Array (String × Value)) →
        UserFunc

end

namespace UserFunc
  def name    : UserFunc → String                  | .mk n _ _ _ _ => n
  def params  : UserFunc → Array String            | .mk _ p _ _ _ => p
  def retVals : UserFunc → Array String            | .mk _ _ r _ _ => r
  def body    : UserFunc → Array Stmt              | .mk _ _ _ b _ => b
  def closure : UserFunc → Array (String × Value)  | .mk _ _ _ _ c => c
end UserFunc

instance : Inhabited Value := ⟨.empty⟩

/-- Quick type-name for error messages (avoids needing Repr) -/
def Value.typeName : Value → String
  | .scalar _ | .fscalar _        => "double"
  | .complex _ _                  => "complex"
  | .integer _                    => "integer"
  | .boolean _                    => "logical"
  | .matrix _ _ _                 => "matrix"
  | .cmatrix _ _ _                => "complex matrix"
  | .boolMat _ _ _                => "logical array"
  | .string _                     => "string"
  | .cell _ _ _                   => "cell"
  | .struct _                     => "struct"
  | .fn _                         => "function_handle"
  | .range _ _ _                  => "range"
  | .empty                        => "[]"

/-! Utility functions -/

/-- Expand a lazy range to an Array of Floats. -/
def Value.rangeToArray (start step stop : Float) : Array Float :=
  if step == 0.0 then #[]
  else
    let rawN := ((stop - start) / step).floor + 1.0
    if rawN <= 0.0 then #[]
    else
      let n := rawN.toUInt64.toNat
      Id.run do
        let mut arr : Array Float := Array.mkEmpty n
        let mut x := start
        for _ in List.range n do
          arr := arr.push x
          x := x + step
        arr

/-- Materialise a Value.range to a row-vector matrix -/
def Value.materialize : Value → Value
  | .range s step e =>
      let data := Value.rangeToArray s step e
      if data.isEmpty then .empty
      else .matrix 1 data.size data
  | v => v

/-- Shape of a value as (rows, cols) -/
def Value.shape : Value → Nat × Nat
  | .scalar _       => (1, 1)
  | .fscalar _      => (1, 1)
  | .complex _ _    => (1, 1)
  | .integer _      => (1, 1)
  | .boolean _      => (1, 1)
  | .matrix r c _   => (r, c)
  | .cmatrix r c _  => (r, c)
  | .boolMat r c _  => (r, c)
  | .string s       => (1, s.length)
  | .cell r c _     => (r, c)
  | .struct _       => (1, 1)
  | .fn _           => (1, 1)
  | .range s st e   => (1, (Value.rangeToArray s st e).size)
  | .empty          => (0, 0)

/-- Format a Float as Octave does: no trailing .0 for integers, reasonable precision -/
def formatFloat (f : Float) : String :=
  -- Use 4 significant figures for display like Octave's default format short
  if f == f.floor && f.abs < 1e15 then
    -- integer-valued float: show without decimal
    let n := f.toUInt64
    if f < 0.0 then "-" ++ toString ((-f).toUInt64)
    else toString n
  else
    toString f

private def padLeft (width : Nat) (c : Char) (s : String) : String :=
  let pad := width - s.length
  if pad > 0 then String.ofList (List.replicate pad c) ++ s else s

/-- Format a matrix row for display -/
private def fmtRow (data : Array Float) (cols : Nat) (row : Nat) : String :=
  let elems := List.range cols |>.map fun j =>
    let v := data[row * cols + j]!
    padLeft 10 ' ' (formatFloat v)
  String.intercalate "" elems

/-- Human-readable display (mirrors Octave's console output style) -/
def Value.display (name : String) : Value → String
  | .scalar f    => s!"{name} = {formatFloat f}"
  | .fscalar f   => s!"{name} = {formatFloat f} (single)"
  | .complex r i =>
      if i >= 0.0 then s!"{name} = {formatFloat r} + {formatFloat i}i"
      else              s!"{name} = {formatFloat r} - {formatFloat (-i)}i"
  | .integer v   => s!"{name} = {v.display}"
  | .boolean b   => s!"{name} = {if b then 1 else 0}"
  | .matrix r c d =>
      if r == 0 || c == 0 then s!"{name} = [](0x0)"
      else if r == 1 && c == 1 then s!"{name} = {formatFloat d[0]!}"
      else
        let rows := List.range r |>.map (fmtRow d c)
        s!"{name} =\n\n{String.intercalate "\n" rows}\n"
  | .boolMat r c d =>
      let rows := List.range r |>.map fun i =>
        let elems := List.range c |>.map fun j =>
          padLeft 4 ' ' (if d[i * c + j]! then "1" else "0")
        String.intercalate "" elems
      s!"{name} =\n\n{String.intercalate "\n" rows}\n"
  | .string s    => s!"{name} = {s}"
  | .cell r c _  => s!"{name} = <{r}x{c} cell>"
  | .struct fs   =>
      let fieldNames := fs.toList.map (·.1) |> String.intercalate ", "
      s!"{name} = <struct: {fieldNames}>"
  | .fn (.builtin n)   => s!"{name} = @{n} [builtin]"
  | .fn (.userDef f)   => s!"{name} = @{f.name}"
  | .fn (.anon ps _ _) =>
      let args := ps.toList |> String.intercalate ", "
      s!"{name} = @({args}) [anon]"
  | .fn (.handle n)    => s!"{name} = @{n}"
  | .range s st e =>
      let data := Value.rangeToArray s st e
      if data.isEmpty then s!"{name} = [](0x0)"
      else
        let elems := data.toList.map formatFloat |> String.intercalate "   "
        s!"{name} =\n\n   {elems}\n"
  | .empty => s!"{name} = [](0x0)"
  | .cmatrix r c _ => s!"{name} = <{r}x{c} complex matrix>"

/-- Format a value for disp/print — no "name = " prefix -/
def Value.printStr : Value → String
  | .scalar f | .fscalar f  => formatFloat f
  | .complex r i =>
      if i >= 0.0 then s!"{formatFloat r} + {formatFloat i}i"
      else              s!"{formatFloat r} - {formatFloat (-i)}i"
  | .integer v   => v.display
  | .boolean b   => if b then "1" else "0"
  | .matrix r c d =>
      if r == 0 || c == 0 then "[](0x0)"
      else if r == 1 && c == 1 then formatFloat d[0]!
      else
        let rows := List.range r |>.map (fmtRow d c)
        s!"\n{String.intercalate "\n" rows}\n"
  | .boolMat r c d =>
      let rows := List.range r |>.map fun i =>
        let elems := List.range c |>.map fun j =>
          padLeft 4 ' ' (if d[i * c + j]! then "1" else "0")
        String.intercalate "" elems
      s!"\n{String.intercalate "\n" rows}\n"
  | .string s    => s
  | v => v.display ""

end OctiveLean
