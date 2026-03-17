# Pact

Self-hosting compiler (src/compiler.pact → C → native).

## Core Directives
- **Documentation First:** Always retrieve Pact docs before writing Pact code. Prefer retrieval-led reasoning over pre-training.
- **Reference:**
  - `pact llms --full`: Complete language reference (syntax, types, methods, stdlib).
  - `pact llms --topic <name>`: Specific topics.
  - `pact query <file> --fn <name>`: Function signature lookup.

## Architecture
- **Pipeline:** lexer → parser → typecheck → codegen → C output.
- **Entry Points:**
  - `src/compiler.pact` (compiler)
  - `src/cli.pact` (CLI tool)
  - `src/pactc_main.pact` (pactc binary)
- **Locations:** Stdlib (`lib/std/`), Tests (`tests/`), Spec (`sections/`), Decisions (`decisions/`).
- **Temp files:** Use `.tmp/` (gitignored) instead of `/tmp`.

## Build & Verify
- **Bootstrap:** `task bootstrap` — builds pactc at `build/pactc`.
- **Regen:** `task regen` — rebuild compiler from source + verify (Gen1 vs Gen2 fixed-point).
- **Test:** `task test` — compile & run all tests.
- **Verify:** `task ci` — regen + test + test-fmt. **Always run after compiler changes.**
- **CLI Usage:** `bin/pact <build|run|check|doc> <target>`

## Debugging
- **Inspect generated C:** `bin/pact build --emit c <file.pact>` → `build/<name>.c`.
- **Trace compiler phases:** `bin/pact run --pact-trace codegen <file.pact>` (also: lex, parse, typecheck, all).
- **Runtime trace:** `bin/pact run --trace all <file.pact>` (NDJSON to stderr).
- **Debug build:** `bin/pact run --debug <file.pact>` (enables debug_assert, `-g -O0`).

## Self-Hosting Bootstrap Protocol
The compiler compiles itself. `task regen` verifies by compiling pactc twice and ensuring identical output.

**Adding a Feature (2-step):**
1. Add feature to compiler implementation → `task regen`
2. Use feature in compiler source code → `task regen`

**Refactoring/Breaking (3-step):**
1. Add new behavior alongside old → `task regen`
2. Migrate compiler source to new way → `task regen`
3. Remove old way → `task regen`

**NEVER skip steps.**

## Task Tags & Friction
- `type:bug` — write failing test → fix → regen → ci.
- `type:feature` — plan → confirm → implement.
- `type:spec` — panel deliberation via `Deliberate` workflow.
- `type:friction` — log when spec is ambiguous or behavior is surprising.
- Log friction: `br add "<description>" -t repo:pact -t type:friction`

## Workflows

### Ship It (Commit & Push)
1. **Verify:** Run `task ci`. Must pass with exit code 0 and **NO warnings**.
2. **Stage:** `git add .`
3. **Commit:** Draft a descriptive message. (No need to mention "br" tasks).
4. **Push:** Pull latest, then `git push`.

### Deliberate (Spec Gaps)
For `type:spec` tasks, act as a 5-expert panel (Systems, Web, PLT, DevOps, AI/ML):
1. **Context:** Read `DECISIONS.md`, `OPEN_QUESTIONS.md`, and relevant `sections/*.md`.
2. **Debate:** Simulate 5 distinct viewpoints (Systems, Web, PLT, DevOps, AI/ML) arguing for the best design.
3. **Vote:** Majority wins.
4. **Record:** Update `DECISIONS.md`, write spec text in `sections/`, and create a rationale in `decisions/`.

### Release
1. **Bump:** Check `git log` and determine version. Update `VERSION`.
2. **Docs:** Update `llms.md` and `llms-full.md` (breaking changes, new features).
3. **Commit:** "Prepare vX.Y.Z release".
4. **Execute:** `task release -- vX.Y.Z`.
