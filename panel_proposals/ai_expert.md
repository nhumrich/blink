# AI/ML Expert Panel Response: Debugging Primitives for AI Agents

**Panelist:** AI/ML Expert (LLM agent tooling, AI-assisted programming)
**Date:** 2026-02-20
**Context:** Responding to AI_DEBUGGING_FRICTION.md — the pact-398 formatter comment duplication session

---

## Q1: Core Debugging Primitives an AI Agent Needs

### Framing: AI debugging is fundamentally batch-mode

An AI agent operates under constraints that make the entire human debugging paradigm irrelevant:

1. **No interactivity.** Breakpoints, stepping, watches, conditional pauses — all require a human in the loop reacting to state in real time. An AI sends a command, waits for output, reads the result. Every debugging action is a discrete tool call with a round-trip cost.
2. **Finite context window.** Every byte of debug output competes with code, spec, and reasoning for context space. Verbose debug output is not just annoying — it actively degrades the agent's ability to reason about the problem.
3. **Token cost is real cost.** Each tool call and each token of output has a dollar cost and a latency cost. The friction report documents ~15 tool calls. At typical agent pricing, that is not free.
4. **No undo.** A human can `Ctrl-Z` debug instrumentation. An AI must explicitly find and remove every `io.println` it added. The friction report highlights this: the cleanup phase is pure waste.

These constraints lead to a clear design principle: **debugging primitives for AI must be one-shot, structured, and zero-residue.** The agent gets everything it needs in a single run, in a machine-parseable format, and leaves no instrumentation behind in the source.

### Primitive 1: Structured Execution Trace (`--trace`)

**Description:** A compiler/runtime flag that emits a structured JSON trace of function entry/exit, key state transitions, and effect operations — without modifying source code. The trace is filterable by module, function, or effect.

**Pact example:**

```sh
pact run src/formatter.pact --trace "parser.*" --trace-format json < input.pact
```

```json
{"event": "enter", "fn": "parser.parse_block", "pos": 22, "depth": 0, "ts_us": 14}
{"event": "enter", "fn": "parser.parse_stmt", "pos": 24, "depth": 1, "ts_us": 18}
{"event": "enter", "fn": "parser.skip_newlines", "pos": 24, "depth": 2, "ts_us": 21}
{"event": "state", "fn": "parser.skip_newlines", "var": "pending_comments", "op": "push", "value": "\" trailing comma case\"", "ts_us": 23}
{"event": "exit", "fn": "parser.skip_newlines", "pos": 26, "depth": 2, "ts_us": 25}
{"event": "enter", "fn": "parser.looks_like_struct_lit", "pos": 26, "depth": 2, "ts_us": 27}
{"event": "enter", "fn": "parser.skip_newlines", "pos": 26, "depth": 3, "ts_us": 29}
{"event": "state", "fn": "parser.skip_newlines", "var": "pending_comments", "op": "push", "value": "\" trailing comma case\"", "ts_us": 31}
{"event": "exit", "fn": "parser.skip_newlines", "pos": 28, "depth": 3, "ts_us": 33}
{"event": "exit", "fn": "parser.looks_like_struct_lit", "pos": 26, "depth": 2, "backtrack": true, "ts_us": 36}
```

With this trace, the pact-398 bug is immediately visible: `pending_comments.push` fires twice for the same comment string, once inside `skip_newlines` called from `parse_stmt` and again inside `skip_newlines` called from `looks_like_struct_lit`. The AI sees the duplication in one run, without inserting a single `io.println`.

**Why AI specifically needs this:**
- **One-shot.** Zero source modifications, zero recompilation cycles. The 5+ iteration loop from the friction report collapses to 1.
- **Structured.** JSON lines are grep-able. The AI can filter `jq '.event == "state" and .var == "pending_comments"'` to isolate exactly the state mutations it cares about, without reading hundreds of lines of function entry/exit noise.
- **Zero residue.** No debug lines to insert, no debug lines to clean up. The agent's edit budget goes entirely toward the fix.

**Cross-language survey:**

