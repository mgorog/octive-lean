namespace OctiveLean

inductive OctaveError where
  | parseError   : String → OctaveError
  | lexError     : String → OctaveError
  | nameError    : String → OctaveError
  | typeError    : String → OctaveError
  | indexError   : String → OctaveError
  | valueError   : String → OctaveError
  | arithError   : String → OctaveError
  | runtimeError : String → OctaveError
  | returnSignal : OctaveError          -- non-error control flow
  | breakSignal  : OctaveError
  | continueSignal : OctaveError
  deriving Repr, Inhabited

instance : ToString OctaveError where
  toString
    | .parseError  s => s!"parse error: {s}"
    | .lexError    s => s!"lex error: {s}"
    | .nameError   s => s!"''{s}'' undefined"
    | .typeError   s => s!"type error: {s}"
    | .indexError  s => s!"index error: {s}"
    | .valueError  s => s!"value error: {s}"
    | .arithError  s => s!"arithmetic error: {s}"
    | .runtimeError s => s!"error: {s}"
    | .returnSignal  => "return"
    | .breakSignal   => "break"
    | .continueSignal => "continue"

end OctiveLean
