# DevOps/Tooling Expert: Debugging Primitives Proposal

**Panelist:** DevOps/Tooling Expert (Go, Terraform, OTel, CI/CD background)
**Date:** 2026-02-20
**Context:** Response to AI_DEBUGGING_FRICTION.md — comment duplication bug required ~15 tool calls

---

## Q1: Core Debugging Primitives an AI Agent Needs

After reading the friction report, the real problem is clear: the AI had no *structured, machine-readable* way to observe program state. It was forced into printf-debugging — the worst possible workflow for an agent that cannot set breakpoints or scroll terminal output. Every primitive below is designed for structured consumption, not human eyeballing.

### Primitive 1: Structured Trace Output (`--trace`)

**Description:** A compiler/runtime flag that emits structured JSON events for function entry/exit, key state transitions, and effect invocations. The AI agent consumes this as a stream of machine-parseable records, not as interleaved text on stdout.

**Pact code example:**

```sh
pact run myprogram.pact --trace parse --format json
```

Output (one JSON object per line, NDJSON):

```json
{"event":"enter","fn":"parse_block","pos":22,"depth":0,"ts_us":1042}
{"event":"enter","fn":"parse_stmt","pos":24,"depth":1,"ts_us":1043}
{"event":"enter","fn":"skip_newlines","pos":24,"depth":2,"ts_us":1044}
{"event":"state","fn":"skip_newlines","var":"pending_comments","action":"push","value":"trailing comma case","pos":26,"ts_us":1045}
{"event":"exit","fn":"skip_newlines","pos":27,"depth":2,"ts_us":1046}
{"event":"exit","fn":"parse_stmt","pos":28,"depth":1,"ts_us":1047}
```

In the friction report scenario, one command + a `jq` filter on `"var":"pending_comments"` would have found the bug immediately. No recompilation, no manual instrumentation, no cleanup.

**Cross-language survey:**

| Tool | Mechanism | Structured? | AI-consumable? |
|------|-----------|-------------|----------------|
| **Go** `runtime/trace` | `go tool trace` writes binary trace, viewable in Chrome trace viewer or parsed programmatically. Event-based: goroutine create/block/unblock, syscalls, GC. | Yes (binary proto) | Partially (needs `go tool trace` to extract) |
| **OpenTelemetry** | Language-agnostic spans with structured attributes. Exporters for JSON, OTLP, Jaeger. Every span has trace_id, parent_id, attributes map. | Yes (OTLP/JSON) | Yes — designed for machine consumption |
| **Rust** `tracing` crate | Structured spans/events with typed fields. `tracing-subscriber` outputs JSON. `RUST_LOG=parser=trace` for per-module filtering. | Yes (JSON subscriber) | Yes |
| **Erlang/BEAM** `dbg`/`recon_trace` | Runtime function-call tracing with match specs. Can trace specific functions, with argument patterns, bounded output. | Semi (Erlang terms) | Partially |
| **Python** `sys.settrace` | Per-line callback with frame objects. Used by debuggers (pdb) and coverage tools. | No (callback API) | No (requires running debugger) |

**Recommendation:** Pact should follow the OpenTelemetry model — structured spans with typed attributes, NDJSON output. This is the format the entire observability ecosystem already consumes. An AI agent can pipe it through `jq`, an OTel collector, or parse it directly.

---

### Primitive 2: AST Dump with Metadata (`pact ast`)

**Description:** A command that dumps the parsed AST as structured JSON, including node IDs, spans, attached comments, inferred types, and write-sets. The CLI reference (section 8.14) lists `pact ast <file>` but there is no dedicated section defining its schema. This is a gap.

**Pact code example:**

```sh
pact ast src/parser.pact --format json --include comments,types,write-sets
```

Output (abbreviated):

```json
{
  "file": "src/parser.pact",
  "nodes": [
    {
      "id": 42,
      "kind": "LetBinding",
      "name": "pending_comments",
      "type": "List[Comment]",
      "mutable": true,
      "span": {"line": 8, "col": 1, "end_line": 8, "end_col": 45},
      "comments": []
    },
    {
      "id": 107,
      "kind": "FnDecl",
      "name": "skip_newlines",
      "return_type": "()",
      "effects": [],
      "write_set": ["pos", "pending_comments"],
      "span": {"line": 42, "col": 1, "end_line": 58, "end_col": 1},
      "body": {
        "children": [
          {
            "id": 108,
            "kind": "WhileLoop",
            "comments_attached": [
              {"text": "trailing comma case", "attachment": "leading", "from_node": 107}
            ]
          }
        ]
      }
    }
  ]
}
```

