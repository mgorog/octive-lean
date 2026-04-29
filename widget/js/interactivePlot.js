window;
import { jsx as h } from "react/jsx-runtime";
import { useState, useRef, useCallback, useEffect } from "react";

const W = 500, H = 370;
const PL = 58, PR = 20, PT = 40, PB = 48;
const PW = W - PL - PR, PHt = H - PT - PB;

function niceTicks(lo, hi, n = 5) {
  if (!isFinite(lo) || !isFinite(hi) || lo >= hi) return [lo || 0];
  const raw = (hi - lo) / n;
  const mag = Math.pow(10, Math.floor(Math.log10(raw)));
  const norm = raw / mag;
  const step = norm < 1.5 ? 1 : norm < 3 ? 2 : norm < 7 ? 5 : 10;
  const s = step * mag;
  const ticks = [];
  for (let t = Math.ceil(lo / s) * s; t <= hi + s * 0.01; t += s)
    ticks.push(+t.toPrecision(10));
  return ticks.length ? ticks : [lo];
}

function fmt(v) {
  if (!isFinite(v)) return String(v);
  const a = Math.abs(v);
  if (a >= 1e5 || (a > 0 && a < 0.001)) return v.toExponential(3);
  return +v.toPrecision(5) + "";
}

function dataRange(series) {
  let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity;
  for (const s of series) {
    for (const x of s.xData) { if (x < x0) x0 = x; if (x > x1) x1 = x; }
    for (const y of s.yData) { if (y < y0) y0 = y; if (y > y1) y1 = y; }
  }
  if (!isFinite(x0)) { x0 = 0; x1 = 1; }
  if (!isFinite(y0)) { y0 = 0; y1 = 1; }
  if (x0 === x1) { x0 -= 0.5; x1 += 0.5; }
  if (y0 === y1) { y0 -= 0.5; y1 += 0.5; }
  const xp = (x1 - x0) * 0.05, yp = (y1 - y0) * 0.05;
  return { x0: x0 - xp, x1: x1 + xp, y0: y0 - yp, y1: y1 + yp };
}

