type Color { Red, Green, Blue }

type Result2 {
    Success(value: Int)
    Error(message: Str)
}

fn show_result(r: Result2) -> Str {
    match r {
        Result2.Success(v) => "success: {v}"
        Result2.Error(msg) => "error: {msg}"
    }
}

fn main() {
    // Mixed: simple enum still works
    let c = Color.Red
    let color_name = match c {
        Color.Red => "red"
        Color.Green => "green"
        Color.Blue => "blue"
    }
    io.println(color_name)

    // Data enum
    let ok = Result2.Success(42)
    let err = Result2.Error("not found")
    io.println(show_result(ok))
    io.println(show_result(err))
}