In the friction report, `pact ast test_file.pact --format json | jq '.nodes[] | select(.comments_attached | length > 0)'` would have immediately shown which nodes had comments and whether any comment appeared twice. One command. Zero recompilation.

**Cross-language survey:**

| Tool | Mechanism | Schema stability? |
|------|-----------|-------------------|
| **Go** `go/ast` + `go/printer` | `ast.Fprint()` dumps AST. Machine-parseable with `go/ast.Inspect`. No built-in JSON output — you write your own walker. | Stable (stdlib) |
| **Rust** `--emit=mir` / `cargo expand` | `rustc --emit=mir` outputs MIR. `cargo expand` shows expanded macros. `-Z ast-json` was experimental and removed. | Unstable |
| **TypeScript** `ts.createProgram` | Full AST access via compiler API. `typescript-json-schema` for types. TSC itself has no `--dump-ast` flag but the API is the AST. | Stable (compiler API) |
| **Clang** `-ast-dump=json` | `clang -Xclang -ast-dump=json` outputs full AST as JSON. Stable, well-documented schema. Used by clang-tidy, clangd, and static analysis tools. | Stable, versioned |
| **Python** `ast` module | `ast.dump(tree, indent=2)` since 3.9. JSON output via `ast.parse` + custom serializer. | Stable (stdlib) |

**Recommendation:** Follow Clang's model — stable, versioned JSON schema for `pact ast`. Include comment attachment info (this is critical for formatter/linter development). The schema should be documented and machine-discoverable via `pact ast --schema`.

---

### Primitive 3: `io.eprintln` — Stderr Output

**Description:** A basic IO operation for writing to stderr without the `[LOG]` prefix that `io.log` adds. The friction report explicitly called this out: debug output interleaved with formatter stdout, and `io.eprintln` does not exist despite appearing in examples.

**Pact code example:**

```pact
fn debug_parser_state(label: Str) ! IO.Print {
    io.eprintln("DEBUG [{label}]: pos={pos} pending={pending_comments.len()}")
}
```

This requires adding `eprintln` to the IO operations table in section 4.4:

| Effect | Handle | Operations |
|--------|--------|------------|
| `IO` / `IO.*` | `io` | `io.print(...)`, `io.println(...)`, `io.eprintln(...)`, `io.log(...)` |

**Cross-language survey:**

| Language | Stderr mechanism |
|----------|-----------------|
| **Go** | `fmt.Fprintln(os.Stderr, ...)` — explicit file descriptor. Also `log.Println` defaults to stderr. |
| **Rust** | `eprintln!("...")` — dedicated macro, mirrors `println!` but to stderr. |
| **Python** | `print(..., file=sys.stderr)` or `logging.error(...)` |
| **Java** | `System.err.println(...)` |
| **C** | `fprintf(stderr, ...)` |

Every language has this. Pact not having it is simply an oversight. Under `IO.Print` capability, `io.eprintln` should be available alongside `io.println`.

**Recommendation:** Add `io.eprintln(...)` to the IO.Print operations. Trivial, non-controversial, immediately useful.

---

### Primitive 4: Debug Assertions (`debug_assert`)

**Description:** Assertions that are compiled into debug/test builds and stripped from release builds. They carry structured context (interpolated messages) and produce structured failure output (JSON with assertion details, variable values, span).

**Pact code example:**

```pact
fn attach_comments(node_id: Int) {
    debug_assert(
        pending_comments.len() < 100,
        "comment leak: {pending_comments.len()} pending at node {node_id}"
    )
    // ... attach logic
}
```

When triggered during `pact run --debug`, output is structured:

```json
{
  "event": "debug_assert_failed",
  "file": "src/parser.pact",
  "line": 47,
  "function": "attach_comments",
  "condition": "pending_comments.len() < 100",
  "message": "comment leak: 247 pending at node 108",
  "variables": {
    "pending_comments.len()": 247,
    "node_id": 108
  }
}
```