| Tool | Mechanism | Structured? | Filterable? | Source modification? |
|------|-----------|-------------|-------------|---------------------|
| **Rust (`tracing` crate)** | `#[instrument]` macro + `RUST_LOG` env var | JSON via `tracing-subscriber` | By module path, level | Requires adding `#[instrument]` to each function |
| **Python (`sys.settrace`)** | Runtime hook, intercepts call/return/line | Raw tuples, not structured | Must implement filtering manually | No source modification (runtime hook) |
| **Go (`runtime/trace`)** | Runtime tracing via `trace.Start()`/`trace.Stop()` | Binary format, parsed by `go tool trace` | By goroutine, region, annotation | Requires `trace.WithRegion()` calls in source |
| **DTrace / BPF** | OS-level dynamic tracing, no recompilation | Structured via probes/aggregations | By probe, predicate | No source modification — probes are external |
| **OpenTelemetry** | Cross-language distributed tracing standard | JSON/protobuf spans | By service, operation, attribute | Requires SDK instrumentation in source |

Pact's advantage: the compiler already has the call graph, the effect annotations, and the mutation write-sets. It can auto-instrument at the compiler level (like DTrace probes) without requiring the user to annotate anything. No other language has the combination of effect-aware structured tracing with zero source modification.

### Primitive 2: State Snapshot Diff (`--snapshot`)

**Description:** A mechanism that captures the complete relevant state at a programmer-specified point (or automatically at function boundaries), serializes it to structured JSON, and supports automatic diffing between two points. The critical insight: AI agents don't debug by watching values change in real time. They debug by comparing "state at point A" vs "state at point B" and reasoning about what went wrong.

**Pact example (compiler flag, no source changes):**

```sh
pact run src/formatter.pact --snapshot-at "parser.looks_like_struct_lit:entry,exit" --snapshot-format json < input.pact
```

```json
{
  "snapshots": [
    {
      "id": "snap_001",
      "fn": "parser.looks_like_struct_lit",
      "point": "entry",
      "call_id": 7,
      "state": {
        "pos": 26,
        "pending_comments": ["\" trailing comma case\""],
        "pending_doc_comment": null,
        "tok_count": 42
      }
    },
    {
      "id": "snap_002",
      "fn": "parser.looks_like_struct_lit",
      "point": "exit",
      "call_id": 7,
      "state": {
        "pos": 26,
        "pending_comments": ["\" trailing comma case\"", "\" trailing comma case\""],
        "pending_doc_comment": null,
        "tok_count": 42
      },
      "diff_from_entry": {
        "pending_comments": {"added": ["\" trailing comma case\""], "at_index": 1}
      }
    }
  ]
}
```

The `diff_from_entry` field immediately shows that `looks_like_struct_lit` (which should be side-effect-free lookahead) mutated `pending_comments` by appending a duplicate entry. Bug found.

**Why AI specifically needs this:**
- **Diffing is the AI's native debugging mode.** AI agents are extraordinarily good at comparing two structured objects and spotting differences. Humans are good at watching values evolve; AI is good at spotting what changed between two snapshots.
- **Token-efficient.** The diff is dramatically smaller than a full trace. In the pact-398 case, the diff is ~50 tokens vs ~500 tokens for the equivalent trace.
- **Captures exactly the mutation write-set.** The compiler knows which module-level `let mut` variables exist (from mutation analysis, section 4.16). It can automatically snapshot exactly those variables, not "everything."

**Cross-language survey:**

| Tool | Mechanism | Diff support? | Auto-capture? |
|------|-----------|---------------|---------------|
| **Redux DevTools (JS)** | State snapshots on every action dispatch. Time-travel debugging with automatic state diffs. | Yes, built-in | Yes, middleware |
| **GDB `checkpoint`** | Process-level fork at a point in time, compare memory | Manual (diff two core dumps) | No |
| **Elm Debugger** | Immutable state model, every message produces a new state, full history with diffs | Yes, built-in | Yes, part of architecture |
| **Python `pdb` + `copy.deepcopy`** | Manual snapshot: save state, run code, compare | Manual (`deepdiff` library) | No |
| **Rust `dbg!` macro** | Prints expression value + file/line to stderr, returns value | No | No |

The pattern from Redux and Elm is telling: languages and frameworks that model state explicitly make debugging dramatically easier. Pact's mutation analysis already tracks which state each function touches. Snapshots are the natural debugging extension.

