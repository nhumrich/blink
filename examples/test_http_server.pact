import std.http_types

fn check_int(actual: Int, expected: Int, label: Str) {
    if actual == expected {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label} — expected {expected}, got {actual}")
    }
}

fn check_str(actual: Str, expected: Str, label: Str) {
    if actual == expected {
        io.println("PASS: {label}")
    } else {
        io.println("FAIL: {label} — expected \"{expected}\", got \"{actual}\"")
    }
}

// ── Server storage (mirrors http_server.pact) ─────────────────────
let mut server_hosts: List[Str] = []
let mut server_ports: List[Int] = []
let mut route_methods: List[Str] = []
let mut route_patterns: List[Str] = []
let mut route_handlers: List[Int] = []
let mut route_server_owners: List[Int] = []

fn server_new(host: Str, port: Int) -> Int {
    let idx = server_hosts.len()
    server_hosts.push(host)
    server_ports.push(port)
    idx
}

fn server_host(idx: Int) -> Str {
    server_hosts.get(idx)
}

fn server_port(idx: Int) -> Int {
    server_ports.get(idx)
}

fn server_route(srv: Int, method: Str, pattern: Str, handler_fn: Int) {
    route_methods.push(method)
    route_patterns.push(pattern)
    route_handlers.push(handler_fn)
    route_server_owners.push(srv)
}

fn route_handler_fn(idx: Int) -> Int {
    route_handlers.get(idx)
}

fn route_count(srv: Int) -> Int {
    let mut count = 0
    let mut i = 0
    while i < route_server_owners.len() {
        if route_server_owners.get(i) == srv {
            count = count + 1
        }
        i = i + 1
    }
    count
}

fn server_clear() {
    server_hosts = []
    server_ports = []
    route_methods = []
    route_patterns = []
    route_handlers = []
    route_server_owners = []
}

// ── Tests ─────────────────────────────────────────────────────────

fn test_server_new() {
    server_clear()
    let s0 = server_new("localhost", 8080)
    check_int(s0, 0, "server_new: first idx == 0")
    check_str(server_host(s0), "localhost", "server_new: host")
    check_int(server_port(s0), 8080, "server_new: port")

    let s1 = server_new("0.0.0.0", 3000)
    check_int(s1, 1, "server_new: second idx == 1")
    check_str(server_host(s1), "0.0.0.0", "server_new: second host")
    check_int(server_port(s1), 3000, "server_new: second port")
}

fn test_server_route() {
    server_clear()
    let srv = server_new("localhost", 8080)
    check_int(route_count(srv), 0, "server_route: 0 routes initially")

    server_route(srv, "GET", "/users", 1)
    check_int(route_count(srv), 1, "server_route: 1 route after add")

    server_route(srv, "POST", "/users", 2)
    server_route(srv, "GET", "/users/:id", 3)
    check_int(route_count(srv), 3, "server_route: 3 routes after adds")

    let srv2 = server_new("localhost", 9090)
    server_route(srv2, "GET", "/health", 4)
    check_int(route_count(srv), 3, "server_route: srv still has 3")
    check_int(route_count(srv2), 1, "server_route: srv2 has 1")
}

fn test_route_storage() {
    server_clear()
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/users", 10)
    server_route(srv, "POST", "/items", 20)
    server_route(srv, "DELETE", "/items", 30)

    check_int(route_methods.len(), 3, "route_storage: 3 routes stored")
    check_str(route_methods.get(0), "GET", "route_storage: method 0 is GET")
    check_str(route_methods.get(1), "POST", "route_storage: method 1 is POST")
    check_str(route_methods.get(2), "DELETE", "route_storage: method 2 is DELETE")
    check_str(route_patterns.get(0), "/users", "route_storage: pattern 0")
    check_str(route_patterns.get(1), "/items", "route_storage: pattern 1")
    check_int(route_handler_fn(0), 10, "route_storage: handler 0")
    check_int(route_handler_fn(1), 20, "route_storage: handler 1")
    check_int(route_handler_fn(2), 30, "route_storage: handler 2")
    check_int(route_server_owners.get(0), srv, "route_storage: owner 0")
}

fn test_route_isolation() {
    server_clear()
    let srv1 = server_new("localhost", 8080)
    let srv2 = server_new("localhost", 9090)

    server_route(srv1, "GET", "/a", 1)
    server_route(srv2, "GET", "/b", 2)
    server_route(srv1, "POST", "/c", 3)

    check_int(route_count(srv1), 2, "route_isolation: srv1 has 2")
    check_int(route_count(srv2), 1, "route_isolation: srv2 has 1")
}

fn test_server_clear() {
    server_clear()
    let srv = server_new("localhost", 8080)
    server_route(srv, "GET", "/test", 1)

    check_int(server_hosts.len(), 1, "clear: before server count")
    check_int(route_methods.len(), 1, "clear: before route count")

    server_clear()

    check_int(server_hosts.len(), 0, "clear: server_hosts empty")
    check_int(server_ports.len(), 0, "clear: server_ports empty")
    check_int(route_methods.len(), 0, "clear: route_methods empty")
    check_int(route_patterns.len(), 0, "clear: route_patterns empty")
    check_int(route_handlers.len(), 0, "clear: route_handlers empty")
    check_int(route_server_owners.len(), 0, "clear: route_server_owners empty")
}

fn main() {
    test_server_new()
    test_server_route()
    test_route_storage()
    test_route_isolation()
    test_server_clear()

    io.println("All http_server tests complete")
}
