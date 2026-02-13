fn compute(n: Int) -> Int {
    let mut sum = 0
    let mut i = 0
    while i < n {
        sum = sum + i
        i = i + 1
    }
    sum
}

fn main() {
    // Test 1: basic async.spawn + await
    let h1 = async.spawn(fn() {
        compute(100)
    })
    let result1 = h1.await
    if result1 == 4950 {
        io.println("PASS: async.spawn + await returned correct value")
    } else {
        io.println("FAIL: expected 4950, got something else")
    }

    // Test 2: multiple spawns
    let h2 = async.spawn(fn() {
        10 + 20
    })
    let h3 = async.spawn(fn() {
        100 + 200
    })
    let r2 = h2.await
    let r3 = h3.await
    if r2 == 30 && r3 == 300 {
        io.println("PASS: multiple async spawns work correctly")
    } else {
        io.println("FAIL: multiple async spawns returned wrong values")
    }

    // Test 3: async.scope (synchronous block)
    let scoped = async.scope {
        let x = 5
        x * 10
    }
    if scoped == 50 {
        io.println("PASS: async.scope works correctly")
    } else {
        io.println("FAIL: async.scope returned wrong value")
    }

    io.println("async codegen tests complete")
}