### Primitive 3: Assertion Trace (`assert_trace`)

**Description:** A debug-mode assertion that, when it fires, dumps not just "the assertion failed" but a structured trace of how the asserted condition became false, including the chain of mutations that led to the violating state. This is the combination of `debug_assert` and `--trace` — the assertion is the trigger, and the trace is the payload.

**Pact code example:**

```pact
fn attach_comments(node_id: Int) {
    assert_trace(
        pending_comments.len() <= 1,
        watch: [pending_comments],
        "expected at most 1 pending comment, got {pending_comments.len()}"
    )
    for comment in pending_comments {
        node_set_comment(node_id, comment)
    }
    pending_comments.clear()
}
```

When the assertion fires, it emits:

```json
{
  "assertion_failed": "pending_comments.len() <= 1",
  "message": "expected at most 1 pending comment, got 2",
  "location": {"file": "src/parser.pact", "line": 142, "col": 5},
  "watch_trace": {
    "pending_comments": [
      {"op": "push", "value": "\" trailing comma case\"", "caller": "parser.skip_newlines", "call_stack": ["parser.parse_stmt", "parser.parse_block"]},
      {"op": "push", "value": "\" trailing comma case\"", "caller": "parser.skip_newlines", "call_stack": ["parser.looks_like_struct_lit", "parser.parse_primary", "parser.parse_stmt", "parser.parse_block"]}
    ]
  }
}
```

The watch trace shows the full mutation history of the watched variable, with call stacks at each mutation point. The AI immediately sees that `pending_comments` was pushed to twice, from two different call paths, both through `skip_newlines`.

**Why AI specifically needs this:**
- **Assertions are left permanently in the code.** Unlike `io.println` debug lines, assertions document invariants. They are useful documentation even after the bug is fixed.
- **The trace payload eliminates follow-up investigation.** A normal `assert` says "this is wrong." An `assert_trace` says "this is wrong, and here is exactly the chain of events that made it wrong." The AI does not need a second debugging cycle.
- **Token-efficient trigger.** Instead of tracing everything and filtering, the assertion fires only on failure. Normal execution produces zero output.

**Cross-language survey:**

| Tool | Assertion type | Trace on failure? | Persists in code? |
|------|---------------|-------------------|-------------------|
| **Rust `debug_assert!`** | Condition + message, compiled out in release | No — just panics with message | Yes (compiles to nothing in release) |
| **C `assert.h`** | Condition, compiled out with `NDEBUG` | No — prints condition string and aborts | Yes (compiled out) |
| **Python `pytest`** | `assert` with AST rewriting for rich output | Partial — shows values of subexpressions | Yes |
| **Java `assert`** | Condition + message, disabled by default at runtime | No | Yes (disabled by flag) |
| **Zig `@breakpoint()` + `std.debug.assert`** | Assertion + optional message | No trace, but `@errorReturnTrace()` captures return trace | Yes |

No language I know of provides mutation-trace-on-assertion-failure. This would be a genuinely novel debugging primitive, and it is uniquely feasible in Pact because the compiler already tracks write-sets via mutation analysis (section 4.16). The compiler knows which functions write to `pending_comments`, so it can instrument exactly those write points.

### Primitive 4: Effect-Aware Call Graph Query

**Description:** A compiler query that returns the call graph for a specific function, annotated with effects and write-sets. Not a runtime debugging tool — a static analysis tool that the AI consults before deciding where to look.

**Pact CLI example:**

```sh
pact query --call-graph parser.looks_like_struct_lit --depth 2 --show-write-sets
```

```json
{
  "root": "parser.looks_like_struct_lit",
  "write_set": ["pos", "pending_comments"],
  "calls": [
    {
      "fn": "parser.skip_newlines",
      "write_set": ["pos", "pending_comments"],
      "calls": [
        {"fn": "parser.advance", "write_set": ["pos"]},
        {"fn": "parser.at", "write_set": []},
        {"fn": "parser.parse_comment", "write_set": ["pending_comments"]}
      ]
    },
    {"fn": "parser.at", "write_set": []}
  ],
  "flags": {
    "saves_and_restores": ["pos"],
    "does_not_restore": ["pending_comments"]
  }
}
```

