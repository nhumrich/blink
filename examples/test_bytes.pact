fn main() {
    let b = Bytes.new()
    b.push(72)
    b.push(101)
    b.push(108)
    b.push(108)
    b.push(111)

    io.println("len: {b.len()}")
    io.println("get 0: {b.get(0) ?? -1}")
    io.println("get OOB: {b.get(99) ?? -1}")

    match b.to_str() {
        Ok(s) => io.println("to_str: {s}")
        Err(e) => io.println("to_str err: {e}")
    }

    b.set(0, 104)
    match b.to_str() {
        Ok(s) => io.println("after set: {s}")
        Err(e) => io.println("after set err: {e}")
    }

    let sl = b.slice(0, 3)
    io.println("slice len: {sl.len()}")
    match sl.to_str() {
        Ok(s) => io.println("slice: {s}")
        Err(e) => io.println("slice err: {e}")
    }

    let b2 = Bytes.from_str("world")
    match b2.to_str() {
        Ok(s) => io.println("from_str: {s}")
        Err(e) => io.println("from_str err: {e}")
    }
    io.println("from_str len: {b2.len()}")

    let b3 = Bytes()
    b3.push(65)
    match b3.to_str() {
        Ok(s) => io.println("Bytes() constructor: {s}")
        Err(e) => io.println("constructor err: {e}")
    }

    let empty = Bytes.new()
    io.println("is_empty: {empty.is_empty()}")
    io.println("not empty: {b.is_empty()}")

    let joined = b.concat(b2)
    match joined.to_str() {
        Ok(s) => io.println("concat: {s}")
        Err(e) => io.println("concat err: {e}")
    }
    io.println("concat len: {joined.len()}")

    io.println("to_hex: {b.to_hex()}")

    let bad = Bytes.new()
    bad.push(255)
    bad.push(254)
    match bad.to_str() {
        Ok(s) => io.println("should not happen: {s}")
        Err(e) => io.println("bad utf8: {e}")
    }
}
