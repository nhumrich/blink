# Web/Scripting Expert -- Debugging Primitives Proposal

**Panelist:** Web/Scripting Expert (Python, JavaScript/TypeScript, Ruby background)
**Date:** 2026-02-20
**Context:** Response to AI_DEBUGGING_FRICTION.md findings

---

## Q1: Core Debugging Primitives an AI Agent Needs

### Primitive 1: `dbg` -- Inspect Expression with Context

**Description:** A built-in `dbg` expression that prints the source expression text, its value, its type, and the file/line location to stderr. Returns the value unchanged so it can be inserted into any expression without restructuring code. Compiles to nothing in release mode.

**Pact example:**

```pact
fn parse_identifier() -> Str ! IO.Print {
    let start = dbg(pos)
    advance()
    let name = source.slice(start, dbg(pos))
    name
}
```

Output (stderr, structured):

```
[dbg] parser.pact:3  pos = 42  : Int
[dbg] parser.pact:5  pos = 47  : Int
```

**Why it matters for AI:** An AI agent adds `dbg(expr)` with zero refactoring -- no need to invent a format string, compute what to print, or remember to capture the variable name. The expression wraps inline. Removal is a simple text substitution. This is the single highest-value debugging primitive for rapid iteration.

**Cross-language survey:**

| Language | Feature | Behavior |
|----------|---------|----------|
| Rust | `dbg!(expr)` | Prints `[file:line] expr = value`, returns value. Removed in release builds via macro. |
| Ruby | `tap { \|x\| p x }` / `then` | `tap` inspects mid-chain. Not auto-formatted but idiomatic for inspect-and-pass-through. |
| Python 3.8+ | `f"{expr=}"` | f-string `=` specifier prints both expression text and value. No auto-removal mechanism. |
| Elixir | `dbg(expr)` | Prints expression, value, and location. Returns value. Added in 1.14 precisely for this use case. |
| Zig | `@breakpoint()` / `std.debug.print` | `std.debug.print` with comptime format strings. No pass-through `dbg` equivalent, but comptime introspection enables similar. |

---

### Primitive 2: `io.eprintln` -- Plain Stderr Output

**Description:** A simple stderr print operation under the `IO.Print` effect. Not prefixed with `[LOG]` like `io.log`. Just writes a string to stderr. This is the missing operation from the IO effect handle table (section 4.4).

**Pact example:**

```pact
fn format_file(path: Str) -> Str ! IO.Print, FS.Read {
    let source = fs.read(path)?
    io.eprintln("formatting {path} ({source.len()} bytes)")
    let formatted = format_source(source)
    io.println(formatted)
    formatted
}
```

**Why it matters for AI:** When debugging a formatter or any program whose stdout IS the output, debug prints to stdout corrupt the result. The friction report documents exactly this problem: `io.println` debug output interleaved with formatted code. `io.log` adds a `[LOG]` prefix which is sometimes unwanted. `io.eprintln` is the missing middle ground.

**Cross-language survey:**

| Language | Feature | Behavior |
|----------|---------|----------|
| Rust | `eprintln!()` | Prints to stderr with newline. Separate from `println!` (stdout). |
| Python | `print(..., file=sys.stderr)` | Redirect print to stderr. Verbose but universal. |
| Go | `fmt.Fprintln(os.Stderr, ...)` | Explicit file handle. Idiomatic Go. |
| Ruby | `$stderr.puts(...)` | Global stderr handle. |
| Node.js | `console.error(...)` | Writes to stderr. Named "error" but universally used for debug output. |
| Bash | `echo "..." >&2` | Redirect to fd 2. |

**Recommendation:** Add `io.eprintln` and `io.eprint` to the IO.Print operations table in section 4.4. This is a gap, not a design question -- every language has this and the spec already has the hook point.

---

### Primitive 3: `assert` with Interpolated Context (outside test blocks)

