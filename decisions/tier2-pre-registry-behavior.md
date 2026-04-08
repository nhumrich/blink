[< All Decisions](../DECISIONS.md)

# Tier-2 Pre-Registry Behavior — Design Rationale

### Panel Deliberation

Five panelists (systems, web/scripting, PLT, DevOps/tooling, AI/ML) voted independently on whether tier-2 stdlib packages should require explicit `blink.toml` declaration before a package registry exists. The core question: when all tier-2 packages are bundled with the compiler and there is no registry to version them independently, should the manifest requirement be enforced?

**Background:** The prior web-service tier classification (5-0 for std.db as Tier 2, 3-2 for std.http as Tier 2) assumed independent versioning via a registry. In practice, all tier-2 packages ship in `lib/std/` and are embedded in the compiler binary. The version string `"0.1"` in `blink.toml` is a placeholder — it doesn't select a version, trigger resolution, or fetch anything. The resolver silently skips "registry" source dependencies and writes empty lockfiles. This caused real bugs: `blink doc std.db` failed on installed binaries because tier-2 modules weren't embedded.

**Q1: Should tier-2 require blink.toml declaration pre-registry? (4-1 for B: collapse into tier-1)**

- **Systems (B):** The current tier-2 machinery is dead code with real costs. The resolver silently skips "registry" sources and writes empty lockfiles — a lie baked into the build system. Users pay cognitive overhead for an abstraction backed by nothing. Zig philosophy: don't add the abstraction until the mechanism exists. *(vote B)*
- **Web/Scripting (B):** A new user writes `import std.http`, hits a wall, has to learn about tiers and `blink add` — all to use something already on their machine. The "import json works but import requests doesn't" confusion from Python is exactly what this creates. Zero-friction onboarding matters more than future-proofing. *(vote B)*
- **PLT (B):** The `blink.toml` entry is a phantom distinction — it has the syntactic form of a binding-time classification but carries zero semantic content. The version string doesn't participate in resolution, the lockfile ignores it. A gate that can only affirm communicates zero bits of information. When the registry ships and the version string actually selects something, re-introduce the gate — because it then carries real information. *(vote B)*
- **DevOps (C):** *(dissent)* Explicit dependency declarations matter for auditability and CI reproducibility. Knowing what your project uses — even bundled modules — has tooling value: dependency scanners, license checkers, upgrade bots. The manifest gate should stay, but the broken resolver/lockfile mechanism should be replaced with a simple compiler manifest check. `blink add std/db` just edits blink.toml, no resolver involved.
- **AI/ML (B):** Uniform access semantics is the single most important stdlib property for LLM code generation. Two rules for `std.*` imports (some need blink.toml, some don't) creates a classification problem with no learnable signal. The tier distinction is purely administrative metadata — an LLM cannot derive which modules need manifest entries from first principles. Until a registry gives version strings actual meaning, this is token overhead for zero value. *(vote B)*

### Resolution

**Result: Option B wins 4-1.** All `std.*` modules are treated as tier-1 (implicit, no `blink.toml` entry required) until a package registry exists to back independent versioning. The tier-2 classification is preserved in the spec as the intended future behavior — it is not removed, merely deferred.

**Migration plan for registry day:** When a registry ships, the compiler will emit warnings for one release cycle ("std.db will require blink.toml declaration in vX.Y"), then enforce. A `blink migrate` command will auto-generate entries. This is a one-time cost versus ongoing friction for every user today.

**What changes:**
- Compiler no longer emits E1052 (PackageNotDeclared) for bundled tier-2 modules
- `blink add std/db` still works (adds to blink.toml for forward-compatibility) but is not required
- All tier-2 modules are embedded in the binary alongside tier-1 modules
- The resolver's "registry" source type remains as dead code for future use

**What doesn't change:**
- The tier-2 classification in the spec (§10.7.1) — the rationale for independent versioning is still sound
- `import std.db` syntax
- Effect system types remain compiler-known regardless of tier