In the friction report, a `debug_assert(pending_comments.len() == 0, "leaked comments after lookahead")` at the exit of `looks_like_struct_lit` would have caught the bug on first run. No instrumentation cycle. No cleanup.

**Cross-language survey:**

| Language | Debug assert | Stripped in release? |
|----------|-------------|---------------------|
| **Go** | No built-in. Convention: `if debug { ... }` with build tags. `testing.TB.Fatal` in tests only. | N/A (manual) |
| **Rust** | `debug_assert!(cond, "msg")` — compiled out in `--release`. | Yes |
| **C/C++** | `assert(cond)` — compiled out with `NDEBUG`. | Yes |
| **Python** | `assert cond, "msg"` — stripped with `python -O`. | Yes |
| **Java** | `assert cond : "msg"` — disabled by default, enabled with `-ea`. | Runtime toggle |
| **D** | `assert(cond, "msg")` in contracts, stripped in release. Also has `debug { }` blocks. | Yes |

**Recommendation:** `debug_assert(condition, message)` as a compiler built-in. Compiles to nothing under `pact build --release`. Active under `pact run --debug` and `pact test`. The failure output MUST be structured JSON, not a panic string.

---

### Primitive 5: Snapshot/Diff of State (`--snapshot`)

**Description:** Capture the value of specified variables at a program point and compare across runs. This is the "conditional breakpoint + watch expression" equivalent for an AI agent that cannot use a debugger interactively.

**Pact code example:**

```sh
pact run formatter.pact --snapshot "parse_block:entry:pending_comments,pos" --format json
```

Output:

```json
{"snapshot":"parse_block:entry","invocation":1,"values":{"pending_comments":[],"pos":0}}
{"snapshot":"parse_block:entry","invocation":2,"values":{"pending_comments":["trailing comma"],"pos":22}}
{"snapshot":"parse_block:entry","invocation":3,"values":{"pending_comments":["trailing comma","trailing comma"],"pos":22}}
```

The duplicate in invocation 3 jumps out. An AI agent can diff invocations 2 and 3 to see exactly what changed.

**Cross-language survey:**

| Tool | Mechanism |
|------|-----------|
| **GDB** watchpoints | `watch pending_comments` — triggers on mutation. Outputs old/new value. |
| **Chrome DevTools** | Logpoints: `console.log(...)` without modifying code. Conditional breakpoints with expressions. |
| **DTrace/BPF** | Tracepoints that capture variable state at function entry/exit without code modification. |
| **Temporal (workflow)** | Event sourcing — every state transition is logged with before/after snapshot. Replay any point. |

**Recommendation:** This is a v2 feature (requires debug symbol tables and runtime instrumentation hooks). But the design should be specified now so the debug info format supports it. The immediate v1 proxy is `--trace` with state events.

---

## Q2: How Should Debugging Interact with the Effect System?

The effect system IS Pact's observability architecture. This is not a metaphor. Here is why.

### Debugging as an Effect: `IO.Debug`

Debug output is IO. It should be an effect. But it should be a SEPARATE sub-effect from `IO.Print` and `IO.Log` so it can be:

1. **Stripped at compile time** — `pact build --release` elides all `IO.Debug` operations to no-ops
2. **Captured in tests** — `with capture_debug(messages) { ... }` collects debug output for assertions
3. **Filtered at runtime** — `pact run --debug=parser` enables only `IO.Debug` calls tagged with "parser"

Proposed addition to the IO effect hierarchy:

```pact
effect IO {
    effect Print      // stdout
    effect Log        // structured logging subsystem (retained in release)
    effect Debug      // debug output (stripped in release)
}
```

Usage:

```pact
fn skip_newlines() ! IO.Debug {
    io.debug("skip_newlines", pos: pos, pending: pending_comments.len())
    while at() == CH_NEWLINE {
        advance()
    }
}
```

The `io.debug` call:
- Emits structured NDJSON to stderr when `--debug` is active
- Compiles to nothing in release builds
- Has a string tag (first argument) for filtering: `--debug=skip_newlines`
- Takes keyword arguments that become structured fields in the output

### Structured Logging Maps to OpenTelemetry

Pact's `IO.Log` should emit structured records, not printf strings. The natural format is OpenTelemetry-compatible:

