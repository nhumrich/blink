## 3. Type System

### 3.1 Overview

Pact's type system exists to serve a single goal: **make incorrect programs unrepresentable**. Not aspirationally, not eventually -- at compile time, before a single byte of machine code is emitted.

The foundation is Hindley-Milner type inference extended with algebraic data types, traits, and targeted verification features. This is not a novel combination. ML, Haskell, Rust, and OCaml have proven these ideas over decades. What Pact adds is a pragmatic verification layer -- refinement types and contracts backed by an SMT solver -- that captures the 90% of dependent-type value that matters in practice, without the 90% of dependent-type complexity that makes languages unusable.

**Design philosophy:**

1. **Types are documentation the compiler enforces.** A function signature in Pact tells you its inputs, outputs, effects, failure modes, and value constraints. An AI agent (or a human) can understand a function's contract from its signature alone, without reading the body. This is locality of reasoning applied to types.

2. **Prove, don't test.** Testing checks examples. Types check universals. A test says "this worked for these 5 inputs." A type says "this works for all inputs, forever." The type system is the primary correctness mechanism; tests are the fallback for properties that can't be expressed as types.

3. **Progressive verification.** Not every function needs SMT-backed contracts. Simple functions get simple types. Critical functions get refinement types and contracts. The type system scales from "just annotate the signature" to "formally verify this precondition" without forcing the heavy machinery on code that doesn't need it.

4. **Inference is a token budget.** Every type annotation an AI writes costs tokens. Every annotation a human writes costs keystrokes. The inference engine should eliminate redundant annotations everywhere it can -- but never at function boundaries, where types serve as API documentation.

---

### 3.2 Built-in Types

```pact
// Numeric
Int             // 64-bit signed integer. The default. Use this.
I8, I16, I32    // Sized signed integers (when you actually need them)
U8, U16, U32, U64  // Unsigned integers
Float           // 64-bit IEEE 754 floating point

// Text
Str             // UTF-8 string, GC-managed
Char            // Unicode scalar value

// Logic
Bool            // true, false

// Unit
()              // The unit type. One value. No information.

// Collections
List[T]         // Growable ordered sequence
[T]             // Shorthand -- [Str] is List[Str]
Map[K, V]       // Hash map
Set[T]          // Hash set

// Core ADTs (defined in stdlib, special compiler support)
Option[T]       // Some(value) | None
Result[T, E]    // Ok(value) | Err(error)
```

**Why short names.** `Str` not `String`. `Int` not `Integer`. `Bool` not `Boolean`. These are the most-written types in any codebase. Over thousands of occurrences, 3 characters vs 6 saves real token budget. All types are PascalCase -- no special casing rules, no distinction between "primitive" and "user-defined." `Str` and `UserProfile` follow the same convention.

**Why one default `Int`.** Rust's numeric type matrix (`i8`/`i16`/`i32`/`i64`/`u8`/.../`usize`/`isize`) is a decision tree that produces wrong answers. LLMs pick `i32` when they mean `i64`, `usize` when they mean `u64`, and `u32` for values that go negative. Pact has `Int`. It's 64-bit. It's signed. It handles every integer you'll encounter in application code. The sized variants (`I8`, `U16`, etc.) exist for interop, binary protocols, and performance-critical paths where you've measured and know you need them.

**Why `Float` not `F32`/`F64`.** Same reasoning. 64-bit is correct for virtually all floating-point work. If you need 32-bit floats (GPU interop, large arrays where memory matters), that's a future extension, not a v1 concern.

**Why `[T]` sugar for `List[T]`.** Lists are the most common generic type. `[Str]` is 5 characters. `List[Str]` is 9. The sugar is unambiguous (square brackets in type position always mean List) and saves tokens in signatures that use lists heavily. Both forms are valid; the canonical formatter normalizes to whichever the project chooses.

**Why `Option` and `Result` are built-in.** These aren't library types bolted on after the fact. The compiler understands them: `T?` desugars to `Option[T]`, the `?` operator desugars to a match on `Result`, `??` desugars to a match on `Option`. Special syntax demands special compiler support.

---

### 3.3 Type Inference

Pact uses Hindley-Milner type inference with the following rule: **annotations are required on function signatures, inferred everywhere else.**

```pact
// Function signatures: fully annotated
fn add(a: Int, b: Int) -> Int {
    a + b
}

fn find_user(id: Int) -> Option[User] ! DB {
    db.query_one("SELECT * FROM users WHERE id = {id}")
}

// Everything inside a function body: inferred
let x = 42                        // Int
let name = "Alice"                // Str
let names = ["Alice", "Bob"]      // List[Str]
let result = add(1, 2)            // Int
let maybe = names.get(0)          // Option[Str]
let doubled = names.map(fn(n) {   // List[Str]
    "{n}{n}"
})
```

**Why require annotations at function boundaries.** A function signature is a contract. It tells callers what to provide and what to expect. If the signature is inferred from the body, understanding the contract requires reading the implementation -- the exact opposite of locality of reasoning. An AI agent browsing an API surface gets complete type information from signatures alone. A human reviewing a PR reads signatures to understand the change. Inference at the boundary would save a few tokens per function at the cost of making every function opaque.

