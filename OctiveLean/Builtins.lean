import OctiveLean.Value
import OctiveLean.Env
import OctiveLean.Error

namespace OctiveLean

/-! Built-in function implementations
    Every lambda is explicitly typed `Array Value → IO (Array Value)` so that
    dot-notation patterns resolve unambiguously. -/

-- Lean 4.30 does not expose Float.nan or String.toFloat?; define them here.
private def floatNaN : Float := 0.0 / 0.0
private def floatTrunc (x : Float) : Float :=
  if x >= 0.0 then Float.floor x else Float.ceil x

private def parseFloatStr? (s : String) : Option Float :=
  -- Try integer first (covers "42"), then give up (full float parsing would
  -- require the Lexer; this stub covers the most common str2double cases).
  match s.toInt? with
  | some n => some (Float.ofInt n)
  | none   =>
    -- Very simple: split on '.' and rebuild
    let parts := s.splitOn "."
    match parts with
    | [intPart, fracPart] =>
        match intPart.toInt?, fracPart.toNat? with
        | some iv, some fv =>
            let fBase := Float.ofNat (10 ^ fracPart.length)
            let base := Float.ofInt iv + Float.ofNat fv / fBase
            some (if intPart.startsWith "-" then -base else base)
        | _, _ => none
    | _ => none

private def asFloat (name : String) (v : Value) : IO Float :=
  match v.materialize with
  | .scalar f | .fscalar f => return f
  | .integer iv => return iv.toFloat
  | .boolean b  => return if b then 1.0 else 0.0
  | .matrix 1 1 d => return d[0]!
  | _ => throw (IO.userError s!"{name}: expected scalar, got {v.typeName}")

private def asNat (name : String) (v : Value) : IO Nat := do
  let f ← asFloat name v; return f.toUInt64.toNat

private def arrFill (n : Nat) (v : Float) : Array Float :=
  List.replicate n v |>.toArray

private def mkZerosV (rows cols : Nat) : Value :=
  .matrix rows cols (arrFill (rows * cols) 0.0)

private def mkOnesV (rows cols : Nat) : Value :=
  .matrix rows cols (arrFill (rows * cols) 1.0)

private def mkEyeV (n : Nat) : Value :=
  let data := Id.run do
    let mut d := arrFill (n * n) 0.0
    for i in List.range n do d := d.set! (i * n + i) 1.0
    d
  .matrix n n data

private def flattenV (v : Value) : Array Float :=
  match v.materialize with
  | .matrix _ _ d  => d
  | .scalar f      => #[f]
  | .integer iv    => #[iv.toFloat]
  | .boolean b     => #[if b then 1.0 else 0.0]
  | .range s st e  => Value.rangeToArray s st e
  | _              => #[]

-- Short alias for the builtin function type
private abbrev BFn := Array Value → IO (Array Value)

-- Apply Float→Float to scalar or element-wise to a matrix
private def applyU (name : String) (f : Float → Float) : BFn := fun args => do
  if args.isEmpty then throw (IO.userError s!"{name}: expected 1 arg")
  match args[0]!.materialize with
  | .scalar x     => return #[Value.scalar (f x)]
  | .matrix r c d => return #[Value.matrix r c (d.map f)]
  | .integer iv   => return #[Value.scalar (f iv.toFloat)]
  | .boolean b    => return #[Value.scalar (f (if b then 1.0 else 0.0))]
  | other         => throw (IO.userError s!"{name}: expected numeric, got {other.typeName}")

-- Apply Float→Float→Float to two scalar/matrix args
private def applyB (name : String) (f : Float → Float → Float) : BFn := fun args => do
  if args.size < 2 then throw (IO.userError s!"{name}: expected 2 args")
  match args[0]!.materialize, args[1]!.materialize with
  | .scalar x, .scalar y => return #[Value.scalar (f x y)]
  | .matrix r c d1, .matrix _ _ d2 => return #[Value.matrix r c (Array.zipWith f d1 d2)]
  | .scalar x, .matrix r c d => return #[Value.matrix r c (d.map (f x ·))]
  | .matrix r c d, .scalar y  => return #[Value.matrix r c (d.map (f · y))]
  | la, lb => throw (IO.userError s!"{name}: unsupported {la.typeName} and {lb.typeName}")

