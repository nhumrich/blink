fn pure_add(a: Int, b: Int) -> Int {
    a + b
}

fn log_msg(msg: Str) ! IO {
    io.println(msg)
}

fn read_only(path: Str) ! FS.Read {
    io.println("reading {path}")
}

fn process(a: Int) ! IO, DB.Read {
    io.println("processing {a}")
}

fn needs_db_read() ! DB.Read {
    io.println("db read")
}

fn has_full_db() ! DB {
    needs_db_read()
}

fn needs_io_print() ! IO.Print {
    io.println("just print")
}

fn has_full_io() ! IO {
    needs_io_print()
}

fn multi_effect() ! IO, FS, DB {
    io.println("multi")
    needs_db_read()
    read_only("multi.txt")
}

fn test_io_print() ! IO {
    io.print("no newline ")
    io.print("here")
    io.println("")
}

fn test_io_log() ! IO {
    io.log("this goes to stderr")
}

fn test_fs_read() ! FS.Read {
    let content = fs.read("examples/test_effects.pact")
    let first_two = content.substring(0, 2)
    io.println("fs.read first 2 chars: {first_two}")
}

fn test_fs_write() ! FS.Write {
    fs.write("build/test_effects_tmp.txt", "hello from pact")
    let check = fs.read("build/test_effects_tmp.txt")
    io.println("fs.write roundtrip: {check}")
}

fn main() {
    let r = pure_add(1, 2)
    io.println("pure_add: {r}")
    log_msg("hello from log_msg")
    read_only("test.txt")
    process(42)
    has_full_db()
    has_full_io()
    needs_io_print()
    multi_effect()
    test_io_print()
    test_io_log()
    test_fs_read()
    test_fs_write()
    io.println("PASS: all effect tests passed")
}