function Figure2D({ fig }) {
  const [view, setView] = useState(() => dataRange(fig.series));
  const [tip, setTip] = useState(null);
  const svgRef = useRef(null);
  const drag = useRef(null);
  const clipId = useRef("clip-" + Math.random().toString(36).slice(2)).current;

  const sx = (x) => PL + (x - view.x0) / (view.x1 - view.x0) * PW;
  const sy = (y) => PT + (1 - (y - view.y0) / (view.y1 - view.y0)) * PHt;
  const ux = (px) => view.x0 + (px - PL) / PW * (view.x1 - view.x0);
  const uy = (py) => view.y0 + (1 - (py - PT) / PHt) * (view.y1 - view.y0);

  useEffect(() => {
    const el = svgRef.current;
    if (!el) return;
    const onWheel = (e) => {
      e.preventDefault();
      const rect = el.getBoundingClientRect();
      const cx = ux(e.clientX - rect.left);
      const cy = uy(e.clientY - rect.top);
      const f = e.deltaY > 0 ? 1.2 : 1 / 1.2;
      setView(v => ({
        x0: cx + (v.x0 - cx) * f, x1: cx + (v.x1 - cx) * f,
        y0: cy + (v.y0 - cy) * f, y1: cy + (v.y1 - cy) * f,
      }));
    };
    el.addEventListener("wheel", onWheel, { passive: false });
    return () => el.removeEventListener("wheel", onWheel);
  }, [view]);

  const onDown = useCallback((e) => {
    if (e.button !== 0) return;
    drag.current = { x: e.clientX, y: e.clientY, v: { ...view } };
    e.preventDefault();
  }, [view]);

  const onMove = useCallback((e) => {
    const rect = svgRef.current?.getBoundingClientRect();
    if (!rect) return;
    const px = e.clientX - rect.left, py = e.clientY - rect.top;

    if (drag.current) {
      const dx = e.clientX - drag.current.x, dy = e.clientY - drag.current.y;
      const xs = (drag.current.v.x1 - drag.current.v.x0) / PW;
      const ys = (drag.current.v.y1 - drag.current.v.y0) / PHt;
      setView({
        x0: drag.current.v.x0 - dx * xs, x1: drag.current.v.x1 - dx * xs,
        y0: drag.current.v.y0 + dy * ys, y1: drag.current.v.y1 + dy * ys,
      });
    }

    if (px < PL || px > W - PR || py < PT || py > H - PB) { setTip(null); return; }
    let best = null, bestD = 225;
    for (const s of fig.series) {
      for (let i = 0; i < s.xData.length; i++) {
        const dx = sx(s.xData[i]) - px, dy = sy(s.yData[i]) - py;
        const d2 = dx * dx + dy * dy;
        if (d2 < bestD) { bestD = d2; best = { x: s.xData[i], y: s.yData[i], px, py }; }
      }
    }
    setTip(best);
  }, [view, fig]);

  const onUp = () => { drag.current = null; };
  const onLeave = () => { drag.current = null; setTip(null); };

  const xTicks = niceTicks(view.x0, view.x1);
  const yTicks = niceTicks(view.y0, view.y1);
  const clip = `url(#${clipId})`;

  const seriesElems = fig.series.flatMap((s, si) => {
    const c = s.color || "#1f77b4";
    if (s.markType === "line" || s.markType === "histogram") {
      const pts = s.xData.map((x, i) => `${sx(x)},${sy(s.yData[i])}`).join(" ");
      return [h("polyline", { key: si, points: pts, fill: "none", stroke: c, strokeWidth: 2, clipPath: clip, strokeLinejoin: "round" })];
    }
    if (s.markType === "scatter") {
      return s.xData.map((x, i) =>
        h("circle", { key: `${si}-${i}`, cx: sx(x), cy: sy(s.yData[i]), r: 4, fill: c, clipPath: clip })
      );
    }
    if (s.markType === "bar") {
      const bw = Math.max(2, PW / (s.xData.length * 1.3));
      const z0 = Math.min(H - PB, Math.max(PT, sy(0)));
      return s.xData.map((x, i) => {
        const pyi = sy(s.yData[i]);
        return h("rect", { key: `${si}-${i}`, x: sx(x) - bw / 2, y: Math.min(pyi, z0), width: bw, height: Math.abs(z0 - pyi), fill: c, clipPath: clip });
      });
    }
    if (s.markType === "stem") {
      const z0 = Math.min(H - PB, Math.max(PT, sy(0)));
      return s.xData.flatMap((x, i) => {
        const pxi = sx(x), pyi = sy(s.yData[i]);
        return [
          h("line", { key: `${si}l${i}`, x1: pxi, y1: z0, x2: pxi, y2: pyi, stroke: c, strokeWidth: 1.5, clipPath: clip }),
          h("circle", { key: `${si}c${i}`, cx: pxi, cy: pyi, r: 4, fill: c, clipPath: clip }),
        ];
      });
    }
    return [];
  });

  const labeled = fig.series.filter(s => s.label);
  const legendElems = labeled.length === 0 ? [] : (() => {
    const lh = 18, bw = 130, bh = lh * labeled.length + 10;
    const bx = W - PR - bw - 4, by = PT + 6;
    return [
      h("rect", { key: "lb", x: bx, y: by, width: bw, height: bh, fill: "rgba(255,255,255,0.92)", stroke: "#ccc" }),
      ...labeled.flatMap((s, i) => [
        h("rect", { key: `li${i}`, x: bx + 6, y: by + 10 + i * lh - 7, width: 16, height: 10, fill: s.color }),
        h("text", { key: `lt${i}`, x: bx + 26, y: by + 10 + i * lh, fontSize: 11, fill: "#333" }, s.label),
      ]),
    ];
  })();

  return h("div", { style: { display: "inline-block", position: "relative", userSelect: "none" } },
    h("svg", { ref: svgRef, width: W, height: H, style: { cursor: "crosshair", background: "#fff", display: "block" }, onMouseDown: onDown, onMouseMove: onMove, onMouseUp: onUp, onMouseLeave: onLeave },
      h("defs", {}, h("clipPath", { id: clipId }, h("rect", { x: PL, y: PT, width: PW, height: PHt }))),
      h("rect", { x: PL, y: PT, width: PW, height: PHt, fill: "#fff", stroke: "#ccc" }),
      ...xTicks.map(t => h("line", { key: `xg${t}`, x1: sx(t), y1: PT, x2: sx(t), y2: H - PB, stroke: "#e5e5e5" })),
      ...yTicks.map(t => h("line", { key: `yg${t}`, x1: PL, y1: sy(t), x2: W - PR, y2: sy(t), stroke: "#e5e5e5" })),
      h("line", { x1: PL, y1: H - PB, x2: W - PR, y2: H - PB, stroke: "#333", strokeWidth: 1.5 }),
      h("line", { x1: PL, y1: PT, x2: PL, y2: H - PB, stroke: "#333", strokeWidth: 1.5 }),
      ...xTicks.flatMap(t => [
        h("line", { key: `xt${t}`, x1: sx(t), y1: H - PB, x2: sx(t), y2: H - PB + 5, stroke: "#333" }),
        h("text", { key: `xl${t}`, x: sx(t), y: H - PB + 17, textAnchor: "middle", fontSize: 11, fill: "#333" }, fmt(t)),
      ]),
      ...yTicks.flatMap(t => [
        h("line", { key: `yt${t}`, x1: PL - 5, y1: sy(t), x2: PL, y2: sy(t), stroke: "#333" }),
        h("text", { key: `yl${t}`, x: PL - 8, y: sy(t) + 4, textAnchor: "end", fontSize: 11, fill: "#333" }, fmt(t)),
      ]),
      fig.title && h("text", { x: W / 2, y: 22, textAnchor: "middle", fontSize: 14, fontWeight: "bold", fill: "#111" }, fig.title),
      fig.xlabel && h("text", { x: W / 2, y: H - 6, textAnchor: "middle", fontSize: 12, fill: "#333" }, fig.xlabel),
      fig.ylabel && h("text", { x: 14, y: PT + PHt / 2, textAnchor: "middle", fontSize: 12, fill: "#333", transform: `rotate(-90,14,${PT + PHt / 2})` }, fig.ylabel),
      ...seriesElems,
      ...legendElems,
      tip && h("g", { key: "xh" },
        h("line", { x1: PL, y1: sy(tip.y), x2: W - PR, y2: sy(tip.y), stroke: "#666", strokeWidth: 0.5, strokeDasharray: "3,3" }),
        h("line", { x1: sx(tip.x), y1: PT, x2: sx(tip.x), y2: H - PB, stroke: "#666", strokeWidth: 0.5, strokeDasharray: "3,3" }),
      ),
    ),
    tip && h("div", { key: "tt", style: { position: "absolute", left: tip.px + 12, top: tip.py - 28, background: "rgba(0,0,0,0.75)", color: "#fff", padding: "3px 7px", borderRadius: 4, fontSize: 12, pointerEvents: "none", whiteSpace: "nowrap" } },
      `(${fmt(tip.x)}, ${fmt(tip.y)})`
    ),
    h("button", { key: "rst", onClick: () => setView(dataRange(fig.series)), style: { position: "absolute", top: 4, right: 4, fontSize: 11, padding: "2px 6px", cursor: "pointer", background: "#f0f0f0", border: "1px solid #ccc", borderRadius: 3 } }, "⟳"),
  );
}

