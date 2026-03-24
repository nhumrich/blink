[< All Decisions](../DECISIONS.md)

# Stdlib API Surface — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 1 question. Each expert ran as a separate agent and returned votes without seeing other experts' reasoning.

**Context:** Blink's stdlib modules expose operations on built-in types (Str, Bytes, StringBuilder, List, Map, Set) via two mechanisms: (1) compiler-hardcoded method dispatch in `codegen_methods.bl` (`b.len()`, `s.split(",")`) and (2) free functions in `lib/std/` (`bytes_len(b)`, `str_split(s, ",")`). Both call the same C runtime. This creates a Principle 2 tension — "one way to do everything." The panel was asked to decide: methods only, free functions only, both with guidance, or a hybrid.

**Critical finding (all 5 experts independently confirmed):** The free functions in `lib/std/str.bl`, `lib/std/bytes.bl`, and `lib/std/sb.bl` are already non-`pub` — they are internal FFI bridges. Users cannot call `str_len(s)` today. The user-facing API is already methods-only. The question reduces to: formalize this as spec policy, and audit remaining modules for `pub fn` violations.

**Q1: Should stdlib types expose their API through methods only (A), free functions only (B), both (C), methods + namespaced constructors (D), or methods + real trait dispatch roadmap (E)? (4-1 for A/E — methods only)**

- **Systems:** A. Method calls compile to direct C function calls — zero runtime overhead, identical codegen to free functions. The ~3000-line dispatch table in `codegen_methods.bl` is a compile-time artifact, not a runtime cost. Dot-chaining (`data.to_str().trim().split(",")`) matches execution order; nested free functions (`str_split(str_trim(bytes_to_str(data)), ",")`) inverts it. Every modern systems language (Rust, Go, Swift) uses methods as the primary API. Free functions as internal FFI plumbing is already the pattern in str/bytes/sb.
- **Web/Scripting:** D. Methods for operations, static constructors for creation (`Type.new()`, `Bytes.from_str()`). This is what JS, Python, Kotlin, and Rust all converge on. Dot-completion in LSPs is the #1 discovery mechanism — method syntax enables it. The real cleanup needed is internal: eventually replace hardcoded dispatch with real trait resolution. *(dissent — but D is functionally identical to A since constructors already use `Type.method()` static syntax)*
- **PLT:** E. Methods only, but the compiler must eventually replace hardcoded dispatch with real trait resolution. The spec claims "all methods are trait methods" (§3c.4) while the implementation pattern-matches on type tags. The traits (`Sized`, `StrOps`, `ListOps`) are phantoms — no source declarations, no `impl` blocks. This bifurcation means builtins and user types resolve methods through different mechanisms, which is unsound. Migration path: (1) formalize methods-only now, (2) define traits in source near-term, (3) implement real resolution eventually.
- **DevOps:** A. LSP autocomplete is the killer argument. Type `s.` → get the full Str method list. Type `str_` → get a flat, unfiltered list. With both forms (Option C), LSP shows duplicates and users ask "which one?" Error messages are better too: `5.split(",")` → "Int has no method `split`" vs `str_split(5, ",")` → generic type mismatch. `blink fmt` has nothing to normalize when there's one canonical form. No major language with a strong LSP exposes the same operation as both `x.method()` and `type_method(x)`.
- **AI/ML:** A. Method syntax is the dominant training signal across Python, JS, TS, Rust, Go, Java, C#, Ruby, Swift, Kotlin. Free functions with type-prefixed names (`str_len`, `bytes_push`) are a C-ism. With both forms: ~15 unnecessary decision points per 100 lines. With methods only: 0. Token efficiency: `s.trim().split(",")` ~8 tokens vs `str_split(str_trim(s), ",")` ~12 tokens. One rule ("call `.method()` on values") is learnable from spec + examples; N type-prefixed function names is memorization.

### Notable Cross-Cutting Concerns

- **Constructor syntax is already clean.** All experts confirmed that static constructors (`Bytes.new()`, `StringBuilder.new()`, `Duration.ms(100)`) already use `Type.method()` syntax — this is method dispatch on the type, not a free function. Web's Option D doesn't diverge from A in practice.
- **Hardcoded dispatch is tech debt, not a design question.** The 3000-line `codegen_methods.bl` is an implementation concern. The spec decision (methods-only API) is orthogonal to whether dispatch uses pattern matching or real trait resolution. PLT's roadmap is noted but doesn't change the user-facing rule.
- **Method references (future).** AI/ML and Systems both noted that removing free functions eliminates the terse form for higher-order usage (`list.map(str_len)` vs `list.map(fn(s) { s.len() })`). Solvable with method references (`Str::len`) if needed later. YAGNI for now.

### AI-First Review

All 5 criteria pass:

| Criterion | Result | Notes |
|-----------|--------|-------|
| Learnability | Pass | "Call `.method()` on values" is one rule |
| Consistency | Pass | Matches existing trait-method-only rule (§3c.4) |
| Generability | Pass | `.method()` is dominant LLM training signal |
| Debuggability | Pass | Type-specific error messages ("no method X on Y") |
| Token Efficiency | Pass | Chaining < nesting; fewer tokens per operation |
