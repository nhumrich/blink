fn main() {
    // Test 1: basic send/recv
    let ch = Channel(10)
    ch.send(42)
    let val = ch.recv()
    if val == 42 {
        io.println("PASS: basic send/recv")
    } else {
        io.println("FAIL: basic send/recv")
    }

    // Test 2: multiple send/recv (FIFO order)
    ch.send(1)
    ch.send(2)
    ch.send(3)
    let a = ch.recv()
    let b = ch.recv()
    let c = ch.recv()
    if a == 1 && b == 2 && c == 3 {
        io.println("PASS: FIFO order")
    } else {
        io.println("FAIL: FIFO order")
    }

    // Test 3: close channel
    ch.close()
    io.println("PASS: close channel")

    // Test 4: channel with async.spawn (producer/consumer)
    let ch2 = Channel(10)
    let h = async.spawn(fn() {
        ch2.send(100)
        ch2.send(200)
        ch2.close()
        0
    })
    let v1 = ch2.recv()
    let v2 = ch2.recv()
    h.await
    if v1 == 100 && v2 == 200 {
        io.println("PASS: async producer/consumer")
    } else {
        io.println("FAIL: async producer/consumer")
    }

    // Test 5: for-in on channel
    let ch3 = Channel(10)
    ch3.send(10)
    ch3.send(20)
    ch3.send(30)
    ch3.close()
    let mut sum = 0
    for val in ch3 {
        sum = sum + val
    }
    if sum == 60 {
        io.println("PASS: for-in on channel")
    } else {
        io.println("FAIL: for-in on channel")
    }

    io.println("All channel tests complete")
}
