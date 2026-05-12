# Typst documents tied to octive-lean

Typst sources for the m242 command-line diaries that demo octive-lean live
outside this repo, in `~/.env/typst/m242/`. The `.m` drivers in this repo's
root produce the data each diary plots; the typst files compile to PDF and
embed the plots, screenshots, and prose.

| Typst file | PDF | Topic | Driver(s) in this repo |
| --- | --- | --- | --- |
| `~/.env/typst/m242/CLDiary.typ` | `CLDiary.pdf` | Polynomial interpolation: Runge phenomenon, least-squares fit, splines, Chebyshev nodes | `Lab7Interp.m` |
| `~/.env/typst/m242/CLDiary_Sym.typ` | `CLDiary_Sym.pdf` | Symbolic Math Toolbox walkthrough (28 cheat-sheet ops via SymPy bridge) | `SymToolboxDemo.m` |
| `~/.env/typst/m242/CLDiary_Sim.typ` | `CLDiary_Sim.pdf` | Simulink/Xcos: 4 dynamic systems with Xcos canvas screenshots + native fletcher diagrams + RK4 trajectories | `Sim_Gravity.m`, `Sim_VanDerPol.m`, `Sim_Lorenz.m` |

## Build

```sh
cd ~/.env/typst/m242
typst compile CLDiary.typ
typst compile CLDiary_Sym.typ
typst compile CLDiary_Sim.typ
```

## Supporting assets (in `~/.env/typst/m242/`)

| Path | What |
| --- | --- |
| `sim_data/*.csv` | Trajectories produced by `Sim_*.m`, loaded by `CLDiary_Sim.typ` |
| `screenshots/xcos_*.png` | Xcos canvas screenshots for `CLDiary_Sim.typ` |
| `xcos/*.zcos` | Scilab/Xcos diagram files (Lorenz, Bouncing_ball, gensin, pendulum, Inverted_pendulum, Colpitts, Boost_Converter) |
| `xcos/BUILD_DIAGRAMS.md` | How to build / screenshot each Xcos diagram |

## Regenerating sim_data

```sh
cd ~/.env/lean/octive-lean
lake exe octive-lean Sim_Gravity.m   | grep , > ~/.env/typst/m242/sim_data/gravity.csv
lake exe octive-lean Sim_VanDerPol.m | grep , > ~/.env/typst/m242/sim_data/vanderpol.csv
lake exe octive-lean Sim_Lorenz.m    | grep , > ~/.env/typst/m242/sim_data/lorenz.csv
```

## Octive-lean features added for these diaries

- `polyfit`, `polyval`, `spline`, `linsolve` — `OctiveLean/Builtins.lean`
- `OctiveLean/SymPyBridge.lean` — persistent SymPy subprocess
- 25+ symbolic builtins (`diff`, `int`, `subs`, `simplify`, `solve`, `taylor`, `dsolve`, `jacobian`, `hessian`, `laplacian`, `symsum`, `rewrite`, `resultant`, `series`, `isolate`, `lhs`/`rhs`, `latex`, `pretty`, `vpa`, `coeffs`, `collect`, `expand`, `factor`, `gradient`, `piecewise`, `symfun`) — `OctiveLean/Builtins.lean`
- `Value.sym` variant + binop overloading for symbolic operands — `OctiveLean/Value.lean`, `OctiveLean/Eval.lean`
