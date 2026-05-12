import ProofWidgets.Data.Html
import ProofWidgets.Component.Basic
import OctiveLean.PlotData

/-! Renders plot figures via Plotly.js in the infoview. Figure data is
    JSON-encoded and passed to a React component bundled with Plotly
    (see `widget/js/interactivePlot.js`). The component handles
    pan/zoom/legend/tooltips and translates our markType taxonomy to
    Plotly trace types. -/

namespace OctiveLean.PlotWidget

open ProofWidgets Lean

-- ── User-facing Lean option ───────────────────────────────────────

register_option octive.plotTheme : String := {
  defValue := "auto"
  descr    := "Plot theme used by the `octave!` macro. \
               \"auto\" detects VSCode's theme (vscode-dark class or \
               prefers-color-scheme); \"dark\" and \"light\" force the choice."
}

-- ── Props ─────────────────────────────────────────────────────────

structure OctivePlotProps where
  figures : Array Json
  theme   : String
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
    ("gridCols", toJson s.gridCols),
    ("nbins",    toJson s.nbins)
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

-- ── Entry points ──────────────────────────────────────────────────

def render (figs : Array Figure) (theme : String := "auto") : Html :=
  if figs.isEmpty then Html.text ""
  else
    Html.ofComponent OctivePlotWidget
      { figures := figs.map encodeFigure, theme }
      #[]

/-- Render figures and, if a message is present, an error block beneath.
    Used by the `octave!` macro so runtime failures surface inside the
    infoview panel instead of getting eaten by `IO.eprintln`. -/
def renderWithError (figs : Array Figure) (theme : String) (err : Option String) : Html :=
  let chart := render figs theme
  match err with
  | none     => chart
  | some msg =>
      let errStyle : Json := Json.mkObj
        [ ("color",       Json.str "#d44")
        , ("fontFamily",  Json.str "monospace")
        , ("whiteSpace",  Json.str "pre-wrap")
        , ("padding",     Json.str "6px 8px")
        , ("margin",      Json.str "4px 0")
        , ("borderLeft",  Json.str "3px solid #d44")
        , ("background",  Json.str "rgba(220,80,80,0.08)") ]
      let errBox : Html := Html.element "pre" #[("style", errStyle)] #[Html.text msg]
      if figs.isEmpty then errBox
      else Html.element "div" #[] #[chart, errBox]

end OctiveLean.PlotWidget
