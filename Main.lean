import OctiveLean

open OctiveLean in
def main (args : List String) : IO UInt32 := do
  match args with
  | []     => runREPL; return 0
  | [path] => runFile path
  | _      =>
      IO.eprintln "Usage: octive-lean [script.m]"
      return 1
