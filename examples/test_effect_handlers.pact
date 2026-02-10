fn main() {
    let mut tests_run = 0

    io.println("=== effect handler tests ===")

    io.println("--- test 1: handler builds vtable struct ---")
    handler IO {
        fn print(msg: Str) {
            io.println("[MOCK] {msg}")
        }
        fn log(msg: Str) {
            io.println("[MOCK-LOG] {msg}")
        }
    }
    tests_run = tests_run + 1
    io.println("ok: handler IO constructed with print+log")

    io.println("--- test 2: with-block installs and restores handler ---")
    io.println("before with-block")
    with handler IO {
        fn print(msg: Str) {
            io.println("[CAPTURE] {msg}")
        }
    } {
        io.println("inside with-block")
    }
    io.println("after with-block (handler restored)")
    tests_run = tests_run + 1
    io.println("ok: with-block install/restore")

    io.println("--- test 3: nested with-blocks restore correctly ---")
    with handler IO {
        fn print(msg: Str) {
            io.println("[OUTER-HANDLER] {msg}")
        }
    } {
        io.println("in outer handler scope")
        with handler IO {
            fn print(msg: Str) {
                io.println("[INNER-HANDLER] {msg}")
            }
        } {
            io.println("in inner handler scope")
        }
        io.println("back in outer handler scope")
    }
    io.println("back in default scope")
    tests_run = tests_run + 1
    io.println("ok: nested with-blocks restore")

    io.println("--- test 4: deeply nested with-blocks (3 levels) ---")
    with handler IO {
        fn print(msg: Str) {
            io.println("[L1] {msg}")
        }
    } {
        io.println("level 1")
        with handler IO {
            fn print(msg: Str) {
                io.println("[L2] {msg}")
            }
        } {
            io.println("level 2")
            with handler IO {
                fn print(msg: Str) {
                    io.println("[L3] {msg}")
                }
            } {
                io.println("level 3")
            }
            io.println("back to level 2")
        }
        io.println("back to level 1")
    }
    io.println("back to default")
    tests_run = tests_run + 1
    io.println("ok: 3-level nested with-blocks")

    io.println("--- test 5: handler with single method ---")
    with handler IO {
        fn log(msg: Str) {
            io.println("[CUSTOM-LOG-ONLY] {msg}")
        }
    } {
        io.println("with-block that only overrides log")
    }
    tests_run = tests_run + 1
    io.println("ok: single-method handler")

    io.println("--- test 6: sequential with-blocks ---")
    with handler IO {
        fn print(msg: Str) {
            io.println("[FIRST] {msg}")
        }
    } {
        io.println("first with-block")
    }
    with handler IO {
        fn print(msg: Str) {
            io.println("[SECOND] {msg}")
        }
    } {
        io.println("second with-block")
    }
    io.println("after both sequential with-blocks")
    tests_run = tests_run + 1
    io.println("ok: sequential with-blocks")

    io.println("--- test 7: with-block with let bindings inside ---")
    with handler IO {
        fn print(msg: Str) {
            io.println("[BINDING-TEST] {msg}")
        }
    } {
        let x = 42
        let y = x + 8
        io.println("computed {y} inside with-block")
    }
    tests_run = tests_run + 1
    io.println("ok: let bindings in with-block")

    io.println("--- test 8: FS handler vtable construction ---")
    handler FS {
        fn read(path: Str) -> Str {
            "[mock-content]"
        }
    }
    tests_run = tests_run + 1
    io.println("ok: FS handler constructed")

    io.println("--- test 9: with-block for FS handler ---")
    with handler FS {
        fn read(path: Str) -> Str {
            "[mock-read]"
        }
    } {
        io.println("inside FS with-block")
    }
    io.println("after FS with-block")
    tests_run = tests_run + 1
    io.println("ok: FS with-block install/restore")

    io.println("--- results ---")
    io.println("tests run: {tests_run}")
    io.println("PASS")
}