```pact
fn process_order(id: Int) -> Result[Receipt, OrderError] ! DB.Read, IO.Log {
    io.log("processing_order", order_id: id, step: "start")
    let order = db.read("SELECT * FROM orders WHERE id = {id}")?
    io.log("order_fetched", order_id: id, total: order.total)
    Ok(Receipt { order_id: id, total: order.total })
}
```

Output when run with `--log-format=otlp`:

```json
{
  "timestamp": "2026-02-20T10:30:00.042Z",
  "severity": "INFO",
  "body": "processing_order",
  "attributes": {"order_id": 42, "step": "start"},
  "resource": {"service.name": "myapp"},
  "traceId": "abc123",
  "spanId": "def456"
}
```

This means Pact programs are OTel-native from day one. No instrumentation library, no SDK import, no configuration ceremony. The effect system provides the trace context propagation automatically — every `with` handler block is a natural span boundary.

### Effect Handlers as Trace Spans

The `with handler { }` construct maps directly to distributed tracing spans:

```pact
fn handle_request(req: Request) -> Response ! DB, IO, Net {
    with request_span(req) {            // span: "handle_request"
        let user = fetch_user(req)?     // child span: "fetch_user" (DB.Read)
        let data = fetch_external()?    // child span: "fetch_external" (Net.Connect)
        build_response(user, data)
    }
}
```

The span hierarchy mirrors the handler nesting. The effect system already tracks what capabilities each scope has — attaching trace attributes for which effects are active in each span is trivial.

### Why This Matters for AI Debugging

The friction report's core problem was: "I had no structured way to observe what the program was doing." The effect system already forces every side effect to be declared. Extending it with `IO.Debug` means:

1. Debug instrumentation is VISIBLE in signatures — you can `pact query --effect IO.Debug` to find all debug-instrumented functions
2. Debug output is SWAPPABLE — test handlers can capture and assert on debug events
3. Debug output is STRIPPABLE — release builds have zero debug overhead
4. Debug output is STRUCTURED — AI agents parse JSON, not interleaved println strings

The effect system prevents the exact class of bug from the friction report (hidden side effects in speculative lookahead). But even before full effect enforcement lands, `IO.Debug` as an effect gives AI agents the observability primitives they need.

---

## Q3: Compiler/Tooling Support for AI-Efficient Debugging

This is where I have the strongest opinions. The Go philosophy applies: **simple language, powerful tooling.** Most "debugging features" should be flags on `pact run` and `pact build`, not language syntax.

### 3.1 `pact run --debug` vs `pact run`

These MUST be clearly differentiated:

| Flag | Behavior |
|------|----------|
| `pact run file.pact` | Normal execution. `IO.Debug` operations are no-ops (compiled out or skipped). `debug_assert` is inactive. |
| `pact run --debug file.pact` | Debug mode. `IO.Debug` operations emit to stderr as NDJSON. `debug_assert` is active and produces structured failures. |
| `pact run --debug=parser file.pact` | Filtered debug mode. Only `IO.Debug` calls tagged "parser" (or functions in the parser module) emit output. |
| `pact run --trace file.pact` | Full execution trace. Function entry/exit, effect invocations, state mutations — all as NDJSON to stderr. High overhead, comprehensive. |
| `pact run --trace=parse file.pact` | Filtered trace. Only traces functions matching the filter. |
| `pact build --release file.pact` | Production build. All `IO.Debug` calls, `debug_assert` calls, and trace instrumentation physically removed from generated C. Zero overhead. |

The key principle: **debug instrumentation should never require editing source code.** The friction report's pain was the edit-compile-run-read-edit-compile-run cycle of adding and removing `io.println` calls. With `--debug` and `IO.Debug`, the instrumentation lives in the source permanently and is activated by a flag.

### 3.2 `pact ast` — Full Specification

`pact ast` is listed in the CLI reference (section 8.14) but has no dedicated section. Here is what it needs:

```sh
pact ast <file> [options]
```

| Option | Description |
|--------|-------------|
| `--format json` | JSON output (default) |
| `--format pretty` | Human-readable indented text |
| `--include comments` | Include comment attachment info |
| `--include types` | Include inferred type annotations |
| `--include write-sets` | Include mutation analysis write-sets per function |
| `--include effects` | Include resolved effect sets per function |
| `--include spans` | Include source spans for every node |
| `--include all` | Include everything |
| `--node-id <id>` | Dump subtree rooted at a specific node ID |
| `--fn <name>` | Dump AST for a specific function only |
| `--depth <n>` | Limit tree depth |
| `--schema` | Output the JSON schema for the AST format |

