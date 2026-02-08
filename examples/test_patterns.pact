// test_patterns.pact — Integration test for all pattern matching features
//
// Exercises: wildcard, int literal, bool literal, string literal,
//            range (exclusive/inclusive), enum variant (unqualified/qualified),
//            struct destructuring, or-patterns, as-patterns, identifier binding
//
// KNOWN BUGS (not tested here, filed as issues):
// - Guards (np_guard) not wired into emit_match_expr codegen
// - Struct string field matching (bind_pattern_vars uses string value as field name)
// - Identifier + guard combo generates bare block instead of if(guard)

type Color { Red, Green, Blue }
type Direction { North, South, East, West }

type Point {
    x: Int
    y: Int
}

type User {
    name: Str
    age: Int
}

// --- 1. Integer literal patterns ---
fn classify_int(n: Int) -> Str {
    match n {
        0 => "zero"
        1 => "one"
        42 => "answer"
        _ => "other"
    }
}

// --- 2. Bool literal patterns ---
fn describe_bool(b: Bool) -> Str {
    match b {
        true => "yes"
        false => "no"
    }
}

// --- 3. String literal patterns ---
fn greet(name: Str) -> Str {
    match name {
        "alice" => "hi alice!"
        "bob" => "hey bob!"
        _ => "hello stranger"
    }
}

// --- 4. Range patterns (exclusive and inclusive) ---
fn age_group(age: Int) -> Str {
    match age {
        0..13 => "child"
        13..18 => "teen"
        18..=65 => "adult"
        _ => "senior"
    }
}

// --- 5. Enum patterns (unqualified) ---
fn color_name(c: Color) -> Str {
    match c {
        Red => "red"
        Green => "green"
        Blue => "blue"
    }
}

// --- 6. Enum patterns (qualified) ---
fn color_name_q(c: Color) -> Str {
    match c {
        Color.Red => "RED"
        Color.Green => "GREEN"
        Color.Blue => "BLUE"
    }
}

// --- 7. Or-patterns (enum) ---
fn is_warm(d: Direction) -> Str {
    match d {
        South | East => "warm"
        _ => "cold"
    }
}

// --- 8. Or-patterns (int) ---
fn is_small(n: Int) -> Str {
    match n {
        0 | 1 | 2 | 3 => "small"
        _ => "big"
    }
}

// --- 9. Struct patterns (field punning, rest) ---
fn describe_user(u: User) -> Str {
    match u {
        User { name, .. } => "user: {name}"
    }
}

// --- 10. Struct pattern with nested int value match ---
fn describe_point(p: Point) -> Str {
    match p {
        Point { x: 0, y: 0, .. } => "origin"
        Point { x: 0, .. } => "y-axis"
        Point { y: 0, .. } => "x-axis"
        _ => "other"
    }
}

// --- 11. As-patterns (capture whole enum + match variant) ---
fn color_as(c: Color) -> Str {
    match c {
        whole as Color.Red => "matched red"
        _ => "not red"
    }
}

// --- 12. Identifier binding ---
fn echo_doubled(n: Int) -> Int {
    match n {
        x => x * 2
    }
}

// --- 13. Wildcard ---
fn first_only(n: Int) -> Str {
    match n {
        1 => "one"
        _ => "whatever"
    }
}

// --- 14. Multiple enum or-patterns with qualified syntax ---
fn compass_axis(d: Direction) -> Str {
    match d {
        Direction.North | Direction.South => "vertical"
        Direction.East | Direction.West => "horizontal"
    }
}

fn main() {
    // 1. Integer literals
    io.println("=== Int Literals ===")
    io.println(classify_int(0))
    io.println(classify_int(1))
    io.println(classify_int(42))
    io.println(classify_int(99))

    // 2. Bool literals
    io.println("=== Bool Literals ===")
    io.println(describe_bool(true))
    io.println(describe_bool(false))

    // 3. String literals
    io.println("=== String Literals ===")
    io.println(greet("alice"))
    io.println(greet("bob"))
    io.println(greet("eve"))

    // 4. Range patterns (boundary testing)
    io.println("=== Range Patterns ===")
    io.println(age_group(0))
    io.println(age_group(12))
    io.println(age_group(13))
    io.println(age_group(17))
    io.println(age_group(18))
    io.println(age_group(65))
    io.println(age_group(66))

    // 5. Enum patterns (unqualified)
    io.println("=== Enum Unqualified ===")
    io.println(color_name(Color.Red))
    io.println(color_name(Color.Green))
    io.println(color_name(Color.Blue))

    // 6. Enum patterns (qualified)
    io.println("=== Enum Qualified ===")
    io.println(color_name_q(Color.Red))
    io.println(color_name_q(Color.Green))
    io.println(color_name_q(Color.Blue))

    // 7. Or-patterns (enum)
    io.println("=== Or-Patterns Enum ===")
    io.println(is_warm(Direction.South))
    io.println(is_warm(Direction.East))
    io.println(is_warm(Direction.North))
    io.println(is_warm(Direction.West))

    // 8. Or-patterns (int)
    io.println("=== Or-Patterns Int ===")
    io.println(is_small(0))
    io.println(is_small(3))
    io.println(is_small(10))

    // 9. Struct patterns
    io.println("=== Struct Patterns ===")
    let admin = User { name: "admin", age: 30 }
    let alice = User { name: "alice", age: 25 }
    io.println(describe_user(admin))
    io.println(describe_user(alice))

    // 10. Struct with nested int match
    io.println("=== Struct Nested ===")
    let origin = Point { x: 0, y: 0 }
    let on_y = Point { x: 0, y: 5 }
    let on_x = Point { x: 3, y: 0 }
    let diag = Point { x: 7, y: 9 }
    io.println(describe_point(origin))
    io.println(describe_point(on_y))
    io.println(describe_point(on_x))
    io.println(describe_point(diag))

    // 11. As-patterns
    io.println("=== As-Patterns ===")
    io.println(color_as(Color.Red))
    io.println(color_as(Color.Blue))

    // 12. Identifier binding
    io.println("=== Identifier Binding ===")
    io.println(echo_doubled(21))

    // 13. Wildcard
    io.println("=== Wildcard ===")
    io.println(first_only(1))
    io.println(first_only(999))

    // 14. Qualified or-patterns
    io.println("=== Qualified Or-Patterns ===")
    io.println(compass_axis(Direction.North))
    io.println(compass_axis(Direction.South))
    io.println(compass_axis(Direction.East))
    io.println(compass_axis(Direction.West))

    io.println("=== ALL TESTS PASSED ===")
}
