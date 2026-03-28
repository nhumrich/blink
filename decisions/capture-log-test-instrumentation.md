[< All Decisions](../DECISIONS.md)

# capture_log / Test Instrumentation API — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions. Resolves spec gap: "capture_log / test instrumentation API — ability to capture and assert on log output in tests."

**Q1: Should `capture_log` be stdlib or user-land? (4-1 for stdlib in `std.testing`)**

- **Systems:** User-land. `capture_log` is a trivial 3-line handler constructor. No codegen complexity — creates a vtable struct with one function pointer. Putting this in stdlib adds maintenance surface for something that compiles identically either way. Document the pattern in examples. *(dissent)*
- **Web/Scripting:** Stdlib. Every testing framework ships log capture out of the box (Python `assertLogs`, Jest `spyOn`, Elixir `CaptureLog`). Making developers write their own handler to capture logs forces understanding full effect handler machinery before writing a first meaningful test. Spec already uses `capture_log` in examples — ship what the docs promise.
- **PLT:** Stdlib. `capture_log` is the canonical example of a handler-returning function — it establishes the idiom that handlers are the testing primitive. A compiler-team-maintained reference implementation grounds `Handler[E]` semantics. Users see exactly how handler values are produced and composed.
- **DevOps:** Stdlib. Critical for tooling: (1) compiler can emit targeted diagnostics referencing it by name ("Hint: wrap in `with capture_log([]) { }`"); (2) LSP autocomplete can suggest it; (3) `blink test --json` can standardize captured log reporting.
- **AI/ML:** Stdlib. A single canonical pattern that LLMs learn from spec + examples and reproduce reliably. User-land patterns invite variation — every generation might differ. Fixed stdlib function = one import, one signature, lower token cost.

**Q2: What should `capture_log` capture? (5-0 for `io.log()` only as `List[Str]`)**

- **Systems:** Only `io.log()`. Minimal vtable (single function pointer), no unused slots. Composes with separate `IO.Print` handlers via partial handler + auto-delegation. Structured `LogEntry` adds heap allocation per log call for a wrapper that carries no info beyond the string.
- **Web/Scripting:** Only `io.log()`. Does one thing obviously. Bundling print and log muddies the mental model. `LogEntry` adds a type that doesn't exist yet with no value until structured logging ships. YAGNI.
- **PLT:** Only `io.log()`. `Handler[IO.Log]` is a more precise type than `Handler[IO]` — captures exactly the capability it intercepts. The effect hierarchy exists to enable fine-grained decomposition; bundling undermines it. Handler algebra composes focused handlers: `with capture_log(logs), capture_print(prints) { ... }`.
- **DevOps:** Only `io.log()`. CI output semantics should be unambiguous — "these are log messages." Mixing streams makes parsing harder. Diagnostic hints stay precise: "needs IO.Log handler" → `capture_log`.
- **AI/ML:** Only `io.log()`. Minimal API surface = fewer decision points. Option B forces reasoning about two lists even when only one is needed. Option C's `LogEntry` adds a type to remember and destructure — overhead for the 90% case.

**Q3: Should there be assertion helpers for captured output? (5-0 for no new assertions)**

- **Systems:** No. `List[Str]` supports indexing, `len()`, iteration. `assert(messages[0].contains("..."))` compiles to direct string search. `assert_logged` introduces a linear scan users can't control. Predicate-based option requires closure allocation per assertion. New helpers need same compiler integration for useful failure output — non-trivial codegen work for marginal benefit.
- **Web/Scripting:** No. `assert(messages[0].contains("Processing order 42"))` is immediately readable to anyone from JS or Python. `assert_logged` saves zero keystrokes and obscures what's checked. Keep assertion vocabulary small, let composition work.
- **PLT:** No. Existing assertions are polymorphic (`assert_eq` works on any `Eq` type). `assert_logged` is domain-specific to `List[Str]` and string matching — breaks the principle that assertions should be type-generic. Predicate-based option is equivalent to `assert(messages.any(pred))` which is already expressible.
- **DevOps:** No. Power assert introspection already shows actual values on failure. Adding `assert_logged` creates a second assertion vocabulary tooling must understand and render in JSON output. Standard list operations with power asserts cover common cases.
- **AI/ML:** No. Existing assertions + `List` methods are sufficient and well-understood across languages. `assert_logged` introduces ambiguity ("does it check contains, equals, or regex?") that causes generation errors. Zero new API surface, zero new decision points.
