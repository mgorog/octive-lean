import OctiveLean.PlotData

namespace OctiveLean.PlotSVG

-- ── Canvas layout ────────────────────────────────────────────────
def canvasW : Float := 520
def canvasH : Float := 400
def marginL : Float := 72
def marginR : Float := 20
def marginT : Float := 44
def marginB : Float := 58

def plotL := marginL
def plotR := canvasW - marginR
def plotT := marginT
def plotB := canvasH - marginB

-- ── Numeric helpers ───────────────────────────────────────────────

/-- Format a float for SVG attributes (2 decimal places max). -/
def ff (x : Float) : String := toString ((x * 100.0).round / 100.0)

def mapX (v vMin vMax : Float) : Float :=
  if vMax == vMin then (plotL + plotR) / 2.0
  else plotL + (v - vMin) / (vMax - vMin) * (plotR - plotL)

def mapY (v vMin vMax : Float) : Float :=
  if vMax == vMin then (plotT + plotB) / 2.0
  else plotB - (v - vMin) / (vMax - vMin) * (plotB - plotT)

def arrayMin (a : Array Float) : Float := a.foldl min (a.getD 0 0.0)
def arrayMax (a : Array Float) : Float := a.foldl max (a.getD 0 0.0)

/-- ~5 round tick values spanning [lo, hi]. -/
def niceTicks (lo hi : Float) : Array Float :=
  if lo >= hi then #[lo, hi]
  else
    let range := hi - lo
    let rough := range / 5.0
    let mag   := (Float.log rough / Float.log 10.0).floor
    let power := (10.0 : Float) ^ mag
    let norm  := rough / power
    let step  :=
      if norm < 1.5 then power
      else if norm < 3.5 then 2.0 * power
      else if norm < 7.5 then 5.0 * power
      else 10.0 * power
    let start := (lo / step).ceil * step
    let count := ((hi - start) / step + 1.5).floor.toUInt64.toNat + 1
    (Array.range count).filterMap fun i =>
      let t := start + i.toFloat * step
      if t <= hi + step * 0.001 then some t else none

-- ── SVG element builders ─────────────────────────────────────────

def svgLine (x1 y1 x2 y2 : Float) (stroke : String) (sw : String := "1") : String :=
  s!"<line x1=\"{ff x1}\" y1=\"{ff y1}\" x2=\"{ff x2}\" y2=\"{ff y2}\" \
     stroke=\"{stroke}\" stroke-width=\"{sw}\"/>"

def svgRect (x y w h : Float) (fill : String) (stroke : String := "none") : String :=
  s!"<rect x=\"{ff x}\" y=\"{ff y}\" width=\"{ff w}\" height=\"{ff h}\" \
     fill=\"{fill}\" stroke=\"{stroke}\"/>"

def svgText (x y : Float) (txt : String) (anchor : String) (size : String := "11")
    (fill : String := "#333") : String :=
  s!"<text x=\"{ff x}\" y=\"{ff y}\" text-anchor=\"{anchor}\" \
     font-size=\"{size}\" fill=\"{fill}\">{txt}</text>"

def svgCircle (cx cy r : Float) (fill : String) : String :=
  s!"<circle cx=\"{ff cx}\" cy=\"{ff cy}\" r=\"{ff r}\" fill=\"{fill}\"/>"

def svgPolyline (pts : Array (Float × Float)) (stroke : String) (sw : String := "2") : String :=
  let pStr := (pts.map fun (x, y) => s!"{ff x},{ff y}").toList |> String.intercalate " "
  s!"<polyline points=\"{pStr}\" fill=\"none\" stroke=\"{stroke}\" \
     stroke-width=\"{sw}\" stroke-linejoin=\"round\" stroke-linecap=\"round\"/>"

