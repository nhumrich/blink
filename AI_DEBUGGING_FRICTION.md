# AI Debugging Friction Report

**Date:** 2026-02-15
**Context:** Fixing pact-398 (formatter comment duplication)
**Filed by:** AI (Claude) after painful debugging session

## The Problem

Debugging the comment duplication bug required understanding parser state (specifically, when comments were being collected into `pending_comments` and at what token positions). The only tool available was print-style debugging — adding `io.println` calls, recompiling the entire compiler, running the test, reading output, then repeating.

## What Happened

1. Narrowed the bug to "two let-bindings before a while-loop cause comment duplication"
2. Needed to understand WHY — which function was collecting the comment twice
3. Added `io.println` debug lines to `skip_newlines()`, `attach_comments()`, `parse_block()`, `parse_let_binding()`, `parse_while_loop()`
4. `io.eprintln` doesn't exist — had to discover that only `io.println` and `io.log` are available
5. Each debug iteration required: edit parser → compile compiler → compile output → run — ~10 seconds per cycle
6. Took 5+ iterations of adding/refining debug output before finding the root cause
7. Had to manually remove all debug instrumentation afterward

Total: ~15 tool calls and significant token burn just to trace function execution flow.

## What a Human Would Do

- Set a conditional breakpoint in a debugger: `break skip_newlines if strcmp(peek_value(), " trailing comma case") == 0`
- Inspect the call stack at the breakpoint to see exactly who called `skip_newlines`
- Done in one step. The call stack would immediately show `looks_like_struct_lit → skip_newlines`, revealing the bug.

## What Would Have Helped (AI-Specific)

### 1. Built-in Trace/Debug Mode for the Compiler
A `--trace` flag that logs parser function entry/exit and key state changes:
```
pactc file.pact out.c --trace parse
```
Output:
```
parse_block ENTER pos=22
  parse_stmt ENTER pos=24
    parse_primary ENTER pos=24
      looks_like_struct_lit ENTER pos=24
        skip_newlines: collected comment " trailing comma case" pos=26
      looks_like_struct_lit EXIT pos=24 (backtrack)
    parse_primary EXIT pos=25
```

This would have revealed the bug in ONE run.

### 2. AST Debug Dump
A `--dump-ast` flag showing the parsed AST with comment attachments:
```
pactc file.pact --dump-ast
```
Would immediately show which nodes have comments attached and whether any comment appears twice.

### 3. `io.eprintln` / stderr output
Not having stderr output meant debug prints interleaved with formatter output. Minor but annoying.

### 4. Conditional Compilation / Debug Blocks
Something like:
```pact
@debug
fn trace_skip_newlines() {
    io.log("skip_newlines at pos={pos}")
}
```
That compiles to nothing in release mode but activates with `--debug`.

### 5. Assert With Context
```pact
debug_assert(pending_comments.len() == 0, "comments leaked: {pending_comments}")
```

## The Deeper Issue: Pact's Effect System Would Have Prevented This

The root cause was a PATTERN: `skip_newlines()` has side effects (comment collection) that poison speculative lookahead. This same bug appeared THREE times:

1. `parse_postfix()` dot-continuation lookahead
2. `parse_if_expr()` else-lookahead
3. `looks_like_struct_lit()` struct literal lookahead

Each time, the fix was the same: replace `skip_newlines()` with side-effect-free peek through `tok_kinds` array.

### The irony

Pact's **entire design philosophy** is that side effects should be explicit and visible in function signatures. That's what the effect system (`! IO, DB`) is for. Yet the compiler — Pact's flagship program — has a function called `skip_newlines()` that:

- **Looks pure.** The name says "skip newlines." It takes no arguments. It returns nothing.
- **Is not pure.** It mutates global state (`pending_comments`, `pending_doc_comment`) as a hidden side effect.

If the compiler were written with effect annotations enforced, `skip_newlines()` would need to declare something like `! MutateParserState` or `! CommentCollection`. Any caller would see that annotation. And critically, `looks_like_struct_lit()` — which is supposed to be a **pure lookahead** — would fail to compile if it called a function with effects, unless it also declared those effects. The type system would have caught this bug at compile time.

**The AI didn't need a debugger. It needed the language to enforce its own rules.**

I spent ~15 tool calls and burned through significant context doing print-style debugging to reconstruct information that the effect system is DESIGNED to make obvious. The function signature should have told me `skip_newlines()` mutates state. It didn't. So I had to discover it empirically.

### This validates the effect system design

This is actually a strong argument FOR Pact's effect system. The compiler is living proof of what happens when effects are implicit:
- Hidden side effects in "utility" functions
- Same class of bug recurring 3 times because nothing flags the danger
- Debugging requires tracing runtime behavior instead of reading signatures

The effect system exists to make this impossible. The compiler just isn't using it on itself yet.

### Questions for the panel

1. **Should the compiler dogfood the effect system?** If Pact's own compiler can't use effects (because the effect system isn't bootstrapped yet), that's understandable. But it should be a goal. The compiler is the best test case for whether effects actually prevent real bugs.

2. **Is "mutates module-level state" an effect?** The current effect system focuses on IO, DB, etc. But `skip_newlines()` mutates module-level mutable variables. Should there be a `! Mut` or `! State` effect for functions that touch mutable globals? Or is this just a code smell that should be refactored away (no globals, pass state explicitly)?

3. **What about speculative/lookahead patterns?** Many parsers need "try this, backtrack if it fails." Pact's effect system could help here — a pure function can't accidentally collect comments. But does the language make it easy enough to write side-effect-free lookahead? Or does the effect system need escape hatches for this pattern?

## Recommendations for Panel

### Language / Tooling (helps all Pact users)

1. **`io.eprintln`** — Pact has `io.println` (stdout) and `io.log` (stderr with `[LOG]` prefix) but no plain stderr print. Debug output interleaves with program output. Every language needs this.

2. **`--trace` compiler flag** — A built-in `--trace parse` (or `--trace typecheck`, etc.) that logs function entry/exit and key state. The compiler is the first large Pact program; if debugging it is painful, debugging user code will be too.

3. **`--dump-ast`** — Show the parsed AST with comment attachments, types, node IDs. Useful for anyone writing macros, linters, formatters, or debugging parser issues.

4. **`@debug` conditional blocks** — Code that compiles away in release mode but activates with a flag. Every `println`-debugging session involves adding and then manually removing instrumentation. This is especially painful for AI, which can't just "undo" — it has to find and remove each line.

5. **`debug_assert` with context** — `debug_assert(cond, "msg with {interpolation}")` that compiles to nothing in release. Lets you leave invariant checks in the code permanently without runtime cost.

### Compiler-Internal (our codebase, not the language)

6. **Split `skip_newlines()`** into `skip_whitespace()` (no side effects) and `collect_comments()` (explicit). The implicit comment-collection side effect caused the same class of bug three times.

7. **Decouple comment attachment from parsing** — A separate pass over the token stream to attach comments to AST nodes might be simpler than the current interleaved `pending_comments` approach.

8. **Dogfood the effect system** — Once the compiler can self-host with effect checking, annotate parser functions with their actual effects. Let the type system catch the next `looks_like_struct_lit` before it ships.
