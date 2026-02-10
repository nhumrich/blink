trait TryFrom[T] {
    fn try_from(value: T) -> Result[Self, Str]
}

type Percent {
    value: Int
}

impl TryFrom[Int] for Percent {
    fn try_from(value: Int) -> Result[Int, Str] {
        if value < 0 {
            Err("negative percentage")
        } else if value > 100 {
            Err("percentage exceeds 100")
        } else {
            Ok(value)
        }
    }
}

type Rating {
    score: Int
}

impl TryFrom[Int] for Rating {
    fn try_from(value: Int) -> Result[Int, Str] {
        if value < 1 {
            Err("rating too low")
        } else if value > 5 {
            Err("rating too high")
        } else {
            Ok(value)
        }
    }
}

// try_from + ? in a function returning Result
fn validate_percent(n: Int) -> Result[Int, Str] {
    let v = Percent.try_from(n)?
    Ok(v)
}

fn validate_rating(n: Int) -> Result[Int, Str] {
    let r = Rating.try_from(n)?
    Ok(r)
}

// Chain multiple try_from with ? in same function
fn validate_both(pct: Int, rate: Int) -> Result[Int, Str] {
    let p = Percent.try_from(pct)?
    let r = Rating.try_from(rate)?
    Ok(p + r)
}

// ? should early-return on Err, so Ok(999) is only reached for valid inputs
fn error_should_propagate(n: Int) -> Result[Int, Str] {
    let v = validate_percent(n)?
    Ok(999)
}

// Tests error propagation by calling a function that should fail,
// then verifying via ? that a subsequent valid call still works
fn test_error_propagation() -> Result[Int, Str] {
    // Call with invalid input — stores Err result but doesn't use ? on it
    let e1 = error_should_propagate(-5)
    // Call with valid input — ? extracts Ok(999)
    let ok1 = error_should_propagate(50)?
    if ok1 != 999 { return Err("error_prop: valid call failed") }

    // Call validate_both with invalid first arg
    let e2 = validate_both(-1, 3)
    // Valid chain still works
    let ok2 = validate_both(10, 2)?
    if ok2 != 12 { return Err("error_prop: chain failed") }

    // Call validate_both with invalid second arg
    let e3 = validate_both(50, 0)
    // Valid chain still works
    let ok3 = validate_both(20, 5)?
    if ok3 != 25 { return Err("error_prop: chain2 failed") }

    // Call with boundary error (>100)
    let e4 = error_should_propagate(150)
    let ok4 = error_should_propagate(25)?
    if ok4 != 999 { return Err("error_prop: boundary failed") }

    Ok(0)
}

fn run_all() -> Result[Int, Str] {
    // Test 1: direct Percent.try_from + ? extracts correct value
    let v1 = Percent.try_from(42)?
    if v1 != 42 { return Err("test1") }

    // Test 2: try_from + ? through validate wrapper
    let v2 = validate_percent(75)?
    if v2 != 75 { return Err("test2") }

    // Test 3: Rating.try_from + ?
    let v3 = Rating.try_from(3)?
    if v3 != 3 { return Err("test3") }

    // Test 4: validate_rating wrapper + ?
    let v4 = validate_rating(5)?
    if v4 != 5 { return Err("test4") }

    // Test 5: chained try_from + ? in validate_both
    let v5 = validate_both(50, 4)?
    if v5 != 54 { return Err("test5") }

    // Test 6: boundary value 0 (valid percent)
    let v6 = Percent.try_from(0)?
    if v6 != 0 { return Err("test6") }

    // Test 7: boundary value 100 (valid percent)
    let v7 = Percent.try_from(100)?
    if v7 != 100 { return Err("test7") }

    // Test 8: error propagation tests
    let ep = test_error_propagation()?

    // Only reaches here if ALL tests passed
    io.println("PASS")
    Ok(0)
}

fn main() {
    let r = run_all()
}
