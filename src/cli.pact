fn print_usage() {
    io.println("Usage: pact <command> [options] <file>")
    io.println("")
    io.println("Commands:")
    io.println("  build <file>    Compile .pact to native binary")
    io.println("  run <file>      Build and execute")
    io.println("  test [<file>]   Build and run tests (discovers .pact files with test blocks)")
    io.println("  check <file>    Validate without producing binary")
    io.println("  fmt [<file>]    Format source file(s) in place")
    io.println("")
    io.println("Options:")
    io.println("  --output <path>   Output path (default: build/<name>)")
    io.println("  --format json     Machine-readable JSON diagnostic output")
    io.println("")
    io.println("Test options:")
    io.println("  --filter <pat>    Run only tests matching pattern")
    io.println("  --json            Output test results as JSON")
    io.println("  --tags <tag>      Run only tests with matching tag")
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

fn has_test_blocks(source: Str) -> Int {
    if source.starts_with("test \"") || source.contains("\ntest \"") {
        return 1
    }
    return 0
}

fn collect_test_files(dir: Str, results: List[Str]) {
    let entries = fs.list_dir(dir)
    let mut i = 0
    while i < entries.len() {
        let entry = entries.get(i)
        if entry.starts_with(".") || entry == "build" || entry == "legacy" || entry == "node_modules" {
            i = i + 1
            continue
        }
        let full_path = path_join(dir, entry)
        if is_dir(full_path) {
            collect_test_files(full_path, results)
        } else if entry.ends_with(".pact") {
            let source = read_file(full_path)
            if has_test_blocks(source) {
                results.push(full_path)
            }
        }
        i = i + 1
    }
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

    let cc_cmd = "cc -o {output_path} {c_path} -Ibuild {link_flags}"
    let cc_rc = shell_exec(cc_cmd)
    if cc_rc != 0 {
        io.println("error: C compilation failed")
        return cc_rc
    }

    return 0
}

fn main() {
    if arg_count() < 2 {
        print_usage()
        return
    }

    let command = get_arg(1)
    let mut source_path = ""
    let mut output_path = ""
    let mut format_flag = ""
    let mut filter_pattern = ""
    let mut json_output = 0
    let mut tags_filter = ""
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
        } else if arg == "--filter" {
            if i + 1 < arg_count() {
                i = i + 1
                filter_pattern = get_arg(i)
            } else {
                io.println("error: --filter requires a pattern")
                return
            }
        } else if arg == "--json" {
            json_output = 1
        } else if arg == "--tags" {
            if i + 1 < arg_count() {
                i = i + 1
                tags_filter = get_arg(i)
            } else {
                io.println("error: --tags requires a value")
                return
            }
        } else {
            source_path = arg
        }
        i = i + 1
    }

    if source_path == "" && command != "fmt" && command != "test" {
        io.println("error: no source file specified")
        print_usage()
        return
    }

    if source_path != "" && !file_exists(source_path) {
        io.println("error: file not found: {source_path}")
        return
    }

    let mut basename = ""
    let mut name = ""
    let mut c_path = ""
    if source_path != "" {
        basename = path_basename(source_path)
        name = strip_extension(basename)
        c_path = "build/{name}.c"
    }

    shell_exec("mkdir -p build")

    if output_path == "" && name != "" {
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
        let run_rc = shell_exec(output_path)
        exit(run_rc)
    } else if command == "test" {
        if source_path != "" {
            let rc = do_build(source_path, output_path, c_path, format_flag)
            if rc != 0 {
                return
            }
            let mut run_cmd = output_path
            if filter_pattern != "" {
                run_cmd = "{run_cmd} --test-filter \"{filter_pattern}\""
            }
            if json_output != 0 {
                run_cmd = "{run_cmd} --test-json"
            }
            if tags_filter != "" {
                run_cmd = "{run_cmd} --test-tags \"{tags_filter}\""
            }
            let test_rc = shell_exec(run_cmd)
            exit(test_rc)
        }

        let mut test_files: List[Str] = []
        collect_test_files(".", test_files)

        let mut total_passed = 0
        let mut total_failed = 0
        let mut total_errors = 0
        let file_count = test_files.len()
        let mut json_first = 1
        let mut fi = 0

        if json_output != 0 {
            io.println("\{\"files\":[")
        }

        while fi < file_count {
            let tf = test_files.get(fi)
            let tf_dir = path_dirname(tf)
            let tf_base = strip_extension(path_basename(tf))
            let mut build_dir = "build"
            if tf_dir != "." && tf_dir != "" {
                build_dir = "build/{tf_dir}"
            }
            shell_exec("mkdir -p {build_dir}")
            let tf_c = "{build_dir}/{tf_base}.c"
            let tf_out = "{build_dir}/{tf_base}"

            let build_rc = do_build(tf, tf_out, tf_c, format_flag)
            if build_rc != 0 {
                total_errors = total_errors + 1
                if json_output != 0 {
                    if json_first == 0 {
                        io.println(",")
                    }
                    json_first = 0
                    io.println("\{\"file\":\"{tf}\",\"error\":\"build failed\"}")
                } else {
                    io.println("--- {tf} ---")
                    io.println("  BUILD FAILED")
                    io.println("")
                }
                fi = fi + 1
                continue
            }

            let source = read_file(tf)
            let mut run_cmd = tf_out
            if source.contains("fn main(") {
                run_cmd = "{run_cmd} --test"
            }
            if filter_pattern != "" {
                run_cmd = "{run_cmd} --test-filter \"{filter_pattern}\""
            }
            if json_output != 0 {
                run_cmd = "{run_cmd} --test-json"
            }
            if tags_filter != "" {
                run_cmd = "{run_cmd} --test-tags \"{tags_filter}\""
            }

            if json_output == 0 {
                io.println("--- {tf} ---")
            } else {
                if json_first == 0 {
                    io.println(",")
                }
                json_first = 0
                io.println("\{\"file\":\"{tf}\",\"results\":")
            }

            let test_rc = shell_exec(run_cmd)

            if json_output != 0 {
                io.println("}")
            }

            if test_rc != 0 {
                total_failed = total_failed + 1
            } else {
                total_passed = total_passed + 1
            }

            fi = fi + 1
        }

        if file_count == 0 {
            if json_output != 0 {
                io.println("],\"summary\":\{\"files\":0,\"files_passed\":0,\"files_failed\":0,\"build_errors\":0}}")
            } else {
                io.println("error: no files with test blocks found")
            }
            exit(1)
        }

        if json_output != 0 {
            io.println("],\"summary\":\{\"files\":{file_count},\"files_passed\":{total_passed},\"files_failed\":{total_failed},\"build_errors\":{total_errors}}}")
        } else {
            io.println("========================================")
            io.println("{file_count} test files: {total_passed} passed, {total_failed} failed, {total_errors} build errors")
        }

        if total_failed > 0 || total_errors > 0 {
            exit(1)
        }
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
    } else if command == "fmt" {
        let pactc = "build/pactc"
        if !file_exists(pactc) {
            io.println("error: compiler not found at build/pactc")
            io.println("  run: ./bootstrap/bootstrap.sh")
            return
        }
        if source_path == "" {
            let files = fs.list_dir(".")
            let mut fi = 0
            while fi < files.len() {
                let fname = files.get(fi)
                if fname.ends_with(".pact") {
                    let fmt_cmd = "{pactc} {fname} {fname} --emit pact"
                    let rc = shell_exec(fmt_cmd)
                    if rc == 0 {
                        io.println("formatted: {fname}")
                    } else {
                        io.println("error: formatting failed for {fname}")
                    }
                }
                fi = fi + 1
            }
        } else {
            let compile_cmd = "{pactc} {source_path} {source_path} --emit pact"
            let rc = shell_exec(compile_cmd)
            if rc == 0 {
                io.println("formatted: {source_path}")
            } else {
                io.println("error: formatting failed")
            }
        }
    } else {
        io.println("error: unknown command '{command}'")
        print_usage()
    }
}
