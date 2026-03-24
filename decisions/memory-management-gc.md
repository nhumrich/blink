[< All Decisions](../DECISIONS.md)

# Memory Management: Boehm GC — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) proposed solutions independently. All five converged on the same answer: Boehm-Demers-Weiser conservative tracing GC as a drop-in replacement for `malloc`.

**Q1: What memory management implementation should the C backend use? (5-0 for Boehm GC)**

- **Systems:** Boehm GC. Conservative tracing via `GC_MALLOC` replacing `malloc`. ~15 lines changed. Cross-language validation: Guile, Nim, D all use Boehm for C-emitting backends. `GC_MALLOC_ATOMIC` for leaf allocations (strings, byte buffers) as optimization. Custom precise GC is 10K-50K lines — not justified when Boehm works.
- **Web/Scripting:** Boehm Drop-In. "It's boring, it's proven, it's 5 lines of real change." Matches JS/Python developer expectations (allocate, stop using it, it goes away). Crystal lang is the closest analogue — compiles to native, uses Boehm, production-proven.
- **PLT:** Boehm-First with Static Reuse Analysis. Boehm now, Perceus-inspired deterministic frees later as optimization. Key insight: Blink's shared-reference closure captures (voted 3-2 in closure semantics deliberation) create cycles that pure refcounting cannot handle without a cycle detector — and a cycle detector is just a worse tracing GC. Tracing GC is the theoretically sound choice.
- **DevOps:** Boehm Bridge. Focus on operational instrumentation: `GC_get_heap_size()` for monitoring, `GC_set_start_callback()` for pause visibility, `GC_set_find_leak(1)` for debugging. Non-comblinking collector means valgrind/ASan/gdb all work unchanged. Every successful LSP daemon (gopls, tsserver, merlin) uses tracing GC.
- **AI/ML:** Boehm GC. Zero imblink on AI-generated code (memory management is invisible). Matches the memory model of every GC'd language in LLM training data (JS, Python, Go, Java). No new concepts for users or AI to learn.

### Why Not Reference Counting

Multiple experts independently identified the same fatal flaw: Blink's shared-reference closure captures (§2.8, voted 3-2) create reference cycles. Two closures capturing the same mutable cell form a cycle through their capture arrays. Pure reference counting (Swift ARC, Koka Perceus) either leaks cycles silently or requires a backup cycle detector — which is effectively a tracing GC with extra steps.

Koka's Perceus works because Koka uses value semantics with linear/affine types — closures don't share. Blink explicitly chose shared references. The consequence is that tracing GC is required for soundness.

### Why Not Custom Precise GC

A production-quality precise tracing GC requires:
- Stack maps (knowing which stack slots contain pointers)
- Write barriers (for generational collection)
- Precise type layout descriptors for every allocation
- 10K-50K lines of carefully hardened C

Blink's C backend erases type information (everything is `void*`), making precise scanning difficult without shadow stacks or generated layout tables. Boehm's conservative approach works precisely because it doesn't need this information.

A custom GC can replace Boehm later behind the `blink_alloc` abstraction if pause times become a measured bottleneck.

### Implementation Summary

**Changes required (~15 lines across 2-3 files):**
1. `runtime_core.h`: Replace `malloc` with `GC_MALLOC` in `blink_alloc`. Add `#include <gc.h>`.
2. Codegen: Add `GC_INIT()` call in generated `main()`.
3. Build system: Add `-lgc` to cc invocation.
4. Optional: `GC_MALLOC_ATOMIC` for string/byte allocations (no-pointer optimization).

**What doesn't change:** All generated C code structure. All codegen logic. All Blink source code. The bootstrap protocol.

**External dependency:** `libgc` (BSD-licensed, available in every Linux distro, Homebrew, vcpkg). In production since 1988. Used by Mono, GCJ, Guile, Crystal, Inkscape.

### Migration Path

```
Phase 1: Boehm drop-in          → fixes 93GB leak, ~15 lines
Phase 2: Static reuse analysis   → compiler inserts deterministic frees where provably safe
Phase 3: Custom precise GC       → if/when Boehm's pause times become a measured bottleneck
```
