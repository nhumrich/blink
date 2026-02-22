# Systems Programming Expert — Debugging Primitives Proposal

**Panelist:** Systems Programming Expert (C, C++, Rust, Zig background)
**Date:** 2026-02-20
**Context:** Response to AI_DEBUGGING_FRICTION.md — comment duplication debugging session

---

## Q1: Core Debugging Primitives an AI Agent Needs

After reviewing the friction report, I see a fundamental mismatch: the debugging session burned ~15 tool calls doing what amounts to reconstructing control flow and state snapshots that the compiler already knows about. AI agents do not use interactive debuggers — they read structured output. Every primitive below is designed around that constraint.

### Primitive 1: `debug_assert` — Invariant Assertion with Context

**Description:** A conditional check that compiles to nothing in release mode but panics with a structured, interpolated message in debug builds. The key differentiator from a plain `assert` is that it carries rich context (variable snapshots) and is stripped at zero cost.

**Pact syntax:**

```pact
fn attach_comments(node_idx: Int) {
    debug_assert(pending_comments.len() < 100, "comment leak: {pending_comments.len()} pending at node {node_idx}")

    for comment in pending_comments {
        np_comments[node_idx] = comment
    }
    pending_comments.clear()

    debug_assert(pending_comments.len() == 0, "clear failed for node {node_idx}")
}
```

**Cross-language survey:**

| Language | Mechanism | Compile-out? | Structured output? |
|----------|-----------|-------------|-------------------|
| C/C++ | `assert()` macro, `#include <assert.h>`, disabled by `NDEBUG` | Yes | No — just prints expression text and file:line to stderr |
| Rust | `debug_assert!()` and `debug_assert_eq!()` | Yes — no-op in `--release` | Partial — prints expression text, left/right values for `_eq` variant |
| Zig | `std.debug.assert()` | Yes — `ReleaseFast` and `ReleaseSmall` strip it | No — triggers unreachable, safety-checked in debug |
| D | `assert` with lazy message parameter | Yes — `-release` strips | No |
| Swift | `assert()` and `precondition()` | `assert` strips in `-O`, `precondition` strips only in `-Ounchecked` | No |

**Effect system interaction:** `debug_assert` is NOT an effect. It does not perform IO in the normal sense — it either does nothing (release) or panics (debug). Like `panic()`, it is untracked divergence. A pure function can contain `debug_assert` and remain pure. This is critical: if `debug_assert` required `! IO.Debug`, it would poison every function signature in the codebase and nobody would use it.

**Zero-cost guarantee:** In release mode, the compiler must eliminate the assert AND the string interpolation expressions. No allocation for the message string, no evaluation of `pending_comments.len()` if the result is only used in the assert message. This is the same guarantee C gives with `NDEBUG` — the expression inside the assert is not evaluated at all.

### Primitive 2: `@trace` — Function Entry/Exit Instrumentation

**Description:** A compiler-driven annotation that instruments a function with structured entry/exit logging, including argument values and return values. Activated by compiler flag, compiles to nothing otherwise.

**Pact syntax:**

```pact
@trace
fn skip_newlines() {
    while at() == CH_NEWLINE {
        advance()
        if at() == CH_HASH {
            pending_comments.push(parse_comment())
        }
    }
}

@trace
fn looks_like_struct_lit() -> Bool {
    let saved_pos = pos
    skip_newlines()
    let result = at() == CH_LBRACE
    pos = saved_pos
    result
}
```

When compiled with `pact build --trace` or `pact run --trace`, output is structured JSON to stderr:

```json
{"event":"enter","fn":"looks_like_struct_lit","pos":42,"depth":3,"ts_us":18042}
{"event":"enter","fn":"skip_newlines","pos":42,"depth":4,"ts_us":18043}
{"event":"state","fn":"skip_newlines","var":"pending_comments.len","before":0,"after":1,"ts_us":18045}
{"event":"exit","fn":"skip_newlines","pos":44,"depth":4,"ts_us":18046}
{"event":"exit","fn":"looks_like_struct_lit","return":false,"depth":3,"ts_us":18047}
```

