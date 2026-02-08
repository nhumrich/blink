// test_generics.pact — Integration tests for generic types and functions

type Pair[A, B] {
    first: A
    second: B
}

type Box[T] {
    value: T
}

fn identity[T](x: T) -> T {
    x
}

fn first_of[T](a: T, b: T) -> T {
    a
}

fn max_val[T](a: T, b: T) -> T {
    if a > b { a } else { b }
}

fn main() {
    // Test 1: Generic struct with Int fields
    let p1 = Pair { first: 10, second: 20 }
    io.println(p1.first)
    io.println(p1.second)

    // Test 2: Generic struct with Str fields
    let p2 = Pair { first: "hello", second: "world" }
    io.println(p2.first)
    io.println(p2.second)

    // Test 3: Mixed types — Pair[Int, Str]
    let p3 = Pair { first: 42, second: "answer" }
    io.println(p3.first)
    io.println(p3.second)

    // Test 4: Mixed types — Pair[Str, Int] (reversed)
    let p4 = Pair { first: "count", second: 99 }
    io.println(p4.first)
    io.println(p4.second)

    // Test 5: Single type param struct — Box[Int]
    let b1 = Box { value: 777 }
    io.println(b1.value)

    // Test 6: Single type param struct — Box[Str]
    let b2 = Box { value: "boxed" }
    io.println(b2.value)

    // Test 7: Generic function — identity with Int
    let id_int = identity(123)
    io.println(id_int)

    // Test 8: Generic function — identity with Str
    let id_str = identity("hello identity")
    io.println(id_str)

    // Test 9: Generic function — first_of with Int
    let f1 = first_of(10, 20)
    io.println(f1)

    // Test 10: Generic function — max_val with Int
    let m1 = max_val(3, 7)
    io.println(m1)
    let m2 = max_val(100, 42)
    io.println(m2)

    // Test 11: Field access in string interpolation
    let p5 = Pair { first: 1, second: 2 }
    io.println("Pair: {p5.first}, {p5.second}")

    // Test 12: Multiple monomorphizations of same generic struct
    let box_a = Box { value: 1 }
    let box_b = Box { value: "two" }
    io.println("box_a={box_a.value} box_b={box_b.value}")

    io.println("ALL TESTS PASSED")
}
