# Friction Log

AI + human friction encountered while building the Pact compiler. Captures pain points, ambiguities, and surprises for future spec revision.

Format: append new entries at the bottom.

Categories: `syntax` | `types` | `codegen` | `ergonomics` | `ambiguity` | `tooling` | `spec-gap`
Severity: `papercut` | `annoying` | `blocking`
Source: `ai` (Claude) | `human` | `both`

---

### 2026-02-07 — Sublist API is a silent corruption footgun
- **Category:** `codegen`
- **Severity:** `annoying`
- **Source:** `ai`
- **Context:** Implementing `merge_programs()` for multi-file imports
- **Description:** The sublist system (`new_sublist` / `sublist_push` / `finalize_sublist`) uses a shared `sl_items` array. If you create multiple sublists upfront and then interleave pushes to them, all sublists get the same `sl_start` and `finalize_sublist` computes wrong lengths. There's no error — you just get silently corrupted data that crashes later in `generate()` with an opaque "list index out of bounds: -1". Had to restructure to collect into Pact `List[Int]` temporaries first, then build each sublist sequentially (create → fill → finalize, one at a time). The API shape invites the wrong usage pattern. Consider: (a) making `new_sublist` set `sl_start` at finalize-time instead of creation-time, or (b) adding a runtime check that no other sublist is "open" when pushing.
- **Update 2026-02-08:** This bug resurfaced in the pattern parser — struct/tuple/enum/or-pattern parsing all called `parse_pattern()` inside open sublists, causing silent corruption (pact-203). Fixed all pattern sublist sites to use the collect-then-build pattern. The API footgun remains; all current call sites are now safe.

### 2026-02-07 — Module-level `let mut` redeclaration semantics are confusing
- **Category:** `ambiguity`
- **Severity:** `papercut`
- **Source:** `ai`
- **Context:** Understanding how parser and codegen share the `np_*` node pool arrays in the amalgamated compiler
- **Description:** The amalgamated `pactc.pact` has duplicate `let mut np_kind: List[Int] = []` declarations (one from parser section, one from codegen section). The codegen deduplicates these to a single C variable, and only the first initialization runs. This works but is confusing — nothing in the spec or the code makes it obvious that the second declaration is a no-op rather than creating a new binding. This is an artifact of the amalgamation process, but it exposed a spec gap: what *should* happen when a module-level `let` name is declared twice? Error? Shadow? Merge? The spec should clarify.

### 2026-02-07 — Import system defeats `pub` visibility by requiring everything be `pub`
- **Category:** `spec-gap`
- **Severity:** `annoying`
- **Source:** `ai`
- **Context:** Splitting pactc.pact into 6 multi-file modules using the import system
- **Description:** The import system only brings `pub`-marked items into the merged program. But when an imported `pub fn` references module-internal helpers (non-pub functions, constants), those helpers are missing from the merged C output — the codegen emits calls to undeclared symbols. The fix was making *everything* `pub` in every module, which defeats the purpose of `pub` entirely. Root cause: the import mechanism operates at the AST declaration level (filtering which top-level nodes to include), but function bodies contain unresolved references to their module's internal symbols. Either: (a) the import system needs to transitively include non-pub items that pub items depend on, (b) codegen needs to emit all items from a module when any item from it is imported, or (c) the compilation model should change so each module is compiled to C independently and linked, rather than merging ASTs.

### 2026-02-08 — Closure const-qualifier warnings flood every call site
- **Category:** `codegen`
- **Severity:** `annoying`
- **Source:** `ai`
- **Context:** Implementing HOF support (pact-222) and immutable captures (pact-218)
- **Description:** Closures are emitted as `const pact_closure*` variables (since the binding is immutable `let`), but calling through `fn_ptr` requires casting and passing `self` as the first argument — which expects `pact_closure*` (non-const). Every single closure call site generates a `-Wdiscarded-qualifiers` warning. Similarly, `pact_list_len`/`pact_list_get` in runtime.h don't accept `const pact_list*`, so any list stored as `const` triggers the same warning. The bootstrap output has dozens of these. Fix options: (a) make runtime.h functions accept `const` pointers where they don't mutate, (b) emit closures as non-const `pact_closure*`, (c) generate explicit casts at call sites to suppress warnings.

