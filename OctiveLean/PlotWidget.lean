import ProofWidgets.Data.Html
import ProofWidgets.Component.Basic
import OctiveLean.PlotData

/-! Renders plot figures as an interactive widget in the infoview.
    Figure data is encoded as JSON and passed to the React component
    in `widget/js/interactivePlot.js`, which handles zoom, pan, and hover. -/

namespace OctiveLean.PlotWidget

open ProofWidgets Lean

-- ── Props ─────────────────────────────────────────────────────────

structure OctivePlotProps where
  figures : Array Json
  deriving Server.RpcEncodable

-- ── Widget module ─────────────────────────────────────────────────

@[widget_module]
def OctivePlotWidget : Component OctivePlotProps where
  javascript := include_str ".." / "widget" / "js" / "interactivePlot.js"

-- ── JSON encoding of plot data ────────────────────────────────────

private def encodeMarkType : MarkType → String
  | .line       => "line"
  | .scatter    => "scatter"
  | .bar        => "bar"
  | .stem       => "stem"
  | .histogram  => "histogram"
  | .scatter3   => "scatter3"
  | .line3      => "line3"
  | .surface    => "surface"
  | .waterfall  => "waterfall"
  | .contour    => "contour"

private def encodeFloatArr (a : Array Float) : Json :=
  Json.arr (a.map toJson)

private def encodeSeries (s : PlotSeries) : Json :=
  Json.mkObj [
    ("xData",    encodeFloatArr s.xData),
    ("yData",    encodeFloatArr s.yData),
    ("zData",    encodeFloatArr s.zData),
    ("markType", Json.str (encodeMarkType s.markType)),
    ("label",    Json.str s.label),
    ("color",    Json.str s.color),
    ("gridRows", toJson s.gridRows),
    ("gridCols", toJson s.gridCols)
  ]

private def encodeFigure (fig : Figure) : Json :=
  Json.mkObj [
    ("title",   Json.str fig.title),
    ("xlabel",  Json.str fig.xlabel),
    ("ylabel",  Json.str fig.ylabel),
    ("zlabel",  Json.str fig.zlabel),
    ("is3D",    Json.bool fig.is3D),
    ("series",  Json.arr (fig.series.map encodeSeries))
  ]

-- ── Entry point ───────────────────────────────────────────────────

def render (figs : Array Figure) : Html :=
  if figs.isEmpty then Html.text ""
  else
    Html.ofComponent OctivePlotWidget
      { figures := figs.map encodeFigure }
      #[]

end OctiveLean.PlotWidget