The JSON schema MUST be versioned. Breaking changes to the AST schema get a major version bump. This is critical for CI tooling that parses AST output.

Example CI integration:

```yaml
# .github/workflows/lint.yml
- name: Check no debug effects in production code
  run: |
    pact ast src/ --format json --include effects \
      | jq '[.nodes[] | select(.effects[]? == "IO.Debug")] | length' \
      | xargs -I{} test {} -eq 0
```

### 3.3 `--trace` Output Format

Trace output MUST be NDJSON (newline-delimited JSON) to stderr. One event per line. This is the format that:
- `jq` can filter line-by-line
- OpenTelemetry collectors can ingest
- CI log aggregators (Datadog, Grafana Loki) can parse
- AI agents can process incrementally

**Event schema:**

```json
{
  "ts_us": 1042,
  "event": "enter|exit|state|effect|assert_fail",
  "fn": "function_name",
  "module": "module_name",
  "depth": 2,
  "span": {"file": "src/parser.pact", "line": 42, "col": 5},

  "var": "variable_name",
  "action": "read|write|push|pop",
  "old_value": "...",
  "new_value": "...",

  "effect": "IO.Debug",
  "operation": "debug",
  "args": {"tag": "skip_newlines", "pos": 24}
}
```

Not all fields present on every event. The schema is a union — `event` discriminates the shape.

**Filtering is essential.** Full trace of a compiler run might produce millions of events. Filters:

```sh
pact run --trace=fn:skip_newlines         # only this function
pact run --trace=module:parser            # only functions in parser module
pact run --trace=effect:IO.Debug          # only IO.Debug effect invocations
pact run --trace=state:pending_comments   # only mutations of this variable
pact run --trace=depth:3                  # only top 3 levels of call depth
```

Multiple filters combine with AND: `--trace=module:parser,state:pending_comments`

### 3.4 Structured Debug Output in CI Pipelines

Every debug/diagnostic output format should integrate cleanly with CI:

**GitHub Actions annotations:**

```sh
pact check --format github-actions
```

Output:

```
::error file=src/parser.pact,line=42,col=5::E0500: undeclared effect DB.Read
::warning file=src/parser.pact,line=108,col=1::W0300: incomplete state restore in lookahead
```

GitHub renders these as inline annotations on the PR diff. The AI agent (or human reviewer) sees errors at the exact line without reading logs.

**SARIF (Static Analysis Results Interchange Format):**

```sh
pact check --format sarif > results.sarif
```

SARIF is the standard for static analysis results. GitHub, Azure DevOps, and most CI platforms render SARIF natively. One output format, every platform.

**JUnit XML for test results:**

```sh
pact test --format junit > test-results.xml
```

Every CI platform knows JUnit XML. This is table stakes.

**Summary:** `pact check`, `pact test`, and `pact ast` should support at minimum:
- `--format json` (default for machine consumption)
- `--format github-actions` (CI annotation integration)
- `--format sarif` (static analysis standard)
- `--format junit` (test results standard, `pact test` only)
- `--format pretty` (human-readable, for terminal use)

### 3.5 `pact check --watch` with Event Stream

For AI agents running in a tight loop, a watch mode that emits events as files change:

```sh
pact check --watch --format json
```

Output (NDJSON stream):

```json
{"event":"file_changed","file":"src/parser.pact","ts":"2026-02-20T10:30:00Z"}
{"event":"check_start","files":["src/parser.pact"],"ts":"2026-02-20T10:30:00.01Z"}
{"event":"diagnostic","severity":"error","code":"E0500","file":"src/parser.pact","line":42}
{"event":"check_complete","errors":1,"warnings":0,"duration_ms":47,"ts":"2026-02-20T10:30:00.06Z"}
```

The AI agent reads the stream, sees the error, generates a fix, writes the file, and the next `check_start` event fires automatically. No polling. No explicit re-invocation. The feedback loop is: write file -> see error -> fix -> see clean.

---

## Q4: Language Feature or Purely Tooling?

**My position: primarily tooling, with one small language addition.**

### What should be tooling (NOT language features):

