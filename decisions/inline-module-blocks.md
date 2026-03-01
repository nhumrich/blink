[< All Decisions](../DECISIONS.md)

# Inline Module Blocks (`mod name { }`) — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted on whether Pact should support inline module blocks (`mod name { }`) for sub-file scoping, and if so, what form they should take.

**Background:** Pact's module system is file-based: "File = Module, Directory = Package" (§10.1, 5-0 locked). One file = one module = one namespace. The `json_validator.pact` example and §2.19 (test scope) reference `mod name { }` blocks, but no formal specification exists. The compiler has zero support for inline modules. The question: is `mod name { }` the right mechanism for sub-file scoping, or should the file = module principle be absolute?

**Options considered:**
- **A: Full Inline Modules** — `mod name { }` creates a real sub-module: namespace, visibility, importable from other files, nesting allowed
- **B: File-Scoped Namespaces** — `mod name { }` creates a file-local namespace only, not importable cross-file, no nesting
- **C: No Inline Modules** — File = Module is absolute. No `mod { }` blocks. Separate files for sub-modules. `mod` keyword reserved but unused
- **D: Test-Only Mod Blocks** — `mod { }` exists only for test grouping with private access

**Vote (4-1): Option C — No Inline Modules**

- **Systems:** Vote C. File = Module maps cleanly to C translation units with deterministic symbol namespaces. Options A and B both introduce partial namespacing that complicates symbol mangling at the C emit layer — non-trivial bookkeeping for zero runtime benefit. File splits actually improve incremental recompilation granularity.
- **Web/Scripting:** Vote B *(dissent)*. Inline namespaces are a daily reality in TypeScript and Python. Option B gives developers the organizational benefit they clearly want without cognitive overhead of cross-file importability. The `schema.validate_field()` access pattern feels natural. Concern: `pub` meaning shifts depending on nesting context.
- **PLT:** Vote C. The "File = Module" invariant is a clean, compositional principle — one kind of module entity, one way to create it. Introducing inline `mod` blocks creates two distinct module-like constructs which violates having one canonical concept. Even Option B (carefully not calling them "modules") would lead users to reason about them as second-class modules and hit surprising edges.
- **DevOps/Tooling:** Vote C. File = Module is the one invariant that makes every tooling story trivially correct. Go-to-definition always opens a file. Symbol search maps 1:1 to files. LSP implementation for C is ~20% the complexity of A or B — and that saving compounds across every future feature (rename, find-all-refs, hover).
- **AI/ML:** Vote C. File-based modules with zero inline constructs represent the minimal decision surface for LLM generation. Every capable AI already has strong priors on "one file = one module" from Go and Python training data. Options A and B multiply opportunities for hallucination about `pub` semantics and import paths. Compiler should emit a clear error if `mod name { }` is attempted.

**AI-First Review: 5/5 PASS**

1. **Learnability** — PASS. Zero new concepts. "File = module, always" is the simplest possible rule
2. **Consistency** — PASS. Reinforces §10.1 rather than introducing exceptions
3. **Generability** — PASS. LLMs already generate file-based modules reliably from Go/Python priors
4. **Debuggability** — PASS. Clear compiler error if `mod name { }` is attempted, guiding toward separate files
5. **Token Efficiency** — PASS. No wrapper tokens or extra indentation needed

**Resolution:** No inline module blocks. File = Module is absolute (§10.1). The `mod` keyword remains reserved but unused in v1. If users need sub-module organization, they create separate files in a subdirectory. The `json_validator.pact` example is restructured to demonstrate file-based sub-modules. Test scoping is simplified: tests in a file see all items (pub and private) in that file's module — no `mod { }` wrapper needed. Spec: §10.1.1.
