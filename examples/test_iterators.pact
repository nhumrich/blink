fn main() {
    io.println("=== iterator protocol tests ===")

    io.println("--- test 1: for-in over exclusive range ---")
    let mut sum1 = 0
    for x in 1..5 {
        sum1 = sum1 + x
    }
    if sum1 == 10 {
        io.println("ok: 1..5 sum = 10")
    } else {
        io.println("FAIL: 1..5 sum = {sum1}, expected 10")
    }

    io.println("--- test 2: for-in over inclusive range ---")
    let mut sum2 = 0
    for x in 1..=5 {
        sum2 = sum2 + x
    }
    if sum2 == 15 {
        io.println("ok: 1..=5 sum = 15")
    } else {
        io.println("FAIL: 1..=5 sum = {sum2}, expected 15")
    }

    io.println("--- test 3: for-in over List[Int] ---")
    let mut items: List[Int] = []
    items.push(10)
    items.push(20)
    items.push(30)
    let mut sum3 = 0
    for x in items {
        sum3 = sum3 + x
    }
    if sum3 == 60 {
        io.println("ok: list sum = 60")
    } else {
        io.println("FAIL: list sum = {sum3}, expected 60")
    }

    io.println("--- test 4: empty range ---")
    let mut count4 = 0
    for x in 5..5 {
        count4 = count4 + 1
    }
    if count4 == 0 {
        io.println("ok: empty range iterated 0 times")
    } else {
        io.println("FAIL: empty range iterated {count4} times")
    }

    io.println("--- test 5: inclusive range with single element ---")
    let mut count5 = 0
    let mut val5 = 0
    for x in 3..=3 {
        count5 = count5 + 1
        val5 = x
    }
    if count5 == 1 && val5 == 3 {
        io.println("ok: 3..=3 iterated once with value 3")
    } else {
        io.println("FAIL: count={count5}, val={val5}")
    }

    io.println("--- test 6: nested for-in loops ---")
    let mut sum6 = 0
    for i in 1..=3 {
        for j in 1..=3 {
            sum6 = sum6 + i * j
        }
    }
    if sum6 == 36 {
        io.println("ok: nested loop sum = 36")
    } else {
        io.println("FAIL: nested loop sum = {sum6}, expected 36")
    }

    io.println("--- test 7: for-in over empty list ---")
    let mut empty_list: List[Int] = []
    let mut count7 = 0
    for x in empty_list {
        count7 = count7 + 1
    }
    if count7 == 0 {
        io.println("ok: empty list iterated 0 times")
    } else {
        io.println("FAIL: empty list iterated {count7} times")
    }

    io.println("--- results ---")
    io.println("PASS")
}