The `@trace` annotation is inert without `--trace`. With it, the compiler injects entry/exit logging. The `state` events come from mutation analysis (section 4.16) — the compiler already knows `skip_newlines` writes `{pos, pending_comments}`, so it can emit before/after snapshots of those variables automatically.

**Cross-language survey:**

| Language | Mechanism | Structured? | Zero-cost when off? |
|----------|-----------|------------|-------------------|
| Rust | `tracing` crate with `#[instrument]` proc macro | Yes — structured spans with fields | Conditional — compile-time feature gate, but crate is always a dependency |
| Go | `runtime/trace` package + `go tool trace` | Yes — binary format, visualized with web UI | No — runtime overhead even when not tracing |
| Zig | `@setRuntimeSafety(true)` + `std.log` | Partial — log has levels, but no automatic instrumentation | Yes — comptime branching eliminates dead code |
| DTrace/SystemTap (C/C++) | Userspace probes (`USDT`) | Yes — structured probes with typed arguments | Yes — probes are NOPs until enabled by external tracer |
| Java | JFR (Java Flight Recorder) events | Yes — structured events with metadata | Mostly — JFR overhead is minimal when events are not requested |

**Effect system interaction:** `@trace` output bypasses the effect system entirely. This is deliberate and mirrors DTrace's design philosophy: tracing is an observability layer orthogonal to program semantics. A function with `@trace` does not gain `! IO` — the trace output is a compiler/runtime concern, not a program-level side effect. The trace writes to a dedicated channel (stderr or a trace file), never to the program's stdout.

**Why annotation, not a compiler flag alone:** A blanket `--trace-all` would generate enormous output for a large program. The `@trace` annotation lets the developer (or AI) mark specific functions of interest. The compiler flag activates the marked functions. This is the same model as Rust's `#[instrument]` — selective, opt-in, zero-cost when inactive.

### Primitive 3: `pact ast --annotated` — AST Dump with Metadata

**Description:** A compiler command that dumps the parsed AST as structured JSON, annotated with comment attachments, inferred write sets, types, and source spans. This is diagnostic tooling, not a language feature.

**Pact invocation:**

```sh
pact ast src/parser.pact --annotated --json
```

```json
{
  "nodes": [
    {
      "id": 42,
      "kind": "LetBinding",
      "name": "x",
      "span": {"line": 10, "col": 5, "end_line": 10, "end_col": 20},
      "type": "Int",
      "comments": [
        {"text": " trailing comma case", "position": "leading", "line": 9}
      ],
      "children": [...]
    }
  ]
}
```

The friction report specifically calls out that comment attachments were invisible. This command would have immediately shown which nodes had comments attached and whether any comment appeared on multiple nodes — resolving the bug in a single invocation.

**Cross-language survey:**

| Language | Mechanism | Structured? | Includes metadata? |
|----------|-----------|------------|-------------------|
| Rust | `rustc -Zunpretty=ast-tree` (nightly) | Semi — tree text format | Types partial, no comments |
| Go | `go/ast` package + `ast.Print()` | Yes — Go struct dump | Comments attached to nodes |
| Clang (C/C++) | `clang -ast-dump -ast-dump-filter=foo` | Yes — indented text or JSON with `-ast-dump=json` | Full — types, source ranges, includes |
| Python | `ast.dump(ast.parse(...))` | Yes — Python repr | No types (dynamic), no comments (stripped by parser) |
| TypeScript | `ts.createSourceFile()` + visitor | Yes — full AST with `ts.SyntaxKind` | Full — types, trivia (comments/whitespace) |

**Effect system interaction:** None. This is a compiler tool command. It reads source, produces output. It does not interact with the effect system at all.

### Primitive 4: `io.eprintln` — Stderr Print

