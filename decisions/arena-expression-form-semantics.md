[< All Decisions](../DECISIONS.md)

# Arena Expression-Form Semantics — Design Rationale

### Problem Statement

The original arena deliberation ([arena-allocation-semantics.md](arena-allocation-semantics.md))
fixed promotion walkers (D1), escape rules (D2), handler plumbing (D3), and
nesting (D4). Six semantic questions about the expression-form behavior of
`with arena { expr }` were deferred and now block heap-promotion codegen
wiring (task `dvpq88`):

1. Tail-return semantics of `with arena { expr }`.
2. Early `return` / `?` inside `with arena { }`.
3. Handler composition order for `with h1, arena, h2 { body }`.
4. How the outer promotion target is threaded into nested arenas.
5. Whether `with arena { }` discharges `! Arena` on the enclosing function.
6. RAII ordering for `with arena, file = open(...) as file { body }`.

This deliberation resolves all six so implementation can proceed against one
consistent spec.

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted
independently on each question.

---

**Q1. Tail-return semantics.**

**Result: A — trailing expression is the block's value, promoted at `}` (5-0).**

Options considered:
- **A:** `with arena { body }` evaluates to `body`'s tail expression,
  deep-copied via `blink_promote_<T>` at the closing `}`. Tail position
  propagates through `if`/`match` arms.
- **B:** Statement-only; values extracted via a pre-block `outvar` binding.
- **C:** Explicit `return expr` required inside the block.

Votes:
- **Systems:** A. The walker runs exactly once, at a syntactically obvious
  point. B needs an out-parameter calling convention just for arenas — a
  special case that poisons every codegen decision downstream. C forces
  early-return machinery onto the common path.
- **Web:** A. `let x = with arena { f() }` is the shortest form a user can
  write and matches Rust/Kotlin/OCaml priors. B is a teaching disaster —
  "arena blocks don't return values like other blocks" is a foot-gun users
  will hit within five minutes.
- **PLT:** A. Block-expression semantics preserve subject reduction: the
  expression `with arena { e }` has the same type as `e`. B breaks the
  uniformity of the expression language; C conflates control-flow with
  result-extraction.
- **DevOps:** A. One promotion point per block = one span for diagnostics.
  B scatters promotions across assignment sites.
- **AI/ML:** A. Aligns with the strongest training signal (Rust/Kotlin block
  expressions). B/C introduce novelty with no matching corpus.

---

**Q2. Early return and `?`.**

**Result: A — promote into nearest enclosing arena (else caller target else GC), then `exit(false)`, then propagate (5-0).**

Options considered:
- **A:** `return expr` / `expr?` inside `with arena { }` promotes `expr`
  into the same target the tail expression would resolve to at that program
  point, runs `arena.exit(false)`, then propagates.
- **B:** `return`/`?` skip promotion; callers of an `! Arena` function that
  returns early get a dangling pointer. (Unsound.)
- **C:** `return`/`?` forbidden inside `with arena { }`.

Votes:
- **Systems:** A. The tail-position predicate (Q1) must be the single source
  of truth reused by the tail-expression path, `return`, and `?`. Two
  implementations = subject reduction bugs. B is unsound. C cripples the
  feature.
- **Web:** A. Users already reach for `?` more than any other control-flow
  construct. Forbidding it inside arenas would be an onboarding cliff.
- **PLT:** A. Subject reduction demands that early and tail exits have the
  same semantics with respect to region closure. B violates type safety.
- **DevOps:** A. Error-flow path matches happy-path — diagnostics stay
  consistent.
- **AI/ML:** A. Models expect `?` to propagate everywhere; carving out an
  exception would produce mysteriously-broken generations.

---

**Q3. Handler composition order.**

**Result: A — L-to-R enter, R-to-L exit; promotion inside `arena.exit()` against the snapshot (5-0).**

Options considered:
- **A:** Standard LIFO `BlockHandler` ordering. Promotion happens *inside*
  `arena.exit()` against the TLS snapshot captured at `arena.enter()`.
  Handlers right of `arena` run `exit` *before* promotion (see
  pre-promotion state); handlers left run `exit` *after* (see post).
- **B:** Promote before any handler's `exit`, regardless of position.
- **C:** Promote after all handlers' `exit`.

Votes:
- **Systems:** A. Matches existing `BlockHandler` contract (§4.6.3). Any
  other ordering requires a second handler protocol just for arenas.
- **Web:** A. Positional composition is the only rule a user can predict
  without reading the compiler — "position in `with` clause = position in
  teardown timeline."
- **PLT:** A. Preserves the algebraic identity for handler composition:
  `with h1, h2 { e }` and `with h1 { with h2 { e } }` are observationally
  equivalent. B and C break this for arena.
- **DevOps:** A. Traces render as a clean LIFO timeline. Requires a
  canonical timeline example in `blink llms --topic arena` — users will not
  derive this correctly from prose alone.
- **AI/ML:** A. One rule (LIFO) generalizes across all handler kinds.

---

**Q4. Outer target threading.**

**Result: A — TLS snapshot captured at `arena.enter()` into the BlockHandler restore struct (5-0).**

Options considered:
- **A:** `arena.enter()` reads `__blink_current_arena` once, stores it in
  its own restore struct, and passes it to `blink_promote_<T>` at exit.
- **B:** Separate TLS slot for "outer promotion target."
- **C:** Walk the BlockHandler stack at promotion time.