function proj3(x, y, z, az, el, x0, x1, y0, y1, z0, z1) {
  const nx = x1 > x0 ? (x - x0) / (x1 - x0) * 2 - 1 : 0;
  const ny = y1 > y0 ? (y - y0) / (y1 - y0) * 2 - 1 : 0;
  const nz = z1 > z0 ? (z - z0) / (z1 - z0) * 2 - 1 : 0;
  const azR = az * Math.PI / 180, elR = el * Math.PI / 180;
  const cAz = Math.cos(azR), sAz = Math.sin(azR);
  const cEl = Math.cos(elR), sEl = Math.sin(elR);
  const px = nx * cAz - ny * sAz;
  const py2 = nx * sAz * sEl + ny * cAz * sEl + nz * cEl;
  const sc = Math.min(PW, PHt) * 0.42;
  return [W / 2 + px * sc, H / 2 - py2 * sc];
}

function bounds3(series) {
  let x0 = Infinity, x1 = -Infinity, y0 = Infinity, y1 = -Infinity, z0 = Infinity, z1 = -Infinity;
  for (const s of series) {
    for (const x of s.xData) { if (x < x0) x0 = x; if (x > x1) x1 = x; }
    for (const y of s.yData) { if (y < y0) y0 = y; if (y > y1) y1 = y; }
    for (const z of (s.zData || [])) { if (z < z0) z0 = z; if (z > z1) z1 = z; }
  }
  if (!isFinite(x0)) { x0 = 0; x1 = 1; } if (x0 === x1) { x0 -= 0.5; x1 += 0.5; }
  if (!isFinite(y0)) { y0 = 0; y1 = 1; } if (y0 === y1) { y0 -= 0.5; y1 += 0.5; }
  if (!isFinite(z0)) { z0 = 0; z1 = 1; } if (z0 === z1) { z0 -= 0.5; z1 += 0.5; }
  return [x0, x1, y0, y1, z0, z1];
}

