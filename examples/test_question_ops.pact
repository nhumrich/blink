fn divide(a: Int, b: Int) -> Result[Int, Str] {
    if b == 0 {
        Err("division by zero")
    } else {
        Ok(a / b)
    }
}

fn try_divide(a: Int, b: Int) -> Result[Int, Str] {
    let result = divide(a, b)?
    Ok(result * 2)
}

fn find_value(x: Int) -> Int? {
    if x > 0 {
        Some(x * 10)
    } else {
        None
    }
}

fn main() {
    // Test ? operator
    let ok_result = try_divide(10, 2)
    io.println("try_divide(10, 2) ok")

    // Test ?? operator
    let x = Some(42)
    let y = None
    let val1 = x ?? 0
    let val2 = y ?? 99
    io.println("{val1}")
    io.println("{val2}")

    // Test T? syntax sugar
    let found = find_value(5)
    let not_found = find_value(-1)
    let v1 = found ?? 0
    let v2 = not_found ?? 0
    io.println("{v1}")
    io.println("{v2}")

    io.println("PASS")
}