**Description:** Plain stderr output. The friction report documents that `io.eprintln` does not exist, forcing debug output to interleave with program stdout. This is a gap in the IO effect operation table (section 4.4).

**Pact syntax:**

```pact
fn debug_parser_state() ! IO.Print {
    io.eprintln("pos={pos} pending={pending_comments.len()}")
}
```

**Cross-language survey:**

| Language | Mechanism |
|----------|-----------|
| Rust | `eprintln!()` macro |
| Go | `fmt.Fprintln(os.Stderr, ...)` |
| Python | `print(..., file=sys.stderr)` |
| C | `fprintf(stderr, ...)` |
| Zig | `std.debug.print()` writes to stderr |

Every language has this. The IO effect operation table in section 4.4 lists `io.print(...)` and `io.log(...)` but no plain stderr print. `io.log` adds a `[LOG]` prefix, which is wrong for raw debug output. The fix is to add `io.eprintln` and `io.eprint` to the `IO.Print` effect's operation set.

**Effect system interaction:** `io.eprintln` requires `! IO.Print`, same as `io.println`. It is a different output stream, not a different capability. A function that can print to stdout can print to stderr — the distinction is about stream routing, not security. Splitting into `IO.Stdout` and `IO.Stderr` sub-effects would be over-engineering; no language makes this distinction at the capability level.

### Primitive 5: Structured Snapshot — `pact query --write-sets`

**Description:** Expose the compiler's mutation analysis (section 4.16) through the query system. The compiler already computes write sets for every function. Making that data queryable lets an AI instantly understand which functions mutate which state — the exact information the friction report's debugging session was reconstructing manually.

**Pact invocation:**

```sh
pact query --write-sets --module parser
```

```json
{
  "module": "parser",
  "functions": [
    {"name": "advance", "writes": ["pos"]},
    {"name": "skip_newlines", "writes": ["pos", "pending_comments"]},
    {"name": "at", "writes": []},
    {"name": "looks_like_struct_lit", "writes": ["pos", "pending_comments"]},
    {"name": "parse_block", "writes": ["pos", "pending_comments", "np_kinds", "np_count"]}
  ]
}
```

This would have immediately revealed that `skip_newlines` writes to `pending_comments` — the root cause of the bug — without adding a single print statement.

**Cross-language survey:**

| Language | Mechanism | Automatic? |
|----------|-----------|-----------|
| Rust | Borrow checker enforces mutation statically, but no "query what mutates what" tool | Implicit in type system |
| Java | IDE "find usages" of a field shows all write sites | Manual search |
| C/C++ | Static analyzers (Coverity, Infer) track mutation, but results are in their own formats | External tool |

No mainstream language exposes write-set analysis as a first-class query. This is a genuine innovation opportunity. Pact already computes this (section 4.16) — exposing it through the query system is incremental work with outsized debugging value.

**Effect system interaction:** None. This is a query over compile-time analysis data.

---

## Q2: How Should Debugging Interact with the Effect System?

This is the central design tension. I will analyze three options and argue for a specific one.

### Option A: Debug output is effect-tracked (`! IO.Debug`)

Add `IO.Debug` as a sub-effect of `IO`. Debug prints require declaring `! IO.Debug`.

```pact
effect IO {
    effect Print
    effect Log
    effect Debug    // new
}

fn trace_parser() ! IO.Debug {
    io.debug("pos={pos}")
}
```

**I reject this option.** Here is why:

1. **Signature pollution.** If `debug_assert` and debug prints require `! IO.Debug`, every function in the call chain up to `main` must declare it. The friction report's debugging session touched `skip_newlines`, `parse_block`, `parse_let_binding`, `parse_while_loop`, and `attach_comments`. Adding `! IO.Debug` to all five functions plus their callers to enable temporary debug output is exactly the kind of ceremony that makes developers skip debugging and just stare at the code.

2. **Effect propagation defeats the purpose.** The whole point of debugging output is that it is temporary. You add it, find the bug, remove it. An effect declaration is a permanent signature change for a temporary need.

