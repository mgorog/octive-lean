import OctiveLean.Value

namespace OctiveLean.SymPyBridge

/-! Persistent SymPy subprocess.

Mirrors the architecture of GNU Octave's `symbolic` package
(`pycall_sympy__.m`): keep one Python process alive across calls and
exchange SymPy expressions over stdin/stdout using line-based sentinels.

Each `Value.sym` carries the SymPy `srepr` (round-trips back into Python
verbatim) and the human-readable `str(...)` form (for `disp`).
-/

private def pythonScript : String := r#"
import sys, sympy
from sympy import *
from sympy.parsing.sympy_parser import parse_expr, standard_transformations, convert_xor, implicit_multiplication

ns = {}
exec("from sympy import *", ns)

_TRANSFORMS = standard_transformations + (convert_xor, implicit_multiplication)

def _parse(s):
    return parse_expr(s, transformations=_TRANSFORMS, local_dict=ns)
ns['_parse'] = _parse

def _emit(x):
    sys.stdout.write("~~~SREPR~~~\n")
    try: sys.stdout.write(srepr(x) + "\n")
    except Exception: sys.stdout.write(repr(x) + "\n")
    sys.stdout.write("~~~PRETTY~~~\n")
    try: sys.stdout.write(str(x) + "\n")
    except Exception: sys.stdout.write(repr(x) + "\n")
ns['_emit'] = _emit

EOC = "~~~EOC~~~"
EOR = "~~~EOR~~~"
ERR = "~~~ERR~~~"

buf = []
for raw in iter(sys.stdin.readline, ""):
    line = raw.rstrip("\n")
    if line == EOC:
        code = "\n".join(buf)
        buf = []
        try:
            exec(code, ns)
        except Exception as e:
            sys.stdout.write(ERR + type(e).__name__ + ": " + str(e) + "\n")
        sys.stdout.write(EOR + "\n")
        sys.stdout.flush()
    else:
        buf.append(line)
"#

private def cfg : IO.Process.StdioConfig :=
  { stdin := .piped, stdout := .piped, stderr := .piped }

private structure Bridge where
  proc : IO.Process.Child cfg

initialize bridgeRef : IO.Ref (Option Bridge) ← IO.mkRef none

private def spawn : IO Bridge := do
  let proc ← IO.Process.spawn
    { cmd := "python3"
      args := #["-u", "-c", pythonScript]
      stdin := .piped
      stdout := .piped
      stderr := .piped }
  return { proc }

private def getOrInit : IO Bridge := do
  match (← bridgeRef.get) with
  | some b => return b
  | none =>
    let b ← spawn
    bridgeRef.set (some b)
    return b

private def stripTrailingNL (s : String) : String :=
  if s.endsWith "\n" then (s.dropEnd 1).toString else s

/-- Send a Python `code` block to the subprocess and read everything it writes
    until the EOR sentinel. Returns the captured stdout (without sentinel) or
    an error message if Python raised. -/
def runRaw (code : String) : IO (Except String String) := do
  let bridge ← getOrInit
  for line in code.splitOn "\n" do
    bridge.proc.stdin.putStrLn line
  bridge.proc.stdin.putStrLn "~~~EOC~~~"
  bridge.proc.stdin.flush
  let mut collected : Array String := #[]
  let mut error? : Option String := none
  let mut done := false
  while not done do
    let raw ← bridge.proc.stdout.getLine
    let line := stripTrailingNL raw
    if line == "~~~EOR~~~" then
      done := true
    else if line.startsWith "~~~ERR~~~" then
      error? := some ((line.drop "~~~ERR~~~".length).toString)
    else
      collected := collected.push line
  match error? with
  | some e => return .error e
  | none   => return .ok (String.intercalate "\n" collected.toList)

private def parseEmitOutput (out : String) : Except String (String × String) :=
  let needle := "~~~PRETTY~~~\n"
  match (out.splitOn needle) with
  | [head, tail] =>
      let srMarker := "~~~SREPR~~~\n"
      if head.startsWith srMarker then
        let srepr  := stripTrailingNL ((head.drop srMarker.length).toString)
        let pretty := stripTrailingNL tail
        .ok (srepr, pretty)
      else .error s!"sympy: missing SREPR marker in {out}"
  | _ => .error s!"sympy: missing PRETTY marker in {out}"

/-- Evaluate a Python expression that produces a SymPy object and wrap the
    result as a `Value.sym`. Caller is responsible for building a syntactically
    valid Python expression (use `Value.toSympyExpr` for operands). -/
def emit (expr : String) : IO Value := do
  match (← runRaw s!"_emit({expr})") with
  | .error e => throw (IO.userError s!"sympy: {e}")
  | .ok out =>
    match parseEmitOutput out with
    | .ok (sr, pr) => return .sym sr pr
    | .error e     => throw (IO.userError e)

/-- Convert any OctiveLean Value into a Python expression string suitable for
    splicing into SymPy commands. Numerics become SymPy `Integer`/`Float`,
    Sym values forward their `srepr`, strings get parsed with `_parse`. -/
def toSympy : Value → IO String
  | .sym sr _      => return sr
  | .scalar f      =>
      if f == f.floor && f.abs < 1e15 then return s!"Integer({f.toInt64})"
      else return s!"Float({f})"
  | .fscalar f     => return s!"Float({f})"
  | .integer iv    => return s!"Integer({iv.display})"
  | .boolean b     => return if b then "true" else "false"
  | .string s      =>
      let escaped := s.replace "\\" "\\\\" |>.replace "'" "\\'"
      return s!"_parse('{escaped}')"
  | v              => throw (IO.userError s!"sympy: cannot convert {v.typeName} to symbolic")

/-- Coerce a Value to a Sym, by parsing through SymPy if it is not already one. -/
def asSym (v : Value) : IO Value := do
  match v with
  | .sym _ _ => return v
  | _        =>
      let py ← toSympy v
      emit py

end OctiveLean.SymPyBridge
