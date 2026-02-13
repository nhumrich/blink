# Pact Error Catalog

Complete catalog of all compiler diagnostics. Names are the primary identification scheme; numeric codes are secondary compact identifiers.

## Identification Format

**Human-facing (terminal):**
```
error[NonExhaustiveMatch]: non-exhaustive match
```

**JSON (structured output):**
```json
{
  "name": "NonExhaustiveMatch",
  "code": "E0004",
  "severity": "error",
  "message": "non-exhaustive match",
  ...
}
```

## Conventions

- **Names** are PascalCase, stable API. Once published, a name is frozen — never renamed, never reassigned.
- **Codes** are secondary compact identifiers (E/W + 4 digits). Codes are never reused after retirement.
- **Suppression** uses names: `@allow(NonExhaustiveMatch)`.
- **`pact explain <name>`** prints a detailed explanation (future — not yet implemented).

---

## Category Ranges

| Range | Category |
|-------|----------|
| E00xx | Pattern matching / exhaustiveness |
| E01xx | Type identity / traits / derive |
| E03xx | Type checking / type mismatch |
| E05xx | Effects / capabilities |
| E06xx | Resource scope / closures |
| E07xx | Method resolution / arena / coherence |
| E08xx | FFI |
| E09xx | Module capabilities |
| E10xx | Module resolution / imports |

---

## Error Names

| Name | Code | One-line | Category | Spec ref |
|------|------|----------|----------|----------|
| NonExhaustiveMatch | E0004 | Non-exhaustive match expression | Pattern matching | §3.5 |
| RefutableLetPattern | E0005 | Refutable pattern in `let` binding | Pattern matching | §3.5 |
| SealedTraitImpl | E0120 | Impl of sealed trait by non-builtin type | Traits | §3.6 |
| TraitBoundNotSatisfied | E0121 | Required trait bound not satisfied | Traits | §3.6, §3.8 |
| NonDerivableTrait | E0160 | Cannot derive trait — field type lacks required impl | Derive | §3.6.1 |
| SelfOutsideTraitOrImpl | E0170 | `Self` used outside trait or impl block | Traits | §3.6 |
| SelfNotConstructor | E0171 | `Self` used as constructor | Traits | §3.6 |
| TupleArityExceeded | E0180 | Tuple exceeds maximum arity (6) | Types | §3.8 |
| InconsistentPatternBindings | E0311 | Inconsistent bindings in OR-pattern | Pattern matching | §3.5 |
| MissingDisplayImpl | E0312 | Type does not implement `Display` for interpolation | Type checking | §3.6.1 |
| UndeclaredEffect | E0500 | Callee requires effect not declared by caller | Effects | §4.5 |
| InsufficientCapability | E0501 | Effect operation exceeds declared capability | Effects | §4.4 |
| QuestionMarkRequiresResult | E0502 | `?` operator used on non-Result or in non-Result function | Effects | §7.2 |
| CoalesceRequiresOption | E0503 | `??` operator used on non-Option value | Effects | §7.3 |
| UndefinedFunction | E0504 | Call to undefined function | Effects | §6.4 |
| UnresolvedMethod | E0505 | Unresolved method call on variable | Effects | §3c.4 |
| CapabilityBudgetExceeded | E0510 | Function effect exceeds module `@capabilities` budget | Effects | §4.8 |
| EffectMismatchInFnType | E0511 | Effect mismatch between expected and actual function type | Effects | §4.15 |
| InvalidHandlerTypeParam | E0520 | `Handler[E]` used with non-effect type parameter | Effects | §4.7.1 |
| InsufficientHandlerCoverage | E0521 | Handler lacks required effect operations | Effects | §4.7.1 |
| UnhandledEffectInTest | E0540 | Unhandled effect in test block | Effects | §2.19 |
| CloseableEscapesScope | E0601 | `Closeable` value escapes `with...as` scope | Resources | §5.5 |
| CloseableStoredInCollection | E0602 | `Closeable` value stored in collection | Resources | §5.5 |
| MutableCaptureInSpawn | E0650 | `let mut` binding captured in `async.spawn` closure | Closures | §2.8 |
| ArenaValueEscapes | E0700 | Arena-scoped value escapes arena scope | Arena | §5.2 |
| EffectHandleShadowed | E0710 | Local variable shadows reserved effect handle name | Method resolution | §3c.4 |
| AmbiguousMethodCall | E0730 | Method found in multiple traits — ambiguous | Method resolution | §3c.4 |
| OrphanImpl | E0750 | Impl in package that defines neither trait nor type | Coherence | §3.6 |
| OverlappingImpls | E0760 | Two impls overlap for same (Trait, Type) pair | Coherence | §3.6 |
| FfiFunctionPublic | E0801 | FFI function cannot be `pub` | FFI | §9.1 |
| InvalidPtrTypeParam | E0810 | Invalid `Ptr[T]` type parameter | FFI | §9.1.1 |
| PtrOutsideFfiContext | E0811 | `Ptr[T]` used outside FFI context | FFI | §9.1.1 |
| EffectExceedsModuleCaps | E0900 | Effect exceeds module capabilities | Module caps | §10.2 |
| DuplicateModuleName | E1001 | Duplicate module name in package | Modules | §10.5 |
| CircularPackageDep | E1002 | Circular package dependency | Modules | §10.5 |
| PrivateItemAccess | E1003 | Access to private item in another module | Modules | §10.5 |
| AmbiguousImport | E1005 | Ambiguous import — name exists in multiple modules | Modules | §10.5 |

---

## Warning Names

| Name | Code | One-line | Category | Spec ref |
|------|------|----------|----------|----------|
| LossyConversion | W0350 | Int-to-Float conversion loses precision | Numeric | §3c.3 |
| RawBypassesParam | W0310 | `Raw()` bypasses query parameterization | Contracts | §3b.5 |
| CloseableWithoutScope | W0600 | `Closeable` value used outside `with...as` block | Resources | §5.5 |
| UnauditedFfi | W0800 | Unaudited foreign function call | FFI | §9.1 |
| UnscopedPointerAlloc | W0810 | Pointer allocation outside `ffi.scope()` | FFI | §9.1.1 |
| LocalShadowsDep | W1000 | Local module shadows a dependency | Modules | §10.5 |
| NameShadowsPrelude | W1010 | Name shadows a prelude type | Modules | §10.6 |

---

## Compiler-Implemented Codes

The self-hosting compiler (`src/codegen_types.pact`, `src/codegen_expr.pact`) currently implements these error codes:

| Code | Name | Implementation |
|------|------|---------------|
| E0500 | UndeclaredEffect | `codegen_types.pact` — effect propagation check |
| E0501 | InsufficientCapability | `codegen_types.pact` — `@capabilities` budget check |
| E0502 | QuestionMarkRequiresResult | `codegen_expr.pact` — `?` operator type check |
| E0503 | CoalesceRequiresOption | `codegen_expr.pact` — `??` operator type check |
| E0504 | UndefinedFunction | `codegen_expr.pact` — function call resolution |
| E0505 | UnresolvedMethod | `codegen_expr.pact` — method call resolution |