1. **`--trace` flag** — this is a compiler/runtime flag that instruments generated code. No syntax changes needed. The compiler inserts trace calls at function boundaries when `--trace` is active. Go does this with `go tool trace` and it works brilliantly.

2. **`--dump-ast` / `pact ast`** — pure tooling. A different rendering of what the compiler already computes.

3. **`--debug` mode** — a build flag that controls whether `IO.Debug` operations and `debug_assert` are compiled in.

4. **Structured output formats** — `--format json`, `--format sarif`, `--format github-actions` are output formatting choices, not language features.

5. **`pact check --watch`** — tooling feature. The daemon already exists.

6. **CI integration formats** — SARIF, JUnit, GitHub annotations are purely tooling concerns.

### What should be a language feature (minimal additions):

1. **`IO.Debug` sub-effect** — this is a small addition to the effect hierarchy. It gives debug output the same structured, swappable, strippable properties as every other effect. Without it, people use `IO.Print` for debugging and then forget to remove it. With `IO.Debug`, the compiler can warn on `IO.Debug` in release builds, tests can capture debug output, and `pact query --effect IO.Debug` finds all instrumented code.

2. **`io.eprintln`** — an IO.Print operation. This is the tiniest possible language addition: one new method on an existing handle. Every language has stderr output. Pact should too.

3. **`debug_assert`** — a compiler built-in, not a library function. It needs compiler support to:
   - Be stripped in release builds (the compiler must know about it)
   - Produce structured failure output (including variable values and source spans)
   - Interact with the test runner (failures are test failures, not panics)

### The Go lesson

Go's debugging story is: simple language (no debug macros, no conditional compilation, no `#[cfg(debug)]`), powerful tooling (`go tool trace`, `go tool pprof`, `dlv` debugger, `runtime/debug` package). The language provides `fmt.Println` and `log.Println` and that is literally it. Everything else is tooling.

Pact should follow this pattern but do it BETTER because:

1. Pact has an effect system that Go lacks — `IO.Debug` naturally fits as a sub-effect, giving debug output properties Go's `fmt.Println` cannot have (strippable, swappable, queryable)
2. Pact has structured output everywhere — debug output should be structured JSON, not printf strings
3. Pact has a compiler daemon — watch mode and incremental debug-check are natural extensions

The anti-pattern to avoid is D's `debug { }` blocks or Rust's `#[cfg(debug_assertions)]` — compile-time conditional blocks that fragment the language into two dialects (debug and release) and confuse AI agents about which code is "real." Keep the language clean. Let the tooling do the work.

### Summary: What goes where

| Feature | Language or Tooling? | Rationale |
|---------|---------------------|-----------|
| `IO.Debug` sub-effect | **Language** (effect hierarchy addition) | Needs compiler awareness for stripping, handler swapping, effect queries |
| `io.eprintln` | **Language** (IO.Print operation) | Trivial addition to existing effect handle |
| `debug_assert` | **Language** (compiler built-in) | Needs compiler support for stripping and structured output |
| `--trace` flag | **Tooling** | Compiler instruments code at build time; no syntax |
| `pact ast --format json` | **Tooling** | Different rendering of existing compiler data |
| `--debug` build mode | **Tooling** | Build flag that toggles IO.Debug and debug_assert |
| CI output formats | **Tooling** | Output formatting, not language semantics |
| `pact check --watch` | **Tooling** | Daemon feature, not language |
| `--snapshot` variable capture | **Tooling** (v2) | Runtime instrumentation, needs debug symbol tables |

Three small language additions. Everything else is tooling. The language stays clean. The tooling does the heavy lifting. That is the right balance.

---

## Vote Summary

As the DevOps/Tooling panelist, I vote:

1. **YES** to `IO.Debug` as a sub-effect of IO (the one language-level debug primitive that pays for itself)
2. **YES** to `io.eprintln` in the IO.Print operations table (obvious gap)
3. **YES** to `debug_assert` as a compiler built-in (necessary for leave-in-place invariant checks)
4. **YES** to specifying the `pact ast` JSON schema (the CLI reference lists it but has no specification)
5. **YES** to NDJSON trace output via `--trace` flag (the single highest-impact debugging tool for AI agents)
6. **NO** to `@debug` annotation or `debug { }` conditional blocks (tooling handles this via build mode; no language syntax needed)
7. **DEFER** to v2: `--snapshot` variable capture (needs debug symbol infrastructure)
