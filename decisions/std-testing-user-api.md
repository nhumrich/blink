[< All Decisions](../DECISIONS.md)

# std.testing — Library API Expansion — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on four questions, then ran a Round-2 live debate on Q4 after the Round-1 result (3-2 for "no new matchers") was contradicted by the panel's own dissent — every voter, including the majority, flagged float comparison as a genuine correctness trap.

Resolves spec gap `nyyt0s`: "expand std.testing user-facing API beyond `capture_log`/`capture_print`/`capture_eprint`."

Scope was narrowed by user direction to a tight core (Q1 fixtures, Q2 table-driven, Q3 snapshots, Q4 matchers); sub-tests, mocking helpers beyond IO, deterministic randomness, compiler-as-library, and runner knobs (`@timeout_ms`/`@only`/`@retry`) are deferred to follow-up tickets.

---

**Q1: Setup/teardown/fixtures (4-1 for `defer` builtin; PLT dissent)**

Options: A — none, factor with `fn` and `with`. B — `defer cleanup()` runs at scope exit on pass/fail/skip. C — module-level `setup`/`teardown`. D — `Fixture[T]` trait.

- **Systems:** B. `defer` is the zero-overhead primitive — stack-pushed cleanup, no hidden allocator, no trait dispatch, no runtime fixture registry. Composes with existing `with` blocks for RAII-style effects instead of bolting on a parallel "fixture" type system that forces indirect calls.
- **Web/Scripting:** B. `defer` is the JS/Python/Go developer's bread and butter (Go `defer`, Python context managers, JS `try/finally`). What people actually mess up is teardown on the failure path — `defer` solves exactly that without inventing `Fixture[T]` ceremony. Module-level setup/teardown (C) is a JUnit-era footgun: shared mutable state across tests is the #1 source of flakiness.
- **PLT:** A. *(dissent)* Blink already has algebraic effects with `with handler { }` — that IS the principled teardown mechanism. `defer` (B) duplicates effect-handler semantics with an ad-hoc control-flow construct, breaking compositionality; setup/teardown blocks (C) are imperative cruft from xUnit and don't compose across modules; `Fixture[T]` (D) is fine in user-land but premature in stdlib. A test is just a pure function — factor with `fn` and scope effects with `with`.
- **DevOps:** B. `defer` gives the cleanest diagnostic surface — teardown lives at the call site, so failure stack traces and trace output show cleanup in the same scope as the test body. Module-level setup/teardown (C) is a notorious LSP/error-message hazard: "which test failed in setUp?" is a perpetual JUnit/pytest pain point.
- **AI/ML:** B. `defer` is a single, generalizable concept LLMs already recognize from Go/Zig/Swift, and it co-locates teardown with the resource it pairs with — exactly the structure that makes generated tests correct on first try. Module-level setup/teardown (C) and Fixture traits (D) require non-local control flow and lifecycle ordering, a known LLM failure mode.

`defer` is a new compiler intrinsic. Filed as a separate `type:feature` ticket; this decision records the panel's preference but does not implement.

---

**Q2: Table-driven / parameterized tests (5-0 for `for_each` library helper)**

Options: A — nothing, loop in test. B — `testing.for_each(cases, fn(case) { ... })`. C — compiler `test "name" for case in cases { ... }`. D — `@cases([...])` annotation.

- **Systems:** B. A library helper iterating a `List` is what users would write by hand — zero new compiler machinery, predictable codegen (a loop calling a closure). C and D add parser/typecheck surface for a 10-line library function.
- **Web/Scripting:** B. Reads like ordinary Blink, matches what Python (pytest.parametrize-via-fixtures), JS (`test.each`), and Kotlin (`forAll`) developers already know. Compiler syntax for table tests is overkill; annotation-driven (D) requires literal-only case lists and falls over the moment cases are computed.
- **PLT:** B. A higher-order `for_each(cases, fn(case) { ... })` is a pure library function — fully compositional, trivially type-checked via existing function/closure machinery. New surface syntax (C) and annotations (D) add parser complexity for zero expressive gain over an HOF.
- **DevOps:** B. One `test` block = one test name keeps the runner's mental model simple; sub-cases get derived names from the explicit label. Compiler syntax bloats the language for something trivially expressible as a function call, and makes `--json` output and LSP "run test at cursor" codelens harder to implement (now there are N invisible tests behind one source span).
- **AI/ML:** B. Most token-efficient and discoverable form — just a function call, the case type is whatever the user wants, failure naming falls out of the explicit label. Compiler syntax adds surface area LLMs must learn from spec rather than transfer from existing closure/iteration knowledge. Loop-inside-one-test (A) collapses N failures into 1, which destroys the signal that makes table tests valuable.

Multiple panelists flagged that auto-generating sub-test names from `Display` of the case risks collisions; the spec uses `(label, value)` pairs to make case identifiers explicit and deterministic.

---

