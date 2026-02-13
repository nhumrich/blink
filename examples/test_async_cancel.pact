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
    io.println("=== async cancel (scope auto-join) tests ===")
    let mut pass = 0
    let mut fail = 0

    // --- scope auto-joins un-awaited spawns ---
    io.println("--- un-awaited spawns joined on scope exit ---")
    let ch = Channel(10)
    async.scope {
        let h1 = async.spawn(fn() {
            ch.send(compute(10))
            0
        })
        let h2 = async.spawn(fn() {
            ch.send(compute(5))
            0
        })
        // deliberately NOT awaiting h1 or h2
    }
    // scope exited, both tasks should have completed
    let v1 = ch.recv()
    let v2 = ch.recv()
    let joined_sum = v1 + v2
    // compute(10) = 45, compute(5) = 10, sum = 55
    if joined_sum == 55 {
        io.println("ok: un-awaited tasks completed, sum = 55")
        pass = pass + 1
    } else {
        io.println("FAIL: expected sum 55, got {joined_sum}")
        fail = fail + 1
    }

    // --- scope auto-joins even with many spawns ---
    io.println("--- many un-awaited spawns ---")
    let ch2 = Channel(20)
    async.scope {
        let a = async.spawn(fn() {
            ch2.send(1)
            0
        })
        let b = async.spawn(fn() {
            ch2.send(2)
            0
        })
        let c = async.spawn(fn() {
            ch2.send(3)
            0
        })
        let d = async.spawn(fn() {
            ch2.send(4)
            0
        })
    }
    ch2.close()
    let mut total = 0
    let mut n = 0
    for v in ch2 {
        total = total + v
        n = n + 1
    }
    if n == 4 {
        io.println("ok: all 4 un-awaited tasks ran")
        pass = pass + 1
    } else {
        io.println("FAIL: expected 4 sends, got {n}")
        fail = fail + 1
    }
    if total == 10 {
        io.println("ok: sum of sends = 10")
        pass = pass + 1
    } else {
        io.println("FAIL: expected sum 10, got {total}")
        fail = fail + 1
    }

    // --- mixed: some awaited, some not ---
    io.println("--- mixed awaited and un-awaited ---")
    let ch3 = Channel(10)
    let awaited_val = async.scope {
        let h_awaited = async.spawn(fn() {
            42
        })
        let h_fire = async.spawn(fn() {
            ch3.send(99)
            0
        })
        h_awaited.await
    }
    // h_fire should have completed due to scope auto-join
    let fire_val = ch3.recv()
    if awaited_val == 42 && fire_val == 99 {
        io.println("ok: awaited=42, fire-and-forget=99")
        pass = pass + 1
    } else {
        io.println("FAIL: expected 42 and 99")
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
