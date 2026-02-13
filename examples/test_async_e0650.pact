// Test: E0650 -- mutable capture in async.spawn should be a compile error.
//
// The Pact spec forbids capturing `let mut` variables in async.spawn closures
// because mutable shared state across threads is unsafe without synchronization.
// Error E0650: "mutable variable 'x' cannot be captured by async.spawn"
//
// This file tests the PASSING case: immutable captures work fine in async.spawn.
// The failing case (mutable capture) is commented out below for reference.

fn main() {
    io.println("=== async E0650 (capture safety) tests ===")
    let mut pass = 0
    let mut fail = 0

    // --- immutable capture in async.spawn works ---
    io.println("--- immutable capture ---")
    let x = 10
    let y = 20
    let h = async.spawn(fn() {
        x + y
    })
    let result = h.await
    if result == 30 {
        io.println("ok: immutable capture x+y = 30")
        pass = pass + 1
    } else {
        io.println("FAIL: expected 30, got {result}")
        fail = fail + 1
    }

    // --- multiple immutable captures ---
    io.println("--- multiple immutable captures ---")
    let a = 100
    let b = 200
    let c = 300
    async.scope {
        let h1 = async.spawn(fn() {
            a + b + c
        })
        let r1 = h1.await
        if r1 == 600 {
            io.println("ok: three immutable captures sum = 600")
            pass = pass + 1
        } else {
            io.println("FAIL: expected 600, got {r1}")
            fail = fail + 1
        }
    }

    // --- immutable capture of computed value ---
    io.println("--- capture of computed value ---")
    let computed = 7 * 8
    let h2 = async.spawn(fn() {
        computed + 1
    })
    let r2 = h2.await
    if r2 == 57 {
        io.println("ok: computed capture = 57")
        pass = pass + 1
    } else {
        io.println("FAIL: expected 57, got {r2}")
        fail = fail + 1
    }

    // --- E0650: mutable capture (SHOULD NOT COMPILE) ---
    // Uncommenting the code below should produce:
    //   error E0650: mutable variable 'counter' cannot be captured by async.spawn
    //
    // let mut counter = 0
    // let h_bad = async.spawn(fn() {
    //     counter + 1
    // })
    // h_bad.await

    // --- results ---
    io.println("--- results ---")
    if fail == 0 {
        io.println("{pass} passed, 0 errors")
        io.println("PASS")
    } else {
        io.println("{pass} passed, {fail} FAIL")
    }
}