The `does_not_restore` flag catches the pact-398 bug class at the query level: `looks_like_struct_lit` saves/restores `pos` but not `pending_comments`, yet it transitively writes to `pending_comments`. The AI doesn't even need to run the program.

**Why AI specifically needs this:**
- **Pre-debugging triage.** Before inserting any instrumentation or running any trace, the AI can ask "which functions touch which state?" and immediately narrow the investigation space. In the pact-398 case, this query alone would have identified `skip_newlines` as the problematic call — the entire 15-tool-call debugging session replaced by one query.
- **Integrates with the layered inspection model.** This is Layer 1.5 — more than signatures (Layer 1) but less than full source (Layer 3). It gives the AI the call structure and mutation surface without reading any function bodies.
- **Static, not dynamic.** No program execution needed. Works even when the program crashes on startup.

**Cross-language survey:**

| Tool | Call graph? | Write-set tracking? | Structured output? |
|------|-------------|--------------------|--------------------|
| **Rust Analyzer** | Yes, via LSP call hierarchy | No write-set tracking | LSP protocol (structured) |
| **Go `callgraph` (x/tools)** | Yes, multiple algorithms (static, RTA, CHA) | No | Dot/text format |
| **Python `pyan3`** | Yes, static analysis of function calls | No | Dot/JSON |
| **Haskell GHC (`-ddump-stg`)** | Partial — STG dumps show call structure | No (IO monad is opaque) | Unstructured text |
| **Java IntelliJ** | Yes, IDE call hierarchy | No write-set | IDE-only, not CLI-queryable |

None of these combine call graph with write-set information. Pact's mutation analysis (section 4.16) makes this combination natural. The data already exists inside the compiler; exposing it through the query system requires only a new output format.

### Primitive 5: Structured AST Dump with Metadata (`pact ast`)

**Description:** The CLI reference (section 8.14) lists `pact ast <file>` but the spec gives it no dedicated section. This should emit the full AST as structured JSON with comment attachments, node IDs, spans, and inferred types. This is the "X-ray" view: when an AI needs to understand exactly what the parser produced, it reads the AST rather than guessing from source text.

**Pact CLI example:**

```sh
pact ast src/example.pact --json --include comments,types,spans
```

```json
{
  "nodes": [
    {
      "id": 42,
      "kind": "LetBinding",
      "name": "x",
      "span": {"line": 5, "col": 5, "end_line": 5, "end_col": 20},
      "type": "Int",
      "comments": [{"text": " important value", "position": "leading"}],
      "children": [
        {"id": 43, "kind": "IntLiteral", "value": 42, "span": {"line": 5, "col": 13, "end_col": 15}}
      ]
    }
  ]
}
```

**Why AI specifically needs this:**
- **Parser bugs are AST bugs.** The friction report is about a parser bug. The symptom is in the AST (duplicate comments). If the AI can see the AST directly, many parser bugs are immediately visible without running the formatter at all.
- **Comment attachment is invisible in source.** You cannot tell from reading source code which AST node a comment is attached to. The AST dump makes this explicit.
- **Diff two AST dumps for regression testing.** Parse the same file before and after a change, diff the JSON. Structural regressions show up as JSON diffs, not as "the formatter output looks different somehow."

**Cross-language survey:**

| Tool | AST dump? | Structured? | Includes comments? |
|------|-----------|-------------|-------------------|
| **Rust (`rustc -Zunpretty=ast-tree`)** | Yes | Unstructured text (Debug format) | No — comments stripped by lexer |
| **Python (`ast.dump`)** | Yes | Semi-structured Python repr | No |
| **Go (`go/ast` + `go/printer`)** | Yes, via `ast.Print` | Semi-structured Go repr | Yes (AST retains comments) |
| **TypeScript Compiler API** | Yes, full AST as objects | Structured (TS objects) | Yes (trivia attached to nodes) |
| **Clang (`-Xclang -ast-dump=json`)** | Yes | Full JSON | Partial |

Pact should ensure its AST dump is strictly JSON and includes comment attachments, since comment handling is a known pain point.

---

## Q2: Debugging and the Effect System

### The catastrophic signature propagation problem

The friction report buries the lede on this one. Consider the debugging workflow:

