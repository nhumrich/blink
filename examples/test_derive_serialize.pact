@derive(Serialize)
type User {
    name: Str
    age: Int
    score: Float
    active: Bool
}

fn main() {
    let mut pass = true

    let u = User { name: "Alice", age: 30, score: 9.5, active: true }
    let json = u.to_json()
    let expected = "\{\"name\":\"Alice\",\"age\":30,\"score\":9.5,\"active\":true}"
    if json != expected {
        io.println("FAIL: struct serialize -- got {json}")
        pass = false
    }

    if pass {
        io.println("PASS")
    }
}