def svgPolygon (pts : Array (Float × Float)) (fill stroke : String) (opacity : String := "1") : String :=
  let pStr := (pts.map fun (x, y) => s!"{ff x},{ff y}").toList |> String.intercalate " "
  s!"<polygon points=\"{pStr}\" fill=\"{fill}\" fill-opacity=\"{opacity}\" \
     stroke=\"{stroke}\" stroke-width=\"0.5\"/>"

-- ── Axes ─────────────────────────────────────────────────────────

def renderAxes (xMin xMax yMin yMax : Float) (fig : Figure) : String := Id.run do
  let xTicks := niceTicks xMin xMax
  let yTicks := niceTicks yMin yMax
  let mut p : Array String := #[]

  p := p.push (svgRect plotL plotT (plotR - plotL) (plotB - plotT) "white" "#ccc")

  for xt in xTicks do
    p := p.push (svgLine (mapX xt xMin xMax) plotT (mapX xt xMin xMax) plotB "#e5e5e5")
  for yt in yTicks do
    p := p.push (svgLine plotL (mapY yt yMin yMax) plotR (mapY yt yMin yMax) "#e5e5e5")

  p := p.push (svgLine plotL plotB plotR plotB "#333" "1.5")
  p := p.push (svgLine plotL plotT plotL plotB "#333" "1.5")

  for xt in xTicks do
    let px := mapX xt xMin xMax
    p := p.push (svgLine px plotB px (plotB + 5) "#333")
    p := p.push (svgText px (plotB + 17) (ff xt) "middle")

  for yt in yTicks do
    let py := mapY yt yMin yMax
    p := p.push (svgLine (plotL - 5) py plotL py "#333")
    p := p.push (svgText (plotL - 8) (py + 4) (ff yt) "end")

  unless fig.title.isEmpty do
    p := p.push (svgText (canvasW / 2) 20 fig.title "middle" "14" "#111")
  unless fig.xlabel.isEmpty do
    p := p.push (svgText (canvasW / 2) (canvasH - 8) fig.xlabel "middle" "12")
  unless fig.ylabel.isEmpty do
    let cx := 14.0; let cy := (plotT + plotB) / 2.0
    p := p.push
      s!"<text x=\"{ff cx}\" y=\"{ff cy}\" text-anchor=\"middle\" font-size=\"12\" \
         fill=\"#333\" transform=\"rotate(-90,{ff cx},{ff cy})\">{fig.ylabel}</text>"

  return String.intercalate "\n  " p.toList

-- ── Series renderers ─────────────────────────────────────────────

def renderLineSeries (s : PlotSeries) (xMin xMax yMin yMax : Float) : String :=
  if s.xData.isEmpty then ""
  else svgPolyline (s.xData.zip s.yData |>.map fun (x, y) =>
         (mapX x xMin xMax, mapY y yMin yMax)) s.color

def renderScatterSeries (s : PlotSeries) (xMin xMax yMin yMax : Float) : String :=
  if s.xData.isEmpty then ""
  else String.intercalate "\n  " <|
    (s.xData.zip s.yData |>.map fun (x, y) =>
      svgCircle (mapX x xMin xMax) (mapY y yMin yMax) 4 s.color).toList

def renderBarSeries (s : PlotSeries) (xMin xMax yMin yMax : Float) : String :=
  if s.xData.isEmpty then ""
  else
    let n    := s.xData.size
    let bw   := max 2.0 ((plotR - plotL) / (n.toFloat * 1.3))
    let zero := min plotB (max plotT (mapY 0.0 yMin yMax))
    String.intercalate "\n  " <|
      (s.xData.zip s.yData |>.map fun (x, y) =>
        let px := mapX x xMin xMax - bw / 2.0
        let py := mapY y yMin yMax
        svgRect px (min py zero) bw (Float.abs (zero - py)) s.color).toList

def renderStemSeries (s : PlotSeries) (xMin xMax yMin yMax : Float) : String :=
  if s.xData.isEmpty then ""
  else
    let zero := min plotB (max plotT (mapY 0.0 yMin yMax))
    String.intercalate "\n  " <|
      (s.xData.zip s.yData |>.map fun (x, y) =>
        let px := mapX x xMin xMax
        let py := mapY y yMin yMax
        svgLine px zero px py s.color ++ "  " ++ svgCircle px py 4 s.color).toList

