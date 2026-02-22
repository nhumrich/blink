# Panel Deliberation: AI-First Debugging Story — Synthesis & Vote

**Date:** 2026-02-20
**Panelists:** Systems (Sys), Web/Scripting (Web), PL Theory (PLT), DevOps/Tooling (DevOps), AI/ML (AI)

---

## Unanimous Consensus (No Vote Needed)

### C1: Add `io.eprintln` to IO.Print operations table (§4.4)
**Vote: 5-0 (unanimous)**
All five experts identify this as a spec gap. `io.eprintln(msg)` and `io.eprint(msg)` write to stderr under `IO.Print` capability. Every surveyed language has stderr output. The IO operations table currently lists only `io.print(...)` and `io.log(...)`.

### C2: Add `debug_assert(condition, message)` as compiler built-in
**Vote: 5-0 (unanimous)**
Two-tier model: `assert(cond, msg)` always checks, `debug_assert(cond, msg)` compiles to nothing in release. Interpolated message with variable context. Not an effect — same status as `panic()`. Available everywhere without import.

### C3: Specify `pact ast` with structured JSON output
**Vote: 5-0 (unanimous)**
Already in CLI reference (§8.14) but has no dedicated section. Must include: comment attachments (the pact-398 bug class), node spans, optional types/effects/write-sets. JSON schema should be versioned and stable.

### C4: Add `--trace` flag with structured NDJSON output
**Vote: 5-0 (unanimous)**
`pact run --trace <filter>` emits function entry/exit, state mutations, and effect invocations as NDJSON to stderr. Filterable by module, function, variable, depth. Zero source modification required.

### C5: Expose write-sets through the query system
**Vote: 5-0 (unanimous)**
`pact query --write-sets --fn <name>` returns which module-level `let mut` bindings each function writes. Leverages existing mutation analysis (§4.16). Would have identified the pact-398 bug without running the program.

### C6: Reject `@debug` annotation blocks
**Vote: 5-0 (unanimous rejection)**
All experts independently reject `@debug { }` conditional compilation blocks. Reasons: fragments the language into debug/release dialects, conflates annotations with conditional compilation, creates invisible effect holes, slippery slope toward `#ifdef` spaghetti.

---

## Contested Questions — Panel Vote

### V1: How should debug primitives interact with the effect system?

**Option A: Real effect `! IO.Debug`** (DevOps)
- Debug output tracked as `IO.Debug` sub-effect, stripped in release
- Pro: queryable (`pact query --effect IO.Debug`), swappable via handlers, consistent with effect system
- Con: signature pollution — adding debug output cascades `! IO.Debug` through entire call chain

**Option B: Outside effect system entirely** (Systems, Web)
- `debug_assert` and debug-mode primitives are compiler intrinsics, no effect declaration
- `io.eprintln` (manual debug prints) remains effect-tracked under `IO.Print`
- Pro: zero ceremony for temporary debug output, matches C/Rust/Zig precedent
- Con: violates "no `!` means no effects" guarantee (though only in debug builds)

**Option C: Transparent non-propagating effect `Observe`** (PLT)
- New effect class with special semantics: tracked by compiler but stripped at call boundaries
- Formally grounded in commutativity axioms from algebraic effect theory
- Pro: principled, compiler-aware, non-interfering, formally sound
- Con: novel effect modality adds type-theoretic complexity, no precedent in other languages

**Option D: Transparent `debug.*` handle** (AI/ML)
- Always-in-scope handle (`debug.trace(...)`, `debug.assert(...)`)
- Not a real effect — compiler instrumentation that is stripped in release
- Pro: zero ceremony, always available, explicit handle syntax distinguishes from real effects
- Con: introduces a "magic" handle that violates normal handle-from-effect rules

**Vote:**
- Systems: **B** (outside effect system — zero-cost abstraction principle)
- Web: **B** (outside effect system — "if it's stripped in release, it's not an effect")
- PLT: **C** (transparent Observe — formally grounded non-propagation)
- DevOps: **A** (IO.Debug — observable, queryable, consistent with effect model)
- AI/ML: **D** (transparent debug handle — zero ceremony, always available)

**Result: No clear majority.** B has 2 votes, A/C/D have 1 each.

