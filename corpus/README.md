# Conformance Corpus

Each `.m` file is paired with an `.expected` file containing the expected stdout
when OctiveLean runs that source. The corpus is the data feed for both regression
testing and (later) for cross-checking against real Octave.

## Workflow

1. **Add a case.** Create `corpus/NN_short_name.m`.
2. **Snapshot.** Run `lake exe corpus-check --update` to capture actual stdout
   into a sibling `.expected` file.
3. **Verify.** Hand-review the `.expected` content. Compare to real Octave or to
   the language spec. **If it's wrong, fix the implementation, not the snapshot.**
4. **Commit** the `.m` and the verified `.expected` together.

## Running

```sh
lake build octive-lean        # ensure the interpreter binary exists
lake exe corpus-check         # run the full corpus (exit 0 iff all pass)
lake exe corpus-check --update   # rewrite every .expected from current behavior
```

Flags:

- `--dir DIR`  alternate corpus directory (default `corpus`)
- `--bin PATH` alternate interpreter binary (default `.lake/build/bin/octive-lean`)
- `--update`   snapshot mode

## Outcome legend

- `pass`  stdout matches `.expected` (trailing whitespace ignored)
- `FAIL`  ran cleanly, output diverged
- `ERROR` exit code != 0; runtime or parse error from OctiveLean
- `miss`  no `.expected` file yet — run `--update` to seed it

## Philosophy

This is a snapshot test, not a unit test. `--update` is dangerous when used
without thought: it makes failing tests pass by rewriting the expectation. Always
review the diff manually before committing an updated snapshot.
