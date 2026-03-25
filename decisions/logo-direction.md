[< All Decisions](../DECISIONS.md)

# Logo Direction — Branding Decision

### Panel Deliberation

Four questions deliberated for the Blink logo ahead of first public release. The language was renamed from Pact to Blink, invalidating most existing logo concepts (stylized P, handshake, seal, linked rings).

#### Q1: Primary Visual Metaphor

What should the Blink logo primarily represent?

- **A) Eye/blink** (speed, instant compilation)
- **B) Horse blinkers** (focused vision, capabilities, removing distractions)
- **C) Code syntax elements** (chevrons, braces)
- **D) Abstract geometric** (modern tech brand)

**Result: Split 2-2** (DevOps absent). Resolved as hybrid C+B.

- **Systems (C):** Chevrons and braces are universally recognized by developers — zero explanation needed. An eye or horse blinkers require backstory, which is cognitive overhead antithetical to a language that promises no ambiguity.
- **Web (C):** The most successful language logos immediately signal "this is a programming language" without requiring backstory. Developers scrolling GitHub need to instantly clock "this is a programming language."
- **PLT (B):** The capability/effect system is Blink's most distinctive PLT contribution — the logo should represent principled restriction, not generic speed. *(dissent)*
- **AI/ML (B):** Every AI-adjacent tool already uses eye/sparkle imagery — that space is saturated. The capability system (AI power under directed constraint) is the actual product story. *(dissent)*

**Resolution:** Hybrid approach — code syntax shapes (chevrons) arranged to evoke the blinkers/focused-vision concept. Flanking angular shapes that read as both "code" and "directed focus." Satisfies both camps.

#### Q2: Dual Meaning Expression

Should the logo express both "blink" meanings (speed + focus)?

**Result: B (Pick one, commit) — 4-0 unanimous**

- **Systems (B):** Serving two masters means serving neither. A logo combining speed AND focus is an overloaded function — bad design in code, bad design in branding. Commit to focus since it's the unique differentiator.
- **Web (B):** Logos that try to say two things end up saying neither. The Nike swoosh means one thing. Pick one and go all in.
- **PLT (B):** Compositionality demands clarity. A logo expressing two orthogonal concepts will be incoherent — a pun rather than a symbol. Commit to capability/focus.
- **AI/ML (B):** Blink's philosophy is "one way to do everything" — the logo should embody that same commitment. Ambiguity is exactly what the language eliminates.

#### Q3: Color Palette

Keep dark blue (#1e3a5f) + burnished gold (#d4930d)?

**Result: A (Keep blue + gold) — 4-0 unanimous**

- **Systems (A):** Dark blue + gold occupies a distinct niche in the language landscape. It signals precision and reliability. Dark blue renders well on both light and dark terminal backgrounds.
- **Web (A):** Reads as premium and authoritative. Stands out against JS yellow, TS blue-white, Rust orange-black. Gold pops on dark surfaces where 90% of devs work.
- **PLT (A):** Communicates authority, formality, and rigor — exactly the identity of a language with HM inference, refinement types, and SMT-backed contracts. Not a "fun scripting language" palette.
- **AI/ML (A):** Rare in the PL logo space. Strong contrast in dark-mode IDEs and chat UIs. Gold reinforces the harness/blinker metaphor naturally. Stay burnished (#d4930d), avoid shinier #f0b429 (crypto aesthetics).

#### Q4: Multi-Context Requirements

What rendering contexts must the logo support?

**Result: C (Full design system) — 4-0 unanimous**

- **Systems (C):** Design for all deployment targets from the start. Retrofitting is technical debt in visual form. Rust's logo system (gear + wordmark + combination) is the reference implementation.
- **Web (C):** Table stakes. Every successful language ships icon + wordmark + combo from day one. Design icon first (hardest constraint), derive wordmark from same visual language.
- **PLT (C):** A principled design system is the only correct answer. The icon is the base type, the wordmark is a dependent type, the combination mark is the product type.
- **AI/ML (C):** Non-negotiable for AI-first. Logo will appear in unpredictable contexts — GitHub badges, VS Code, AI agent tool-selection UIs. Need minimum viable variants from day one.

### AI-First Review

All applicable criteria pass (Learnability, Consistency, Token Efficiency). Generability and Debuggability N/A for branding decisions. 0 failures — decision stands.

---

## Creative Brief for Image Generation

### What is Blink?

Blink is a programming language designed for the age of AI-assisted development. It's not "a language with good AI tooling" — it's a language where every design decision optimizes the human-AI-compiler collaboration loop. The compiler compiles itself (self-hosting). It compiles to native binaries via C. Sub-200ms incremental compilation.

### Name Meaning

"Blink" has two layers:

1. **Horse blinkers** (primary): AI is the horse — immensely powerful, capable of generating code at extraordinary speed. But raw power without direction is wasted. Blinkers on a harness restrict a horse's peripheral vision, eliminating distractions and keeping the animal focused on the path ahead. Blink does the same for AI. The effect/capability system is the clearest expression: a function can only "see" what it explicitly declares access to — everything else is blinkered away.

2. **Speed** (secondary): Sub-200ms compilation. The generate-compile-check-fix loop completes in the blink of an eye.

The logo should primarily evoke **focused direction / channeled power** (the blinkers metaphor), NOT speed. One metaphor, committed.

### Design Direction

**Hybrid concept:** Use code-syntax-derived shapes (chevrons `>`, angles, braces) arranged to evoke the blinkers/focused-vision concept. Two flanking elements that read as both "this is a programming language" AND "directed focus / restricted peripheral vision." The negative space between them should feel like a focused channel or path.

Think: two angular panels on either side channeling attention toward a central focal point. The visual should feel like looking through blinkers — peripheral vision blocked, forward vision sharp and clear.

### Color Palette

- **Primary:** Dark navy blue `#1e3a5f`
- **Accent:** Burnished gold `#d4930d`
- **Secondary:** Lighter blue `#2d5a8e` (for gradients)
- **Avoid:** Bright/shiny gold (#f0b429) — too crypto/flashy

Blue + gold signals authority, precision, rigor. It occupies an unclaimed niche in the programming language logo landscape (Rust=orange/black, Go=cyan, JS=yellow, TS=blue/white, Python=blue/yellow).

### Style Requirements

- **Geometric and clean** — no organic shapes, no gradients-for-the-sake-of-gradients
- **Works at 16px** — must be recognizable as a favicon/browser tab icon
- **Flat or near-flat** — no 3D effects, no drop shadows, no glossy reflections
- **Distinctive silhouette** — recognizable in monochrome/single-color
- **Not an eye** — the AI tool space is saturated with eye/sparkle imagery. Avoid.
- **Not a horse** — too literal. The blinkers metaphor should be abstract/geometric.
- **Not generic angle brackets** — every dev tool uses `< >`. Must be distinctive.

### Reference Logos (for positioning, NOT copying)

- **Rust** (gear/crab) — technical, distinctive silhouette, works at all sizes
- **Haskell** (lambda) — simple geometric symbol that teaches the language's identity
- **Kotlin** (angular K) — code-syntax-derived but unique and recognizable
- **Go** (gopher) — memorable mascot approach (we're NOT doing a mascot, but note the distinctiveness)

### Taglines (for context, not for the logo)

- "Blink and it's built."
- "Focus the machine."
- "Channel the power. Remove the noise."
- "One way. The right way."

### Deliverables Needed

1. **Icon mark** — square, works at 16x16 through 512x512
2. **Should feel like** — a programming language logo, not a startup logo, not a consulting firm logo
3. **Should NOT feel like** — an AI company logo, a fintech logo, a university crest