-- Apply a format specifier with optional precision to a float
private def fmtFloat (spec : Char) (prec : Option Nat) (f : Float) : String :=
  let p := prec.getD (if spec == 'g' then 6 else 6)
  match spec with
  | 'f' =>
      -- fixed-point with p decimal places
      let scale := Float.ofNat (10 ^ p)
      let rounded := Float.round (f * scale) / scale
      let intPart := if rounded < 0.0 then (-rounded).floor else rounded.floor
      let fracPart := Float.round ((rounded - (if rounded < 0.0 then -intPart else intPart)) * scale)
      let intStr := if f < 0.0 then "-" ++ toString intPart.toUInt64 else toString intPart.toUInt64
      let fracStr := toString fracPart.toUInt64
      let fracPadded := String.ofList (List.replicate (p - fracStr.length) '0') ++ fracStr
      if p == 0 then intStr else intStr ++ "." ++ fracPadded
  | 'e' | 'E' =>
      -- scientific notation stub: use toString and reformat
      let s := toString f
      s  -- simplified: just use default toString
  | 'g' | 'G' =>
      -- use fixed if reasonable, else scientific
      if f.abs >= 1e-4 && f.abs < 1e6 then
        let scale := Float.ofNat (10 ^ p)
        let rounded := Float.round (f * scale) / scale
        let s := toString rounded
        s
      else toString f
  | _ => toString f

