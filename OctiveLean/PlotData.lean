namespace OctiveLean

def plotColors : Array String := #[
  "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728",
  "#9467bd", "#8c564b", "#e377c2", "#bcbd22"
]

inductive MarkType where
  | line | scatter | bar | stem | histogram
  | scatter3              -- 3-D scatter
  | line3                 -- 3-D line
  | surface               -- 3-D surface (mesh grid)
  | waterfall             -- waterfall / ribbon
  | contour               -- filled contour
  deriving Repr, BEq, Inhabited

structure PlotSeries where
  xData    : Array Float := #[]
  yData    : Array Float := #[]
  zData    : Array Float := #[]   -- empty for 2-D series
  markType : MarkType    := .line
  label    : String      := ""
  color    : String      := "#1f77b4"
  -- for surface/contour: grid dimensions (rows × cols)
  gridRows : Nat         := 0
  gridCols : Nat         := 0
  deriving Repr, Inhabited

structure Figure where
  series  : Array PlotSeries       := #[]
  title   : String                 := ""
  xlabel  : String                 := ""
  ylabel  : String                 := ""
  zlabel  : String                 := ""
  xRange  : Option (Float × Float) := none
  yRange  : Option (Float × Float) := none
  zRange  : Option (Float × Float) := none
  holdOn  : Bool                   := false
  is3D    : Bool                   := false
  deriving Repr, Inhabited

end OctiveLean