**Q3: Snapshot testing in stdlib (5-0 against)**

Options: A — not in stdlib. B — `testing.assert_snapshot` library. C — compiler intrinsic.

- **Systems:** A. Snapshot testing is policy, not mechanism — needs filesystem layout conventions, diff renderers, update flags, CI ergonomics. None of that belongs in stdlib, let alone the compiler. Userland packages can iterate without locking the language to a `__snapshots__/` convention forever.
- **Web/Scripting:** A. Snapshot testing is opinionated and divisive — Jest users love it, half the Python world hates it, and the file-format/diff-UX bikeshed eats months. Userland keeps stdlib lean and lets the community pick winners.
- **PLT:** A. Snapshot testing is fundamentally a workflow concern (file management, golden updates, diffing) tangled with serialization choices — none of which belong in stdlib at this stage. Putting it in std.testing commits the language to a `Serialize` story before that's designed.
- **DevOps:** A. Huge diagnostic surface — diff rendering, update workflows, CI-vs-local divergence, merge conflicts in `__snapshots__/` — and getting it wrong is worse than not having it. Stdlib inclusion commits the toolchain to maintaining a golden-file format and a `--update-snapshots` flag forever; that's a Jest-tier maintenance burden for a young language.
- **AI/ML:** A. Too many policy decisions (where files live, when to update, how to diff, binary vs text, ANSI stripping, redaction) for stdlib to bake in without painting the language into a corner. The four built-in assertions plus power-assert already cover the common-case "is the value what I expect" without snapshots.

Multiple panelists noted ecosystem fragmentation risk; the spec records the recommended pattern (small goldens via `assert_eq` against a `pub const`; large/structured outputs via an ecosystem package).

---

**Q4 — Round 1: Richer matchers (3-2 for "none", but contradicted by dissent on every vote)**

Options: A — none. B — `assert_close` for floats only. C — full matcher library.

Round 1 result was A (3-2), but every Round 1 voter — including all three majority voters — explicitly flagged float comparison as a genuine correctness trap. AI/ML additionally flagged `assert_panics` as the only other case genuinely awkward without compiler support. The panel reconvened in a live debate.

**Q4 — Round 2: live debate (5-0 for `assert_close` + `assert_close_rel` library pair)**

The Round 2 debate produced four distinct shape proposals before converging:

- **Free function pair (sys, web, plt initial position):** `fn assert_close(actual, expected, tol)` and `fn assert_close_rel(actual, expected, rel_tol)` as plain library functions. Two functions instead of one with kwargs because absolute and relative tolerance are different equivalence relations and conflating them with "smart" predicates hides which one failed.
- **Compiler built-in (devops initial position):** `assert_close` as a compiler intrinsic so power-assert can produce structured introspection on `actual`/`expected`/`|diff|`/`tol`/`mode`. Argued that a library `fn` body would only be able to `panic` with a stringified message.
- **Method on Float (aiml initial position):** `Float.close_to(other, eps)` and `Float.close_to_rel(other, rel)` as predicate methods, used via `assert(x.close_to(y, eps))`. Argued that two free-function names create LLM hallucination surface.
- **Hybrid library-fn delegating to `assert` (devops's R2 counter, accepted by all):** library `fn` whose body is `assert((actual - expected).abs() <= tol)` so power-assert decomposes the *inner* assert at the matcher's call site. Same structured diagnostic as a built-in, no compiler change.

**Convergence:** the hybrid resolved the matcher-vs-method debate. The library `fn` form owns its diagnostic at the assertion site (sys's critique of the method form: `assert(x.close_to(y, eps))` prints only `false`); the underlying `Float.close_to` / `Float.close_to_rel` methods exist as primitives for non-test use (aiml's reusability win). Power-assert's existing one-level decomposition (§2.20) renders the failure without new compiler machinery (devops's diagnostic-surface win).

- **Systems:** Adopted hybrid. "Power-assert on the inner `assert` shows operands of `(a-e).abs()`, the LHS, the RHS, and `tol`/`rel*scale`. That's exactly the diagnostic devops wanted, with zero compiler surface area." Hard line: no default tolerance. "Defaults on float tolerance are exactly the trap — they encode an absolute scale that's wrong for values near `1e-12` and pointlessly tight for values near `1e9`."
- **Web/Scripting:** Conceded the default — "annoyingly, sys is right. `1e-9` is meaningless without knowing the magnitude." Final shape: library pair, NaN fails, Inf fails unless both equal Inf with same sign, tolerance required, no default.
- **PLT:** "Tolerance is domain-specific; force the caller to write it. 'Matches pytest' is not an argument; pytest got it wrong by inheriting Python's keyword-arg culture. No defaults." NaN policy: `assert_close(NaN, NaN, _)` must fail. "NaN ≠ NaN is the IEEE invariant; if you want NaN-equality, use `assert(x.is_nan())`."
- **DevOps:** Withdrew compiler built-in demand on the strength of the hybrid. Hard ship gate: "before this ships, the test suite must include a golden-output test showing the actual power-assert rendering on a failed `assert_close`. If the rendering is just 'assertion failed', we have a regression dressed as a feature."
- **AI/ML:** *(initial dissent on form, later converged)*. Initial position: method on Float. Conceded after sys's critique: "`assert(x.close_to(y, eps))` failing with `false` and three opaque operands is genuinely worse for an LLM iterating against a red test than a message that says `|diff|=1e-6, tol=1e-9`. Debuggability is one of my core axes; I have to weigh it." Final vote: hybrid library pair, with `Float.close_to` methods existing as primitives.

