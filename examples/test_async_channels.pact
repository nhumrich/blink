fn main() {
    io.println("=== async channels (producer-consumer) tests ===")
    let mut pass = 0
    let mut fail = 0

    // --- producer sends N values, consumer iterates ---
    io.println("--- producer-consumer with for-in ---")
    let ch = Channel(20)
    let producer = async.spawn(fn() {
        let mut i = 1
        while i <= 10 {
            ch.send(i)
            i = i + 1
        }
        ch.close()
        0
    })
    let mut count = 0
    let mut sum = 0
    for val in ch {
        count = count + 1
        sum = sum + val
    }
    producer.await
    if count == 10 {
        io.println("ok: received 10 values")
        pass = pass + 1
    } else {
        io.println("FAIL: expected 10 values, got {count}")
        fail = fail + 1
    }
    if sum == 55 {
        io.println("ok: sum of 1..10 = 55")
        pass = pass + 1
    } else {
        io.println("FAIL: expected sum 55, got {sum}")
        fail = fail + 1
    }

    // --- multiple producers, single consumer ---
    io.println("--- two producers, one consumer ---")
    let ch2 = Channel(20)
    let p1 = async.spawn(fn() {
        ch2.send(100)
        ch2.send(200)
        0
    })
    let p2 = async.spawn(fn() {
        ch2.send(300)
        ch2.send(400)
        0
    })
    p1.await
    p2.await
    ch2.close()
    let mut sum2 = 0
    let mut count2 = 0
    for v in ch2 {
        sum2 = sum2 + v
        count2 = count2 + 1
    }
    if count2 == 4 {
        io.println("ok: received 4 values from two producers")
        pass = pass + 1
    } else {
        io.println("FAIL: expected 4 values, got {count2}")
        fail = fail + 1
    }
    if sum2 == 1000 {
        io.println("ok: sum from two producers = 1000")
        pass = pass + 1
    } else {
        io.println("FAIL: expected sum 1000, got {sum2}")
        fail = fail + 1
    }

    // --- producer in scope, consumer after ---
    io.println("--- scoped producer ---")
    let ch3 = Channel(10)
    async.scope {
        let p = async.spawn(fn() {
            ch3.send(11)
            ch3.send(22)
            ch3.send(33)
            ch3.close()
            0
        })
    }
    let mut sum3 = 0
    for v in ch3 {
        sum3 = sum3 + v
    }
    if sum3 == 66 {
        io.println("ok: scoped producer sum = 66")
        pass = pass + 1
    } else {
        io.println("FAIL: scoped producer expected 66, got {sum3}")
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