### 2026-02-09 — Calling an undefined function produces no error
- **Category:** `spec-gap`
- **Severity:** `annoying`
- **Source:** `ai`
- **Context:** Implementing closure capture helpers; `capture_cast_expr` called `int_to_string()` which doesn't exist
- **Description:** The compiler has no notion of "defined functions" at compile time. If you call a function that was never declared, the compiler happily emits a C call to it — you only discover the mistake when `gcc` reports an implicit function declaration. This applies to all function calls, not just built-ins. A Pact program with `foo_bar_baz()` will compile to C without complaint. The spec assumes functions are checked, but there's no symbol table or name resolution pass. Fix: add a name resolution phase that checks all function calls against known declarations (top-level `fn`, imported names, built-ins) before codegen. This would catch typos, missing imports, and nonexistent functions at the Pact level instead of deferring to C.

### 2026-02-09 — Method call fallback silently generates invalid C identifiers
- **Category:** `spec-gap`
- **Severity:** `annoying`
- **Source:** `ai`
- **Context:** Implementing Into trait; `x.into()` generated `x_into()` as a C function call
- **Description:** When `emit_method_call` encounters a method it doesn't recognize (not a built-in, not a known trait impl), it falls through to a generic handler that concatenates `{obj}_{method}({args})`. So `x.into()` becomes `x_into(x)`, `foo.whatever()` becomes `foo_whatever(foo)` — no error, no warning, just nonsense C code. The return type defaults to `CT_VOID`, so variables assigned from these calls get declared as `const void y`, which is also invalid C. The fallback should either (a) emit an error for unresolved methods, or (b) at minimum not silently produce garbage. This is the method-call equivalent of the undefined function problem above — the compiler trusts that all names resolve and defers validation to `gcc`.

### 2026-02-09 — Generic list element types not propagated through function returns
- **Category:** `types`
- **Severity:** `annoying`
- **Source:** `ai`
- **Context:** Implementing mutable captures (pact-219) and effect system handles
- **Description:** When a function returns `List[Str]`, the codegen registers the return as `CT_LIST` but drops the element type parameter. So `let caps = analyze_captures(...)` followed by `caps.get(i)` generates `(int64_t)(intptr_t)pact_list_get(caps, i)` — treating strings as integers. The fix required adding `fn_ret_list_names`/`fn_ret_list_elem` parallel registries and propagating element types through call expressions and let bindings. This is a recurring pattern: the CT_* type system has no way to express parameterized types (`List[Str]`, `Option[Int]`, `Result[Int, Str]`). Each one needed its own ad-hoc parallel registry. A proper type representation (even just a struct with a CT code + inner types) would eliminate the entire class of bugs.

### 2026-02-09 — Result/Option return types silently compiled to `void`
- **Category:** `codegen`
- **Severity:** `blocking`
- **Source:** `ai`
- **Context:** Implementing `?` and `??` operators (pact-161)
- **Description:** `c_type_str()` has no case for `CT_RESULT` or `CT_OPTION`, defaulting to `"void"`. Functions declared as `fn foo() -> Result[Int, Str]` got C return type `void`, making `?` and `??` unusable. Additionally, the parser stored only `"Result"` as the return type string, discarding the type parameters `[Int, Str]`. Had to add `np_type_ann` storage on FnDef nodes and `resolve_ret_type_from_ann()` to reconstruct the full C type. Root cause is the same as the list element type issue: CT_* integers can't represent parameterized types, so every generic type needs special-case plumbing. Consider promoting to GAPS since this pattern will recur for every new generic type.