**Description:** A general-purpose `assert(condition, "message with {context}")` that is available outside test blocks in debug/dev builds and compiles to nothing in release mode. Distinct from test assertions (which are test-scoped) and from `@requires`/`@ensures` (which are contract-level). This is the "sanity check I leave in the code permanently" primitive.

**Pact example:**

```pact
fn attach_comments(node_idx: Int) {
    assert(node_idx >= 0, "invalid node index: {node_idx}")
    assert(
        pending_comments.len() < 100,
        "comment accumulation runaway: {pending_comments.len()} pending at pos {pos}"
    )
    // ... actual logic
}
```

**Why it matters for AI:** The friction report shows a bug where `pending_comments` accumulated duplicates silently. A permanent `assert(pending_comments.len() < N)` would have caught it immediately on any test run, without needing a dedicated debugging session. Assertions are "always-on debug instrumentation" that catch invariant violations at the point of corruption, not downstream where the symptom manifests.

**Cross-language survey:**

| Language | Feature | Behavior |
|----------|---------|----------|
| Python | `assert cond, msg` | Statement. Disabled with `-O` flag. |
| C/C++ | `assert(cond)` | Macro. Disabled with `NDEBUG`. No message interpolation. |
| Rust | `debug_assert!(cond, "msg {}", val)` | Macro. Removed in release builds. Has `debug_assert_eq!` variant. |
| Java | `assert cond : msg` | Disabled by default, enabled with `-ea`. |
| Go | No built-in | Community convention: `if !cond { panic("msg") }`. No stripping. |
| Swift | `assert(cond, "msg")` | Removed in `-O` builds. `precondition()` for always-on checks. |

**Recommendation:** `debug_assert(cond, msg)` as a compiler-known function. Available everywhere (not just test blocks). Compiles to nothing in release mode. The message supports string interpolation. Panics with source location on failure.

---

### Primitive 4: Structured Trace Output via `--trace` Compiler/Runtime Flag

**Description:** A runtime tracing mode activated by flag, not by source code modification. When running with `pact run --trace <category>`, the runtime emits structured JSON trace events for function entry/exit, key state transitions, and effect invocations. No code changes required.

**Pact example (invocation, not source code):**

```sh
pact run --trace parse my_file.pact
```

Output (structured, to stderr):

```json
{"event": "enter", "fn": "parse_block", "pos": 22, "depth": 3}
{"event": "enter", "fn": "parse_stmt", "pos": 24, "depth": 4}
{"event": "enter", "fn": "skip_newlines", "pos": 24, "writes": ["pos", "pending_comments"], "depth": 5}
{"event": "state", "var": "pending_comments", "action": "push", "value": "trailing comma case", "pos": 26}
{"event": "exit", "fn": "skip_newlines", "pos": 27, "depth": 5}
```

**Why it matters for AI:** This is the single most impactful primitive from the friction report. The AI spent ~15 tool calls doing what `--trace` would have done in one. Trace output is structured JSON, so an AI agent can parse it programmatically. No source modification means no cleanup step, no recompilation loop, no risk of introducing bugs through debug instrumentation.

**Cross-language survey:**

| Language | Feature | Behavior |
|----------|---------|----------|
| Python | `python -m trace --trace script.py` | Line-level execution tracing. Also `sys.settrace()` for programmatic hooks. |
| Node.js | `node --trace-warnings` / `--inspect` | Various `--trace-*` flags for specific subsystems. Chrome DevTools protocol for structured inspection. |
| Ruby | `ruby -r tracer script.rb` | Built-in tracer library. Also `TracePoint` API for custom hooks. |
| Java | `-agentlib:jdwp` / JFR | Java Flight Recorder provides structured event tracing without code changes. |
| Go | `go tool trace` | Runtime execution tracer. Structured output. Requires `runtime/trace` import but no code changes to traced functions. |
| Erlang/Elixir | `:dbg.tracer()` / `:recon_trace` | Function-level tracing without code changes. Filter by module, function, arity. Production-safe. |