**Rejected by 5-0:** generic `assert_lt` / `assert_gt` / `assert_le` / `assert_ge`. Power-assert on `assert(a < b)` already prints both operands.

---

**Q4 — `assert_panics` follow-up (5-0 to defer)**

Initial proposals split four ways: tests-only intrinsic `__blink_test_catch` (sys), block form `assert_panics { ... }` (aiml), library `assert_panics` backed by general `catch_panic[T](f) -> Result[T, PanicInfo]` primitive (devops), defer entirely (web, plt).

- **Systems:** Initially proposed the tests-only intrinsic; later conceded. "plt and web are right. 'Tests-only intrinsic' is a fiction; once it's in the compiler, it leaks. And panic-recovery genuinely is a language design question (intrinsic vs effect vs Result), not a matcher question."
- **Web/Scripting:** "Hard no on the intrinsic. 'Tests-only intrinsic' is a fiction — once it's in the compiler, someone will reach for it from non-test code within six months. Either panic is divergence everywhere, or it isn't. Pick one." `pytest.raises` shows up in 5% of tests; not the brief.
- **PLT:** "A 'test-only intrinsic' is exactly the kind of locally-convenient, globally-corrosive design move I'm here to block. `panic: Never` means *no continuation exists*. `__blink_test_catch` punches a hole in that. 'Only legal inside std.testing' isn't a real restriction — every stdlib-privilege escape hatch I've seen in other languages eventually leaks (Rust's `#[lang]` items, OCaml's `Obj.magic`, Haskell's `unsafePerformIO` in `base`)."
- **DevOps:** Initially proposed `catch_panic[T](f) -> Result[T, PanicInfo]` as a general primitive ("test runner needs it anyway for isolation"); later conceded. PLT's response: "If `catch_panic` exists as a general primitive, `panic` is no longer divergence — it's a recoverable effect, and the type system needs to reflect that. 'Test runner needs it for isolation' is a *process-level* concern (fork, signal handler, longjmp at the runtime boundary) — not a language-level primitive exposed to user code."
- **AI/ML:** Initially proposed the block form; later switched to sys's intrinsic; conceded fully when sys dropped his own proposal. "sys's tests-only intrinsic is clever but creates a 'magic module' precedent we'll regret."

Filed as a separate `type:spec` ticket on recoverable-panic semantics.

---

### Final Spec

```blink
// std.testing — library helpers, no new compiler intrinsics

pub fn assert_close(actual: Float, expected: Float, tol: Float)
pub fn assert_close_rel(actual: Float, expected: Float, rel_tol: Float)

pub fn for_each[T](cases: List[(Str, T)], body: fn(T) -> Unit)
```

- Tolerance is required on both float helpers; no default.
- NaN in either argument fails the assertion. `+Inf`/`-Inf` accepted only when both arguments are the same infinity.
- Bodies delegate to the existing `assert(...)` built-in so power-assert (§2.20) renders failures.
- `Float.close_to(other, eps) -> Bool` and `Float.close_to_rel(other, rel) -> Bool` exist as primitive predicates for non-test use.
- `for_each` cases are `(label, value)` pairs; label appears in failure messages for unambiguous attribution.
- Snapshots, fixtures, sub-tests, and panic capture are not in `std.testing` — see follow-up tickets.

### AI-First Review

Scored against the five criteria:

1. **Learnability** — Pass. Both helpers extend the `assert_*` family already established in §2.20. `for_each` is a higher-order function in a language that already uses HOFs everywhere.
2. **Consistency** — Pass. Naming (`assert_close`, `assert_close_rel`) matches `assert_eq`/`assert_ne`/`assert_matches`. `for_each` mirrors existing list iteration patterns.
3. **Generability** — Pass. Single signature per helper, no overloads, no kwargs. The required-tolerance contract is enforced by the type system, not by convention.
4. **Debuggability** — Pass. Failures route through power-assert at the inner `assert(...)` site, producing structured introspection of `(actual - expected).abs()`, `tol`, and the operands.
5. **Token efficiency** — Pass. Two-token cost for the explicit `for_each` label is the price of unambiguous CI failure attribution; no defaults eliminate magnitude-blind float-tolerance footguns.

0 fails — proceed.
