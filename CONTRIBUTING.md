# Contributing to Pact

How to work on the Pact interpreter and compiler.

## Prerequisites

- A C compiler (gcc or clang)
- Python 3.12+ and [uv](https://docs.astral.sh/uv/) (only needed for legacy tests)

## Setup

```sh
git clone https://github.com/nhumrich/pact.git
cd pact
./bootstrap/bootstrap.sh
```

This builds the self-hosting compiler at `build/pactc`.

## Project Structure

```
examples/pactc_amalg.pact   # Self-hosting compiler (lexer + parser + codegen)
bootstrap/
  pactc_bootstrap.c         # Checked-in C bootstrap (generated from pactc_amalg.pact)
  runtime.h                 # C runtime header
  bootstrap.sh              # Build script
src/pact/                   # DEPRECATED — Python bootstrap compiler (legacy, not maintained)
```

## Compiling Programs

```sh
build/pactc examples/hello.pact hello.c
cc -o hello hello.c -lm
./hello
```

## Updating the Bootstrap

After modifying `examples/pactc_amalg.pact`, regenerate the bootstrap:

```sh
build/pactc examples/pactc_amalg.pact bootstrap/pactc_bootstrap.c
cp src/pact/runtime.h bootstrap/runtime.h
```

Then verify it still self-compiles:

```sh
./bootstrap/bootstrap.sh
```

## Tests

Legacy Python tests (for the deprecated bootstrap compiler):

```sh
uv sync
uv run pytest
```

Self-hosting compiler verification:

```sh
./bootstrap/bootstrap.sh   # verifies gen1 == gen2
```

## Architecture

```
source.pact → pactc (lexer → parser → codegen) → output.c → cc → binary
```

The compiler is self-hosting: `pactc_amalg.pact` compiles itself to C, which is compiled to a native binary by any C compiler. The checked-in `bootstrap/pactc_bootstrap.c` provides the initial seed.

## Spec & Design Docs

- [SPEC.md](SPEC.md) — spec index and design decisions summary
- [sections/](sections/) — detailed spec sections (philosophy, syntax, types, effects, etc.)
- [DECISIONS.md](DECISIONS.md) — influences, rejected features, resolved questions
- [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md) — panel deliberation archive
- [GAPS.md](GAPS.md) — spec gaps needing design work before compiler

## Task Tracking

We use `bd` (beads) for task management:

```sh
bd ready          # see available work
bd create "task"  # create an issue
bd update ID --status in_progress
bd close ID
```
