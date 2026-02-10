fn main() {
    let mut pass = true

    // 1. Mutable counter visible across closure boundary
    let mut counter = 0
    let increment = fn() {
        counter = counter + 1
    }
    increment()
    increment()
    increment()
    if counter != 3 {
        io.println("FAIL: mutable counter expected 3, got {counter}")
        pass = false
    }

    // 2. Snapshot idiom: capture a frozen copy, not the mutable
    let mut count = 0
    count = count + 1
    count = count + 1
    let snapshot = count
    let get_snapshot = fn() -> Int { snapshot }
    count = count + 1
    count = count + 1
    if get_snapshot() != 2 {
        io.println("FAIL: snapshot expected 2, got {get_snapshot()}")
        pass = false
    }
    if count != 4 {
        io.println("FAIL: count expected 4, got {count}")
        pass = false
    }

    // 3. Immutable capture
    let x = 42
    let msg = "hello"
    let check = fn() -> Int { x }
    let greet = fn() -> Str { "{msg} world" }
    if check() != 42 {
        io.println("FAIL: immutable int capture expected 42, got {check()}")
        pass = false
    }
    if greet() != "hello world" {
        io.println("FAIL: immutable str capture expected 'hello world', got {greet()}")
        pass = false
    }

    if pass {
        io.println("PASS")
    }
}
