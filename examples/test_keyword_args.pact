fn add(a: Int, b: Int) -> Int {
    a + b
}

fn transfer(amount: Int, -- from: Str, to: Str) -> Str {
    "{from} sends {amount} to {to}"
}

fn start_server(-- host: Str, port: Int) -> Str {
    "{host}:{port}"
}

fn main() {
    let r1 = add(1, 2)
    assert_eq(r1, 3)
    let r2 = transfer(100, "alice", "bob")
    assert_eq(r2, "alice sends 100 to bob")
    let r4 = start_server("0.0.0.0", 8080)
    assert_eq(r4, "0.0.0.0:8080")
    io.println("All keyword arg tests passed!")
}