Votes:
- **Systems:** A. One TLS read at `enter`, one struct field at `exit`.
  B doubles TLS pressure for no benefit. C is an O(depth) stack walk on
  every `}`.
- **Web:** A. Already matches how other BlockHandlers capture prior state
  (transactions, locks). No new mechanism.
- **PLT:** A. The snapshot is the natural representation of "outer region
  at this point." B introduces a parallel state that can desynchronize.
- **DevOps:** A. Debug output reads `handler.snapshot_target` as one field
  — trivially printable.
- **AI/ML:** A. Uniform with other handler patterns in the codebase.

---

**Q5. `! Arena` escape boundary.**

**Result: A (outcome) with PLT's C framing — `with arena { }` is the escape boundary (4-1, PLT dissent on framing, adopted).**

Options considered:
- **A:** `with arena { }` "discharges" `! Arena`: an `! Arena` callee
  inside the block does not force `! Arena` on the enclosing function.
- **B:** `! Arena` always propagates; `with arena { }` does not affect
  signatures.
- **C:** `with arena { }` is the escape boundary for the `! Arena` marker
  effect — escape analysis stops at the block, not a discharge mechanism.

Votes:
- **Systems:** A. Observationally correct: the arena block bounds the
  region where arena allocations are observable.
- **Web:** A. Signature hygiene — users don't want `! Arena` to climb
  transitively through their call graph.
- **PLT:** *(dissent)* C. D3 already locked in "`! Arena` is a marker
  effect consumed by escape analysis, not an algebraic effect with
  evidence-passing dispatch." Using "discharge" vocabulary risks future
  contributors wiring handler-evidence plumbing that doesn't exist.
  Observationally identical to A; the *framing* matters.
- **DevOps:** A. Diagnostic surface — "remove `! Arena` because it's
  contained in a `with arena` block" is writable as an error message.
- **AI/ML:** A. Same behavior users expect from borrow-checker-style region
  containment.

Spec adopts PLT's **C framing** with A's **outcome**: the spec calls the
block an "escape boundary" rather than a "discharge point." Behavior is
identical; wording preserves the D3 invariant.

---

**Q6. RAII resources inside arena block.**

**Result: A — body → promote(tail) → LIFO cleanup of non-arena resources → `arena.exit()` (5-0).**

Options considered:
- **A:** `body` runs with all resources live, tail is promoted while
  resources still live, then LIFO cleanup of non-arena Closeables, then
  `arena.exit()`.
- **B:** Close all Closeables before promotion.
- **C:** Destroy arena before closing Closeables.

Votes:
- **Systems:** A. Promotion may read through resource-backed buffers (e.g.,
  a value computed from a file's mapped region). B prematurely closes the
  source of truth. C leaves dangling arena pointers in Closeable destructors.
- **Web:** A. Matches the mental model "resources live for the block,
  including while the block is producing its value."
- **PLT:** A. Tail expression must be evaluated while all bindings in scope
  are live. But tail values that *retain* references into a Closeable's
  buffers must be rejected (E0700) — the promoted value is about to outlive
  the resource.
- **DevOps:** A. Diagnostic: E0700 must span both the capturing expression
  and the `as file` binding. Without that, the error is unfindable.
- **AI/ML:** A. Parallels Python `with` semantics; no novel rule to learn.

### AI-First Review

| Criterion | Pass/Fail | Note |
|-----------|-----------|------|
| Learnability | ✅ Pass | A-across-board aligns with Rust/Kotlin/Python priors; one worked example covers the composition subtlety. |
| Consistency | ✅ Pass | Reuses BlockHandler, `with…as`, leftmost-wins composition — no new syntax. |
| Generability | ✅ Pass | `let x = with arena { f() }` is the shortest common form. |
| Debuggability | ⚠️ Borderline | "Promote inside `arena.exit()`" is an invisible step at `}`; needs `--blink-trace codegen` to emit a spanned event. Tooling concern, not spec-level. |
| Token Efficiency | ✅ Pass | No ceremony added. |

Fails: 0-1. Proceed. Debuggability is an implementation constraint on tracing infrastructure, not a spec redesign.

### Concerns & Follow-ups

1. **Single tail-position predicate** (Q1, Q2, Q6): implement ONE function
   consumed by escape analysis and codegen. Two implementations = subject
   reduction bugs.
2. **Marker-effect hygiene** (Q5, D3): `! Arena` MUST NOT participate in
   evidence-passing codegen. Assert in `--debug` builds.
3. **Trace event for promotion** (debuggability): emit a spanned event
   with stable name `arena.promote` in `--blink-trace codegen` and
   `--trace all` so users can locate invisible promotion points.
4. **Diagnostic content** (web, devops): E0700 must print the resolved
   promotion target (`promoted into: outer arena at <span>` or
   `promoted into: GC heap`). Without this, nested-arena debugging is blind.
5. **Tail captures Closeable** (Q6 PLT): classify as E0700 with a span
   pointing at both the capturing expression and the `as file` binding.
6. **Canonical timeline example** (Q3 PLT): `blink llms --topic arena`
   must include the step-by-step execution order for
   `with h1, arena, h2 { body }`.
7. **No `redundant ! Arena` auto-fix yet** (devops Q5): lint warning when
   `! Arena` is on a function whose `! Arena` sites are all inside a
   `with arena { }` — candidate follow-up task.
8. **Coroutine / resumable continuation precondition**: if Blink ever adds
   resumable continuations that can suspend inside `with arena`, the TLS
   snapshot becomes stale. Documented as a future precondition.
