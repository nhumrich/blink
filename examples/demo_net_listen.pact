// demo_net_listen.pact — TCP echo server demo (manual testing)
//
// Run: bin/pact run examples/demo_net_listen.pact
// Then connect: echo "hello" | nc localhost 9876
//
// The server accepts one connection, reads data, echoes it back, and exits.

import std.net

fn main() ! Net.Listen, IO {
    io.println("Starting TCP echo test on port 9876...")
    let listen_result = tcp_listen("0.0.0.0", 9876)
    if listen_result.is_err() {
        io.println("FAIL: listen failed")
        return
    }
    let fd = listen_result.unwrap()
    io.println("PASS: listen returned fd {fd}")
    io.println("Waiting for connection (use: echo hello | nc localhost 9876)")

    let accept_result = tcp_accept(fd)
    if accept_result.is_err() {
        io.println("FAIL: accept failed")
        return
    }
    let conn = accept_result.unwrap()
    io.println("PASS: accepted connection fd {conn}")

    let data = tcp_read(conn, 4096)
    io.println("PASS: read data: \"{data}\"")

    tcp_write(conn, "echo: {data}")
    io.println("PASS: wrote response")

    tcp_close(conn)
    tcp_close(fd)
    io.println("PASS: closed connections")
    io.println("All net_listen tests complete")
}
