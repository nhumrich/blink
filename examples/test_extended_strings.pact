fn main() {
    // Depth 1: literal quotes
    let json = #"{"key": "value"}"#
    io.println(json)
    assert(json == "\{\"key\": \"value\"\}", "json should contain literal quotes")

    // Depth 1: no escape processing (raw backslash)
    let path = #"C:\Users\test"#
    io.println(path)
    assert(path == "C:\\Users\\test", "path should have literal backslashes")

    // Depth 1: with interpolation
    let name = "Alice"
    let greeting = #"Hello, #{name}!"#
    io.println(greeting)
    assert(greeting == "Hello, Alice!", "greeting should interpolate name")

    // Depth 1: literal { without interpolation
    let braces = #"use { for blocks"#
    io.println(braces)
    assert(braces == "use \{ for blocks", "braces should be literal")

    // Depth 2: literal #" inside
    let meta = ##"she said #"hi"#"##
    io.println(meta)
    assert(meta == "she said #\"hi\"#", "meta should contain #quotes#")

    io.println("All extended string tests passed!")
}
