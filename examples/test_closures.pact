fn main() {
    let add = fn(a: Int, b: Int) -> Int { a + b }
    let result = add(1, 2)
    io.println("{result}")

    let mul = fn(x: Int, y: Int) -> Int { x * y }
    io.println("{mul(6, 7)}")

    let greet = fn(name: Str) -> Str { "hello {name}" }
    let msg = greet("pact")
    io.println(msg)

    let is_even = fn(n: Int) -> Bool { n % 2 == 0 }
    if is_even(4) {
        io.println("4 is even")
    }
    if is_even(3) == false {
        io.println("3 is odd")
    }

    let identity = fn(s: Str) -> Str { s }
    io.println(identity("echo"))

    io.println("PASS")
}
