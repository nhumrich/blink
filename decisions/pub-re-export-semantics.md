[< All Decisions](../DECISIONS.md)

# Pub Re-export Semantics — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions. All votes unanimous.

**Context:** The spec (§10.5) already defines `pub import` syntax and basic rules (re-exported items must be pub, transitive re-exports work, circular re-exports rejected). However, several semantic details were underspecified: how consumers access re-exported items, name collision handling, unused import warning interaction, and whether re-exports require facade modules. The motivating use case is the codegen subsystem where 6 files each import 50-100 overlapping symbols from `codegen_types` — a common re-export module would eliminate this duplication.

**Q1: Consumer-side semantics — how do consumers access re-exported items? (5-0 for A: both selective and qualified)**

- **Systems (A):** Re-exported symbols should behave identically to locally-defined pub symbols. The C output uses `blink_A_foo` regardless of provenance, so both qualified and selective access should work. The compiler doesn't need to track "how was this symbol made public" — only "is it public."
- **Web/Scripting (A):** This is the most intuitive behavior and matches how barrel files work in TypeScript and `__init__.py` re-exports work in Python. A JS/Python dev would expect both `A.foo` and `import A.{foo}` to work.
- **PLT (A):** Re-exported names must become first-class members of the re-exporting module's public signature. This follows from the substitution principle: a consumer should not need to know whether `A.foo` was defined locally or re-exported from B. ML's `include` and Haskell's explicit export lists both work this way.
- **DevOps (A):** If `foo` is in A's public namespace, LSP autocomplete on `A.` must show it, and `import A.{foo}` must find it. Having the two access mechanisms disagree on visibility creates confusing diagnostics.
- **AI/ML (A):** One consistent rule: "pub items are pub items, regardless of origin." An AI needs only one mental model, no hidden decision points about access mechanism depending on how an item entered a namespace.

**Q2: Name collision — what if A re-exports and locally defines the same name? (5-0 for A: compile error)**

- **Systems (A):** Duplicate symbols in the same namespace should be a compile error. Shadowing creates invisible order-dependent resolution. C linkers reject duplicate symbols, Rust rejects duplicate names in the same scope.
- **Web/Scripting (A):** Shadowing rules are one of the most common sources of subtle bugs in JS and Python. TypeScript explicitly disallows duplicate exports. If a module both defines and re-exports the same name, that is almost certainly a mistake.
- **PLT (A):** Compile error is the only sound option. Shadowing breaks referential transparency of names within a module's public interface. Both ML and Haskell reject duplicate names in export lists.
- **DevOps (A):** Shadowing would force the LSP to silently resolve to one definition while the other becomes dead code with no diagnostic. The error message is clear: "duplicate public symbol `foo` in module A: defined at A.bl:12 and re-exported from B at A.bl:3".
- **AI/ML (A):** Compile error is the only outcome an AI can reliably predict. Shadowing rules fail silently and require memorizing priority conventions.

**Q3: Unused import warnings — how does `pub import` interact with W0602? (5-0 for A: never triggers)**

- **Systems (A):** `pub import` declares public API surface, not local usage intent. It's analogous to a C header's `extern` declaration. Options B and C require whole-program analysis that conflicts with separate/incremental compilation.
- **Web/Scripting (A):** Analogous to `export { foo } from './b'` in TypeScript — you would never get an unused import warning for that. Firing W0602 on pub imports would make barrel/facade modules unusable without suppression comments everywhere.
- **PLT (A):** Warning on "unused" re-exports conflates interface declaration with local usage intent and would require whole-program analysis that breaks separate compilation. You would not warn that an exported type is "unused" just because the module itself doesn't reference it.
- **DevOps (A):** `pub import` is a declaration of public API surface, not a usage site. Firing W0602 on it is a false positive. Option B requires whole-program analysis to determine "downstream consumer usage," which is architecturally wrong for a per-file warning pass.
- **AI/ML (A):** `pub import` is a public API declaration, not local usage. Option A is trivially learnable: "pub import = re-export, no W0602." Zero decision points.

**Q4: Sibling module re-exports — does `pub import` require facade files? (5-0 for A: no restriction)**

- **Systems (A):** `pub import` is a visibility mechanism, not a packaging mechanism. The motivating use case (`codegen_common.bl`) directly requires sibling-to-sibling re-exports without facade annotation.
- **Web/Scripting (A):** Restricting to `@module` facades adds ceremony without clear benefit. In Python and TypeScript, any module/file can re-export.
- **PLT (A):** Restricting `pub import` to `@module`-annotated files introduces an ad-hoc syntactic constraint with no type-theoretic justification. The typing rule for re-export is well-defined regardless of file annotation.
- **DevOps (A):** Restricting to facades produces a confusing error: "you can't use `pub import` here because this file isn't a facade." Keep it simple: if you can import it, you can pub import from it.
- **AI/ML (A):** Zero preconditions: if you can import it, you can pub-import it. Requiring `@module` annotation adds a prerequisite concept and an extra branching point with no semantic benefit.

### Cross-language Survey

| Language | Re-export Mechanism | Restrictions | Consumer Access |
|----------|-------------------|-------------|-----------------|
| Rust | `pub use` | Works in any module | Full qualified + use |
| TypeScript | `export { x } from './mod'` | Any module | Both import styles |
| Python | Re-assign in `__init__.py` | Convention, not enforced | Any access |
| Haskell | Module export list | Any module | Qualified + unqualified |
| OCaml | `include` in `.mli` | Any module signature | Full access |
| Go | No direct re-export | N/A (capitalization-based) | Package-qualified only |

### Resolution

1. **Consumer access**: Re-exported items are indistinguishable from locally-defined pub items. Both `import A.{foo}` and `A.foo` work when A re-exports foo.
2. **Name collision**: Compile error if a module both defines and re-exports the same public name.
3. **Unused import warnings**: `pub import` never triggers W0602. Stale re-exports are a separate concern for a future "unused public API" lint.
4. **Scope**: Any module can use `pub import`, not just `@module`-annotated facades.