function Figure3D({ fig }) {
  const [rot, setRot] = useState({ az: 30, el: 20 });
  const drag = useRef(null);
  const [bx0, bx1, by0, by1, bz0, bz1] = bounds3(fig.series);
  const p = (x, y, z) => proj3(x, y, z, rot.az, rot.el, bx0, bx1, by0, by1, bz0, bz1);

  const onDown = (e) => { drag.current = { x: e.clientX, y: e.clientY, rot: { ...rot } }; e.preventDefault(); };
  const onMove = (e) => {
    if (!drag.current) return;
    const dx = e.clientX - drag.current.x, dy = e.clientY - drag.current.y;
    setRot({ az: drag.current.rot.az - dx * 0.5, el: Math.max(-89, Math.min(89, drag.current.rot.el + dy * 0.3)) });
  };
  const onUp = () => { drag.current = null; };

  const seriesElems = fig.series.flatMap((s, si) => {
    const c = s.color || "#1f77b4";
    if (s.markType === "scatter3") {
      const n = Math.min(s.xData.length, s.yData.length, (s.zData || []).length);
      return Array.from({ length: n }, (_, i) => {
        const [px, py] = p(s.xData[i], s.yData[i], s.zData[i]);
        return h("circle", { key: `${si}-${i}`, cx: px, cy: py, r: 3.5, fill: c });
      });
    }
    if (s.markType === "line3") {
      const n = Math.min(s.xData.length, s.yData.length, (s.zData || []).length);
      const pts = Array.from({ length: n }, (_, i) => p(s.xData[i], s.yData[i], s.zData[i])).map(([px, py]) => `${px},${py}`).join(" ");
      return [h("polyline", { key: si, points: pts, fill: "none", stroke: c, strokeWidth: 1.5, strokeLinejoin: "round" })];
    }
    if (s.markType === "surface") {
      const rows = s.gridRows, cols = s.gridCols;
      if (rows < 2 || cols < 2 || !s.zData) return [];
      const zArr = s.zData;
      const zMin = Math.min(...zArr), zMax = Math.max(...zArr), zRng = zMax === zMin ? 1 : zMax - zMin;
      return Array.from({ length: rows - 1 }, (_, i) =>
        Array.from({ length: cols - 1 }, (_, j) => {
          const g = (r, c) => [s.xData[r * cols + c] ?? 0, s.yData[r * cols + c] ?? 0, zArr[r * cols + c] ?? 0];
          const pts = [[i,j],[i,j+1],[i+1,j+1],[i+1,j]].map(([r,c]) => p(...g(r,c))).map(([x,y]) => `${x},${y}`).join(" ");
          const avgZ = (zArr[i*cols+j] + zArr[i*cols+j+1] + zArr[(i+1)*cols+j] + zArr[(i+1)*cols+j+1]) / 4;
          const t = (avgZ - zMin) / zRng;
          const rv = Math.round(255 * t), bv = Math.round(255 * (1 - t));
          return h("polygon", { key: `${i}-${j}`, points: pts, fill: `rgb(${rv},80,${bv})`, stroke: "rgba(0,0,0,0.1)", strokeWidth: 0.5, fillOpacity: 0.85 });
        })
      ).flat();
    }
    if (s.markType === "waterfall") {
      const rows = s.gridRows, cols = s.gridCols;
      if (rows < 2 || cols < 2) return [];
      return Array.from({ length: rows }, (_, i) => {
        const pts = Array.from({ length: cols }, (_, j) => p(s.xData[i*cols+j]??0, s.yData[i*cols+j]??0, (s.zData??[])[i*cols+j]??0)).map(([x,y]) => `${x},${y}`).join(" ");
        return h("polyline", { key: i, points: pts, fill: "none", stroke: c, strokeWidth: 1.5 });
      });
    }
    if (s.markType === "contour") {
      const rows = s.gridRows, cols = s.gridCols;
      if (rows < 2 || cols < 2 || !s.zData) return [];
      const zArr = s.zData, zMin = Math.min(...zArr), zMax = Math.max(...zArr), zRng = zMax === zMin ? 1 : zMax - zMin;
      const cw = PW / cols, ch = PHt / rows;
      return Array.from({ length: rows }, (_, i) =>
        Array.from({ length: cols }, (_, j) => {
          const t = (zArr[i*cols+j] - zMin) / zRng;
          const rv = Math.round(220 * t + 20), bv = Math.round(220 * (1 - t) + 20);
          return h("rect", { key: `${i}-${j}`, x: PL + j * cw, y: PT + (rows-1-i) * ch, width: cw + 1, height: ch + 1, fill: `rgb(${rv},60,${bv})` });
        })
      ).flat();
    }
    return [];
  });

  return h("div", { style: { display: "inline-block", position: "relative", userSelect: "none" } },
    h("svg", { width: W, height: H, style: { cursor: drag.current ? "grabbing" : "grab", background: "#f8f8f8", display: "block" }, onMouseDown: onDown, onMouseMove: onMove, onMouseUp: onUp, onMouseLeave: onUp },
      h("rect", { x: PL, y: PT, width: PW, height: PHt, fill: "#f0f0f0", stroke: "#ccc" }),
      ...seriesElems,
      fig.title && h("text", { x: W / 2, y: 22, textAnchor: "middle", fontSize: 14, fontWeight: "bold", fill: "#111" }, fig.title),
    ),
    h("div", { style: { textAlign: "center", fontSize: 11, color: "#888", marginTop: 2 } }, "drag to rotate"),
    h("button", { onClick: () => setRot({ az: 30, el: 20 }), style: { display: "block", margin: "2px auto", fontSize: 11, padding: "2px 6px", cursor: "pointer", background: "#f0f0f0", border: "1px solid #ccc", borderRadius: 3 } }, "⟳"),
  );
}

function InteractivePlot({ figures }) {
  if (!figures || figures.length === 0) return null;
  return h("div", { style: { display: "flex", flexWrap: "wrap", gap: "8px", padding: "4px" } },
    figures.map((fig, i) => h(fig.is3D ? Figure3D : Figure2D, { key: i, fig }))
  );
}

export default InteractivePlot;
