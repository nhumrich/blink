[< All Decisions](../DECISIONS.md)

# Long-Term Stdlib Tier Architecture — Design Rationale

### Panel Deliberation

Five panelists voted independently on the long-term stdlib packaging model. The question: should Blink maintain a tier-2 concept (independently versioned `std.*` packages) or commit to a single-tier stdlib?

**Background:** A prior vote (4-1) collapsed tier-2 into tier-1 for the pre-registry era. This vote determines whether tier-2 should *ever* return, or whether a simpler model is better long-term.

**Q1: Long-term stdlib tier architecture (3-2 for A: batteries included)**

- **Systems (B — Small Core + Ecosystem):** Stdlib should be a thin foundation. HTTP/DB/logging should compete on merit in the ecosystem. Go's `net/http` stagnation shows what happens when opinionated modules get locked into stdlib. Blink compiles to C — the ecosystem can leverage C libraries directly.
- **Web/Scripting (C — Semi-Stdlib):** The `std.http` import path is golden for discoverability. Deno's trajectory (started batteries-included, moved to independently-versioned std) is instructive. Blessed packages with independent versioning gives you both stability and evolution. *(dissent)*
- **PLT (C — Semi-Stdlib):** Blink's effect system creates a natural semantic boundary — effect types are compiler-known and must be version-locked, while convenience layers above them are just libraries. Option C respects this distinction. Versioning the kernel with the sugar is a category error. *(dissent)*
- **DevOps (A — Batteries Included):** Single resolution path. `blink --version` reproduces everything. Fast point releases solve the "can't ship a fix" problem. Premature separation is harder to undo than premature bundling. Zig's model (everything ships together) is the right reference for a young language.
- **AI/ML (A — Batteries Included):** Fewest decision points = fewest hallucination sites. Python's stdlib has the best LLM generation accuracy of any language. The "which HTTP library?" problem in Rust/JS ecosystems is the #1 LLM code generation failure mode. One rule for `std.*` eliminates an entire class of errors.

**Tiebreak:** AI/ML expert breaks the 2-2-1 tie in favor of A per project tiebreak rules.

### Resolution

**Result: Option A wins 3-2.** All `std.*` modules are tier-1 — they ship with the compiler, are version-locked, and require no `blink.toml` entry. The tier-2 concept is removed entirely, not deferred.

**What this means:**
- The `std.*` namespace means "ships with compiler, always available"
- If a module doesn't belong in stdlib, it gets a different namespace (ecosystem package)
- No registry-gated stdlib modules. No independently-versioned `std.*` packages.
- The stdlib grows with the compiler, Python-style "batteries included"
- Keeping the stdlib surface area intentionally small mitigates bloat (Go/Zig approach)

**Dissent notes:**
- **PLT** argued that the effect system creates a principled boundary between compiler-known types and convenience layers, and that bundling them together is a category error. The counter-argument: the practical benefits of a single resolution model outweigh the semantic elegance, especially for a young language.
- **Web** argued for Deno's trajectory (independently-versioned std). The counter-argument: Deno had an active registry from the start; Blink doesn't, and adding that complexity prematurely creates more problems than it solves.

**Stagnation mitigation:** The concern about Go-style stdlib stagnation is addressed by (1) frequent point releases for stdlib fixes, (2) the edition system for API evolution, and (3) keeping stdlib surface area small — only include modules where there's a clear single "right" design.
