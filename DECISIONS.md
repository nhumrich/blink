# Pact Design Decisions

Reference material extracted from the spec process. Influences, rejected features, resolved questions, editor's notes, and design process history.

---

## Editor's Notes

Minor inconsistencies between sections written by different experts. These need resolution:

1. ~~**Annotation syntax**: Section 8 (in 06_tooling.md) uses `/// @i("text")` inside doc comments, while sections 2, 3, 4, 5, 9, 10, 11 use standalone `@i("text")`.~~ **Resolved:** `@i` removed entirely (panel vote 5-0). Intent is now the first line of `///` doc comments. See `@i` Annotation deliberation.

2. ~~**Annotation ordering**: Section 2.9 puts `@capabilities` after `@perf`. Section 11.1 puts `@capabilities` before `@i`.~~ **Resolved:** `@i` removed. Canonical ordering is now: `@mod` > `@capabilities` > `@derive` > `@src` > `@requires` > `@ensures` > `@where` > `@invariant` > `@perf` > `@ffi` > `@trusted` > `@effects` > `@alt` > `@verify` > `@deprecated`.

3. **Method call syntax**: ~~Some sections use `email.len > 0` (property-style), others use `email.len() > 0` (method-style). Needs a decision.~~ **Resolved:** Always `x.len()` method-call syntax everywhere, including contracts. Panel vote 5-0.

---

## Design Process

This spec was developed through a multi-expert panel process across two sessions:

**Session 1:** 5 domain experts (systems programming, web/scripting, PL theory, DevOps/tooling, AI/ML) independently brainstormed attributes, designed syntax, and voted on contested decisions.

**Session 2:** 7 experts (original 5 + 2 fresh perspectives) each independently wrote sections of this merged spec, incorporating the best ideas from both prior iterations. The user's directive: think long-term ideal design, not v1-constrained.

---

## Influences

| Language | What Pact Borrows |
|----------|------------------|
| **Go** | Single binary deployment, `gofmt` philosophy, compilation speed priority |
| **Rust** | `fn` keyword, `match` expressions, `Option`/`Result`, `?` operator, traits, expression-oriented |
| **Koka** | Algebraic effects as a core feature, effect tracking in signatures |
| **OCaml/Haskell** | Hindley-Milner type inference, ADTs, pattern matching, ML type system level |
| **TypeScript** | `: Type` annotation syntax, developer experience focus |
| **Scala/Python 3.9+** | Square brackets for generics |
| **Swift** | `??` nil-coalescing operator |
| **E Language** | Object-capability model (Mark Miller) — effects as capabilities |
| **Dafny/Liquid Haskell** | Refinement types, `@requires`/`@ensures` contracts, SMT verification |
| **Z3** | SMT solver integration for contract verification |

---

## What We Explicitly Rejected

