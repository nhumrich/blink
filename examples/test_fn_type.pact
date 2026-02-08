fn apply(f: fn(Int) -> Int, x: Int) -> Int {
    f(x)
}

fn main() {
    let add_one = fn(x: Int) -> Int { x + 1 }

    let result1 = apply(add_one, 5)
    io.println("{result1}")

    let result2 = apply(fn(x: Int) -> Int { x * 3 }, 4)
    io.println("{result2}")

    io.println("PASS")
}