**Tiebreak analysis:** Options B, C, and D all share the critical property: **debug output does not propagate through effect signatures.** They differ in formalism but agree on the practical constraint. Option A is the outlier — it requires signature changes, which all other experts identify as a dealbreaker.

**Consolidated vote (propagation question):**
- Should debug primitives propagate through effect signatures? **NO: 4-1** (only DevOps votes yes)

**Refined vote (B vs C vs D for non-propagating approach):**
- B (compiler intrinsic, no effect tracking): Systems, Web
- C (transparent Observe effect class): PLT
- D (transparent debug handle): AI/ML

**Resolution:** Options C and D are mechanistically similar — both propose a debug facility that the compiler is aware of but that doesn't propagate. The difference is whether it's formally modeled as a novel effect class (C) or as a special handle (D). PLT's formal grounding strengthens D's pragmatic approach.

**Merged proposal (B+C+D):** Debug primitives (`debug_assert`, `trace`) are **compiler-known constructs** that:
1. Do not appear in effect signatures (non-propagating)
2. Are tracked by the compiler (can be listed, warned on, stripped)
3. Compile to nothing in release builds (zero-cost)
4. Are formally characterized as non-interfering observations (PLT's commutativity argument)

Manual debug prints (`io.eprintln`) remain fully effect-tracked under `IO.Print`.

**Final vote on merged proposal: 4-1** (DevOps dissents, prefers IO.Debug for queryability; accepts the result noting that compiler tracking per point 2 provides equivalent queryability)

---

### V2: Should there be an inline expression inspector (`dbg`/`trace`)?

**Option A: `dbg(expr)` — returns value, prints expression text + value + location** (Web)
- Syntax: `let x = dbg(pos)` — prints and returns `pos`
- Compiles to nothing in release
- Matches Rust `dbg!`, Elixir `dbg`, Python `f"{expr=}"`

**Option B: `trace(expr, msg)` — returns value, prints message** (PLT)
- Syntax: `let result = trace(at() == CH_LBRACE, "struct check at {pos}")`
- Transparent Observe effect semantics
- Two forms: `trace(msg)` (statement) and `trace(expr, msg)` (expression, returns expr)

**Option C: No inline inspector — use `--trace` tooling** (Systems, DevOps, AI)
- `@trace`/`@instrument` annotations + `--trace` flag handle function-level tracing
- `debug.trace(msg)` statement form handles ad-hoc output
- No need for pass-through expression form

**Vote:**
- Systems: **C** (annotations + flags sufficient)
- Web: **A** (`dbg` is highest-value primitive for rapid iteration)
- PLT: **B** (`trace` with formal semantics)
- DevOps: **C** (tooling, not language)
- AI/ML: **C** (statement form `debug.trace(msg)` sufficient; expression form is sugar)

**Result: 3-1-1.** C wins (no inline expression inspector in v1). Web dissents (strongly wants `dbg`). PLT proposes `trace` with formal semantics but accepts statement-only form.

**Resolution:** v1 ships with statement-form `debug_assert(cond, msg)` only. A pass-through expression form (`dbg` or `trace`) is deferred to v2 consideration — it's sugar over the statement form and can be added later without breaking changes.

---

### V3: Should there be a function-level tracing annotation (`@trace`/`@instrument`)?

**Option A: Yes — add `@trace` or `@instrument` as 16th annotation** (Systems, PLT)
- Declarative: annotate function, compiler instruments entry/exit
- Leverages write-set analysis for automatic state capture
- Activated by `--trace` flag, compiles to nothing otherwise

**Option B: No annotation — `--trace` flag instruments all/filtered functions** (Web, DevOps, AI)
- The compiler can instrument any function when `--trace=fn:name` is specified
- No source annotation needed — purely a tooling concern
- Avoids adding to the already-long annotation list

**Vote:**
- Systems: **A** (`@trace` — selective instrumentation, zero-cost when off)
- Web: **B** (tooling — no annotation needed, `--trace` filter is sufficient)
- PLT: **A** (`@instrument` — declarative, integrates with annotation system)
- DevOps: **B** (tooling — Go philosophy, keep language simple)
- AI/ML: **B** (tooling — no source modification for investigation)

**Result: 3-2.** B wins (no annotation; `--trace` is purely a tooling flag). Systems and PLT dissent (prefer declarative annotation for selective tracing).

**Resolution:** v1 uses `--trace` with filter syntax (`--trace=fn:name`, `--trace=module:parser`). No `@trace`/`@instrument` annotation. Rationale: the 3-vote majority argues that tooling-level tracing achieves the same result without growing the annotation surface. The compiler can instrument any function on demand via flag — no source change needed.

---

### V4: CLI commands for call graph queries

**Proposed:** `pact query --callers <fn>`, `pact query --callees <fn>`, `pact query --call-graph <fn>`

**Vote: 5-0 (unanimous)**
All experts agree the compiler has this data. Exposing it through the query system is incremental work with high debugging value.

---

### V5: `--debug` build mode flag

**Proposed:** `pact build --debug` / `pact run --debug` activates `debug_assert`, debug output, and disables optimizations. `pact build` (default) is release mode with debug primitives stripped.

**Vote: 5-0 (unanimous)**

---

### V6: Structured runtime error context

**Proposed:** Runtime panics and assertion failures produce structured JSON with call stack, local variables, and relevant module-level state.

**Vote: 5-0 (unanimous)**

---

## AI-First Review

Evaluating the consolidated decisions against the 5 AI-First criteria:

### 1. Learnability
**PASS.** Three primitives: `debug_assert(cond, msg)`, `io.eprintln(msg)`, and `--trace` flag. Minimal new concepts. `debug_assert` mirrors Rust/C convention. `io.eprintln` mirrors `io.println`. `--trace` is a flag, not syntax.

### 2. Consistency
**PASS.** `io.eprintln` fits the existing `io.*` handle pattern. `debug_assert` parallels `assert` (from test blocks). `--trace` follows the existing `--format json` flag pattern. No new syntax forms.

### 3. Generability (can AI generate correct usage?)
**PASS.** All primitives have simple, memorable signatures. `debug_assert(bool, str)` is trivial to generate. `io.eprintln(str)` is trivial. `--trace` is a CLI flag. No complex interaction patterns.

### 4. Debuggability
**PASS (by definition).** This is the debugging feature set. The pact-398 session drops from ~15 tool calls to 2-4.

### 5. Token Efficiency
**PASS.** `debug_assert` is 1 line. `io.eprintln` is 1 line. `--trace` produces structured JSON that can be filtered with `jq`. Write-set queries at ~80 tokens/function give full mutation surface for an entire module in <5000 tokens. The debug inspection layer (Layer 2.5 in query system) provides mutation + call target info at ~80 tok/fn.

**AI-First Review: 5/5 PASS. No reconsideration needed.**

---

## Summary of Decisions

| # | Decision | Vote | Status |
|---|----------|------|--------|
| C1 | Add `io.eprintln`/`io.eprint` to IO.Print ops (§4.4) | 5-0 | **Resolved** |
| C2 | Add `debug_assert(cond, msg)` — compiler built-in, stripped in release | 5-0 | **Resolved** |
| C3 | Specify `pact ast` with JSON output, comment attachments, versioned schema | 5-0 | **Resolved** |
| C4 | Add `--trace` flag with structured NDJSON output, filterable | 5-0 | **Resolved** |
| C5 | Expose write-sets via `pact query --write-sets` | 5-0 | **Resolved** |
| C6 | Reject `@debug` annotation blocks | 5-0 | **Resolved (rejected)** |
| V1 | Debug primitives do not propagate through effect signatures | 4-1 | **Resolved** (DevOps dissents) |
| V2 | No inline expression inspector (`dbg`/`trace`) in v1; defer to v2 | 3-1-1 | **Resolved** (Web dissents) |
| V3 | No `@trace`/`@instrument` annotation; `--trace` is tooling-only | 3-2 | **Resolved** (Sys/PLT dissent) |
| V4 | Add call graph queries to `pact query` | 5-0 | **Resolved** |
| V5 | Add `--debug` build mode flag | 5-0 | **Resolved** |
| V6 | Structured JSON for runtime errors (call stack, locals, state) | 5-0 | **Resolved** |