1. AI adds `io.println("debug: pos={pos}")` to `skip_newlines()`
2. `skip_newlines()` now requires `! IO.Print`
3. Every caller of `skip_newlines()` must also declare `! IO.Print`
4. `parse_block()`, `parse_stmt()`, `parse_let_binding()`, `looks_like_struct_lit()` — all must change
5. Their callers must change too
6. Effect propagation cascades through the entire call graph back to `main()`

This is not hypothetical. If Pact enforces effects on its own compiler (which it should, per the friction report's recommendation), then adding a single debug print requires editing dozens of function signatures. Removing the debug print requires reverting all of them. This makes print-debugging catastrophically expensive under effect discipline.

### Solution: Debug effects are transparent to the effect checker

The effect system should recognize a `Debug` effect that is:
- Implicitly available in all functions when compiling with `--debug` or when `pact run` is used in development mode
- Completely stripped (not compiled) in release mode
- Invisible in function signatures — it does not propagate

This is analogous to how mutation analysis (section 4.16) tracks writes without putting them in effect signatures. Debug output is instrumentation, not application semantics.

**Proposed mechanism:**

```pact
fn skip_newlines() {
    while at() == CH_NEWLINE {
        debug.trace("skip_newlines at pos={pos}")
        advance()
        if at() == CH_HASH {
            pending_comments.push(parse_comment())
            debug.trace("collected comment at pos={pos}")
        }
    }
}
```

Rules:
- `debug.trace(...)`, `debug.snapshot(...)`, `debug.assert(...)` are the debug handle operations
- The `debug` handle is always in scope, like `io` is for `main`
- In release mode (`pact build`), all `debug.*` calls are stripped at the AST level before codegen. They produce zero code.
- In debug mode (`pact run --debug`, `pact check --debug`), they emit to stderr as structured JSON
- `debug.*` calls do NOT require `! Debug` in the function signature. The effect checker ignores them entirely.
- `debug.*` calls are syntactically distinct from real effect operations — the compiler knows they are instrumentation

**Why this is safe:** Debug output is a side effect, but it is not a capability. The security argument for effects (section 4.1) is about controlling what code is *allowed to do* in production. Debug instrumentation is ephemeral by definition — it exists only during development and is stripped from deployed code. Including it in the capability model would mean the effect system actively hinders debugging, which is counterproductive.

**Precedent:** Rust's `debug_assert!` compiles to nothing in release. Zig's `@breakpoint()` is stripped in ReleaseFast. Neither language tracks these as effects in their type system. The principle is the same: debug instrumentation is metadata about development, not application semantics.

**Interaction with handlers:** Debug output should NOT be interceptable via effect handlers. It is not a "real" effect — it is compiler instrumentation. Trying to `with mock_debug() { ... }` would be a compile error. This prevents debug instrumentation from accidentally becoming load-bearing application logic.

### Alternative considered and rejected: `@debug` annotation blocks

The friction report proposes `@debug`-annotated functions. This is worse than transparent debug effects because:

1. It still requires marking functions. If you need debug output in 5 functions, you annotate 5 functions.
2. It creates a second class of function. "Is this function `@debug` or not?" becomes a question.
3. It interacts with the existing 15 annotations in non-obvious ways (where does `@debug` go in canonical ordering?).

The transparent debug effect is simpler: `debug.trace(...)` works everywhere, always, with zero ceremony.

---

## Q3: Compiler/Tooling Support for AI-Efficient Debugging

### Principle: One run, all information

The pact-398 session required 5+ iterations because each iteration added slightly more debug output. The AI was doing a binary search through state space, one print statement at a time. The right approach is to give the AI everything in one run and let it filter.

### Concrete tooling proposals

**1. `--trace` with structured JSON lines output**

Already described in Q1. Key design decisions:
- Output format: JSON lines (one JSON object per line). Not a single JSON array. JSON lines can be streamed, filtered with `grep`/`jq`, and truncated without breaking parsing.
- Filtering: `--trace "parser.*"` (module glob), `--trace "parser.skip_newlines"` (specific function), `--trace-state "pending_comments"` (specific variable mutations).
- Depth control: `--trace-depth 3` limits call nesting to avoid combinatorial explosion in deeply recursive functions.
- Token budget: Include a `--trace-limit 1000` flag that stops after N trace events. Better to get 1000 events from the beginning than the last 1000 from an overflowed buffer.

**2. Structured error context at every level**

The existing structured diagnostics (section 8.6) are excellent for compile errors. Extend the same principle to runtime failures:

```json
{
  "kind": "runtime_assertion",
  "message": "index out of bounds: -1",
  "location": {"file": "src/codegen.pact", "line": 847, "col": 12},
  "context": {
    "function": "codegen.emit_call",
    "locals": {"node_id": 142, "arg_count": 3, "emitted": -1},
    "call_stack": [
      {"fn": "codegen.emit_call", "line": 847},
      {"fn": "codegen.emit_expr", "line": 623},
      {"fn": "codegen.emit_stmt", "line": 412},
      {"fn": "codegen.generate", "line": 55}
    ],
    "write_set_at_crash": {
      "output_buffer": "[...4823 chars]",
      "indent_level": 2,
      "current_fn": "pact_parser_parse_block"
    }
  }
}
```

This combines the crash location, local variable state, call stack, and relevant module-level state into one JSON blob. The AI reads this once and has full context.

**3. Integration with layered inspection (section 8.3)**

Add a `debug` layer between `contract` (Layer 2) and `full` (Layer 3):

```
Layer 0: Intent        ~20 tokens/function    @i annotations only
Layer 1: Signatures    ~40 tokens/function    names + types + effects
Layer 2: Contracts     ~60 tokens/function    + @requires/@ensures
Layer 2.5: Debug       ~80 tokens/function    + write-sets + call targets
Layer 3: Full          ~200 tokens/function   complete implementation
```

The debug layer adds write-set information and direct call targets to signatures — exactly what the AI needs for debugging triage without reading full implementations.

```sh
pact query --layer debug --module parser
```

```json
{
  "module": "parser",
  "functions": [
    {
      "name": "skip_newlines",
      "signature": "fn skip_newlines()",
      "write_set": ["pos", "pending_comments"],
      "calls": ["advance", "at", "parse_comment"],
      "intent": "Skip newline tokens, collecting comments"
    },
    {
      "name": "looks_like_struct_lit",
      "signature": "fn looks_like_struct_lit() -> Bool",
      "write_set": ["pos", "pending_comments"],
      "saves_restores": ["pos"],
      "does_not_restore": ["pending_comments"],
      "calls": ["skip_newlines", "at"],
      "intent": "Speculative lookahead for struct literal syntax"
    }
  ]
}
```

At ~80 tokens per function, the AI can read the debug layer for the entire parser module (~40 functions = ~3200 tokens) and immediately identify `does_not_restore: ["pending_comments"]` on `looks_like_struct_lit` as suspicious. Total token budget: 3200 tokens vs the 15-tool-call investigation in the friction report.

**4. `pact ast` with diff mode**

```sh
pact ast input.pact --json > before.json
# (make a change)
pact ast input.pact --json > after.json
pact ast --diff before.json after.json
```

The diff shows structural AST changes: added nodes, removed nodes, changed comment attachments, moved subtrees. This is strictly more useful than text diff for parser debugging.

**5. `pact check --why <function>`**

When the compiler emits a warning (like the `IncompleteStateRestore` warning from section 4.16), the AI should be able to ask "why?" and get the full reasoning chain:

```sh
pact check --why "parser.looks_like_struct_lit"
```

```json
{
  "function": "parser.looks_like_struct_lit",
  "diagnostics": [
    {
      "code": "W_IncompleteStateRestore",
      "reasoning": [
        "looks_like_struct_lit saves `pos` at line 42",
        "looks_like_struct_lit calls skip_newlines()",
        "skip_newlines writes to: {pos, pending_comments}",
        "looks_like_struct_lit restores `pos` at line 48",
        "looks_like_struct_lit does NOT restore `pending_comments`",
        "=> pending_comments may be corrupted after speculative lookahead"
      ]
    }
  ]
}
```

This is the compiler explaining its own analysis in a structured, step-by-step format that the AI can follow. It turns the mutation analysis from section 4.16 into an active debugging tool.

---

## Q4: Language Feature vs Purely Tooling

### The AI workflow and where it breaks

The current debug workflow for an AI agent is:

```
1. Add debug code to N functions     → N file edits (tool calls)
2. Compile                           → 1 tool call
3. Run                               → 1 tool call
4. Read output                       → 1 tool call
5. Analyze, repeat 1-4               → M iterations
6. Remove debug code from N functions → N file edits (tool calls)
7. Compile to verify clean            → 1 tool call
```

Total: `(N + 3) * M + N + 1` tool calls. For the pact-398 case: `(5 + 3) * 5 + 5 + 1 = 46` tool calls (the actual count was lower due to batching, but the magnitude is right).

The ideal workflow is:

```
1. Run with trace flags    → 1 tool call
2. Read output             → 1 tool call
3. Query compiler          → 0-2 tool calls
```

Total: 2-4 tool calls. An order of magnitude improvement.

### Recommendation: Three-tier approach

**Tier 1: Pure tooling (no language changes)**
- `--trace`, `--snapshot`, `pact ast --json`, `pact query --call-graph`, `pact query --layer debug`
- Implemented entirely in the compiler/CLI
- No syntax changes, no new keywords, no new annotations
- Covers 80% of AI debugging needs
- Should ship first, possibly v1

**Tier 2: Lightweight language feature (`debug.*` handle)**
- `debug.trace(...)`, `debug.snapshot(...)`, `debug.assert(...)`
- A handle that is always in scope, compiled out in release
- Not a real effect — does not participate in effect signatures
- Covers the remaining 15% — cases where the agent needs to instrument specific code paths that tooling-level tracing cannot isolate
- v1 or v1.1

**Tier 3: Advanced (`assert_trace` with mutation history)**
- Assertion that captures the mutation trace of watched variables
- Requires deeper compiler integration (instrumenting write points for watched variables)
- Covers the final 5% — deep state corruption bugs
- v2

### Why NOT purely tooling

If debugging is purely tooling, there is no way to leave permanent invariant checks in the code. `debug.assert(pending_comments.len() <= 1, "...")` is valuable documentation that catches regressions. Tooling flags are ephemeral — they are not committed to the repository, they are not shared across developers, they are not part of the program's self-description.

The effect system's thesis is "make side effects explicit and visible." Debug assertions are a form of making invariants explicit and visible. They belong in the language, not just the tooling.

### Why NOT purely language

Most debugging does not need source changes. The `--trace` flag and the query system handle the overwhelming majority of cases by giving the AI structured visibility into program execution without touching any source files. Making everything a language feature would mean: more syntax to learn, more annotation ordering to debate, more interaction with the effect system to design.

The sweet spot is: **tooling for investigation, language features for invariants.** The AI uses `--trace` to find the bug (investigation), then adds a `debug.assert(...)` to prevent regression (invariant). The investigation is ephemeral; the invariant is permanent.

---

## Summary of Proposals

| Primitive | Type | Priority | Token efficiency | pact-398 impact |
|-----------|------|----------|-----------------|-----------------|
| `--trace` (structured execution trace) | Tooling | v1 | ~500 tok vs ~5000 tok manual tracing | Would have found bug in 1 run |
| `--snapshot` (state diff) | Tooling | v1 | ~50 tok diff vs ~500 tok trace | Would have shown the mutation directly |
| `debug.*` handle (transparent debug effect) | Language | v1 | Zero in release, ~20 tok/call in debug | Permanent instrumentation without effect cascading |
| Call graph + write-set query | Tooling | v1 | ~80 tok/fn at debug layer | Would have identified bug without running the program |
| `pact ast --json` (structured AST dump) | Tooling | v1 | Variable, but grep-able | Would have shown duplicate comment attachment |
| `assert_trace` (mutation-traced assertion) | Language | v2 | Zero unless triggered, ~200 tok on failure | Would have caught regression automatically |
| Debug inspection layer (Layer 2.5) | Tooling | v1 | ~80 tok/fn | Triage in ~3200 tokens for entire parser |

### The key insight from the friction report, restated

"The AI didn't need a debugger. It needed the language to enforce its own rules."

This is correct but incomplete. The full version: **The AI needed the language to enforce its own rules AND, when those rules were not yet enforced, it needed structured batch-mode visibility into program state.** The first half is the effect system. The second half is everything proposed in this document.