**Recommendation:** This should be a tooling feature, not a language feature. `pact run --trace <category>` where category can be `parse`, `typecheck`, `effects`, `all`. The compiler daemon can instrument functions at compile time when the flag is present. Output format is structured JSON to stderr. This is how Erlang/OTP has done it for 30 years -- it works.

---

### Primitive 5: `pact ast --comments` / `pact ast --annotated` -- AST Dump with Metadata

**Description:** The CLI reference (section 8.14) lists `pact ast <file>` but has no dedicated section. This should dump the parsed AST as structured JSON, with options to include comment attachments, type annotations, effect annotations, and write-set information. This is a diagnostic tool for compiler developers and anyone writing tools that consume the AST (formatters, linters, macro authors).

**Pact example (invocation):**

```sh
pact ast src/parser.pact --comments --json
```

Output (abbreviated):

```json
{
  "kind": "LetBinding",
  "name": "x",
  "line": 42,
  "comments_before": ["// the lookahead variable"],
  "comments_after": [],
  "children": [...]
}
```

**Why it matters for AI:** The friction report's root cause was comment duplication in the AST. An `pact ast --comments` dump would have revealed the duplicate attachment immediately -- one command instead of 15 tool calls of print-debugging. For any AST-level bug (formatter, linter, macro expansion), this is the fastest diagnostic path.

**Cross-language survey:**

| Language | Feature | Behavior |
|----------|---------|----------|
| Python | `ast.dump(ast.parse(code))` | Built-in AST dump. JSON-like output. Includes all node types. |
| TypeScript | `ts.createSourceFile()` + visitor | Compiler API exposes full AST with comments via `getLeadingCommentRanges`. |
| Rust | `cargo expand` / `rustc -Zunpretty=ast` | AST dump via compiler flags. Nightly only for some formats. |
| Go | `go/ast` + `ast.Print()` | Standard library AST dump. Includes comments via `ast.CommentMap`. |
| Elixir | `Code.string_to_quoted(code)` | Returns AST as nested tuples. Inspectable in IEx. |

**Recommendation:** Document the `pact ast` command with options: `--json` (structured), `--comments` (include comment attachments), `--types` (include inferred types), `--effects` (include inferred effects), `--write-sets` (include mutation analysis). This is the "X-ray mode" for the compiler's internal representation.

---

## Q2: How Should Debugging Interact with the Effect System?

### Position: `dbg` Escapes the Effect System. Everything Else is Tracked.

This is the critical design question and I feel strongly about it. Let me break it into tiers:

**Tier 1 -- `dbg`: Effect-free (untracked)**

`dbg(expr)` should NOT require `! IO.Print` or any effect declaration. Rationale:

1. **Friction kills adoption.** If adding `dbg(pos)` requires changing the function signature from pure to `! IO.Print`, and then changing every caller's signature, and then changing THEIR callers... nobody will use it. Python developers reach for `print()` because it has zero ceremony. Pact's `dbg` must match that.

2. **It compiles to nothing in release.** If it does not exist in the final binary, it is not an effect in any meaningful sense. Effects track what a program CAN DO. A `dbg` that is stripped is a program that CANNOT print.

3. **Precedent is universal.** Rust's `dbg!` works in any context. Python's `print()` has no effect tracking. Go's `fmt.Println` has no effect tracking. Ruby's `p` has no effect tracking. Zero languages require effect/capability declarations for debug output.

4. **AI ergonomics.** An AI agent adding debug instrumentation should not need to reason about effect propagation. Add `dbg`, run, read output, remove `dbg`. That is the workflow.

**Tier 2 -- `io.eprintln`, `io.println`, `io.log`: Effect-tracked (as today)**

These are real IO operations that appear in production code. They MUST be effect-tracked:

```pact
fn process(data: Str) ! IO.Print {
    io.eprintln("processing: {data}")
    // ...
}
```

This is correct and should not change. The effect system's value comes from tracking real IO.

**Tier 3 -- `debug_assert`: Effect-free (untracked)**

