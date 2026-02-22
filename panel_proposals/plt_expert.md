# PLT Expert Panel Response: Debugging Primitives for AI Agents

**Panelist:** Programming Language Theory Expert
**Background:** Haskell, OCaml, Koka, formal methods
**Date:** 2026-02-20

---

## Q1: Core Debugging Primitives an AI Agent Needs

After studying the friction report, I identify five primitives. The ordering reflects what I consider the type-theoretic priority: static information first, runtime observation second.

### Primitive 1: `assert` / `debug_assert` — Invariant Assertions

**Description:** Two-tier assertion system. `assert(cond, msg)` always checks (runtime cost proportional to the condition). `debug_assert(cond, msg)` compiles to nothing in release builds, active only under `--debug` or in test mode. Both accept string-interpolated messages for context.

**Pact example:**

```pact
fn attach_comments(node_id: Int) {
    debug_assert(node_id >= 0, "invalid node_id: {node_id}")
    debug_assert(
        pending_comments.len() < 1000,
        "comment leak detected: {pending_comments.len()} pending at node {node_id}"
    )
    // ... attach logic
}

fn parse_block() -> Int {
    let start_pos = pos
    // ... parsing logic
    assert(pos >= start_pos, "parser went backwards: {pos} < {start_pos}")
    block_id
}
```

**Cross-language survey:**

| Language | Mechanism | Semantics |
|----------|-----------|-----------|
| **Rust** | `assert!()`, `debug_assert!()` | `debug_assert!` compiled out in release. Both panic on failure. |
| **C/C++** | `assert()` via `<assert.h>` | Compiled out when `NDEBUG` defined. Single tier only. |
| **Python** | `assert` statement | Compiled out with `-O` flag. Single tier. |
| **Go** | No built-in. Convention: manual `if !cond { panic() }` | No conditional compilation. Always present or manually deleted. |
| **D** | `assert()`, plus `debug { }` blocks | `debug` blocks removed in release. `assert` can be disabled per-module. |
| **Koka** | `assert()` in std/core | Always-on, no conditional tier. |

