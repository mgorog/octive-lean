// octive-lean DSL companion extension.
//
// Adds context-aware completion + hover inside `octave! { ... }` blocks
// within Lean 4 files. Outside such blocks, defers to the Lean LSP.

import * as vscode from "vscode";
import { BUILTINS, Builtin } from "./builtins";

// ── Block detection ────────────────────────────────────────────────
//
// We rely on a robust enough regex to find `octave!` blocks: the macro
// signature is `octave! { ... }` (or `octave_program! name { ... }`),
// and `{`/`}` may be nested via matrix literals `[ ; ]` — but never via
// curly braces in our Octave subset. So a brace-depth scan from the
// start of every match correctly bounds the block.

function findOctaveBlocks(text: string): { start: number; end: number }[] {
  const out: { start: number; end: number }[] = [];
  const re = /\boctave(?:_program)?!\s*(?:[A-Za-z_][A-Za-z0-9_]*\s*)?\{/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(text)) !== null) {
    const open = m.index + m[0].length - 1;        // index of `{`
    let depth = 1;
    let i = open + 1;
    while (i < text.length && depth > 0) {
      const c = text.charCodeAt(i);
      if (c === 0x7b /* { */) depth++;
      else if (c === 0x7d /* } */) depth--;
      i++;
    }
    if (depth === 0) out.push({ start: open + 1, end: i - 1 });
  }
  return out;
}

function isInsideOctaveBlock(doc: vscode.TextDocument, pos: vscode.Position): boolean {
  const offset = doc.offsetAt(pos);
  for (const b of findOctaveBlocks(doc.getText())) {
    if (offset > b.start && offset <= b.end) return true;
  }
  return false;
}

// ── Markdown builder ──────────────────────────────────────────────

function builtinMarkdown(name: string, b: Builtin): vscode.MarkdownString {
  const md = new vscode.MarkdownString();
  md.appendCodeblock(b.signature, "octave");
  md.appendMarkdown(`\n${b.summary}\n\n*octive-lean · ${b.category}*`);
  md.isTrusted = false;
  return md;
}

// ── Completion ────────────────────────────────────────────────────

class OctaveCompletionProvider implements vscode.CompletionItemProvider {
  provideCompletionItems(
    document: vscode.TextDocument,
    position: vscode.Position
  ): vscode.ProviderResult<vscode.CompletionItem[] | vscode.CompletionList> {
    const cfg = vscode.workspace.getConfiguration("octiveLean");
    if (!cfg.get<boolean>("completionEnabled", true)) return null;
    if (!isInsideOctaveBlock(document, position)) return null;
    const items: vscode.CompletionItem[] = [];
    for (const [name, b] of Object.entries(BUILTINS)) {
      const item = new vscode.CompletionItem(name, vscode.CompletionItemKind.Function);
      item.detail = b.signature;
      item.documentation = builtinMarkdown(name, b);
      item.filterText = name;
      // Bump priority so we appear above Lean's identifier suggestions.
      item.sortText = `0_${name}`;
      items.push(item);
    }
    return new vscode.CompletionList(items, false);
  }
}

// ── Hover ─────────────────────────────────────────────────────────

class OctaveHoverProvider implements vscode.HoverProvider {
  provideHover(
    document: vscode.TextDocument,
    position: vscode.Position
  ): vscode.ProviderResult<vscode.Hover> {
    const cfg = vscode.workspace.getConfiguration("octiveLean");
    if (!cfg.get<boolean>("hoverEnabled", true)) return null;
    if (!isInsideOctaveBlock(document, position)) return null;
    const range = document.getWordRangeAtPosition(position, /[A-Za-z_][A-Za-z0-9_]*/);
    if (!range) return null;
    const name = document.getText(range);
    const b = BUILTINS[name];
    if (!b) return null;
    return new vscode.Hover(builtinMarkdown(name, b), range);
  }
}

// ── Activation ────────────────────────────────────────────────────

export function activate(ctx: vscode.ExtensionContext) {
  const selectors: vscode.DocumentSelector = [
    { language: "lean4", scheme: "file" },
    { language: "lean", scheme: "file" },
  ];
  ctx.subscriptions.push(
    vscode.languages.registerCompletionItemProvider(selectors, new OctaveCompletionProvider()),
    vscode.languages.registerHoverProvider(selectors, new OctaveHoverProvider()),
  );
}

export function deactivate() {}