Same reasoning as `dbg`. It compiles to nothing in release. It should not require effect declarations. Assertions are invariant checks, not IO operations.

**Tier 4 -- `--trace` flag: Orthogonal (tooling, not language)**

Trace output is injected by the compiler/runtime, not by user code. It does not appear in function signatures because it is not part of the program's semantics. This is the same model as code coverage instrumentation -- `pact test --coverage` does not require functions to declare a "coverage" effect.

### The Principle

**If it is stripped in release builds, it is not an effect.** Effects model what a program does in production. Debug instrumentation models what a developer needs during development. These are orthogonal concerns. Conflating them punishes debugging with type system friction, which is the opposite of what an AI-first language should do.

### Potential Objection: "But a pure function should not print"

True. And `dbg` does not print in the released program. The function IS pure in the final artifact. `dbg` is a development-time overlay on the program, like breakpoints in a debugger -- they do not change the program's semantics.

If we must model this formally: `dbg` is a compiler directive that temporarily injects IO at a specific source location. It is not a property of the function. It is a property of the current build configuration.

---

## Q3: Compiler/Tooling Support for AI-Efficient Debugging

### 3.1 Structured JSON for Everything (Already Planned -- Reinforce)

Section 8.6 already mandates structured JSON diagnostics. Extend this to ALL debugging output:

- `pact run --trace` outputs JSON to stderr
- `pact ast --json` outputs structured AST
- `dbg` output is structured (parseable by AI, not just human-readable)
- Test failures include structured diffs (section 8.10 already does this)

The AI agent should NEVER need to regex-parse debug output. If it does, the tooling has failed.

### 3.2 Incremental Rebuild for Debug Cycles

The friction report documents a ~10 second cycle: edit -> compile compiler -> compile output -> run. For debug iteration, this must be sub-second.

**Recommendation:** `pact run --watch` mode in the daemon. The daemon watches for file changes, incrementally recompiles only affected functions, and re-runs. The AI agent's workflow becomes: edit file -> output appears automatically. No explicit compile step.

This is standard in web development (webpack dev server, Vite, `nodemon`, `cargo watch`). Pact's compiler daemon architecture (section 8.2) already supports incremental compilation -- expose it as a watch mode.

### 3.3 `pact eval` for Quick Expression Testing

Section 8.13 describes `pact eval` for quick expression evaluation. This is enormously valuable for debugging -- an AI agent can test hypotheses about expression values without modifying source files:

```sh
pact eval "parse_identifier()" --with-state "pos=42, source=\"hello world\""
```

The `--with-state` flag (proposed) would inject module-level variable values, enabling an AI to probe specific program states without running the full program.

### 3.4 Diff-Aware Test Runs

When the AI modifies a function, it should be able to run only the tests affected by that change:

```sh
pact test --affected
```

The compiler daemon knows the dependency graph. It knows which tests call which functions. When `skip_newlines()` changes, run only the tests that transitively depend on `skip_newlines()`. This turns a 30-second full test suite into a 2-second targeted run.

### 3.5 Source Location Snapshots for `dbg`

When `dbg` is used, the compiler should record the insertion point so that cleanup is trivial:

```sh
pact dbg list
```

```
  src/parser.pact:42    dbg(pos)
  src/parser.pact:57    dbg(pending_comments.len())
  src/parser.pact:89    dbg(token)
```

```sh
pact dbg clean          # remove all dbg expressions
pact dbg clean src/parser.pact  # remove dbg from one file
```

This directly addresses the friction report's complaint about manual removal of debug instrumentation. The AI adds `dbg` calls, debugs the issue, then runs `pact dbg clean`. One command, zero risk of missing one.

---

## Q4: Language Feature vs. Purely Tooling?

### The Line

