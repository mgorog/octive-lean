import OctiveLean.Eval
import OctiveLean.Parser
import OctiveLean.Builtins
import OctiveLean.Env

namespace OctiveLean.Corpus

/-- A corpus test case: an Octave source file paired with its expected stdout. -/
structure Case where
  name    : String
  srcPath : System.FilePath
  expPath : System.FilePath
  deriving Inhabited

/-- Outcome of running one case. -/
inductive Outcome where
  | pass
  | fail            (expected actual : String)
  | runtimeError    (exitCode : UInt32) (stderr stdout : String)
  | missingExpected (actual : String)

/-- Aggregate counters across a run. -/
structure Summary where
  total   : Nat := 0
  passed  : Nat := 0
  failed  : Nat := 0
  errored : Nat := 0
  missing : Nat := 0
  deriving Inhabited

/-- Runtime config: which corpus dir, which binary, update mode. -/
structure Config where
  dir    : System.FilePath := "corpus"
  binary : System.FilePath := ".lake/build/bin/octive-lean"
  update : Bool := false
  deriving Inhabited

/-- Plain CLI arg parser: flags only, no positional. -/
partial def parseArgs : List String → Config → Except String Config
  | [],                     cfg => .ok cfg
  | "--update" :: rest,     cfg => parseArgs rest { cfg with update := true }
  | "--bin"    :: b :: rest, cfg => parseArgs rest { cfg with binary := b }
  | "--dir"    :: d :: rest, cfg => parseArgs rest { cfg with dir := d }
  | x :: _, _ => .error s!"unknown arg: {x}"

/-- Walk `dir`, pair every `*.m` with the sibling `*.expected`. Sorted by name. -/
def discoverCases (dir : System.FilePath) : IO (Array Case) := do
  if !(← dir.pathExists) then
    return #[]
  let entries ← dir.readDir
  let mut cases : Array Case := #[]
  for e in entries do
    if e.path.extension == some "m" then
      let stem := e.path.fileStem.getD ""
      let expPath := dir / (stem ++ ".expected")
      cases := cases.push { name := stem, srcPath := e.path, expPath := expPath }
  return cases.qsort (fun a b => a.name < b.name)

/-- Diff-resistant compare: ignore trailing whitespace / final newline. -/
private def normalize (s : String) : String := s.trimRight

/-- Run a single case as a subprocess; return the outcome. -/
def runCase (binary : System.FilePath) (c : Case) : IO Outcome := do
  let result ← IO.Process.output {
    cmd  := binary.toString
    args := #[c.srcPath.toString]
  }
  if result.exitCode != 0 then
    return .runtimeError result.exitCode result.stderr result.stdout
  if !(← c.expPath.pathExists) then
    return .missingExpected result.stdout
  let expected ← IO.FS.readFile c.expPath
  if normalize result.stdout == normalize expected then
    return .pass
  else
    return .fail expected result.stdout

/-- Update mode: run, write actual stdout to `.expected`. -/
def updateCase (binary : System.FilePath) (c : Case) : IO Bool := do
  let result ← IO.Process.output {
    cmd  := binary.toString
    args := #[c.srcPath.toString]
  }
  if result.exitCode != 0 then
    IO.eprintln s!"  [SKIP]  {c.name}  (exit {result.exitCode})"
    if result.stderr.trim != "" then
      IO.eprintln s!"          stderr: {result.stderr.trim}"
    return false
  IO.FS.writeFile c.expPath result.stdout
  IO.println s!"  [WROTE] {c.expPath}"
  return true

private def indent (pre : String) (s : String) : String :=
  String.intercalate "\n" (s.splitOn "\n" |>.map (pre ++ ·))

/-- Pretty-print one outcome. -/
def printOutcome (c : Case) : Outcome → IO Unit
  | .pass =>
      IO.println s!"  pass    {c.name}"
  | .fail expected actual => do
      IO.println s!"  FAIL    {c.name}"
      IO.println "    expected:"
      IO.println (indent "    | " expected)
      IO.println "    actual:"
      IO.println (indent "    | " actual)
  | .runtimeError ec stderr stdout => do
      IO.println s!"  ERROR   {c.name}  (exit {ec})"
      if stderr.trim != "" then
        IO.println "    stderr:"
        IO.println (indent "    | " stderr)
      if stdout.trim != "" then
        IO.println "    stdout:"
        IO.println (indent "    | " stdout)
  | .missingExpected actual => do
      IO.println s!"  miss    {c.name}  (no .expected; run with --update)"
      IO.println "    actual:"
      IO.println (indent "    | " actual)

end OctiveLean.Corpus
