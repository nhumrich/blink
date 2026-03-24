[< All Decisions](../DECISIONS.md)

# Inline String Escape Pain — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted on whether inline string escape stacking (as evidenced by 13+ `\\\"` instances in the compiler's own codegen) warrants a language-level solution, and if so, what mechanism.

**Background:** The previous `#embed("path")` deliberation (5-0) solved large text blob embedding but explicitly did not address inline escaping. The compiler's codegen_derive.bl demonstrates the remaining pain: generating C strings containing quoted JSON keys requires triple-escaped quotes (`\\\"`), making code unreadable and error-prone for both humans and LLMs. The panel previously stated "`\{`/`\}` escaping is adequate for inline strings" — the evidence from 13+ codegen instances and 20+ JSON test assertions challenged that claim.

**Options considered:**
- **A: Do Nothing** — Accept escape stacking as inherent to metaprogramming (~13 instances)
- **B: Stdlib Helper Functions** — `c_quote()`, `c_str_escape()` etc. No syntax change
- **C: Extended Delimiter Strings (`#"..."#`)** — Swift-inspired, `"` and `\` literal inside, interpolation via `#{expr}`
- **D: Dedicated Codegen Builder API** — Structured builder pattern for C emission

**Vote (5-0): Option C — Extended Delimiter Strings**

- **Systems:** Vote C. Zero runtime cost — purely a lexer concern. The `\\\"` instances are a correctness hazard, not just aesthetic pain. Rust's `r#"..."#` and Swift's `#"..."#` prove the pattern is lexer-simple and ergonomic. Recommends capping `#` depth.
- **Web/Scripting:** Vote C. Triple-escaped strings are a cognitive disaster for JS/Python devs. JSON is everywhere in web work — `\{\"name\":\"Alice\"}` will appear constantly. Swift-inspired `#"..."#` is a 5-minute explanation. Concerned about two interpolation syntaxes (`{expr}` vs `#{expr}`).
- **PLT:** Vote C. Formally clean: `#^n "..." #^n` with interpolation `#^n{expr}` is a parametric extension of existing string syntax indexed by delimiter depth. Composes correctly — same `Str` type, interpolation still works, no new type rules. OCaml's `{id|...|id}` quoted strings (since 4.00) are closest precedent.
- **DevOps/Tooling:** Vote C. Lexer change is bounded and well-understood. Formatter treats interior as opaque text. Critical requirement: LSP must detect `{expr}` patterns inside `#"..."#` and emit a hint ("Did you mean `#{expr}`?") to prevent silent failures.
- **AI/ML:** Vote C. Escape miscounting is one of the most reliable LLM failure modes — compounds silently with no diagnostic signal. Swift's `#"..."#` exists in training data. Key analysis: "LLM miscounts escapes" (silent corruption) is strictly worse than "LLM forgets `#` prefix on interpolation" (literal text in output, loud failure). Loud failures are debuggable; silent ones are not.

**AI-First Review: 5/5 PASS**

1. **Learnability** — PASS. Swift `#"..."#` is direct precedent in LLM training data
2. **Consistency** — PASS. `#` prefix already established for compile-time category (`#embed`). Same `Str` result type. Parametric extension, not a separate syntax
3. **Generability** — PASS. LLMs can generate `#"..."#` reliably from Swift training data
4. **Debuggability** — PASS. "Unterminated extended string" error is clear. `{expr}` inside `#"..."#` produces visible literal output (loud failure)
5. **Token Efficiency** — PASS. 2 tokens overhead, eliminates many `\\` escape tokens. Net positive for dense strings

**Resolution:** `#"..."#` extended delimiter strings with `#{expr}` interpolation. `#` count adjustable (max depth 3). Interior treats `"` and `\` as literal characters — no escape processing. Same `Str` type as regular strings. Locked "one string syntax" decision preserved — this is a parametric extension of the same delimiter (same `"`, same type), not an alternate string syntax. Spec: §2.4.2.