| Capability | Language or Tooling? | Rationale |
|------------|---------------------|-----------|
| `dbg(expr)` | **Language** (compiler-known expression) | Must be an expression that returns a value. Must understand source text of the expression. Must compile to nothing in release. Only the compiler can do this. |
| `debug_assert(cond, msg)` | **Language** (compiler-known function) | Must compile to nothing in release. Must capture source location. Must be available everywhere without import. Only the compiler can do this. |
| `io.eprintln` | **Language** (effect operation) | It is a missing entry in the IO effect handle table. It belongs alongside `io.println` and `io.log`. |
| `--trace` | **Tooling** (compiler flag) | No source code changes. The compiler instruments functions at build time when the flag is present. This is a build mode, not a language construct. |
| `pact ast` | **Tooling** (CLI command) | Reads the compiler's internal representation. No source code involvement. |
| `pact dbg list/clean` | **Tooling** (CLI command) | Source manipulation commands that operate on `dbg` expressions the compiler already knows about. |
| `pact run --watch` | **Tooling** (daemon feature) | Build system feature. No language involvement. |
| `pact test --affected` | **Tooling** (daemon feature) | Dependency graph analysis. No language involvement. |

### The Principle

**Language features model semantics. Tooling features model workflow.**

`dbg` is a language feature because it IS an expression -- it has a type, it returns a value, it participates in evaluation. You can write `let x = dbg(foo()) + dbg(bar())` and it must work correctly. Only the compiler can make this happen.

`--trace` is a tooling feature because it observes execution without participating in it. It does not change what expressions evaluate to. It does not appear in source code. It is metadata about a run, not part of the program.

`io.eprintln` is a language feature because it is a real IO operation that persists in release builds, is effect-tracked, and is part of the program's semantics. It is not debug instrumentation -- it is a permanent capability of the IO effect.

`debug_assert` sits on the boundary but is a language feature because it must participate in the type system (the condition is a `Bool` expression, the message is a `Str` with interpolation) and must be stripped by the compiler. A library function cannot strip itself from the binary.

### What I Would NOT Add

- **`@debug` annotation.** The friction report suggests it. I oppose it. Annotations in Pact are semantic metadata (contracts, capabilities, provenance). Using an annotation for "strip this code in release" conflates metadata with conditional compilation. Use `dbg` for expressions and `debug_assert` for invariants -- these are specific, well-scoped primitives. A general-purpose `@debug` annotation is a slippery slope toward `#ifdef DEBUG` spaghetti.

- **A REPL / interactive debugger.** Not for v1. Pact's compilation model (Pact -> C -> native) makes interactive debugging painful. The payoff is low for AI agents (they cannot interact with a REPL efficiently -- each step costs a tool call). Invest in `--trace` and `dbg` instead, which fit the "run, read output, iterate" workflow that AI agents actually use.

- **Conditional compilation beyond debug stripping.** No `@cfg(target)`, no `#if`, no feature-gated code blocks. Pact has the `@alt` system for alternative implementations. Use that. Conditional compilation is a complexity multiplier that makes every line of code potentially N different programs.

---

## Summary of Recommendations

| Priority | Item | Type | Effort |
|----------|------|------|--------|
| P0 | `dbg(expr)` -- effect-free, stripped in release | Language | Medium |
| P0 | `io.eprintln` / `io.eprint` -- add to IO.Print operations | Language (spec gap) | Small |
| P0 | `pact ast` -- document with `--comments`, `--json` options | Tooling (spec gap) | Small |
| P1 | `debug_assert(cond, msg)` -- effect-free, stripped in release | Language | Medium |
| P1 | `--trace <category>` -- structured JSON trace output | Tooling | Large |
| P1 | `pact dbg list/clean` -- manage debug instrumentation | Tooling | Small |
| P2 | `pact test --affected` -- dependency-aware test runs | Tooling | Medium |
| P2 | `pact run --watch` -- incremental rebuild on change | Tooling | Medium |

The North Star: **an AI agent should be able to diagnose any bug in 3 tool calls or fewer.** One to add instrumentation (or run with `--trace`), one to execute, one to read the structured output. The friction report took 15. That is a 5x gap we can close with these primitives.