**Why infer everything else.** Inside a function body, types are implementation detail. `let x: Int = 42` carries no information that the compiler doesn't already know from `42`. Every redundant annotation is a token the AI had to generate and the human has to read. Inference reclaims those tokens for code that matters.

**Bidirectional inference.** Type information flows both forward (from definitions to uses) and backward (from uses to definitions). This handles common patterns without annotation:

```pact
// Forward: type of map's output inferred from closure body
let lengths = names.map(fn(n) { n.len() })   // List[Int]

// Backward: closure param type inferred from map's expected input
let upper = names.map(fn(n) { n.to_upper() }) // n is Str, inferred from List[Str]
```

**Keyword labels are not part of the type.** Declaration-site keyword parameters (see [2.13](02_syntax.md#213-declaration-site-keyword-arguments)) use `--` to separate positional from keyword params, but labels are call-site enforcement only. The function type ignores labels entirely:

```pact
// This function:
fn transfer(amount: Int, -- from: Account, to: Account) -> Result[Transaction, BankError]

// Has type: fn(Int, Account, Account) -> Result[Transaction, BankError]
// The -- and labels are invisible to the type system
```

This means closures, trait implementations, and higher-order functions work without label awareness:

```pact
// A closure assigned to a variable with compatible type
let f: fn(Int, Account, Account) -> Result[Transaction, BankError] = transfer

// Passing as a higher-order function argument
fn apply(op: fn(Int, Account, Account) -> Result[Transaction, BankError]) { ... }
apply(transfer)  // works — labels are erased at the type level
```

Direct call sites enforce labels (the compiler errors if you call `transfer` without `from:` and `to:`). But when a function is passed as a value, labels are erased. This keeps the type system simple — 99% of same-typed-param bugs occur at direct call sites, where labels are enforced.

**Numeric literals.** Unadorned integer literals default to `Int`. Unadorned float literals default to `Float`. If context demands a specific size (e.g., assigning to a `U8` field), the literal is checked against the target type's range at compile time:

```pact
let port: U16 = 8080        // OK: 8080 fits in U16
let bad: U8 = 300           // COMPILE ERROR: 300 exceeds U8 range (0..255)
```

---

### 3.4 Algebraic Data Types

Pact uses a single `type` keyword for all user-defined types. The compiler distinguishes sum types (variants) from product types (fields) by structure, not by separate keywords.

#### Product Types (Structs)

A type with only named fields is a product type:

```pact
type User {
    name: Str
    email: Str
    age: Int
}

// Construction
let user = User { name: "Alice", email: "alice@example.com", age: 30 }

// Field access
let name = user.name
```

#### Sum Types (Enums)

A type with variants is a sum type. Variants can carry data or be unit-like:

```pact
type Color {
    Red
    Green
    Blue
    Custom(r: U8, g: U8, b: U8)
}

type Shape {
    Circle(radius: Float)
    Rectangle(width: Float, height: Float)
    Point
}
```

#### Why One Keyword

Most languages split these: `struct` + `enum` (Rust), `data class` + `sealed class` (Kotlin), `type` + `datatype` (SML). Two keywords means two mental models, two sets of rules, and an AI that has to decide which one to use.

In Pact, `type` is `type`. If it has variants, it's a sum. If it has fields, it's a product. If it has variants where some carry fields, it's a sum of products. The compiler doesn't care about the taxonomy; it cares about the structure.

#### Generic Types

Type parameters use square brackets:

```pact
type Pair[A, B] {
    first: A
    second: B
}

type Tree[T] {
    Leaf(value: T)
    Branch(left: Tree[T], right: Tree[T])
}

type Either[L, R] {
    Left(L)
    Right(R)
}
```

Type parameters are inferred at construction sites when possible:

```pact
let pair = Pair { first: "hello", second: 42 }  // Pair[Str, Int]
let tree = Branch(Leaf(1), Leaf(2))              // Tree[Int]
```

#### Recursive Types

Types can reference themselves. The compiler handles the indirection:

```pact
type JsonValue {
    Null
    Boolean(Bool)
    Number(Float)
    Str(Str)
    Array(List[JsonValue])
    Object(Map[Str, JsonValue])
}
```

---

### 3.5 Pattern Matching

Pattern matching is Pact's primary mechanism for branching on data shape. Every `match` expression must exhaustively cover all possible values of the scrutinee type. The compiler rejects non-exhaustive matches at compile time.

```pact
match value {
    pattern => expression
    pattern if guard => expression
}
```

#### Pattern Grammar

```
pattern       ::= or_pattern

or_pattern    ::= bind_pattern ( "|" bind_pattern )*

bind_pattern  ::= IDENT "as" atomic_pattern
               |  atomic_pattern

atomic_pattern ::= "_"                                        // wildcard
               |   IDENT                                      // variable binding
               |   INT_LIT                                    // integer literal
               |   FLOAT_LIT                                  // float literal
               |   BOOL_LIT                                   // true | false
               |   STR_LIT                                    // string literal
               |   INT_LIT ".." INT_LIT                       // exclusive range
               |   INT_LIT "..=" INT_LIT                      // inclusive range
               |   CHAR_LIT ".." CHAR_LIT                     // char exclusive range
               |   CHAR_LIT "..=" CHAR_LIT                    // char inclusive range
               |   TYPE_NAME                                  // unit variant
               |   TYPE_NAME "." IDENT                        // qualified unit variant
               |   TYPE_NAME "(" pattern_list ")"             // constructor
               |   TYPE_NAME "." IDENT "(" pattern_list ")"   // qualified constructor
               |   "(" pattern_list ")"                       // tuple
               |   TYPE_NAME "{" field_patterns "}"           // struct

pattern_list  ::= pattern ( "," pattern )*

field_patterns ::= field_pattern ( "," field_pattern )* ( "," ".." )?
               |   ".."

field_pattern  ::= IDENT ":" pattern                          // field with sub-pattern
               |   IDENT                                      // field punning

guard         ::= "if" expression

match_arm     ::= pattern guard? "=>" expression
```

#### Pattern Forms

**Wildcard.** `_` matches any value and discards it.

**Variable binding.** An identifier binds the matched value to a new variable in the arm body.

**Literal.** Integer, float, boolean, and string literals match by value equality.

```pact
match status {
    200 => "ok"
    404 => "not found"
    _ => "other"
}
```

**Constructor.** Matches enum variants, destructuring their fields.

```pact
fn area(shape: Shape) -> Float {
    match shape {
        Circle(r) => 3.14159 * r * r
        Rectangle(w, h) => w * h
        Point => 0.0
    }
}
```

**Nested patterns.** Patterns compose — any sub-position accepts a full pattern.

```pact
fn describe(val: JsonValue) -> Str {
    match val {
        Null => "null"
        Boolean(true) => "yes"
        Boolean(false) => "no"
        Number(n) => "number: {n}"
        Str(s) => "string: {s}"
        Array(items) => "array of {items.len()}"
        Object(map) => "object with {map.len()} keys"
    }
}
```

**Tuple patterns.** Match and destructure tuple values (see also §3.8).

```pact
fn classify(pair: (Int, Int)) -> Str {
    match pair {
        (0, 0) => "origin"
        (0, _) => "y-axis"
        (_, 0) => "x-axis"
        _ => "other"
    }
}
```

**Struct patterns.** Match struct types by field values. Type name is required (nominal matching). Field punning binds a field to a variable of the same name. `..` is required when not all fields are listed.

```pact
match user {
    User { name: "admin", .. } => grant_admin_access()
    User { name, age, .. } if age >= 18 => allow_access(name)
    User { name, .. } => deny_access(name)
}

// Nested: struct inside enum
match response {
    Ok(User { name, email, .. }) => send_welcome(name, email)
    Err(ApiError.NotFound(msg)) => log_error(msg)
    Err(_) => log_error("unknown error")
}

// Field punning: { name } is short for { name: name }
match config {
    ServerConfig { port, debug: true, .. } => start_debug(port)
    ServerConfig { port, .. } => start(port)
}
```

#### OR-Patterns

Multiple patterns separated by `|` share a single arm body. All alternatives must bind the same set of variable names with the same types. `|` binds looser than constructor application, tighter than `=>`. No nested OR inside constructors — use `Some(1) | Some(2)`, not `Some(1 | 2)`.

```pact
match status_code {
    200 | 201 | 204 => handle_success(response)
    400 | 422 => handle_client_error(response)
    500 | 502 | 503 => handle_server_error(response)
    code => handle_unknown(code)
}

match event {
    Event.Click(x, y) | Event.Touch(x, y) => handle_input(x, y)
    Event.Quit => break
    _ => {}
}
```

```
error[E0310]: inconsistent bindings in OR-pattern
 --> input.pact:5:5
  |
5 |     Some(x) | None => use(x)
  |     ^^^^^^^   ^^^^ `None` does not bind `x`
  |
  = help: all alternatives must bind the same variables
```

#### Range Patterns

Integer and character ranges match contiguous value sets. Both `..` (exclusive end) and `..=` (inclusive end) are supported, consistent with range expression syntax (§2.9). Bounds must be compile-time constants. Only `Int`, sized integers (`I8`, `U8`, etc.), and `Char` types are allowed — not `Float` or `Str`. The exhaustiveness checker tracks covered ranges.

```pact
fn classify_http(code: Int) -> Str {
    match code {
        100..=199 => "informational"
        200..=299 => "success"
        300..=399 => "redirect"
        400..=499 => "client error"
        500..=599 => "server error"
        _ => "unknown"
    }
}

// Combined with OR-patterns
match score {
    0 => "zero"
    1..=59 => "failing"
    60..=100 => "passing"
    _ => "invalid"
}
```

#### Pattern Binding (`as`)

Bind the matched value to a name while simultaneously destructuring it. The bound name gets the pre-destructured value (scrutinee type). Syntax: `name as pattern`.

```pact
match get_config() {
    config as ServerConfig { port, .. } if port > 1024 =>
        start_with_config(config, port)
    _ => start_with_defaults()
}

match event {
    original as Event.Request(req) => {
        log_event(original)
        handle(req)
    }
    _ => {}
}
```

#### Guard Clauses

A guard is a boolean expression attached to a match arm with `if`. The arm matches only when the pattern matches AND the guard evaluates to `true`. Guards must be pure expressions — no effect operations in guard position. Guards are opaque to the exhaustiveness checker; a match with guards always requires a wildcard or otherwise complete coverage.

```pact
fn classify(n: Int) -> Str {
    match n {
        0 => "zero"
        n if n > 0 => "positive"
        _ => "negative"
    }
}
```

Guards apply to the entire OR-pattern group: `Some(x) | Some(y) if x > 0` means `(Some(x) | Some(y)) if x > 0`.

#### Exhaustiveness

Every `match` must cover all possible values. The compiler performs exhaustiveness analysis and rejects incomplete matches.

```
error[E0004]: non-exhaustive match
 --> geometry.pact:15:5
  |
15|     match shape {
  |     ^^^^^ missing pattern: `Triangle`
  |
  = fix: add arm `Triangle(base, height) => <expr>`
```

The exhaustiveness checker handles:
- **Enum variants** — tracks which variants are covered
- **Boolean** — `true` and `false` must both appear (or wildcard)
- **Integer/char ranges** — tracks covered intervals, reports uncovered ranges
- **Nested patterns** — recursive analysis through constructors, tuples, and structs
- **Guards** — treated as opaque (may be false), so guarded arms do not contribute to exhaustiveness
- **OR-patterns** — union of covered patterns per alternative

**Why exhaustiveness matters for AI.** The single most common bug AI-generated code produces is the forgotten case. A missing `None` handler, an unhandled error variant, an enum value added without updating all consumers. Exhaustive matching makes this class of bug structurally impossible. The compiler mechanically identifies what's missing and suggests the fix. An AI agent can apply the fix automatically — this is the generate-compile-fix loop working as designed.

#### Refutable vs Irrefutable Patterns

Patterns are classified as **irrefutable** (always match) or **refutable** (may fail to match).

`let` bindings and `for` loops require **irrefutable** patterns. A refutable pattern in `let` position is a compile error. `match` arms accept refutable patterns.

**Irrefutable patterns** (allowed in `let` and `for`):
- Variable binding: `let x = ...`
- Wildcard: `let _ = ...`
- Tuple of irrefutable patterns: `let (a, b) = ...`
- Struct with all irrefutable field patterns + `..`: `let User { name, .. } = ...`
- Single-variant enum: if an enum has exactly one variant, that variant's pattern is irrefutable
- Nested irrefutable: `let ((x, y), label) = ...`

**Refutable patterns** (only in `match` arms):
- Literals: `0`, `true`, `"hello"`
- Specific enum variants when the enum has multiple variants: `Some(x)`, `None`, `Ok(v)`
- Range patterns: `1..=5`
- OR-patterns: `Some(x) | None`
- Struct patterns with literal field values: `User { name: "admin", .. }`

```pact
// OK: irrefutable — tuple always has 2 elements
let (x, y) = get_point()

// OK: irrefutable — struct destructuring with rest
let User { name, email, .. } = get_user()

// OK: irrefutable in for loop
for (key, value) in map {
    io.println("{key}: {value}")
}
```

```
error[E0500]: refutable pattern in `let` binding
 --> auth.pact:3:5
  |
3 |     let Some(x) = maybe_value
  |         ^^^^^^^ pattern `None` not covered
  |
  = help: use `match` or `??` instead:
  |   let x = maybe_value ?? default_value
  |   match maybe_value { Some(x) => ..., None => ... }
```

#### Destructuring Summary

Destructuring is the irrefutable subset of pattern matching. It works uniformly in `let` bindings, `for` loops, and function parameters (§3.8 for tuples).

```pact
// Tuple destructuring
let (name, age) = get_user_info()
let (status, body) = parse_response(data)?

// Nested tuple destructuring
let ((x, y), label) = get_labeled_point()

// Struct destructuring
let User { name, email, .. } = get_current_user()

// Ignoring elements
let (_, count) = tally(items)

// In for loops
for (key, value) in map {
    io.println("{key}: {value}")
}
```

---

### 3.6 Traits

Traits define shared behavior. They are the sole polymorphism mechanism in Pact. There is no inheritance, no subtyping, no implicit conversions.

#### Trait Declaration

```pact
trait Display {
    fn display(self) -> Str
}

trait Eq {
    fn eq(self, other: Self) -> Bool
    fn ne(self, other: Self) -> Bool {
        !self.eq(other)
    }
}

trait Hash: Eq {
    fn hash(self) -> U64
}

trait Ord: Eq {
    fn cmp(self, other: Self) -> Ordering
}
```

The `Ordering` type used by `Ord.cmp` is compiler-known and auto-imported in the module prelude (vote: 5-0):

```pact
type Ordering {
    Less
    Equal
    Greater
}
```

#### The `Self` Type

`Self` is a built-in type alias that refers to the implementing type. It is valid in exactly two contexts:

1. **Trait declarations** — `Self` refers to whichever type will implement the trait.
2. **`impl` blocks** — `Self` refers to the type being implemented.

Outside these contexts, `Self` is a compile error.

```pact
trait Eq {
    fn eq(self, other: Self) -> Bool       // Self = the implementing type
    fn ne(self, other: Self) -> Bool {
        !self.eq(other)
    }
}

impl Eq for Color {
    fn eq(self, other: Self) -> Bool {     // Self = Color
        // ...
    }
}
```

```
error[E0170]: `Self` outside trait or impl
 --> utils.pact:3:18
  |
3 |     fn clone() -> Self {
  |                    ^^^^ `Self` is only valid inside trait declarations and impl blocks
```

**`self` is sugar for `self: Self`.** The first parameter of a trait method can be written as bare `self`, which desugars to `self: Self`. Method-call syntax (`x.method()`) requires the first parameter to be literally `self` — a method with `self` renamed (e.g., `this: Self`) is callable only via qualified syntax `Trait.method(this)`.

```pact
trait Display {
    fn display(self) -> Str          // self: Self, enables x.display()
}

trait Combiner {
    fn combine(a: Self, b: Self) -> Self   // no `self` param — not a method
}

// Combiner must be called with qualified syntax:
let merged = Combiner.combine(left, right)
```

**`Self` is a type-position alias, not a constructor.** You cannot write `Self { field: value }` or `Self(args)` to construct values. Use the concrete type name.

```
error[E0171]: `Self` is not a constructor
 --> shapes.pact:12:9
  |
12|         Self { x: 0, y: 0 }
  |         ^^^^ cannot construct with `Self`
  |
  = help: use the concrete type name: `Point { x: 0, y: 0 }`
```

**`self` is always passed by value.** Pact is garbage-collected — there is no by-reference vs by-move distinction. The `self` parameter is a value like any other parameter. No `&self`, `&mut self`, or `self: Box[Self]` forms exist.

#### Arithmetic Traits

```pact
trait Add {
    fn add(self, other: Self) -> Self
}

trait Sub {
    fn sub(self, other: Self) -> Self
}

trait Mul {
    fn mul(self, other: Self) -> Self
}

trait Div {
    fn div(self, other: Self) -> Self
}

trait Rem {
    fn rem(self, other: Self) -> Self
}

trait Neg {
    fn neg(self) -> Self
}
```

Arithmetic traits are **sealed** -- the compiler restricts implementations to built-in numeric types only. User-defined types cannot implement them. This prevents operator soup where `+` means something different on every type (vote: 4-1, Systems expert dissented wanting open impls).

```
error[E0120]: sealed trait
 --> vector.pact:8:1
  |
8 | impl Add for Vector2 {
  | ^^^^^^^^ `Add` is sealed -- only built-in numeric types may implement it
  |
  = note: arithmetic traits (Add, Sub, Mul, Div, Rem, Neg) are compiler-restricted
  = help: define a named method instead: `fn add(self, other: Vector2) -> Vector2`
```

If you need vector/matrix math, use named methods: `v1.add(v2)` -- clear and grep-able.

#### Operator Desugaring

Operators desugar to trait method calls. The full mapping:

| Expression | Desugars to | Trait |
|------------|-------------|-------|
| `a + b` | `Add.add(a, b)` | `Add` |
| `a - b` | `Sub.sub(a, b)` | `Sub` |
| `a * b` | `Mul.mul(a, b)` | `Mul` |
| `a / b` | `Div.div(a, b)` | `Div` |
| `a % b` | `Rem.rem(a, b)` | `Rem` |
| `-a` | `Neg.neg(a)` | `Neg` |
| `a == b` | `a.eq(b)` | `Eq` |
| `a != b` | `a.ne(b)` | `Eq` |
| `a < b` | `a.cmp(b) == Less` | `Ord` |
| `a > b` | `a.cmp(b) == Greater` | `Ord` |
| `a <= b` | `a.cmp(b) != Greater` | `Ord` |
| `a >= b` | `a.cmp(b) != Less` | `Ord` |

Operands must be the same type. Mixed-type arithmetic (`Int + Float`) is a compile error -- use explicit conversion.

#### Float Total Ordering

`Float` implements `Eq` and `Ord` with **total ordering** semantics (vote: 5-0):

- `NaN == NaN` is `true` (restores reflexivity)
- `NaN` sorts greater than all other values
- `-0.0 == 0.0` is `true`
- `Float` does **not** implement `Hash` (float equality is fraught for hashing)

For IEEE 754-strict comparison where `NaN != NaN` and `-0.0 != 0.0`: use `float.ieee_eq(other)` from stdlib.

#### Built-in Type Trait Implementations

| Type | Add | Sub | Mul | Div | Rem | Neg | Eq | Ord | Hash | Display |
|------|-----|-----|-----|-----|-----|-----|----|----|------|---------|
| Int | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| I8/I16/I32 | Y | Y | Y | Y | Y | Y | Y | Y | Y | Y |
| U8/U16/U32/U64 | Y | Y | Y | Y | Y | -- | Y | Y | Y | Y |
| Float | Y | Y | Y | Y | Y | Y | Y* | Y* | -- | Y |
| Bool | -- | -- | -- | -- | -- | -- | Y | -- | Y | Y |
| Str | -- | -- | -- | -- | -- | -- | Y | Y | Y | Y |
| Char | -- | -- | -- | -- | -- | -- | Y | Y | Y | Y |

Y* = total ordering semantics. Unsigned types don't impl `Neg`. `Float` doesn't impl `Hash`.

#### Integer Division

`Int / Int` performs integer division (truncates toward zero). `Float / Float` performs IEEE 754 division. Division by zero on integers is a runtime panic.

Traits can have default method implementations (`ne` above). Traits can require other traits (`Hash: Eq` means implementing `Hash` requires implementing `Eq`).

#### Trait Implementation

```pact
impl Display for Color {
    fn display(self) -> Str {
        match self {
            Red => "Red"
            Green => "Green"
            Blue => "Blue"
            Custom(r, g, b) => "rgb({r}, {g}, {b})"
        }
    }
}

impl Eq for Color {
    fn eq(self, other: Color) -> Bool {
        match (self, other) {
            (Red, Red) => true
            (Green, Green) => true
            (Blue, Blue) => true
            (Custom(r1, g1, b1), Custom(r2, g2, b2)) =>
                r1 == r2 && g1 == g2 && b1 == b2
            _ => false
        }
    }
}
```

#### Trait Bounds

Generics are constrained by trait bounds:

```pact
fn max[T: Ord](a: T, b: T) -> T {
    match a.cmp(b) {
        Greater => a
        _ => b
    }
}

fn print_all[T: Display](items: List[T]) ! IO {
    for item in items {
        io.println(item.display())
    }
}

// Multiple bounds
fn dedup[T: Eq + Hash](items: List[T]) -> List[T] {
    let mut seen = Set.new()
    items.filter(fn(item) {
        seen.insert(item)
    })
}
```

#### Why Traits Over Inheritance

Inheritance creates vertical hierarchies. Understanding a method call requires traversing the class tree upward through potentially dozens of files. This is anti-locality at its worst -- a single method dispatch can depend on code scattered across an entire codebase.

Traits are horizontal. Each `impl` block is self-contained. To understand what `Display` does for `Color`, you read one block. No parent classes, no `super` calls, no method resolution order, no fragile base class problem, no diamond inheritance.

For AI, this is critical. An AI generating a trait impl needs context from two places: the trait declaration and the type definition. Not the entire class hierarchy. Two files, not fifteen.

Traits also support retroactive implementation -- you can implement a trait for a type you didn't define (subject to coherence rules). This enables extending types with new behavior without modifying their source, which is impossible with class inheritance.

---

#### Compiler-Known Traits

Certain traits have special meaning to the compiler. They are defined in the standard library but the compiler understands their semantics and can generate or enforce behavior based on them.

| Trait | Compiler behavior |
|-------|------------------|
| `Eq` | Enables `==` and `!=` operators. `@derive(Eq)` auto-generates structural equality. |
| `Ord` | Enables `<`, `>`, `<=`, `>=` and `cmp`. Requires `Eq`. |
| `Hash` | Enables use as `Map` key or `Set` element. Requires `Eq`. |
| `Display` | Enables string interpolation (`"{value}"`). |
| `Add` | Enables `+` operator. Sealed to numeric types. |
| `Sub` | Enables `-` operator. Sealed to numeric types. |
| `Mul` | Enables `*` operator. Sealed to numeric types. |
| `Div` | Enables `/` operator. Sealed to numeric types. |
| `Rem` | Enables `%` operator. Sealed to numeric types. |
| `Neg` | Enables unary `-` operator. Sealed to signed numeric types. |
| `From[T]` | Infallible type conversion. Enables `Into[T]` auto-derivation. User-implemented. |
| `Into[T]` | Auto-derived mirror of `From`. Provides `.into()` method syntax. Never user-implemented. |
| `TryFrom[T]` | Fallible conversion returning `Result[Self, ConversionError]`. Auto-generated for refinement types. |
| `Closeable` | Signals non-memory resources needing deterministic cleanup. Enables `with...as` scoped resource blocks. |
| `Iterator` | Enables `for`-loop iteration, lazy adapter methods (`.map()`, `.filter()`, etc.), and `.collect()` materialization. |
| `IntoIterator` | Enables a type to be used in `for x in expr`. Collections implement this to produce an `Iterator`. |

The `Closeable` trait is the simplest:

```pact
trait Closeable {
    fn close(self)
}
```

A type implementing `Closeable` holds resources (file handles, sockets, locks, database cursors) that must be released deterministically — not when the GC gets around to it, but at a specific point in the program. The `with...as` construct (section 2.17, section 5.5) guarantees `close()` is called on all exit paths.

```pact
type FileHandle {
    fd: Int
    path: Str
}

impl Closeable for FileHandle {
    fn close(self) ! FS {
        fs.close_fd(self.fd)
    }
}
```

The compiler uses `Closeable` to power lint W0600 (warn when a `Closeable` value is used outside a `with...as` block) and errors E0601/E0602 (closeable escapes scope). See section 5.5 for the full mechanism.

---

### 3.7 No Null, No Exceptions

These are not restrictions. They are the elimination of two categories of bugs that account for more production incidents than any other.

#### No Null

There is no `null`, `nil`, `None`-as-implicit-value, or bottom type that inhabits every type. A `Str` is always a string. An `Int` is always an integer. If a value might be absent, the type says so:

```pact
// This function might not find a user. The type says so.
fn find_user(id: Int) -> Option[User] ! DB {
    db.query_one("SELECT * FROM users WHERE id = {id}")
}

// The caller MUST handle the absence. The compiler enforces this.
let user = find_user(42)
// user is Option[User] -- you cannot call .name on it directly

// Option 1: Default value with ??
let name = find_user(42)?.name ?? "Unknown"

// Option 2: Pattern match
match find_user(42) {
    Some(u) => io.println("Found: {u.name}")
    None => io.println("User not found")
}

// Option 3: Early return with ?
fn get_user_name(id: Int) -> Option[Str] ! DB {
    let user = find_user(id)?   // returns None if not found
    Some(user.name)
}
```

The `T?` sugar makes optional types concise in signatures:

```pact
fn find_user(id: Int) -> User? ! DB      // same as Option[User]
fn get_config(key: Str) -> Str?           // same as Option[Str]
```

#### No Exceptions

There is no `throw`, no `try/catch`, no unchecked exceptions, no exception hierarchy. Operations that can fail return `Result[T, E]`:

```pact
fn parse_port(s: Str) -> Result[Int, ParseError] {
    let n = parse_int(s)?
    if n < 1 || n > 65535 {
        Err(ParseError { message: "port out of range: {n}" })
    } else {
        Ok(n)
    }
}

fn read_config(path: Str) -> Result[Config, ConfigError] ! IO {
    let text = io.read_file(path)?             // IOError -> ConfigError
    let parsed = parse_toml(text)?             // ParseError -> ConfigError
    validate_config(parsed)?                    // ValidationError -> ConfigError
    Ok(parsed)
}
```

The `?` operator is the error propagation mechanism. It unwraps `Ok` or returns early with `Err`. Every error path is visible in the return type. Every propagation point is visible in the body (the `?` character). There is no invisible control flow.

#### Why This Is Right for an AI-First Language

**Null**: AI models produce null-related bugs at a rate proportional to how easy the language makes it to forget null checks. In languages with null, every reference is implicitly `T | null`, and every dereference is an implicit null check that the programmer (or AI) might forget. In Pact, if a value can be absent, the type says `Option[T]`, and the compiler refuses to let you use it as a `T` without handling the `None` case. The bug category is structurally eliminated.

**Exceptions**: Exceptions create invisible control flow. A function signature says `fn process(data: Str) -> Report`, but the function might throw `IOException`, `ParseException`, `ValidationException`, or anything its callees throw. The signature lies. An AI reading the signature gets incomplete information. In Pact, the same function says `fn process(data: Str) -> Result[Report, ProcessError] ! IO` -- complete, honest, compiler-checked.

The `?` operator is one character with unambiguous semantics. Compare to try/catch blocks where AI commonly generates: wrong catch order, overly broad catches (`catch (Exception e)`), missing finally clauses, and incorrect resource cleanup. The `?` operator has one behavior. There's nothing to get wrong.

---

### 3.8 Tuple Types

Tuples are anonymous product types — fixed-size, heterogeneous, ordered collections of values. They serve as lightweight grouping for returning multiple values, iterating over key-value pairs, and passing small bundles of data without defining a named struct.

#### Syntax

```pact
// Type position
(Int, Str)
(Bool, Int, Float)
(T, Stack[T])

// Value construction
let pair = (42, "hello")
let triple = (true, 1, 3.14)

// Element access — positional, zero-indexed
pair.0          // 42
pair.1          // "hello"
triple.2        // 3.14

// Destructuring
let (code, message) = get_status()
let (key, value) = entry

// In function signatures
fn pop[T](stack: Stack[T]) -> (T, Stack[T]) {
    // ...
}

// As generic parameters
fn zip[T, U](a: Iterator[T], b: Iterator[U]) -> Iterator[(T, U)] {
    // ...
}
```

#### Unit Type

The unit type `()` is the 0-tuple — a type with exactly one value, carrying no information. It is the implicit return type of functions and blocks that produce no value.

```pact
fn log(msg: Str) ! IO {
    io.println(msg)
}
// return type is (), omitted by convention
```

#### No 1-Tuples

`(T)` in type or expression position is always parenthesization, never a 1-tuple. The 1-ary product is isomorphic to `T` and adds no expressiveness. For newtype wrapping, use a named struct:

```pact
// Not a 1-tuple — just parenthesized
let x: (Int) = 42        // same as: let x: Int = 42
let y = (some_expr)       // same as: let y = some_expr

// For newtype wrapping, use a struct
type UserId {
    value: Int
}
```

#### Arity Limit

Tuples support arity 0 (unit) through 6. A tuple with more than 6 elements is a compile error — use a named struct instead.

```pact
let ok = (1, 2, 3, 4, 5, 6)           // OK: arity 6
let bad = (1, 2, 3, 4, 5, 6, 7)       // COMPILE ERROR
```

```
error[E0180]: tuple arity exceeds maximum
 --> data.pact:3:11
  |
3 |     let x = (1, 2, 3, 4, 5, 6, 7)
  |             ^^^^^^^^^^^^^^^^^^^^^^^ tuple has 7 elements, maximum is 6
  |
  = help: use a named struct for data with more than 6 fields
```

**Why cap at 6.** Tuples are anonymous — elements have no names, only positions. Beyond 3-4 elements, positional access (`.4`, `.5`) becomes unreadable and error-prone. A cap at 6 provides headroom for real use cases (coordinate triples, tagged pairs, iterator adapters) while pushing complex data toward named structs where field names carry semantic information. The cap also bounds the compiler's trait impl generation to a small fixed set of arities.

#### Element Access

Tuple elements are accessed by zero-indexed numeric fields: `.0`, `.1`, `.2`, etc. These are compile-time resolved field accesses, not method calls.

```pact
let point = (10.0, 20.0, 30.0)
let x = point.0    // 10.0
let y = point.1    // 20.0
let z = point.2    // 30.0
```

Out-of-bounds access is a compile error:

```pact
let pair = (1, 2)
pair.2              // COMPILE ERROR: tuple (Int, Int) has no field `2`
```

#### Destructuring

Tuples support irrefutable destructuring in `let` bindings (see also §3.5):

```pact
let (name, age) = get_user_info()
let (status, body) = parse_response(data)?

// Nested destructuring
let ((x, y), label) = get_labeled_point()

// Ignore elements with _
let (_, count) = tally(items)

// In for loops
for (key, value) in map {
    io.println("{key}: {value}")
}
```

Pattern matching on tuples works in `match` expressions:

```pact
fn classify(pair: (Int, Int)) -> Str {
    match pair {
        (0, 0) => "origin"
        (0, _) => "y-axis"
        (_, 0) => "x-axis"
        (x, y) if x == y => "diagonal"
        _ => "other"
    }
}
```

#### Auto-Derived Trait Implementations

The compiler automatically implements traits for tuple types when all element types satisfy the trait. No `@derive` annotation needed — tuples are anonymous, so derivation is structural and implicit.

| Trait | Behavior | Derived when |
|-------|----------|-------------|
| `Eq` | Element-wise `==`. `(a0, a1) == (b0, b1)` iff `a0 == b0 && a1 == b1` | All elements: `Eq` |
| `Ord` | Lexicographic. Compare `.0` first; if equal, compare `.1`; etc. | All elements: `Ord` |
| `Hash` | Combine element hashes | All elements: `Hash` |
| `Display` | `"(a, b, c)"` format | All elements: `Display` |
| `Clone` | Element-wise clone | All elements: `Clone` |

```pact
// Eq — works because Int and Str both implement Eq
let a = (1, "hello")
let b = (1, "hello")
assert_eq(a, b)

// Ord — lexicographic comparison
let pairs = [(3, "c"), (1, "b"), (1, "a")]
let sorted = pairs.into_iter().sort().collect()
// [(1, "a"), (1, "b"), (3, "c")]

// Hash — tuples as Map keys
let mut cache: Map[(Str, Int), Result] = Map.new()
cache.insert(("users", 42), result)

// Display — string interpolation
let point = (10, 20)
io.println("Point: {point}")   // "Point: (10, 20)"
```

When an element type lacks a trait, the tuple type also lacks it, and the compiler identifies the specific element:

```
error[E0120]: trait bound not satisfied
 --> render.pact:5:12
  |
5 |     let sorted = shapes.sort()
  |                         ^^^^ `(Int, Canvas)` does not implement `Ord`
  |
  = note: `Canvas` does not implement `Ord` (element .1 of tuple)
  = help: implement `Ord` for `Canvas`, or extract a sortable key
```

#### Tuples vs Structs

Tuples and structs are both product types. Use tuples for ephemeral grouping; use structs when the data has identity or the fields need names.

| Use tuples for | Use structs for |
|----------------|-----------------|
| Multiple return values: `fn pop() -> (T, Stack[T])` | Domain types: `type User { name: Str, age: Int }` |
| Iterator adapters: `enumerate() -> Iterator[(Int, T)]` | Config: `type ServerConfig { host: Str, port: Int }` |
| Map iteration: `for (k, v) in map` | Public API types |
| Temporary grouping in local scope | Anything with more than 6 fields |
| Pattern matching on pairs | Anything that needs trait impls beyond the auto-derived set |
