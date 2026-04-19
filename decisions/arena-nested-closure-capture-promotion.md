[< All Decisions](../DECISIONS.md)

# Arena Nested Closure Capture Promotion — Design Rationale

### Problem Statement

The closure-typed tail of `with arena { expr }` is rejected with diagnostic
`E0702c ArenaClosureNestedCapture` when any of its captures is itself a
closure. The residual test in
`tests/test_with_arena_closure_tail.bl` pins the carve-out:

```blink
fn main() {
    let inner = fn(x: Int) -> Int { x * 2 }
    let g = with arena {
        fn(x: Int) -> Int { inner(x) + 1 }
    }
    let _ = g
}
```

Arena promotion walks every capture and deep-copies it into the outer
allocator (`emit_closure_tail_promotion` at `src/codegen_stmt.bl:2443`). For
primitive, struct, list, map, and `let mut` captures the compiler knows the
layout and emits a per-type walker via `queue_promote_type`
(`src/codegen_derive.bl:698`). For a closure capture, the descriptor
collapses to `"C:Closure"` — a `blink_closure*` whose signature is not
recoverable from runtime state, so the compiler cannot emit a recursive
promoter.

This is the closure-ABI change k107d2 flagged as the more invasive option
and deferred. It is the last residual carve-out in the arena closure-tail
promotion family (E0702a/b/c/d).

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted
independently.

Options considered:
- **A:** Typed capture slots — extend the `blink_closure` ABI with a
  per-capture type descriptor table parallel to `void** captures`.
  Promotion iterates the descriptor table and dispatches to
  `blink_promote_<T>` per slot; closure-typed captures carry a pointer to
  their own descriptor table so promotion recurses structurally.
- **B:** Runtime signature tag on `blink_closure` — promoter looks up the
  capture layout at runtime by tag.
- **C:** Compile-time capture-origin resolver — mini escape analysis in
  codegen reconstructs the signature of each closure capture from the
  surrounding source.

Votes:
- **Systems:** *(dissent)* C. Zero runtime cost; the typechecker already
  holds the signature. Don't inflate closure records for info we can
  monomorphize at the call-site.
- **Web:** A. The naive "compose callables in an arena" pattern must just
  work. Option C generates Stack Overflow posts — users hit "why does this
  one carve-out exist" and never form a mental model.
- **PLT:** A. Subject reduction and compositionality: if `with arena { e }`
  has type `e`, promotion must be total on closure-typed tails. C is a
  soundness wart dressed as a diagnostic.
- **DevOps:** *(dissent)* C. Writable diagnostic with spans; A has no
  user-facing error code to self-correct against, and miscompiles surface
  as runtime garbage rather than a compile error.
- **AI/ML:** A. Context-sensitive rules fire inside `with arena { }` only —
  exactly the class LLMs get wrong most often. A has zero new rules to
  learn.

**Result: Option A wins 3–2** (Web/PLT/AI for A; Systems/DevOps for C).

### Key Swing Argument

PLT's compositionality framing: the prior arena decision
([arena-expression-form-semantics.md](arena-expression-form-semantics.md),
Q1) locked in that `with arena { e }` has the same type as `e`. Refusing
to promote a well-typed closure value through that region boundary is a
type-system carve-out, not a diagnostic. AI/ML reinforced from the other
side: a spatially-scoped rule ("only inside `with arena { }`") is exactly
the category LLMs regenerate wrong each time.

### AI-First Review

| Criterion | Pass/Fail | Note |
|-----------|-----------|------|
| Learnability | ✅ Pass | No new rule; closures "just work" in `with arena { }`. Matches OCaml/Go/Rust priors. |
| Consistency | ✅ Pass | Mirrors the per-type promoter pattern used for List/Map/Struct. |
| Generability | ✅ Pass | LLM generating "composed callable in an arena" gets the naive MVCE right. |
| Debuggability | ⚠️ Borderline | No user-facing error code to self-correct against. Mitigation: `--blink-trace codegen` must emit a spanned `arena.promote.capture` event per capture slot (ties into ticket r90br2). |
| Token Efficiency | ✅ Pass | Zero new syntax. |

Fails: 0. Proceed.

### Concerns & Follow-ups

1. **Closure ABI migration.** Every closure allocation site touches the
   new descriptor slot. Gated on `task regen` fixed-point. Must land as a
   3-step self-hosting migration (add descriptor alongside → migrate
   compiler sources → remove the old path).
2. **`--blink-trace codegen`.** Emit spanned `arena.promote.capture`
   events so debuggers can locate per-slot promotions. Satisfies DevOps
   dissent's "diagnostic black hole" concern.
3. **Future parametric closure polymorphism.** If Blink later allows
   closures to cross generic boundaries, the descriptor table must become
   generic-aware. Design the descriptor encoding so polymorphism can slot
   in without an ABI rebreak.
4. **Closure-capture origin resolver is redundant.** Option C would have
   required a mini escape analysis inside codegen. Option A obsoletes
   that work — do not reintroduce it in follow-ups.
