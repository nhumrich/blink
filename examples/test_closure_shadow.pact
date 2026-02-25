fn main() ! IO {
    let mut x = 10
    let f = fn(x: Int) -> Int { x + 1 }
    io.println(f(42).to_string())
    io.println(x.to_string())
    x = 20
    io.println(f(99).to_string())
    io.println(x.to_string())
}
