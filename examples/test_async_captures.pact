fn main() {
    let multiplier = 10
    let h = async.spawn(fn() {
        5 * multiplier
    })
    let result = h.await
    if result == 50 {
        io.println("PASS: async.spawn with captures works")
    } else {
        io.println("FAIL: expected 50 from capture test")
    }

    let base = 100
    let offset = 42
    let h2 = async.spawn(fn() {
        base + offset
    })
    let r2 = h2.await
    if r2 == 142 {
        io.println("PASS: async.spawn with multiple captures works")
    } else {
        io.println("FAIL: expected 142 from multi-capture test")
    }

    io.println("async capture tests complete")
}