3. **Contradiction with the effect system's thesis.** Effects track capabilities that matter for correctness and security. Debug output does not affect program correctness. It does not cross trust boundaries. It is not a capability that callers need to reason about. Tracking it as an effect elevates noise to the same status as `DB.Write`.

### Option B: Debug output is explicitly OUTSIDE the effect system

Debug primitives are compiler intrinsics that bypass effect tracking. They work in any function regardless of declared effects.

```pact
// This function is pure — no ! in its signature
fn validate(order: Order) -> Result[Order, OrderError] {
    debug_assert(order.items.len() > 0, "empty order")
    if order.items.is_empty() {
        Err(OrderError.InvalidOrder("empty order"))
    } else {
        Ok(order)
    }
}
```

`debug_assert` works inside a pure function. No signature change. Compiles to nothing in release.

**I advocate for this option, with caveats.**

The precedent is strong. In every systems language I have worked with:

- C: `assert()` works everywhere, disabled by `NDEBUG`. No type system interaction.
- Rust: `debug_assert!()` works everywhere, including in functions with no side effects. Not tracked by the borrow checker or type system.
- Zig: `std.debug.assert()` works everywhere. `@setRuntimeSafety` is orthogonal to the type system.

The principle is: **debugging instrumentation is a meta-level concern, not a program-level concern.** It is in the same category as compiler warnings, profiling probes, and code coverage instrumentation. These observe the program but do not participate in its semantics.

**Caveats:**

1. **`debug_assert` and `@trace` must be compile-mode-gated.** They exist in debug builds and are erased in release builds. This is the zero-cost abstraction: you do not pay for debugging in production.

2. **Explicit `io.println` / `io.eprintln` for manual debug prints remain effect-tracked.** If you manually write `io.eprintln("debug: {x}")`, that requires `! IO.Print` as it does today. The distinction: `debug_assert` and `@trace` are compiler-managed instrumentation (automatically stripped). `io.eprintln` is user-written code (you control its lifetime). The compiler does not know which `io.eprintln` calls are "debug" vs "production" — that distinction lives in programmer intent, not in the type system.

3. **Handler testing still works.** In test blocks, you can mock IO to capture debug prints. But `debug_assert` panics are not IO — they are contract violations, handled the same way as `panic()`.

### Option C: Hybrid — `@debug` blocks with implicit IO.Debug

Blocks annotated with `@debug` get implicit `! IO.Debug` that does not propagate to callers.

```pact
fn skip_newlines() {
    @debug {
        io.eprintln("skip_newlines at pos={pos}")
    }
    while at() == CH_NEWLINE {
        advance()
    }
}
```

The `@debug` block has implicit IO access that does not appear in the function's signature. The block compiles to nothing without `--debug`.

**I reject this option too.** It creates an invisible effect hole — a function that performs IO but does not declare it. This directly contradicts section 4.1's thesis: "A function with no `!` in its signature cannot perform side effects. The compiler proves it." Adding `@debug` blocks that secretly perform IO makes that guarantee conditional on build mode. You now have two semantics for the same source code — one where the function is pure and one where it is not. This is the kind of subtlety that breeds bugs in exactly the way the effect system was designed to prevent.

### Recommendation

**Option B.** Debugging primitives (`debug_assert`, `@trace`) are compiler intrinsics outside the effect system. They are erased in release mode. Manual debug printing (`io.eprintln`) remains effect-tracked. The language maintains a clean separation:

| Mechanism | Effect-tracked? | Compile-out? | Purpose |
|-----------|----------------|-------------|---------|
| `debug_assert(cond, msg)` | No — compiler intrinsic | Yes — release mode | Invariant checking |
| `@trace` annotation | No — compiler instrumentation | Yes — without `--trace` | Function tracing |
| `io.println` / `io.eprintln` | Yes — `! IO.Print` | No — always present | Program output |
| `io.log` | Yes — `! IO.Log` | No — always present | Structured logging |

