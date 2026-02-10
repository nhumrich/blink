fn main() {
    io.println("=== handler expression test ===")

    io.println("--- basic handler construction ---")
    handler IO {
        fn print(msg: Str) {
            io.println("[CUSTOM] {msg}")
        }
        fn log(msg: Str) {
            io.println("[CUSTOM-LOG] {msg}")
        }
    }
    io.println("handler vtable built")

    io.println("--- handler in with block ---")
    with handler IO {
        fn print(msg: Str) {
            io.println("[WITH-PRINT] {msg}")
        }
    } {
        io.println("inside with-handler block")
    }

    io.println("PASS: handler expression test")
}