-- ── 3-D projection helpers ────────────────────────────────────────
-- Isometric-ish perspective: rotate 30° around Z, tilt 20° around X

def proj3 (x y z xMin xMax yMin yMax zMin zMax : Float) : Float × Float :=
  -- Normalise to [-1, 1]
  let nx := if xMax == xMin then 0.0 else 2.0 * (x - xMin) / (xMax - xMin) - 1.0
  let ny := if yMax == yMin then 0.0 else 2.0 * (y - yMin) / (yMax - yMin) - 1.0
  let nz := if zMax == zMin then 0.0 else 2.0 * (z - zMin) / (zMax - zMin) - 1.0
  -- Rotation angles (radians)
  let azim  : Float := 0.5236  -- 30°
  let elev  : Float := 0.3491  -- 20°
  let cosA := Float.cos azim;  let sinA := Float.sin azim
  let cosE := Float.cos elev;  let sinE := Float.sin elev
  -- Rotate around Z by azim, then tilt by elev
  let rx  := cosA * nx - sinA * ny
  let ry0 := sinA * nx + cosA * ny
  let ry  := cosE * ry0 - sinE * nz
  let _ := sinE * ry0 + cosE * nz  -- depth (unused for now)
  -- Map to canvas plot area
  let cx := (plotL + plotR) / 2.0
  let cy := (plotT + plotB) / 2.0
  let scaleX := (plotR - plotL) * 0.45
  let scaleY := (plotB - plotT) * 0.40
  (cx + rx * scaleX, cy - ry * scaleY)

def renderScatter3Series (s : PlotSeries) : String :=
  if s.xData.isEmpty || s.zData.isEmpty then ""
  else
    let xMin := arrayMin s.xData; let xMax := arrayMax s.xData
    let yMin := arrayMin s.yData; let yMax := arrayMax s.yData
    let zMin := arrayMin s.zData; let zMax := arrayMax s.zData
    let n := min s.xData.size (min s.yData.size s.zData.size)
    String.intercalate "\n  " <|
      (Array.range n).map (fun i =>
        let x := s.xData[i]!; let y := s.yData[i]!; let z := s.zData[i]!
        let (px, py) := proj3 x y z xMin xMax yMin yMax zMin zMax
        svgCircle px py 3.5 s.color) |>.toList

def renderLine3Series (s : PlotSeries) : String :=
  if s.xData.isEmpty || s.zData.isEmpty then ""
  else
    let xMin := arrayMin s.xData; let xMax := arrayMax s.xData
    let yMin := arrayMin s.yData; let yMax := arrayMax s.yData
    let zMin := arrayMin s.zData; let zMax := arrayMax s.zData
    let n := min s.xData.size (min s.yData.size s.zData.size)
    let pts := (Array.range n).map fun i =>
      let x := s.xData[i]!; let y := s.yData[i]!; let z := s.zData[i]!
      proj3 x y z xMin xMax yMin yMax zMin zMax
    svgPolyline pts s.color

