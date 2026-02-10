fn apply(f: fn(Int) -> Int, x: Int) -> Int {
    f(x)
}

fn apply_twice(f: fn(Int) -> Int, x: Int) -> Int {
    f(f(x))
}

fn apply_then_add(f: fn(Int) -> Int, x: Int, extra: Int) -> Int {
    f(x) + extra
}

fn main() {
    let mut pass = true

    // 1. Basic HOF: pass named closure to function
    let dbl = fn(x: Int) -> Int { x * 2 }
    if apply(dbl, 5) != 10 {
        io.println("FAIL: apply(dbl, 5) expected 10")
        pass = false
    }

    // 2. Pass inline (anonymous) closure directly
    if apply(fn(x: Int) -> Int { x + 3 }, 10) != 13 {
        io.println("FAIL: apply(inline +3, 10) expected 13")
        pass = false
    }

    // 3. Apply a closure twice (nested HOF call)
    if apply_twice(dbl, 3) != 12 {
        io.println("FAIL: apply_twice(dbl, 3) expected 12")
        pass = false
    }

    // 4. Apply with extra computation in HOF body
    let triple = fn(x: Int) -> Int { x * 3 }
    if apply_then_add(triple, 4, 1) != 13 {
        io.println("FAIL: apply_then_add(triple, 4, 1) expected 13")
        pass = false
    }

    // 5. Closure with single capture passed to HOF
    let offset = 100
    let add_offset = fn(x: Int) -> Int { x + offset }
    if apply(add_offset, 5) != 105 {
        io.println("FAIL: apply(add_offset, 5) expected 105")
        pass = false
    }

    // 6. Closure with multiple captures passed to HOF
    let base = 10
    let multiplier = 3
    let transform = fn(x: Int) -> Int { (x + base) * multiplier }
    if apply(transform, 5) != 45 {
        io.println("FAIL: apply(transform, 5) expected 45")
        pass = false
    }

    // 7. Apply-twice with a capturing closure
    let step = 10
    let add_step = fn(x: Int) -> Int { x + step }
    if apply_twice(add_step, 0) != 20 {
        io.println("FAIL: apply_twice(add_step, 0) expected 20")
        pass = false
    }

    // 8. Different closures reuse the same HOF
    let negate = fn(x: Int) -> Int { 0 - x }
    let square = fn(x: Int) -> Int { x * x }
    if apply(negate, 42) != -42 {
        io.println("FAIL: apply(negate, 42) expected -42")
        pass = false
    }
    if apply(square, 7) != 49 {
        io.println("FAIL: apply(square, 7) expected 49")
        pass = false
    }

    // 9. Chain HOF calls: apply a closure, then apply another to the result
    let inc = fn(x: Int) -> Int { x + 1 }
    let r = apply(dbl, apply(inc, 4))
    if r != 10 {
        io.println("FAIL: apply(dbl, apply(inc, 4)) expected 10")
        pass = false
    }

    // 10. Pass same capturing closure to different HOFs
    let bias = 7
    let add_bias = fn(x: Int) -> Int { x + bias }
    if apply(add_bias, 3) != 10 {
        io.println("FAIL: apply(add_bias, 3) expected 10")
        pass = false
    }
    if apply_twice(add_bias, 0) != 14 {
        io.println("FAIL: apply_twice(add_bias, 0) expected 14")
        pass = false
    }
    if apply_then_add(add_bias, 10, 3) != 20 {
        io.println("FAIL: apply_then_add(add_bias, 10, 3) expected 20")
        pass = false
    }

    // 11. Inline closure with capture passed to HOF
    let factor = 5
    if apply(fn(x: Int) -> Int { x * factor }, 6) != 30 {
        io.println("FAIL: apply(inline capture, 6) expected 30")
        pass = false
    }

    // 12. Deeply nested apply
    if apply(dbl, apply(dbl, apply(dbl, 1))) != 8 {
        io.println("FAIL: triple nested apply(dbl) expected 8")
        pass = false
    }

    if pass {
        io.println("PASS")
    }
}
