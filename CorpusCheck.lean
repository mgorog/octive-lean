import OctiveLean.Corpus

open OctiveLean.Corpus in
def main (args : List String) : IO UInt32 := do
  match parseArgs args ({} : Config) with
  | .error e =>
      IO.eprintln s!"argument error: {e}"
      IO.eprintln "usage: corpus-check [--dir DIR] [--bin PATH] [--update]"
      return 2
  | .ok cfg =>
      if !(← cfg.binary.pathExists) then
        IO.eprintln s!"binary not found: {cfg.binary}"
        IO.eprintln "  run first: lake build octive-lean"
        return 2
      let cases ← discoverCases cfg.dir
      if cases.isEmpty then
        IO.eprintln s!"no .m files in {cfg.dir}"
        return 0
      if cfg.update then
        IO.println s!"Updating expected outputs for {cases.size} case(s)..."
        for c in cases do
          let _ ← updateCase cfg.binary c
        return 0
      IO.println s!"Running {cases.size} case(s) against {cfg.binary}"
      IO.println ""
      let mut s : Summary := { total := cases.size }
      for c in cases do
        let outcome ← runCase cfg.binary c
        printOutcome c outcome
        match outcome with
        | .pass              => s := { s with passed  := s.passed  + 1 }
        | .fail _ _          => s := { s with failed  := s.failed  + 1 }
        | .runtimeError ..   => s := { s with errored := s.errored + 1 }
        | .missingExpected _ => s := { s with missing := s.missing + 1 }
      IO.println ""
      IO.println s!"Total: {s.total}  pass: {s.passed}  fail: {s.failed}  error: {s.errored}  miss: {s.missing}"
      if s.failed == 0 && s.errored == 0 && s.missing == 0 then
        return 0
      else
        return 1