---

## Q3: Compiler/Tooling Support for AI-Efficient Debugging

AI agents do not set breakpoints. They read text. Every debugging tool must produce structured, parseable output. Here are specific proposals:

### Flag: `--trace`

Activates `@trace`-annotated functions. Output goes to stderr as newline-delimited JSON.

```sh
pact run src/formatter.pact --trace
pact run src/formatter.pact --trace --trace-filter="skip_newlines,looks_like_struct_lit"
```

**`--trace-filter`** restricts which `@trace` functions actually emit. Without it, all `@trace` functions emit. With it, only named functions emit. This prevents output explosion in large programs while keeping `@trace` annotations on many functions for future use.

Output format:

```json
{"event":"enter","fn":"skip_newlines","args":{},"depth":4,"ts_us":18043,"file":"src/parser.pact","line":142}
{"event":"mutation","fn":"skip_newlines","var":"pending_comments","action":"push","depth":4,"ts_us":18045}
{"event":"exit","fn":"skip_newlines","return":"()","depth":4,"ts_us":18046,"duration_us":3}
```

Fields:
- `event`: `enter`, `exit`, `mutation`, `state_snapshot`
- `fn`: fully-qualified function name
- `args`: argument values (for `enter`)
- `return`: return value (for `exit`)
- `depth`: call stack depth (enables reconstruction of call tree)
- `var`, `action`: for mutation events (leverages write-set analysis)
- `ts_us`: microsecond timestamp (monotonic)
- `duration_us`: wall time in function (for `exit`)

The structured format means an AI agent can parse this directly, filter by function, sort by timestamp, or reconstruct the call tree — all without regex.

### Flag: `--dump-ast`

Dumps the AST after parsing, before codegen. Produces JSON with full metadata.

```sh
pact ast src/parser.pact --json
pact ast src/parser.pact --json --filter="LetBinding,WhileLoop"
```

The `--filter` flag restricts output to specific node kinds. For the comment duplication bug, `pact ast test_file.pact --json | jq '.nodes[] | select(.comments | length > 0)'` would have immediately shown all nodes with attached comments.

### Flag: `--debug` (build mode)

Enables `debug_assert` evaluation. This is the analog of C's removing `NDEBUG` or Rust's debug profile.

```sh
pact build src/app.pact              # release: debug_assert stripped
pact build src/app.pact --debug      # debug: debug_assert active
pact run src/app.pact                # release by default
pact run src/app.pact --debug        # debug mode
```

The `--debug` flag also:
- Disables optimizations (no function inlining, no dead code elimination beyond `debug_assert` stripping)
- Preserves all symbol names in generated C (no mangling beyond module prefixes)
- Emits DWARF debug info in the compiled binary (for humans who want gdb/lldb)

### Query: `pact query --write-sets`

Exposes mutation analysis through the existing query system. See Primitive 5 above.

### Query: `pact query --callers` and `--callees`

Call graph queries. The compiler already has this information in its symbol-level dependency graph (section 8.2).

```sh
pact query --callers skip_newlines --json
```

```json
{
  "function": "skip_newlines",
  "callers": [
    {"name": "parse_block", "file": "src/parser.pact", "line": 200},
    {"name": "parse_let_binding", "file": "src/parser.pact", "line": 310},
    {"name": "looks_like_struct_lit", "file": "src/parser.pact", "line": 450}
  ]
}
```

For the friction report's bug, `pact query --callers skip_newlines` would have immediately shown all call sites — the exact information the AI spent multiple tool calls discovering.

### Diagnostic Enhancement: Write-Set Warnings

The compiler should warn when a function with a non-empty write set is called inside a speculative/lookahead pattern without saving all written state. This leverages existing mutation analysis:

