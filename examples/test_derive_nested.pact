@derive(Serialize)
type Address {
    city: Str
    zip: Str
}

@derive(Serialize)
type Person {
    name: Str
    address: Address
    tags: List[Str]
}

fn main() {
    let mut pass = true

    let a = Address { city: "NYC", zip: "10001" }
    let p = Person {
        name: "Bob",
        address: a,
        tags: ["dev", "pact"]
    }
    let json = p.to_json()
    let expected = "\{\"name\":\"Bob\",\"address\":\{\"city\":\"NYC\",\"zip\":\"10001\"},\"tags\":[\"dev\",\"pact\"]}"
    if json != expected {
        io.println("FAIL: nested -- got {json}")
        pass = false
    }

    if pass {
        io.println("PASS")
    }
}
