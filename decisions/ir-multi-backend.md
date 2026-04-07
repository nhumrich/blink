[< All Decisions](../DECISIONS.md)

# IR Layer & Multi-Backend Codegen — Design Rationale

### Problem Statement

Blink's codegen is tightly coupled to C emission — 17K+ lines across 7 files, all producing raw C strings via `emit_line()`. No intermediate representation exists between the typechecked AST and C text output. Should Blink introduce an IR layer to enable multiple backend targets (JavaScript, Python, Go, WASM), positioning it as a "universal application language"?

### Questions

Three questions were deliberated:
1. Should Blink add an IR layer for multi-backend codegen?
2. If/when an IR is added, what migration strategy?
3. Which non-C backend should be prioritized first?

---

### Q1: Should Blink add an IR layer?

**Options:**
- **A: Yes, high-level IR** — Preserves Blink-level semantics (closures, effects, async as first-class). Each backend lowers idiomatically.
- **B: Yes, low-level IR** — Close to C/LLVM level (structs, function pointers, linear memory). Uniform but unidiomatic output for non-C targets.
- **C: No, keep C-only** — C backend is sufficient. WASM via emscripten.
- **D: Defer to post-v1** — Good idea but wrong time. Ship v1 with C, revisit after language stabilizes.

**Decision: D — Defer to post-v1 (4-1, PLT dissented with A)**

Panel reasoning: The language is still evolving (new features landing regularly). Inserting an IR into 17K lines of self-hosting codegen before v1 means every new feature requires IR design *and* backend lowering for targets nobody is using yet. The self-hosting fixed-point verification becomes a moving target. Ship v1 on C, get real adoption, then build the IR informed by actual needs.

- **Systems:** Introducing IR doubles the codegen surface area for bugs while the language is still in flux. WASM already reachable via `CC=emcc`. *(dissent: consciously keep codegen separable from C syntax to ease future extraction)*
- **Web/DX:** Multi-backend is exciting but Blink has no users yet. IR is a DX tax on contributors, not a DX win for users, until the language stabilizes.
- **PLT:** *A (dissent).* The codegen interleaves semantic lowering and C emission — a high-level IR is the natural separation point. It should preserve effect/closure/async semantics so backends can lower idiomatically. Concern: the IR must be *smaller* than the surface AST, not a mirror. *(dissent)*
- **DevOps:** Current `--emit c` and `--blink-trace codegen` debugging workflows are well-understood. An IR needs its own inspection tooling before it delivers value.
- **AI/ML:** One language, one backend, one compilation model = tight generate-compile-check-fix loop. IR before v1 doubles the verification surface for compiler bugs — the hardest class of errors for AI to diagnose.

**Key argument:** The self-hosting bootstrap chain is fragile and the language is pre-v1. An IR refactor now would slow feature development for a benefit that only materializes once semantics are frozen.

**PLT dissent:** The *right time* for an IR is when the codegen first gets structured — retrofitting it later is always harder. A high-level IR that preserves effect/closure semantics is the principled separation between "what Blink means" and "how C expresses it." Every day without it, more C-specific assumptions calcify.

**Mitigation for deferral risk:** Consciously keep codegen logic separable from C syntax emission even without a formal IR. When adding features, structure codegen as "compute what to emit" then "emit it as C" rather than interleaving the two.

---

### Q2: When IR is added, what migration strategy?

**Options:**
- **A: Clean-room IR insertion, refactor C backend to emit from IR** — Clean but risky for bootstrap.
- **B: Incremental — IR that trivially re-emits same C first, then gradually enrich** — Safe but slow.
- **C: Emscripten shortcut first** — Compile existing C output through emscripten/wasi-sdk for WASM. Buys time.

**Decision: B — Incremental (4-1, Systems dissented with C)**

- **Systems:** *C (dissent).* Emscripten is zero-risk and delivers a real WASM target today. It validates whether Blink programs actually work in WASM before designing an IR abstractly.
- **Web/DX:** Incremental is the only sane migration for a self-hosting compiler. Verify via C output diffing — exactly like the current regen protocol.
- **PLT:** Insert IR as thin layer, verify byte-identical C output, then gradually enrich. This is the 3-step refactoring protocol already documented. The IR is "real" when the C backend no longer inspects original AST nodes.
- **DevOps:** Even trivial IR touches every `emit_line()` call site. Strict milestone gates needed: trivial IR must produce byte-identical C before any enrichment.
- **AI/ML:** Incremental preserves AI-debuggability. Existing error messages, trace output, and `--emit c` remain valid through the transition.

**Systems dissent:** Emscripten is a pragmatic shortcut that surfaces real WASM problems (GC in linear memory, green thread Asyncify overhead) without any compiler changes. This empirical data should inform IR design rather than designing in the abstract.

---

### Q3: Which non-C backend first?

**Options:**
- **A: WASM** — Browser + edge deployment, closest memory model to C.
- **B: JavaScript** — Largest ecosystem reach.
- **C: Go** — Similar runtime model (GC, goroutines).
- **D: None yet** — Stabilize IR with C-only backend first.

**Decision: A — WASM first (4-1, PLT dissented with D)**

- **Systems:** WASM preserves the performance contract. JS/Python would be orders of magnitude slower for compute. WASM shares C's linear memory model.
- **Web/DX:** WASM unlocks browser demos, playground, edge deployment — critical for new-language adoption. JS target would fight host runtime semantics.
- **PLT:** *D (dissent).* Stabilize IR against C first. The first non-C backend permanently influences IR design. Rushing to WASM before IR semantics are settled means co-evolving IR and lowering simultaneously.
- **DevOps:** WASM unlocks genuinely new deployment surfaces. Has well-defined validation semantics (`wasm-validate` in CI). JS/Go backends would increase CI complexity.
- **AI/ML:** WASM runs everywhere without language-specific runtime. Linear memory model lets AI transfer existing mental model of how Blink compiles.

**PLT dissent:** Set a concrete stability criterion first: the IR is stable when adding a new language feature requires only IR node additions (not restructuring). Then proceed to WASM.

**Runtime concern (all experts):** The hard part is not instruction emission — it's the runtime. Blink depends on Boehm GC, platform fibers (ucontext), and libc. None have clean WASM equivalents. WasmGC proposal is still maturing. This is the real risk regardless of IR design.

---

### Summary

| Question | Decision | Vote | Dissent |
|----------|----------|------|---------|
| IR layer timing | Defer to post-v1 | 4-1 | PLT: should start now with high-level IR |
| Migration strategy | Incremental (trivial IR → enrich) | 4-1 | Systems: emscripten shortcut first |
| First non-C backend | WASM | 4-1 | PLT: stabilize IR before any backend |

### Recommended Roadmap

1. **Now (pre-v1):** Keep codegen separable — "compute then emit" discipline. Use emscripten for experimental WASM.
2. **Post-v1:** Introduce incremental IR (trivial C re-emission, verify fixed-point).
3. **IR stable:** Add WASM backend as first non-C target.
4. **Future:** JS, Python, Go backends as demand warrants.

### AI-First Review

| Criterion | Pass/Fail |
|-----------|-----------|
| Learnability | Pass — no new concepts for AI to learn |
| Consistency | Pass — no change to existing patterns |
| Generability | Pass — no impact on code generation |
| Debuggability | Pass — existing workflows unchanged |
| Token Efficiency | Pass — no additional token cost |

All 5 criteria pass. Decision stands.
