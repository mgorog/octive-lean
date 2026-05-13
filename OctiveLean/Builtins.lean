import OctiveLean.Value
import OctiveLean.Env
import OctiveLean.Error
import OctiveLean.SymPyBridge

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
      -- fixed-point with p decimal places (sign-prepend; format absolute value)
      let scale := Float.ofNat (10 ^ p)
      let absF := f.abs
      let rounded := Float.round (absF * scale) / scale
      let intPart := rounded.floor
      let fracPart := Float.round ((rounded - intPart) * scale)
      let signStr := if f < 0.0 then "-" else ""
      let intStr := signStr ++ toString intPart.toUInt64
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
            | .sym _ _   => "sym"
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
  |>.registerBuiltin "transpose"  (fun args => do
      if args.isEmpty then throw (IO.userError "transpose: expected 1 arg")
      match args[0]!.materialize with
      | .scalar f => return #[.scalar f]
      | .matrix r c d =>
          let mut o : Array Float := Array.replicate (r * c) 0.0
          for i in [:r] do
            for j in [:c] do
              o := o.set! (j * r + i) d[i * c + j]!
          return #[.matrix c r o]
      | other => throw (IO.userError s!"transpose: cannot transpose {other.typeName}"))
  |>.registerBuiltin "htranspose" (fun args => do
      -- Hermitian transpose; for real-valued matrices this is the same as transpose.
      if args.isEmpty then throw (IO.userError "htranspose: expected 1 arg")
      match args[0]!.materialize with
      | .scalar f => return #[.scalar f]
      | .matrix r c d =>
          let mut o : Array Float := Array.replicate (r * c) 0.0
          for i in [:r] do
            for j in [:c] do
              o := o.set! (j * r + i) d[i * c + j]!
          return #[.matrix c r o]
      | other => throw (IO.userError s!"htranspose: cannot transpose {other.typeName}"))
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
      | some v =>
          match v with
          | Value.sym sr _ =>
              match (← SymPyBridge.runRaw s!"print(repr(float(({sr}).evalf())))") with
              | .ok s =>
                  match parseFloatStr? s.trimAscii.toString with
                  | some f => return #[Value.scalar f]
                  | none   => throw (IO.userError s!"double: cannot convert sym '{s}' to float")
              | .error e => throw (IO.userError s!"double: {e}")
          | _ => return #[Value.scalar (← asFloat "double" v)]
      | none => return #[Value.empty])
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
  -- ── Numerical: linear solve, polyfit, polyval, spline ────────────────────
  |>.registerBuiltin "linsolve" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "linsolve: expected (A, b)")
      match args[0]!.materialize, args[1]!.materialize with
      | .matrix n m a, .matrix nb _ b =>
          if n != m || nb != n then
            throw (IO.userError s!"linsolve: A must be square and match b ({n}×{m} vs b={nb})")
          let mut M : Array Float := a
          let mut bv : Array Float := b
          for i in List.range n do
            let mut maxRow := i
            let mut maxV := (M[i * n + i]!).abs
            for k in List.range (n - i - 1) do
              let kk := i + 1 + k
              let v := (M[kk * n + i]!).abs
              if v > maxV then maxRow := kk; maxV := v
            if maxRow != i then
              for j in List.range n do
                let t := M[i * n + j]!
                M := M.set! (i * n + j) M[maxRow * n + j]!
                M := M.set! (maxRow * n + j) t
              let tb := bv[i]!
              bv := bv.set! i bv[maxRow]!
              bv := bv.set! maxRow tb
            let pivot := M[i * n + i]!
            if pivot.abs < 1e-15 then
              throw (IO.userError "linsolve: singular matrix")
            for k in List.range (n - i - 1) do
              let kk := i + 1 + k
              let factor := M[kk * n + i]! / pivot
              for j in List.range (n - i) do
                let jj := i + j
                M := M.set! (kk * n + jj) (M[kk * n + jj]! - factor * M[i * n + jj]!)
              bv := bv.set! kk (bv[kk]! - factor * bv[i]!)
          let mut x : Array Float := arrFill n 0.0
          for ii in List.range n do
            let i := n - 1 - ii
            let mut s := bv[i]!
            for k in List.range (n - i - 1) do
              let j := i + 1 + k
              s := s - M[i * n + j]! * x[j]!
            x := x.set! i (s / M[i * n + i]!)
          return #[Value.matrix n 1 x]
      | _, _ => throw (IO.userError "linsolve: expected matrix arguments"))
  |>.registerBuiltin "polyval" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "polyval: expected (c, x)")
      let c := flattenV args[0]!
      let xs := flattenV args[1]!
      if c.isEmpty then throw (IO.userError "polyval: empty coefficients")
      let eval := fun (x : Float) => Id.run do
        let mut y := c[0]!
        for i in List.range (c.size - 1) do
          y := y * x + c[i + 1]!
        y
      let ys : Array Float := xs.map eval
      match args[1]!.materialize with
      | .scalar _   => return #[Value.scalar (ys[0]!)]
      | .matrix r co _ => return #[Value.matrix r co ys]
      | .range _ _ _ => return #[Value.matrix 1 ys.size ys]
      | _ => return #[Value.matrix 1 ys.size ys])
  |>.registerBuiltin "polyfit" (fun (args : Array Value) => do
      if args.size < 3 then throw (IO.userError "polyfit: expected (x, y, n)")
      let xs := flattenV args[0]!
      let ys := flattenV args[1]!
      let n ← asNat "polyfit" args[2]!
      let m := xs.size
      if ys.size != m then throw (IO.userError "polyfit: x and y must be same length")
      if n + 1 > m then throw (IO.userError s!"polyfit: degree {n} requires at least {n+1} points")
      -- Build Vandermonde V[i,j] = xs[i]^(n - j)  (i in 0..m, j in 0..n)
      let cols := n + 1
      let V : Array Float := Id.run do
        let mut v := arrFill (m * cols) 0.0
        for i in List.range m do
          let mut p := 1.0
          for k in List.range cols do
            v := v.set! (i * cols + (n - k)) p
            p := p * xs[i]!
        v
      -- Normal equations: A = V^T V (cols × cols), b = V^T y
      let A : Array Float := Id.run do
        let mut a := arrFill (cols * cols) 0.0
        for i in List.range cols do
          for j in List.range cols do
            let mut s := 0.0
            for k in List.range m do
              s := s + V[k * cols + i]! * V[k * cols + j]!
            a := a.set! (i * cols + j) s
        a
      let bv : Array Float := Id.run do
        let mut b := arrFill cols 0.0
        for i in List.range cols do
          let mut s := 0.0
          for k in List.range m do
            s := s + V[k * cols + i]! * ys[k]!
          b := b.set! i s
        b
      -- Solve A c = bv via in-place Gaussian elimination with partial pivot
      let mut M := A
      let mut rhs := bv
      let nn := cols
      for i in List.range nn do
        let mut maxRow := i
        let mut maxV := (M[i * nn + i]!).abs
        for k in List.range (nn - i - 1) do
          let kk := i + 1 + k
          let v := (M[kk * nn + i]!).abs
          if v > maxV then maxRow := kk; maxV := v
        if maxRow != i then
          for j in List.range nn do
            let t := M[i * nn + j]!
            M := M.set! (i * nn + j) M[maxRow * nn + j]!
            M := M.set! (maxRow * nn + j) t
          let tb := rhs[i]!
          rhs := rhs.set! i rhs[maxRow]!
          rhs := rhs.set! maxRow tb
        let pivot := M[i * nn + i]!
        if pivot.abs < 1e-15 then
          throw (IO.userError "polyfit: singular normal equations")
        for k in List.range (nn - i - 1) do
          let kk := i + 1 + k
          let factor := M[kk * nn + i]! / pivot
          for j in List.range (nn - i) do
            let jj := i + j
            M := M.set! (kk * nn + jj) (M[kk * nn + jj]! - factor * M[i * nn + jj]!)
          rhs := rhs.set! kk (rhs[kk]! - factor * rhs[i]!)
      let mut c := arrFill nn 0.0
      for ii in List.range nn do
        let i := nn - 1 - ii
        let mut s := rhs[i]!
        for k in List.range (nn - i - 1) do
          let j := i + 1 + k
          s := s - M[i * nn + j]! * c[j]!
        c := c.set! i (s / M[i * nn + i]!)
      return #[Value.matrix 1 nn c])
  |>.registerBuiltin "spline" (fun (args : Array Value) => do
      if args.size < 3 then throw (IO.userError "spline: expected (x, y, t)")
      let xs := flattenV args[0]!
      let ys := flattenV args[1]!
      let ts := flattenV args[2]!
      let n := xs.size
      if ys.size != n || n < 2 then throw (IO.userError "spline: bad input")
      let nseg := n - 1
      let h : Array Float := Id.run do
        let mut h := arrFill nseg 0.0
        for i in List.range nseg do h := h.set! i (xs[i+1]! - xs[i]!)
        h
      -- Solve tridiagonal for M[1..n-2], with M[0]=M[n-1]=0 (natural)
      let mut M := arrFill n 0.0
      if n >= 3 then
        let inner := n - 2
        let mut a := arrFill inner 0.0
        let mut b := arrFill inner 0.0
        let mut c := arrFill inner 0.0
        let mut d := arrFill inner 0.0
        for i in List.range inner do
          let i1 := i + 1
          let hL := h[i1 - 1]!
          let hR := h[i1]!
          a := a.set! i hL
          b := b.set! i (2.0 * (hL + hR))
          c := c.set! i hR
          d := d.set! i (6.0 * ((ys[i1+1]! - ys[i1]!) / hR - (ys[i1]! - ys[i1-1]!) / hL))
        -- Thomas algorithm
        for i in List.range (inner - 1) do
          let ii := i + 1
          let factor := a[ii]! / b[i]!
          b := b.set! ii (b[ii]! - factor * c[i]!)
          d := d.set! ii (d[ii]! - factor * d[i]!)
        let mut sol := arrFill inner 0.0
        sol := sol.set! (inner - 1) (d[inner-1]! / b[inner-1]!)
        for ii in List.range (inner - 1) do
          let i := inner - 2 - ii
          sol := sol.set! i ((d[i]! - c[i]! * sol[i+1]!) / b[i]!)
        for i in List.range inner do M := M.set! (i + 1) sol[i]!
      -- Evaluate at each t
      let evalAt := fun (t : Float) => Id.run do
        let mut idx := 0
        for k in List.range nseg do if xs[k]! <= t then idx := k
        if t > xs[n-1]! then idx := nseg - 1
        let i := idx
        let hi := h[i]!
        let xi := xs[i]!; let xi1 := xs[i+1]!
        let yi := ys[i]!; let yi1 := ys[i+1]!
        let Mi := M[i]!; let Mi1 := M[i+1]!
        let A1 := Mi * (xi1 - t)^3.0 / (6.0 * hi)
        let A2 := Mi1 * (t - xi)^3.0 / (6.0 * hi)
        let A3 := (yi / hi - Mi * hi / 6.0) * (xi1 - t)
        let A4 := (yi1 / hi - Mi1 * hi / 6.0) * (t - xi)
        A1 + A2 + A3 + A4
      let out : Array Float := ts.map evalAt
      match args[2]!.materialize with
      | .scalar _ => return #[Value.scalar out[0]!]
      | .matrix r co _ => return #[Value.matrix r co out]
      | .range _ _ _ => return #[Value.matrix 1 out.size out]
      | _ => return #[Value.matrix 1 out.size out])
  -- ── Symbolic Math (SymPy bridge) ─────────────────────────────────────────
  -- Architecture mirrors GNU Octave's `symbolic` package: each builtin is a
  -- thin wrapper that converts arguments to a Python expression and forwards
  -- to a persistent SymPy subprocess. See `OctiveLean/SymPyBridge.lean`.
  |>.registerBuiltin "sym" (fun (args : Array Value) => do
      match args[0]? with
      | some v =>
          let py ← SymPyBridge.toSympy v
          return #[← SymPyBridge.emit py]
      | none => throw (IO.userError "sym: expected 1 argument"))
  |>.registerBuiltin "syms" (fun (args : Array Value) => do
      -- Returns one Sym per argument — invoked as `[x,y,z] = syms('x','y','z')`.
      let mut out : Array Value := #[]
      for a in args do
        match a with
        | .string s => out := out.push (← SymPyBridge.emit s!"symbols('{s}')")
        | _         => throw (IO.userError "syms: expected string arg")
      return out)
  |>.registerBuiltin "diff" (fun (args : Array Value) => do
      match args.size with
      | 0 => throw (IO.userError "diff: expected at least 1 argument")
      | 1 =>
          let f ← SymPyBridge.toSympy args[0]!
          return #[← SymPyBridge.emit s!"diff({f})"]
      | _ =>
          let f ← SymPyBridge.toSympy args[0]!
          let v ← SymPyBridge.toSympy args[1]!
          if h : args.size >= 3 then
            let n ← SymPyBridge.toSympy args[2]!
            return #[← SymPyBridge.emit s!"diff({f}, {v}, {n})"]
          else
            return #[← SymPyBridge.emit s!"diff({f}, {v})"])
  |>.registerBuiltin "int" (fun (args : Array Value) => do
      match args.size with
      | 0 => throw (IO.userError "int: expected at least 1 argument")
      | 1 =>
          let f ← SymPyBridge.toSympy args[0]!
          return #[← SymPyBridge.emit s!"integrate({f})"]
      | 2 =>
          let f ← SymPyBridge.toSympy args[0]!
          let v ← SymPyBridge.toSympy args[1]!
          return #[← SymPyBridge.emit s!"integrate({f}, {v})"]
      | _ =>
          -- int(f, x, a, b) — definite integral
          let f ← SymPyBridge.toSympy args[0]!
          let v ← SymPyBridge.toSympy args[1]!
          let a ← SymPyBridge.toSympy args[2]!
          let b ← SymPyBridge.toSympy args[3]!
          return #[← SymPyBridge.emit s!"integrate({f}, ({v}, {a}, {b}))"])
  |>.registerBuiltin "subs" (fun (args : Array Value) => do
      if args.size < 3 then throw (IO.userError "subs: expected (expr, var, val)")
      let f ← SymPyBridge.toSympy args[0]!
      let v ← SymPyBridge.toSympy args[1]!
      let r ← SymPyBridge.toSympy args[2]!
      return #[← SymPyBridge.emit s!"({f}).subs({v}, {r})"])
  |>.registerBuiltin "simplify" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      return #[← SymPyBridge.emit s!"simplify({f})"])
  |>.registerBuiltin "expand" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      return #[← SymPyBridge.emit s!"expand({f})"])
  |>.registerBuiltin "factor" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      return #[← SymPyBridge.emit s!"factor({f})"])
  |>.registerBuiltin "collect" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "collect: expected (expr, var)")
      let f ← SymPyBridge.toSympy args[0]!
      let v ← SymPyBridge.toSympy args[1]!
      return #[← SymPyBridge.emit s!"collect({f}, {v})"])
  |>.registerBuiltin "solve" (fun (args : Array Value) => do
      match args.size with
      | 0 => throw (IO.userError "solve: expected at least 1 argument")
      | 1 =>
          let f ← SymPyBridge.toSympy args[0]!
          return #[← SymPyBridge.emit s!"solve({f})"]
      | _ =>
          let f ← SymPyBridge.toSympy args[0]!
          let v ← SymPyBridge.toSympy args[1]!
          return #[← SymPyBridge.emit s!"solve({f}, {v})"])
  |>.registerBuiltin "taylor" (fun (args : Array Value) => do
      match args.size with
      | 0 => throw (IO.userError "taylor: expected at least 1 argument")
      | 1 =>
          let f ← SymPyBridge.toSympy args[0]!
          return #[← SymPyBridge.emit s!"series({f}).removeO()"]
      | 2 =>
          let f ← SymPyBridge.toSympy args[0]!
          let v ← SymPyBridge.toSympy args[1]!
          return #[← SymPyBridge.emit s!"series({f}, {v}).removeO()"]
      | _ =>
          let f ← SymPyBridge.toSympy args[0]!
          let v ← SymPyBridge.toSympy args[1]!
          let a ← SymPyBridge.toSympy args[2]!
          if h : args.size >= 4 then
            let n ← SymPyBridge.toSympy args[3]!
            return #[← SymPyBridge.emit s!"series({f}, {v}, {a}, {n}).removeO()"]
          else
            return #[← SymPyBridge.emit s!"series({f}, {v}, {a}).removeO()"])
  |>.registerBuiltin "limit" (fun (args : Array Value) => do
      if args.size < 3 then throw (IO.userError "limit: expected (expr, var, point)")
      let f ← SymPyBridge.toSympy args[0]!
      let v ← SymPyBridge.toSympy args[1]!
      let p ← SymPyBridge.toSympy args[2]!
      if h : args.size >= 4 then
        match args[3]! with
        | .string "left"  => return #[← SymPyBridge.emit s!"limit({f}, {v}, {p}, '-')"]
        | .string "right" => return #[← SymPyBridge.emit s!"limit({f}, {v}, {p}, '+')"]
        | _ => return #[← SymPyBridge.emit s!"limit({f}, {v}, {p})"]
      else
        return #[← SymPyBridge.emit s!"limit({f}, {v}, {p})"])
  |>.registerBuiltin "jacobian" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "jacobian: expected (f, vars)")
      let f ← SymPyBridge.toSympy args[0]!
      let v ← SymPyBridge.toSympy args[1]!
      return #[← SymPyBridge.emit s!"Matrix([{f}]).jacobian({v})"])
  |>.registerBuiltin "gradient" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "gradient: expected (f, vars)")
      let f ← SymPyBridge.toSympy args[0]!
      let v ← SymPyBridge.toSympy args[1]!
      return #[← SymPyBridge.emit s!"Matrix([{f}]).jacobian({v}).T"])
  |>.registerBuiltin "hessian" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "hessian: expected (f, vars)")
      let f ← SymPyBridge.toSympy args[0]!
      let v ← SymPyBridge.toSympy args[1]!
      return #[← SymPyBridge.emit s!"hessian({f}, {v})"])
  |>.registerBuiltin "coeffs" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      if h : args.size >= 2 then
        let v ← SymPyBridge.toSympy args[1]!
        return #[← SymPyBridge.emit s!"Poly({f}, {v}).all_coeffs()"]
      else
        return #[← SymPyBridge.emit s!"Poly({f}).all_coeffs()"])
  |>.registerBuiltin "lhs" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      return #[← SymPyBridge.emit s!"({f}).lhs"])
  |>.registerBuiltin "rhs" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      return #[← SymPyBridge.emit s!"({f}).rhs"])
  |>.registerBuiltin "latex" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      match (← SymPyBridge.runRaw s!"print(latex({f}))") with
      | .ok s   => return #[Value.string (s.trimAscii.toString)]
      | .error e => throw (IO.userError s!"latex: {e}"))
  |>.registerBuiltin "pretty" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      match (← SymPyBridge.runRaw s!"print(pretty({f}, use_unicode=False))") with
      | .ok s   => IO.println s; return #[]
      | .error e => throw (IO.userError s!"pretty: {e}"))
  |>.registerBuiltin "vpa" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      let n : String := if h : args.size >= 2 then
          match args[1]! with
          | .scalar f => toString f.toInt64
          | _         => "15"
        else "15"
      return #[← SymPyBridge.emit s!"N({f}, {n})"])
  |>.registerBuiltin "symsum" (fun (args : Array Value) => do
      if args.size < 4 then throw (IO.userError "symsum: expected (expr, var, lo, hi)")
      let f ← SymPyBridge.toSympy args[0]!
      let v ← SymPyBridge.toSympy args[1]!
      let lo ← SymPyBridge.toSympy args[2]!
      let hi ← SymPyBridge.toSympy args[3]!
      return #[← SymPyBridge.emit s!"summation({f}, ({v}, {lo}, {hi}))"])
  |>.registerBuiltin "laplacian" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "laplacian: expected (f, vars)")
      let f ← SymPyBridge.toSympy args[0]!
      let v ← SymPyBridge.toSympy args[1]!
      return #[← SymPyBridge.emit s!"sum(diff({f}, _v, 2) for _v in {v})"])
  |>.registerBuiltin "divergence" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "divergence: expected (F, vars)")
      let f ← SymPyBridge.toSympy args[0]!
      let v ← SymPyBridge.toSympy args[1]!
      return #[← SymPyBridge.emit s!"sum(diff(_F[i], {v}[i]) for i, _F in enumerate([{f}] * 1) for i in range(len({v})))"])
  |>.registerBuiltin "rewrite" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "rewrite: expected (expr, target)")
      let f ← SymPyBridge.toSympy args[0]!
      let target := match args[1]! with | .string s => s | _ => "sin"
      return #[← SymPyBridge.emit s!"({f}).rewrite({target})"])
  |>.registerBuiltin "resultant" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "resultant: expected (p, q[, var])")
      let p ← SymPyBridge.toSympy args[0]!
      let q ← SymPyBridge.toSympy args[1]!
      if h : args.size >= 3 then
        let v ← SymPyBridge.toSympy args[2]!
        return #[← SymPyBridge.emit s!"resultant({p}, {q}, {v})"]
      else
        return #[← SymPyBridge.emit s!"resultant({p}, {q})"])
  |>.registerBuiltin "series" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      if h : args.size >= 2 then
        let v ← SymPyBridge.toSympy args[1]!
        return #[← SymPyBridge.emit s!"series({f}, {v})"]
      else
        return #[← SymPyBridge.emit s!"series({f})"])
  |>.registerBuiltin "isolate" (fun (args : Array Value) => do
      if args.size < 2 then throw (IO.userError "isolate: expected (eq, var)")
      let f ← SymPyBridge.toSympy args[0]!
      let v ← SymPyBridge.toSympy args[1]!
      return #[← SymPyBridge.emit s!"Eq({v}, solve({f}, {v})[0])"])
  |>.registerBuiltin "symfun" (fun (args : Array Value) => do
      match args[0]? with
      | some v =>
          match v with
          | Value.string n =>
              match (← SymPyBridge.runRaw s!"{n} = Function('{n}')") with
              | .ok _ => return #[← SymPyBridge.emit s!"Function('{n}')"]
              | .error e => throw (IO.userError s!"symfun: {e}")
          | _ => throw (IO.userError "symfun: expected name string")
      | none => throw (IO.userError "symfun: expected name string"))
  |>.registerBuiltin "dsolve" (fun (args : Array Value) => do
      let f ← SymPyBridge.toSympy args[0]!
      if h : args.size >= 2 then
        let y ← SymPyBridge.toSympy args[1]!
        return #[← SymPyBridge.emit s!"dsolve({f}, {y})"]
      else
        return #[← SymPyBridge.emit s!"dsolve({f})"])
  |>.registerBuiltin "piecewise" (fun (args : Array Value) => do
      -- piecewise(cond1, val1, cond2, val2, ...)  →  Piecewise((val1, cond1), ...)
      let mut parts : Array String := #[]
      let mut i := 0
      while h : i + 1 < args.size do
        let c ← SymPyBridge.toSympy args[i]!
        let v ← SymPyBridge.toSympy args[i+1]!
        parts := parts.push s!"({v}, {c})"
        i := i + 2
      let body := String.intercalate ", " parts.toList
      return #[← SymPyBridge.emit s!"Piecewise({body})"])

end OctiveLean