| Feature | Why Rejected |
|---------|-------------|
| **Ownership/lifetimes** | AI struggles with borrow checker (30-40% failure rate). Interacts badly with algebraic effects. Cognitive overhead anti-locality. |
| **Gradual typing** | "If you build a trapdoor, AI will find it." Undermines every type system guarantee. |
| **Null** | Billion-dollar mistake. `Option[T]` makes absence explicit and compiler-enforced. |
| **Exceptions** | Invisible control flow. Violates locality. LLMs generate incorrect catch blocks. `Result[T, E]` is explicit. |
| **Inheritance** | Creates deep hierarchies that destroy locality. Fragile base class problem. Traits are strictly better. |
| **Implicit conversions** | Action-at-a-distance. The AI (and the human) should see exactly what types flow where. |
| **Arbitrary operator overloading** | Reduces readability. Trait-based operator impls for numeric types only. |
| **Arbitrary macros** | Create sublanguages the AI hasn't seen in training data. Derive macros for codegen are the exception. |
| **Significant whitespace** | LLMs mangle indentation. Copy-paste loses whitespace. Braces are unambiguous. |
| **Multiple string delimiters** | One string syntax. No `'single'` vs `"double"` vs `` `backtick` ``. |
| **Semicolons** | Redundant with canonical formatting. Pure noise tokens. |
| **Structural typing** | Nominal types are easier for LLMs — distinct identifiers to latch onto. |
| **Full dependent types** | Type inference becomes undecidable. LLMs cannot reliably generate proofs. Error messages become incomprehensible. Refinement types give 90% of the value at 10% cost. |
| **JIT compilation** | Two compilation pipelines = two sets of bugs. JIT warmup is nondeterministic. Single binary deployment wins. |
| **Coarse-grained effects** | `! IO` collapses to meaninglessness within 3 call levels. Fine-grained effects (FS.Read, DB.Write) are the security model. |
| **Sigils for declaration** (`~`/`+`) | `fn` is universal. Sigils conflate visibility with declaration. Rejected 5-0. |
| **`:=` for bindings** | `let`/`let mut` has explicit mutability semantics. `:=` is ambiguous. Rejected 5-0. |
| **`::` for return type** | `->` is standard. `::` conflicts with Haskell convention. Rejected 4-1. |
| **Angle bracket generics** `<>` | Genuine parsing ambiguity with comparison operators. Zero technical argument over `[]`. Rejected 5-0. |
| **Optional keyword args (caller's choice)** | Caller deciding whether to name args violates Principle 2 (one way). Creates style decision at every call site. AI must choose between two forms. |
| **Mixed positional + keyword at same call site** | `foo(1, y: 2)` is the Python/Swift/Kotlin path. Creates decision-point-per-call-site that Principle 2 exists to prevent. |
| **Function parameter defaults** | Interact with closures (does `fn(Int) -> Int` match a fn with defaulted 2nd param?), higher-order functions, partial application. Struct field defaults are the simpler, controlled version. |

---

## Resolved Questions

Decided by expert panel vote. See [OPEN_QUESTIONS.md](OPEN_QUESTIONS.md) for full deliberation.

| Decision | Result | Vote |
|----------|--------|------|
| Closure syntax | `fn(params) { body }` — one keyword, no `\|x\|` sigil form | 5-0 |
| Derive/codegen | `@derive(Eq, Hash)` annotation. Compiler-known traits only for v1 | 5-0 |
| Property access | Always `x.len()` method-call syntax, including in contracts | 5-0 |
| Concurrency model | Green threads, structured concurrency, `Async` as effect. `main` has implicit effects | 5-0 ratified |
| Await semantics | `handle.await` — method on `Handle[T]`, compiler-recognized suspension point. Composes with `?` | 5-0 |
| Iterator/loop syntax | `for x in collection { }`, `.method()` chaining, `\|>` pipes. No comprehensions v1 | 5-0 ratified |
| Iterator trait | Single `next(self) -> Option[T]` method. No `has_next()`, no `size_hint()` in v1 | 3-2 (Web/DevOps/AI for single; Sys/PLT for multi-method) |
| IntoIterator separation | Separate `IntoIterator` trait; collections produce iterators, aren't iterators | 5-0 |
| Lazy iteration | Adapters (`.map()`, `.filter()`) return lazy iterators. `.collect()` materializes | 5-0 |
| Iterator adapter placement | Default methods on `Iterator` trait. Implement `next()`, get adapters free | 5-0 |
| Effectful iteration | Deferred to v2. v1 Iterator is pure — `next()` cannot perform effects | 3-2 (Web/DevOps/AI for defer; Sys/PLT for v1 effects) |
| Standard library scope | 3-tier system: Core (compiler), Batteries (toolchain), Ecosystem (community). `math/str/fmt` confirmed Tier 1 | 5-0 ratified |
| Range syntax | `..` exclusive, `..=` inclusive, `Range[T: Ord]`, lazy | 5-0 ratified |
| Keyword arg separator | `--` separator divides positional from keyword params. Author decides, caller has no choice | 3-1-1 (`--` 3, `;` 1, `*` 1) |
| Keyword labels in type | Labels are call-site sugar only. Function type is `fn(Int, Account, Account)` regardless of `--` | 5-0 |
| Struct field defaults | Struct fields can declare compile-time constant defaults. Omitted fields use default at construction | 5-0 |
| Struct construction shorthand | `foo({ port: 3000 })` when param type is inferrable. Sugar only — function takes one struct arg | 5-0 |
| Function param defaults | Rejected for v1. Interact with closures, HOFs, partial application. Struct defaults cover the use case | 5-0 (reject) |
| Resource cleanup | `Closeable` trait + `with...as` scoped resource blocks. 3-0 over `defer` and lint-only approaches | 3-0 |
| Interpolation injection safety | `Query[C]` phantom-typed parameterized queries. Auto-parameterize `{expr}` in Query context. `Raw(expr)` per-interpolation escape hatch (replaces `Query.raw()`). Taint tracking deferred to v2 | 3-0 |
| Query escape hatch | `Raw(expr)` marker type. Per-interpolation bypass inside `Query[C]` strings. No format specs v1. No `Query.raw()` | 2-1 (D 2, A 1) |
| Codegen backend | Emit C source, shell out to cc/gcc/clang. Koka-style evidence-passing for effects. Optional LLVM via `clang -O2` for release builds | 4-1 (Sys/PLT/DevOps/AI for C; Web for Cranelift) |
| Operator desugaring | Trait-based: operators desugar to trait method calls (Add, Sub, Mul, Div, Rem, Neg, Eq, Ord) | 5-0 |
| Arithmetic trait restriction | Sealed: only compiler-provided impls for built-in numeric types | 4-1 |
| Boolean operator semantics | Language primitives requiring `Bool`. Short-circuit. No truthiness | 5-0 |
| Assignment operators | `+=` `-=` `*=` `/=` `%=` as syntactic sugar, `let mut` only | 5-0 |
| String concatenation via `+` | Rejected. Use interpolation or `.concat()` | 5-0 |
| Float equality | Total ordering: NaN == NaN, NaN sorts last | 5-0 |
| Ordering type | `type Ordering { Less, Equal, Greater }`, compiler-known, prelude | 5-0 |
| Assertion messages | Optional trailing `Str` message on all assertions. Interpolation via standard string syntax | 3-2 (Sys/PLT/AI for B; Web/DevOps for C) |
| `panic()` function | `panic(msg: Str) -> Never` available everywhere. Untracked divergence, not an effect. Test runner catches; production terminates | 5-0 |
| `assert_matches` | Fourth compiler intrinsic. Second arg is a pattern, not an expression. No binding support v1 | 4-1 (AI/ML: thin training data, pattern-as-arg confuses LLMs) |
| Assertion output format | Expression introspection (Power Assert). Sub-expression values on failure. Left/right for `assert_eq`. One-level bounded depth | 4-1 (PLT: left/right is structurally honest, introspection is ad-hoc) |
| Comparison chaining | Rejected. `a < b < c` is compile error. Use `a < b && b < c` | 4-1 |
| `From[T]` trait | Single method `fn from(value: T) -> Self`. Compiler-known trait | 5-0 |
| `Into[T]` trait | Auto-derived by compiler from every `From` impl. Never user-implemented | 4-1 (AI/ML: no Into) |
| `TryFrom[T]` trait | Exists with fixed `ConversionError` error type (no associated types) | 5-0 exists; 3-2 fixed error (Sys/PLT: generic) |
| Numeric conversions | Both named methods (`.to_float()`) AND From/TryFrom impls | 4-1 (AI/ML: traits only) |
| `?` error conversion | No auto `.into()` on Err. Exact type match required. Use `.map_err()` | 4-1 (DevOps: auto-convert) |
| Generic From bounds | `fn foo[T: From[Str]](s: Str) -> T { T.from(s) }` is valid | 5-0 |
| If/else as expression | Always an expression. Value discarded → type `()`. Both branches type-unify when value is used | 5-0 |
| Else mandatory (expression context) | Required when value is used (let, return, arg). Optional when standalone (type `()`) | 5-0 |
| `if let` syntax | Rejected for v1. `match` + `??` cover use cases. Principle 2 | 5-0 |
| Parentheses around if condition | Forbidden (not optional). Consistent with `for`. One canonical form | 5-0 |
| `while` and `loop` constructs | Both: `while cond { }` for conditional, `loop { }` for unconditional. Different intent, different semantics | 3-2 (Sys/PLT/DevOps for both; Web/AI for while-only) |
| Break/continue semantics | Plain `break`/`continue` only. No break-with-value for v1 | 3-2 (Web/DevOps/AI for plain; Sys/PLT for break-expr) |
| Labeled breaks | Rejected for v1. Extract to function for nested loop exit | 4-1 (DevOps dissent) |
| `while let` syntax | Rejected for v1. Consistent with `if let` rejection. Use `loop { match ... }` | 5-0 |
| Import search paths | Single `src/` root + deps from `pact.lock`. No env vars, no configurable roots | 5-0 |
| Import cycle handling | Intra-package cycles OK (ML-style batch resolution), cross-package cycles are compile errors | 4-1 (DevOps: strict everywhere) |
| Diamond dependencies | Exactly one version per package. Conflict → compile error. Minimum version selection | 4-1 (Web: semver-compatible dedup) |
| Re-exports | `pub import` syntax. Decouples internal structure from public API | 5-0 |
| Import aliases | `import mod.{X as Y}` for local renaming. No wildcard imports | 5-0 |
| Method resolution: dot semantics | `x.foo()` is always trait method call, never field-call. `(x.field)(args)` for callable fields | 5-0 |
| Method resolution: effect handles | Effect handles are reserved names, cannot be shadowed by local variables | 5-0 |
| Method resolution: trait ambiguity | Multiple traits with same method → compile error at call site, use `Trait.method(x)` to disambiguate | 5-0 |
| Inherent methods | Rejected. All methods must belong to traits. No `impl Foo { fn bar(self) }` | 4-1 (Sys: wanted inherent) |
| Test effect model | Pure by default. No implicit effects in test blocks. Use `with` handlers | 5-0 |
| Test assertions (original) | Three built-ins: `assert`, `assert_eq`, `assert_ne` | 4-1 (PLT: minimal only) |
| Test filtering | Name + path + `@tags(...)` annotation for structured filtering | 4-1 (AI/ML: name-only) |
| Test scope | Top-level and inside `mod { }`. Module tests see private items | 4-1 (AI/ML: top-level only) |
| Test skip mechanism | Both `@skip` annotation (compile-time) and `skip()` built-in (runtime conditional) | 3-2 (PLT/AI: `@skip` only) |
| Tuple max arity | Cap at 6. Beyond 6 → compile error, use named struct | 5-0 |
| Tuple 1-tuples | No 1-tuple. `(T)` is always parenthesization | 5-0 |
| Serialization mechanism | `@derive(Serialize, Deserialize)` generating trait impls. Extends existing `@derive` | 5-0 |
| Serialization field renaming | No `@json("name")` field renaming in v1. Field names must match JSON keys | 3-2 (Sys/PLT/AI for no rename; Web/DevOps for `@json`) |
| Serialization codec dispatch | JSON-specific `Serialize` trait returning `JsonValue`. Add separate traits for other codecs later | 5-0 |
| Serialization tier | Tier 1 — `Serialize`/`Deserialize` are compiler-known traits, `@derive` works out of the box | 5-0 |
| Option JSON encoding | `Option[T]` `None` → JSON `null`. Consistent with majority of JSON libraries | 5-0 |
| Serialization error type | Single `JsonError` type covering both serialization and deserialization | 4-1 (PLT: separate types) |
| Serialization purity | Pure — `to_json()` returns `JsonValue`, IO effects only at call site | 5-0 |
| Tuple auto traits | Full structural: Eq, Ord, Hash, Display, Clone when elements satisfy | 5-0 |
| OR-patterns | `\|` separator. All alternatives bind same vars with same types | 5-0 |
| Range patterns | `..`/`..=` in patterns. Int/sized ints/Char only, compile-time constant bounds | 5-0 |
| Pattern binding | `as` keyword (`name as pattern`). Not `@` (conflicts with annotations) | 4-1 (AI/ML: defer) |
| Struct patterns in match | Full: field punning, `..` rest, literal field values. Nominal (type name required) | 5-0 |
| Refutable vs irrefutable | Strict compile error on refutable `let`. `let`/`for` = irrefutable, `match` = refutable | 5-0 |
| `Self` type scope | Valid in trait declarations + impl blocks only. Compile error elsewhere | 5-0 |
| `self` keyword sugar | `self` desugars to `self: Self`. `.method()` requires literal `self` first param | 5-0 |
| `Self` as constructor | Type-position alias only, not a constructor. Use concrete type name | 4-1 (Web wanted construction) |
| `self` passing semantics | Always by-value (GC, no references). No `&self`/`&mut self` | 5-0 |
| Closure capture mode | Shared reference (GC pointer). Mutations to `let mut` visible across closure boundary | 3-2 (PLT/AI/DevOps for shared; Sys/Web for by-value) |
| Explicit capture syntax | No explicit syntax (no `move`, no capture lists). Snapshot via `let` binding | 4-1 (DevOps: `move` keyword) |
| Spawn mutable captures | Compile error E0650 on `let mut` captures in `async.spawn`. Immutable captures OK | 3-2 (PLT/DevOps/AI for error; Sys/Web for auto-copy) |
| Module prelude scope | All built-in types + Option/Result + Ordering + all compiler-known traits. Not: ConversionError, Range, Handler | 3-1-1 (PLT/DevOps/AI for C; Web for B; Sys for D) |
| `true`/`false` status | Language keywords, not prelude values. Recognized by parser, not name resolution | 5-0 |
| Test builtins availability | `assert`, `assert_eq`, `assert_ne`, `prop_check` auto-available in test blocks. No import needed | 5-0 |
| Trait coherence: orphan rule | Strict: impl must be in package that defines the trait or the type. No third-party orphan impls | 5-0 |
| Trait coherence: impl overlap | No overlap, no specialization. Overlapping impls are a compile error | 5-0 |
| Trait coherence: impl placement | Any module within the owning package. Impls auto-visible when trait or type is imported | 5-0 |
| Effects on function types | Explicit: `fn(T) -> U ! IO.Log` as type expression. Same `!` syntax as declarations | 5-0 |
| Effect polymorphism form | Wildcard forwarding: `fn map(f: fn(T) -> U ! _) -> Iterator[U] ! _`. Named effect variables deferred to v2 | 3-2 (Web/DevOps/AI for wildcard; Sys/PLT for row polymorphism) |
| Effect polymorphism timeline | Fn-type effects in v1, wildcard polymorphism v2. Foundation now, generality later | 4-1 (Web/PLT/DevOps/AI for B; Sys for full v1) |
| Handler type identity | `Handler[E]` is a single generic type constructor parameterized by effect | 5-0 |
| Handler effect projection | Implicit projection: `Handler[DB]` usable where `Handler[DB.Read]` expected, compiler extracts vtable slots | 3-2 (Sys/PLT/DevOps for projection; Web/AI for covariant subtyping) |
| Handler generic parameters | No effect-kinded generics in v1. Handlers always concrete. Deferred to v2 with named effect variables | 4-1 (PLT dissented: wanted effect-kinded generics now) |
| Handler storage | Full first-class values: struct fields, lists, maps, closures, arguments, return values | 4-1 (Sys dissented: wanted restricted storage) |
| Handler completeness | Partial handlers with auto-delegation. Omitted ops forward via `default.op(args)` | 5-0 |
| Clone semantics | Logical copy (one-level deep). GC pointers copied, not recursively cloned. Deep clone deferred to v1+ | 3-2 (Sys/Web/PLT for logical; DevOps/AI for deep) |
| Debug trait | Separate `Debug` trait, no supertrait relationship with `Display`. Structural repr for developers | 5-0 |
| Derive codegen algorithm | Inferred bounds on generics + auto supertrait derivation. Field-by-field for structs, variant-match for enums | 5-0 |
| Derive error reporting | Report all non-derivable fields in one diagnostic pass. Field-level error pointing | 5-0 |
| Collection trait organization | `Contains[T]` shared trait + per-type `ListOps[T]`, `MapOps[K,V]`, `SetOps[T]` | 5-0 |
| List[T] method surface | Expanded: 12 methods (push, pop, get, set, append, contains, reverse, sort, insert, remove, index_of, last) | 3-2 (Web/DevOps/AI for expanded; Sys/PLT for 8) |
| Map[K,V] method surface | Expanded: 8 methods (get, insert, remove, contains_key, keys, values, entries, get_or_default) | 3-2 (Web/DevOps/AI for expanded; Sys/PLT for 6) |
| Set[T] method surface | Core: 4 methods (insert, remove, contains, union). Full set algebra deferred | 3-2 (Sys/Web/AI for core; PLT/DevOps for full algebra) |
| Collection construction | `Type.new()` + `let mut` required for mutation. No split types, no literal-only | 5-0 |
| Display interpolation requirement | Strict: `{expr}` requires `T: Display` at compile time. No fallback, no auto-synthesis. Built-ins have compiler-provided impls | 5-0 |
| Display desugaring mechanism | Two-phase: type checker verifies `T: Display`, codegen optimizes built-ins to format specifiers, emits `Display.display()` for user types | 5-0 |
| Display and Query[C] interaction | Display is Str-context only. `Query[C]` interpolation passes raw typed values as parameters, not Display-stringified strings. Compiler-known param type set | 5-0 |
| FFI pointer type model | `Ptr[T]` non-null default, `Ptr[T]?` for nullable via `Option`. `Void` opaque type for `Ptr[Void]`. No const/mut distinction | 4-1 (Sys/Web/PLT/DevOps for B; AI for A) |
| FFI pointer operations | Minimal + deref/write/null: `alloc_ptr`, `as_cstr`, `addr`, `deref() -> Option[T]`, `write(T)`, `is_null()`, `null_ptr[T]()`, `to_str()` | 5-0 |
| FFI pointer lifetime | Scoped `ffi.scope()` via Closeable integration. `scope.take()` for ownership transfer. Standalone `alloc_ptr` with GC finalizer as fallback | 3-2 (PLT/DevOps/AI for scope; Sys/Web for hybrid) |
| Error identification scheme | Names primary (PascalCase, frozen), codes secondary compact alias. `error[NonExhaustiveMatch]` in terminal, both in JSON | 3-2 (PLT/DevOps/AI for names; Sys/Web for hybrid) |
| Error code organization | Category-based numeric ranges (E00xx pattern matching, E01xx traits, E03xx types, E05xx effects, etc.) | 4-1 (Web/PLT/DevOps/AI; Sys for clean-up-current) |
| Error code collisions | Reassign unique IDs to all colliding codes. 8 reassignments across 4 spec sections | 5-0 |
| Error catalog format | Table with name, code, one-line, category, spec ref. Deferred `--explain` for detailed explanations | 4-1 (Sys/PLT/DevOps/AI; Web for full Rust-style explain now) |
| Error catalog location | Standalone `ERROR_CATALOG.md` at repo root | 5-0 |
| Machine output format | JSON stays. Panel voted 3-1-1 for JSON+TOON flag, but deferred — JSON is required regardless, TOON ecosystem too immature. Revisit when token-optimized formats have tooling parity | Deferred (3-1-1 panel vote recorded) |
| Package registry model | Hybrid: central registry + git URL fallback. Identity invariant: registered package has one identity regardless of access path | 5-0 |
| Package naming | Namespaced `org/name` format. Maps to trust boundaries for capability auditing | 4-1 (AI: flat names for LLM accuracy) |
| Version resolution algorithm | Minimal Version Selection. Oldest satisfying version. Deterministic without lockfile. No SAT solver | 4-1 (Web: maximal/latest for dev expectations) |
| Version constraint syntax | Caret default (`"1.2"` = `>=1.2, <2.0`). Tilde/exact available. Pre-1.0: minor is breaking | 4-1 (Sys: tilde default for tighter control) |
| MVP dependency sources | Path + git deps for v1. No registry infrastructure required. Schema forward-compatible for v2 registry | 5-0 |
| Stdlib resolution mechanism | Implicit dependency model. `std.*` prefix. Stdlib bundled with compiler, injected as virtual deps. No new resolution step | 4-1 virtual dep, 3-2 `std` prefix, 3-2 stdlib-as-dep |
| Module-level let duplicates | Compile error. No shadowing, no silent dedup | 5-0 |
| Module-level pub let | `pub let` (immutable) allowed. `pub let mut` forbidden | 5-0 |
| Shadowing scope rules | Function-local allows shadowing, module-level does not | 5-0 |
| Import compilation model | Emit-all: importing any item includes all module definitions in C output. Separate compilation deferred to v2 | 5-0 |
| Pub enforcement | Enforced at compile time. Using non-pub item from outside module is a compile error | 5-0 |
| C symbol naming | Module-qualified for ALL items: `pact_module_name_fn` format. No flat names | 5-0 |
| Name resolution: symbol table | Annotated AST — typecheck decorates nodes with resolution results, codegen reads decorations | 5-0 |
| Name resolution: method timing | Two-phase — name binding first, then type-aware method resolution. Methods are type-directed, not name-directed | 5-0 |
| Name resolution: error recovery | Accumulate all name errors, halt before codegen. Codegen never sees unresolved names | 4-1 (DevOps: continue through all phases with poison) |
| Name resolution: module scoping | Module-scoped symbol table. Each declaration tagged with source module. pub enforcement structural | 4-1 (Sys: flat scope with pub checking) |
| `?` operator: validation phase | Type checking phase. Codegen never sees invalid `?` usage. Phase gate architecture | 5-0 |
| `?` operator: operand types | Both `Result[T, E]` and `Option[T]`. No cross-type mixing | 5-0 |
| `?` operator: error type match | Exact structural match (`E1 == E2`). Consistent with no-auto-into vote. Use `.map_err()` | 5-0 |
| `?` operator: error codes | Separate codes: E0502 (invalid operand), E0508 (Result in non-Result fn), E0509 (Option in non-Option fn), E0512 (error type mismatch) | 5-0 |
| JSON codec: dynamic vs typed | Both `json.parse()` (dynamic) and `json.decode[T]()` (typed) as equal peer entry points | 4-1 (PLT: dynamic primary) |
| JSON codec: API surface | Medium 5 functions: parse, stringify, pretty, decode[T], encode[T] | 4-1 (PLT: minimal 3) |
| JSON codec: navigation returns | Option-returning methods on JsonValue (`.get() -> Option[JsonValue]`, `.as_str() -> Option[Str]`, etc.) | 5-0 |
| JSON codec: deserialization path | Two-step canonical: parse → JsonValue → T.from_json(). `json.decode[T]` is sugar composing the two | 5-0 |
| Net.Connect: method surface | Single `request(req)` core operation + HTTP verb default methods (`get`, `post`, etc.) | 4-1 (AI/ML: verbs only) |
| Net.Connect: request config | `Request` builder struct with `.with_header()`, `.with_timeout()` method chaining | 4-1 (Web: options struct) |
| Net.Connect: Response type | Transparent struct `{ status: Int, body: Str, headers: Map[Str, Str] }` with trait methods | 5-0 |
| Net.Connect: WebSocket | Deferred to v2. HTTP request/response only in v1 | 4-1 (Web: separate sub-effect) |
| Net.Listen: server API | Minimal value-server: `net.listen()` → `Server`, `.route()`/`.get()`/`.post()`, `server.serve()`. Go/Flask-style | 3-2 (Sys/Web/AI for A; PLT/DevOps for C: route table) |
| Net.Listen: middleware | Functional wrapping: `fn(handler) -> handler`. Compose by nesting. `.use()` for global middleware | 4-1 (Sys/Web/DevOps/AI for A; PLT for B: effect stacking) |
| Net.Listen: error recovery | Typed error handler: `ServerError { HandlerPanic, Timeout, Internal }` + configurable `error_handler` on Server and per-route | 3-2 (Sys/PLT/DevOps for C; Web/AI for B: effect-based) |
| Net.Listen: @requires auto-400 | Validation effect: compiler generates `validation.contract_violation()`. Default handler returns 400 JSON. Swappable via `with` | 4-1 (Sys/Web/PLT/DevOps for B; AI for A: implicit route marker) |
| Time value type (Instant) | Stdlib opaque `Instant` struct in `std.time` Tier 2. Nanosecond precision. Methods not operators | 5-0 |
| Duration type | Stdlib `Duration` struct in `std.time` Tier 2. Named constructors (`Duration.seconds(5)`). Methods not operators | 5-0 |
| Bytes type | Stdlib `Bytes` in `std.bytes` Tier 1. Contiguous buffer, not `List[U8]` | 5-0 |
| Numeric extensions | F32 built-in (sized numeric family), Decimal in `std.decimal` Tier 2, BigInt in `std.math` Tier 2. Sealed arithmetic not extended | 5-0 |
| UUID type | Stdlib `UUID` in `std.uuid` Tier 2. 128-bit nominal type, not Str. `UUID.random() ! Rand` | 5-0 |
| Env.Read operations | Standard: `args()`, `var()`, `vars()`, `cwd()`. No `home()`/`exe_path()` v1 | 5-0 |
| Env.Write operations | Standard: `set_var()`, `remove_var()`. No `set_cwd()` (process-global footgun) | 4-1 (AI: minimal set_var only) |
| env.exit() placement | Under Env as `env.exit(code) -> Never`. Requires `! Env` (parent). Effect-tracked, handler-interceptable | 5-0 |
| Env sub-effect granularity | Keep Env.Read + Env.Write. No separate Env.Args, no flattening | 5-0 |
| Env return types | Simple: `env.var() -> Option[Str]`, `env.args() -> List[Str]`. Non-UTF-8 lossy-converted. No dual API | 5-0 |
| Const expression scope | Literals + arithmetic + boolean + comparison ops. No function calls, no method calls. Purity does not imply constness | 5-0 |
| `const` keyword | Required. `const NAME = expr` distinct from `let`. Explicit phase annotation. `let` at module level is runtime-initialized | 3-2 (PLT/DevOps/AI for `const`; Sys/Web for inferred `let`) |
| Const struct/enum literals | Struct literal syntax and enum variant construction are const when all fields are const. `Type.new()` is NOT const | 3-1-1 (PLT/DevOps/AI for B; Web for C nested; Sys for A scalars) |
| Const codegen strategy | Compiler evaluates const expressions during compilation, emits result as C literals. No `#define`, no compound literals | 5-0 |
| Web-service stdlib: JSON codec | Tier 1 — ships with compiler. `JsonValue`/`Serialize`/`Deserialize` already compiler-known; codec completes the semantic loop | 5-0 |
| Web-service stdlib: HTTP client | Tier 2 — blessed separate package. Effect types (Request/Response) are compiler-known; convenience layer (retry, redirects, pooling) versions independently | 3-2 (Sys/DevOps/AI for T2; PLT/Web for T1) |
| Web-service stdlib: HTTP server | Tier 2 — blessed separate package. Server frameworks are opinionated and evolve faster than compilers | 5-0 |
| Web-service stdlib: SQL/DB | Tier 2 — blessed separate package. Database drivers are backend-specific; `Query[C]` and `db.*` effect handles are already compiler-known | 5-0 |
| Web-service stdlib: Logging | Tier 2 — blessed separate package. `io.log()` effect handle is the T1 primitive; structured logging is policy above capability | 4-1 (DevOps dissented: default IO.Log handler should be T1) |
| Web-service stdlib: Config | Tier 2 — blessed separate package. `std.toml` + `env.var()` cover basics; config merging/validation is opinionated | 5-0 |
| Module-level `let mut` mutation | Compiler write-set inference (not an effect). Tracks which `let mut` bindings each function writes, fully automatic. Cross-module statefulness via user-defined effects (§4.12) | Round 1: 5-0. Round 2 (PLT/Systems/AI): 3-0 |
| Collection mutation via params | No effect required for v1. GC aliasing is real but tracking it approaches borrow-checker territory. Defer to v2 | 5-0 |
| Closure capture mutation | No effect required. Lexically scoped, visible in enclosing function body | 5-0 |
| `@i` annotation | Merged into `///`. First line of doc comment is queryable intent. `@i` removed from annotation system | 5-0 |

---

## Trait Coherence — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions. All votes unanimous.

**Q1: Orphan rules (5-0 for strict)**

- **Systems:** Strict. Evidence-passing requires exactly one vtable per (Trait, Type). Orphan ambiguity would require runtime dispatch or link-time deduplication. Newtype workaround covers the practical cases.
- **Web/Scripting:** Strict. Haskell's orphan instances are a well-known disaster. Two packages defining `impl Display for HttpResponse` and any program importing both breaks silently. The newtype pattern is a small price for deterministic behavior.
- **PLT:** Strict. Global coherence is a syntactic property under the orphan rule (package ownership), not a whole-program semantic analysis. This keeps compilation fast and decidable. Relaxing later is backwards-compatible; tightening is not.
- **DevOps:** Strict. LSP go-to-definition on a trait method needs exactly one impl target. Orphan impls mean the impl could be anywhere in the dependency graph. Strict rule bounds the search to two packages.
- **AI/ML:** Strict. LLMs generating `impl Trait for Type` need one clear rule: "is this my trait or my type?" Binary check, zero ambiguity. Orphan impls would require the model to reason about which package owns what across the entire dependency graph.

**Q2: Impl overlap (5-0 for no overlap, no specialization)**

- **Systems:** No overlap. Specialization sounds useful but Rust has kept it unstable for over a decade with multiple soundness holes. Each (Trait, Type) pair maps to one vtable entry. Zero runtime ambiguity.
- **Web/Scripting:** No overlap. "Most specific wins" rules are never intuitive. Adding an impl to a library silently changing behavior in downstream code is the opposite of locality of reasoning.
- **PLT:** No overlap. Specialization requires a partial ordering on impls that interacts with type inference in subtle ways. Without specialization, adding a new impl can only cause overlap errors (loud), never silent behavior changes. The helper-trait and newtype workarounds are compositional.
- **DevOps:** No overlap. Overlap errors at the impl site are actionable ("these two impls conflict, choose one"). Specialization errors are baffling ("this impl was silently superseded by a more specific one three dependencies deep").
- **AI/ML:** No overlap. One impl per (Trait, Type) is the only pattern with significant training data (Rust stable). Specialization has near-zero training data (Rust nightly only). LLMs would generate overlapping impls and be confused by the resolution rules.

**Q3: Impl placement and visibility (5-0 for package-scoped, auto-visible)**

- **Systems:** Package-scoped. The impl must live in the trait's package or the type's package — follows directly from the orphan rule. Within a package, any module is fine. Intra-package cycles are already allowed (§10.5).
- **Web/Scripting:** Package-scoped with auto-visibility. Requiring explicit impl imports would be boilerplate torture. Importing `User` should give you all of `User`'s behavior. This matches how JS/TS modules work — import a class, get all its methods.
- **PLT:** Package-scoped. Auto-visibility is the only principled choice: an impl is a fact about a (Trait, Type) pair, not an independent entity to be imported. The compiler discovers impls by following the import graph — importing either the trait or the type is sufficient.
- **DevOps:** Package-scoped. For LSP, "find all impls of Trait for Type" has a bounded search: check the trait's package and the type's package. Auto-visibility means go-to-definition never fails because of a missing impl import.
- **AI/ML:** Package-scoped with auto-visibility. Zero-boilerplate discovery. An AI importing a type should immediately be able to call all its trait methods without hunting for impl import paths. One import, complete behavior.

---

## While/Loop — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions.

**Q1: `while` vs `loop` vs both (3-2 for both)**

- **Systems:** Both share the same IR lowering. `while` and `loop` express different *intent* — conditional vs unconditional. `while true` adds a dead constant that communicates nothing. Event loops, server accept loops are conceptually infinite.
- **Web/Scripting:** `while` only. Every JS/TS/Python dev knows `while`. `while true` for infinite is immediately readable. `loop` as separate keyword violates Principle 2. *(dissent)*
- **PLT:** Both. `while` and `loop` have different typing — `while` may execute zero times (type `()`), `loop` without reachable `break` diverges (type `Never`). Collapsing them forces special-casing `while true` in the type checker.
- **DevOps:** Both. Linter can warn on `while true` → suggest `loop`. LSP can offer context-appropriate snippets. Two constructs, two distinct intents.
- **AI/ML:** `while` only. `while` is dominant in training data across Python/JS/Java/C/Go. `loop` is basically Rust-only. Models frequently fumble Rust's `loop`. *(dissent)*

**Q2: Break-with-value (3-2 for plain break)**

- **Systems:** Break-with-value. Polling/retry/search loops all produce a value. Without `break expr`, forced into `let mut` + assign — the declare-then-assign antipattern expression-oriented design exists to eliminate. *(dissent)*
- **Web/Scripting:** Plain break. Break-with-value is alien to web devs. `let mut` + assign + `break` is universal and obvious.
- **PLT:** Break-with-value. If `if/else` and `match` are expressions, `loop` should be too. Without it, unnecessary mutation to work around a missing semantic feature. *(dissent)*
- **DevOps:** Plain break. Break-with-value is a diagnostic nightmare — compiler must verify all break paths return compatible types. YAGNI for v1.
- **AI/ML:** Plain break. `break expr` is a Rust-ism LLMs get wrong constantly. Plain break matches Python/JS/Java/C/Go training data.

**Q3: Labeled breaks (4-1 no labels)**

- **Systems:** No. Rare need, extract-to-function handles it. Labels can be added in v2 without breaking changes.
- **Web/Scripting:** No. In 15+ years, can count on one hand. Nested loops needing coordinated exit is a code smell.
- **PLT:** No. Labels add continuation points that interact with algebraic effects — semantics get hairy. Extract a function.
- **DevOps:** Yes. Retry-with-timeout (outer=timeout, inner=retry), polling multiple endpoints. `@outer` reuses annotation sigil. *(dissent)*
- **AI/ML:** No. Rare in training data. Models routinely botch label placement. Extract-to-function is more common and correctly generated.

**Q4: `while let` (5-0 reject)**

- **Systems:** No. Same construct as rejected `if let`. Interacts awkwardly with potential future break-with-value.
- **Web/Scripting:** No. Consistent with `if let` rejection. `loop { match ... }` is explicit.
- **PLT:** No. Pattern matching should live in `match`. Adding `while let` after rejecting `if let` would be inconsistent.
- **DevOps:** No. One fewer special form for formatter, linter, and LSP. `loop + match` is more flexible.
- **AI/ML:** No. Rust/Swift-specific syntax with thin training signal. LLMs frequently generate wrong destructuring patterns.

---

## If/Else as Expressions — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions. All votes unanimous.

**Q1: Expression-based if/else (5-0 for "always expression")**

- **Systems:** Maps to SSA phi nodes cleanly. Eliminates uninitialized-variable bugs from declare-then-assign. One construct, one lowering strategy.
- **Web/Scripting:** Eliminates need for a separate ternary operator (Principle 2). TS devs already fake this with ternaries — expression if/else is cleaner.
- **PLT:** Only clean option type-theoretically. Dual-mode would require defining `if` twice in typing rules. All ML-family languages get this right.
- **DevOps:** One rule for formatter/linter/LSP. Dual mode means context-dependent formatting and ambiguous diagnostics.
- **AI/ML:** Universal rule = more reliable LLM generation. Dual system forces model to track whether if/else appears in value-consuming position — subtle contextual reasoning that causes generation errors.

**Q2: Else mandatory when value used (5-0)**

- **Systems:** Type unification is compile-time only, zero runtime cost. Option wrapping creates implicit type complexity and hidden allocations.
- **Web/Scripting:** Forgetting else is a constant JS/TS bug source (implicit `undefined`). Compiler-enforced completeness when value matters.
- **PLT:** Conditional without else is a partial function. Implicit `Option[T]` wrapping adds monadic lifting into core syntax unnecessarily.
- **DevOps:** Trivial linter rule: value-producing if must have else. Catches real bugs mechanically. Auto-Option wrapping creates diagnostic ambiguity.
- **AI/ML:** When LLM produces `let x = if cond { 5 }`, it almost certainly forgot else — that's a bug, not intentional Option wrapping.

**Q3: No `if let` for v1 (5-0 reject)**

- **Systems:** Sugar over two-arm match — backend doesn't care. Smaller surface area = better for compiler simplicity.
- **Web/Scripting:** Two ways to pattern match = inconsistency in large codebases. If single-arm match feels verbose, that's tooling, not language.
- **PLT:** Pattern matching should live in one syntactic construct for exhaustiveness checking and type narrowing.
- **DevOps:** Every new syntax form multiplies formatter edge cases, LSP completions, and linter patterns.
- **AI/ML:** `if let` is a constant source of LLM syntax errors in Rust (forgetting `=`, wrong destructuring). One mechanism = more training signal per pattern.

**Q4: Parentheses forbidden, not optional (5-0)**

- **Systems:** Fewer grammar productions = simpler parsing, fewer ambiguities, faster parse times.
- **Web/Scripting:** Forbidding (not optional) prevents formatting inconsistency — optional means half the team uses them.
- **PLT:** Condition unambiguously delimited by `if` and `{`. Optional parens = two parse trees for same program.
- **DevOps:** Optional parens directly undermines `pact fmt` canonical formatting — formatter must either normalize (diff churn) or preserve (inconsistency).
- **AI/ML:** Models trained on mixed corpora randomly include/omit optional parens. Forbidding eliminates a decision point = one fewer error.

---

## Keyword Arguments & Defaults — Design Rationale

### Problem Statement

Positional-only parameters create two classes of problems:

1. **Same-typed parameter swap bugs.** `transfer(from, to, amount)` where `from` and `to` are both `Account` — positional-only means a swap is type-correct but semantically wrong. LLMs swap same-typed positional args at 3-8% per call site.

2. **API evolution brittleness.** Adding a parameter to a positional-only function breaks every caller. Without defaults, the most common API evolution (adding an optional parameter) is always breaking.

### Cross-Language Survey

- **Python**: Full keyword args + defaults. Hugely popular but creates positional-or-keyword ambiguity, mutable default gotcha, `*args/**kwargs` untypeable black holes.
- **Swift**: External/internal param names. Best-in-class readability but dual naming is complex.
- **Kotlin**: Named args + defaults. Clean but "two ways to call" violates Principle 2.
- **Rust**: No keyword args, no defaults. Builder pattern workaround. #1 requested feature in surveys.
- **Go**: No keyword args, no defaults. Functional options pattern. Widely considered an ergonomics failure.

### Decision: Declaration-Site `--` Separator

The function author decides which params are positional and which are keyword. The caller has no choice.

```pact
fn transfer(amount: Int, -- from: Account, to: Account) -> Result[Transaction, BankError]
transfer(300, from: alice, to: bob)
```

**`--` separator won 3-1-1** (3 for `--`, 1 for `;`, 1 for `*`). `--` is the most visually distinctive, hard to confuse with any Pact syntax. `;` triggers statement-terminator instinct in AI. `*` (Python precedent) was considered too subtle.

**Labels as call-site sugar won 5-0 (unanimous).** Function type is `fn(Int, Account, Account)` regardless of `--`. Keeps closures and HOFs simple. No label propagation tracking needed.

### Decision: Struct Field Defaults

Struct fields can declare compile-time constant defaults. Primary config and API evolution mechanism.

```pact
type ServerConfig {
    host: Str = "0.0.0.0"
    port: Port = 8080
    debug: Bool = false
}
ServerConfig { port: 3000 }  // host and debug use defaults
```

Adding a field with a default is always backwards-compatible.

### Decision: Reject Function Parameter Defaults

Function param defaults interact with closures, HOFs, and partial application. Struct field defaults cover the same use cases with less type system complexity.

---

## Resource Cleanup — Design Rationale

### Problem Statement

Section 5.1 hand-waved "defer/drop semantics" without specifying them. Effect handlers manage DI'd resources (connection pools, FS capability) but not individual resources acquired within a function. The `?` operator causes early returns that skip cleanup code — the same problem that motivated Python's `with`, Go's `defer`, and Rust's `Drop`.

### Cross-Language Survey

| Language | Mechanism | Strengths | Weaknesses |
|----------|-----------|-----------|------------|
| Python | `with X as Y` + `__enter__`/`__exit__` | Scoped, familiar to LLMs | Two dunder methods, context manager protocol verbose |
| Go | `defer` | Simple, one keyword | Forgettable, no type signal, resource stays in scope after cleanup |
| Rust | `Drop` trait + RAII | Automatic, zero overhead | Tied to ownership system Pact doesn't have |
| Java | `try-with-resources` + `AutoCloseable` | Trait-based, scoped | Verbose syntax, bolted onto exception system |
| C# | `using` + `IDisposable` | Clean syntax | Requires explicit `IDisposable` cast in some cases |
| Swift | `defer` | Simple | Same problems as Go's defer |

### Proposals Considered

**Proposal A: `Closeable` trait + `with...as`** (selected)
- Single compiler-known trait signals resource-holding types
- `with...as` guarantees cleanup on all exit paths
- Reuses existing `with` keyword; `as` disambiguates from effect handlers
- Scopes the resource — cannot escape the block

**Proposal B: `defer` statements**
- `let f = fs.open(path)?` then `defer f.close()`
- Forgettable — no type signal, compiler can't warn when you forget
- Two steps to manage one resource
- Resource stays in scope after logical cleanup point

**Proposal C: Lint-only approach**
- Warn when `Closeable` values aren't closed
- No enforcement mechanism — easy to ignore
- No scoping guarantees

### Decision: Proposal A (3-0)

Why not `defer`:
1. **Forgettable** — no type signal, compiler can't warn when you forget
2. **Two steps** — acquire then defer, vs single `with...as` construct
3. **Principle 2** — adds a second resource management mechanism alongside `with`
4. **Training data** — `with X as Y` is Python (dominant in LLM training data); `defer` is Go/Zig (smaller representation)
5. **Scope leaking** — `defer` leaves the resource in scope after cleanup; `with...as` scopes it

---

## Codegen Backend & Bootstrap — Design Rationale

### Problem Statement

Pact compiles AOT to native binaries (§5.1, §6.1). The compiler will be self-hosted (written in Pact). Three questions:
1. What does the compiler emit to produce native code?
2. How does the self-hosted compiler bootstrap?
3. How are algebraic effects compiled?

### Options Considered

| Backend | Pros | Cons | Used by |
|---------|------|------|---------|
| **Emit C → cc** | Simplest, cross-compile for free, WASM via emscripten, every platform C supports | Two-phase compilation slower, no native stack maps | Nim, Chicken Scheme, Zig (stage1), Vala |
| **LLVM IR → llc** | Best optimization, wide targets | 500MB+ dep, SSA complex to emit, version churn, slow compilation | Rust, Swift, Julia, Crystal |
| **Cranelift (FFI)** | Fast compilation, self-contained | Fewer targets, no WASM output, FFI from Pact to Rust lib, less mature | Wasmtime, rustc (experimental) |

### Decision: Emit C (4-1)

**Phase 1 (v1.0):** Emit C, shell out to system cc/gcc/clang.
**Release builds:** `clang -O2` gives LLVM optimization without a separate backend.
**Phase 2 (optional, post-v1):** Evaluate Cranelift for self-contained builds if "needs cc installed" becomes a real user complaint.
**LLVM as standalone backend: rejected.** Massive dependency, version churn, no panel support.

### Algebraic Effects: Evidence-Passing Translation (Koka model)

Effects are compiled away *before* codegen via Koka-style evidence-passing (Leijen, ICFP 2021):
- Each effect type → slot in evidence vector (vtable of function pointers)
- Evidence vector threaded as hidden parameter
- **Tail-resumptive handlers** (common case in Pact) → direct function pointer call, zero overhead
- **Non-resumptive handlers** → return from handler function
- **One-shot resumptive handlers** → yield bubbling (heap-allocated continuation, rare)
- Backend never sees effects — just structs and function calls

Pact restricts to **one-shot continuations** (like OCaml 5). Multi-shot not required by spec.

### GC Integration: Shadow Stack (v1)

Generated C uses shadow stack for GC root tracking:
- Function prologue/epilogue registers/deregisters GC roots
- ~5-10% overhead on pointer-heavy code
- Escape analysis (§5.3) eliminates most roots (stack-allocated values skip shadow stack)
- Precedent: Go used shadow stack through v1.4 at production scale
- Upgrade path: LLVM backend could use statepoints for zero-overhead precise scanning

### Green Threads: Runtime Library (C)

M:N scheduling is a runtime concern, not codegen:
- C runtime library handles stack allocation/switching (ucontext/platform fibers)
- Compiler inserts cooperative preemption checks in function prologues
- Same model as Go

### Bootstrap Path (COMPLETE)

All three stages verified. Fixed-point proven across 6 generations.

```
Stage 0: Python compiler (legacy/py_bootstrap/pact/) ✓ [DEPRECATED]
         → compiles src/pactc.pact (Pact compiler written in Pact)
         → emits C → cc → gen1 native binary

Stage 1: gen1 (compiled by Stage 0, checked in at bootstrap/pactc_bootstrap.c) ✓
         → compiles src/pactc.pact → C → gen2 native binary

Stage 2: gen1 C output == gen2 C output → fixed point ✓
         → verified identical through gen6
         → bootstrap complete, Python interpreter no longer required
```

Self-hosting compiler: `src/pactc.pact` (amalgamated lexer + parser + codegen + driver). Uses parallel arrays instead of structs-in-lists (C backend limitation). Compiles hello, fizzbuzz, and itself.

### Panel Votes

- **Systems:** C primary. Shadow stack for GC. CPS + stack switching for effects. Optional LLVM later. Cranelift rejected (FFI coupling, insufficient targets).
- **PLT:** C primary. Evidence-passing makes backend irrelevant for effects. Koka proves it at scale. One-shot continuations only.
- **Web/DX:** Cranelift primary *(dissent)*. Wants Go-like zero-dep toolchain. Concedes C for bootstrap. Compilation speed concerns.
- **DevOps:** C primary. Ubiquitous toolchain. LLVM hard no. Optional Cranelift v1.x for self-contained builds.
- **AI/ML:** C primary. AI can write/debug/maintain C codegen easiest. Most training data. `clang -O2` for release = free LLVM optimization.

### Cross-Compilation & WASM

C backend delegates entirely to C compiler ecosystem:
- `CC=aarch64-linux-gnu-gcc pact build` → ARM64
- `CC=emcc pact build --target wasm32` → WASM
- `CC=x86_64-w64-mingw32-gcc pact build` → Windows
- `CC=musl-gcc pact build` → static musl binary

### References

- Leijen, "Type Directed Compilation of Row-Typed Algebraic Effects" (ICFP 2021) — evidence-passing
- Koka language (github.com/koka-lang/koka) — production evidence-passing to C
- Chicken Scheme — continuations in C via "Cheney on the MTA"
- Nim — production self-hosted compiler emitting C

---

## Iterator Protocol — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 5 questions.

**Q1: Single-method vs multi-method Iterator (3-2 for single)**

- **Systems:** Multi-method (next + size_hint). `size_hint()` enables pre-allocation in `collect()` and `Vec::extend`. Critical for performance-predictable iteration. *(dissent)*
- **Web/Scripting:** Single. JS `[Symbol.iterator].next()` returning `{value, done}` maps to `Option[T]`. `has_next()` creates awkward double-call state. Training data strongly favors single-method.
- **PLT:** Multi-method (next + size_hint). Pragmatic extension that enables fusion without breaking the semantic model. *(dissent)*
- **DevOps:** Single. One required method means simpler derive macros, cleaner LSP completions, better error messages. Size hints can be added later as optional overrides.
- **AI/ML:** Single. Dominant pattern across Rust/Python/JS training data. Split methods require LLMs to coordinate two calls, increasing error rates.

**Q2: IntoIterator separation (5-0 for separate)**

- **Systems:** Separate. Collections shouldn't be consumed by iteration. Fresh cursor each time.
- **Web/Scripting:** Separate. JS distinguishes iterables (`[Symbol.iterator]()`) from iterators (`.next()`). Two loops over same list must both work.
- **PLT:** Separate. Conflating collection with traversal state is a category error. Semantically crucial.
- **DevOps:** Separate. Better error messages: "Vec does not implement Iterator, did you mean `for x in vec`?"
- **AI/ML:** Separate. Clear conceptual boundary LLMs can learn. Matches Rust's ubiquitous pattern.

**Q3: Lazy by default (5-0 for lazy)**

- **Systems:** Lazy. Only model compatible with zero-cost abstractions. `.map().filter().take(10)` on a million elements must not allocate intermediates.
- **Web/Scripting:** Lazy. Modern JS/Kotlin lazy chains are the right default. Token-efficient for AI generation.
- **PLT:** Lazy. Composes with fusion optimizations. Explicit `collect()` gives control.
- **DevOps:** Lazy. Prevents accidental quadratic behavior. Makes pending transformations visible in type signatures.
- **AI/ML:** Lazy. Produces token-efficient pipelines. LLMs excel at fluent chain generation.

**Q4: Adapter method placement (5-0 for default methods)**

- **Systems:** Default methods. Implement `next()`, get combinators free. Performance overrides still possible.
- **Web/Scripting:** Default methods. Web devs expect `.map()` to "just work". Minimum friction.
- **PLT:** Default methods. Natural home for combinators. Mirrors Haskell typeclasses.
- **DevOps:** Default methods. Derive macros trivial (generate `next()` only). One canonical documentation location.
- **AI/ML:** Default methods. Minimizes what LLMs must generate. Heavily represented in training data.

**Q5: Effectful iteration (3-2 for defer to v2)**

- **Systems:** Effects in v1. Effectful iteration is fundamental (file lines, DB cursors). Deferring creates compatibility chasm. *(dissent)*
- **Web/Scripting:** Defer. Async iteration in JS is a separate protocol because mixing has nasty edge cases. Get the simple case right first.
- **PLT:** Effects in v1. Evidence-passing means effectful iterators are just monomorphizations. No runtime burden. *(dissent)*
- **DevOps:** Defer. Effects on lazy iterators add compiler complexity (when does `! IO` fire?). Avoid half-solutions.
- **AI/ML:** Defer. Effectful iterators have virtually no training data. LLMs would hallucinate syntax. Ship pure, add effects when usage patterns emerge.

---

## Type Conversions (From/Into/TryFrom) — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 5 questions.

**Q1: From[T] trait shape (5-0 for single method)**

- **Systems:** Single method `fn from(value: T) -> Self` compiles to a single function pointer in evidence-passing, zero overhead. Into should be auto-derived, not user-implementable — two user-facing traits doubles vtable surface for no gain.
- **Web/Scripting:** Web devs are used to `String(x)`, `Number(x)` style conversion. One method, one direction, dead simple. Auto-derive Into for `.into()` ergonomics but never let users implement it directly.
- **PLT:** Single method is correct. Manual Into would allow incoherent pairs (A: Into[B] without B: From[A]), breaking the categorical dual.
- **DevOps:** Single method, clean. If Into exists as a writable trait, you get two places to look when debugging "why did this conversion happen." LSP should show "derived from From[X] for Y" on hover.
- **AI/ML:** Single method cleanest for LLM generation. Into creates "two ways to do the same thing" — models trained on Rust constantly confuse From vs Into. *(Dissent: wants no Into at all — but 4-1 for auto-derive.)*

**Q2: TryFrom existence and error type (5-0 exists; 3-2 for fixed ConversionError)**

- **Systems:** TryFrom should exist with generic error parameter `TryFrom[T, E]`. A single ConversionError is a runtime-typed escape hatch that undermines the type system. *(Dissent on error type.)*
- **Web/Scripting:** Yes to TryFrom. Concrete ConversionError is fine — don't over-engineer without associated types. A single error type carrying a message is plenty.
- **PLT:** TryFrom yes, but parameterize E on the trait itself: `TryFrom[T, E]`. A fixed ConversionError becomes a god-type that loses information. *(Dissent on error type.)*
- **DevOps:** TryFrom should exist with fixed ConversionError. Per-impl error types create boilerplate cascade — every TryFrom needs a custom error, every call site needs a From impl for that error.
- **AI/ML:** Fixed ConversionError is better than Rust's associated-type approach for LLMs — models frequently botch the error type. One concrete error type = one pattern to learn.

**Q3: Numeric conversion mechanism (4-1 for both methods and traits)**

- **Systems:** Both. Named methods for primitives — discoverable, compile to single instructions. Plus From/TryFrom impls for generic programming. Complementary, not redundant.
- **Web/Scripting:** Both. Named methods are autocomplete-friendly. But From impls needed for generic code.
- **PLT:** Both. Methods for readability, From/TryFrom for generic programming. Methods should be sugar over the trait machinery.
- **DevOps:** Both. LSP autocomplete on `my_int.to_` shows available conversions — that's the primary discovery mechanism. From/TryFrom enables generic conversion functions.
- **AI/ML:** Traits only, no named methods. Named methods create open-ended surface area LLMs hallucinate (`.to_float()` vs `.as_float()` vs `.to_f64()`). Having both violates "one way to do everything." *(Dissent.)*

**Q4: `?` auto-conversion on Err (4-1 for NO)**

- **Systems:** No. A language that rejected implicit conversions shouldn't have `?` silently calling `.into()`. Require exact match. `.map_err()` is explicit and greppable.
- **Web/Scripting:** No. Auto-conversion on `?` is one of Rust's most confusing features for newcomers. Explicit `.map_err()` is more verbose but readable and obvious. Start strict, loosen later.
- **PLT:** No. Makes inference harder — compiler must solve From constraints at every `?` site. Degrades error messages. Violates explicit-over-implicit philosophy.
- **DevOps:** Yes. The spec already showed this pattern. Invest in diagnostic quality — generate "implement From[X] for Y" suggestions and LSP quick-fix actions. *(Dissent.)*
- **AI/ML:** No. LLMs handling Rust's `?` with implicit `.into()` is a mess — models generate code that compiles only because of hidden From impls they didn't reason about.

**Q5: Generic From-bounded code (5-0 valid)**

- **Systems:** Basic bounded polymorphism. Evidence-passing handles it naturally. Standard orphan rules ensure at most one From[Str] impl per type.
- **Web/Scripting:** Standard generic programming, would be bizarre to disallow. Invest in good error messages when the bound isn't satisfied.
- **PLT:** Sound. T determined at call site, coherence maintained. Standard return-type polymorphism.
- **DevOps:** No tooling concerns. LSP can resolve T.from to the From trait and show all satisfying types on hover.
- **AI/ML:** Clean, well-constrained, LLMs generate reliably. Bound makes contract explicit.

---

## Import Resolution — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions.

**Q1: Search path algorithm (5-0 for single `src/` root)**

- **Systems:** Deterministic resolution with zero env-dependent state. `import foo.bar` → `src/foo/bar.pact`, done. One stat call. Configurable source roots create shadowing bugs that only manifest in CI with different directory layouts.
- **Web/Scripting:** Go proved single-root works. Python's sys.path is a legendary footgun — "works on my machine" is 90% a path problem. One folder, one rule.
- **PLT:** Resolution must be a total function from module path to file. Single root gives `resolve(path) = src/ ++ path.replace(".", "/") ++ ".pact"`. Configurable roots make resolution partial — first-match is nondeterministic if two roots contain the same module name.
- **DevOps:** LSP go-to-definition must be instant and unambiguous. Single root = path rewrite. Multiple roots = scan and handle shadows. Workspaces can be layered later without breaking single-root.
- **AI/ML:** LLMs generate imports by pattern matching. `import auth.token` → `src/auth/token.pact` is a mechanical rewrite the model learns instantly. Configurable roots mean the model must read `pact.toml` to resolve — extra context dependency that increases error rates.

**Q2: Cycle handling (4-1 for intra-package OK, cross-package error)**

- **Systems:** Intra-package cycles are natural — `auth.login` needs `auth.types`, and `auth.types` may reference errors from `auth.login`. Forcing extraction into a third module is artificial ceremony. Cross-package cycles are genuinely pathological.
- **Web/Scripting:** Strict no-cycles is frustrating in practice — hit it in Go constantly. Two files in the same directory should reference each other without extract-to-avoid-cycle gymnastics. Cross-package cycles are a real design smell.
- **PLT:** Within a package, the compiler resolves all declarations before checking bodies — standard ML-module semantics. Cross-package cycles would require recursive module resolution which is complex and rarely needed.
- **DevOps:** Strict cycles everywhere. Cycles within a package still make the dependency graph messy for incremental compilation — daemon can't recheck one module without rechecking the other. Forces clean layering. *(dissent)*
- **AI/ML:** LLMs generating multi-file modules naturally create cross-references between files in the same package. Forcing strict no-cycles means the model must plan extraction ahead of time — a planning task that increases error rates.

**Q3: Diamond dependencies (4-1 for exactly one version per package)**

- **Systems:** One version per package. Multiple versions in one binary break global state, type identity across versions, and FFI symbols. Go's minimum version selection is the right model.
- **Web/Scripting:** The "one version" constraint is why Go has dependency hell at scale. SemVer-compatible dedup gives flexibility — `http 0.5.1` and `http 0.5.3` can coexist as `http 0.5.3`. *(dissent)*
- **PLT:** Type identity requires one version. If `auth` uses `http.Response` from http 0.6 and `myapp` expects `http.Response` from http 0.5, these are distinct types. The compiler must reject this or insert hidden conversions (which Pact already rejected).
- **DevOps:** `pact.lock` has one version per package. Resolution is deterministic. Multiple versions → "which version did this bug come from?" diagnostic nightmare.
- **AI/ML:** LLMs don't reason about semver. They import `http.Response` and assume one definition. Multiple versions mean generated code might reference the wrong version's API silently.

**Q4: Re-exports (5-0 for `pub import`)**

- **Systems:** `pub import` is clean, explicit, and compiles to nothing — it's a namespace alias. Without re-exports, every consumer must know internal module structure. Adding a file forces downstream import changes.
- **Web/Scripting:** Every modern JS package has an `index.js` barrel file. `pub import` is the typed, explicit version. Without it, refactoring (moving a type between internal modules) breaks every consumer's imports.
- **PLT:** Re-exports are module-level abstraction — the module signature is independent of internal layout. Standard in ML, OCaml, Haskell.
- **DevOps:** LSP resolves `pub import` by following one redirect. Go-to-definition lands on the original declaration. Package-level re-exports mean the public API is visible in one file.
- **AI/ML:** `pub import auth.token.{Token}` is explicit and greppable. LLMs generate it mechanically. No re-exports forces models to track internal module structure — more context needed per import.

---

## Method Resolution — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions.

**Q1: Effect handle namespace — reserved vs shadowable (5-0 for reserved)**

- **Systems:** Reserved. Effect handles compile to evidence-vector slots — not variables, capability proofs. Shadowing would require checking handler-compatibility at every use site. Keep the invariant simple: handle name → evidence slot, always.
- **Web/Scripting:** Reserved. If a dev writes `let io = 5` inside a function with `! IO` and `io.println` silently breaks, the bug is incomprehensible. Effect handles must be sacred.
- **PLT:** Reserved. Handles are capability witnesses. The typing rule for `io.println(x)` checks that `IO.Print` is in the effect row — trivially correct when `io` is a fixed binding in a separate namespace. If shadowable, the type rule must verify the variable's type matches at every use.
- **DevOps:** Reserved. LSP go-to-definition on `io.println` should always jump to the effect operation signature, never to some local variable. If shadowable, go-to-definition becomes context-dependent.
- **AI/ML:** Reserved. LLMs would shadow effect handles by accident constantly — `io`, `db`, `fs` are common variable names in training data. Making them reserved eliminates an entire error class.

**Q2: Dot-call semantics — method-only or field-call too (5-0 for method-only)**

- **Systems:** Method-only. `x.foo()` should compile to a single vtable dispatch or direct call. If it can also mean "load field, then indirect call," the codegen has two paths. `(x.callback)(args)` is explicit and compiles to a load+call.
- **Web/Scripting:** Method-only. `obj.method()` means method call. `(obj.field)(args)` for callable fields is unusual but the case is rare. Parentheses make intent clear.
- **PLT:** Method-only. Separating field projection (`.foo`) from method dispatch (`.foo()`) in typing rules avoids needing a "field-or-method?" judgment form. `(x.foo)(args)` is explicit projection-then-application — two rules composed, not one ambiguous rule.
- **DevOps:** Method-only. LSP autocomplete for `x.` shows methods uniformly. If fields could be callable too, autocomplete must inspect field types to decide which get `()` appended.
- **AI/ML:** Method-only. In training data, `x.foo()` is overwhelmingly a method call. Same syntax for two semantics = generation errors. `(x.callback)(args)` has a distinct visual pattern.

**Q3: Multiple trait methods — error at impl site or call site (5-0 for call-site)**

- **Systems:** Call site. Two independent authors defining traits with the same method name is realistic. Preventing a type from implementing both kills composability. Qualified syntax `Trait.method(x)` at the ambiguous call site is the right fix.
- **Web/Scripting:** Call site. Blocking impls is too aggressive — you'd discover the problem when adding a dependency, not when writing code. Error at call site with "did you mean `TraitA.foo(x)` or `TraitB.foo(x)`?" is better DX.
- **PLT:** Call site. Forbidding at impl site violates the open-world assumption for traits. Types should be freely implementable for any trait whose contract they satisfy.
- **DevOps:** Call site. Error message can list both traits, show signatures, offer quick-fix to insert qualified form. Error at impl site gives "you can't implement this trait" with no actionable fix for third-party traits.
- **AI/ML:** Call site. Call-site errors happen where the AI is generating code and can immediately fix. Impl-site errors happen at definition time, far from where the AI is working.

**Q4: Inherent methods — yes or no (4-1 for no)**

- **Systems:** Yes. Inherent methods are essential for type-specific operations that don't belong to any trait. Forcing everything through traits creates artificial trait proliferation — one-method traits that exist only to give a type a method. *(dissent)*
- **Web/Scripting:** No. One way to define methods: in traits. No "should this be inherent or a trait?" decision. A one-method trait is fine — the overhead is one line.
- **PLT:** No. Inherent methods create silent priority over trait methods. Adding an inherent method to a type can change which code runs at existing call sites without any error. Without inherent methods, adding a trait impl can only cause ambiguity errors, never silent behavior change.
- **DevOps:** No. "Where is this method defined?" has one answer: in a trait impl block. LSP searches trait impls only. With inherent methods, LSP must also search `impl Foo { }` blocks.
- **AI/ML:** No. "All methods live in traits" is a single rule. One mechanism = one pattern = better generation accuracy. Consistent with Pact's rejection of alternatives everywhere.

---

## Test Syntax — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions. Each expert ran as a separate agent and returned votes without seeing other experts' reasoning.

**Q1: Test effect model — pure by default vs implicit effects (5-0 for pure)**

- **Systems:** Pure-by-default means zero hidden runtime cost. Implicit effects require the test runner to silently inject handler implementations — hidden behavior that Pact's effect system exists to eliminate. Pure tests are trivially parallelizable since the compiler knows they're side-effect-free.
- **Web/Scripting:** JS/Python devs are used to explicit test setup. A test that silently hits a real database is a footgun. `with mock_net(...)` is self-documenting. Worth more than saving one line of boilerplate.
- **PLT:** Implicit effects destroy the information content of the effect row and require the compiler to silently insert evidence the programmer never requested. Pure-by-default preserves compositionality — the principled Koka approach.
- **DevOps:** Best diagnostics. Compiler emits actionable errors: `test "fetch data" calls fetch() which requires !Net, no handler provided. Hint: wrap in 'with mock_net(...) { }'`. LSP can offer quick-fix.
- **AI/ML:** "Pure by default, opt-in with `with`" is one rule everywhere. Two different implicit-effect contexts (main vs test) forces LLMs to track which context they're in — bad at context-dependent behavior shifts.

**Q2: Assertion built-ins (4-1 for three: assert + assert_eq + assert_ne)**

- **Systems:** Three intrinsics compile to comparison + branch + panic-with-diagnostics. `assert_match` implies compiler needs to lower arbitrary pattern syntax into assertion diagnostics — significant codegen complexity. Three is manageable; four starts to smell like a framework.
- **Web/Scripting:** `assert`, `assert_eq`, `assert_ne` — the holy trinity. Every developer from every language expects these three. `assert_match` can wait.
- **PLT:** `assert_ne(a, b)` is literally `assert(a != b)` — zero expressive power added, violates Principle 2. Keep the trusted kernel small. Two primitives form a complete basis. Compiler could special-case `assert(a != b)` for better messages via syntactic analysis. *(dissent)*
- **DevOps:** Three autocomplete entries in LSP, clean and fast. `assert_match` has ugly diagnostics — pattern failure diffs are walls of text. Defer until someone designs good pattern diff formatting.
- **AI/ML:** `assert`, `assert_eq`, `assert_ne` are near-universal across training data. Three built-ins = high coverage, low hallucination surface.

**Q3: Test discovery & filtering (4-1 for name + path + annotation tags)**

- **Systems:** Tags are compile-time metadata, zero runtime cost — stripped with test bodies. Without tags, you get name conventions encoding structured data in unstructured strings, making build systems fragile. The annotation system already exists; tags are a trivial extension.
- **Web/Scripting:** Every real-world project needs `--tag unit` vs `--tag integration`. JS-land abuses filename conventions because the framework didn't give them tags. `@tags(...)` is dead simple and immediately familiar.
- **PLT:** Annotations are already in the language — `@tags(...)` introduces no new typing concerns. Tags provide an orthogonal classification algebra without conflating naming conventions with test categorization.
- **DevOps:** Every real CI pipeline needs structured tag filtering. `@tags(...)` fits existing annotation system. Test runner output groups by tag naturally. `pact test --json` includes tags for CI parsing.
- **AI/ML:** Tags are metadata LLMs consistently forget to add. Name/path filtering requires zero additional annotation. Naming conventions are what LLMs are good at. *(dissent)*

**Q4: Test scope — top-level only vs inside modules too (4-1 for inside modules)**

- **Systems:** Tests inside `mod { }` can access private items — test internal invariants without making them `pub`. Internal data structure invariants need rigorous testing and must NOT be public API. Top-level-only forces either making internals `pub` or adding `pub(test)` visibility.
- **Web/Scripting:** This is the Rust model and it's genuinely good. Being able to write tests next to the code they test, with access to private items, is one of Rust's best features. Strictly more capable than top-level-only.
- **PLT:** Module-scoped tests seeing private items is the correct typing rule for verification. The scoping rule is uniform: `test` inside `mod M` sees `M`'s private scope, same as `fn` inside `M`. No special cases.
- **DevOps:** Tests next to code, access private items. LSP shows code lens "Run test" above each block. Filter uses path prefix: `auth::verify works`.
- **AI/ML:** Flat file structures are far more reliable for LLMs. Nested placement adds an ambiguous decision point. Rust's `mod tests { }` is the counterexample — LLMs frequently mess it up. *(dissent)*

---

## Tuple Types — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions. All votes unanimous.

**Q1: Maximum arity (5-0 for cap at 6)**

- **Systems:** Cap at 6. Every tuple arity is a distinct struct in emitted C. Bounding at 6 keeps monomorphized trait impls small and fixed. Tuples beyond 3-4 smell like a struct that deserves a name.
- **Web/Scripting:** Cap at 6, already generous. Nobody asks "why can't I have a 13-tuple" — they DO ask "how do I remember what element 9 means."
- **PLT:** Tuples are an exception to Pact's nominal typing — anonymous structural products in a nominal world. The exception should be narrow. Cap pushes users toward better-designed named types.
- **DevOps:** Hover info stays readable, error messages stay clean. When someone hits the cap, the compiler emits "consider using a named struct" — a genuinely helpful diagnostic.
- **AI/ML:** Training data clusters at 2-3 elements. Cap forces structs for complex data, which LLMs handle better due to named fields carrying semantic info.

**Q2: 1-tuples (5-0 for no 1-tuple)**

- **Systems:** No 1-tuple. `(T)` is always parenthesized expression. A 1-tuple is isomorphic to its element — zero performance benefit, adds parser complexity.
- **Web/Scripting:** Every JS/Python dev has been burned by Python's `(x,)` vs `(x)` confusion. Don't make parentheses context-dependent.
- **PLT:** The 1-ary product is isomorphic to T in standard type theory. Trailing-comma syntax is a parsing hack with zero gain in expressiveness or soundness.
- **DevOps:** Eliminates an entire class of confusing diagnostics. Parser never has to guess intent when user types `(SomeType)`.
- **AI/ML:** LLMs get trailing comma `(T,)` wrong at measurably higher rates than almost any other syntax detail. Eliminating 1-tuples removes ambiguity entirely.

**Q3: Auto-derived traits (5-0 for full structural)**

- **Systems:** Full structural derivation. Tuples are anonymous product types — their value proposition is convenience. Lexicographic Ord matches every language with tuple ordering. Trait impls are trivially generated, zero cost beyond hand-written equivalent.
- **Web/Scripting:** "I returned `(status, count)`, why can't I sort a list of them?" is a question nobody should have to ask. Lexicographic ordering is what people expect.
- **PLT:** All five traits have canonical compositional interpretations on product types. Lexicographic Ord is the unique order compatible with product structure — mathematically canonical, not a design choice.
- **DevOps:** When a trait is NOT available, the compiler points at the specific element: "`Canvas` does not implement `Ord` (element .1 of tuple)." Omitting Ord artificially produces worse diagnostics.
- **AI/ML:** Matches Rust behavior, the largest source of typed-tuple training data. Missing traits create compile errors LLMs have no mental model for.

---

## Pattern Matching Grammar — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 5 questions. Each expert ran as a separate agent and returned votes without seeing other experts' reasoning.

**Q1: OR-patterns (5-0 for `|` separator)**

- **Systems:** OR-patterns compile to merged branches/jump tables — zero runtime cost. Duplicate arms make the optimizer deduplicate what the programmer already expressed. `|` is universally understood, trivially parseable.
- **Web/Scripting:** Every JS/Python dev who has touched Python 3.10 `match` knows `|` as "or" in type contexts. Comma-separated (C) would be a trap — Pact already uses commas inside tuples. `|` is unambiguous and Pact doesn't use it as a bitwise operator.
- **PLT:** OR-patterns mirror the algebraic sum type structure. The typing rule is well-studied: all alternatives must bind the same variables at the same types. This is a standard judgment in ML-family pattern calculi.
- **DevOps:** Universal syntax, LSP can offer "merge duplicate arms" quick-fixes, formatter has clear precedent from every language that supports it.
- **AI/ML:** Overwhelming training data signal from Rust, OCaml, Scala, Python 3.10, C#. LLMs will generate `|` in match arms regardless — better to accept it than produce confusing errors.

**Q2: Range patterns (5-0 for `..`/`..=`)**

- **Systems:** Range patterns = two comparisons, predictable branch. Without them, guards are opaque to exhaustiveness checker — compiler can't verify completeness or optimize dispatch. For integer-heavy matching (protocol codes, byte ranges), this matters.
- **Web/Scripting:** Guards are where developer productivity goes to die. `n if n >= 1 && n <= 5` is 21 tokens for something that should be `1..=5`. HTTP status code matching is a bread-and-butter web dev task.
- **PLT:** Exhaustiveness over discrete types with range patterns is decidable via interval arithmetic. Guards defeat the purpose of exhaustiveness checking — the compiler cannot reason about their truth. Range patterns preserve the safety guarantee.
- **DevOps:** Diagnostic goldmine. When a range match misses `256..=511`, the compiler can say exactly which interval is uncovered. Guards produce only "non-exhaustive, add wildcard" — useless.
- **AI/ML:** Fewer decision points than guards, reduces off-by-one bugs in generation. LLMs handle Rust range patterns reasonably well — decent training signal.

**Q3: Pattern binding (4-1 for `as` keyword)**

- **Systems:** `@` conflicts with annotation prefix — parsing ambiguity. `as` is already a Pact keyword, no new token. Binding+destructure is just aliasing a pointer/value — zero cost either way.
- **Web/Scripting:** Pact already uses `as` in `with...as`. It reads naturally: "match this config AS a ServerConfig with these fields." Python devs know `as` from `import x as y`. Meanwhile `@` is the annotation prefix — LLMs would hallucinate annotations inside match arms.
- **PLT:** `@` conflicts with the annotation sigil. The typing rule for `as` binding is trivial: bound name gets the scrutinee type. No interaction with the type system beyond standard variable introduction.
- **DevOps:** Context-dependent `@` is a diagnostic nightmare. Is `@foo` an annotation or a pattern binding? LSP go-to-definition, syntax highlighting, and error recovery all suffer. `as` has clear precedent.
- **AI/ML:** Pattern binding is rare — thin training data even in Rust. Fewer features = fewer decision points for LLM generation. Defer to v2. *(dissent)*

**Q4: Struct patterns in match (5-0 for full)**

- **Systems:** Gives the compiler complete visibility — direct field-offset comparisons vs opaque guard calls. Already have struct destructuring in `let`; refusing it in `match` is artificial and costs optimization opportunity.
- **Web/Scripting:** If I can destructure an enum, I should be able to destructure a struct. Field punning (`User { name, .. }`) is exactly how JS destructuring works and every web dev already knows it.
- **PLT:** Restricting struct patterns to `let` breaks compositional nested matching. `Ok(User { name, .. })` is a nested pattern — disallowing the struct layer while permitting the enum layer is unprincipled.
- **DevOps:** Inconsistency between `let` and `match` is a diagnostics anti-pattern. LSP can autocomplete field names in struct patterns, and error messages can point to specific non-matching fields.
- **AI/ML:** Rust has strong training data for struct patterns in match. LLMs handle `Struct { field, .. }` well from Rust exposure. Restricting to `let`-only contradicts what models have learned.

**Q5: Refutable vs irrefutable (5-0 for strict compile error)**

- **Systems:** `let` that can fail = hidden panic = unpredictable codegen. Strict separation means `let` always succeeds (no hidden branches, no dead panic code), `match` handles all refutable logic. Clean CFG.
- **Web/Scripting:** JS devs have been burned by "undefined is not a function" for decades. `let Some(x) = val` panicking at runtime is exactly the "works in dev, crashes in prod" bug Pact's type system prevents. The language already rejected `if let` — allowing refutable `let` would be backdooring it as a runtime panic.
- **PLT:** Refutable `let` is type-theoretically unsound — it introduces a partial function into a total context. Non-negotiable. Pattern is irrefutable iff it covers all values of the scrutinee type; single-variant enums are naturally irrefutable by this definition.
- **DevOps:** Compile error + actionable fix is the gold standard. `"refutable pattern in let, use match or ?? instead"` with a code suggestion. Warnings get ignored — developers tune them out.
- **AI/ML:** Binary rules (error vs not-error) are easiest for LLMs. Warnings are invisible during generation — the model doesn't see them in compile output. Errors feed back into iterative fix cycles.

---

## `Self` Type — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions.

**Q1: Where is `Self` valid (5-0 for trait decls + impl blocks only)**

- **Systems:** `Self` is resolved at monomorphization — it's a placeholder the compiler substitutes. Only meaningful where there's a "current implementing type." Free functions have no implementing type.
- **Web/Scripting:** TS `this` type works exactly this way — valid in class/interface bodies, nowhere else. Familiar rule.
- **PLT:** `Self` is a type variable bound by the trait/impl quantifier. Outside that scope, it's unbound — standard scoping rules.
- **DevOps:** LSP go-to-definition on `Self` jumps to the impl header's type. If `Self` appeared in free functions, where does it point? Nowhere useful.
- **AI/ML:** Clear binary rule: inside trait/impl = valid, outside = error. LLMs handle binary rules well.

**Q2: `self` keyword sugar (5-0 for sugar, literal `self` required for methods)**

- **Systems:** `self: Self` is the mechanical truth. Sugar saves tokens. Requiring literal `self` for dot-call dispatch means the compiler checks one name, not arbitrary parameter names.
- **Web/Scripting:** Python's explicit `self` parameter is beloved for clarity. Sugar makes it concise without hiding it. `this: Self` not enabling `.method()` prevents confusion.
- **PLT:** Method dispatch keyed on a syntactic marker (`self`) rather than positional convention avoids the fragile "first parameter is special" rule that Python has.
- **DevOps:** Formatter and LSP can reliably identify methods (has `self`) vs associated functions (no `self`). No heuristics needed.
- **AI/ML:** `self` as first param = method is the dominant pattern in training data. Enforcing it eliminates a class of generation errors where models name it `this` or `s`.

**Q3: `Self` in construction position (4-1 for type-position only)**

- **Systems:** Type-position only. `Self { ... }` in a default method doesn't know field names — traits don't see struct internals. Would require trait-level field visibility, massive complexity.
- **Web/Scripting:** Allow `Self { ... }` construction. Factory methods (`fn default() -> Self { Self { x: 0 } }`) are common. Requiring the concrete name defeats the purpose of writing generic defaults. *(dissent)*
- **PLT:** Type-position only. `Self` as constructor in a trait default method would require the trait to know the representation of all implementing types — breaks parametricity.
- **DevOps:** Type-position only. Error message is clear and actionable: "use the concrete type name." LSP can auto-fix.
- **AI/ML:** Type-position only. `Self` as constructor is rare in training data (Rust allows it but it's uncommon in default methods). Simpler rule = fewer generation errors.

**Q4: `self` passing semantics (5-0 for always by-value)**

- **Systems:** GC handles memory. No ownership distinction means no `&self`/`&mut self`. One form, zero decisions. The runtime manages sharing.
- **Web/Scripting:** By-value is what every GC language does. JS, Python, Java, Go — `self` is a reference under the hood but passed "by value" at the language level. Natural.
- **PLT:** Pact has no reference types. The type system has no `&T` or `&mut T`. Introducing by-reference `self` would require adding reference types to the language — rejected design direction.
- **DevOps:** One calling convention. No "should this be `&self` or `&mut self`?" decisions at every method. Eliminates entire category of Rust-style borrow checker diagnostics.
- **AI/ML:** Rust's `&self`/`&mut self`/`self` triple is the #1 source of trait impl errors in LLM-generated code. Single form eliminates the decision entirely.

---

## Closure Capture Semantics — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions.

**Q1: Capture mode — shared reference vs by-value vs inferred (3-2 for shared reference)**

- **Systems:** By-value (Option A). In a GC'd language, "by value" for heap objects means copying a pointer — 8 bytes, one register copy. Closure struct with flat fields, populated by copying locals. No indirection cells, no boxing. `let mut` snapshotted at closure creation. *(dissent)*
- **Web/Scripting:** By-value (Option A). Snapshotting mutable bindings is far more predictable than sharing them. Python's late-binding closure semantics are the single most common closure footgun. *(dissent)*
- **PLT:** Shared reference (Option B). In a GC'd language with no reference types, all bindings are GC-managed handles. Snapshotting `let mut` is a semantic trap — `count += 1` inside a closure silently mutates a copy, producing wrong results with no compiler error. Every GC'd language (OCaml, Koka, JS, Python, C#) uses shared-reference captures. For immutable bindings, shared-ref is observationally equivalent to by-value copy. The capture mode is not part of the function type.
- **DevOps:** Inferred (Option C). Immutable by-value, mutable by-ref. But acknowledged that C and B produce identical observable behavior for all cases. Critical requirement: LSP must show capture modes on hover.
- **AI/ML:** Shared reference (Option B). ~70% of closure training data (JS + Python + Go) uses shared-reference semantics. By-value silently breaks the `count += 1` mutation pattern — a silent logic bug is the worst outcome for LLM-generated code. Inferred (Option C) has zero training data for the specific inference rules; Rust's inferred capture is the #1 source of LLM errors in Rust closures.

**Q2: Explicit capture syntax (4-1 for no explicit syntax)**

- **Systems:** No syntax. If everything is always by-value, nothing to disambiguate. YAGNI. *(Note: voted for by-value in Q1, but no-syntax still applies under shared-ref — one mode = nothing to annotate.)*
- **Web/Scripting:** No syntax. Principle 2 — one way to do everything. GC'd languages don't need capture annotations.
- **PLT:** No syntax. GC eliminates the primary reason for explicit captures (Rust's `move` exists for ownership transfer; Pact has no ownership). The snapshot-via-`let` idiom covers edge cases. `move` can be added backward-compatibly in v2 if needed.
- **DevOps:** `move` keyword (Option B). Users need an escape hatch when inference is wrong. `move fn(params) { body }` forces all captures to by-value. One keyword, one behavior. `pact fmt` just puts `move` before `fn`. *(dissent)*
- **AI/ML:** No syntax. Explicit capture has ~40% LLM error rate in Rust/C++. One mode = nothing to annotate. Zero additional decision points.

**Q3: `async.spawn` mutable captures (3-2 for compile error)**

- **Systems:** Auto-copy (Option B). Falls naturally from by-value capture. `async.spawn` copies GC pointer into closure. Both tasks hold GC roots. Zero additional overhead. *(dissent)*
- **Web/Scripting:** Auto-copy (Option B). Spawned task gets own copies. No shared mutable state between tasks. Like `structuredClone` for web workers. *(dissent)*
- **PLT:** Compile error (Option A). `async.spawn` with shared mutable captures creates data races. Pact has no `Mutex`, no `Atomic`, no memory model for concurrent mutation of shared cells. Allowing this would be unsound. Immutable captures are fine — no data race potential.
- **DevOps:** Compile error (Option A). Silent correctness bugs are worst for tooling. Compile error E0650 with machine-applicable fix (snapshot via `let`, use channel, or use `Atomic[T]`). Error message should include quick-fix.
- **AI/ML:** Compile error (Option A). Data races are the #1 concurrency bug in LLM code. The compile error pushes LLMs toward the fork-join pattern (more training data, more correct). Immutable captures in spawn should be fine.

---

## Module Prelude — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions. Each expert ran as a separate agent and returned votes without seeing other experts' reasoning.

**Q1: Which types belong in the prelude (3-1-1 for types + ADTs + traits)**

- **Systems:** Full set including ConversionError, Range, Handler (Option D). Every type in A through D is already compiler-intrinsic. The compiler must know their layout, vtable shape, and monomorphization behavior. Forcing imports for items the compiler already knows about adds zero information and wastes tokens. *(dissent — wanted D)*
- **Web/Scripting:** Types + ADTs only, no traits (Option B). Every mainstream language makes primitives and core collections available without imports. But traits in the prelude go too far — they're an intermediate concept newcomers shouldn't need to encounter in the prelude. *(dissent — wanted B)*
- **PLT:** Types + ADTs + traits (Option C). `==` desugars to `Eq.eq`, `<` to `Ord.cmp`, `for` through `IntoIterator`/`Iterator`, interpolation through `Display`, `@derive` references traits by name. If these traits aren't in scope, every file needs boilerplate imports for basic language features. Stops at C because `ConversionError`, `Range`, `Handler` are used by specific subsystems, not core typing rules.
- **DevOps:** Types + ADTs + traits (Option C). LSP autocomplete for `x.` needs all compiler-known traits in scope to show methods. Error messages referencing `Eq` or `Ord` should never say "did you forget to import Eq?" — that's a broken diagnostic experience. `ConversionError`/`Range`/`Handler` are importable without degrading day-to-day tooling.
- **AI/ML:** Types + ADTs + traits (Option C). Every import is a failure point for LLMs. Primitive types + core traits have near-100% usage in training data without imports. Forcing imports for `Int` or `Eq` would create a pattern with zero training data. ConversionError/Range/Handler are niche enough to import.

**Q2: `true`/`false` — keywords or prelude values (5-0 for keywords)**

- **Systems:** Keywords. The compiler emits direct boolean instructions — no vtable, no trait resolution, no name lookup. Making them keywords reflects what the hardware sees.
- **Web/Scripting:** Keywords. In every language web devs know, boolean literals are keywords. `let true = 5` should give "cannot use keyword as identifier," not a confusing shadowing error.
- **PLT:** Keywords. `true` and `false` are introduction forms for `Bool`, like `42` for `Int`. They participate in exhaustiveness analysis. The lowercase spelling already signals "keyword, not constructor" — Pact constructors are PascalCase.
- **DevOps:** Keywords. Keywords get syntax highlighting for free. No "unknown identifier" errors. No import needed. Clean diagnostic story.
- **AI/ML:** Keywords. `true`/`false` are keywords in 95%+ of training data. Zero ambiguity, zero decision points.

**Q3: Test builtins — auto-available or require import (5-0 for auto-available)**

- **Systems:** Auto-available. Test builtins are compiler intrinsics — `assert_eq` needs source locations and display values at compile time. They're not library functions. Test code is dead-code-eliminated in release builds regardless.
- **Web/Scripting:** Auto-available. Jest, pytest, Go testing — all have built-in assertions. Requiring imports adds ceremony to the simplest tests. Cap auto-available set at these four; richer testing utilities require imports.
- **PLT:** Auto-available. `test` blocks are a special syntactic form with their own scoping rules. `assert`/`assert_eq`/`assert_ne` are observation forms of the testing judgment — they need no import, same as `match` needs no import for pattern elimination.
- **DevOps:** Auto-available. The compiler already knows about test blocks. Built-in assertions should produce compile errors when used outside test blocks — this requires compiler awareness, not library code. LSP can show "only available in test blocks" hints.
- **AI/ML:** Auto-available. In training data, test assertions are never imported. LLMs would forget the import at high rates. Zero-friction test authoring is critical for adoption.

---

## Effect Polymorphism — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions.

**Q1: Should function types carry effects? (5-0 for explicit effects)**

- **Systems:** The evidence vector is already threaded through every call. If a callback performs effects, that must be in the type so the compiler knows which vtable slots to pass. Hiding it makes C codegen unpredictable. Pure-only means you can't even log inside a map callback — non-starter.
- **Web/Scripting:** Web devs live and breathe HOFs — map, filter, forEach, middleware. If callbacks can't carry effects, the most natural JS/TS patterns become second-class citizens. TypeScript proved function types need full expressiveness. The `!` syntax is consistent with declarations — no new concept.
- **PLT:** A function type that cannot express its effects is unsound by construction. In Koka, Frank, and every serious effect calculus, the arrow type carries an effect row because `fn(T) -> U` and `fn(T) -> U ! IO` have fundamentally different denotations. Omitting effects from function types means the type system cannot express the contract of any HOF accepting effectful callbacks — a compositionality failure.
- **DevOps:** Explicit `! IO.Log` on function types is a massive win for LSP hover and diagnostic quality. When a user hovers over a callback parameter, the tooltip should show exactly what effects it can perform. Invisible semantics would make hover info misleading. Explicit syntax gives the formatter a clear layout rule.
- **AI/ML:** LLMs generate more correct code when syntax is uniform and local. If `fn foo() -> Int ! IO` works at declaration sites but `fn(Int) -> Int` silently drops effects at type sites, that's two rules where there should be one. Every special case increases error rates.

**Q2: Form of effect polymorphism (3-2 for wildcard forwarding)**

- **Systems:** Row-polymorphic effect variables. For C codegen, `e` compiles to "pass through whatever evidence sub-vector the caller provided." Monomorphizer specializes at call sites. Wildcard loses composability — can't distinguish effect sets from two different callback parameters. *(dissent)*
- **Web/Scripting:** Wildcard `_`. Row polymorphism is theoretically correct but `fn map[T, U, e](f: fn(T) -> U ! e) -> Iterator[U] ! e` will make web developers close the tab. The `_` is familiar from TypeScript's `any` and Rust's `_` patterns. Covers the 95% case without requiring developers to understand effect variables.
- **PLT:** Row polymorphism. The only approach that preserves principal types and decidable inference. Wildcard `_` cannot unify two wildcards from different parameters, which breaks `zip_with(f, g)` where both callbacks must share the same effect set. Give the variable a name; it costs one generic parameter and buys full expressiveness. *(dissent)*
- **DevOps:** Wildcard `_`. Row polymorphism produces horrific error messages — effect variable unification errors are nearly impossible for users to parse. `_` covers the 95% case and produces actionable diagnostics. Incremental compilation benefits since `_` is a local marker rather than a constraint variable propagating through the call graph.
- **AI/ML:** Wildcard `_`. Koka-style effect variables have vanishingly small training data. Models will hallucinate variable names, forget to thread `e` through return types, or invent nonsensical combinations. `_` is a single token learnable from one example, doesn't introduce naming decisions (Principle 2), and doesn't require reasoning about effect unification.

**Q3: Timeline (4-1 for fn-type effects v1, polymorphism v2)**

- **Systems:** Full in v1. If function types ship without effect information, every HOF signature becomes a lie you have to break later. Retrofitting changes calling conventions and ABI. The compilation strategy is known. Deferring borrows complexity at loan-shark interest rates. *(dissent)*
- **Web/Scripting:** Fn-type effects v1, polymorphism v2. Ship the `fn(T) -> U ! IO` syntax now so the type system is complete. Don't block v1 on getting polymorphism perfect — iterate after real users hit real friction.
- **PLT:** Fn-type effects v1, polymorphism v2. Pragmatic concession. Shipping `fn(T) -> U ! E1, E2` means library authors can write monomorphic effectful callbacks today. The type system remains sound; you just lose generality. The critical invariant: do not ship v1 with pure-only function types, because retrofitting `!` onto arrow types is breaking, while adding effect variables is additive.
- **DevOps:** Fn-type effects v1, polymorphism v2. Gives LSP and diagnostics a solid foundation. Trying to ship both at once means half-baked tooling for effect variables at launch. Better to have solid tooling for a smaller feature set.
- **AI/ML:** Fn-type effects v1, polymorphism v2. The foundation (`fn(T) -> U ! IO.Log`) is simple enough to ship now and unblocks real patterns. Deferring everything means v1 ships with a known hole that forces workarounds which become the patterns LLMs learn and then have to unlearn.

---

## Handler Type System — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 5 questions.

**Q1: Handler[E] type identity (5-0 for generic type)**

- **Systems:** `Handler[E]` compiles to one vtable struct per effect. The type parameter is erased at codegen — at C level, `Handler[DB]` and `Handler[IO]` are different structs with different function pointer layouts. The generic type constructor is a source-level abstraction over effect-specific vtables. Correct and zero-cost.
- **Web/Scripting:** A single `Handler[E]` type makes the mental model simple — handlers are values, parameterized by which effect they handle. No need for separate `DBHandler`, `IOHandler` types. Matches how TypeScript generics work.
- **PLT:** `Handler[E]` is a type constructor indexed by effect declarations, analogous to `List[T]` indexed by types. The kinding rule is `Handler : Effect -> Type`. Standard parametric polymorphism over the effect namespace.
- **DevOps:** One type constructor means one autocomplete pattern, one hover format, one diagnostic template. LSP shows `Handler[DB]` uniformly regardless of which effect.
- **AI/ML:** `Handler[E]` is the pattern in every code example. LLMs already generate it correctly from existing spec examples. Formalizing what's already in practice.

**Q2: Effect subtyping on handlers (3-2 for implicit projection)**

- **Systems:** Implicit projection. `Handler[DB]` used where `Handler[DB.Read]` expected → compiler extracts `read` slot from the DB vtable and builds a projected handler. Not subtyping — a mechanical extraction. No runtime dispatch, no vtable indirection. Clean codegen.
- **Web/Scripting:** Covariant subtyping. If `DB > DB.Read` in the effect hierarchy, then `Handler[DB]` should be a subtype of `Handler[DB.Read]` — standard variance. Projection is an implementation detail that shouldn't leak into the mental model. *(dissent)*
- **PLT:** Implicit projection. True subtyping on handlers would require the type system to track variance of the handler type constructor with respect to effects — complexity that buys nothing over mechanical slot extraction. Projection is semantically transparent and verifiable.
- **DevOps:** Implicit projection. The compiler generates the projected vtable — users see a clean "OK" at the call site. Error messages for the reverse direction ("Handler[DB.Read] cannot satisfy Handler[DB]") are precise and actionable.
- **AI/ML:** Covariant subtyping. "DB is bigger than DB.Read, so Handler[DB] works where Handler[DB.Read] is needed" is the simplest mental model. LLMs reason about subtyping better than projection mechanics. *(dissent)*

**Q3: Generic handler parameters (4-1 for no generics v1)**

- **Systems:** No generics v1. Effect-kinded generics require a kinding system (`E: Effect`), monomorphization over effects, and interaction with evidence-passing. Doable but adds compiler complexity. Ship concrete handlers, add generics with named effect variables in v2.
- **Web/Scripting:** No generics v1. `Handler[DB]` and `Handler[IO]` are what people write. Generic-over-effect functions are a library-author concern, not a day-one need.
- **PLT:** Effect-kinded generics now. `fn apply_handler[E: Effect](h: Handler[E], f: fn() ! E)` is the principled way to write handler combinators. Without it, every handler combinator must be written per-effect, defeating the purpose of first-class handlers. *(dissent)*
- **DevOps:** No generics v1. Simpler LSP, simpler diagnostics. Concrete handler types are easier to display and reason about in tooling. Generics can be added without breaking changes.
- **AI/ML:** No generics v1. Effect-kinded generics have zero training data. LLMs would hallucinate syntax. Concrete handlers cover all practical v1 use cases (testing, DI, sandboxing).

**Q4: Handler storage (4-1 for full first-class)**

- **Systems:** Restricted. Handlers stored in long-lived data structures (struct fields, collections) risk holding stale vtable references if the handler's captured state is invalidated. Limit to local variables, function parameters, and `with` blocks. Storing in structs requires `'static`-like lifetime guarantee. *(dissent)*
- **Web/Scripting:** Full first-class. Handlers are GC-managed values — no dangling references by construction. Storing a handler in a struct field is identical to storing any other GC-managed value. Restricting storage would make the `TestEnv` pattern impossible.
- **PLT:** Full first-class. In a GC'd language, all values have the same storage semantics. Artificially restricting handler storage introduces a second class of values — exactly the complexity Pact rejected by choosing GC over ownership. Handlers are values; values can be stored anywhere.
- **DevOps:** Full first-class. The `TestEnv { db: Handler[DB], io: Handler[IO] }` pattern is the natural way to build test fixtures. Restricting it forces workarounds (factory functions, closures) that are strictly worse.
- **AI/ML:** Full first-class. Every GC'd language allows storing any value anywhere. Restrictions would be a novel pattern with zero training data, guaranteed to confuse LLMs.

**Q5: Handler completeness (5-0 for partial with auto-delegation)**

- **Systems:** Partial + auto-delegation. Most handler use cases override 1-2 operations (logging wrapper, restricted sandbox). Requiring all operations makes simple wrappers verbose. Auto-delegation to `default.op(args)` is the evidence-passing equivalent of prototype chain delegation — the enclosing handler's vtable slot is called.
- **Web/Scripting:** Partial + auto-delegation. Middleware pattern: override what you care about, pass through everything else. Express/Koa devs write `next()` constantly — `default.op(args)` is the same concept. Full completeness would make every handler as verbose as the full effect definition.
- **PLT:** Partial + auto-delegation. The handler algebra requires a default case for compositional reasoning — a handler that only overrides `read` should compose with any handler that provides `write` and `admin`. Auto-delegation provides this. Explicit `default.op(args)` remains available for custom forwarding logic.
- **DevOps:** Partial + auto-delegation. Compiler generates the forwarding code, zero boilerplate. Diagnostics can still warn when a handler overrides nothing (likely a mistake). LSP can show which operations are auto-delegated on hover.
- **AI/ML:** Partial + auto-delegation. LLMs generating test handlers will typically only mock the operations under test. Requiring completeness means the model must generate stubs for every operation — more tokens, more error surface, more maintenance burden when operations are added to an effect.

---

## Derive Mechanics + Clone Trait — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions. Resolves two Tier 2 gaps: "Derive mechanics" and "Clone trait".

**Q1: Clone semantics in GC context (3-2 for logical copy)**

- **Systems:** Logical copy (Option C). In a GC'd runtime, "clone" means allocate a new struct shell, copy field values (GC pointers). Deep copy is an O(n×m) allocation storm for nested collections with cycle risk. The C backend emits a single `malloc` + `memcpy` for struct fields — clean, predictable, zero recursion. If users need deep independence, a separate `DeepClone` trait with explicit recursion is the right tool.
- **Web/Scripting:** Logical copy (Option C). This is exactly JS's `{...obj}` spread or Python's `copy.copy()`. Web developers already understand one-level semantics — the clone shares nested references. This is the dominant pattern in GC'd languages and matches the largest body of LLM training data.
- **PLT:** Logical copy (Option C). In ML/OCaml tradition, record copy is structural — `{r with field = new_value}` copies the record, shares nested references. Deep copy is a separate concern requiring recursion schemes. The distinction is principled and well-understood in PL literature.
- **DevOps:** Deep copy (Option B). A `clone()` that doesn't give you an independent value is semantically vacuous — it's just aliasing with extra allocation. When you clone a config struct, you expect modifying the clone doesn't affect the original. Shallow clone violates the principle of least surprise. *(dissent)*
- **AI/ML:** Deep copy (Option B). Training data overwhelmingly associates "clone" with "independent copy." When an LLM generates `let backup = config.clone()` and then mutates `backup`, it expects isolation. Shallow clone causes aliasing bugs that are invisible at the call site. *(dissent)*

**Q2: Debug trait design (5-0 for separate trait)**

- **Systems:** Separate `Debug` trait with `fn debug(self) -> Str`. No supertrait relationship with `Display`. Debug emits structural representation (`TypeName { field: value }`), Display emits user-facing strings. At C level, separate vtable slots — no coupling. The compiler can optimize away unused Debug impls in release builds.
- **Web/Scripting:** Separate `Debug`. Maps to `console.log()` vs `.toString()` distinction in JavaScript. Developers expect one format for logging/debugging and a different one for user-facing output. No supertrait means implementing Display doesn't require Debug and vice versa.
- **PLT:** Separate `Debug`. Haskell's `Show` conflates both roles and regrets it. Rust's `Debug` vs `Display` split is one of its best ergonomic decisions. The structural representation is mechanical and derivable; the user-facing string requires human judgment.
- **DevOps:** Separate `Debug`. Structured logging needs consistent machine-parseable output. `Debug` gives `"User { name: \"Alice\", age: 30 }"` which tools can parse. `Display` gives `"Alice (alice@example.com)"` for humans. Different audiences, different traits.
- **AI/ML:** Separate `Debug`. LLMs generating debug output and user-facing output are clearly different tasks. Having them in separate traits means the model picks the right one from context. No ambiguity about which to call.

**Q3: Derive codegen algorithm (5-0 for inferred bounds + auto supertrait)**

- **Systems:** Inferred bounds. The compiler scans field types, collects trait requirements, emits `where` clauses. For `@derive(Eq)` on `Pair[A, B]`, field `first: A` needs `A.eq()` → emit `where A: Eq`. Supertrait auto-derivation: `@derive(Ord)` checks for existing `Eq` impl, derives one if missing. Mechanical, deterministic, zero user annotation.
- **Web/Scripting:** Inferred bounds. "It just works" — the developer writes `@derive(Eq)` and the compiler figures out the bounds. No manual `where` clauses on derived impls. This is TypeScript-level ergonomics applied to trait derivation.
- **PLT:** Inferred bounds with auto supertrait. This follows the standard derivation algorithm from Haskell/Rust: derive obligations propagate through field types and supertrait relationships. Sound and complete for the derivable trait set.
- **DevOps:** Inferred bounds. LSP can show the inferred bounds on hover. Error messages point to the specific field that can't satisfy the bound. Clean diagnostic story.
- **AI/ML:** Inferred bounds. LLMs write `@derive(Eq)` and move on. No need to think about generic constraints — the compiler handles it. Reduces token count and error surface.

**Q4: Error reporting for non-derivable fields (5-0 for field-level errors)**

- **Systems:** Report all failing fields in one pass. The compiler walks every field, collects failures, emits a single diagnostic with all of them. No "fix one, compile, find the next" loop. Batch error reporting matches the existing diagnostic strategy.
- **Web/Scripting:** All fields at once. TypeScript shows all type errors in one pass. Developers expect to see the full picture, not a drip feed.
- **PLT:** All fields. Standard practice — GHC, rustc, and OCaml all report multiple derivation failures in a single compilation unit.
- **DevOps:** All fields. CI pipelines get a complete error list in one build. No wasted cycles on iterative fix-compile cycles.
- **AI/ML:** All fields. An AI agent in a generate-compile-fix loop needs all errors at once to fix them in a single pass. Reporting one at a time forces O(n) compilation rounds for n failing fields.

---

## String Methods — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 5 questions. Resolves Tier 2 gap: "String methods".

**Q1: Trait organization (5-0 for generic Sized + StrOps)**

- **Systems:** Generic `Sized` trait. `.len()` and `.is_empty()` compile to one vtable slot per collection type. Sharing the trait across `Str`, `List`, `Map`, `Set` means one evidence-passing path for size checks in generic code. The `StrOps` catch-all avoids vtable fragmentation — one struct with all string function pointers, cache-friendly.
- **Web/Scripting:** Generic `Sized` + `StrOps`. Every web developer expects `.len()` to work the same way on strings and arrays. A shared `Sized` trait makes this intuition correct. `StrOps` as a single trait mirrors how Iterator works — one import, all methods available via LSP autocomplete.
- **PLT:** `Sized` as a generic trait is well-founded — it provides a uniform interface for the cardinality observation on finite containers. Separating it from `StrOps` respects the trait coherence model: `Sized` is implementable by any container, while `StrOps` is string-specific. This is the standard algebraic factoring.
- **DevOps:** `Sized` + `StrOps`. LSP autocomplete on `s.` shows `len()` and `is_empty()` from `Sized`, plus all string methods from `StrOps`. Two traits, clean categorization. Resolving the Collection methods gap simultaneously is a tooling win — `.len()` hover shows `Sized.len` for all types.
- **AI/ML:** Shared `Sized` trait matches training data where `.len()` works uniformly across collection types. One `StrOps` trait minimizes import decisions — LLMs don't need to choose which string trait to import. Follows the Iterator precedent that models already understand.

**Q2: v1 method surface area (5-0 for 15 existing methods)**

- **Systems:** Codify what exists. The self-hosting compiler already uses these 15 methods; each maps to a C runtime function. No speculative surface area — every method has a known caller. Adding methods later is additive; removing is breaking.
- **Web/Scripting:** The 15 existing methods cover the JS/Python string API core that web developers reach for daily. `trim_start`/`trim_end` and `pad_left`/`pad_right` are nice-to-have but not blocking — they can be added in a point release. Ship what's tested.
- **PLT:** Minimal committed API surface. Each method in the trait is a coherence obligation — every implementor must provide it. Starting with 15 well-understood methods minimizes the proof burden. Default methods can extend the surface later without breaking existing impls.
- **DevOps:** 15 methods = manageable autocomplete list. Expanded 22 would add noise. Every method in the spec needs LSP descriptions, error messages, and documentation. Ship the known set, extend based on friction logs.
- **AI/ML:** 15 methods match the common string operations in training data. Expanding to 22 adds methods with lower frequency in training data (`pad_left`, `repeat`) increasing hallucination risk for parameter order. The Iterator pattern proved that starting minimal and extending works.

**Q3: Unicode semantics (3-2 for codepoint-default dual API)**

- **Systems:** Byte-oriented defaults with honest names (Option D). `.len()` = `strlen()` is O(1) and maps to a single C call. Codepoint-length is O(n) — hiding that behind `.len()` violates the principle that simple syntax implies simple cost. Name the operations honestly: `.byte_len()`, `.byte_at()`, `.codepoint_at()`. *(dissent)*
- **Web/Scripting:** Dual API with codepoint default (Option C). Web developers think in characters, not bytes. Python, JavaScript (mostly), and Ruby all have codepoint-oriented `.length`. `.len()` returning bytes would surprise 90% of users — "hello" should have length 5, and "café" should have length 4, not 5. Byte access via `byte_` prefix for the rare cases that need it.
- **PLT:** Byte-oriented defaults with honest names (Option D). The type system should not lie about complexity. If `.len()` is O(n), that's a hidden cost the type signature doesn't reveal. Naming matters: `.byte_len()` is honest about what it counts, `.codepoint_count()` is honest about its cost. Option D preserves the correspondence between names and semantics. *(dissent)*
- **DevOps:** Dual API with codepoint default (Option C). Codepoint `.len()` matches what developers expect in diagnostics and error messages — "string has length 4" should mean 4 characters. The `byte_` prefix is clear and discoverable via LSP autocomplete. Performance-sensitive code can opt into byte methods explicitly.
- **AI/ML:** Dual API with codepoint default (Option C). Training data overwhelmingly associates `.len()` with character count. LLMs generating `if name.len() > 50` mean "50 characters" not "50 bytes." Byte-oriented default would cause systematic off-by-one bugs in every non-ASCII context. The `byte_` prefix is unambiguous and won't be hallucinated by models trained on Python/JS patterns.

**Q4: Parsing methods (4-1 for named methods on Str)**

- **Systems:** Named methods. `.parse_int()` compiles to a direct C function call — no vtable dispatch, no generic monomorphization overhead. The method name in the binary's symbol table is greppable. Delegating to `TryFrom` under the hood keeps the trait system consistent while giving call sites zero-cost direct dispatch.
- **Web/Scripting:** Named methods. `str.parse_int()` is exactly what Python's `int(str)` and JS's `parseInt(str)` developers expect, just in method-call form. LSP autocomplete on `s.parse_` shows available parse targets. Far more discoverable than `Int.try_from(s)` which requires knowing the target type has a `TryFrom` impl.
- **PLT:** TryFrom only (Option A). Named methods on `Str` create ad-hoc coupling — `Str` must know about `Int` and `Float` at definition time. `TryFrom` is parametric: the conversion knowledge lives with the target type, not the source. Adding `parse_int()` to `Str` violates the open-world assumption of trait-based dispatch. *(dissent)*
- **DevOps:** Named methods. `s.parse_` in autocomplete immediately shows `parse_int`, `parse_float` — zero lookup cost. `Int.try_from(s)` requires the developer to know both the target type and that `TryFrom` exists. Named methods are the discoverability sweet spot for tooling.
- **AI/ML:** Named methods. `s.parse_int()` is a single-token decision that models get right from Python/JS training data. `Int.try_from(s)` requires generating the correct target type first, then knowing the trait — two decision points. Generic `.parse[T]()` requires type inference context that models frequently get wrong.

**Q5: String building (5-0 for join now, StrBuf deferred)**

- **Systems:** `List[Str].join()` is O(n) with a single allocation — measure total length, allocate, copy. No intermediate allocations, no amortized realloc. `StrBuf` adds a mutable type to the language surface that requires growth-factor decisions and realloc strategy — defer until profiling data from real Pact programs shows it's needed.
- **Web/Scripting:** `.join()` is the pattern every web developer knows from `Array.join()`. It covers the 95% case (building strings from parts). `StrBuf` is a premature optimization for v1 — most programs build strings with interpolation and occasionally join a list. YAGNI, ship `join()`, add `StrBuf` when someone needs it.
- **PLT:** `List[Str].join()` is a fold with a separator — algebraically clean. It doesn't require new types or mutable state. `StrBuf` would be the first mutable non-collection type in the language, requiring design decisions about growth semantics and trait implementations. Defer to v1.1 when the design space is better understood.
- **DevOps:** `join()` now. One method, one signature, one autocomplete entry. `StrBuf` is an entire type with its own methods, its own documentation, its own error messages. Ship the simple thing, add complexity when the friction log demands it.
- **AI/ML:** `join()` has massive training data from every language. LLMs generate `parts.join(", ")` correctly at near-100% rates. `StrBuf` would be a novel type with zero training data — guaranteed hallucination target. Defer until there's enough Pact-specific training data to teach models the builder pattern.

---

## Collection Methods — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 5 questions. Each expert ran as a separate agent and returned votes without seeing other experts' reasoning.

**Q1: Trait organization — per-type vs generic shared vs hybrid (5-0 for hybrid: shared Contains + per-type)**

- **Systems:** Hybrid. `Contains[T]` is justified — containment has identical semantics across collections. But `Indexable[K,V]` or `Growable[T]` are false unifications: `List.get(Int)` and `Map.get(K)` have fundamentally different memory access patterns (contiguous vs hash lookup). Per-type traits let the C backend emit type-specific code without trait dispatch indirection for hot-path operations.
- **Web/Scripting:** Hybrid. Web devs expect `contains`/`includes` to work uniformly across collections — Python's `in`, JS's `.includes()/.has()`. Per-type for the rest because List, Map, and Set have genuinely different semantics (push vs insert-with-key); forcing them into shared abstractions creates leaky APIs.
- **PLT:** Hybrid. A pure per-type approach misses shared algebraic structure (the point of traits). Full generic conflates fundamentally different structures. `Contains[T]` is a legitimate shared predicate (membership testing is universal set-theoretic), while per-type traits handle operations with genuinely different signatures.
- **DevOps:** Hybrid. Shared `Contains[T]` is gold for tooling — LSP resolves `.contains(` once for all collections. Per-type traits keep autocomplete focused. Generic traits like `Indexable` produce confusing diagnostics: "type X doesn't implement Indexable" is harder to act on than "type X doesn't implement MapOps."
- **AI/ML:** Hybrid. Shared `Contains[T]` minimizes generation errors (most common LLM pattern: "is X in collection"). Per-type traits keep method discovery unambiguous — models don't confuse List methods with Map methods.

**Q2: List[T] method surface (3-2 for expanded: 12 methods)**

- **Systems:** 8 methods (Option A). `insert`/`remove` at arbitrary indices are O(n) on contiguous arrays — including them signals they're cheap when they're not. `index_of` and `last` are expressible via iterator methods already in the spec. Keep the core API tight. *(dissent)*
- **Web/Scripting:** 12 methods (Option B). `indexOf`, `splice`/`insert`, `remove`, and `last` are bread-and-butter operations in web code. Leaving them out means everyone writes the same helpers on day one.
- **PLT:** 8 methods (Option A). The 8-method surface covers core algebraic operations on sequences. `insert`/`remove` are O(n) and advertising them as first-class methods violates least-surprise regarding performance. *(dissent)*
- **DevOps:** 12 methods (Option B). `insert`, `remove`, `index_of`, and `last` are methods people reach for constantly. 12 methods is table stakes for a list type. Every time someone hand-rolls these, that's friction and a potential bug.
- **AI/ML:** 12 methods (Option B). LLMs trained on Python/Rust/JS constantly generate `insert`, `remove`, `index_of`, `last`. Omitting them causes hallucinated methods or verbose workarounds.

**Q3: Map[K,V] method surface (3-2 for expanded: 8 methods)**

- **Systems:** 6 methods (Option A). `entries` is sugar for what `IntoIterator` already gives (Map yields `(K, V)` tuples). `get_or_default` is one line with `??`. Six methods keep the vtable small and C codegen simple. *(dissent)*
- **Web/Scripting:** 8 methods (Option B). `entries` is used constantly when iterating maps, and `get_or_default` eliminates the most common Map boilerplate pattern (Python's `dict.get(k, default)`).
- **PLT:** 6 methods (Option A). Maps are finite functions K→V; 6 methods precisely capture CRUD plus canonical projections. `get_or_default` conflates two concerns better expressed as `map.get(k) ?? default`. *(dissent)*
- **DevOps:** 8 methods (Option B). `entries` is critical for iteration and debugging. `get_or_default` eliminates a massive class of "key not found" runtime errors.
- **AI/ML:** 8 methods (Option B). `entries` and `get_or_default` are extremely high-frequency LLM patterns. `get_or_default` eliminates the "check then get" anti-pattern models frequently generate incorrectly.

**Q4: Set[T] method surface (3-2 for core: 4 methods)**

- **Systems:** Core 4 (Option A). `union` is worth including because it's non-trivial to implement correctly in userspace. `intersection`/`difference` are expressible as iterator filter chains. Most code only uses `contains` and `insert`.
- **Web/Scripting:** Core 4 (Option A). Web developers rarely do set algebra beyond union. The 95% case is covered. Set algebra can be added later without breaking anything — YAGNI.
- **PLT:** Full algebra (Option B). Sets form a Boolean algebra under union, intersection, difference, and symmetric difference. Omitting these is like defining a numeric type without subtraction. *(dissent)*
- **DevOps:** Full algebra (Option B). If you're going to have a Set type at all, you need intersection and difference. Without them, developers will roll their own buggy versions. *(dissent)*
- **AI/ML:** Core 4 (Option A). Full set algebra appears rarely in generated code. Small surface means models are less likely to confuse method names and signatures.

**Q5: Construction and mutability (5-0 for `Type.new()` + `let mut`)**

- **Systems:** `Type.new()` + `let mut`. Mutability at the binding, not the type. C backend can emit `const` qualifiers for immutable bindings. Split types double the surface for no gain with GC. Literal-only makes empty construction awkward.
- **Web/Scripting:** `Type.new()` + `let mut`. Most familiar for devs from Rust/Swift/Kotlin, straightforward for JS/Python devs. Split types create confusion and double the API surface. Literal-only breaks the `Type.new()` pattern already in the compiler.
- **PLT:** `Type.new()` + `let mut`. Mutability is a property of the binding, not the type — same insight as ML's `ref`. Split types double the type surface and create trait coherence nightmares (do both implement `Sized`?). `Type.new()` has clear formal semantics.
- **DevOps:** `Type.new()` + `let mut`. LSP flags mutation on non-mut bindings at edit time. `let mut` is greppable, lintable. Split types double surface for autocomplete, docs, and errors. `Type.new()` is unambiguous for tooling.
- **AI/ML:** `Type.new()` + `let mut`. Most consistent with Rust-influenced training data. LLMs handle "declare mutable, then mutate" well. Split types doubles type vocabulary and confuses models.

---

## Display Format Protocol — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions resolving the Display trait format protocol gap (GAPS.md Tier 2). All votes unanimous.

**Q1: Display requirement for interpolation (5-0 for strict compile error)**

- **Systems:** Strict. `{expr}` is a trait call site — if the type doesn't impl the trait, it's a type error. Period. Auto-synthesis would make Display meaningless as a trait; you'd never know if a type's string representation is intentional or compiler-generated garbage. Built-in types get compiler-provided impls, same as `Eq` for `Int`.
- **Web/Scripting:** Strict. JavaScript's `toString()` auto-synthesis is a notorious source of `"[object Object]"` bugs. Requiring explicit Display means every type that appears in a string was consciously designed for it. `@derive(Display)` is one line — the cost of explicitness is negligible.
- **PLT:** Strict. Display is a semantic contract: "this type has a meaningful user-facing string representation." Auto-synthesis violates the contract — a compiler-generated string for an arbitrary type has no semantic content. Debug exists for the "just show me something" use case. Separate traits, separate purposes.
- **DevOps:** Strict. The error message (`type X does not implement Display`) is immediately actionable. The fix is one annotation. Auto-synthesis would mean Display output is never trustworthy in logs or user-facing strings — you'd always wonder if it's intentional or default garbage.
- **AI/ML:** Strict. LLMs trained on Rust know: missing trait → add derive or impl. This is a well-learned pattern. Auto-synthesis removes a signal the model uses to decide whether a type is "displayable." Explicit is better for code generation reliability.

**Q2: Compiler desugaring mechanism (5-0 for two-phase check+optimize)**

- **Systems:** Two-phase. The type checker treats `{expr}` as requiring `T: Display` — standard trait bound checking. But codegen doesn't need to emit a function call for `{42}` — `%d` in snprintf is correct and faster. The semantic guarantee (Display exists) is orthogonal to the codegen strategy (inline vs call). Rust does this exact optimization for built-in Display impls.
- **Web/Scripting:** Two-phase. Developers don't care about the desugaring mechanism — they care that `{42}` works and `{MyType}` requires Display. Two-phase gives both: clean semantics for the programmer, fast codegen for the runtime. Full trait dispatch for `{42}` would be silly overhead that the programmer can't even observe.
- **PLT:** Two-phase. Formally, `"{expr}"` desugars to `Display.display(expr)` concatenated into a string. The optimizer is free to replace `Display.display(42: Int)` with its known definition `snprintf(buf, ..., "%d", 42)` — this is standard inlining of known implementations. No semantic difference. The two-phase framing is just saying "the compiler is allowed to optimize known impls."
- **DevOps:** Two-phase. The current compiler already does this — snprintf with format specifiers for built-ins. Formalizing it means the spec matches the implementation. Full trait dispatch would require changing the existing working codegen for no benefit. Two-phase also means the LSP can show "Display.display() called here" in hovers without the runtime paying for virtual dispatch.
- **AI/ML:** Two-phase. The semantic model is simple for LLMs: "interpolation calls Display." The optimization is invisible to the programmer. LLMs generating Pact don't need to know about the codegen phase — they just need to know Display is required. Clean separation of concerns.

**Q3: Query[C] context interaction (5-0 for Display is Str-context only)**

- **Systems:** Str-context only. Query[C] parameterization passes raw typed values to the database driver — `Int` stays `Int`, not `"42"`. Calling Display first would serialize to Str, then the DB driver would have to parse it back. That's a round-trip through string representation that loses type information and adds a potential injection vector if the Display impl produces unexpected characters.
- **Web/Scripting:** Str-context only. This was already decided when we voted 3-0 for Query[C] phantom types. The entire point is that `{id}` in `Query[DB]` becomes a typed parameter `$1` with value `42: Int`, not a string `"42"`. Display-then-parameterize defeats the purpose. The compiler knows the context (Str vs Query) from the type annotation.
- **PLT:** Str-context only. Display's return type is `Str`. Query parameterization requires typed values. These are fundamentally different operations — one is presentation (type → string), the other is data binding (type → parameter slot). Conflating them is a type error in the formal sense. The context type (Str vs Query[C]) selects the interpolation semantics.
- **DevOps:** Str-context only. Database parameterized queries expect typed parameters for good reason — the driver can validate types, use binary protocols, prevent injection. If we Display-ify everything first, we lose all of that. The compiler already knows whether it's building a Str or a Query[C] from the type context. Two codepaths, clearly motivated.
- **AI/ML:** Str-context only. LLMs need one clear rule: "in Str context, Display; in Query context, parameterize." Two distinct behaviors selected by type context. If Display were invoked in both, models would be confused about when injection safety applies. The type-based dispatch is the simplest mental model.

---

## FFI Type Mapping — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions. Resolves Tier 3 gap: "FFI type mapping."

**Q1: Pointer type model (4-1 for non-null `Ptr[T]`, `Ptr[T]?` nullable)**

- **Systems:** Non-null default (Option B). Maps cleanly to `T*` in C. Null-checks at FFI boundaries are zero-cost for the non-null path. Separating const/mut adds type system complexity with no codegen benefit — C enforces const on its side, not Pact.
- **Web/Scripting:** Non-null default (Option B). Reuses the nullable pattern every TS/Kotlin/Swift dev already knows. `T` vs `T?` is universal. Option A (everything nullable) is C's footgun. Option C (const/mut) adds a concept nobody writing a wrapper cares about.
- **PLT:** Non-null default (Option B). Preserves the Curry-Howard correspondence Pact exploits via `Option[T]`. Nullability IS the partiality monad — encoding it in `Option` means existing elimination forms (`match`, `??`) compose with pointer types with zero ad-hoc rules.
- **DevOps:** Non-null default (Option B). Reuses existing `Option`/`?` diagnostic infrastructure. LSP hover can distinguish "guaranteed non-null" vs "may be null." Autocomplete surface stays small.
- **AI/ML:** Single nullable `Ptr[T]` (Option A). Zero decision points. LLMs generating FFI code already struggle with C pointer semantics; adding a nullability decision increases error rates. *(dissent)*

**Q2: Pointer operations (5-0 for minimal + deref/write/null)**

- **Systems:** Option B. Option A is too minimal — you'd need C shims for every pointer read/write. `deref()` and `write(T)` map to single load/store instructions in C. Option C's `cast[U]()` and `offset(Int)` are pointer arithmetic footguns in a GC'd language.
- **Web/Scripting:** Option B. Option A has no deref — can't read what a pointer points to. Option B has exactly the four things a wrapper author needs: read, write, null-check, null construction. Option C (`cast`, `offset`, `free`) are expert footguns.
- **PLT:** Option B. `deref` is correctly typed as partial — return MUST be `Option[T]`. Option A is practically unsound (can't inspect values without FFI round-trips). Option C's `cast[U]()` destroys parametricity — it's `unsafeCoerce` and cannot be given a sound typing rule.
- **DevOps:** Option B. Gives the compiler enough info to emit structured null-safety warnings. Option A has zero diagnostic story for null derefs. Option C's `cast`/`offset` create pointer arithmetic errors nearly impossible to diagnose well.
- **AI/ML:** Option B. Covers exactly the patterns LLMs reach for. Option A's 3-op minimum causes hallucination: the LLM "knows" deref should exist and will generate it anyway. Option C's full surface creates decision paralysis.

**Q3: Lifetime and cleanup (3-2 for scoped `ffi.scope()` via Closeable)**

- **Systems:** Hybrid (Option D). Two real FFI patterns: short-lived marshaling (scope/arena) and long-lived opaque handles (GC finalizer). Neither alone suffices. *(dissent)*
- **Web/Scripting:** Hybrid (Option D). "Don't think about it" (GC) for the common case, deterministic cleanup (`with` block) when C requires explicit free. Matches Python `with` and JS explicit resource management. *(dissent)*
- **PLT:** Scoped (Option C). Only choice giving lexically scoped lifetime — minimal structure for soundness without linear types. Composes with existing `Closeable`. `scope.take(ptr)` is the affine typing escape hatch. GC finalizers are unsound for ordered resources.
- **DevOps:** Scoped (Option C). Direct analog to existing `with-resource`/Closeable pattern. Reuses E0601 scope-escape diagnostics. Only option where the compiler can actually help catch leaks.
- **AI/ML:** Scoped (Option C). Maps to Python's `with`, Kotlin's `use`, C#'s `using`. LLMs generate correct scoped cleanup ~85% of the time vs ~70% for manual free. One pattern, high accuracy, zero decision points.

**Resolution:** Scoped `ffi.scope()` is the primary mechanism, with standalone `alloc_ptr` as a GC-registered fallback for trivial cases. This satisfies the Sys/Web concern (both patterns available) while maintaining the PLT/DevOps/AI preference for scope-first design.

---

## Error Catalog — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 5 questions. Resolves Tier 3 gap: "error codes referenced but no complete catalog."

**Q0: Identification scheme — names vs codes vs hybrid (3-2 for names primary)**

- **Systems:** Hybrid — both visible in terminal. Codes are searchable, greppable, copy-pastable. Names add value but shouldn't replace codes. *(dissent)*
- **Web/Scripting:** Hybrid — TS-familiar DX with both in output. *(dissent)*
- **PLT:** Names primary. Self-documenting, collision-proof by construction (namespace is unbounded). Work as suppression IDs (`@allow(NonExhaustiveMatch)`). Codes stay in JSON as compact alias.
- **DevOps:** Names primary. LSP hover shows the name, not a number. Names are stable API — frozen once published. CLI `pact explain NonExhaustiveMatch` is discoverable.
- **AI/ML:** Names primary. Python exception names are the most represented error pattern in LLM training data. `NonExhaustiveMatch` is self-explanatory; `E0004` requires a lookup table. Names survive context window compression better than codes.

**Q1: Organization — category ranges vs prefixes vs flat (4-1 for category ranges)**

- **Systems:** Clean-up-current — fix collisions, no new scheme. Adding ranges is over-engineering for 30 codes. *(dissent)*
- **Web/Scripting:** Category ranges. E00xx-E10xx gives room for growth. Browsing a range tells you the domain.
- **PLT:** Category ranges. Mirrors Rust's proven organization. Numeric ranges partition the code space cleanly.
- **DevOps:** Category ranges. CI rules like "fail on any E05xx" (effect errors) become trivial. Range-based filtering is a real operational tool.
- **AI/ML:** Category ranges. Training data from Rust/C# uses ranged codes. LLMs can infer category from code prefix.

**Q2: Collision handling — reassign vs reserve (5-0 for reassign)**

All panelists agreed: reassign unique IDs to every collision. Reserving ranges for "same code, different meaning" defeats the purpose of having codes at all. Eight reassignments were identified and applied.

**Q3: Documentation format — table vs detailed explain (4-1 for table + deferred explain)**

- **Systems:** Table. One-line descriptions suffice for a reference. Detailed `--explain` is a future tooling concern, not a spec concern.
- **Web/Scripting:** Full Rust-style explain now. Every error should have a prose explanation with examples from day one. *(dissent)*
- **PLT:** Table. The spec examples already serve as the "explain" for each error. A separate prose catalog duplicates them.
- **DevOps:** Table. Ship the catalog now, add `pact explain` tooling later. Perfect is the enemy of done.
- **AI/ML:** Table. LLMs parse tables efficiently. Prose explanations add tokens without proportional value when the spec sections already contain examples.

**Q4: Location — standalone file vs embedded in spec (5-0 for standalone)**

All panelists agreed: standalone `ERROR_CATALOG.md` at repo root. Embedding in a spec section makes the catalog hard to find and forces readers to navigate through prose. Standalone file is directly linkable, greppable, and serves as a single source of truth.

---

## Testing Framework — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions. Resolves Tier 3 gap: "assert(), assert_eq(), panic() used in test blocks but assertion API not defined."

**Q1: Custom assertion messages (3-2 for optional trailing message)**

- **Systems:** Option B. Optional `Str` is zero-cost when omitted — compiler emits two different call sites, no runtime branch. Expression text alone isn't sufficient context for multi-layer test scenarios. Interpolation (C) adds compilation complexity for marginal gain — Pact's universal string interpolation already works in the message argument.
- **Web/Scripting:** Option C. String interpolation in assertion messages is table stakes for DX. Every modern language lets you embed values in error messages. Option A's auto-generated messages can't infer domain context. *(dissent)*
- **PLT:** Option B. Clean typing rule: `assert(cond: Bool, msg: Str = "")`. The message is a plain `Str` — Pact's regular string interpolation handles `"balance was {balance}"` before it reaches `assert`. Option C is unnecessary since interpolation is a property of the string literal, not the intrinsic.
- **DevOps:** Option C. CI/CD triage at 2am needs context like `"withdrawal of {amount} from account {acct_id}"` without reading source. JSON output should have a separate `message` field. *(dissent)*
- **AI/ML:** Option B. Dominant pattern across Python, Rust, Go, JS training data. Interpolation (C) adds format-string decision points. A useless message is cheaper than a compile error from trying to pass one when not allowed.

**Resolution note:** B and C are functionally equivalent in Pact — since all strings support `{expr}` interpolation, `assert(cond, "value was {x}")` works under Option B. The vote is really about whether the *intrinsic* needs special interpolation support (no — the *string literal* handles it).

**Q2: `panic()` function (5-0 for available everywhere)**

- **Systems:** `panic` is `__builtin_unreachable()` with a message. Every real program has invariants that can't be expressed in the type system. `Never` return type lets the optimizer eliminate dead code. Overuse mitigated via lint, not hard ban.
- **Web/Scripting:** Non-negotiable for DX. Every mainstream language has an escape hatch for "this should never happen." Forcing `Result` for truly impossible states creates boilerplate.
- **PLT:** `panic(msg: Str) -> Never`. `Never` (bottom) inhabits every type, standard in type theory. Panic is divergence, not a handleable algebraic effect — tracking it as an effect would poison every function signature. Koka separates `div` from algebraic effects for exactly this reason.
- **DevOps:** Production code needs unrecoverable error paths. Critical requirement: JSON output must distinguish `"status": "failed"` (assertion) from `"status": "panicked"` (unexpected panic) for CI categorization.
- **AI/ML:** `panic!()`/`raise` are deeply embedded in training data. Test-only panic means LLMs generate code that compiles in one context but not another.

**Q3: Pattern assertion — `assert_matches` (4-1 for fourth built-in)**

- **Systems:** Option A. The `match + assert(false)` pattern produces "assertion failed: false at line 43" — zero information about the actual variant. `assert_matches` captures the actual discriminant and Display representation. Binding extraction (C) is over-engineered for v1.
- **Web/Scripting:** Option A. The match-assert pattern is an embarrassing DX failure. `assert_matches` is standard in Rust, Jest, pytest. Keep it simple — no binding support.
- **PLT:** Option A. Principled sugar for `match e { p => (), _ => panic(...) }`. Well-typed when `e: T` and `p` is a refutable pattern over `T`. Must be a syntactic form (second arg is a pattern, not an expression). Binding support (C) deferred to a future `let_assert`.
- **DevOps:** Option A. Compiler has pattern structure at compile time for better failure messages. JSON can include `"expected_pattern"` and `"actual"` as structured fields.
- **AI/ML:** Option B. Training data is thin (Rust nightly-only). Second argument being a *pattern* not an *expression* is exactly the kind of distinction LLMs get wrong. `match` + `panic()` is reliably generated from existing training data. *(dissent)*

**Q4: Assertion failure output format (4-1 for expression introspection)**

- **Systems:** Option C. Compiler already has the full AST. Decomposing `assert(a > b)` into sub-expression values costs nothing at compile time, only emits extra code on the cold failure path. Option B's "expected/actual" labels are misleading — which argument is "expected"? Introspection bounded to one level of sub-expressions. For `assert_eq`, preserve left/right format.
- **Web/Scripting:** Option C. Power Assert is the single biggest testing DX win a language can ship. Groovy and Elixir adopted it. Since assertions are compiler intrinsics, the compiler *has* the AST and *can* decompose sub-expressions. Start with single-level decomposition.
- **PLT:** Option A. "Expected/actual" (B) imposes argument-order convention. Left/right is structurally honest — reports what the arguments are without semantic interpretation. Power assert (C) requires ad-hoc compiler decomposition with evaluation-order concerns. Can be added later as optional enhancement. *(dissent)*
- **DevOps:** Option C. Power assert produces the most actionable diagnostics. CI engineers diagnose from JSON: `"introspection": {"account.balance": 450, "minimum": 500}`. "Expected/actual" is misleading because users put expected on either side. For `assert_eq`, keep left/right labels; introspection applies to `assert()` booleans.
- **AI/ML:** Option C. Sub-expression values let the LLM map values back to variable names instantly in the fix loop. "Expected/actual" has a well-known argument-order swap problem (~30-40% of the time). Power Assert eliminates ordering conventions entirely.

---

## Machine Output Format — Design Rationale

### Panel Deliberation

Five panelists voted on whether Pact's machine-readable output format (§8.1) should remain JSON-only or adopt token-optimized alternatives like TOON.

**Context:** TOON (Token-Oriented Object Notation, v1.4, 2025) offers 30-60% token reduction vs JSON for LLM consumption, with 73.9% LLM parsing accuracy vs JSON's 69.7%. However, JSON has universal CI/IDE/tooling support while TOON has zero ecosystem tooling (no `jq` equivalent, no SARIF, no GitHub Actions parser).

**Q1: Primary output format (3-1-1 for JSON default + TOON flag)**

- **Systems:** Option C. JSON parsing overhead is negligible (SIMD parsers); token savings are the AI consumer's concern. `--format toon` flag is a cheap runtime branch.
- **Web/Scripting:** Option A. JSON universal, zero learning curve. Adding TOON means two paths to document/test/maintain. YAGNI. *(dissent)*
- **PLT:** Option D. Schema and encoding are separate concerns. Spec should define abstract schemas, not bind to a wire format. *(dissent)*
- **DevOps:** Option C. JSON is the only format CI/IDE actually consumes. TOON as opt-in for AI agents.
- **AI/ML:** Option C. 35-40% token savings on diagnostics. LLMs parse TOON more accurately despite less training data.

**Q2: Diagnostic-specific optimization (3-1-1 for uniform format)**

- **Systems:** Option C. Streaming (NDJSON) matches incremental compilation. *(dissent)*
- **Web/Scripting:** Option A. One format, one parser. Principle 2.
- **PLT:** Option A. Uniform treatment. Special-casing breaks compositionality.
- **DevOps:** Option A. One parser, one test suite, one integration.
- **AI/ML:** Option B. Diagnostics are the hot path; tabular TOON has highest ROI here. *(dissent)*

**Q3: Spec language (3-2 for "structured output with canonical JSON schema")**

- **Systems:** Option C. Schema is the contract, wire format is transport.
- **Web/Scripting:** Option A. Just say "JSON." Abstract language invites bikeshedding. *(dissent)*
- **PLT:** Option C. Separates type (schema) from representation (encoding).
- **DevOps:** Option A. CI authors need certainty, not abstract promises. *(dissent)*
- **AI/ML:** Option C. Schema is training signal; encoding is transport. Future-proof.

**Final decision: Deferred.** Panel voted for JSON+TOON, but the pragmatic conclusion was that JSON is required regardless for ecosystem compatibility. TOON (v1.4) is too immature — no `jq`, no SARIF, no CI tooling. The `--format` extensibility point can be added when token-optimized formats achieve tooling parity. No spec changes for v0.3.

---

## Test Skip Mechanism — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on whether and how to support skipping tests. Not a pre-existing GAPS.md item — arose from implementing recursive test discovery.

**Q1: Skip mechanism form (3-2 for both `@skip` annotation + `skip()` runtime built-in)**

- **Systems:** Option C. `@skip` is the zero-cost path — compiler elides the test body entirely. But runtime `skip()` is genuinely necessary for platform/environment-dependent tests. Two mechanisms is fine when they map to two fundamentally different evaluation times. Zig's `return error.SkipZigTest` proves runtime skip works cleanly.
- **Web/Scripting:** Option C. Every major framework (pytest, Jest, JUnit) ships both because they solve different problems. `@skip` is the TODO marker, `skip()` handles "this only works on Linux." Forcing conditional skips into tag filtering is clunky and unfamiliar.
- **PLT:** Option A. `@skip` operates at the declaration level as compile-time metadata — principled, composes orthogonally. Runtime `skip()` conflates a meta-level concern (whether to run) with object-level computation (the test body). This is a level confusion. *(dissent)*
- **DevOps:** Option C. `@skip` gives LSP/linter/formatter a static signal: dimmed rendering, CI warnings, reason-less skip linting. But `skip()` solves what `@skip` cannot: conditional skipping produces proper `"skipped"` status instead of misleading `"pass"`.
- **AI/ML:** Option A. `@skip` is highest-signal for LLM generation — annotation-before-test is massively represented in training data. `skip()` adds a runtime decision point that increases LLM error surface. LLMs will hallucinate `@skip` anyway; better to make the hallucination correct. *(dissent)*

**Key argument:** Compile-time and runtime skips are fundamentally different evaluation times. `@skip` cannot express "skip if no GPU" and `skip()` cannot avoid compiling/loading a test with missing dependencies. Conflating them into one mechanism forces losing either zero-cost static skipping or runtime conditional capability.

**Dissent summary:** PLT argued that skip is a meta-level judgment about the test, not part of the test's computation — `skip()` inside the body is a category error. AI/ML argued that two mechanisms doubles the decision surface for LLMs and `@skip` alone covers 90% of use cases with zero ambiguity.

---

## Package Distribution & Resolution — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 5 questions covering the package manager design gap identified in GAPS.md.

**Q1: Registry model (5-0 for hybrid)**

- **Systems:** Hybrid. Central registry provides content-addressed integrity verification. Git fallback handles private/corporate repos without requiring a private registry instance. Identity invariant prevents the "same package, two names" dependency duplication bug.
- **Web/Scripting:** Hybrid. npm taught us that a central registry with URL fallback covers 99% of cases. Corporate proxies and private repos need git URLs. The identity invariant is critical — npm has the `npm:` alias mess because they lack this.
- **PLT:** Hybrid. Go's proxy model proves this works at scale. The identity invariant is a theorem about package identity that prevents diamond-dependency confusion. Registry is the canonical source; git is a transport mechanism.
- **DevOps:** Hybrid. CI/CD pipelines need deterministic dependency resolution from a single source of truth. Git fallback handles air-gapped environments and internal packages. The lockfile pins both registry and git deps uniformly.
- **AI/ML:** Hybrid. LLMs need one canonical name per package for reliable code generation. If `http-client` and `git:...http-client.git` were different identities, models would hallucinate the wrong one. Single identity = single training signal.

**Q2: Package naming (4-1 for namespaced org/name)**

- **Systems:** Namespaced. `org/name` provides collision-free naming and maps directly to capability trust boundaries. `std/http` and `acme/http` are unambiguous. Slash separator is universal (GitHub, Docker, Go modules).
- **Web/Scripting:** Namespaced. npm's `@scope/name` proves namespacing works at massive scale. Flat naming caused the `left-pad` land-grab problem. Organizations need ownership boundaries.
- **PLT:** Namespaced. Module path mapping (`import std.http` → package `std/http`) is clean and deterministic. Namespaces provide a natural hierarchical organization that matches how developers think about code provenance.
- **DevOps:** Namespaced. Org-scoped names enable per-org security policies in CI: `std/*` packages can be auto-approved while `unknown-org/*` requires review. Trust boundaries need machine-readable organization signals.
- **AI/ML:** Flat names. LLMs trained on npm/PyPI primarily see flat names (`requests`, `express`, `flask`). Namespaced names double the token count per dependency reference and increase hallucination surface — models must get both org AND name correct. Flat names with a prefix convention (`pact-http`) would leverage existing training data better. *(dissent)*

**Q3: Version resolution algorithm (4-1 for MVS)**

- **Systems:** MVS. Deterministic without lockfile is the key property — reproducible builds are guaranteed by the algorithm, not by an artifact. No SAT solver means no exponential worst-case. Resolution is a simple graph walk.
- **Web/Scripting:** Maximal/latest. Every JS/Python/Ruby developer expects `pact add foo` to get the newest version. MVS getting the *oldest* satisfying version will confuse developers and generate support tickets. The lockfile already ensures reproducibility — MVS's determinism-without-lockfile is solving a problem we don't have since lockfiles are mandatory. *(dissent)*
- **PLT:** MVS. Russ Cox's formal proof that MVS is the only algorithm where adding a dependency cannot change existing resolved versions is compelling. Monotonicity is a strong theoretical property that prevents "dependency hell" by construction.
- **DevOps:** MVS. `pact update` is an explicit operation that upgrades. Implicit latest-version resolution means CI builds change based on when they run. MVS + mandatory lockfile = maximum reproducibility.
- **AI/ML:** MVS. Deterministic resolution means LLMs can predict resolved versions from `pact.toml` alone. Non-deterministic resolution (latest at time of resolve) means the model cannot know what versions will be selected, making version-specific API advice unreliable.

**Q4: Version constraint syntax (4-1 for caret default)**

- **Systems:** Tilde. Caret is too permissive — `"1.2"` accepting `1.9.0` trusts the entire ecosystem to never break semver within a major. Tilde (`~1.2` = `>=1.2, <1.3`) limits blast radius to patch versions, which are far less likely to break. *(dissent)*
- **Web/Scripting:** Caret. npm's `^` default has proven itself at massive scale. Developers expect `"1.2"` to mean "compatible with 1.2." Tilde is too conservative — it prevents adopting minor-version features without manual update.
- **PLT:** Caret. The semver contract explicitly states that minor versions add functionality without breaking compatibility. Caret directly encodes this contract. Tilde underutilizes semver by treating minor versions as potentially breaking.
- **DevOps:** Caret. Combined with MVS, caret is conservative in practice — MVS selects the *oldest* 1.x that satisfies constraints, not the newest. Caret + MVS = you get 1.2.0 until something explicitly requires 1.3+.
- **AI/ML:** Caret. Simpler mental model for LLMs: `"1.2"` means "1.x compatible." Models generating `pact.toml` files will use the default constraint most often — caret is the most forgiving default for AI-generated version strings.

**Q5: MVP dependency sources (5-0 for path + git only)**

- **Systems:** Path + git. Registry infrastructure is a massive engineering effort (storage, CDN, authentication, moderation). Path and git deps cover all development scenarios. Ship the language, not the ecosystem infrastructure.
- **Web/Scripting:** Path + git. npm didn't launch with a registry either — the tool came first. Developers need local and git deps for real work. Registry can follow when there's a community to serve.
- **PLT:** Path + git. The `pact.toml` schema should be forward-compatible so adding `version = "1.0"` registry deps later requires zero breaking changes. Design the schema now, ship the registry later.
- **DevOps:** Path + git. Git deps with commit-hash pinning in the lockfile provide reproducibility. Path deps enable monorepo workflows. These two cover corporate development patterns completely.
- **AI/ML:** Path + git. LLMs generating `pact.toml` for new projects will use path deps for workspace packages and git deps for external code. Registry deps need a live package index — AI can't verify package existence without it. Ship what works offline first.

**Key argument:** MVS + caret + mandatory lockfile creates a uniquely conservative system: caret constraints allow compatible updates, but MVS selects the oldest satisfying version rather than the newest. `pact update` is the only operation that moves versions forward, making dependency upgrades always intentional. This eliminates the "it worked yesterday but today it resolves differently" class of bugs.

**Dissent summary:** Web/Scripting argued that MVS's "oldest version" behavior contradicts developer expectations from every major package manager (npm, pip, cargo all select newest). AI/ML argued that flat package names would better leverage existing LLM training data from npm/PyPI ecosystems. Systems argued that tilde constraints provide tighter blast radius than caret.

---

## Stdlib Distribution & Import Resolution — Design Rationale

### Panel Deliberation

The import resolution algorithm (§10.5) specified local `src/` resolution and `pact.lock` dependency resolution but had no mechanism for standard library modules. This gap blocked stdlib modules (`std.toml`, `std.semver`) from being importable outside of the compiler's own `src/` directory.

**Q1: Where does the stdlib physically live? (4-1 for D: virtual/implicit dependency)**

- **Sys (A):** Alongside compiler binary in `<pactc_dir>/stdlib/`. Hermetic, relocatable, matches Go/Zig.
- **Web (D):** Virtual dependency. Zero new concepts — stdlib is just deps you didn't have to declare. Go's approach.
- **PLT (D):** Uniform module semantics. No special resolution step. Effect system needs zero special cases.
- **DevOps (D):** Virtual dep backed by `<pactc_dir>/lib/std/`. LSP and compiler share same path. CI needs zero config.
- **AI (D):** Virtual dep. Implementation detail hidden from import syntax. Eliminates "where is my stdlib?" debugging.

*(dissent: Sys — preferred explicit filesystem colocating over virtual abstraction, citing Go's `GOROOT/src/` simplicity)*

**Q2: What is the import syntax for stdlib? (3-2 for A: `std` prefix)**

- **Sys (A):** `std.` prefix eliminates ambiguity. `pact.` prefix collides with language name. Matches Rust `std::`.
- **Web (C):** `pact.` prefix — spec already shows `import pact.http` in §10.5 examples. No new naming convention. *(dissent)*
- **PLT (A):** `std.` prefix avoids open namespace problems. OCaml retrofitted `Stdlib.List` for exactly this reason.
- **DevOps (A):** `std.` prefix — matches `std/` org on registry (§8.9.2). `import std.http` → `std/http` package.
- **AI (C):** `pact.` prefix — existing spec examples are the training data. Changing creates contradiction. *(dissent)*

*Clarifying note: §8.9.7 explicitly states "import paths follow the `org/name` structure: `import std.http` maps to the `std/http` package." The `pact.*` namespace in §10.6 (`pact.core`, `pact.ffi`) is reserved for compiler-internal pseudo-modules, not distributable packages. The existing spec is consistent with the `std` prefix.*

**Q3: What is the resolution order? (3-2 for C: stdlib is a dep, no new step)**

- **Sys (A):** Local → stdlib → deps → error. Stdlib is trusted toolchain code, should shadow deps for security.
- **Web (C):** Local → deps (stdlib included) → error. No new resolution step, uniform mental model.
- **PLT (C):** Stdlib-as-dep. Scales to Tier 2/3 without semantic boundary changes.
- **DevOps (A):** Local → stdlib → deps → error. With escape hatch: explicit `pact.toml` pinning overrides bundled version. *(dissent)*
- **AI (C):** Stdlib-as-dep. One resolution algorithm, zero special cases.

*(dissent: Sys — wanted explicit stdlib priority for supply-chain security. DevOps — wanted stdlib step for clearer error messages on corrupted installs)*

### Resolution

Stdlib modules are distributed alongside the compiler binary in `<pactc_dir>/lib/std/`. The compiler treats them as implicit dependencies injected into the dependency graph before resolution. Import syntax uses the `std` prefix: `import std.toml`, `import std.semver`. The resolution algorithm remains unchanged — local `src/` first, then all dependencies (including implicit stdlib entries), then error. See §10.7 for the full specification.

---

## Module-Level Let Semantics — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions. All votes unanimous.

**Context:** Friction log (Feb 7, 2026) discovered that duplicate `let mut` declarations at module level silently collapse — codegen's `is_emitted_let()` dedup skips the second declaration with no error or warning. The spec had no guidance on module-level `let` uniqueness, `pub let` visibility, or how shadowing rules differ from function-local scope.

**Q1: What happens with duplicate module-level `let` names? (5-0 for compile error)**

- **Systems:** Silent dedup hides ambiguity at static-storage level. Both `static const` and `static` in C require unique names per translation unit. Every systems language errors on redeclaration. The codegen workaround (first-binding-wins) is an implementation accident, not a feature.
- **Web/Scripting:** JavaScript/TypeScript `let` redeclaration in the same scope is a `SyntaxError`. Pact developers coming from these languages expect the same. Silent dedup is the worst possible behavior — it looks like it works but does the wrong thing.
- **PLT:** Module-level scope is a flat namespace. There is no inner scope for shadowing to inhabit, so "redeclaration" has no well-defined semantics under lexical scoping. Compile error preserves referential transparency — every name has exactly one binding.
- **DevOps:** Silent dedup is a tooling nightmare. LSP go-to-definition becomes ambiguous, no diagnostic is available, and the developer has no signal that their code is wrong. An early compile error is cheap and saves hours of debugging.
- **AI:** Silent-first-wins means an LLM generates `x = 2` but runtime has `x = 1` from an earlier binding. Compile error provides a strong training signal — the model learns immediately that duplicate bindings are wrong.

**Q2: Should `pub let mut` be allowed? (5-0 for immutable only)**

- **Systems:** `pub let` maps to `static const` in C — zero synchronization cost, safe to read from any context. `pub let mut` maps to mutable global state — a concurrency landmine that requires synchronization primitives the language doesn't yet provide.
- **Web/Scripting:** Maps directly to `export const` in JavaScript. Mutable exports cause chaos — even Python developers regret the pattern. Cross-module mutable state should go through functions.
- **PLT:** An immutable export is semantically equivalent to a nullary function — clean, compositional, no side effects. Cross-module mutation is an effect and should be tracked through the effect system.
- **DevOps:** Read-only constants support LSP hover-for-value and dead-code analysis. `pub let mut` creates "who changed this?" questions that are unanswerable without full program tracing.
- **AI:** `pub const`/`export const` patterns are well-represented in training data. Cross-module mutable state has a high error rate in LLM-generated code because models can't track mutation across files.

**Q3: Should function-local and module-level shadowing rules differ? (5-0 for yes)**

- **Systems:** Different codegen contexts justify different rules. Function-local shadowing is stack-based (cheap, scoped). Module-level would require static storage reallocation. Rust draws this exact line.
- **Web/Scripting:** TypeScript and Rust developers expect function-local `let x = parse(x)` as an idiomatic pipeline pattern. Module-level shadowing has no such ergonomic justification.
- **PLT:** Function bodies use sequential lexical scoping — each `let` opens a new scope (compositional). Modules use a flat namespace — all bindings coexist (collision). The scoping models are fundamentally different.
- **DevOps:** LSP handles function-local shadowing well — hover shows the right binding by scope. Module-level "which x?" creates confusion in every tool that processes the file.
- **AI:** Rust's shadowing model (allowed in functions, forbidden at module level) is the best-represented pattern in training data. Module-level shadowing has essentially zero training signal — models would have to guess.

### Resolution

Module-level `let` bindings must have unique names — duplicates are a compile error (`DuplicateModuleBinding`, E1004). Only immutable `pub let` is allowed; `pub let mut` is a compile error (`PubLetMutForbidden`, E1006). Function-local `let` shadowing remains permitted. See §2.12.1 for the full specification.

---

## Serialization / Deserialization Story — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 7 questions. Strong consensus on all questions, with two split votes.

**Context:** Every web service needs JSON serialization, but Pact had no `@derive(Serialize)` or codec story. The `@derive` annotation already supports 6 traits (Eq, Ord, Hash, Clone, Display, Debug). Examples show `json.serialize(forecast)` and `Response.json(user)` patterns. The "One Way" principle demands a single blessed approach.

**Q1: Trait or annotation for serialization? (5-0 for A: `@derive(Serialize, Deserialize)` trait impls)**

- **Sys (A):** Trait-based dispatch monomorphizes cleanly. `to_json()` compiles to a direct function call per type — zero vtable overhead. Extends the existing `@derive` mechanism with no new compiler concepts.
- **Web (A):** `@derive(Serialize, Deserialize)` is the Rust serde pattern — massive training data. Developers get it immediately. One line on the struct and you're done.
- **PLT (A):** Traits are the principled mechanism for ad-hoc polymorphism. `Serialize` and `Deserialize` are textbook type classes. Using traits means the type system enforces serialization constraints — `fn send[T: Serialize](data: T)` statically guarantees the argument is serializable.
- **DevOps (A):** Trait-based approach produces clear error messages: "Type `Foo` does not implement `Serialize`" with "add `@derive(Serialize)`" help text. The annotation-only approach would require new diagnostic infrastructure.
- **AI (A):** `@derive(Serialize)` mirrors Rust's `#[derive(Serialize)]` — the single most common derive in Rust training data. LLMs will generate this correctly >95% of the time.

**Q2: Field customization in v1? (3-2 for B: no field renaming)**

- **Sys (B):** Field renaming is syntactic sugar with runtime cost (name lookup tables). Ship v1 without it — if struct field names match JSON keys, zero overhead. Add `@json("name")` in v2 when the derive macro system is more mature.
- **Web (A):** Real-world APIs use snake_case, camelCase, and kebab-case. Without `@json("field_name")`, every API integration requires manual serialization. This is a day-one need. *(dissent)*
- **PLT (B):** Adding field-level annotations requires the compiler to process annotation arguments at the field level — a new capability. The type-to-JSON mapping should be structural for v1. Renaming is a v2 concern once the derive system supports annotation introspection.
- **DevOps (A):** Real APIs don't match Pact naming conventions. `@json("firstName")` is essential for interop. Without it, users bypass `@derive` entirely and write manual conversion, defeating the purpose. *(dissent)*
- **AI (B):** Zero field customization means zero decision points per field. LLMs don't have to choose between `@json("name")` and no annotation. One pattern: fields always match JSON keys.

**Q3: Codec dispatch model? (5-0 for A: JSON-specific `Serialize` trait)**

- **Sys (A):** JSON-specific trait compiles to direct calls. No type erasure, no generic codec dispatch overhead. If TOML or YAML are needed later, add `TomlSerialize` — a separate trait is cheaper than a generic framework.
- **Web (A):** JSON is 99% of serialization in web services. YAGNI for codec-generic. TypeScript doesn't have a generic codec system and nobody misses it.
- **PLT (A):** A codec-generic `Serialize[Format]` requires associated types or higher-kinded types (`F.Value`, `F.Error`) which Pact doesn't have in v1. The JSON-specific trait is sound and complete for v1. Codec generics can be added in v2 without breaking changes.
- **DevOps (A):** Simple trait = simple error messages. `Serialize[Format]` would produce error messages mentioning `Format.Encoder` and `Format.Value` — confusing for new users.
- **AI (A):** JSON-specific serialization is overwhelmingly dominant in training data. Codec-generic patterns (like Swift's `Codable`) are less represented and more error-prone in LLM generation.

**Q4: Tier 1 or Tier 2? (5-0 for A: Tier 1, ships with compiler)**

- **Sys (A):** Serialization traits must be compiler-known for `@derive` to work without custom derive infrastructure. Tier 1 is the only option that makes `@derive(Serialize)` zero-config.
- **Web (A):** Every web service needs JSON. Making it Tier 2 means every project starts with `pact add std.json`. That's friction for the most common use case.
- **PLT (A):** `Serialize` and `Deserialize` interact with the type system via `@derive` — they must be compiler-known. This is analogous to `Eq` and `Hash` being Tier 1.
- **DevOps (A):** Tier 1 means `@derive(Serialize)` works in every LSP session without project configuration. Zero-config tooling support.
- **AI (A):** Tier 1 eliminates an import decision. LLMs generate `@derive(Serialize)` and it just works — no "did you add std.json to pact.toml?" failures.

**Q5: Option[T] handling in JSON? (5-0 for A: None → null)**

- **Sys (A):** `null` is a concrete JSON value with well-defined semantics. Omitting fields creates variable-width structs in the JSON, complicating parsing. `null` maps 1:1 to `None`.
- **Web (A):** JavaScript's `null` is the standard. Every JSON library in every language maps `None`/`nil`/`null` to JSON `null`. Go's `omitempty` is the exception, not the rule.
- **PLT (A):** `Option[T]` is isomorphic to `T | null` in JSON's type system. `None → null` is the natural embedding. Omitting fields requires type-level field presence tracking.
- **DevOps (A):** `null` in JSON output is inspectable. Missing fields are ambiguous — was the field removed from the schema, or is it absent because of a bug?
- **AI (A):** `None → null` matches the dominant pattern in training data (serde, Jackson, System.Text.Json). Omit-field behavior requires additional annotations, adding decision points.

**Q6: Error type? (4-1 for C: single `JsonError`)**

- **Sys (C):** One error type, one match arm. JSON errors are JSON errors whether from serialization or deserialization. A single `JsonError` with a message string is sufficient.
- **Web (C):** `JsonError` is simple and familiar. `try { json.parse(s) } catch (JsonError e)` is the pattern every web developer knows. Splitting into two types doubles the error handling surface for no user benefit.
- **PLT (B):** Serialization and deserialization are distinct operations with different failure modes. `SerializeError` occurs when a type can't be represented (e.g., infinite recursion). `DeserializeError` occurs when input doesn't match expected structure. Conflating them loses information. *(dissent)*
- **DevOps (C):** One error type means one error code range, one diagnostic message format, one thing to search for in docs. The message string carries the specifics.
- **AI (C):** Single `JsonError` is one pattern to learn. Separate types double the error handling decision points. `ConversionError` precedent (voted 3-2 for single fixed type) supports this.

**Q7: Purity of serialization? (5-0 for A: pure)**

- **Sys (A):** `to_json()` is a pure function from data to data. No allocation beyond the return value. Streaming serialization is an optimization concern for v2.
- **Web (A):** Serialization should never have side effects. `JSON.stringify()` is pure. `json.dumps()` is pure. Users expect this.
- **PLT (A):** Serialization is a morphism between data types — inherently pure. IO effects belong to the caller who writes the bytes. Mixing serialization with IO would pollute effect signatures everywhere.
- **DevOps (A):** Pure serialization is testable without effect handlers. `assert_eq(user.to_json(), expected_json)` — no mock setup needed.
- **AI (A):** Pure functions are the safest pattern for LLM generation. No effect declarations to get wrong, no handler setup to forget.

### Resolution

Serialization uses `@derive(Serialize, Deserialize)` to generate trait implementations, extending the existing derive mechanism. `Serialize` has a single method `fn to_json(self) -> JsonValue` and `Deserialize` has `fn from_json(json: JsonValue) -> Result[Self, JsonError]`. Both traits are compiler-known (Tier 1) and derivable via `@derive`. Serialization is pure — IO effects belong to the caller. `Option[T]` maps to JSON `null` for `None`. Field names must match JSON keys exactly in v1 (no `@json("name")` renaming). A single `JsonError` type covers both directions. See §3.6.2 for the full specification.

---

## Import Compilation Model — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions. All votes unanimous.

**Context:** Friction log (Feb 7, 2026) identified a critical flaw: the import system only brings `pub`-marked items into the merged C output, but when those `pub` functions reference module-internal helpers, the helpers are missing — gcc reports undefined symbols. The workaround was making everything `pub`, defeating visibility entirely. Root cause: the import mechanism filters AST declarations by visibility, but function bodies contain unresolved references to their module's private symbols. Three options were proposed: (a) transitive closure — call-graph analysis to include non-pub dependencies of pub items, (b) emit-all — include everything from imported modules, (c) separate compilation — each module to its own `.c` file.

**Q1: Which compilation model? (5-0 for B: emit-all)**

- **Sys (B):** Emit-all unblocks the compiler with a one-line semantic change. Transitive closure (a) requires call-graph analysis — a subset of name resolution that doesn't exist yet. Separate compilation (c) introduces linker orchestration and header generation, a massive yak-shave. Layer on dead-code elimination later when you have a symbol table.
- **Web (B):** TypeScript/JavaScript bundlers do emit-all — pull in entire modules, optionally tree-shake later. Python and Go load entire modules. Developers expect "import a module, it just works." Transitive closure is an optimization for later, not a prerequisite.
- **PLT (B):** Analogous to MLton's whole-program compilation or OCaml's bytecode `.cmo` files. Transitive closure conflates reachability (operational) with visibility (semantic) and breaks with function pointers, vtable dispatch, or indirect effect handlers. Emit-all is sound if pub is enforced at the type-checking level. *(noted: separate compilation is the principled v2 target)*
- **DevOps (B):** Dead simple to implement, eliminates linker errors immediately. Separate compilation requires a symbol table, header generation, and build graph — all missing. Ship (b) now, migrate to (c) when compile times demand it.
- **AI (B):** Simplest mental model for LLM code generation: import a module, everything works. Transitive closure introduces subtle dependency analysis where the AI must reason about call graphs to predict what gets included — exactly the hidden coupling that causes mysterious failures LLMs can't self-diagnose.

**Q2: Should `pub` be enforced or advisory? (5-0 for A: enforced at compile time)**

- **Sys (A):** Every modern systems language enforces visibility at compile time. Advisory means accumulating tech debt in downstream modules that accidentally depend on internals. Design `pub` as enforced from day one.
- **Web (A):** TypeScript enforces `export`, Go enforces capitalization. Advisory visibility leads to "just make it public" culture. Clear error messages enable fast self-correction.
- **PLT (A):** Information hiding is a soundness property, not convenience. Mitchell & Plotkin (1988) showed abstract types are existentials — leaked private constructors break representation independence. Pact's effect system makes this critical: leaked private handlers break effect encapsulation.
- **DevOps (A):** Compile-time enforcement means LSP flags private access instantly, import suggestions only offer pub items, and CI catches violations before anything hits the linker.
- **AI (A):** LLMs handle "clear error, fix it" far better than "works but subtly wrong." Enforced `pub` produces actionable errors ("item `foo` is private, add `pub`") that LLMs self-correct on in one retry.

**Q3: Symbol naming in C output? (5-0 for B: module-qualified for all items)**

- **Sys (B):** Flat names are a collision timebomb. Two modules defining `parse` or `init` cause silent C-level redefinition. Module-qualifying everything matches Rust (mangled), Go (package-prefixed), and makes separate compilation trivial to add later since symbols are already globally unique.
- **Web (B):** `pact_auth_token_validate` in a gcc error immediately tells you where to look. Name collisions between modules are inevitable in real projects. Consistent naming eliminates ambiguity.
- **PLT (B):** Alpha-equivalence tells us binding identity is scope, not string. Private symbols are *more* collision-prone (common names like `helper`, `impl`, `inner`) and need qualification more than pub symbols. Mixed schemes (c) are incoherent.
- **DevOps (B):** At 2 AM staring at a gdb backtrace, `pact_auth_token_validate` tells you exactly which module crashed. Flat `pact_validate` tells you nothing. Consistent naming prevents the two-tier debugging experience where private helper crashes produce useless stack frames.
- **AI (B):** When AI-generated code hits C compiler errors, module-qualified names let the LLM map symbols back to Pact source unambiguously. Mixed naming means reasoning about pub/private just to parse gcc errors.

### Cross-language Survey

| Language | Compilation Unit | Visibility Enforcement | Symbol Naming |
|----------|-----------------|----------------------|---------------|
| C | Translation unit (`.o`) | `static`/`extern` at link time | Flat (collision is programmer's problem) |
| Rust | Crate (whole-crate) | `pub` enforced at compile time | Fully mangled with crate+module path |
| Go | Package (all files) | Capitalization enforced at compile time | Package-qualified |
| Zig | Per-file modules | `pub` enforced at comptime | Fully-qualified mangled names |
| OCaml | Separate (`.cmo`/`.cmx`) | `.mli` interface files | Module-qualified |
| Haskell (GHC) | Separate (`.hi` interface) | Export list enforced by type checker | Fully-qualified z-encoded |
| TypeScript | Module-level | `export` enforced at compile time | Bundler-mangled unique identifiers |
| Python | Module-level (load all) | `_prefix` advisory (widely criticized) | Module-qualified at runtime |
| Swift | Whole-module default | `public`/`internal`/`private` enforced | Module-qualified mangled |

Universal pattern: compile the whole module, enforce visibility in the front-end, qualify all symbols.

### Resolution

The Pact compiler uses **emit-all** compilation: when any item from a module is imported, all items (pub and non-pub) are included in the generated C output. The `pub` keyword controls **Pact-level visibility** — using a non-pub item from outside its module is a compile error, enforced by name resolution. In generated C, all symbols use **module-qualified names** (`pact_<module_path>_<item_name>`) to prevent collisions and enable debuggability. Separate compilation (one `.c` per module, link together) is the planned v2 optimization when compile times warrant it. See §10.8 for the full specification.

---

## Name Resolution Pass — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions. Each expert ran as a separate agent and returned votes without seeing other experts' reasoning.

**Context:** The Pact compiler has no complete name resolution. A partial `resolve_names()` pass in typecheck checks variables and function calls but does NOT verify method existence (which requires type information). Codegen maintains its own separate scope system with 11+ type-specific tracking lists. Undefined function calls log E0504 but continue emitting garbage C. Method calls silently generate invalid C identifiers like `x_nonexistent(x)`. The resolved import compilation model (5-0 emit-all) flattens all imported declarations into a single AST with no module scoping. The resolved `pub` enforcement decision (5-0 compile-time) is not yet implemented.

**Q1: How should the typecheck symbol table and codegen scope system be unified? (5-0 for C: annotated AST)**

- **Systems (C):** Extends the existing parallel-array architecture naturally. `np_resolved_type`/`np_resolved_fn` give codegen O(1) access via node index — data-oriented, cache-friendly, no layering violations. Option A forces typecheck to carry codegen-specific CT_* baggage.
- **Web/Scripting (C):** TypeScript's checker decorates AST nodes with type info that downstream phases consume — same pattern. Avoids the "two systems diverge" risk of B without the massive refactor of A. Data-flow model is easy to reason about: typecheck writes, codegen reads.
- **PLT (C):** The compiler already uses parallel arrays as its AST representation — this IS an annotated AST. Adding resolution annotations is the natural extension. Maintains the phase distinction principle: typecheck writes, codegen reads. Shared symbol table (A) forces premature coupling between semantic analysis and code emission.
- **DevOps (C):** Annotated AST nodes are the bread and butter of LSP: hover needs resolved type at a node, goto-definition needs resolved symbol — both are "read annotation off AST node" operations. A's shared symbol table fights the parallel-array design. B's separate systems produce inconsistent diagnostics.
- **AI/ML (C):** Parallel arrays are already the compiler's idiom, so adding resolution arrays is a pattern the model has learned. Shared symbol table (A) introduces a broken transitional period. Two systems (B) means tracking two separate mental models — documented failure mode in code generation benchmarks.

**Q2: Should method resolution be deferred to a type-aware pass? (5-0 for A: two-phase)**

- **Systems (A):** Method resolution is inherently type-directed — can't resolve `x.len()` without knowing what `x` is. Two-phase maps to the real dependency graph. The "double walk" cost is negligible in parallel arrays.
- **Web/Scripting (A):** The TypeScript/Kotlin model. When I write `x.foo()` and `foo` doesn't exist on that type, I want an error at typecheck time, not a cryptic C compiler error. Option B can't handle inferred types. Option C keeps semantic validation in codegen — dead end for tooling.
- **PLT (A):** The only sound option. Name binding answers "does this identifier refer to something?"; method resolution answers "which implementation does this call dispatch to?" These are distinct problems requiring distinct information. Conflating them (B) is a category error.
- **DevOps (A):** The only option that enables real LSP method completions. Option B can only complete methods on explicitly annotated types. Option C keeps method resolution in codegen — dead end for language server.
- **AI/ML (A):** Two-phase gives the AI a clean, ordered error sequence: first all "unknown name" errors, then all "no such method on type X" errors. This is the Rust/TypeScript pattern that dominates training data.

**Q3: What error recovery strategy for name resolution? (4-1 for A: accumulate, halt before codegen)**

- **Systems (A):** Hard gate: codegen only sees valid input. Every phase needs a clear contract. Option B imposes poison-value handling tax on every future codegen change.
- **Web/Scripting (A):** This is what every modern language does and what developers expect. Name errors are high confidence — no cascade ambiguity like type inference. One missing import can trigger 50 downstream errors with Option B — all meaningless noise.
- **PLT (A):** A program that is not well-scoped cannot be meaningfully typed. Continuing with unresolved names (B) requires introducing poison types that propagate through the type system — enormous complexity. Clean phase gate is the principled choice.
- **DevOps (B):** Developer feedback loop is king. When I have 3 typos, 1 missing import, and 1 type error, I want all 5 in one compiler run. Cascade suppression (poison symbols suppress downstream errors) mitigates false positives. *(dissent)*
- **AI/ML (A):** Models perform measurably better seeing ALL errors of a given category at once rather than one-at-a-time. Cascade errors from poison values are pure noise — LLMs cannot distinguish real errors from cascade artifacts.

**Q4: How should name resolution interact with imports and pub enforcement? (4-1 for B: module-scoped symbol table)**

- **Systems (A):** The 5-0 emit-all decision committed to flat compilation. Module-scoped tables contradict that architecture. Minimal delta: tag declarations with source module, check `np_is_pub` on cross-module references. *(dissent)*
- **Web/Scripting (B):** The panel already voted 5-0 for module-qualified C symbols and 5-0 for pub enforcement. A module-scoped symbol table is the natural implementation. Option A is the "allow then deny" anti-pattern. Every language (TypeScript modules, Python packages, Kotlin packages) has module-scoped resolution.
- **PLT (B):** The only compositional option. A flat scope cannot distinguish `module_a.helper` from `module_b.helper` — it structurally cannot represent pub boundaries. Module-scoped tables are standard in every language with a module system (ML, Haskell, Rust). Option C (defer) is unsound — allows programs to compile that should be rejected.
- **DevOps (B):** Module-scoped tables enable LSP scoped completions (`std.json.` shows JSON methods only). Proper go-to-definition. Useful `PrivateItemAccess` errors with module context. The flat model becomes a collision minefield as stdlib grows.
- **AI/ML (B):** Every major language in training data uses module-scoped resolution. LLMs have internalized `import X` → `X.thing`. A flat scope is novel and fights the training distribution. Option C creates a time-bomb: AI generates code using private items that compiles today, breaks when pub enforcement arrives.

### Resolution

Name resolution uses an **annotated AST** architecture: the typecheck phase decorates AST nodes with resolution results via new parallel arrays, and codegen reads these annotations instead of maintaining its own scope system. Method resolution runs in **two phases** — name binding first, then type-aware method resolution — reflecting the fundamental distinction between name binding and type-directed dispatch. Name resolution **accumulates all errors and halts before codegen**, ensuring codegen never processes unresolved names. The symbol table is **module-scoped**, with each declaration tagged by source module, enabling structural `pub` enforcement and module-qualified error messages. See §6.3 for the full specification.

---

## `?` Operator Type Validation — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions. All votes unanimous.

**Q1: Where should `?` validation live? (5-0 for A: type checking phase)**

- **Systems (A):** You never let invalid IR reach codegen in a sound compiler pipeline. Codegen should assume all invariants hold. Phase separation exists for a reason — Rust does this in HIR/type checking, not LLVM IR generation.
- **Web/Scripting (A):** Type checking is the natural home. It needs type information to differentiate Result vs Option, and putting it in a dedicated phase gives consistent error reporting and a clean contract to codegen.
- **PLT (A):** Phase separation exists for a reason. The `?` operator is fundamentally a type-level concern — it requires knowing the monadic container type, the return type signature, and proving compatibility. Codegen should consume validated ASTs.
- **DevOps (A):** Validation belongs in a dedicated phase gate — basic compiler hygiene. Type checking has all the context it needs, and catching errors early means better diagnostics and no wasted work downstream.
- **AI/ML (A):** AI code generators need deterministic error messages before hitting codegen. Catching `?` misuse in type checking gives clear, actionable errors the model can use in the next fix iteration.

**Q2: Should `?` work on both Result[T,E] and Option[T]? (5-0 for A: both)**

- **Systems (A):** `?` is early-return sugar — semantically identical whether unwrapping T|E or T|None. Separating them forces arbitrary syntactic distinctions for the same control flow pattern. The spec already committed to this.
- **Web/Scripting (A):** The obvious ergonomic win. Web devs are used to early-return patterns. Cross-type auto-wrapping (C) adds implicit magic that conflicts with the no-auto-into stance.
- **PLT (A):** Basic monad uniformity — `?` is sugar for early-return on the failure branch of a sum type. For Result that's Err(e), for Option it's None. Option C would be inconsistent with the 4-1 vote against implicit `.into()`.
- **DevOps (A):** Having two operators with subtly different semantics is a diagnostic nightmare. Developers expect `?` to mean "early return on sad path" regardless of container type.
- **AI/ML (A):** Training data across Rust/Swift/Kotlin shows this pattern. Both are "short-circuit on absence" — Option just has no error payload. Forcing Result-only would be an arbitrary restriction.

**Q3: How should error type compatibility be validated? (5-0 for A: exact structural match)**

- **Systems (A):** Structural equality is how the rest of the type system works. Nominal matching would spuriously unify two differently-defined types with the same name from different modules.
- **Web/Scripting (A):** The panel already voted 4-1 against auto `.into()`, so consistency demands exact match. If error types don't match, explicit `.map_err()` is the answer.
- **PLT (A):** The only sound choice that doesn't require runtime checks or implicit conversions. Nominal matching fails with generic error types or same-name-different-structure scenarios.
- **DevOps (A):** Structural equality gives precise, actionable errors: "expected Err(IoError), got Err(ParseError)" tells the developer exactly what's wrong.
- **AI/ML (A):** Exact match means clear errors that are greppable and fixable. Matches what AI models expect from typed languages.

**Q4: What error codes and diagnostics? (5-0 for A: separate codes per failure)**

- **Systems (A):** Systems programmers need actionable diagnostics. Separate codes point directly at the specific type mismatch. Generic codes with context text lead to "what does my error mean" questions.
- **Web/Scripting (A):** Separate error codes per failure mode make error docs easier to navigate. TypeScript and Rust nail this pattern.
- **PLT (A):** Separate codes let you write targeted diagnostics with fix suggestions (wrap in Result, use `??` instead, add `.map_err()`). The whole point of a type checker is giving actionable information.
- **DevOps (A):** Non-negotiable from a tooling perspective. IDE integrations, error parsers, CI failure messages all key off error codes. Parsing human-readable strings to determine what went wrong is barbaric.
- **AI/ML (A):** AI fix loops thrive on specificity. E0508/E0509/E0512 are different bugs with different fixes. Separate codes = separate fix patterns = faster convergence.

### Resolution

The `?` operator is validated during the **type checking phase** (Phase 2: type-aware), ensuring codegen never processes invalid `?` usage. `?` works on both **`Result[T, E]` and `Option[T]`** with no cross-type mixing — `?` on Result requires a Result return type, `?` on Option requires an Option return type. Error types require **exact structural match** (`E1 == E2`), consistent with the 4-1 no-auto-into vote. Four **separate error codes** provide targeted diagnostics: E0502 (invalid operand type), E0508 (Result `?` in non-Result fn), E0509 (Option `?` in non-Option fn), E0512 (error type mismatch). See §3c.2 for the full specification.

---

## JSON Codec Design — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions. Each expert ran as a separate agent and returned votes without seeing other experts' reasoning.

**Q1: Dynamic vs typed entry point (4-1 for C: both as equal peers)**

- **Systems (C):** Both paths serve different codegen profiles. Dynamic parsing allocates a single GC'd JsonValue tree — predictable, one allocation pattern. Typed deserialization through `json.decode[T]` compiles to the same parse + field extraction but with monomorphized field access. Neither subsumes the other.
- **Web (C):** JS devs expect `JSON.parse()` for quick prototyping and exploration. But production code wants typed deserialization. Having both at the same level mirrors the JS → TypeScript progression. `json.parse()` for the REPL, `json.decode[User]()` for the service.
- **PLT (A):** `json.parse : Str → Result[JsonValue, JsonError]` and `from_json : JsonValue → Result[T, JsonError]` are two composable morphisms. `decode` is their composition — a derived operation, not a peer. Elevating it to "equal" status obscures the algebraic structure. *(dissent)*
- **DevOps (C):** Dynamic and typed paths produce different diagnostic surfaces. `json.parse` + navigation gives runtime path errors ("key 'age' not found"). `json.decode[User]` gives structural errors ("field 'age' expected Int, got String"). Both are valuable, neither is reducible.
- **AI (C):** `json.parse(s)` maps directly to Python/JS training data — the two dominant JSON patterns. `json.decode[User](s)` maps to Rust/Go typed patterns. Having both means LLMs can use whichever pattern has stronger signal for the context.

**Q2: Module API surface (4-1 for B: medium 5 functions)**

- **Systems (B):** `json.encode[T]` eliminates the two-step `json.stringify(x.to_json())` ceremony. The compiler can fuse these into a single pass. `json.pretty` is trivial sugar but prevents every project from writing their own indentation function.
- **Web (B):** `json.encode(user)` is the `JSON.stringify(user)` equivalent every web developer expects as a one-liner. `json.pretty()` is the first thing anyone reaches for when debugging. These five functions are the complete "80% API."
- **PLT (A):** `json.encode[T](x)` is trivially `json.stringify(x.to_json())` — a two-character pipe. Adding derivable convenience functions to the module surface violates minimality. Three functions form the algebraic basis; the rest are derived. *(dissent)*
- **DevOps (B):** Five autocomplete entries in LSP is immediately discoverable. `json.pretty` prevents the inevitable "how do I pretty-print JSON in Pact" FAQ. Every real project needs it; stdlib should provide it.
- **AI (B):** `json.encode(user)` is the single most common serialization pattern across all training data. Requiring two-step `json.stringify(user.to_json())` forces LLMs to remember method chaining order — unnecessary decision point.

**Q3: JsonValue navigation return types (5-0 for A: Option-returning)**

- **Systems (A):** Option is zero-cost — null pointer or tag bit. Result carries error string allocation overhead on every navigation call. For chains like `.get("a")?.get("b")?.as_str()`, Option avoids N error allocations for N navigation steps.
- **Web (A):** `json.get("key")?.as_str() ?? ""` is the Pact equivalent of JS optional chaining `data?.key ?? ""`. Familiar, fluent, minimal boilerplate. Result would force `.map_err()` at every step — hostile to the 90% case.
- **PLT (A):** Navigation on a sum type is inherently partial — a `JsonValue.Int` has no string projection. `Option` is the canonical encoding of partiality in type theory. Result implies a meaningful error distinct from "not applicable" — but `.as_str()` on an Int isn't an error, it's a type mismatch the caller expects.
- **DevOps (A):** Option composes with both `?` (propagate None) and `??` (provide default). Result would require matching error types with the enclosing function's error — and Pact requires exact error match, so every `.get()` would need `.map_err()`. Diagnostic-hostile.
- **AI (A):** `.get("key")?.as_str() ?? ""` is a single learnable three-part pattern (navigate, project, default). Each piece uses a Pact feature LLMs already know. Result would add error handling boilerplate that varies per context — more decision points, more generation errors.

**Q4: Two-step vs one-step deserialization (5-0 for A: two-step canonical)**

- **Systems (A):** `from_json(JsonValue)` is already the trait method — decided in §3.6.2. `json.decode[T]` is mechanically `json.parse(s) |> T.from_json()`. No new trait surface, no new codegen path. The compiler can optimize the composition.
- **Web (A):** Two-step matches the mental model every developer has: parse the text, then validate the shape. When something goes wrong, you know which step failed. `json.decode[T]` is the one-liner shortcut for when you don't care.
- **PLT (A):** Composition: `decode = from_json ∘ parse`. The Deserialize trait takes `JsonValue` (already committed). Changing to a string-based trait would contradict §3.6.2 and lose the ability to deserialize sub-trees of already-parsed JSON.
- **DevOps (A):** Two-step produces two distinct error locations: parse errors point at line/column in JSON text, type errors point at field mismatches against struct definition. Collapsing into one step merges these error domains.
- **AI (A):** Both `json.parse(s)` and `json.decode[User](s)` are reliably generated patterns. Two-step gives more explicit error handling that LLMs can reason about step by step.

---

## HTTP Client Effect Mapping — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions for the `Net.Connect` effect operation table.

**Q1: Method surface — verbs vs request() vs both (4-1 for C: both with request() as core)**

- **Systems (C):** Single `request()` vtable entry = one function pointer. Verb methods are compiler-generated wrappers that inline to direct `request()` calls with pre-populated Request structs. Zero overhead. Handler implementors write one method. The vtable stays minimal — 6 function pointers for verbs would bloat every Handler[Net.Connect] allocation.
- **Web (C):** `net.get(url)` is what every web dev reaches for first — it's the 90% case. But `net.request(req)` covers complex cases (custom methods, multipart, auth flows). Both exist in Python requests (`requests.get()` + `requests.request()`). Handler authors implementing one method is a huge win for the testing story.
- **PLT (C):** The single `request()` operation is the minimal effect interface — one typing rule, one handler obligation. Default methods on effects follow the same principle as Iterator adapters: implement `next()`, get `map`/`filter`/`collect` free. This is compositionally clean — the verb methods are derived, not primitive.
- **DevOps (C):** Handler completeness error saying "missing operation: request" + one-line hint is far better than "missing operations: get, post, put, delete, head, patch" + six-line implementation skeleton. Mock handlers in tests go from 6 methods to 1. LSP autocomplete still shows all verb methods — they're just default-implemented.
- **AI/ML (A):** `net.get(url)` maps directly to `requests.get(url)` from Python training data — the most common HTTP pattern in LLM corpora. Having `request()` as the "real" operation with verbs as sugar means LLMs must understand the desugaring relationship. The verb-method pattern from Python/Rust reqwest has overwhelming training signal. *(dissent)*

**Q2: Request configuration (4-1 for A: Request builder struct)**

- **Systems (A):** Request struct is flat data — method, url, body, headers map, timeout int. Builder methods are field writes, zero allocation beyond the struct itself. The struct compiles to a predictable C struct. Method chaining `.with_header().with_timeout()` is sugar for field assignment — inlined away.
- **Web (C):** Struct with defaults is the most Pact-native pattern. `RequestOptions { timeout: 5000 }` leverages struct defaults — no builder ceremony needed. But builder chaining is also fine for web devs used to fetch options objects. *(dissent)*
- **PLT (A):** Request as a first-class value is compositionally superior — it can be stored, passed, partially configured, and composed. The builder pattern produces a value of type Request; the struct IS the request. Both are the same underlying product type.
- **DevOps (A):** Builder has the best LSP autocomplete story. Typing `Request.new("GET", url).with_` shows all configuration options. Each `.with_*` is a named, discoverable method. Options struct requires knowing field names upfront.
- **AI/ML (A):** Builder chaining (`.with_header().with_timeout()`) is the dominant pattern for request configuration across Python requests, Go http.NewRequest, Rust reqwest, Java HttpClient. LLMs reliably generate builder chains.

**Q3: Response type (5-0 for B: transparent struct)**

- **Systems (B):** Direct field access compiles to struct member access in C — a load instruction, not a function call. `response.status` is a register read. `.status()` method would dispatch through a vtable or at minimum a call instruction. For hot paths checking status codes, this matters.
- **Web (B):** `response.status` and `response.body` are what every developer expects. Destructuring `let Response { status, body, .. } = net.get(url)?` is clean and familiar. Add `.json()` as a convenience method via trait impl — best of both worlds.
- **PLT (B):** A response is a product type (status × body × headers). Making it transparent exposes its algebraic structure for pattern matching. Behavior belongs on traits, not hidden behind opaque accessors. This is the principled separation of data from behavior.
- **DevOps (B):** Field access gives better LSP hover information — "status: Int" is self-documenting. Pattern matching on `Response { status: 404, .. }` produces excellent diagnostics when patterns don't match. Methods would hide the structure.
- **AI/ML (B):** Struct field access is the single most universal pattern across all programming languages. `response.status` has near-100% LLM generation accuracy. Method-based access adds unnecessary indirection that LLMs occasionally get wrong (`.status()` vs `.status` vs `.get_status()`).

**Q4: WebSocket/SSE separation (4-1 for C: defer to v2)**

- **Systems (C):** WebSocket requires persistent connection state, framing protocol, message buffering — completely different codegen from stateless request/response HTTP. Mixing them in the same vtable conflates two distinct runtime models. Ship HTTP, design WebSocket properly later.
- **Web (A):** Web developers expect WebSocket support. Real-time features (chat, notifications, live updates) are core to modern web apps. A separate `Net.WebSocket` sub-effect with `net.ws_connect(url)` would be clean capability separation while still being v1. *(dissent)*
- **PLT (C):** WebSocket introduces stateful bidirectional channels — algebraically different from the request/response pattern. Request/response is `A → B`, WebSocket is a session type. Rushing the design would create type-theoretic problems that are hard to fix later.
- **DevOps (C):** HTTP client is the critical path. WebSocket adds connection lifecycle management, reconnection diagnostics, message ordering tests. Each is a significant diagnostic surface. Ship HTTP, learn from it, then design WebSocket diagnostics properly.
- **AI/ML (C):** WebSocket APIs have much less training data diversity than HTTP client patterns. LLMs will struggle with novel WebSocket-over-effects patterns. Building HTTP first creates canonical training data before adding the next protocol.

---

## HTTP Server Routing Model — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions for the `Net.Listen` effect operation table, middleware composition, error recovery, and `@requires` boundary validation.

**Q1: Server API surface (3-2 for A: minimal value-server)**

- **Systems (A):** The Server value is a flat struct with a function pointer array for routes. Effect boundary is only at `net.listen()` and `server.serve()`, keeping vtable dispatch out of the per-request hot path. Option B routes everything through effect dispatch (indirect branch per route lookup, kills branch prediction). Option C adds unnecessary abstraction — the value-server already IS a route table internally. Matches the existing web_api.pact code, minimizing codegen churn.
- **Web (A):** The existing web_api.pact already shows this pattern and it reads beautifully: `net.listen()` returns a server, you chain `.route()`/`.get()`/`.post()`, then call `.serve()`. This is the Express/Flask/Go pattern every web developer knows. Option B adds ceremony obscuring the "I'm building routes and starting a server" intent. Option C adds indirection; the value-server already lets you build routes programmatically.
- **PLT (C):** Routes-as-data is the principled choice. A `RouteTable` is a pure value admitting algebraic composition (union, intersection, prefix scoping) and compile-time analysis (exhaustiveness, overlap detection). Option A's `.route()` is imperative mutation — order-dependent, opaque to the compiler, not composable. Data admits more equational reasoning than operations. *(dissent)*
- **DevOps (C):** Routes-as-data enables compile-time conflict detection via `pact check`, LSP navigation between routes and handlers, and startup route table dumps for operational visibility. `.merge()` maps to real team composition patterns where different modules contribute routes. *(dissent)*
- **AI/ML (A):** LLMs have seen Flask's `app.route()`, Express's `app.get()`, and Go's `http.HandleFunc()` millions of times in training data. `net.listen() → Server, .route(), .serve()` is a direct structural analogue. Option B has zero training analogues — LLMs would hallucinate incorrect syntax. The existing web_api.pact reinforces this form for fine-tuning.

**Q2: Middleware model (4-1 for A: functional wrapping)**

- **Systems (A):** `fn(handler) -> handler` compiles to direct function pointer composition in C. The wrapping chain collapses at server startup, not per-request. Option B (effect handler stacking) means per-request vtable traversal through nested `with` blocks. Option C requires runtime list iteration with two indirect calls per entry per request.
- **Web (A):** Middleware as `fn(handler) -> handler` is the most proven pattern across web frameworks: Express `app.use()`, Rack, WSGI. Composes naturally, easy to understand. Effect handler stacking forces web devs to think in terms of effect layering just to add CORS headers — massive DX tax. Wrapping means middleware can short-circuit by returning early.
- **PLT (B):** Middleware is cross-cutting computation over request/response flow — precisely what algebraic effect handlers model. Handler stacking gives compositionality, well-scoped lifetimes, and the resumption/abort choice. Algebraically cleaner than functional wrapping which requires manual plumbing. *(dissent)*
- **DevOps (A):** Simple `fn(handler) -> handler` gives clear stack traces showing "logging → auth → handler" for debugging. Effect stacking makes middleware ordering opaque in diagnostics. Middleware debugging is painful enough without indirection.
- **AI/ML (A):** `fn(handler) -> handler` is the single most common middleware pattern across training corpora. Express, Go, WSGI, Rack — all follow this shape. LLMs generate it with extremely high accuracy. Effect handler stacking has essentially zero training signal.

**Q3: Error recovery (3-2 for C: typed error handler)**

- **Systems (C):** Option A (catch_panic) requires setjmp/longjmp — expensive, interacts badly with stack cleanup. Option C gives a `ServerError` tagged union with configurable error handler function pointers per route. No unwinding, predictable control flow. The sum type enables exhaustive match checking.
- **Web (B):** An `on_error` callback with a `ServerError` sum type hits the sweet spot: simple to set up, typed error variants, integrates with pattern matching. Per-route error overrides are over-engineered for the common case — most apps want one global error handler. *(dissent)*
- **PLT (C):** A `ServerError` sum type makes the error domain explicit and pattern-matchable. Placing error handlers alongside routes keeps configuration as a single coherent value. Per-route overrides are semantically important — API routes return JSON, page routes return HTML.
- **DevOps (C):** `ServerError` sum type enables exhaustive handling checks in `pact check` and LSP warnings for unhandled cases. Per-route overrides critical for real APIs (JSON errors for `/api/*`, HTML for `/pages/*`). Putting error strategy alongside routes makes it visible and inspectable.
- **AI/ML (B):** `on_error` with a `ServerError` sum type is closest to Express error middleware, which LLMs generate reliably. Per-route overrides add decision points LLMs will get wrong. One canonical error handler maps naturally onto the dominant training data pattern. *(dissent)*

**Q4: @requires auto-400 boundary detection (4-1 for B: validation effect)**

- **Systems (B):** Compiler emits `validation.contract_violation()` through existing vtable dispatch — zero additional codegen complexity. Default handler returns 400, users swap via standard `with` blocks. Reuses the effect system rather than creating a parallel dispatch mechanism. Also works outside HTTP contexts, so the investment amortizes across the whole language.
- **Web (B):** Most flexible option. `validation.contract_violation()` with default 400 handler means it works out of the box, and users can change to 422 for RFC 9110, add custom formatting (JSON:API, GraphQL errors). Plays beautifully with Pact's `with handler { }` testing pattern.
- **PLT (B):** Most compositional option. Generating `validation.contract_violation()` as an effect operation transforms a static specification (`@requires`) into a dynamic effect that participates in the handler mechanism. Reuses algebraic effect infrastructure — swappable, testable, composable.
- **DevOps (B):** Validation failures appear in effect traces for debugging. Effect handler swapping lets users customize to 422, structured JSON, localized messages without fighting the framework. Option A too rigid, option C overloads the route table.
- **AI/ML (A):** Route-registration marker requires zero effort from the developer or the LLM. Compiler auto-detects `.route()` calls and generates 400 responses for contract violations. Zero new concepts — LLMs just write `@requires` and register routes. Options B and C add concepts the LLM must learn. *(dissent)*

---

## Additional Built-in Types — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 5 questions. All votes unanimous.

**Q1: DateTime/Instant value type — what `time.read()` returns (5-0 for stdlib Instant)**

- **Systems:** `struct { int64_t nanos; }` is zero-cost nominal typing. Same codegen as raw Int but prevents nonsense like adding two timestamps. Tier 2 placement needs stable ABI contract with effect system.
- **Web/Scripting:** Every JS dev knows `Date.now()` returning a raw number is painful — you immediately wrap it. Go's `time.Now()` returning `time.Time` is vastly better DX. One import line is nothing; LSP handles it. Methods like `.to_rfc3339()` and `.elapsed()` are discoverable on the value.
- **PLT:** Time points form an affine space over durations. `Int` collapses point/vector distinction, allowing nonsensical `time1 + time2`. Distinct `Instant` type encodes correct algebraic structure statically. Tier 2 keeps the core language small.
- **DevOps:** Diagnostic difference between `got Int` and `got Instant` is massive. LSP hover and autocomplete for `.elapsed()`, `.to_rfc3339()` is a huge ergonomics win. Missing import diagnostic: `Instant not found. Did you mean: import std.time.Instant?`
- **AI/ML:** Raw Int maximizes initial generation accuracy but creates long-tail hallucination bugs. Stdlib Instant with `.to_rfc3339()` gives LLMs method-call patterns matching Rust/Go/Python training data. Import is one learnable pattern.

**Q2: Duration type — what `time.sleep()` accepts (5-0 for stdlib Duration)**

- **Systems:** Named constructors kill unit confusion bugs. `.scale(Int)` method handles sealed-trait ergonomic gap — compiles to a single `imul`. Zero overhead wrapper.
- **Web/Scripting:** `time.sleep(5000)` — milliseconds? seconds? Every web dev has been bitten. `Duration.seconds(5)` is self-documenting and eliminates entire class of bugs. Named constructors guide toward correct usage.
- **PLT:** Duration carries dimensional information; `Int` is dimensionless. Mars Climate Orbiter was lost to a unit confusion bug — same error class. Named constructors enforce units at construction, the only correct approach without a units-of-measure system.
- **DevOps:** `time.sleep(5)` — 5ms or 5 seconds? No tooling can catch this with raw Int. With Duration: `expected Duration, got Int. Hint: use Duration.ms(5) or Duration.seconds(5)`. Actionable error messages teach the API.
- **AI/ML:** Strongest vote. Unit confusion with raw Int is a *guaranteed* bug source. Python-trained LLMs write `time.sleep(5)` meaning seconds. `Duration.seconds(5)` is unambiguous — LLMs can't get the unit wrong.

**Q3: Bytes/ByteArray (5-0 for stdlib Bytes, Tier 1)**

- **Systems:** `List[U8]` with boxed elements is 8-24 bytes overhead *per byte*. Contiguous `uint8_t*` buffer is non-negotiable for I/O, FFI, crypto. Tier 1 because FS/Net effects must return contiguous memory.
- **Web/Scripting:** Web devs deal with binary data constantly — file uploads, image processing, crypto. `List[U8]` is semantically wrong and performance-terrible. Dedicated `Bytes` with `.slice()`, `.to_hex()` is table stakes.
- **PLT:** `List[U8]` is parametrically correct but representationally wrong. Same lesson as Haskell's `[Word8]` vs `ByteString`. Nominal type boundary lets compiler guarantee contiguous layout.
- **DevOps:** Debug output `Bytes(ff d8 ff e0 ...)` vs `[255, 216, 255, 224, ...]`. Hex display alone justifies a dedicated type. Error: `expected Str, got Bytes. Hint: use data.to_str()`.
- **AI/ML:** `List[U8]` triggers `.decode("utf-8")` hallucinations from Python training data. Dedicated `Bytes` maps to Go's `[]byte` (very well-represented in training data).

**Q4: Numeric extensions (5-0 for F32 built-in + Decimal/BigInt stdlib)**

- **Systems:** F32 maps to `float`, uses existing FPU hardware, fits sized-numeric pattern. Decimal/BigInt are complex enough for stdlib Tier 2. 128-bit fixed-point for Decimal representation.
- **Web/Scripting:** F32 fits sized numeric pattern. Decimal matters for payments — e-commerce, fintech need exact arithmetic. BigInt useful for crypto and large ID spaces.
- **PLT:** F32 is isomorphic to I8/I16/I32 — fixed-size primitive with direct C type. Excluding it is unprincipled asymmetry. Decimal/BigInt have variable/unbounded representations — categorically different. Sealed arithmetic must be absolute; named methods for Decimal/BigInt.
- **DevOps:** F32 consistent with I8/U64 in error messages. Decimal: `expected Decimal, got Float. Hint: use Decimal.from_str("19.99")`. Overflow diagnostics can suggest BigInt.
- **AI/ML:** F32 alongside I32/U64 is consistent pattern. Stdlib Decimal critical — without it, LLMs use Float for money 100% of the time. BigInt niche enough for stdlib, not built-in.

**Q5: UUID classification (5-0 for stdlib UUID, Tier 2)**

- **Systems:** 16-byte `memcmp` beats 36-byte string comparison. Memory: 160MB vs 360MB for 10M rows. Tier 2 is right — no effect handle signature needs UUID.
- **Web/Scripting:** Every web API uses UUIDs. `UUID.random()`, `UUID.parse()`, `.to_str()` is basic web infrastructure. Type safety: `fn get_user(id: UUID)` is self-documenting.
- **PLT:** UUIDs and strings have different algebras. `uuid.concat(other_uuid)` type-checks with Str but produces garbage. Nominal type prevents confusion. Not phantom-typed by version — premature for v1.
- **DevOps:** Parse errors are clear: `UUID.parse("not-a-uuid")` → `Err(ConversionError("invalid UUID format"))`. LSP: `.to_str()`, `.random()`, `.parse()` all discoverable.
- **AI/ML:** `UUID.random()` has excellent training data: Java `UUID.randomUUID()`, Python `uuid.uuid4()`, Go `uuid.New()`. Type safety catches arbitrary string passing. Recommend `.random()` — shortest, avoids version-specific naming.

---

## Env Effect API — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 5 questions about the Env effect API surface. High consensus: four questions unanimous, one 4-1.

**Q1: Env.Read operations (5-0 for B: Standard)**

- **Systems:** `vars()` and `cwd()` are syscall primitives (`environ`, `getcwd`) — not convenience helpers. Every systems program that spawns child processes needs the env map. `cwd()` is needed for relative path resolution. `home()` and `exe_path()` are derivable from `env.var("HOME")` and `/proc/self/exe` — stdlib, not effect surface.
- **Web/Scripting:** Config loading iterates env vars constantly. `env.vars()` to build a config map is bread-and-butter. `env.cwd()` needed for file resolution. Without them, people loop over hardcoded var name lists — ugly and fragile. `home()` and `exe_path()` are niche, defer to v2.
- **PLT:** Four operations form a clean closed set: scalar query (`var`), bulk query (`vars`), positional args (`args`), working directory (`cwd`). `home()` and `exe_path()` are derivable from `var("HOME")` — they add surface without adding capability.
- **DevOps:** `vars()` and `cwd()` essential for build scripts, CI runners, CLIs. Omitting them forces shell-outs. `home()` and `exe_path()` niche — defer them.
- **AI/ML:** These four are universal across all languages — LLMs will hallucinate `env.vars()` and `env.cwd()` even if not provided. Including them prevents hallucination errors. `home()` and `exe_path()` are niche — LLMs won't expect them on the env handle.

**Q2: Env.Write operations (4-1 for B: Standard)**

- **Systems:** `set_var` and `remove_var` are the two operations on the process environment table (`setenv`/`unsetenv`). Symmetric with read side. `set_cwd()` is process-global `chdir()` — breaks concurrent code, violates structured concurrency. If needed, should be a scoped handler.
- **Web/Scripting:** `remove_var()` needed for test setup/teardown. Setting var to empty string is semantically different from removing it. `set_cwd()` is dangerous in concurrent contexts.
- **PLT:** `remove_var` is the capability-attenuation primitive — clearing sensitive vars before delegating to untrusted code. Without it, only `set_var(name, "")` which is semantically different. `set_cwd` would require both Env.Write and FS capabilities — overly complex.
- **DevOps:** `remove_var()` is the natural complement to `set_var()`. Asymmetry confuses users. `remove_var()` on non-existent key should silently succeed (POSIX semantics).
- **AI/ML:** *(dissent)* Only `set_var()`. `remove_var` is rare in training data — fewer write ops means fewer ways LLMs generate destructive code. Can be added later without breakage.

**Q3: env.exit() placement (5-0 for A: Under Env)**

- **Systems:** `exit()` is in the same domain as process environment. Consistency with existing examples matters. Moving to `Process` means CLI programs need two effects (`Env.Read` + `Process`) — needlessly verbose. Standalone `exit()` breaks the ocap model entirely — can't be intercepted by handlers, can't be mocked in tests.
- **Web/Scripting:** `env.exit()` is the most intuitive. `Process` is about spawning/signaling child processes — different domain. Free function `exit()` would be the only side-effectful free function, contradicting Pact's core thesis.
- **PLT:** `exit` is intentional control flow with observable results (exit code), unlike `panic` which represents program errors. Making it an effect operation means handlers can intercept it for testing. The `-> Never` return type on handler operations is sound — handlers abort the computation rather than resuming past exit.
- **DevOps:** Already in examples. Keeps handle count low. Introducing Process just for `exit()` is terrible ergonomics — whole new effect for one operation. Diagnostic: `error[E0412]: missing required effect 'Env'` with actionable fix suggestion.
- **AI/ML:** Despite `process.exit(1)` having massive Node.js training weight, Pact has no `process` handle for this. Creating Process just to match Node idiom adds confusion. LLMs that generate `process.exit(1)` get a clear error and self-correct.

**Q4: Env sub-effect granularity (5-0 for A: Keep Read + Write)**

- **Systems:** Read/Write matches every other effect. Meaningful attenuation: compromised dependency with `Env.Read` can observe but not mutate. `Env.Args` distinction doesn't prevent real attacks — args often contain secrets too. Flattening loses useful information.
- **Web/Scripting:** Config-loading code declares `! Env.Read`, test setup declares `! Env.Write`. Matches mental model. `Env.Args` is over-engineering — args and env vars co-occur in practice.
- **PLT:** `Env.Args` without `Env.Read` prevents what attack? Attacker reads `argv` but not `$SECRET_KEY`? Not a meaningful capability boundary. Read/Write captures the real distinction: observation vs mutation.
- **DevOps:** Read/Write is the natural permission split. `Env.Args` adds granularity nobody asked for. Flattening loses useful permission info for LSP and audit tools.
- **AI/ML:** Two sub-effects is the sweet spot. Read/Write is universal pattern. Adding third = 50% more decision points for minimal benefit.

**Q5: Return types (5-0 for A: Simple Option[Str])**

- **Systems:** GC language, no ownership system. `Option[Bytes]` is a Rust/systems concern. 99.9% of env vars are valid UTF-8. `Result[Str, EnvError]` conflates "not set" (normal) with "invalid bytes" (nearly impossible). Non-UTF-8 is a v2 cross-platform concern.
- **Web/Scripting:** `Option[Str]` + `??` is beautiful: `let port = env.var("PORT") ?? "8080"`. Already in examples. Non-UTF-8 is not a web concern. Runtime should lossy-convert and document the behavior.
- **PLT:** `Option[Str]` is a partial function from names to UTF-8 strings. Partiality is honest (var may not exist). Value domain totality (always UTF-8 when present) is a deliberate modeling choice, same as `Int` being always 64-bit signed.
- **DevOps:** `Option[Str]` is the right default. `Result` or dual API pollutes LSP autocomplete. Non-UTF-8 is a platform edge case for 99% of programs.
- **AI/ML:** `Option[Str]` maps directly to `??` pattern. `Result` forces LLMs to choose between `?` and `??`. Dual API doubles surface. Non-UTF-8 too rare to justify.

---

## Const Evaluation — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 4 questions about compile-time constant evaluation rules. Two unanimous, two contested.

**Q1: What qualifies as a const expression? (5-0 for B: Literals + arithmetic/boolean ops)**

- **Systems:** Literal folding + arithmetic maps directly to `static const` in C. Option D (any pure expression) requires whole-program purity analysis that doesn't exist. Option C (`const fn`) needs a compiler interpreter. B covers 90%+ of real uses: `let TK_FN = 0`, `let BUFFER_SIZE = 1024 * 64`.
- **Web/Scripting:** Devs expect `MAX_SIZE = 1024 * 1024` to work. Literals-only forces precomputed magic numbers. Option D creates a "is this const?" guessing game like TypeScript's `as const`. B is the sweet spot.
- **PLT:** Option D conflates compile-time evaluability with runtime purity — evaluating `fib(40)` at compile time is undecidable. Option C introduces function coloring. B gives a decidable, syntactic set of const expressions. `"hello".len()` being non-const may feel arbitrary, but opening method calls is `const fn` in disguise.
- **DevOps:** Closed set = precise error messages. "function call 'config.port()' is not a compile-time constant" vs "this expression might have effects." B is the only option where constness is syntactically obvious without type information.
- **AI/ML:** Simple arithmetic folding has near-zero LLM error rate in training data. `const fn` causes 15-20% error rates in Rust training data. Option D requires deep semantic reasoning transformers fail at.

**Q2: Should Pact have a `const` keyword? (3-2 for B: Required keyword)**

- **PLT:** `const` and `let` inhabit different evaluation phases. Conflating them (Option A) violates the principle that distinct concepts deserve distinct syntax. Option C (optional) creates two forms with identical semantics — Principle 2 violation.
- **DevOps:** With `const`, LSP shows "compile-time constant" on hover without analysis. `pact fmt` can enforce UPPER_SNAKE_CASE. Changing a const's RHS to non-const errors at the *definition*, not downstream use sites.
- **AI/ML:** `const` is top-5 most recognized keywords across all LLM training data (C, C++, Rust, JS, TS, Go). Distinct token for the model to key on. Without it, `let MAX = 100` has noisy semantics across training data.
- **Systems:** *(dissent)* The compiler already emits `static const` for immutable module-level `let` with simple RHS. A separate keyword is a distinction without a difference — if the RHS is const and the binding is immutable, it IS const. `let` + `let mut` already encodes the important information.
- **Web/Scripting:** *(dissent)* Pact already has `pub let api_version = "2.0"` described as "equivalent to a named constant" (§2.12.1). Adding `const` creates a decision at every module-level binding. TS's `const` vs `let` is a constant source of confusion. One keyword, one concept.

**Q3: Can struct/enum constructors appear in const expressions? (3-1-1 for B: Struct literals with const fields)**

- **PLT:** A struct is a product type. If components are const, the composite is const — this follows from compositional semantics. Denying this (Option A) would be a compositionality failure. B is the natural first step; C follows trivially later.
- **DevOps:** Struct defaults are already const contexts. If `const DEFAULT_CONFIG = ServerConfig { port: 8080 }` doesn't work, users repeat defaults everywhere — drift and CI failures. `Type.new()` is not const (function call), but `Type { field: value }` is (literal syntax).
- **AI/ML:** Struct literal constants are ubiquitous in training data (C, Rust, TS, Go). LLMs generate these correctly. Nested structs (C over B) follow naturally. *(voted C, counted as supporting B since B is the minimal version of C)*
- **Web/Scripting:** *(voted C)* Every web framework has nested config structs. Blocking nested structs creates an arbitrary cliff devs trip over.
- **Systems:** *(voted A)* Struct const literals require C compound literals or static initializers — reworking codegen. Current compiler uses `__pact_init_globals()` runtime initialization. Ship v1 with scalar-only, add struct const in v1.1.

**Q4: How does const evaluation interact with C codegen? (5-0 for C: Compiler-evaluated, emitted as literals)**

- **Systems:** Only option giving Pact compiler full control. `#define` loses type safety. C static initializer rules vary by standard version. Compiler folds `1024 * 64` to `65536` and emits literal — maximally portable.
- **Web/Scripting:** Maximum flexibility on Pact side, dead simple C output. Compiler is source of truth, not the C compiler. Extend const-eval later without changing codegen strategy.
- **PLT:** Cleanest phase factoring. Pact compiler owns const-eval semantics; C backend is emission target, not semantic participant. Backend independence essential for future WASM/LLVM targets.
- **DevOps:** Cleanest diagnostics, most portable C. No macro expansion bugs, no compound literal portability issues, no platform-dependent static initializer behavior.
- **AI/ML:** Simplest generated C for LLM-assisted debugging. Plain literals have zero ambiguity. Decouples const-eval complexity from C codegen complexity.

---

## Web-Service Stdlib Tier — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 6 module tier placements. The core question: which web-service modules should be Tier 1 (ships with compiler, version-locked) vs Tier 2 (blessed separate package under `std/` org, versions independently)?

**Key architectural distinction:** Effect system types (`Request`, `Response`, `Headers`, `NetError`, `Query[C]`, `JsonValue`) are compiler-known and ship with the compiler regardless of tier classification. Stdlib modules provide convenience layers ABOVE effect operations — retry logic, connection pooling, routing frameworks, structured logging formatters. The tier question is about these convenience layers, not the core types.

**Q1: JSON codec — std.json (5-0 for Tier 1)**

- **Systems:** `Serialize`/`Deserialize` traits and `JsonValue` are compiler-known. The codec functions are the only way to USE those types. Shipping them separately creates a bizarre split. Pure implementation, tiny codegen footprint.
- **Web/Scripting:** Most clear-cut T1. Every language Pact competes with has JSON built-in. `import std.json` must work on day one with zero `pact.toml` entries. The `fetch.pact` example already uses `json.parse()`.
- **PLT:** `@derive(Serialize)` generates `fn to_json(self) -> JsonValue`. The function consuming `JsonValue -> Str` must be in the same versioning domain. Separating derive mechanism from codec breaks compositionality.
- **DevOps:** LSP autocomplete for `json.parse()` and `@derive(Serialize, Deserialize)` should work on `pact init` with zero config. JSON spec is stable (RFC 8259), so version-lock risk is near zero.
- **AI/ML:** JSON is the single most generated code pattern in LLM web/API code. Making it T2 means every AI-generated web project has a "did you `pact add`?" failure on first compile.

**Q2: HTTP client — std.http.client (3-2 for Tier 2; PLT/Web dissented)**

- **Systems:** HTTP semantics evolve (HTTP/2, HTTP/3). Version-locking convenience types violates zero-cost — unused HTTP types in every hello-world. Effect system already provides the core types.
- **Web/Scripting:** *(dissent — T1)* `Request`/`Response` are the output types of `net.get()` effect handles. Making effect handle return types live in a separate package is a DX nightmare.
- **PLT:** *(dissent — T1)* `fn request(req: Request) -> Result[Response, NetError]` is the core `Net.Connect` operation. These types ARE the effect's operational interface. Version mismatch breaks handler soundness.
- **DevOps:** Effect system already provides `Net.Connect` with `Request`/`Response` types. `std.http.client` adds higher-level conveniences (retry, redirect following, connection pooling) that version independently. `pact init --template web` auto-adds it.
- **AI/ML:** HTTP client APIs are large and evolving. Training data shows massive variance across languages. T2 with stable import path allows API evolution.

**Resolution note:** The PLT/Web dissent highlights that core HTTP types (`Request`, `Response`, `Headers`, `NetError`) must be compiler-known and ship with the compiler as part of the effect system definition (§4.4.1). The `std.http` Tier 2 package provides convenience layers above these types — builder patterns, retry policies, redirect following, connection pooling. The types themselves are not in Tier 2.

**Q3: HTTP server — std.http.server (5-0 for Tier 2)**

- **Systems:** Server module is the largest stdlib module by code volume. Including it in every binary unconditionally is wasteful. The `Net.Listen` effect handle provides the primitive.
- **Web/Scripting:** Server frameworks are opinionated. Go's `net/http` locked in 2012 is the cautionary tale. The effect system provides the primitive; the framework should iterate independently.
- **PLT:** `Server`, routing, middleware are application-level composition patterns built ON TOP of `Net.Listen`. These are framework choices, not type-theoretic necessities.
- **DevOps:** Server frameworks evolve fast. `pact init --template web-server` auto-adds it. Version-locking a web framework to compiler release cadence is Go's `net/http` stagnation.
- **AI/ML:** Server routing patterns have the widest variance in LLM training data. Freezing a pattern as T1 creates training/reality mismatch as the framework evolves.

**Q4: SQL/DB — std.db (5-0 for Tier 2)**

- **Systems:** DB drivers require linking against external C libraries (`libpq`, `libsqlite3`). T1 would break the "single compiler binary, no external deps" model.
- **Web/Scripting:** PostgreSQL, SQLite, MySQL each have different type systems and drivers. `Query[C]` and `db.*` effect handles are already the thin interface (like Go's `database/sql`).
- **PLT:** `Query[C]` is compiler-known for injection safety. Types around it (connection pools, transaction builders, row mapping) are library-level concerns with high domain variability.
- **DevOps:** Different projects need different drivers. No single DB package satisfies everyone. Templates (`pact init --template api`) handle onboarding.
- **AI/ML:** Training data shows massive fragmentation (SQLAlchemy vs diesel vs GORM vs prisma). No single API dominates.

**Q5: Logging — std.log (4-1 for Tier 2; DevOps dissented)**

- **Systems:** `io.log()` is the primitive. Structured logging varies by deployment target (cloud JSON logs vs minimal stderr). Version-locking one opinion is unnecessary.
- **Web/Scripting:** `io.log()` is already T1 via the effect system. Structured logging wraps it — a deliberate architectural choice, not a default.
- **PLT:** The effect is the capability; the library is the policy. Coupling policy to compiler version violates capability/policy separation.
- **DevOps:** *(dissent — T1)* `io.log()` compiles but if the default handler lives in T2, calling it does nothing useful without adding a dep. The default IO.Log handler must exist somewhere T1.
- **AI/ML:** LLMs will reach for `io.log("message")` as the default, which already works. Structured logging is a deliberate choice, not something AI should auto-generate.

**Resolution note on DevOps dissent:** The default `IO.Log` handler (which writes to stderr) is part of the **runtime**, not a stdlib module. When `main` has implicit effects, the compiler provides default handlers for all declared effects. `io.log()` works out of the box because the runtime includes a basic handler — no `std.log` import required. `std.log` would add structured logging policy (levels, formatters, sinks) above this default, which is correctly Tier 2.

**Q6: Config — std.config (5-0 for Tier 2)**

- **Systems:** `std.toml` is already T1 for file parsing. Config merging, env var overlay, validation are convenience — not infrastructure.
- **Web/Scripting:** Between `env.var()` and `std.toml`, basic config loading already works. A unified layer is framework-level.
- **PLT:** No compiler-known types, no effect system integration beyond FS.Read and Env.Read. Cleanest T2 case.
- **DevOps:** TOML + Env.Read cover basics. Config patterns are opinionated. Let community converge, then bless.
- **AI/ML:** Config patterns are the most fragmented in training data. Worst possible T1 candidate — novel API with zero training data representation.

---

## Non-Local Mutable State — Design Rationale

### Round 1: Panel Deliberation (5 experts)

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on 3 questions. The question arose from a real bug: the Pact compiler's `skip_newlines()` mutates module-level `pos` and `pending_comments` without declaring any effect — it looks pure but isn't. Speculative lookahead called it, collected comments as a side effect, then backtracked `pos` without undoing the comment collection. This caused three separate bugs. The broader question: should mutation of state outside the scope where it was created require tracking?

**Four options considered:**
- **A: Track module-level `let mut` mutation** — targeted, zero runtime cost
- **B: Track ALL non-local mutation** — sound but approaches borrow-checker territory
- **C: Compiler warning** — lint, not enforced
- **D: No change** — rely on convention

**Q1: Should module-level `let mut` mutation be tracked? (5-0 for Yes)**

- **Systems:** Zero runtime cost. Module globals are just C globals; tracking changes nothing in codegen. Functions that don't touch globals can be freely reordered and memoized by the compiler.
- **Web/Scripting:** Yes, reluctantly. It's one more thing to learn, but JS/Python devs understand the concept of global vs local. The 90% case is functions that DON'T touch globals, so most functions are unaffected.
- **PLT:** This is not optional — the purity guarantee is currently **unsound**. A function with no `!` can observe different results depending on call order — the textbook definition of an effectful function. Tracking restores referential transparency for non-mutating functions.
- **DevOps:** Diagnostics are the win: "skip_newlines writes {pos, pending_comments}" tells you exactly what a function touches. LSP can show this on hover. The diagnostic surface is excellent.
- **AI/ML:** This is the highest-value change for AI. An LLM reading a function can now know which globals it touches. The compiler catching AI mistakes at this level is exactly what an AI-first language should do.

**Q2: Should mutation of GC-aliased collections (List/Map/Set) received as arguments be tracked? (5-0 for No — defer to v2)**

- **Systems:** This is Rust's borrow checker repackaged. Tracking `.push()` on a received List means tracking every method call on every GC'd object. Pact deliberately chose GC to avoid this complexity.
- **Web/Scripting:** Hard no. If `.push()` on a list requires annotation, every web dev's first Pact program will be 50% annotations. Collections should just work.
- **PLT:** In principle, mutating a GC-aliased collection violates referential transparency. In practice, Pact chose GC over ownership (§5.1). Defer to v2 where escape analysis could make this targeted.
- **DevOps:** Overwhelming noise. Signal-to-noise ratio collapses. Keep tracking meaningful — globals are a clear boundary, parameter mutation is not.
- **AI/ML:** Collection mutation is too granular for LLMs. Module globals are a crisp, binary check the LLM can learn from one example.

**Q3: Should closure mutation of captured `let mut` be tracked? (5-0 for No)**

- **Systems:** Closures are syntactic sugar for a struct with captured fields. The mutation is contained within the enclosing function's stack frame. No action-at-a-distance.
- **Web/Scripting:** Closures mutating captures is the single most natural pattern in JS/TS/Python. The mutation is visible in the same function body.
- **PLT:** Closures are lexically scoped. The mutation is syntactically visible within the enclosing function. No additional tracking needed for soundness.
- **DevOps:** No diagnostic benefit. Closures are tooling-transparent — the LSP shows them inline with the enclosing scope.
- **AI/ML:** Closures with captured mutable state are a high-frequency pattern in training data. LLMs understand this pattern.

### Round 2: Refinement (PLT, Systems, AI/ML — 3-0)

Round 1 established that module-level mutation must be tracked, but left open the mechanism. The initial proposal was a built-in `! State` effect. Round 2 considered two approaches:

- **A: `! State` effect** — boolean annotation, must propagate through callers, sealed (no handlers)
- **B: Compiler write-set inference** — automatic analysis, binding-parameterized (knows WHICH bindings), no signature annotations

**Decision: Compiler write-set inference (3-0 for B)**

- **PLT:** `! State` is a boolean — it tells you a function touches globals but not WHICH ones. The three parser bugs were caused by incomplete save/restore of specific bindings. Write-set inference tracks `{pos, pending_comments}` per function, which is the actual information needed for diagnostics. Additionally, making this a compiler analysis rather than an effect keeps the effect system clean — effects are for cross-module capabilities, not intra-module implementation details.
- **Systems:** Write-set inference is zero-annotation. The parser has ~80 functions touching module globals. Adding `! State` to 80 functions plus propagating through all callers adds ceremony without additional information — you already know it's a parser, of course it touches parser state. The write set (`{pos, pending_comments, ...}`) is the useful information, and it's inferred automatically.
- **AI/ML:** Against all 5 AI-first criteria: (1) **Learnability** — `! State` is novel; no mainstream language has it. Write-set inference is invisible, nothing to learn. (2) **Consistency** — `! State` would be the only effect that's sealed, has no handler, and tracks reads. Special cases hurt generability. (3) **Generability** — LLMs would over-annotate (adding `! State` where not needed) or under-annotate (missing it in callers). Inference eliminates this failure mode. (4) **Debuggability** — Write sets in diagnostics (`writes {pos, pending_comments}`) are more actionable than boolean `! State`. (5) **Token efficiency** — zero tokens vs `! State` on every mutating function.

**Key design decisions from Round 2:**

| Decision | Outcome | Vote |
|----------|---------|------|
| Writes only (reads are free) | Yes — reading mutable state doesn't corrupt it | 3-0 |
| Transitive within module | Yes — if `a()` calls `b()` which writes `pos`, `a`'s set includes `pos` | 3-0 |
| Cross-module: opaque | Yes — imported function calls are opaque, no cross-module propagation | 3-0 |
| Cross-module statefulness | Use user-defined effects (§4.12) if module wants to expose state changes | 3-0 |
| Not an effect | Yes — compiler analysis like type inference, not a declared effect | 3-0 |
| Remove `effect State` from hierarchy | Yes — no longer a built-in effect | 3-0 |

---

## AI-First Review Pass — Process Decision

### Rationale

Pact is AI-first, but the 5-expert panel gives equal vote weight. The AI/ML expert frequently dissents in 4-1 splits, often arguing "thin training data" or "LLMs will fumble this." Inflating vote weight would let "LLMs haven't seen this" override genuinely good designs — designing for AI learnability is fundamentally different from designing for today's training data coverage. Instead, a structural second-pass review evaluates every decision against AI-first criteria after voting concludes.

### Process Change

- **Equal vote weight preserved** — 5 experts, majority wins, no changes to voting
- **AI-First Review pass added** after vote tally (Step 8.5 in deliberation workflow)
- **5 criteria** evaluated pass/fail on the winning decision:
  1. **Learnability** — Can AI learn this from spec + examples without relying on other languages' training data?
  2. **Consistency** — Follows existing Pact patterns, or introduces a special case?
  3. **Generability** — Can AI reliably generate correct code using this feature?
  4. **Debuggability** — When AI gets this wrong, are error messages clear enough to self-correct?
  5. **Token Efficiency** — Does this minimize token count for common patterns?
- **2+ failures trigger reconsideration** — not a veto, but forces the panel to re-examine with AI-first concerns explicitly on the table
- **0-1 failures** — decision stands, proceed to spec writing

### AI/ML Expert Profile Update

The AI/ML expert's personality was reframed from "statistical thinker valuing training data representation" to evaluating through the 5 criteria above. This ensures the expert argues from principled AI-first design rather than "this pattern exists in training corpora."

---

## `@i` Annotation — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on whether to keep `@i` as a separate annotation, merge it into `///` doc comments, cut it entirely, or redesign it.

**Context:** `@i("text")` was a natural-language intent declaration on functions, types, and modules. Investigation revealed that Pact already has `///` doc comments producing structured compiler-queryable data (§2.1), and examples like `bank.pact` had both `///` and `@i` carrying duplicate information — violating Principle 2 ("one way to do everything"). The drift detection feature (the killer differentiator for `@i`) was deferred to v2+ with no concrete mechanism. `@i` was the only annotation in Pact's system carrying unstructured prose with no formal semantics — every other annotation is compiler-checkable.

**Q1: Keep @i, merge into ///, cut entirely, or redesign? (5-0 for merge into ///)**

- **Systems:** Merge. `@i` adds compiler complexity (parsing, AST storage, symbol table field) for zero runtime benefit. `///` already exists in the AST — no reason to store intent twice. Rust and Go prove doc comments handle this without a separate annotation.
- **Web/Scripting:** Merge. Every JS/Python/TS developer knows doc comments. Nobody knows `@i`. Having both `///` and `@i` is the first "wait, what?" moment for newcomers. The `bank.pact` duplication is exactly the kind of thing that makes developers distrust a language's design.
- **PLT:** Merge. `@i` is the only annotation carrying unstructured prose with no formal semantics. Every other annotation (`@requires`, `@ensures`, `@where`, `@effects`) is compiler-checkable. `@i` is categorically different — it's documentation masquerading as a formal annotation. Moving it to `///` is more honest. Haskell and OCaml use Haddock/odoc for this.
- **DevOps:** Merge. One source of truth for LSP hover, one thing for `pact fmt` to format, one lint to enforce. With `@i`, every tool must handle two parallel description systems. `pact query --intent` can query `///` first lines with identical results. Go's godoc and Rust's rustdoc extract summaries from doc comments — proven pattern.
- **AI/ML:** Merge. `@i("text")` costs ~4 extra tokens per function vs `/// text`. LLMs trained on every major language know doc comments; zero training data exists for `@i`. Having both creates a decision point with no value. Eliminating `@i` aligns with patterns LLMs already generate correctly.

**AI-First Review:** 5/5 pass (learnability, consistency, generability, debuggability, token efficiency).

**Resolution:** `@i` removed from annotation system. First line of `///` doc comment serves as the queryable intent declaration. `pact query --intent` queries `///` first lines. Annotation count reduced from 15 to 14. Canonical ordering updated. All `@i` references removed from §2.16, §8.4, §11.1, and examples.

---

## Open Questions

These design decisions remain unresolved:

1. **Information flow tracking** — Taint tracking via effect provenance (v2+ roadmap). `Query[C]` covers injection cases for v1
2. ~~**Row polymorphism**~~ — **Partially resolved.** Wildcard `! _` forwarding covers 95% case in v1. Named effect variables (full row polymorphism) deferred to v2. See Effect Polymorphism rationale above.
3. **Higher-kinded types** — Only if needed for effect abstractions. Deferred.
4. ~~**Codegen backend**~~ — **Resolved.** Emit C → cc. See Codegen Backend & Bootstrap rationale above.
