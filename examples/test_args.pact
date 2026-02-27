import std.args

test "help text contains flags and options" {
    let mut p = argparser_new("mytool", "A test tool")
    p = add_flag(p, "--verbose", "-v", "Verbose output")
    p = add_option(p, "--output", "-o", "Output file")
    p = add_positional(p, "source", "Source file")

    let help = generate_help(p)
    assert(help.contains("--verbose"))
    assert(help.contains("--output"))
    assert(help.contains("mytool"))
    assert(help.contains("A test tool"))
}

test "help text contains commands" {
    let mut p = argparser_new("cli", "CLI tool")
    p = add_command(p, "build", "Build the project")
    p = add_command(p, "test", "Run tests")
    p = add_flag(p, "--debug", "-d", "Debug mode")
    let help = generate_help(p)
    assert(help.contains("build"))
    assert(help.contains("test"))
}

test "Args struct accessors" {
    let a = Args {
        command_name: "build",
        flag_names: ["verbose", "debug"],
        option_keys: ["output"],
        option_vals: ["foo.txt"],
        positional_vals: ["input.pact"],
        error: ""
    }
    assert(args_has(a, "verbose"))
    assert(args_has(a, "debug"))
    assert(args_has(a, "nonexistent") == false)
    assert_eq(args_get(a, "output"), "foo.txt")
    assert_eq(args_get(a, "missing"), "")
    assert_eq(args_command(a), "build")
    assert_eq(args_positional(a, 0), "input.pact")
    assert_eq(args_positional(a, 5), "")
}
