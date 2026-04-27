# Package Entry-Point Convention

**Ticket:** ewhnfp
**Spec section:** 07_trust_modules_metadata.md §10.5 — Package Entry Resolution

## Questions

1. What file does `import <pkg>` resolve to for a bare package import?
2. Should `src/lib.bl` remain a valid convention, and if so, is it primary or fallback?
3. How do non-`src/` source files (`tests/`, `examples/`, `bench/`) participate in the package build — specifically, how does their import resolution find the project root?

## Context

The current compiler (`src/compiler.bl:407-416`) hardcodes `src/lib.bl` as the bare-package entry point with no fallback. This was an undocumented Cargo-ism. The two real packages in the workspace already disagree:

- `libs/redis/src/lib.bl` (`@module("redis")`) — works against the hardcode.
- `libs/pg/src/pg.bl` (`@module("pg")`) — fails against the hardcode for external consumers, works incidentally inside the package via path-walk happenstance.

Spec §10.5 documents sub-path resolution (`import auth.token` → `src/auth/token.bl`) but is silent on bare external `import auth`. Downstream ticket `zg6yd9` (test files in `tests/` cannot import their own package) cannot be fixed until the entry-point convention is decided.

## Phase A — Independent proposals (verbatim, by domain)

The five panelists were prompted independently with the same brief — three questions, factual context, no option-listing. Each produced one or more concrete proposals.

### Sys

> **Proposal 1 (recommended): `src/<pkg>.bl` is THE entry point. No fallback. No `lib.bl`.**
>
> "`import <pkg>` resolves to exactly one path: `<pkg-root>/src/<pkg>.bl`. The package name comes from `blink.toml` `[package].name`. One filename, derived deterministically from one source of truth. No ambiguity, no probing."
>
> Rationale: "Two filesystem `stat`s on a hot path. Deterministic. The error mode is *one* error: file missing at exactly one known path. With a fallback, you get the cursed error mode where neither candidate exists and the compiler has to decide which one to name in the diagnostic — and users have to learn that when `src/lib.bl` exists but is broken, the compiler is *also* checking `src/<pkg>.bl`. The current `src/lib.bl` hardcode is exactly the kind of leaked-Cargo-ism the spec already warns about."
>
> Sys also offered Proposal 2 (`<pkg>.bl` primary, `lib.bl` as fallback when `<pkg>.bl` absent, "both present = error") and characterized it as "strictly worse than Proposal 1 for users learning the language."

### Web

> **Proposal 1 (recommended): `src/<pkg>.bl` is the canonical entry, `src/lib.bl` is a deprecated alias.**
>
> "When I'm hacking on a small library, I want to open `src/pg.bl` and immediately know 'yes, this is the file I publish.' `lib.bl` is a meta-name — it tells you the *role* of the file, not its identity, which is exactly the kind of friction that makes new users stare at file trees wondering which one to click. Aligning the entry filename with the package name also makes grep-by-name work for free in monorepos and editor 'go to file' pickers — typing `pg.bl` lands you on the right file instead of one of fifty `lib.bl`s."
>
> Web Proposal 2: explicit `entry = "src/pg.bl"` field in `blink.toml`. Floated as the safer long-horizon option if multi-entry packages were imminent. Verdict: "Proposal 1 today, with `entry` reserved as a future override field."

### PLT

