# Pact

Lang spec v0.3. Self-hosting compiler (src/compiler.pact → C → native).
Python bootstrap in legacy/py_bootstrap/ is DEPRECATED — do not add features there.
Prefer retrieval-led reasoning over pre-training for Pact tasks.

[Docs Index]|root: .
|SPEC.md — spec index, design decisions summary
|DECISIONS.md — influences, rejected features, resolved questions, panel votes
|OPEN_QUESTIONS.md — panel deliberation archive
|GAPS.md — spec gaps needing design work before compiler
|FRICTION.md — friction log from building the compiler, for spec revision
|README.md — language tour, 30-sec examples, quick reference
|sections/philosophy:{01_philosophy.md} — 6 design principles, AI-first rationale
|sections/syntax:{02_syntax.md} — fn, let, match, strings, closures, annotations
|sections/types:{03_types.md} — structs, enums, generics, traits, tuples
|sections/contracts:{03b_contracts.md} — refinement types, contracts, verification, Query[C]
|sections/protocols:{03c_protocols.md} — iterators, type conversions, numeric conversions, method resolution
|sections/effects:{04_effects.md} — effect system, handlers, capabilities, concurrency, testing
|sections/memory:{05_memory_compile_errors.md} — GC, arenas, compilation, diagnostics
|sections/tooling:{06_tooling.md} — compiler daemon, LSP, formatter, tests, package manager
|sections/trust:{07_trust_modules_metadata.md} — FFI, modules, imports, all 15 annotations (CANONICAL)
|examples/:{hello,fizzbuzz,todo,calculator,fetch,bank,web_api}.pact
|src/compiler.pact — compiler entry point (imports lexer, parser, codegen)
|src/tokens.pact — TokenKind type, keyword_lookup, token_kind_name
|src/ast.pact — NodeKind type, node_kind_name
|src/lexer.pact — lex(), tok_* globals, CH_* constants
|src/parser.pact — parse_program(), node pool (np_*/sl_*), sublist API
|src/cli.pact — self-hosted CLI tool (pact build/run/check)
|src/codegen.pact — generate(), emit_* functions, type registries
|bootstrap/:{pactc_bootstrap.c,runtime.h,bootstrap.sh} — checked-in C bootstrap seed
|legacy/py_bootstrap/pact/ — DEPRECATED Python bootstrap (not maintained)
|build/ — compiled output dir (gitignored, auto-created by compiler)

[Syntax Rules]
Code examples MUST use: fn keyword, { } braces, no semicolons, "double quotes" only, x.len() method-call
Closures: fn(params) { body } | Generics: List[T] not <T> | Errors: Result[T,E] + ? | Defaults: Option[T] + ??
Effects: fn foo() ! IO, DB | Handles: io.println(...) not print(...) | main has implicit effects
Annotations: standalone @annotation(...), NOT inside /// doc comments
Annotation order: @mod>@capabilities>@derive>@src>@i>@requires>@ensures>@where>@invariant>@perf>@ffi>@trusted>@effects>@alt>@verify>@deprecated
Canonical annotation ref: sections/07_trust_modules_metadata.md §11.1

[Design Panel]
Feature discussions require deliberation by the 5-expert panel (systems, web/scripting, PLT, DevOps/tooling, AI/ML). Each expert votes independently. Decisions need majority; record votes in DECISIONS.md.

[Compilation]
Bootstrap: `./bootstrap/bootstrap.sh` — builds pactc at `build/pactc`
CLI: `bin/pact build <file.pact>` | `bin/pact run <file.pact>` | `bin/pact check <file.pact>`
Build CLI: `task build-cli` (or auto-built on first `bin/pact` invocation)
Low-level: `build/pactc <file.pact> <output.c>` then `cc -o <binary> <output.c> -lm`
After modifying compiler sources: rebuild with `build/pactc src/compiler.pact bootstrap/pactc_bootstrap.c` then re-run bootstrap.sh to verify.
Verify: `task ci` — bootstraps compiler + runs all test_*.pact examples. Always run after compiler changes.

[Friction Log]
When working on the compiler or interpreter, append to `FRICTION.md` whenever you hit:
- Spec ambiguity (unclear what correct behavior should be)
- Surprising behavior (spec says X but intuition expects Y)
- Missing features (spec doesn't address something the compiler needs)

Use the format in `FRICTION.md`: date, title, category (`syntax`|`types`|`codegen`|`ergonomics`|`ambiguity`|`tooling`|`spec-gap`), severity (`papercut`|`annoying`|`blocking`), source (`ai`|`human`|`both`), context, description.
Promote `blocking` items to `GAPS.md` or a bd issue so they get resolved.