-- Format a printf-style format string with the given argument values
private partial def sprintfArgs (fmt : String) (vals : List Value) : String :=
  let chars := fmt.toList
  -- consume optional flags, width, precision before the spec char
  let rec parseSpec (cs : List Char) : (Option Nat × Char × List Char) :=
    -- skip flags: - + 0 space #
    let rec skipFlags : List Char → List Char
      | '-' :: rest | '+' :: rest | '0' :: rest | ' ' :: rest | '#' :: rest => skipFlags rest
      | cs => cs
    let cs := skipFlags cs
    -- read width digits
    let rec readDigits : List Char → String × List Char
      | c :: rest => if c.isDigit then let (s, r) := readDigits rest; (String.singleton c ++ s, r)
                     else ("", c :: rest)
      | [] => ("", [])
    let (_, cs) := readDigits cs  -- skip width (unused for now)
    -- read optional .precision
    let (prec, cs) := match cs with
      | '.' :: rest =>
          let (digits, rest') := readDigits rest
          (digits.toNat?, rest')
      | _ => (none, cs)
    match cs with
    | spec :: rest => (prec, spec, rest)
    | [] => (none, '?', [])
  let rec go (cs : List Char) (vs : List Value) (acc : String) : String :=
    match cs with
    | [] => acc
    | '%' :: rest =>
        let (prec, spec, rest') := parseSpec rest
        let (fmtd, vs') := match spec, vs with
          | 'd', v :: t | 'i', v :: t => (match v with
              | Value.scalar f => (toString f.toInt64, t)
              | Value.integer iv => (iv.display, t)
              | _ => ("0", t))
          | 'f', v :: t => (match v with
              | Value.scalar f => (fmtFloat 'f' prec f, t)
              | _ => ("0.0", t))
          | 'e', v :: t => (match v with
              | Value.scalar f => (fmtFloat 'e' prec f, t)
              | _ => ("0", t))
          | 'g', v :: t => (match v with
              | Value.scalar f => (fmtFloat 'g' prec f, t)
              | _ => ("0", t))
          | 's', v :: t => (match v with
              | Value.string s => (s, t)
              | vv => (vv.printStr, t))
          | 'c', v :: t => (match v with
              | Value.scalar f =>
                  let n := f.toUInt32
                  (String.singleton (Char.ofNat n.toNat), t)
              | _ => ("?", t))
          | '%', _ => ("%", vs)
          | c, _   => (String.singleton c, vs)
        go rest' vs' (acc ++ fmtd)
    | '\\' :: 'n' :: rest => go rest vs (acc ++ "\n")
    | '\\' :: 't' :: rest => go rest vs (acc ++ "\t")
    | '\\' :: '\\' :: rest => go rest vs (acc ++ "\\")
    | c :: rest => go rest vs (acc ++ String.singleton c)
  go chars vals ""

/-- Register all standard built-in functions. -/
def registerAllBuiltins (env : Env) : Env :=
  env
  -- ── Output ───────────────────────────────────────────────────────────────
  |>.registerBuiltin "disp" (fun (args : Array Value) => do
      for v in args do IO.println v.printStr
      return #[])
  |>.registerBuiltin "printf" (fun (args : Array Value) => do
      match args[0]? with
      | some (Value.string fmt) =>
          IO.print (sprintfArgs fmt (args.toList.drop 1))
      | _ => pure ()
      return #[])
  |>.registerBuiltin "fprintf" (fun (args : Array Value) => do
      -- skip a leading numeric file-descriptor if present
      let fmtList := match args[0]? with
        | some (Value.scalar _) => args.toList.drop 1 | _ => args.toList
      match fmtList with
      | Value.string fmt :: rest => IO.print (sprintfArgs fmt rest)
      | _ => pure ()
      return #[])
  -- ── Type queries ─────────────────────────────────────────────────────────
  |>.registerBuiltin "class" (fun (args : Array Value) => do
      match args[0]? with
      | some v =>
          let cls : String := match v with
            | .scalar _ | .fscalar _ | .complex _ _ | .matrix _ _ _
            | .cmatrix _ _ _ | .range _ _ _ | .empty => "double"
            | .integer (.i8 _)  => "int8"   | .integer (.i16 _) => "int16"
            | .integer (.i32 _) => "int32"  | .integer (.i64 _) => "int64"
            | .integer (.u8 _)  => "uint8"  | .integer (.u16 _) => "uint16"
            | .integer (.u32 _) => "uint32" | .integer (.u64 _) => "uint64"
            | .boolean _ | .boolMat _ _ _ => "logical"
            | .string _  => "char"   | .cell _ _ _ => "cell"
            | .struct _  => "struct" | .fn _ => "function_handle"
          return #[Value.string cls]
      | none => return #[Value.string "unknown"])
  |>.registerBuiltin "isnumeric" (fun (args : Array Value) => do
      return #[Value.boolean (match args[0]? with
        | some (Value.scalar _) | some (Value.fscalar _) | some (Value.matrix _ _ _) => true
        | _ => false)])
  |>.registerBuiltin "ischar" (fun (args : Array Value) => do
      return #[Value.boolean (match args[0]? with | some (Value.string _) => true | _ => false)])
  |>.registerBuiltin "islogical" (fun (args : Array Value) => do
      return #[Value.boolean (match args[0]? with
        | some (Value.boolean _) | some (Value.boolMat _ _ _) => true | _ => false)])
  |>.registerBuiltin "iscell" (fun (args : Array Value) => do
      return #[Value.boolean (match args[0]? with | some (Value.cell _ _ _) => true | _ => false)])
  |>.registerBuiltin "isstruct" (fun (args : Array Value) => do
      return #[Value.boolean (match args[0]? with | some (Value.struct _) => true | _ => false)])
  |>.registerBuiltin "isempty" (fun (args : Array Value) => do
      match args[0]? with
      | some Value.empty => return #[Value.boolean true]
      | some (Value.matrix r c _) | some (Value.cell r c _) =>
          return #[Value.boolean (r == 0 || c == 0)]
      | some (Value.string s) => return #[Value.boolean s.isEmpty]
      | none => return #[Value.boolean true]
      | _ => return #[Value.boolean false])
  -- ── Size / shape ─────────────────────────────────────────────────────────
  |>.registerBuiltin "size" (fun (args : Array Value) => do
      let v := args[0]?.getD Value.empty
      let (r, c) := v.shape
      if args.size >= 2 then
        let dim ← asNat "size" args[1]!
        return #[Value.scalar (if dim == 1 then Float.ofNat r else Float.ofNat c)]
      else
        return #[Value.matrix 1 2 #[Float.ofNat r, Float.ofNat c]])
  |>.registerBuiltin "length" (fun (args : Array Value) => do
      let (r, c) := (args[0]?.getD Value.empty).shape
      return #[Value.scalar (Float.ofNat (max r c))])
  |>.registerBuiltin "numel" (fun (args : Array Value) => do
      let (r, c) := (args[0]?.getD Value.empty).shape
      return #[Value.scalar (Float.ofNat (r * c))])
  |>.registerBuiltin "rows" (fun (args : Array Value) => do
      return #[Value.scalar (Float.ofNat (args[0]?.getD Value.empty).shape.1)])
  |>.registerBuiltin "columns" (fun (args : Array Value) => do
      return #[Value.scalar (Float.ofNat (args[0]?.getD Value.empty).shape.2)])
  -- ── Matrix constructors ───────────────────────────────────────────────────
  |>.registerBuiltin "zeros" (fun (args : Array Value) => do
      match args with
      | #[n]    => return #[mkZerosV (← asNat "zeros" n) (← asNat "zeros" n)]
      | #[r, c] => return #[mkZerosV (← asNat "zeros" r) (← asNat "zeros" c)]
      | _ => return #[mkZerosV 0 0])
  |>.registerBuiltin "ones" (fun (args : Array Value) => do
      match args with
      | #[n]    => return #[mkOnesV (← asNat "ones" n) (← asNat "ones" n)]
      | #[r, c] => return #[mkOnesV (← asNat "ones" r) (← asNat "ones" c)]
      | _ => return #[mkOnesV 0 0])
  |>.registerBuiltin "eye" (fun (args : Array Value) => do
      match args with
      | #[n] => return #[mkEyeV (← asNat "eye" n)]
      | _ => return #[mkEyeV 0])
  |>.registerBuiltin "rand" (fun (_ : Array Value) => return #[Value.scalar 0.5])
  |>.registerBuiltin "linspace" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "linspace: expected 2 args")
      let a ← asFloat "linspace" args[0]!; let b ← asFloat "linspace" args[1]!
      let n : Nat ← if args.size >= 3 then do
        let f ← asFloat "linspace" args[2]!; pure f.toUInt64.toNat
        else pure 100
      if n == 0 then return #[Value.empty]
      else if n == 1 then return #[Value.scalar b]
      else return #[Value.range a ((b - a) / Float.ofNat (n - 1)) b])
  -- ── Reshape / concat ─────────────────────────────────────────────────────
  |>.registerBuiltin "reshape" (fun (args : Array Value) => do
      if args.size < 3 then throw (IO.userError "reshape: expected 3 args")
      let data := flattenV args[0]!
      let r ← asNat "reshape" args[1]!; let c ← asNat "reshape" args[2]!
      if data.size != r * c then
        throw (IO.userError s!"reshape: {data.size} elements, {r*c} requested")
      return #[Value.matrix r c data])
  |>.registerBuiltin "horzcat" (fun (args : Array Value) => do
      if args.isEmpty then return #[Value.empty]
      let r := args[0]!.shape.1
      if args.any (·.shape.1 != r) then
        throw (IO.userError "horzcat: inconsistent row counts")
      let totalCols := args.foldl (fun s v => s + v.shape.2) 0
      let data : Array Float := Id.run do
        let mut out : Array Float := #[]
        for row in List.range r do
          for v in args do
            match v.materialize with
            | .matrix _ mvc d =>
                for j in List.range mvc do out := out.push d[row * mvc + j]!
            | .scalar f => out := out.push f
            | _ => out := out.push 0.0
        out
      return #[Value.matrix r totalCols data])
  |>.registerBuiltin "vertcat" (fun (args : Array Value) => do
      if args.isEmpty then return #[Value.empty]
      let c := args[0]!.shape.2
      if args.any (·.shape.2 != c) then
        throw (IO.userError "vertcat: inconsistent column counts")
      return #[Value.matrix args.size c (args.foldl (fun a v => a ++ flattenV v) #[])])
  -- ── Math functions ────────────────────────────────────────────────────────
  |>.registerBuiltin "abs"   (applyU "abs"   Float.abs)
  |>.registerBuiltin "sqrt"  (applyU "sqrt"  Float.sqrt)
  |>.registerBuiltin "exp"   (applyU "exp"   Float.exp)
  |>.registerBuiltin "log"   (applyU "log"   Float.log)
  |>.registerBuiltin "log2"  (applyU "log2"  (fun x => Float.log x / Float.log 2.0))
  |>.registerBuiltin "log10" (applyU "log10" (fun x => Float.log x / Float.log 10.0))
  |>.registerBuiltin "sin"   (applyU "sin"   Float.sin)
  |>.registerBuiltin "cos"   (applyU "cos"   Float.cos)
  |>.registerBuiltin "tan"   (applyU "tan"   Float.tan)
  |>.registerBuiltin "asin"  (applyU "asin"  Float.asin)
  |>.registerBuiltin "acos"  (applyU "acos"  Float.acos)
  |>.registerBuiltin "atan"  (applyU "atan"  Float.atan)
  |>.registerBuiltin "atan2" (applyB "atan2" Float.atan2)
  |>.registerBuiltin "floor" (applyU "floor" Float.floor)
  |>.registerBuiltin "ceil"  (applyU "ceil"  Float.ceil)
  |>.registerBuiltin "round" (applyU "round" Float.round)
  |>.registerBuiltin "sign"  (applyU "sign"
      (fun x => if x > 0.0 then 1.0 else if x < 0.0 then -1.0 else 0.0))
  |>.registerBuiltin "mod" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "mod: expected 2 args")
      let a ← asFloat "mod" args[0]!; let b ← asFloat "mod" args[1]!
      return #[Value.scalar (a - b * Float.floor (a / b))])
  |>.registerBuiltin "rem" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "rem: expected 2 args")
      let a ← asFloat "rem" args[0]!; let b ← asFloat "rem" args[1]!
      return #[Value.scalar (a - b * floatTrunc (a / b))])
  |>.registerBuiltin "max" (fun (args : Array Value) => do
      match args with
      | #[v] => let d := flattenV v
                return #[Value.scalar (d.foldl max (d[0]?.getD 0.0))]
      | _ => applyB "max" max args)
  |>.registerBuiltin "min" (fun (args : Array Value) => do
      match args with
      | #[v] => let d := flattenV v
                return #[Value.scalar (d.foldl min (d[0]?.getD 0.0))]
      | _ => applyB "min" min args)
  |>.registerBuiltin "sum" (fun (args : Array Value) => do
      return #[Value.scalar ((flattenV (args[0]?.getD Value.empty)).foldl (· + ·) 0.0)])
  |>.registerBuiltin "prod" (fun (args : Array Value) => do
      return #[Value.scalar ((flattenV (args[0]?.getD Value.empty)).foldl (· * ·) 1.0)])
  |>.registerBuiltin "mean" (fun (args : Array Value) => do
      let d := flattenV (args[0]?.getD Value.empty)
      if d.isEmpty then return #[Value.scalar floatNaN]
      return #[Value.scalar (d.foldl (· + ·) 0.0 / Float.ofNat d.size)])
  |>.registerBuiltin "norm" (fun (args : Array Value) => do
      let d := flattenV (args[0]?.getD Value.empty)
      return #[Value.scalar (Float.sqrt (d.foldl (fun acc x => acc + x * x) 0.0))])
  |>.registerBuiltin "dot" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "dot: expected 2 args")
      let a := flattenV args[0]!; let b := flattenV args[1]!
      return #[Value.scalar ((Array.zipWith (· * ·) a b).foldl (· + ·) 0.0)])
  -- ── String ops ───────────────────────────────────────────────────────────
  |>.registerBuiltin "num2str" (fun (args : Array Value) => do
      match args[0]? with
      | some (Value.scalar f) => return #[Value.string (toString f)]
      | some v => return #[Value.string (v.display "")]
      | none   => return #[Value.string ""])
  |>.registerBuiltin "str2num" (fun (args : Array Value) => do
      match args[0]? with
      | some (Value.string s) =>
          match parseFloatStr? s with
          | some f => return #[Value.scalar f]
          | none   => return #[Value.empty]
      | _ => return #[Value.empty])
  |>.registerBuiltin "str2double" (fun (args : Array Value) => do
      match args[0]? with
      | some (Value.string s) =>
          return #[Value.scalar (parseFloatStr? s |>.getD floatNaN)]
      | _ => return #[Value.scalar floatNaN])
  |>.registerBuiltin "strcat" (fun (args : Array Value) => do
      return #[Value.string (args.foldl (fun acc v =>
        acc ++ match v with | Value.string s => s | _ => "") "")])
  |>.registerBuiltin "strcmp" (fun (args : Array Value) => do
      match args[0]?, args[1]? with
      | some (Value.string a), some (Value.string b) => return #[Value.boolean (a == b)]
      | _, _ => return #[Value.boolean false])
  |>.registerBuiltin "strtrim" (fun (args : Array Value) => do
      match args[0]? with
      | some (Value.string s) => return #[Value.string s.trimAscii.toString]
      | _ => return #[Value.string ""])
  |>.registerBuiltin "upper" (fun (args : Array Value) => do
      match args[0]? with
      | some (Value.string s) => return #[Value.string s.toUpper]
      | _ => return #[Value.string ""])
  |>.registerBuiltin "lower" (fun (args : Array Value) => do
      match args[0]? with
      | some (Value.string s) => return #[Value.string s.toLower]
      | _ => return #[Value.string ""])
  -- ── Type conversion ───────────────────────────────────────────────────────
  |>.registerBuiltin "double" (fun (args : Array Value) => do
      match args[0]? with
      | some v => return #[Value.scalar (← asFloat "double" v)]
      | none   => return #[Value.empty])
  |>.registerBuiltin "logical" (fun (args : Array Value) => do
      match args[0]? with
      | some v => return #[Value.boolean ((← asFloat "logical" v) != 0.0)]
      | none   => return #[Value.boolean false])
  -- ── Boolean reductions ────────────────────────────────────────────────────
  |>.registerBuiltin "any" (fun (args : Array Value) => do
      return #[Value.boolean ((flattenV (args[0]?.getD Value.empty)).any (· != 0.0))])
  |>.registerBuiltin "all" (fun (args : Array Value) => do
      return #[Value.boolean ((flattenV (args[0]?.getD Value.empty)).all (· != 0.0))])
  -- ── I/O ──────────────────────────────────────────────────────────────────
  |>.registerBuiltin "input" (fun (args : Array Value) => do
      match args[0]? with
      | some (Value.string p) => IO.print p
      | _ => pure ()
      let line := (← (← IO.getStdin).getLine).trimAscii.toString
      return #[match parseFloatStr? line with | some f => Value.scalar f | none => Value.string line])
  |>.registerBuiltin "error" (fun (args : Array Value) =>
      let msg := match args[0]? with | some (Value.string s) => s | _ => "error"
      throw (IO.userError msg))
  |>.registerBuiltin "warning" (fun (args : Array Value) => do
      match args[0]? with | some (Value.string s) => IO.eprintln s!"warning: {s}" | _ => pure ()
      return (#[] : Array Value))
  |>.registerBuiltin "exit" (fun (_ : Array Value) => do
      IO.Process.exit 0
      return (#[] : Array Value))
  |>.registerBuiltin "quit" (fun (_ : Array Value) => do
      IO.Process.exit 0
      return (#[] : Array Value))

end OctiveLean
