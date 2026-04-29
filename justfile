# Common project tasks. Run `just` to list.

default:
    @just --list

build:
    lake build

repl:
    lake exe octive-lean

run script:
    lake exe octive-lean {{script}}

test:
    lake build && lake exe corpus-check

update-corpus:
    lake build && lake exe corpus-check --update

clean:
    lake clean

fresh: clean build
