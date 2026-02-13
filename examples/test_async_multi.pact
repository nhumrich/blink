fn fibonacci(n: Int) -> Int {
    if n <= 1 {
        n
    } else {
        fibonacci(n - 1) + fibonacci(n - 2)
    }
}

fn sum_to(n: Int) -> Int {
    let mut s = 0
    let mut i = 1
    while i <= n {
        s = s + i
        i = i + 1
    }
    s
}

fn factorial(n: Int) -> Int {
    if n <= 1 {
        1
    } else {
        n * factorial(n - 1)
    }
}

fn main() {
    io.println("=== async multi (varied computations) tests ===")
    let mut pass = 0
    let mut fail = 0

    // --- spawn tasks with different computation types ---
    io.println("--- three different computations ---")
    async.scope {
        let h_fib = async.spawn(fn() {
            fibonacci(10)
        })
        let h_sum = async.spawn(fn() {
            sum_to(100)
        })
        let h_fact = async.spawn(fn() {
            factorial(10)
        })

        let r_fib = h_fib.await
        let r_sum = h_sum.await
        let r_fact = h_fact.await

        if r_fib == 55 {
            io.println("ok: fibonacci(10) = 55")
            pass = pass + 1
        } else {
            io.println("FAIL: fibonacci(10) expected 55, got {r_fib}")
            fail = fail + 1
        }

        if r_sum == 5050 {
            io.println("ok: sum_to(100) = 5050")
            pass = pass + 1
        } else {
            io.println("FAIL: sum_to(100) expected 5050, got {r_sum}")
            fail = fail + 1
        }

        if r_fact == 3628800 {
            io.println("ok: factorial(10) = 3628800")
            pass = pass + 1
        } else {
            io.println("FAIL: factorial(10) expected 3628800, got {r_fact}")
            fail = fail + 1
        }
    }

    // --- spawn tasks with captures and different operations ---
    io.println("--- mixed captures and arithmetic ---")
    let multiplier = 7
    let addend = 13
    async.scope {
        let h1 = async.spawn(fn() {
            multiplier * multiplier
        })
        let h2 = async.spawn(fn() {
            addend + addend + addend
        })
        let h3 = async.spawn(fn() {
            multiplier * addend
        })
        let r1 = h1.await
        let r2 = h2.await
        let r3 = h3.await
        if r1 == 49 {
            io.println("ok: 7*7 = 49")
            pass = pass + 1
        } else {
            io.println("FAIL: 7*7 expected 49, got {r1}")
            fail = fail + 1
        }
        if r2 == 39 {
            io.println("ok: 13+13+13 = 39")
            pass = pass + 1
        } else {
            io.println("FAIL: 13+13+13 expected 39, got {r2}")
            fail = fail + 1
        }
        if r3 == 91 {
            io.println("ok: 7*13 = 91")
            pass = pass + 1
        } else {
            io.println("FAIL: 7*13 expected 91, got {r3}")
            fail = fail + 1
        }
    }

    // --- spawn tasks that call top-level functions ---
    io.println("--- tasks calling different functions ---")
    let combined = async.scope {
        let hf = async.spawn(fn() {
            fibonacci(8)
        })
        let hs = async.spawn(fn() {
            sum_to(10)
        })
        let rf = hf.await
        let rs = hs.await
        rf + rs
    }
    // fibonacci(8) = 21, sum_to(10) = 55, combined = 76
    if combined == 76 {
        io.println("ok: fib(8) + sum_to(10) = 76")
        pass = pass + 1
    } else {
        io.println("FAIL: expected 76, got {combined}")
        fail = fail + 1
    }

    // --- results ---
    io.println("--- results ---")
    if fail == 0 {
        io.println("{pass} passed, 0 errors")
        io.println("PASS")
    } else {
        io.println("{pass} passed, {fail} FAIL")
    }
}
