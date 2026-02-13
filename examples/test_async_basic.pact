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
    io.println("=== async basic (fork-join) tests ===")
    let mut pass = 0
    let mut fail = 0

    // --- fork-join: spawn 2 tasks, await both ---
    io.println("--- fork-join: two tasks ---")
    async.scope {
        let h1 = async.spawn(fn() {
            compute(100)
        })
        let h2 = async.spawn(fn() {
            compute(50)
        })
        let r1 = h1.await
        let r2 = h2.await
        if r1 == 4950 && r2 == 1225 {
            io.println("ok: two-task fork-join correct (4950 + 1225)")
            pass = pass + 1
        } else {
            io.println("FAIL: two-task fork-join expected 4950 and 1225")
            fail = fail + 1
        }
    }

    // --- fork-join: spawn 3 tasks, combine results ---
    io.println("--- fork-join: three tasks combined ---")
    let total = async.scope {
        let ha = async.spawn(fn() {
            10 + 20
        })
        let hb = async.spawn(fn() {
            30 + 40
        })
        let hc = async.spawn(fn() {
            50 + 60
        })
        let ra = ha.await
        let rb = hb.await
        let rc = hc.await
        ra + rb + rc
    }
    if total == 210 {
        io.println("ok: three-task combined result = 210")
        pass = pass + 1
    } else {
        io.println("FAIL: three-task combined expected 210, got {total}")
        fail = fail + 1
    }

    // --- fork-join: scope returns computed value ---
    io.println("--- scope returns value ---")
    let scoped = async.scope {
        let hv = async.spawn(fn() {
            7 * 6
        })
        hv.await
    }
    if scoped == 42 {
        io.println("ok: scope returned awaited value 42")
        pass = pass + 1
    } else {
        io.println("FAIL: scope return expected 42, got {scoped}")
        fail = fail + 1
    }

    // --- fork-join: tasks with captures ---
    io.println("--- fork-join with captures ---")
    let base = 1000
    let offset = 337
    async.scope {
        let hx = async.spawn(fn() {
            base + offset
        })
        let hy = async.spawn(fn() {
            base - offset
        })
        let rx = hx.await
        let ry = hy.await
        if rx == 1337 && ry == 663 {
            io.println("ok: fork-join with captures (1337, 663)")
            pass = pass + 1
        } else {
            io.println("FAIL: fork-join captures expected 1337 and 663")
            fail = fail + 1
        }
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