> **Proposal 1 (recommended at Phase A): `src/lib.bl` is THE entry, path is identity, `@module` becomes redundant on the entry file.**
>
> "Path = identity. The filesystem is the namespace tree. `lib.bl` is the literal name of the root node, the way `index.html` is the root of a web directory... It's the rule that's already true in the compiler. Codifying existing behavior is the lowest-disruption path."
>
> Proposal 2: "the entry file is the file declaring `@module(<package_name>)` at the package root. Filename is unconstrained." Cons: "resolution requires opening files to read metadata, not just stat-ing the filesystem. Slower; harder to reason about without the compiler in your head."
>
> Proposal 3: filename = package name, structural law (Java's `Foo.java` precedent). PLT's own self-critique: "package names with hyphens/dots (`http-client`, `std.json`) require a filename mapping rule. This is the proposal's biggest PLT weakness — it works cleanly only for simple names."
>
> Hard NO from PLT on hybrid: "any hybrid like 'try `src/lib.bl`, fall back to `src/<pkg>.bl`.'"

### DevOps

> **Proposal 1 (recommended): `src/<pkg>.bl` canonical, `src/lib.bl` deprecated fallback.**
>
> "If `src/<pkg>.bl` is missing AND `src/lib.bl` exists, compile but emit `W1010: src/lib.bl is deprecated`. Removed in v0.next+1."
>
> Rationale: "Two failure modes — 'package has no entry' and 'you typed the wrong name' — get distinct, actionable messages. Tooling story is clean: `blink test`, LSP, and `blink check` all do the same walk-up; once they have `blink.toml`, they know the package name and the entry file deterministically. New contributor mental model is one rule: 'the entry file is named after the package.'"
>
> Proposal 3 (second-favored): explicit `entry =` in `blink.toml`. Caution: "Node's `package.json` `\"main\"` is the cautionary tale — `\"main\"` plus `\"module\"` plus `\"exports\"` plus `\"types\"` snowballed into a configuration nightmare. The discipline we'd need is *one* `entry` field, never expanded."
>
> Proposal 2 (rejected): codify `src/lib.bl`. "Spec change > compiler change is generally the wrong direction — specs should drive the compiler, not the other way around."
>
> DevOps also said: "For all three, the `find_src_root` walk-up-to-`blink.toml` behavior at compiler.bl:167-189 should be **promoted to spec**."

### AI/ML

> **Proposal 1 (recommended): single rule — `import <pkg>` always resolves to `src/<pkg>.bl`.**
>
> "When an LLM sees `import pg` in any file, it can write down the resolved path *before* reading anything else: `<somewhere>/pg/src/pg.bl`. No manifest read, no probing two filenames, no 'did the author pick lib.bl or pg.bl' coin flip. This is the single biggest AI-readability win the spec can buy."
>
> "Filename = module name = directory name = `@module` arg is a four-way invariant. Redundancy is a feature for LLMs: any one of the four lets the model recover the other three."
>
> Proposal 2 (try-both, listed to reject): "Model writing a new package has to *choose*. With no signal, it'll pick whichever the training data over-represents, leading to inconsistent libraries. Model reading `import pg` in a strange repo can't predict the file path — it has to probe both, or read the dir listing first."

## Phase A.5 — Mechanical dedupe

After all five proposals were in, the moderator grouped them by shape — no editorial synthesis.

**Q3 (project root):** All five panelists independently proposed walking up to the nearest `blink.toml` and treating `tests/`/`examples/`/`bench/` as peers of `src/`. **Settled before debate.** Promote the `find_src_root` walk-up at compiler.bl:167-189 to a spec-level rule.

**Q1+Q2:** Four distinct shapes proposed.

- **Option A: `src/<pkg>.bl` only** — filename equals package name. (Sys P1, Web P1, AI/ML P1, DevOps P1, PLT P3.)
  - Sub-question: hard-no on `lib.bl` (Sys, AI/ML, PLT P3) vs deprecation-window emitting `W1010` (Web, DevOps).
- **Option B: `src/lib.bl` only** — codify current compiler hardcode. (PLT P1, DevOps P2.)
- **Option C: explicit `entry =` in `blink.toml`** — no filename convention. (Web P2, DevOps P3.)
- **Option D: `@module("<pkg>")` declaration locates the entry; filename free.** (PLT P2.)

Four distinct shapes ⇒ Phase B triggered.

## Phase B — Open debate

One round, all five panelists. Verbatim relay between rounds. No editorial summary in panel-facing messages. Termination signal `STABLE, READY TO VOTE` from each.

### Position shifts during debate

**Web — shifted from deprecation-window to hard-no.** Quote:

> "In Phase A I proposed a deprecation window for `lib.bl`. **I'm dropping that.** Sys and AI/ML convinced me. Specifically, Sys's framing: *'the cursed error mode where neither candidate exists and the compiler has to decide which one to name in the diagnostic.'* That's exactly the kind of subtle two-path error surface that costs new users an afternoon. The libs/redis rename is one PR, not a migration epoch."
>
> Web on PLT's `index.html` analogy: "PLT is invoking a fossil as a north star. The web kept `index.html` because Apache shipped with it as a directory-listing fallback in 1995... Modern frameworks (Next, Remix, SvelteKit, Astro) name entry files after their *route or role*, not `index.*`. Nobody starting fresh picks `index` or `lib` as the convention."

**Sys — softened from immediate-delete to deprecation-window-acceptable.** Quote:

> "Phase-A-me said no fallback at all. After re-reading: I'll concede the deprecation window. The reason isn't migration ergonomics (I don't care about that), it's that **a warned-and-dated fallback is auditable in a way an immediate hard-break isn't**. The diagnostic carries the rule, the deadline, and the rename target — that's better self-documentation than a missing-file error from a fresh checkout. **But the window must be one release, not 'until someone files a bug.'**"
>
> On PLT's hyphen/dot critique: "**Forbid hyphens and dots in package names entirely**, the same way Go forbids them in import paths' final segment. `http-client` becomes `http_client` or `httpclient`. The rule stays mechanical: package name characters are `[a-z][a-z0-9_]*`, filename is exactly that string plus `.bl`, no transformation table needed."

**DevOps — shifted from deprecation-window to hard-no.** Quote:

> "Sys's framing landed: *'the cursed error mode where neither candidate exists and the compiler has to decide which one to name in the diagnostic.'* My Phase A diagnostic listed both candidates as a feature ('looked for X, also looked Y') but Sys is right that this trains users to internalize *two* mental models for 'where does the entry live.' Pre-1.0, that's permanent damage."
>
> "AI/ML's argument changed my mind harder: *'Model writing a new package has to choose. With no signal, it'll pick whichever the training data over-represents.'* CLAUDE.md says this codebase IS training data. With the two existing libs split 50/50 between `lib.bl` and `<pkg>.bl`, a deprecation window perpetuates that split in training data for an entire release cycle. The 'we build it correct' mandate argues against the soft path."

**PLT — shifted from Option B (`lib.bl` only) to Option A.** Quote:

> "I shift from Proposal 1 (Option B) to Option A — `src/<pkg>.bl` only.
>
> Three things moved me:
> 1. The moderator's empirical correction is decisive. The libs at `/home/nhumrich/blinklang/libs/redis` and `/home/nhumrich/blinklang/libs/pg` *already disagree*. Codifying `lib.bl` doesn't ratify reality; it picks a side in an existing schism. That dissolves the strongest argument I had.
> 2. AI/ML's 'four-way invariant' reframes redundancy correctly. For *recoverability under partial information*, redundancy is a feature, not a bug. Quoting AI/ML: 'any one of the four lets the model recover the other three.' AI/ML wins this exchange.
> 3. Sys's hot-path-determinism point survives my Option B defense. Both options are equally mechanical — two stats. The only thing Option B saves is a `blink.toml` read to learn the package name, but the compiler already does that walk-up for the project root anyway. There's no operational advantage to `lib.bl`, and there's a real disadvantage (cursed error mode when both/neither file exists in a fallback world)."
>
> On Option D: "Withdrawing it myself. Resolution under Option D is *content-dependent* — to resolve `import pg`, the compiler must open every file in `pg/src/` to read metadata. Hostile to AI/ML's central case. PLT-Phase-A-me was wrong to propose it as a serious alternative."
>
> On the 50-file tab strip point: "Honest answer: **I don't have a defense, and I shouldn't construct one for the sake of debate.** That argument is correct and is one of the things that moved my vote. 'Path = identity' does not require the path to *end in `lib.bl`*; it only requires the path to be authoritative."

**AI/ML — position unchanged on substance, slight softening.** Quote:

> "Position unchanged on substance from Phase A. Slight softening on hard-no vs deprecation: I'll accept Web/DevOps's W-diag-then-remove path *if* the removal version is hard-pinned in the spec text itself. Otherwise hard-no with Sys."
>
> On PLT's hyphen/dot critique: "It does NOT change my vote, but it forces the spec to be explicit about one rule. Underscore-only, no hyphens, no dots — the four-way invariant becomes character-for-character identical with no transformation. That's the strongest possible signal for a stateless model."
>
> On Option D: "**Hurts. Significantly. This is the worst option for AI/ML and I want it on the record.** Under Option D, the resolved file could be named anything. The model — and the resolver — must open and parse every candidate file in `src/` looking for the `@module("pg")` declaration. The four-way invariant collapses to a two-way (`@module` = import name, filename free). Each broken redundancy is a place the LLM can be wrong. Worst: it permits exactly the Python `__init__.py` failure mode."

### Convergence

By end of Round 1, all five panelists signaled `STABLE, READY TO VOTE`. Convergence:

- All five on Option A (filename = package name).
- Web, AI/ML, PLT, DevOps on hard-no on `lib.bl`. Sys on deprecation-window-acceptable.
- Unanimous reject of Option C (Web and DevOps both withdrew their P2/P3 alternatives) and Option D (PLT withdrew their own P2).
- Auxiliary spec rule converged: package name grammar `[a-z][a-z0-9_]*`, hyphens forbidden, dots reserved for sub-paths.

## Phase C — Silent vote

Each panelist voted in isolation, no team channel.

| Panelist | Q1+Q2 | Sub-Q | Reasoning |
|---|---|---|---|
| Sys | A | **A2 (deprecation window)** | "Name-derived `src/<pkg>.bl` keeps resolution at O(stat) on a deterministic path... A2 over A1 because a one-release `W1010` window costs one extra `stat` on the deprecated path only when the canonical path misses, which is negligible, and it gives the bootstrap protocol a clean 3-step migration instead of a flag-day rename that risks desyncing Gen1/Gen2 during the transition." |
| Web | A | **A1 (hard-no)** | "Inner dev loop is dominated by `import <pkg>` working the way a newcomer guesses on first try — and `src/<pkg>.bl` matches that guess far better than the magic `lib.bl` filename that Node/Python folks have to unlearn. A deprecation window sounds friendly, but two valid layouts during W1010 means every tutorial, template, and Stack Overflow answer forks." |
| PLT | A | **A1 (hard-no)** | "Filename-as-identity gives a one-shot, content-free resolution rule: stat `src/<pkg>.bl`, done. The four-way invariant (toml name = directory = filename = `@module`) is a redundancy-as-checked-equality discipline, which is exactly how PLT prefers to encode identity — multiple witnesses to one fact, mechanically verified. Keeping `lib.bl` as a second valid spelling means the resolver must encode 'try X, else Y,' which is the ad-hoc case the panel is supposed to eliminate." |
| DevOps | A | **A1 (hard-no)** | "From a build-system reliability standpoint, `filename == [package].name` collapses three lookups (toml parse, filesystem probe, fallback probe) into one deterministic path resolution... A deprecation window means tooling has to carry a dual-probe codepath plus a `W1010` emitter for a full release, and every downstream tool inherits the ambiguity. The bootstrap protocol's 2-step rename is exactly the kind of mechanical migration our tooling is designed for." |
| AI/ML | A | **A1 (hard-no)** | "From an AI/ML retrieval standpoint, `src/<pkg>.bl` makes entry resolution a pure function of `blink.toml`'s `name` field — a code-gen model can write the resolved path before opening a single file. Allowing `lib.bl` even transiently bifurcates training data and forces models to emit probe-then-read patterns (or hallucinate the wrong filename half the time, weighted by corpus frequency)." |

### Concerns recorded by voters

- **Sys (A2 vote):** "A2's deprecation window means for one release the resolver has two legal entry paths, and if a package ships both `src/<pkg>.bl` and `src/lib.bl` the precedence rule must be specified and tested or we'll ship a latent ambiguity bug into training data."
- **Web (A1):** "Tooling (formatter, doc, LSP, scaffolder `blink new`) must ship the `src/<pkg>.bl` convention simultaneously with the hard-no, or new users will hit the cursed error before they ever see a working template."
- **PLT (A1):** "A1 only holds if the 3-step rename of `libs/redis` actually lands cleanly through self-host regen — if it stalls, the 'hard-no' degrades into de facto A2 anyway, so the bootstrap PR must be gated on `task ci` green before the spec is declared ratified."
- **DevOps (A1):** "Withdrawing the reserved `entry =` key leaves no forward-compat hook if Option C ever wins on a future ballot, so toml parsers will need a breaking schema bump rather than flipping a reserved-field flag."
- **AI/ML (A1):** "If A2 wins instead of A1, the pinned-sunset clause must appear in the normative spec body, not a footnote, or the deprecation will silently become permanent in model priors."

## Tally

- **Q1+Q2: Option A** — 5/5 (unanimous).
- **Sub-Q: A1 (hard-no on `lib.bl`)** — 4/5; Sys voted A2.
- **Q3: walk-up to `blink.toml`** — 5/5 settled in Phase A.5, no separate vote.

### Soft-consensus collapse on the 4-1

Per the new `/deliberate` workflow's soft-consensus skip rule: a 4-1 result whose dissenter's reasoning is endorsed by the majority's concerns is treated as 5-0 with a follow-up note.

Sys voted A2 specifically to give the `libs/redis` rename a clean 3-step bootstrap rather than a flag-day. The majority's recorded concerns endorse the same migration discipline:

- PLT: "the bootstrap PR must be gated on `task ci` green before the spec is declared ratified."
- AI/ML: "if A2 wins, the pinned-sunset clause must appear in the normative spec body."
- Web: "tooling must ship simultaneously."
- DevOps: 2-step rename "is exactly the kind of mechanical migration our tooling is designed for."

The substantive disagreement — whether `lib.bl` should *ever* be a valid entry — is unanimous: nobody wants `lib.bl` long-term. Sys's dissent is purely about how to land the migration safely. Treated as 5-0 on substance with a binding follow-up: **the bootstrap migration PR is a ship-gate on the spec, gated on `task ci` passing Gen1+Gen2 fixed-point.**

## Decisions

1. **Q1 — Entry file:** `import <pkg>` resolves to `<pkg-root>/src/<pkg>.bl` where `<pkg>` is `[package].name` from the package's `blink.toml`. **Unanimous.**
2. **Q2 — `lib.bl` policy:** Not a recognized convention. Hard-no, no fallback, no deprecation window. Compiler probe at `src/compiler.bl:407-416` deleted, not generalized. **5-0 by soft consensus.**
3. **Q3 — Project root:** Nearest ancestor directory containing `blink.toml`, walked up from the source file. `tests/`/`examples/`/`bench/` are peers of `src/`. Files with no `blink.toml` ancestor produce `error[E1006]` on bare external imports. **Unanimous in Phase A.5.**

### Auxiliary rules ratified by the panel

- **Package name grammar:** `[a-z][a-z0-9_]*`. Hyphens forbidden. Dots reserved for sub-path / registry org-name separation per §8.9.2.
- **`@module` on entry file:** redundant-and-checked. May be omitted; if present, must equal `[package].name`. Mismatch is `error[E1002]`.
- **`@module` on non-entry files:** unchanged from §10.5; remains authoritative for namespace placement.

### Out of scope (explicitly rejected)

- **Option B** (`src/lib.bl` only): all five panelists rejected, including PLT who proposed it in Phase A and withdrew during debate.
- **Option C** (`entry =` field in `blink.toml`): rejected. Both proposers (Web P2, DevOps P3) withdrew. Node `package.json#main` cautionary tale; YAGNI for v1; no reserved field.
- **Option D** (`@module(...)` locates entry, filename free): rejected. PLT withdrew their own P2 during debate; AI/ML on record as "the worst option for AI/ML."

### Migration ship-gate

The spec section is conditional on the migration PR landing cleanly:

1. Add `src/<pkg>.bl` resolution alongside the existing `src/lib.bl` probe → `task regen` → `task ci`.
2. Rename `libs/redis/src/lib.bl` → `libs/redis/src/redis.bl`. `libs/pg/src/pg.bl` requires no change. → `task regen` → `task ci`.
3. Delete the `src/lib.bl` probe at `src/compiler.bl:407-416`. → `task regen` → `task ci`.

Spec is not declared ratified until step 3 passes Gen1+Gen2 fixed-point and the existing test suite is green. Per the bootstrap protocol, each step is its own commit.

## Downstream

- **`zg6yd9`** (test files in `tests/` cannot import their own package): unblocked by Q3 (walk-up to `blink.toml`) plus Q1 (uniform self-import as `<root>/src/<pkg>.bl`). Remove the `pg = { path = "." }` self-dependency workaround in `libs/pg/blink.toml` once the migration ship-gate lands.

## AI-First review pass

Reviewed the spec text against retrieval-led, single-file readability:

- The four-way invariant (`name` = dir = filename = `@module` arg) is character-for-character identical for any conforming package; no transformation rule for an LLM to learn.
- The error message names exactly one expected path — no two-candidate ambiguity for a model to disambiguate.
- The package name grammar is colocated with the entry-point rule in the same subsection so an LLM ingesting the spec sees them as one fact.
- No new `blink.toml` fields, no new annotations, no new keywords. The rule reads as a tightening of §10.5, not an extension.

Approved as drafted.
