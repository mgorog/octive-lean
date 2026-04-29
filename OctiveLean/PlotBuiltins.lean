import OctiveLean.PlotData
import OctiveLean.Value
import OctiveLean.Env

namespace OctiveLean.PlotBuiltins

open OctiveLean

-- ── Value → data extraction ───────────────────────────────────────

def valueToFloats (v : Value) : IO (Array Float) :=
  match v with
  | .scalar x        => return #[x]
  | .range s step e  => return Value.rangeToArray s step e
  | .matrix 1 _ data => return data
  | .matrix _ 1 data => return data
  | .matrix r c data => return (Array.range (r * c)).map fun i => data.getD i 0.0
  | _ => throw (IO.userError "plot: expected numeric vector or matrix")

-- ── Figure buffer helpers ─────────────────────────────────────────

def ensureFigure (buf : IO.Ref (Array Figure)) : IO Unit := do
  let figs ← buf.get
  if figs.isEmpty then buf.set #[{}]

def modifyCurrentFig (buf : IO.Ref (Array Figure)) (f : Figure → Figure) : IO Unit := do
  buf.modify fun figs =>
    if figs.isEmpty then #[f {}]
    else figs.set! (figs.size - 1) (f figs.back!)

def addSeries (buf : IO.Ref (Array Figure)) (s : PlotSeries) : IO Unit := do
  let figs ← buf.get
  if figs.isEmpty then
    buf.set #[{ series := #[s] }]
  else
    let last := figs.back!
    if last.holdOn then
      buf.modify fun arr => arr.set! (arr.size - 1) { last with series := last.series.push s }
    else
      -- new figure for this series
      buf.modify fun arr => arr.push { series := #[s] }

-- ── Color cycling ─────────────────────────────────────────────────

def nextColor (figs : Array Figure) : String :=
  let n := figs.foldl (fun acc f => acc + f.series.size) 0
  plotColors.getD (n % plotColors.size) "#1f77b4"

-- ── Shared plot builder ───────────────────────────────────────────

def plotBuiltin (buf : IO.Ref (Array Figure)) (mk : MarkType)
    (args : Array Value) : IO (Array Value) := do
  match args with
  | #[yv] => do
      let ys ← valueToFloats yv
      let xs := (Array.range ys.size).map (fun i => (i + 1).toFloat)
      let figs ← buf.get
      let color := nextColor figs
      addSeries buf { xData := xs, yData := ys, markType := mk, color }
  | #[xv, yv] => do
      let xs ← valueToFloats xv
      let ys ← valueToFloats yv
      let figs ← buf.get
      let color := nextColor figs
      addSeries buf { xData := xs, yData := ys, markType := mk, color }
  | #[xv, yv, .string spec] => do
      -- basic line spec parsing: color chars and line style ignored for now
      let xs ← valueToFloats xv
      let ys ← valueToFloats yv
      let figs ← buf.get
      let color := nextColor figs
      let mk' := if spec.contains 'o' || spec.contains '+' || spec.contains '*'
                 then .scatter else mk
      addSeries buf { xData := xs, yData := ys, markType := mk', color }
  | _ => throw (IO.userError "plot: expected 1 or 2 numeric vector arguments")
  return #[]

-- ── Histogram builder ─────────────────────────────────────────────

def histBuiltin (buf : IO.Ref (Array Figure)) (args : Array Value) : IO (Array Value) := do
  let data ← match args with
    | #[v]    => valueToFloats v
    | #[v, _] => valueToFloats v   -- nbins arg ignored in bin count for now
    | _ => throw (IO.userError "hist: expected 1 or 2 arguments")
  let nbins := match args.getD 1 (.scalar 10) with
    | .scalar n => n.toUInt64.toNat.max 2
    | _ => 10
  if data.isEmpty then return #[]
  let lo := data.foldl min data[0]!
  let hi := data.foldl max data[0]!
  let bw := if hi == lo then 1.0 else (hi - lo) / nbins.toFloat
  -- Count elements per bin
  let counts := Array.range nbins |>.map fun i =>
    let binLo := lo + i.toFloat * bw
    let binHi := binLo + bw
    data.foldl (fun c x => if x >= binLo && (x < binHi || (i == nbins - 1 && x <= binHi)) then c + 1 else c) (0 : Nat)
  let xs := Array.range nbins |>.map fun i => lo + (i.toFloat + 0.5) * bw
  let ys := counts.map (fun n => n.toFloat)
  let figs ← buf.get
  let color := nextColor figs
  addSeries buf { xData := xs, yData := ys, markType := .histogram, color }
  return #[]

-- ── Metadata builtins ────────────────────────────────────────────

def titleBuiltin (buf : IO.Ref (Array Figure)) (args : Array Value) : IO (Array Value) := do
  match args.getD 0 (.string "") with
  | .string s => do ensureFigure buf; modifyCurrentFig buf fun f => { f with title := s }
  | _ => pure ()
  return #[]

def xlabelBuiltin (buf : IO.Ref (Array Figure)) (args : Array Value) : IO (Array Value) := do
  match args.getD 0 (.string "") with
  | .string s => do ensureFigure buf; modifyCurrentFig buf fun f => { f with xlabel := s }
  | _ => pure ()
  return #[]

def ylabelBuiltin (buf : IO.Ref (Array Figure)) (args : Array Value) : IO (Array Value) := do
  match args.getD 0 (.string "") with
  | .string s => do ensureFigure buf; modifyCurrentFig buf fun f => { f with ylabel := s }
  | _ => pure ()
  return #[]

def legendBuiltin (buf : IO.Ref (Array Figure)) (args : Array Value) : IO (Array Value) := do
  let labels := args.filterMap fun v => match v with | .string s => some s | _ => none
  modifyCurrentFig buf fun f =>
    let updated := f.series.mapIdx fun i s =>
      { s with label := labels.getD i s.label }
    { f with series := updated }
  return #[]

def figureBuiltin (buf : IO.Ref (Array Figure)) (_ : Array Value) : IO (Array Value) := do
  buf.modify fun figs => figs.push {}
  return #[]

def holdBuiltin (buf : IO.Ref (Array Figure)) (on : Bool) (_ : Array Value) : IO (Array Value) := do
  ensureFigure buf
  modifyCurrentFig buf fun f => { f with holdOn := on }
  return #[]

def xlimBuiltin (buf : IO.Ref (Array Figure)) (args : Array Value) : IO (Array Value) := do
  match args.getD 0 (.matrix 1 2 #[0,1]) with
  | .matrix 1 2 d => modifyCurrentFig buf fun f => { f with xRange := some (d[0]!, d[1]!) }
  | _ => pure ()
  return #[]

def ylimBuiltin (buf : IO.Ref (Array Figure)) (args : Array Value) : IO (Array Value) := do
  match args.getD 0 (.matrix 1 2 #[0,1]) with
  | .matrix 1 2 d => modifyCurrentFig buf fun f => { f with yRange := some (d[0]!, d[1]!) }
  | _ => pure ()
  return #[]

-- ── 3-D plot builtins ────────────────────────────────────────────

def plot3Builtin (buf : IO.Ref (Array Figure)) (mk : MarkType)
    (args : Array Value) : IO (Array Value) := do
  match args with
  | #[xv, yv, zv] | #[xv, yv, zv, .string _] => do
      let xs ← valueToFloats xv
      let ys ← valueToFloats yv
      let zs ← valueToFloats zv
      let figs ← buf.get
      let color := nextColor figs
      modifyCurrentFig buf fun f => { f with is3D := true }
      addSeries buf { xData := xs, yData := ys, zData := zs, markType := mk, color }
  | _ => throw (IO.userError "plot3/scatter3: expected 3 numeric vector arguments")
  return #[]

/-- surf/mesh/waterfall/contourf(x, y, z)
    x: 1×cols vector, y: 1×rows vector, z: rows×cols matrix (or flat rows*cols vector).
    Expands x, y vectors into a full grid if needed. -/
def surfBuiltin (buf : IO.Ref (Array Figure)) (mk : MarkType)
    (args : Array Value) : IO (Array Value) := do
  match args with
  | #[xv, yv, zv] => do
      let xs ← valueToFloats xv
      let ys ← valueToFloats yv
      let zs ← valueToFloats zv
      let figs ← buf.get
      let color := nextColor figs
      -- Grid dims: prefer matrix shape of z; fall back to xs.size × ys.size
      let (rows, cols) := match zv with
        | .matrix r c _ => (r, c)
        | _ => (ys.size, xs.size)
      -- Build full grid X, Y matching z layout (row-major: row i, col j)
      let fullX := (Array.range rows).flatMap fun _i => xs
      let fullY := (Array.range rows).flatMap fun i =>
        (Array.range cols).map fun _j => ys.getD i 0.0
      -- Build z grid: if z already has rows*cols elements use as-is;
      -- if z has cols elements, replicate each row (z depends only on x);
      -- if z has rows elements, broadcast each column (z depends only on y);
      -- otherwise pad/trim.
      let n := rows * cols
      let fullZ :=
        if zs.size == n then zs
        else if zs.size == cols then
          (Array.range rows).flatMap fun _i => zs
        else if zs.size == rows then
          (Array.range rows).flatMap fun i =>
            (Array.range cols).map fun _j => zs.getD i 0.0
        else (Array.range n).map fun i => zs.getD i 0.0
      modifyCurrentFig buf fun f => { f with is3D := true }
      addSeries buf { xData := fullX, yData := fullY, zData := fullZ,
                      markType := mk, color, gridRows := rows, gridCols := cols }
  | _ => throw (IO.userError "surf/mesh/contourf: expected 3 matrix arguments")
  return #[]

def zlabelBuiltin (buf : IO.Ref (Array Figure)) (args : Array Value) : IO (Array Value) := do
  match args.getD 0 (.string "") with
  | .string s => do ensureFigure buf; modifyCurrentFig buf fun f => { f with zlabel := s }
  | _ => pure ()
  return #[]

def zlimBuiltin (buf : IO.Ref (Array Figure)) (args : Array Value) : IO (Array Value) := do
  match args.getD 0 (.matrix 1 2 #[0,1]) with
  | .matrix 1 2 d => modifyCurrentFig buf fun f => { f with zRange := some (d[0]!, d[1]!) }
  | _ => pure ()
  return #[]

-- ── Registration ─────────────────────────────────────────────────

/-- Register all plot builtins, closing over the given IO.Ref. -/
def register (buf : IO.Ref (Array Figure)) (env : Env) : Env :=
  env
  |>.registerBuiltin "plot"       (plotBuiltin buf .line)
  |>.registerBuiltin "scatter"    (plotBuiltin buf .scatter)
  |>.registerBuiltin "bar"        (plotBuiltin buf .bar)
  |>.registerBuiltin "stem"       (plotBuiltin buf .stem)
  |>.registerBuiltin "hist"       (histBuiltin buf)
  |>.registerBuiltin "histogram"  (histBuiltin buf)
  |>.registerBuiltin "plot3"      (plot3Builtin buf .line3)
  |>.registerBuiltin "scatter3"   (plot3Builtin buf .scatter3)
  |>.registerBuiltin "surf"       (surfBuiltin buf .surface)
  |>.registerBuiltin "mesh"       (surfBuiltin buf .surface)
  |>.registerBuiltin "waterfall"  (surfBuiltin buf .waterfall)
  |>.registerBuiltin "contourf"   (surfBuiltin buf .contour)
  |>.registerBuiltin "figure"     (figureBuiltin buf)
  |>.registerBuiltin "title"      (titleBuiltin buf)
  |>.registerBuiltin "xlabel"     (xlabelBuiltin buf)
  |>.registerBuiltin "ylabel"     (ylabelBuiltin buf)
  |>.registerBuiltin "zlabel"     (zlabelBuiltin buf)
  |>.registerBuiltin "legend"     (legendBuiltin buf)
  |>.registerBuiltin "hold_on"    (holdBuiltin buf true)
  |>.registerBuiltin "hold_off"   (holdBuiltin buf false)
  |>.registerBuiltin "xlim"       (xlimBuiltin buf)
  |>.registerBuiltin "ylim"       (ylimBuiltin buf)
  |>.registerBuiltin "zlim"       (zlimBuiltin buf)

end OctiveLean.PlotBuiltins