**PLT analysis:** The two-tier model is well-established (Rust's is the gold standard). The critical property for AI is that `debug_assert` is *semantically invisible* — it does not change the program's type, effect signature, or observable behavior. It is metadata for developers, not part of the program's denotation. This makes it safe to leave permanently in the codebase without affecting compiled output.

---

### Primitive 2: `trace` — Transparent Execution Trace

**Description:** A function (or expression form) that emits a value to stderr and returns it unchanged. The key property: `trace(x)` has the same type and value as `x`. It is the identity function with a side effect.

**Pact example:**

```pact
fn skip_newlines() {
    while at() == CH_NEWLINE {
        advance()
        if at() == CH_HASH {
            let comment = parse_comment()
            trace("skip_newlines collected comment: {comment} at pos {pos}")
            pending_comments.push(comment)
        }
    }
}

// Expression form: trace returns its argument
fn looks_like_struct_lit() -> Bool {
    let saved_pos = pos
    skip_newlines()
    let result = trace(at() == CH_LBRACE, "struct_lit check at pos {pos}")
    pos = saved_pos
    result
}
```

**Cross-language survey:**

| Language | Mechanism | Semantics |
|----------|-----------|-----------|
| **Haskell** | `Debug.Trace.trace :: String -> a -> a` | Uses `unsafePerformIO`. Returns argument unchanged. Deliberately impure. |
| **OCaml** | `Printf.eprintf` (manual), or `ppx_debug` | No built-in trace. `eprintf` writes stderr but is a normal effectful call. |
| **Koka** | `trace(msg)` in std/core | Writes to stderr. Declared as having the `console` effect but commonly used with `unsafe-no-div`. |
| **Rust** | `dbg!()` macro | Prints to stderr, returns value. Macro expands to `eprintln!` + value. |
| **Elm** | `Debug.log : String -> a -> a` | Returns argument. Compiler warns if present. Cannot ship in published packages. |
| **Idris 2** | `Debug.Trace.trace : String -> a -> a` | Same as Haskell. Uses `unsafePerformIO` internally. |

**PLT analysis:** This is the most type-theoretically contentious primitive. Every language with a principled type/effect system that provides `trace` does so by cheating: Haskell uses `unsafePerformIO`, Koka uses `unsafe-no-div`, Elm restricts it to dev mode. The fundamental tension is that `trace` violates referential transparency — `trace("x", 42)` and `42` are denotationally identical but operationally distinct. See Q2 for my full treatment of how this should interact with Pact's effect system.

---

### Primitive 3: `pact ast <file>` — Structured AST Dump

**Description:** A compiler command (already listed in Pact's CLI reference at section 8.14) that dumps the parsed AST as structured JSON. For debugging parser and formatter bugs, this is the single most useful primitive — the friction report's bug would have been immediately visible as a duplicate comment attachment in the AST dump.

**Pact example (CLI):**

```
$ pact ast src/parser.pact --json --node-range 42:1-50:1
```

```json
{
  "kind": "WhileLoop",
  "span": {"line": 42, "col": 1, "end_line": 50, "end_col": 1},
  "comments": [
    {"text": "trailing comma case", "line": 26},
    {"text": "trailing comma case", "line": 26}
  ],
  "children": [...]
}
```

The duplicate comment is immediately visible. No print-debugging needed.

**Cross-language survey:**

| Language | Mechanism | Output format |
|----------|-----------|---------------|
| **Rust** | `rustc -Z ast-json` (nightly), `cargo expand` | JSON AST or macro-expanded source. Unstable. |
| **Python** | `ast.dump(ast.parse(source))` | Python repr string. Not JSON. |
| **Go** | `go/ast` package, `go/printer` | Programmatic API, not CLI. |
| **TypeScript** | `ts.createSourceFile()` + custom walk | Programmatic. No built-in CLI dump. |
| **Clang** | `clang -Xclang -ast-dump` | Textual dump. Structured with `-ast-dump=json`. |
| **Koka** | No public AST dump tool | N/A |

**PLT analysis:** AST dumps are the debugging equivalent of the query system's Layer 3 (full implementation) but for the compiler's internal representation rather than the source. The key insight from the friction report is that comment attachment is invisible in source code — you cannot see which AST node owns a comment by reading the source. Only the AST representation reveals it. This makes `pact ast` a necessary complement to `pact query`.

---

### Primitive 4: `--trace <subsystem>` — Compiler-Internal Tracing

**Description:** A compiler flag that enables structured tracing of internal compiler phases. Not a language feature but a tooling feature that produces structured JSON describing the compiler's execution.

**Pact example (CLI):**

```
$ pact build src/example.pact --trace parse --json
```

```json
{"event": "enter", "fn": "parse_block", "pos": 22, "depth": 0}
{"event": "enter", "fn": "parse_stmt", "pos": 24, "depth": 1}
{"event": "enter", "fn": "parse_primary", "pos": 24, "depth": 2}
{"event": "enter", "fn": "looks_like_struct_lit", "pos": 24, "depth": 3}
{"event": "mutation", "fn": "skip_newlines", "var": "pending_comments", "op": "push", "value": "trailing comma case", "pos": 26}
{"event": "exit", "fn": "looks_like_struct_lit", "pos": 24, "result": false, "depth": 3}
```

**Cross-language survey:**

| Language | Mechanism | Granularity |
|----------|-----------|-------------|
| **Rust** | `-Z trace-macros`, `RUSTC_LOG=debug` | Per-pass logging. Extremely verbose. |
| **GHC (Haskell)** | `-ddump-parsed`, `-ddump-tc`, `-ddump-simpl` | Per-pass AST dumps. Can filter by phase. |
| **OCaml** | `OCAMLRUNPARAM` debug flags | GC tracing primarily. Limited compiler pass tracing. |
| **Go** | `GODEBUG` environment variable | Runtime-level (GC, scheduler). Not compiler phases. |
| **Clang/LLVM** | `-mllvm -debug`, `opt -debug-pass=Structure` | Extremely detailed pass pipeline tracing. |
| **Koka** | `--debug`, `--verbose` flags | Compiler phase logging to stderr. |

**PLT analysis:** This is purely tooling — no type-theoretic implications. But it is essential for AI agents because compiler tracing replaces the "add println, recompile, run, read output" loop with a single command. The friction report shows 5+ iterations of manual instrumentation; `--trace parse` would have been one invocation. The structured JSON output is key — an AI agent can programmatically filter and search the trace rather than scanning unstructured text.

---

### Primitive 5: `@instrument` — Compiler-Directed Instrumentation Annotation

**Description:** An annotation that instructs the compiler to emit tracing information for a function's entry, exit, arguments, and return value. Compiled away in release builds. Unlike `trace` (which is ad-hoc), `@instrument` is declarative — you annotate the function once, and the compiler handles the instrumentation.

**Pact example:**

```pact
@instrument
fn skip_newlines() {
    while at() == CH_NEWLINE {
        advance()
        if at() == CH_HASH {
            pending_comments.push(parse_comment())
        }
    }
}

@instrument
fn looks_like_struct_lit() -> Bool {
    let saved_pos = pos
    skip_newlines()
    let result = at() == CH_LBRACE
    pos = saved_pos
    result
}
```

When compiled with `--debug`, the compiler generates entry/exit traces:

```
[TRACE] skip_newlines ENTER  pos=24 pending_comments.len()=0
[TRACE] skip_newlines EXIT   pos=27 pending_comments.len()=1
[TRACE] looks_like_struct_lit ENTER  pos=24
[TRACE]   skip_newlines ENTER  pos=24 pending_comments.len()=0
[TRACE]   skip_newlines EXIT   pos=27 pending_comments.len()=1
[TRACE] looks_like_struct_lit EXIT  pos=24 result=false
```

**Cross-language survey:**

| Language | Mechanism | Semantics |
|----------|-----------|-----------|
| **Rust** | `#[tracing::instrument]` (tracing crate) | Procedural macro. Emits `tracing` spans on entry/exit. Always compiled in (filtered at runtime). |
| **Python** | `@functools.wraps` + custom decorator | Manual. No standard library support. |
| **Java** | AspectJ `@Around`, Spring AOP | Bytecode weaving. Heavy framework dependency. |
| **Elixir** | `:dbg.tpl` / `:sys.trace` | Erlang VM tracing. Can be attached to running processes without recompilation. |
| **D** | `pragma(instrument_function)` | Compiler inserts `__cyg_profile_func_enter/exit` calls. |

**PLT analysis:** `@instrument` is semantically cleaner than `trace` because it is declarative rather than expression-level. The compiler knows the annotation is present and can: (a) generate appropriate tracing code in debug builds, (b) compile it completely away in release builds, (c) include the function's write set (from mutation analysis, section 4.16) in the trace output. Property (c) is particularly powerful — the mutation analysis already knows that `skip_newlines` writes `{pos, pending_comments}`, so the instrumentation can automatically log those variables on entry and exit.

---

## Q2: How Should Debugging Interact with the Effect System?

This is the central question, and the one where I have the strongest opinion. Let me lay out the options with full type-theoretic analysis.

### The Fundamental Tension

Pact's effect system is the language's security architecture (section 4.1). Every side effect is declared, tracked, and enforced. Debug output is a side effect — it writes to stderr. Therefore, by the language's own principles, debug output should be an effect.

But if debug output is an effect, then adding a `trace()` call changes the function's signature. This has cascading consequences:

1. Every caller must also declare the debug effect.
2. Effect propagation (section 4.5) pushes the debug annotation up the entire call graph.
3. Module capability budgets (section 4.8) must include the debug effect.
4. Removing the trace changes signatures back, creating noisy diffs.

This is exactly what makes `trace` unusable in practice if treated as a normal effect. The friction report demonstrates this: the developer needed to add `io.println` calls (requiring `! IO.Print`) to parser functions that were not supposed to have IO effects. The debug instrumentation polluted the effect signatures.

### Analysis of Options

#### Option (a): Real Effect (`! IO.Debug`)

```pact
// What this would look like
fn skip_newlines() ! IO.Debug {
    trace("entering skip_newlines at pos {pos}")
    // ...
}

// Every caller must now declare IO.Debug
fn parse_block() ! IO.Debug {
    skip_newlines()
    // ...
}
```

**Type-theoretic status:** Fully principled. Effect tracking is sound. The compiler can verify that all debug output is declared.

**Fatal problem:** Effect signature pollution. You would need `! IO.Debug` on every function in the call chain. This defeats the purpose of the effect system — when everything has `! IO.Debug`, the annotation carries zero information. It is exactly the "coarse effects collapse to meaninglessness within three call levels" failure mode that section 4.1 warns about. Also violates Principle 3 (locality of reasoning) because the debug annotation tells you nothing about the function's actual behavior.

**Verdict: Reject.**

#### Option (b): Outside the Effect System Entirely

```pact
// What this would look like: trace is a magic function
// that writes to stderr but requires no effect declaration
fn skip_newlines() {
    trace("entering skip_newlines at pos {pos}")
    // ... remains effect-free in its signature
}
```

**Type-theoretic status:** Unsound. This is `unsafePerformIO` by another name. The function signature claims no effects, but calling `trace` performs IO. The effect system's soundness guarantee ("a function with no `!` cannot perform side effects — the compiler proves it") is violated.

**Precedent:** This is exactly what Haskell does with `Debug.Trace`. The Haskell community broadly considers `Debug.Trace` an acceptable pragmatic compromise because: (1) it is clearly marked as `unsafe`, (2) the community norm is to never ship it in production, (3) GHC can warn on its presence. But Haskell's effect tracking is a single `IO` monad — breaking it is binary (you're either in IO or you're not). Pact's fine-grained effect system has more to lose from unsoundness.

**Partial defense:** If `trace` only writes to stderr and only in debug builds, the unsoundness is confined to debug mode. Release builds are effect-sound. The operational semantics of the program are unchanged — `trace` is operationally the identity function in release mode.

**Verdict: Viable but uncomfortable. My second choice.**

#### Option (c): Transparent Effect That Does Not Propagate

```pact
// What this would look like: trace has a special "transparent" effect
// that the compiler tracks but does not propagate to callers
fn skip_newlines() {
    trace("entering at pos {pos}")  // ! Debug.Trace is transparent
    // ... callers of skip_newlines() do not need ! Debug.Trace
}
```

**Type-theoretic status:** This is a novel effect modality. In standard algebraic effect theory (as in Koka, Eff, Frank), effects always propagate. A "transparent" effect that is tracked by the compiler but not propagated would require extending the effect algebra with a new class of effects that have no upward propagation.

**Formal characterization:** Let me be precise. In Pact's effect system, if function `f` has effects `E_f` and calls function `g` with effects `E_g`, then `E_f` must be a superset of `E_g` (section 4.5). A transparent effect `T` would modify this rule: `E_f` must be a superset of `E_g \ {T}`. The transparent effect is stripped at every call boundary.

**Is this sound?** Yes, if the transparent effect satisfies a specific property: **it must not affect the observable behavior of the program**. In domain theory terms, the denotation of `f` with and without the transparent effect must be the same. `trace` satisfies this — it writes to stderr (a side channel) but does not change the return value or other state.

This is formally equivalent to saying the transparent effect lives in a separate "observation monad" that commutes with all other effects. The program's primary effect algebra is unchanged; the observation effect is layered orthogonally.

**Precedent:** This pattern exists in program analysis as "non-interfering instrumentation." It is related to information flow type systems where "low" observations do not interfere with "high" computations.

**Verdict: My strong recommendation.** See detailed proposal below.

#### Option (d): Conditional Compilation (Not an Effect at All)

```pact
// What this would look like: debug blocks compiled away in release
@instrument
fn skip_newlines() {
    // compiler inserts traces in debug build, nothing in release
}
```

**Type-theoretic status:** Fully sound. In release mode, the annotation does not exist. In debug mode, the annotation directs the compiler to generate additional code, but that code is not part of the function's formal semantics.

**This is orthogonal to trace.** `@instrument` is declarative (the compiler decides what to trace). `trace` is imperative (the developer decides what to output). Both are needed.

**Verdict: Complementary to options (b) or (c), not a replacement.**

### My Recommendation: Option (c) with Formal Grounding

I propose introducing a **transparent effect class** called `Observe`. Effects in the `Observe` class have three properties:

1. **Non-propagating:** A caller of a function with `! Observe.Trace` does not need to declare `! Observe.Trace`. The effect is stripped at every call boundary.

2. **Non-interfering:** The compiler guarantees that `Observe` effects cannot modify any state that other effects can observe. `Observe.Trace` can write to stderr but cannot mutate program variables, return different values, or interact with other effect handles.

3. **Build-mode gated:** `Observe` effects compile to no-ops in release builds. They are active only when the compiler is invoked with `--debug` (or in test mode).

```pact
// Formal definition in the effect hierarchy
effect Observe {
    effect Trace     // write to stderr trace channel
    effect Profile   // emit timing markers (future)
    effect Count     // increment counters (future)
}
```

**How it works in practice:**

```pact
fn skip_newlines() {
    // No effect annotation needed. Observe.Trace is transparent.
    trace("entering skip_newlines at pos {pos}")
    while at() == CH_NEWLINE {
        advance()
        if at() == CH_HASH {
            let comment = parse_comment()
            trace("collected comment: {comment}")
            pending_comments.push(comment)
        }
    }
}

fn looks_like_struct_lit() -> Bool {
    // This function's signature remains pure: no ! annotation
    let saved_pos = pos
    skip_newlines()
    let result = at() == CH_LBRACE
    trace("struct_lit check: {result} at pos {pos}")
    pos = saved_pos
    result
}
```

**Why this is better than option (b) (Haskell-style `unsafePerformIO`):**

- The compiler **knows** about `Observe.Trace`. It can warn if trace calls are left in code submitted for release. It can count them, list them, strip them. `unsafePerformIO` is opaque to the compiler.
- The non-interference property is **enforced**. A `trace` call cannot accidentally mutate state or change control flow. In Haskell, `Debug.Trace.trace` can affect evaluation order due to laziness — a known footgun.
- The effect algebra remains **sound at the primary level**. The `Observe` class is a formally separate stratum. You can reason about program correctness ignoring `Observe` effects entirely, because they are provably non-interfering.

**Why not just use handlers to intercept?**

One might ask: "Why not just make `trace` a normal effect and provide a handler that discards it in release?" The answer is the propagation problem. Even with a discarding handler, every function in the call chain must declare `! Observe.Trace` so the handler can intercept it. That is the signature pollution problem from option (a). The transparent property is specifically about avoiding propagation.

**Formal relationship to algebraic effects:**

In the algebraic effect literature (Plotkin & Pretnar, 2009), every effect operation has a type of the form `Op: A -> B` where the handler provides the implementation. Transparent effects extend this with a **commutativity axiom**: for any effect operation `op` in the `Observe` class and any other effect operation `e`, `op; e` and `e; op` produce the same observable result (up to the observation channel). This justifies the non-propagation property — if the observation commutes with all other effects, its presence or absence does not affect the program's meaning.

---

## Q3: Compiler/Tooling Support for AI-Efficient Debugging

Based on the friction report analysis and Pact's existing tooling architecture (section 8), I recommend the following. I order these by impact-to-effort ratio.

### 3.1 Extend the Query System with Write-Set Information

The mutation analysis (section 4.16) already computes write sets. Expose them through the query system:

```
$ pact query --write-set --fn parser.skip_newlines --json
```

```json
{
  "function": "parser.skip_newlines",
  "write_set": ["pos", "pending_comments"],
  "transitive_callees": [
    {"function": "advance", "write_set": ["pos"]},
    {"function": "parse_comment", "write_set": ["pos"]}
  ]
}
```

This is the information the AI needed in the friction report. The write set immediately reveals that `skip_newlines` mutates `pending_comments` — the hidden side effect that caused the bug. No print-debugging needed.

### 3.2 Implement `pact ast` with Comment Attachment Visualization

The CLI reference (section 8.14) lists `pact ast <file>` but it has no dedicated spec section. Implement it with:

- JSON output (consistent with all other Pact tooling).
- Comment attachment shown explicitly (which node owns which comments).
- Span information for every node (file, line, column ranges).
- Optional `--node-range` flag to dump only a subtree.

### 3.3 Structured Compiler Tracing (`--trace`)

Implement per-phase tracing that emits structured JSON (NDJSON, one event per line) to stderr:

```
$ pact build src/parser.pact --trace parse 2>trace.jsonl
```

Subsystem identifiers: `lex`, `parse`, `typecheck`, `effects`, `codegen`, `all`.

Each trace event should include: event type (enter/exit/mutation/error), function name, position, depth, and relevant state variables (from the write set analysis).

### 3.4 LSP Integration: Write-Set on Hover

The LSP already integrates with the compiler daemon. Add write-set information to hover tooltips:

```
skip_newlines()
  ── writes: pos, pending_comments
  ── calls: advance (writes: pos), parse_comment (writes: pos)
```

This is the "mutation analysis for humans and AI" use case from section 4.16.1. The friction report notes that the AI "needed the language to enforce its own rules." Surfacing the write set in the LSP is the next-best thing until the compiler self-hosts with full effect checking.

### 3.5 `io.eprintln` — Plain Stderr Output

The friction report explicitly calls out the absence of `io.eprintln`. The IO effect handle table (section 4.4) lists `io.print(...)` and `io.log(...)` but no plain stderr print. `io.log` adds a `[LOG]` prefix, which interferes with debug output that needs to be parsed.

Add `io.eprintln` as an `IO.Print` operation (it is output, just to a different file descriptor). This is a spec gap, not a deep design question.

---

## Q4: Language Feature vs. Purely Tooling?

This is the key design decision, and I want to frame it precisely in type-theoretic terms.

### The Spectrum

There is a spectrum from "pure tooling" (no language changes) to "deep language feature" (new syntax, new type system concepts):

```
Tooling only  ─────────────────────────────────  Language feature
  │                                                     │
  pact ast          @instrument        trace()      ! Observe
  --trace           debug_assert       (transparent    (new effect
  pact query        (annotation)        effect)        class)
```

Moving rightward increases the type-theoretic footprint. Moving leftward increases the implementation simplicity but reduces the compiler's ability to reason about the feature.

### My Recommended Split

**Language features (require spec changes):**

1. **`debug_assert(cond, msg)`** — A built-in function that compiles to nothing in release builds. Type: `fn(Bool, Str) -> ()`. No effect. No type-theoretic cost. This is a universally accepted primitive. Every serious language has it or should.

2. **`trace(msg)` and `trace(expr, msg)`** — With transparent `Observe.Trace` effect semantics as described in Q2. This is the only type-theoretically novel part of the proposal. The two-argument form `trace(expr, msg)` returns `expr` unchanged (identity semantics with observation side-channel).

3. **`io.eprintln(msg)`** — Add to the IO effect handle table. Trivial spec addition. Requires `! IO.Print`.

**Annotations (metadata, no semantic impact):**

4. **`@instrument`** — A new annotation (would be the 16th, inserted after `@verify` and before `@deprecated` in canonical ordering). Directs the compiler to generate entry/exit tracing in debug builds. No semantic impact in release builds. The compiler uses the mutation analysis write set to determine what state to include in traces.

**Tooling (no spec changes):**

5. **`pact ast <file>`** — Already in CLI reference. Implement with JSON output and comment attachment visualization.

6. **`--trace <subsystem>`** — Compiler flag. Structured NDJSON output. No language-level impact.

7. **Write-set exposure in `pact query` and LSP hover** — Pure tooling extension of existing infrastructure.

### Type-Theoretic Implications

**`debug_assert` has zero type-theoretic cost.** It is operationally the identity function on `()` in release mode. In debug mode, it may diverge (panic), but divergence is already untracked in Pact (same as `panic()` per section 4.4.3 discussion of `exit` vs `panic`).

**`trace` with transparent effects has a bounded type-theoretic cost.** It introduces a new effect modality (non-propagating, non-interfering) that requires extending the effect algebra. The extension is principled — it is grounded in commutativity axioms from the algebraic effects literature. The implementation cost is modest: the compiler tracks `Observe` effects in a separate bitset that does not participate in effect propagation or handler dispatch. The soundness argument is: removing all `Observe` effects from a program does not change its denotation.

**`@instrument` has zero type-theoretic cost.** It is a compiler directive, not a semantic feature. The annotation does not appear in the function's type or effect signature. It is erased in release builds. This is the same status as `@perf` — metadata for tooling, not for the type system.

### Why Not Purely Tooling?

The friction report's key insight is: "The AI didn't need a debugger. It needed the language to enforce its own rules."

Pure tooling approaches (AST dumps, compiler tracing) help *after* a bug is suspected. Language features (`debug_assert`, `trace`) help *prevent* bugs from recurring. The three-time recurrence of the `skip_newlines` bug demonstrates this — each instance required re-discovering the hidden side effect through runtime observation. A `debug_assert(pending_comments.len() == 0, "comment leak")` at the start of every pure lookahead function would have caught the second and third instances immediately.

The type-theoretic argument for language features over pure tooling: **language features compose with the type system, tooling does not.** A `debug_assert` in the source code is checked by the compiler, versioned with the code, and visible to every future reader (human or AI). A `--trace` flag is ephemeral — its output is consumed once and discarded. Permanent invariant documentation (assertions) should live in the language; ephemeral observation (tracing) can live in the tooling.

### Summary of Proposals by Category

| Proposal | Category | Spec Impact | Type-Theory Cost | Priority |
|----------|----------|-------------|------------------|----------|
| `debug_assert` | Language | Minimal (built-in fn) | Zero | **P0** |
| `trace` with `Observe` | Language | Moderate (new effect class) | Bounded, principled | **P0** |
| `io.eprintln` | Language | Minimal (effect table entry) | Zero | **P0** |
| `@instrument` | Annotation | Small (16th annotation) | Zero | **P1** |
| `pact ast` impl | Tooling | None (already in CLI ref) | Zero | **P1** |
| `--trace` flag | Tooling | None | Zero | **P1** |
| Write-set in query/LSP | Tooling | None | Zero | **P2** |

P0 items address the friction report's core complaint directly. P1 items reduce debugging cycle time. P2 items improve the information surface for proactive understanding.

---

## Appendix: On the Friction Report's Deeper Point

The friction report concludes: "The AI didn't need a debugger. It needed the language to enforce its own rules."

I want to sharpen this from a PLT perspective. What the AI actually needed was **effect soundness in the compiler itself**. If `skip_newlines()` had been forced to declare `! MutateState` (or, in Pact's terms, if the mutation analysis had been enforced rather than advisory), the type system would have rejected `looks_like_struct_lit()` calling it without saving and restoring the full state.

The debugging primitives proposed here are a **second line of defense** for when the type system cannot catch a bug statically (which, during bootstrap, is the current situation). The first line of defense — making the compiler dogfood its own effect system — is the architecturally correct solution. These proposals serve the interim period and the general case where effects alone are not sufficient (e.g., logic errors in pure functions that satisfy all type constraints but produce wrong results).

The transparent `Observe` effect is designed to be maximally useful during this interim while being minimally disruptive to the effect algebra that will eventually provide the real solution.
