// Negative test: verifies the compiler rejects undefined names
// Writes a bad .pact file, compiles it with --format json, checks output

fn main() {
    let bad_source = "fn main() {\n    let x = undefined_function(42)\n    io.println(unknown_var)\n}\n"
    write_file("build/_test_nr_bad.pact", bad_source)

    let output = shell_exec("build/pactc build/_test_nr_bad.pact /dev/null --format json 2>&1")

    let mut pass = 1
    if !output.contains("UndefinedFunction") {
        io.println("FAIL: expected UndefinedFunction diagnostic")
        pass = 0
    }
    if !output.contains("UndefinedVariable") {
        io.println("FAIL: expected UndefinedVariable diagnostic")
        pass = 0
    }
    if !output.contains("E0303") {
        io.println("FAIL: expected error code E0303")
        pass = 0
    }
    if !output.contains("E0302") {
        io.println("FAIL: expected error code E0302")
        pass = 0
    }
    if pass {
        io.println("PASS: name resolution rejects undefined names with structured diagnostics")
    }
}
