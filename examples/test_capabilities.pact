@capabilities(IO, FS.Read)

fn greet(name: Str) ! IO {
    io.println("hello {name}")
}

fn check_file(path: Str) ! FS.Read {
    io.println("reading {path}")
}

fn main() {
    greet("world")
    check_file("test.txt")
    io.println("PASS: capabilities test")
}
