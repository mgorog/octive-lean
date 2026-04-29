window;
import { jsx as h } from "react/jsx-runtime";

/** Renders pre-built SVG markup directly into the infoview.
 *  Props: { svgStr: string }
 */
function PlotDisplay({ svgStr }) {
  return h("div", {
    dangerouslySetInnerHTML: { __html: svgStr },
    style: { background: "#f8f8f8", padding: "4px", userSelect: "none" }
  });
}

export default PlotDisplay;
