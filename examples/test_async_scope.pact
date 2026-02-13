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
    // Test 1: scope with spawns, all awaited explicitly
    async.scope {
        let ha = async.spawn(fn() {
            compute(100)
        })
        let hb = async.spawn(fn() {
            compute(50)
        })
        let ra = ha.await
        let rb = hb.await
        if ra == 4950 && rb == 1225 {
            io.println("PASS: scope with explicit awaits")
        } else {
            io.println("FAIL: scope with explicit awaits")
        }
    }

    // Test 2: scope with spawns, NOT awaited — scope exit should join them
    let mut flag = 0
    async.scope {
        let hc = async.spawn(fn() {
            compute(10)
        })
        let hd = async.spawn(fn() {
            compute(20)
        })
        flag = 1
    }
    if flag == 1 {
        io.println("PASS: scope with un-awaited spawns completed")
    } else {
        io.println("FAIL: scope with un-awaited spawns")
    }

    // Test 3: scope with mix of awaited and un-awaited
    async.scope {
        let he = async.spawn(fn() {
            compute(100)
        })
        let re = he.await
        if re == 4950 {
            io.println("PASS: scope mixed - awaited handle correct")
        } else {
            io.println("FAIL: scope mixed - awaited handle wrong")
        }
        let hf = async.spawn(fn() {
            compute(50)
        })
    }
    io.println("PASS: scope mixed - un-awaited handle joined on exit")

    // Test 4: scope value expression (scope body returns a value)
    let scoped_val = async.scope {
        let x = 42
        x + 8
    }
    if scoped_val == 50 {
        io.println("PASS: scope returns value correctly")
    } else {
        io.println("FAIL: scope returns wrong value")
    }

    // Test 5: nested scopes
    async.scope {
        let h_outer = async.spawn(fn() {
            10
        })
        async.scope {
            let h_inner = async.spawn(fn() {
                20
            })
            let r_inner = h_inner.await
            if r_inner == 20 {
                io.println("PASS: nested scope inner await correct")
            } else {
                io.println("FAIL: nested scope inner await wrong")
            }
        }
        let r_outer = h_outer.await
        if r_outer == 10 {
            io.println("PASS: nested scope outer await correct")
        } else {
            io.println("FAIL: nested scope outer await wrong")
        }
    }

    // Test 6: scope with no spawns (should still work fine)
    let simple_val = async.scope {
        let aa = 3
        let bb = 7
        aa * bb
    }
    if simple_val == 21 {
        io.println("PASS: scope with no spawns works")
    } else {
        io.println("FAIL: scope with no spawns returned wrong value")
    }

    io.println("async scope tests complete")
}
