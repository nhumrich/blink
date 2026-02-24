type Coord {
    x: Int
    y: Int
}

type MathError {
    DivByZero
    Overflow(msg: Str)
}

fn make_coord(x: Int, y: Int) -> Result[Coord, MathError] {
    if x == 0 && y == 0 {
        Err(MathError.DivByZero)
    } else {
        Ok(Coord { x: x, y: y })
    }
}

fn use_coord() -> Result[Int, MathError] {
    let c = make_coord(3, 4)?
    Ok(c.x + c.y)
}

fn maybe_coord(x: Int) -> Option[Coord] {
    if x > 0 {
        Some(Coord { x: x, y: x * 2 })
    } else {
        None
    }
}

fn main() ! IO {
    let r = use_coord()
    match r {
        Ok(val) => io.println("use_coord ok: {val}")
        Err(_) => io.println("use_coord err")
    }

    let r2 = make_coord(3, 4)
    match r2 {
        Ok(c) => io.println("coord: {c.x}, {c.y}")
        Err(_) => io.println("err")
    }

    let r3 = make_coord(0, 0)
    match r3 {
        Ok(_) => io.println("should not reach")
        Err(e) => {
            match e {
                DivByZero => io.println("got DivByZero")
                Overflow(msg) => io.println("overflow: {msg}")
            }
        }
    }

    let opt = maybe_coord(5)
    let fallback = Coord { x: 0, y: 0 }
    let c2 = opt ?? fallback
    io.println("option coord: {c2.x}, {c2.y}")

    let opt2 = maybe_coord(-1)
    let c3 = opt2 ?? Coord { x: 99, y: 99 }
    io.println("default coord: {c3.x}, {c3.y}")

    io.println("all tests passed")
}