### 2026-02-10 — Closure const-qualifier warnings compound with every new feature
- **Category:** `codegen`
- **Severity:** `annoying`
- **Source:** `ai`
- **Context:** Testing HOF, closure captures, and TryFrom after codegen module split (pact-257)
- **Description:** The const-qualifier warning issue (see 2026-02-08 entry) continues to compound. Every new feature that touches closures — HOF `apply`/`apply_twice`, immutable captures, mutable captures — adds another wave of `-Wdiscarded-qualifiers` warnings. The test_hof.c output alone has 16 warnings. The bootstrap output has dozens. This makes it hard to spot *real* warnings in the noise. The underlying issue is unchanged (closures emitted as `const pact_closure*` but called through non-const function pointers), but the volume is now bad enough that it's worth prioritizing a fix. Recommend option (b) from the original entry: emit closures as non-const `pact_closure*`, since closures are heap-allocated and the `const` adds no real safety.

### 2026-02-10 — `?` operator in non-Result functions silently generates invalid C
- **Category:** `codegen`
- **Severity:** `annoying`
- **Source:** `ai`
- **Context:** Writing TryFrom + `?` operator tests (pact-233)
- **Description:** The `?` operator emits early-return code: `if (__res.tag == 1) return (Result){.tag=1, .err=__res.err}`. If the enclosing function doesn't return `Result` (e.g. `fn main() -> Void`), this generates a C statement that returns a struct from a void function — which only surfaces as a gcc error, not a Pact-level diagnostic. During test development, the test file had to be restructured multiple times to wrap all `?` usage inside `Result`-returning helper functions. The compiler should check that `?` is only used inside functions whose return type is `Result[T, E]` (or `Option[T]` for `??`) and emit a clear error otherwise. This is another instance of the "defer validation to gcc" pattern — the compiler trusts the code is well-formed and emits garbage when it isn't.

### 2026-02-13 — Formatter: all functions must be `pub` for import to work
- **Category:** `tooling`
- **Severity:** `annoying`
- **Source:** `ai`
- **Context:** Implementing the formatter module (pact-305) with `import formatter` from compiler.pact
- **Description:** Same as the 2026-02-07 `pub` visibility entry. All internal helper functions in formatter.pact had to be made `pub` because the import system only brings across `pub` items. Non-pub helpers called by the pub `format()` function were "undefined" in the merged output. This is the exact same issue as before — the import system needs transitive dependency resolution.

### 2026-02-13 — Formatter: comment attachment lossy for file-level and inline comments
- **Category:** `spec-gap`
- **Severity:** `papercut`
- **Source:** `ai`
- **Context:** Implementing comment preservation in the formatter (pact-305)
- **Description:** The parser attaches pending comments to the next AST node via `attach_comments()`, but this has gaps: (1) file-level header comments before the first declaration sometimes end up attached to the wrong node, (2) inline comments within function bodies are not reliably attached to their associated statement (they get attached to the next statement parsed, which may not be the intended one), (3) comments between declarations (e.g. between two functions) can be consumed by `skip_newlines()` and attached to the wrong function. The formatter can only emit comments where the parser stored them. Proper comment preservation would require either (a) storing comment positions relative to source lines and using heuristic reattachment, or (b) a CST (concrete syntax tree) that preserves all whitespace and comments positionally.

### 2026-02-13 — @tags annotation values emitted as pointer addresses instead of strings
- **Category:** `codegen`
- **Severity:** `annoying`
- **Source:** `ai`
- **Context:** Validating test framework end-to-end (pact-314), creating `test_tags.pact` with `@tags(unit)`, `@tags(slow)`, `@tags(unit, integration)`
- **Description:** The `@tags` annotation is parsed correctly (tag count per test is right), but the tag *values* in the generated C code are pointer addresses instead of string literals. Generated output: `static const char* pact_test_tagged_unit_test_tags[] = {"106281597399504"};` instead of the expected `{"unit"}`. The codegen at `codegen.pact:798` does `tag_arr.concat("\"{tags.get(tgi)}\"")` where `tags` is `List[Str]` from `test_tag_lists: List[List[Str]]`. The `tags.get(tgi)` call appears to return the internal pointer representation of the string rather than the string value when used inside string interpolation within `.concat()`. This means `--test-tags` filtering always returns 0 results since tag strings never match. Tests themselves compile and run fine; only the tag metadata is corrupted.