```
warning[W2000]: speculative call to mutating function
 --> src/parser.pact:452:5
  |
450|     let saved_pos = pos
451|     // note: pending_comments not saved
452|     skip_newlines()
  |     ^^^^^^^^^^^^^^^ writes {pos, pending_comments}
  |
  = note: only `pos` is saved before this call
  = note: `pending_comments` is also in the write set but not saved
  = help: save and restore `pending_comments`, or use a non-mutating alternative
```

This is not a new language feature — it is a smarter diagnostic built on existing analysis. The compiler already computes write sets (section 4.16) and can detect save/restore patterns through straightforward dataflow analysis.

---

## Q4: Language Feature vs. Purely Tooling?

This is ultimately a question about where the abstraction boundary sits. My principle: **if it affects program semantics (even conditionally), it is a language feature. If it only observes, it is tooling.**

### Language features (syntax, compiled into the program)

| Feature | Justification |
|---------|--------------|
| `debug_assert(cond, msg)` | Affects control flow (panics in debug mode). Must be a compiler intrinsic because it needs to be stripped in release builds at the expression level — not just dead-code-eliminated, but guaranteed not to evaluate `msg`. |
| `@trace` annotation | Modifies compiled output (inserts instrumentation code). Must be a language-level annotation because it needs access to function arguments, return values, and write-set data that only the compiler has. A library cannot do this. |
| `io.eprintln` / `io.eprint` | Extends the IO effect operation table. This is a spec-level addition to section 4.4. |

### Tooling features (compiler flags, CLI commands)

| Feature | Justification |
|---------|--------------|
| `--trace` flag | Activates existing `@trace` annotations. Does not change program semantics — only enables instrumentation that is already in the source. |
| `--debug` flag | Activates `debug_assert`. Build mode selection. |
| `--dump-ast` / `pact ast` | Read-only observation of compiler state. Does not affect the program. |
| `pact query --write-sets` | Read-only query over existing analysis. |
| `pact query --callers/--callees` | Read-only query over existing dependency graph. |
| Write-set warnings (W2000) | Diagnostic improvement. Advisory, not semantic. |

### The line

The line is: **does it require compiler knowledge that no external tool could replicate?**

- `debug_assert` requires the compiler to strip the expression and its side effects. An external tool could not safely do this — it does not know whether `msg` evaluation has side effects.
- `@trace` requires the compiler's write-set analysis, argument types, and return types to generate meaningful instrumentation. A source-to-source transform could approximate this, but it would be fragile and lose type information.
- `pact ast --json` only requires the compiler's parser, which is already a service. This is pure tooling.

The critical design constraint from a systems perspective: **every language feature proposed here must be zero-cost in release mode.** Not "low cost." Zero. The generated C for a release build must be byte-identical whether or not the source contains `debug_assert` calls or `@trace` annotations. This is the same guarantee that C's `NDEBUG` and Rust's `debug_assert!` provide, and it is non-negotiable for a language that compiles to native code.

---

## Summary of Proposals

### Spec additions required

1. Add `io.eprintln(msg: Str)` and `io.eprint(msg: Str)` to the IO.Print operation table in section 4.4
2. Add `debug_assert(condition, message)` as a compiler intrinsic — section 8 or new section
3. Add `@trace` to the annotation reference in section 11.1 (16th annotation)
4. Add `pact ast <file> --json` to CLI reference in section 8.14 (partially exists, needs dedicated section)
5. Add `--trace`, `--debug` flags to CLI reference
6. Add `pact query --write-sets`, `--callers`, `--callees` to query system in section 8.5
7. Add write-set speculative call warning (W2000) to diagnostics

### What this gives AI agents

The friction report's 15-tool-call debugging session would become:

1. `pact query --write-sets --module parser` — immediately see that `skip_newlines` writes `pending_comments` (1 call)
2. `pact query --callers skip_newlines` — see all call sites including the speculative lookahead (1 call)
3. Bug identified. Root cause: `looks_like_struct_lit` calls a function that writes to `pending_comments` without saving/restoring it.

Two queries instead of fifteen tool calls. That is the debugging story for an AI-first language.
