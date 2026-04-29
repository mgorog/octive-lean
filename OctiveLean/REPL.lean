import OctiveLean.Eval
import OctiveLean.Parser
import OctiveLean.Builtins
import OctiveLean.Env

namespace OctiveLean

/-- Read-eval-print loop.  Type `quit` or `exit` or Ctrl-D to exit. -/
private partial def replLoop (stdin : IO.FS.Stream) (env : Env) : IO Unit := do
  IO.print ">> "
  let line ← stdin.getLine
  if line.isEmpty then
    IO.println "\nGoodbye."
    return
  let line := line.trimAscii.toString
  if line == "quit" || line == "exit" then
    IO.println "Goodbye."
    return
  match parse line with
  | .error msg =>
      IO.eprintln s!"  parse error: {msg}"
      replLoop stdin env
  | .ok stmts =>
      match ← runProgram stmts env with
      | .ok env' => replLoop stdin env'
      | .error .returnSignal   => replLoop stdin env
      | .error .breakSignal    => replLoop stdin env
      | .error .continueSignal => replLoop stdin env
      | .error e =>
          IO.eprintln s!"  error: {e}"
          replLoop stdin env

def runREPL : IO Unit := do
  let stdin ← IO.getStdin
  IO.println "OctiveLean  (Lean 4 Octave interpreter)"
  IO.println "Type 'quit' or Ctrl-D to exit.\n"
  replLoop stdin (registerAllBuiltins Env.empty)

/-- Execute an Octave source file and return exit status -/
def runFile (path : String) : IO UInt32 := do
  let src ← IO.FS.readFile path
  let env := registerAllBuiltins Env.empty
  match parse src with
  | .error msg =>
      IO.eprintln s!"Parse error in {path}: {msg}"
      return 1
  | .ok stmts =>
      match ← runProgram stmts env with
      | .ok _  => return 0
      | .error .returnSignal => return 0
      | .error e =>
          IO.eprintln s!"error: {e}"
          return 1

end OctiveLean
