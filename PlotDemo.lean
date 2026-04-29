import OctiveLean

-- Hover over each octave! block in the infoview to see the rendered chart.

-- Line plot of a sine wave
octave!
  x = linspace(0, 6.28, 64)
  y = sin(x)
  plot(x, y)
  title("Sine Wave")
  xlabel("x")
  ylabel("sin(x)")
octave_end

-- Scatter plot
octave!
  x = linspace(-3, 3, 40)
  y = x .* x
  scatter(x, y)
  title("Parabola")
octave_end

-- Bar chart
octave!
  bar([1, 2, 3, 4, 5], [3.2, 1.8, 4.5, 2.1, 3.9])
  title("Bar Chart")
  xlabel("Category")
  ylabel("Value")
octave_end

-- Histogram of residuals from a sine wave
octave!
  x = linspace(0, 6.28, 200)
  y = sin(x) .* cos(x)
  hist(y, 20)
  title("Histogram of sin(x)*cos(x)")
  xlabel("Value")
  ylabel("Count")
octave_end

-- Multi-series with hold_on / legend
octave!
  x = linspace(0, 6.28, 64)
  hold_on()
  plot(x, sin(x))
  plot(x, cos(x))
  hold_off()
  legend("sin", "cos")
  title("Trig Functions")
octave_end

-- Stem plot
octave!
  x = linspace(0, 3.14, 16)
  stem(x, sin(x))
  title("Stem Plot")
octave_end

-- ── 3-D: plot3 (helix) ───────────────────────────────────────────
octave!
  t  = linspace(0, 12.57, 80)
  xs = cos(t)
  ys = sin(t)
  zs = t .* 0.5
  plot3(xs, ys, zs)
  title("Helix")
  xlabel("cos t")
  ylabel("sin t")
  zlabel("t/2")
octave_end

-- ── 3-D: scatter3 ────────────────────────────────────────────────
octave!
  t = linspace(0, 6.28, 60)
  scatter3(cos(t), sin(t), t)
  title("Circular Scatter3")
octave_end

-- ── 3-D: surf (corrugated wave) ──────────────────────────────────
octave!
  x = linspace(0, 6.28, 24)
  y = linspace(0, 3, 12)
  surf(x, y, sin(x))
  title("Surface z = sin(x)")
  xlabel("x")
  ylabel("y")
  zlabel("z")
octave_end

-- ── 3-D: waterfall ───────────────────────────────────────────────
octave!
  x = linspace(0, 6.28, 30)
  y = linspace(0, 3, 8)
  waterfall(x, y, sin(x))
  title("Waterfall")
octave_end

-- ── 3-D: contourf ────────────────────────────────────────────────
octave!
  x = linspace(-3, 3, 30)
  y = linspace(-3, 3, 30)
  contourf(x, y, sin(x))
  title("Contour: sin(x)")
  xlabel("x")
  ylabel("y")
octave_end
