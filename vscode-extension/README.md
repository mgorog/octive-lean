# octive-lean DSL extension

Context-sensitive completion and hover help for `octave! { ... }` blocks inside Lean 4 files.

## What it does

- **Inside an `octave! { ... }` block** (or `octave_program!`), pressing trigger keys (`Ctrl-Space`) or typing surfaces a list of Octave builtins with signatures and one-line summaries. Hovering on a known builtin shows the same metadata.
- **Outside the block**, the extension contributes nothing — Lean's normal LSP completion handles the file.

Block detection is purely syntactic: the extension scans the document for `octave! {` and brace-matches forward. No Lean LSP changes required.

## Install (development mode)

```sh
cd vscode-extension
npm install
npm run build
```

Then in VSCodium / VSCode:

1. Open `octive-lean/vscode-extension` as a folder.
2. Press `F5` ("Run Extension") to launch a development host window.
3. In the new window, open a `.lean` file that uses `octave! { ... }`.
4. Position the cursor inside the block, press `Ctrl-Space`, and you should see Octave builtins (`sin`, `plot`, `disp`, etc.) suggested with documentation.

## Configuration

Settings (under `octiveLean.*`):

| Key | Default | Effect |
| --- | --- | --- |
| `octiveLean.completionEnabled` | `true` | Show builtin completions inside `octave!` blocks |
| `octiveLean.hoverEnabled` | `true` | Show builtin hover help inside `octave!` blocks |

## Keeping in sync with octive-lean

`src/builtins.ts` mirrors the names registered in `OctiveLean/Builtins.lean` and `OctiveLean/PlotBuiltins.lean`. Run

```sh
grep -E '\|>.registerBuiltin "' ../OctiveLean/Builtins.lean ../OctiveLean/PlotBuiltins.lean \
  | sed -E 's/.*registerBuiltin "([^"]+)".*/\1/' | sort -u
```

to diff registered names against the table when adding new builtins.