def renderSurfaceSeries (s : PlotSeries) : String :=
  let rows := s.gridRows; let cols := s.gridCols
  if rows < 2 || cols < 2 || s.xData.size < rows * cols then ""
  else
    let xMin := arrayMin s.xData; let xMax := arrayMax s.xData
    let yMin := arrayMin s.yData; let yMax := arrayMax s.yData
    let zMin := arrayMin s.zData; let zMax := arrayMax s.zData
    let zRange := if zMax == zMin then 1.0 else zMax - zMin
    -- Back-to-front: render patches from far to near (approximate)
    let patches := (Array.range (rows - 1)).flatMap fun i =>
      (Array.range (cols - 1)).map fun j =>
        let idx := fun r c => r * cols + c
        let getP := fun r c =>
          let x := s.xData.getD (idx r c) 0.0
          let y := s.yData.getD (idx r c) 0.0
          let z := s.zData.getD (idx r c) 0.0
          (x, y, z)
        let avgZ := ((s.zData.getD (idx i j) 0.0) + (s.zData.getD (idx i (j+1)) 0.0) +
                     (s.zData.getD (idx (i+1) j) 0.0) + (s.zData.getD (idx (i+1) (j+1)) 0.0)) / 4.0
        -- Sort key: far patches (small i+j) first
        let sortKey := i + j
        (sortKey, avgZ, zRange, i, j, getP)
    let pr := fun x y z => proj3 x y z xMin xMax yMin yMax zMin zMax
    -- Build polygons
    String.intercalate "\n  " <|
      (patches.map fun (_, avgZ, zRng, i, j, getP) =>
        let (x0,y0,z0) := getP i j
        let (x1,y1,z1) := getP i (j+1)
        let (x2,y2,z2) := getP (i+1) (j+1)
        let (x3,y3,z3) := getP (i+1) j
        -- Color by z: cool (blue) → warm (red)
        let t := (avgZ - zMin) / zRng
        let rv := (255.0 * t).round.toUInt8
        let bv := (255.0 * (1.0 - t)).round.toUInt8
        let gv : UInt8 := 80
        let fill := s!"rgb({rv},{gv},{bv})"
        svgPolygon #[pr x0 y0 z0, pr x1 y1 z1, pr x2 y2 z2, pr x3 y3 z3] fill "#0002" "0.85").toList

def renderWaterfallSeries (s : PlotSeries) : String :=
  -- Render as multiple vertical line3 slices
  let rows := s.gridRows; let cols := s.gridCols
  if rows < 2 || cols < 2 || s.xData.size < rows * cols then ""
  else
    let xMin := arrayMin s.xData; let xMax := arrayMax s.xData
    let yMin := arrayMin s.yData; let yMax := arrayMax s.yData
    let zMin := arrayMin s.zData; let zMax := arrayMax s.zData
    String.intercalate "\n  " <| (Array.range rows).toList.map fun i =>
      let pts := (Array.range cols).map fun j =>
        let x := s.xData.getD (i * cols + j) 0.0
        let y := s.yData.getD (i * cols + j) 0.0
        let z := s.zData.getD (i * cols + j) 0.0
        proj3 x y z xMin xMax yMin yMax zMin zMax
      svgPolyline pts s.color "1.5"

def renderContourSeries (s : PlotSeries) : String :=
  -- Approximate contour as a colored scatter grid
  let rows := s.gridRows; let cols := s.gridCols
  if rows < 2 || cols < 2 || s.xData.size < rows * cols then ""
  else
    let zMin := arrayMin s.zData; let zMax := arrayMax s.zData
    let zRng := if zMax == zMin then 1.0 else zMax - zMin
    -- Render as colored rectangles on regular 2-D grid
    let cellW := (plotR - plotL) / cols.toFloat
    let cellH := (plotB - plotT) / rows.toFloat
    String.intercalate "\n  " <|
      (Array.range rows).toList.flatMap fun i =>
        (Array.range cols).toList.map fun j =>
          let z := s.zData.getD (i * cols + j) 0.0
          let t := (z - zMin) / zRng
          let r := (220.0 * t + 20.0).round.toUInt8
          let b := (220.0 * (1.0 - t) + 20.0).round.toUInt8
          let g : UInt8 := 60
          let fill := s!"rgb({r},{g},{b})"
          let px := plotL + j.toFloat * cellW
          let py := plotT + (rows - 1 - i).toFloat * cellH
          svgRect px py (cellW + 1.0) (cellH + 1.0) fill

-- ── 3-D axis frame ────────────────────────────────────────────────

def render3DAxes (fig : Figure) (xMin xMax yMin yMax zMin zMax : Float) : String := Id.run do
  let mut p : Array String := #[]
  p := p.push (svgRect plotL plotT (plotR - plotL) (plotB - plotT) "#f0f0f0" "#ccc")
  -- Draw the three axis lines
  let origin := proj3 xMin yMin zMin xMin xMax yMin yMax zMin zMax
  let xEnd   := proj3 xMax yMin zMin xMin xMax yMin yMax zMin zMax
  let yEnd   := proj3 xMin yMax zMin xMin xMax yMin yMax zMin zMax
  let zEnd   := proj3 xMin yMin zMax xMin xMax yMin yMax zMin zMax
  p := p.push (svgLine origin.1 origin.2 xEnd.1 xEnd.2 "#e44" "1.5")
  p := p.push (svgLine origin.1 origin.2 yEnd.1 yEnd.2 "#4a4" "1.5")
  p := p.push (svgLine origin.1 origin.2 zEnd.1 zEnd.2 "#44e" "1.5")
  -- Axis tick labels
  let xTicks := niceTicks xMin xMax
  for xt in xTicks do
    let pt := proj3 xt yMin zMin xMin xMax yMin yMax zMin zMax
    p := p.push (svgText pt.1 (pt.2 + 14) (ff xt) "middle" "9")
  let yTicks := niceTicks yMin yMax
  for yt in yTicks do
    let pt := proj3 xMin yt zMin xMin xMax yMin yMax zMin zMax
    p := p.push (svgText (pt.1 - 6) (pt.2 + 4) (ff yt) "end" "9")
  let zTicks := niceTicks zMin zMax
  for zt in zTicks do
    let pt := proj3 xMin yMin zt xMin xMax yMin yMax zMin zMax
    p := p.push (svgText (pt.1 - 4) pt.2 (ff zt) "end" "9")
  -- Labels
  unless fig.title.isEmpty do
    p := p.push (svgText (canvasW / 2) 20 fig.title "middle" "14" "#111")
  unless fig.xlabel.isEmpty do
    let mid := proj3 ((xMin + xMax) / 2.0) yMin zMin xMin xMax yMin yMax zMin zMax
    p := p.push (svgText mid.1 (mid.2 + 24) fig.xlabel "middle" "11" "#e44")
  unless fig.ylabel.isEmpty do
    let mid := proj3 xMin ((yMin + yMax) / 2.0) zMin xMin xMax yMin yMax zMin zMax
    p := p.push (svgText (mid.1 - 10) mid.2 fig.ylabel "end" "11" "#4a4")
  unless fig.zlabel.isEmpty do
    let mid := proj3 xMin yMin ((zMin + zMax) / 2.0) xMin xMax yMin yMax zMin zMax
    p := p.push (svgText (mid.1 - 6) mid.2 fig.zlabel "end" "11" "#44e")
  return String.intercalate "\n  " p.toList

-- ── Figure bounds ────────────────────────────────────────────────

def computeBounds (fig : Figure) : Float × Float × Float × Float :=
  let allX := fig.series.foldl (fun a s => a ++ s.xData) #[]
  let allY := fig.series.foldl (fun a s => a ++ s.yData) #[]
  if allX.isEmpty || allY.isEmpty then (0, 1, 0, 1)
  else
    let xMin := arrayMin allX;  let xMax := arrayMax allX
    let yMin := arrayMin allY;  let yMax := arrayMax allY
    let hasBar := fig.series.any fun s => s.markType == .bar || s.markType == .histogram
    let yMin' := if hasBar then min yMin 0.0 else yMin
    let xPad := max 0.5 ((xMax - xMin) * 0.05)
    let yPad := max 0.5 ((yMax - yMin') * 0.05)
    let (xLo, xHi) := fig.xRange.getD (xMin - xPad, xMax + xPad)
    let (yLo, yHi) := fig.yRange.getD (yMin' - yPad, yMax + yPad)
    (xLo, xHi, yLo, yHi)

def computeBounds3 (fig : Figure) : Float × Float × Float × Float × Float × Float :=
  let allX := fig.series.foldl (fun a s => a ++ s.xData) #[]
  let allY := fig.series.foldl (fun a s => a ++ s.yData) #[]
  let allZ := fig.series.foldl (fun a s => a ++ s.zData) #[]
  let xMin := arrayMin allX; let xMax := arrayMax allX
  let yMin := arrayMin allY; let yMax := arrayMax allY
  let zMin := arrayMin allZ; let zMax := arrayMax allZ
  let pad := fun lo hi =>
    let p := max 0.01 ((hi - lo) * 0.05)
    (lo - p, hi + p)
  let (xLo, xHi) := fig.xRange.getD (pad xMin xMax)
  let (yLo, yHi) := fig.yRange.getD (pad yMin yMax)
  let (zLo, zHi) := fig.zRange.getD (pad zMin zMax)
  (xLo, xHi, yLo, yHi, zLo, zHi)

-- ── Legend ───────────────────────────────────────────────────────

def renderLegend (series : Array PlotSeries) : String :=
  let labeled := series.filter (fun s => !s.label.isEmpty)
  if labeled.isEmpty then ""
  else
    let lh := 18.0;  let bw := 130.0
    let bh := lh * labeled.size.toFloat + 10.0
    let bx := plotR - bw - 4.0;  let boxY := plotT + 6.0
    let bg := svgRect bx boxY bw bh "rgba(255,255,255,0.85)" "#ccc"
    let items := labeled.mapIdx fun i s =>
      let iy := boxY + 10.0 + i.toFloat * lh
      svgRect (bx + 6) (iy - 7) 16 10 s.color ++ "  " ++
      svgText (bx + 26) iy s.label "start"
    bg ++ "\n  " ++ String.intercalate "\n  " items.toList

-- ── Full figure renderer ─────────────────────────────────────────

def renderFigure (fig : Figure) : String :=
  if fig.is3D then
    let (x0, x1, y0, y1, z0, z1) := computeBounds3 fig
    let axes := render3DAxes fig x0 x1 y0 y1 z0 z1
    let series := fig.series.map fun s =>
      match s.markType with
      | .scatter3  => renderScatter3Series s
      | .line3     => renderLine3Series s
      | .surface   => renderSurfaceSeries s
      | .waterfall => renderWaterfallSeries s
      | .contour   => renderContourSeries s
      | _          => ""
    let legend := renderLegend fig.series
    let inner := String.intercalate "\n  " ([axes] ++ series.toList ++ [legend])
    s!"<svg xmlns=\"http://www.w3.org/2000/svg\" \
       width=\"{ff canvasW}\" height=\"{ff canvasH}\" \
       style=\"font-family:sans-serif;display:block;margin:4px auto\">\n  {inner}\n</svg>"
  else
    let (x0, x1, y0, y1) := computeBounds fig
    let axes   := renderAxes x0 x1 y0 y1 fig
    let series := fig.series.map fun s =>
      match s.markType with
      | .line | .histogram => renderLineSeries s x0 x1 y0 y1
      | .scatter  => renderScatterSeries s x0 x1 y0 y1
      | .bar      => renderBarSeries s x0 x1 y0 y1
      | .stem     => renderStemSeries s x0 x1 y0 y1
      | _         => ""
    let legend := renderLegend fig.series
    let inner  := String.intercalate "\n  " ([axes] ++ series.toList ++ [legend])
    s!"<svg xmlns=\"http://www.w3.org/2000/svg\" \
       width=\"{ff canvasW}\" height=\"{ff canvasH}\" \
       style=\"font-family:sans-serif;display:block;margin:4px auto\">\n  {inner}\n</svg>"

def renderAll (figs : Array Figure) : String :=
  let inner := String.intercalate "\n" (figs.map renderFigure).toList
  "<div style=\"background:#f8f8f8;padding:4px\">\n" ++ inner ++ "\n</div>"

end OctiveLean.PlotSVG
