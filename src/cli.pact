fn print_usage() {
    io.println("Usage: pact <command> [options] <file>")
    io.println("")
    io.println("Commands:")
    io.println("  build <file>    Compile .pact to native binary")
    io.println("  run <file>      Build and execute")
    io.println("  check <file>    Validate without producing binary")
    io.println("")
    io.println("Options:")
    io.println("  --output <path>   Output path (default: build/<name>)")
    io.println("  --format json     Machine-readable JSON diagnostic output")
}

fn strip_extension(filename: Str) -> Str {
    if filename.ends_with(".pact") {
        return filename.substring(0, filename.len() - 5)
    }
    return filename
}

fn detect_async(source: Str) -> Int {
    if source.contains("async.spawn") || source.contains("async.scope") {
        return 1
    }
    return 0
}

fn do_build(source_path: Str, output_path: Str, c_path: Str, format_flag: Str) -> Int {
    let pactc = "build/pactc"
    if !file_exists(pactc) {
        io.println("error: compiler not found at build/pactc")
        io.println("  run: ./bootstrap/bootstrap.sh")
        return 1
    }

    let mut compile_cmd = "{pactc} {source_path} {c_path}"
    if format_flag != "" {
        compile_cmd = "{pactc} {source_path} {c_path} --format {format_flag}"
    }
    let rc = shell_exec(compile_cmd)
    if rc != 0 {
        io.println("error: compilation failed")
        return rc
    }

    let source = read_file(source_path)
    let mut link_flags = "-lm"
    if detect_async(source) {
        link_flags = "-lm -pthread"
    }

    let cc_cmd = "cc -o {output_path} {c_path} {link_flags}"
    let cc_rc = shell_exec(cc_cmd)
    if cc_rc != 0 {
        io.println("error: C compilation failed")
        return cc_rc
    }

    return 0
}

fn main() {
    if arg_count() < 3 {
        print_usage()
        return
    }

    let command = get_arg(1)
    let mut source_path = ""
    let mut output_path = ""
    let mut format_flag = ""
    let mut i = 2

    while i < arg_count() {
        let arg = get_arg(i)
        if arg == "--output" {
            if i + 1 < arg_count() {
                i = i + 1
                output_path = get_arg(i)
            } else {
                io.println("error: --output requires a path")
                return
            }
        } else if arg == "--format" {
            if i + 1 < arg_count() {
                i = i + 1
                format_flag = get_arg(i)
            } else {
                io.println("error: --format requires a value")
                return
            }
        } else {
            source_path = arg
        }
        i = i + 1
    }

    if source_path == "" {
        io.println("error: no source file specified")
        print_usage()
        return
    }

    if !file_exists(source_path) {
        io.println("error: file not found: {source_path}")
        return
    }

    let basename = path_basename(source_path)
    let name = strip_extension(basename)

    shell_exec("mkdir -p build")

    let c_path = "build/{name}.c"

    if output_path == "" {
        output_path = "build/{name}"
    }

    if command == "build" {
        let rc = do_build(source_path, output_path, c_path, format_flag)
        if rc == 0 {
            io.println("built: {output_path}")
        }
    } else if command == "run" {
        let rc = do_build(source_path, output_path, c_path, format_flag)
        if rc != 0 {
            return
        }
        shell_exec(output_path)
    } else if command == "check" {
        let pactc = "build/pactc"
        if !file_exists(pactc) {
            io.println("error: compiler not found at build/pactc")
            io.println("  run: ./bootstrap/bootstrap.sh")
            return
        }
        let mut compile_cmd = "{pactc} {source_path} {c_path}"
        if format_flag != "" {
            compile_cmd = "{pactc} {source_path} {c_path} --format {format_flag}"
        }
        let rc = shell_exec(compile_cmd)
        if rc == 0 {
            io.println("ok: {source_path}")
        } else {
            io.println("error: check failed")
        }
    } else {
        io.println("error: unknown command '{command}'")
        print_usage()
    }
}
